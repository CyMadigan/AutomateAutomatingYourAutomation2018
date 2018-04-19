<#
        .SYNOPSIS
        Generate DSC LCM MOF Files
        .DESCRIPTION
        This script is used in the Bamboo build plan to build the LCM configuration files (.mof documents).

        The script can be used locally as well, just point the Path parameter to a local path to skip the Bamboo variables.
        .EXAMPLE
        .\New-LcmConfigurationBuild.ps1 -SourcePath D:\Repositories\dsclcm\ -Path D:\Temp\LcmConfig\

        This will generate the mof documents locally since we did specify a local path
        .EXAMPLE
        .\New-LcmConfigurationBuild.ps1

        This will run the script with the default parameters (as used for Bamboo), the MOF documents will be uploaded to the pullserver.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # Path to the folder where meta configs are generated.
    [String]$BuildPath = '.\build',
    
    # Path to location of the source files
    [String]$SourcePath = '.\source'
)

$LCMBuildPath = Join-Path -Path $BuildPath -ChildPath 'LCM'

if (Test-Path -LiteralPath $LCMBuildPath -PathType Container){
    If($PSCmdlet.ShouldProcess("Destroy the current build target and rebuild it")){
        $null = Remove-Item -LiteralPath $LCMBuildPath -Recurse -Force
    }
}

If($PSCmdlet.ShouldProcess("Build all LCM configuration files with located at $SourcePath to $LCMBuildPath")){
    if (-not (Test-Path -Path $LCMBuildPath -PathType Container)){
        $null = New-Item -Path $LCMBuildPath -ItemType Directory -Force
    }

    $metaConfigurations = Get-ChildItem -Path $SourcePath\Partial\*.classes.ps1 | ForEach-Object {
        $_.BaseName -replace '\..*'
    }

    [DscLocalConfigurationManager()]
    configuration LcmConfig {
        node $AllNodes.Where{!($_.SkipConfiguration)}.NodeName {
        
            $roles = $Node.RoleName.ForEach{ 
                if ($_ -in $metaConfigurations) {
                    "$_.$NodeName"
                } else {
                    $_
                }
            }
        
            Write-Host "Building MOF document for $($configurationFile.Basename)"
            Settings {
                RefreshMode = $Node.RefreshMode
                ConfigurationMode = $Node.ConfigurationMode
                DebugMode = $Node.DebugMode
                RebootNodeIfNeeded = $Node.RebootNodeIfNeeded
                CertificateID = $Node.CertificateID

                # Use value from .psd1 (if present) or defaults (if absent)
                StatusRetentionTimeInDays = 
                if ($statusRetentionTimeInDays = $Node.StatusRetentionTimeInDays) {
                    $statusRetentionTimeInDays
                } else {
                    1
                }

                RefreshFrequencyMins = 
                if ($refresh = $Node.RefreshFrequencyMins) {
                    $refresh
                } else {
                    61
                }
                ConfigurationModeFrequencyMins = 
                if ($configMode = $Node.ConfigurationModeFrequencyMins) {
                    $configMode
                } else {
                    17
                }
            }

            foreach ($role in $roles.Where{ $_ -ne $baseRole}) {
                PartialConfiguration $role {
                    RefreshMode = 'Push'
                }
            }
        }
    }

    foreach ($configurationFile in Get-ChildItem -Path $SourcePath\ConfigurationData\*.psd1) {
        LcmConfig -ConfigurationData $configurationFile.FullName -OutputPath $LCMBuildPath | Select-Object -ExpandProperty FullName
    }
}
