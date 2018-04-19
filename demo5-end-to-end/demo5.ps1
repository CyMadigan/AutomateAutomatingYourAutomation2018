#region DPS

throw "Hey, Dory! Forgot to use F8?"

#endregion

# End-to-end scenario
$scriptRoot = "$repoLocation\demo5-end-to-end"

# Commands that we need to update configurations
foreach ($functionFile in Get-ChildItem -Path $scriptRoot\Functions\*.ps1) {
    . $functionFile
}

New-OPDscMetaClassModule -Path "$scriptRoot\Partial" -OutputDirectory $scriptRoot
Import-Module -Name $scriptRoot\DscMetaClassModule

$section = New-OPDscMetaFileServerObject -RootPath C:\DSCFileServer -Share @(
    New-OPDscMetaShareObject -ShareName Meta -DirectoryName Meta -Ensure Present -ApplyDefaultPermissions $true -FullControlPrincipals BUILTIN\Administrators -ModifyPrincipals @() -ReadOnlyPrincipals @()
) -ApplyDefaultRootPermissions $true

# Building and testing
foreach ($hostConfiguration in Get-ChildItem -Path $scriptRoot\ConfigurationData\*.psd1) {
    Update-OPDscLcmConfigurationFile -ComputerName $hostConfiguration.BaseName -Sections $section -AddRole FileServer -Path $hostConfiguration.Directory.FullName -SectionUpdatePreference Replace
    Invoke-Pester -Script @{
        Path = "$scriptRoot\PreBuildTests\LCM"
        Parameters = @{
            Path = $hostConfiguration.FullName
            SourcePath = $scriptRoot
        }
    }
}

Invoke-Pester -Script @{
    Path = "$scriptRoot\PreBuildTests\Partial"
    Parameters = @{
        Path = "$scriptRoot\Partial\FileServer.ps1"
        SourcePath = $scriptRoot
    }
}

# Compiling MOFs

# Partial...
$configurationData = Import-PowerShellDataFile -Path "$scriptRoot\ConfigurationData\$(hostname).psd1"
& "$scriptRoot\Partial\FileServer.ps1" -ConfigurationData $configurationData -OutputPath $scriptRoot

# LCMs...
& "$scriptRoot\Buildscripts\New-LCMConfigurationBuild.ps1" -BuildPath $scriptRoot -SourcePath $scriptRoot

# Setting Local Configuration Manager + Partial
Set-DscLocalConfigurationManager -Path $scriptRoot\LCM -ComputerName $(hostname)
Publish-DscConfiguration -Path $scriptRoot -ComputerName $(hostname)
Start-DscConfiguration -Wait -Verbose -UseExisting
