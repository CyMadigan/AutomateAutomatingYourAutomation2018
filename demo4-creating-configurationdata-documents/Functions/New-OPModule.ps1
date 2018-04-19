function New-OPModule {
    <#
        .Synopsis
        Function that can be used to create folder structure for normal modules/ class based resources

        .Description
        Creating a module can be painful and requires several manual steps. This functions is to make it simpler and less prone to errors.
        Can be use to create normal modules, but primary use is to generate modules containing class based resources.

        .Example
        New-OPModule -Path f:\scripts\DSC-Core\Resources -Name opBamboo -Resource opBambooCapabilities, opBambooName
        Creates module for DSC Resources in the specified location. Creates psm1 file with skeleton for classes and psd1 with version 0.1.0.0, listed resources and correct RootModule.

        .Example
        New-OPModule -Path f:\scripts\General -Name TestHook -Function New-OPHook, Test-OPHook -Version 0.2.0.0
        Creates module for normal use in the specified location. Creates psm1 file that dot-sources .ps1 files and skeleton file for each function, with generated help, param block.
        Manifest is created with version 0.2.0.0, listing all the functions and with correct RootModule.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Resource',
        SupportsShouldProcess,
        ConfirmImpact = 'Low'
    )]
    param (
        # Path to folder (has to be in git) that module will be created
        [Parameter(Mandatory)]
        [ValidateScript({
            Test-Path -Path $_
        })]
        [String]$Path,

        # Name of the module that will be created
        [Parameter(Mandatory)]        
        [String]$Name,

        # List of class-based resources that will be included in created module
        [Parameter(
            ParameterSetName = 'Resource',
            Mandatory = $true
        )]
        [String[]]$Resource,

        # List of functions that will be included in created module
        [Parameter(
            ParameterSetName = 'Function',
            Mandatory = $true
        )]
        [String[]]$Function,

        # Version of created module
        [version]$Version,

        # Description of created module
        [String]$Description,

        # Author of created module
        [String]$Author,

        # Tags that will be added to the module manifest. If none specified type of module (functions/resources) will be used.
        [String[]]$Tag,

        # Project URI that will be added to the module manifest. If non specified information gather from git will be used to guess correct URI.
        [String]$ProjectURI,

        # Path to alternate template that should be used for generated functions, classes and main module. Requires keys: moduleFile, function, class. Path to psd1 can be used.
        [ValidateScript({
            $missing = @()
            foreach ($keyRequired in 'moduleFile', 'function', 'class') {
                if (-not $_.Contains($keyRequired)) {
                    $missing += $keyRequired
                }
            }
            if ($missing) {
                throw "Missing key: $($missing -join ', ')."
            } else {
                $true
            }
        })]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable]$Template

    )
    if (-not $Template) {
        $Template = @{
            function = @'
function {0} {{
    <#
        .Synopsis
        Synopsis for {0}

        .Description
        Description for {0}

        .Example
        {0}
        First example of {0} in action
    #>

    [CmdletBinding({1})]
    param (
        # Description of param
        [String]$ParamName
    )
}}
'@
            class = @'
[DscResource()]
class {0} {{
    
    #region class properties
    [DscProperty(Key)]
    
    #endregion
    
    #region Standard methods
    
    [{0}] Get () {{
        return [{0}]@{{

        }}
    }}
    
    [bool] Test () {{
        return $false
    }}
    
    [void] Set () {{
        
    }}
    
    #endregion
    
    #region Helper methods
    
    #endregion
}}
'@
            moduleFile = @'
param (
    [bool]$IsDebug = $false
)

foreach ($item in Get-ChildItem -Path $PSScriptRoot\*.ps1) {
    if ($IsDebug) {
        # Performance is not important...
        . $item.FullName
    } else {
        # InvokeScript(useLocalScope, scriptBlock, input, args)
        $ExecutionContext.InvokeCommand.InvokeScript(
            $false, 
            (
                [scriptblock]::Create(
                    [io.file]::ReadAllText(
                        $item.FullName
                    )
                )
            ), 
            $null, 
            $null
        )
    }
}
'@
        }
    }

    try {
        $null = New-Item -Path $Path\$Name -ItemType Directory -Force
    } catch {
        throw "Failed to create a folder for module $Name in $Path - $_"
    }
        
    #region auto-generating parts of manifest values...

    if (-not $Version) {
        $Version = '0.1.0.1'
    }

    if (-not $Description) {
        $Description = "Module autogenerated for $ENV:USERNAME on $(Get-Date -Format yyyy-MMM-dd)"
    }

    if (-not $Author) {
        $Author = $ENV:USERNAME
    }

    if (-not $Tag) {
        $Tag = switch ($PSCmdlet.ParameterSetName) {
            Function {
                'General'
            }
            Resource {
                'DSCResource'
            }
        }
    }

    #endregion

    $manifestParams = @{
        Path = "$Path\$Name\$Name.psd1"
        RootModule = "$Name.psm1"
        Author = $Author
        CompanyName = 'Optiver'
        Description = $Description
        Tags = $Tag
        ModuleVersion = $Version
        ErrorAction = 'Stop'
        PassThru = $true
    }

    switch ($PSCmdlet.ParameterSetName) {
        Function {
            $manifestParams.FunctionsToExport = $Function
        }
        Resource {
            $manifestParams.DscResourcesToExport = $Resource
        }
    }


    if (-not $PSCmdlet.ShouldProcess(
        "Module $Name",
        "Create with $manifestParams"
    )) {
        # Rather than surround almost whole body of function - I'm exiting prematurely if user doesn't want to continue...
        return
    }

    # In case -Confirm was used...
    $ConfirmPreference = 'continue'

    try {
        $content = New-ModuleManifest @manifestParams 
        $content | Set-Content -LiteralPath $Path\$Name\$Name.psd1 -Encoding UTF8 -ErrorAction Stop -Force
        $null = New-Item -Path $Path\$Name\$Name.psm1 -Force
    } catch {
        throw "Failed to create files for module $Name in $Path - $_"
    }

    switch ($PSCmdlet.ParameterSetName) {
        Function {
            try {
                Set-Content -LiteralPath $Path\$Name\$Name.psm1 -Value $Template.moduleFile -Encoding UTF8 -ErrorAction Stop
            } catch {
                throw "Failed to set content of the RootModule file - $_"
            }

            foreach ($item in $Function) {
                $binding = ''
                if ($item -match '^(New|Set|Remove|Stop)-') {
                    $binding = "SupportsShouldProcess, ConfirmImpact = 'Medium'"
                }
                try {
                    $null = New-Item -Path $Path\$Name\$item.ps1 
                    Set-Content -Path $Path\$Name\$item.ps1 -Encoding UTF8 -Value ($Template.function -f $item, $binding) -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to add function $item to module $Name - $_"
                }
            }
        }
        Resource {
                
            foreach ($item in $Resource) {
                try {
                    Add-Content -Path $Path\$Name\$Name.psm1 -Encoding UTF8 -Value ($Template.class -f $item) -ErrorAction Stop 
                } catch {
                    Write-Warning "Failed to add class $item to module $Name - $_"
                }
            }
        }
    }
    Get-Item -Path $Path\$Name
}
