[CmdletBinding()]
param (
    # Path to ConfigurationData file for a given host.
    [Parameter(Mandatory)]
    [String]$Path,

    # Path to location of the source files
    [String]$SourcePath = '.\source'
)

$fileBaseName = Get-ChildItem (Split-Path -Path $Path -Parent) | Where-Object {$_.FullName -eq $Path} | Select-Object -ExpandProperty BaseName

try {
    $configurationData = Import-PowerShellDataFile -Path $Path -ErrorAction Stop
} catch {
    $exception = $_.Exception
}

Describe "Testing ConfigurationData file $fileBaseName" {
    It 'Can be converted to ConfigurationData object' {
        $exception.Message | Should BeNullOrEmpty
    }

    It 'Has a lowercase filename' {
            
        ($fileBaseName).ToLower() | Should BeExactly $fileBaseName
    }
    
    Context "Testing properties within configuration data for $fileBaseName" {
        It 'Contains AllNodes' {
            $configurationData.Contains('AllNodes') | Should be $true
        }

        It 'AllNodes value is an array' {
            $configurationData.AllNodes.GetType().FullName | Should be System.Object[]
        }

        It 'AllNodes should have just one element' {
            $configurationData.AllNodes.Length | Should be 1
        }

        It "Should describe configuration of $fileBasename only" {
            $configurationData.AllNodes[0].NodeName | Should be $fileBasename
        }

        It 'Should only list Partials that exist in the current repository' {
            $missing = $configurationData.AllNodes[0].RoleName.Where{ 
                    -not (Test-Path -Path "$SourcePath\Partial\$_.ps1")
            }
            $missing -join ', ' | Should BeNullOrEmpty
        }

        It 'Should have correct ConfigurationMode' {
            $configurationData.AllNodes[0].ConfigurationMode -in 'ApplyOnly', 'ApplyAndMonitor', 'ApplyAndAutoCorrect' | Should be $true
        }

        It 'Should have correct DebugMode' {
            $configurationData.AllNodes[0].DebugMode -in 'None', 'ForceModuleImport', 'All' | Should be $true
        }

        It 'Should have correct RefreshMode' {
            $configurationData.AllNodes[0].RefreshMode -in 'Pull', 'Push', 'Disabled' | Should be $true
        }
    }

    Context "Testing meta properties within configuration data for $fileBasename" {
        $MetaRoles = $configurationData.AllNodes[0].RoleName.Where{ 
            Test-Path "$SourcePath\Partial\$_.classes.ps1"
        }
        $partialMetaSections = $configurationData.Keys.Where({ $_ -ne 'AllNodes'})

        It 'Should not have meta data for roles that are not configured'{
            $extra = $partialMetaSections.Where({ $_ -notin $configurationData.AllNodes[0].RoleName -and $_ -ne 'ExternalConfiguration'})
            $extra -join ', ' | Should BeNullOrEmpty
        }

        It 'Should have corresponding meta data for meta partials'{
            $missing = $metaRoles.Where({ $_ -notin $partialMetaSections })
            $missing -join ', ' | Should BeNullOrEmpty
        }
            
        foreach ($metaRole in $partialMetaSections){
            $ExecutionContext.InvokeCommand.InvokeScript(
                $false,
                (
                    [scriptblock]::Create(
                        [io.file]::ReadAllText(
                            "$SourcePath\Partial\$MetaRole.classes.ps1"
                        )
                    )
                ),
                $null,
                $null
            )
    
            It "$metaRole should be an array of hashtables" {
                $ConfigurationData.$metaRole.GetType().FullName | Should Be System.Object[]
            }
            foreach ($metaRoleItem in $ConfigurationData.$metaRole) {
                $metaObject = New-Object -TypeName $MetaRole
                $metaObjectPropertyNames = $metaObject.PSObject.Properties.Name
                    
                It "All Properties of a MetaObject should be described for $metaRole"{
                    $metaObjectPropertyNames.Where{ -not $metaRoleItem.ContainsKey($_) } -join ', ' | Should BeNullOrEmpty
                }
                    
                It "MetaRoleItem doesn't contain keys that don't have matching properties in MetaObject for $metaRole" {
                    $metaRoleItem.Keys.Where{ $_ -notin $metaObjectPropertyNames } -join ', ' | Should BeNullOrEmpty
                }
                    
                    
                It "Given value for <Property> is <Value>, it can be assigned to <Property> of $metaRole" {
                    param (
                        $Property,
                        $Value
                    )
                    $metaObject.$Property = $Value 
                } -TestCases @(
                    foreach ($metaRoleItemKey in $metaRoleItem.Keys) {
                        @{
                            Property = $metaRoleItemKey
                            Value = $metaRoleItem.$metaRoleItemKey
                        }
                    }
                )

                $strictList = @(
                    'System.Boolean'
                    'System.String'
                    'System.Int32'
                )
                $strictProperties = $metaObject.PSObject.Properties | Where-Object {$_.TypeNameOfValue -in $strictList}
                It "Given dataType for <Property> is <Value> in metadata, it is of the same type in $metaRole" {
                    param (
                        $Property,
                        $Value
                    )
                    $metaObject.$Property.GetType().FullName | Should be $Value
                } -TestCases @(
                    foreach ($metaRoleItemKey in ($metaRoleItem.Keys | Where-Object {$_ -in $strictProperties.Name})) {
                        @{
                            Property = $metaRoleItemKey
                            Value = $metaRoleItem[$metaRoleItemKey].GetType().FullName
                        }
                    }
                )
                    
                if ($metaObject.PSObject.Methods.Where{ $_.Name -eq 'Validate' }){
                    $metaObject = New-Object -TypeName $metaRole -Property $MetaRoleItem
                    It "Should have valid/complete metadata for $metaRole (if .Validate() is implemented)" {
                        $metaObject.Validate() | Should BeNullOrEmpty
                    }
                }
            }
        }
    }
}
