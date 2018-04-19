[CmdletBinding()]
param (
    # Path to Partial definition file for a given host.
    [Parameter(Mandatory)]
    [String]$Path,

    # Path to location of the source files
    [String]$SourcePath = '.\source'
)

$fileName = Split-Path -Path $Path -Leaf
$fileBaseName = $fileName -replace '\.ps1'
$buildIn = (Get-DscResource -Module PSDesiredStateConfiguration).Name

$parseError = $null
$buildInUsed = @()
$buildInDeclared = $false
$configurationAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $Path, 
    [ref]$null, 
    [ref]$parseError
)

$definition = $configurationAst.FindAll(
    {
        param ($astElement)
        $astElement -is [System.Management.Automation.Language.ConfigurationDefinitionAst]
    },
    $false
)

$hasMetadata = Test-Path -LiteralPath ($Path -replace '\.ps1', '.classes.ps1')
    
$call = $configurationAst.EndBlock.Statements.Where{ 
    $_ -is [System.Management.Automation.Language.PipelineAst] 
}
    
$importedResources = $definition.Body.ScriptBlock.FindAll(
    {
        param ($astElement) 
        $astElement -is [System.Management.Automation.Language.CommandParameterAst] -and
        $astElement.ParameterName -eq 'ModuleName' -and
        $astElement.Parent.Extent.Text -match '^Import-DscResource'
    },
    $false
)

$resourcesUsed = $definition.Body.ScriptBlock.FindAll(
    {
        param ($astElement)
        $astElement -is [System.Management.Automation.Language.DynamicKeywordStatementAst] -and
        $astElement.CommandElements[0].Extent.Text -ne 'node' -and
        $astElement.CommandElements[1] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $astElement.CommandElements[1] -match '^\w+$'
    },
    $true
) | ForEach-Object { 
    $resourceName = $_.CommandElements[0].Extent.Text
    $itemName = $_.CommandElements[1].Extent.Text 
    $resourceUsed = '[{0}]{1}' -f $resourceName, $itemName 
    $resourceUsed
}

$dependsOnReferences = $definition.Body.ScriptBlock.FindAll(
    {
        param ($astElement)
        $astElement -is [System.Management.Automation.Language.HashtableAst] -and
        $astElement.KeyValuePairs.Item1.Value -eq 'DependsOn'
    }, 
    $true
).Keyvaluepairs.Where{ 
    $_.Item1.Value -eq 'DependsOn' -and
    -not $_.Item2.PipelineElements.Expression.NestedExpressions 
}.Item2.PipelineElements.Expression.Value

$buildInUsed = [bool](
    $definition.Body.ScriptBlock.Find(
        {
            param ($astElement)
            $astElement -is [System.Management.Automation.Language.DynamicKeywordStatementAst] -and
            $astElement.CommandElements[0].Extent.Text -in $buildIn
        },
        $true
    )
)

Describe "Testing partial configuration $fileBaseName - general" -Tags "${fileName}:General" {
    if ($hasMetadata) {
        # Looking up any shared meta-configuration in a form of a hash table inside .ps1 file.
        # It has to have class with the same name defined in order to qualify for these test.
        $sharedMetaConfigurations = $configurationAst.FindAll( 
            { 
                param ($astToken)
                $astToken -is [System.Management.Automation.Language.AssignmentStatementAst] -and 
                $astToken.Right.PipelineElements -and
                $astToken.Right.PipelineElements[0].CommandElements[0].Value -eq 'Import-OPPowerShellDataFile'
            }, 
            $false 
        )

        if ($sharedMetaConfigurations) {
            Write-Host "Shared meta-configurations used - we need to import classes.ps1 file"
            $ExecutionContext.InvokeCommand.InvokeScript(
                $false,
                (
                    [scriptblock]::Create(
                        [io.file]::ReadAllText(
                            "$SourcePath\Partial\$fileBaseName.classes.ps1"
                        )
                    )
                ),
                $null,
                $null
            )
        }

        foreach ($sharedMetaConfiguration in $sharedMetaConfigurations) {
            $className = $sharedMetaConfiguration.Left.VariablePath.UserPath
            $sharedConfigurationHash = Import-OPPowerShellDataFile -LiteralPath $SourcePath\Partial\$className.psd1
            $sharedConfigObject = New-Object -TypeName $className
            $sharedConfigPropertyNames = $sharedConfigObject.PSObject.Properties.Name
            foreach ($sharedConfigurationItem in $sharedConfigurationHash.Keys) {
                Context "Testing class-based definitions inside for item $sharedConfigurationItem of class $className" {
                    $itemCounter = 0
                    foreach ($instance in $sharedConfigurationHash[$sharedConfigurationItem]) {
                        $itemCounter++
                            
                        It "All Properties of a $className should be described for $sharedConfigurationItem ($itemCounter)" {
                            $sharedConfigPropertyNames.Where{ -not $instance.ContainsKey($_) } -join ', ' | Should BeNullOrEmpty
                        }
                    
                        It "Shared configuration item $sharedConfigurationItem ($itemCounter) doesn't contain keys that don't have matching properties in $className" {
                            $instance.Keys.Where{ $_ -notin $sharedConfigPropertyNames } -join ', ' | Should BeNullOrEmpty
                        }
                    
                                
                        It "Given $sharedConfigurationItem ($itemCounter) value for <Property> is <Value>, it can be assigned to property <Property> of the class $className" {
                            param (
                                $Property,
                                $Value
                            )
                            {
                                $sharedConfigObject.$Property = $Value
                            } | Should Not Throw
                        } -TestCases @(
                            foreach ($sharedConfigurationItemKey in $instance.Keys) {
                                @{
                                    Property = $sharedConfigurationItemKey
                                    Value = $instance.$sharedConfigurationItemKey
                                }
                            }
                        )
                    
                        if ($sharedConfigObject.PSObject.Methods.Where{ $_.Name -eq 'Validate' }){
                            $sharedConfigObject = New-Object -TypeName $className -Property $instance
                            It "Should have valid/complete metadata for $className (if .Validate() is implemented)" {
                                $sharedConfigObject.Validate() | Should BeNullOrEmpty
                            }
                        }
                    }
                }
            }
        }
    } else {
        It 'Has only definition and call' {
            $configurationAst.EndBlock.Statements.Count | Should Be 2
        }

        It "Defines configuration $fileBaseName" {
            $definition.InstanceName.Value | Should be $fileBaseName
        }
            
        It 'Calls defined configuration only' {
            $call.Count | Should Be 1
        }
            
        It "Calls configuration $fileBaseName" {
            $call.PipelineElements[0].CommandElements[0].Value | Should be $fileBaseName
        }
    }

    It 'Should not have errors in script body' {
        $parseError.Message -join '; ' | Should BeNullOrEmpty
    }
        
    It 'Defines just one configuration' {
        $definition.Count | Should Be 1
    }
        
    $importedResources | ForEach-Object { 
        $line = $_.Parent.Extent.Text -replace '\.', '_'
        $pair = $_.Parent.CommandElements.FindAll(
                {$args[0] -is [System.Management.Automation.Language.HashtableAst]},
                $false
            ).KeyValuePairs
            $moduleName = $pair.where{ $_.Item1.Value -eq 'ModuleName'}.Item2.PipelineElements.Expression.Value
            if ($moduleName -eq 'PSDesiredStateConfiguration') {
                $buildInDeclared = $true
            }
        It "Should use a hashtable to import DSC resource module $moduleName in line $line" {
            $_.Parent.CommandElements.Where{
                $_ -is [System.Management.Automation.Language.HashtableAst]
            } | Should Not Be $null
        }
    }

    It "Declares PSDesiredStateConfiguration as required module explicitly when needed" {
        [bool]$buildInUsed | Should Be $buildInDeclared
    }

    foreach ($dependsOn in $dependsOnReferences) {
        It "Should depend on existing resource $dependsOn" {
            @($resourcesUsed) -eq $dependsOn | Should be $dependsOn
        }
    }
}

