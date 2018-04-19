#region DPS

throw "Hey, Dory! Forgot to use F8?"

#endregion

# End-to-end scenario
$scriptRoot = "$repoLocation\demo6-includes-and-more"

# Commands that we need to update configurations
foreach ($functionFile in Get-ChildItem -Path $scriptRoot\Functions\*.ps1) {
    . $functionFile
}

psedit "$scriptRoot\ConfigurationData\includes\FileServer.psd1"
Update-OPDscLcmConfigurationFile -Path "$scriptRoot\ConfigurationData" -ComputerName $(hostname) -Sections @{
    Include = @(
        @{
            FileName = '.\includes\FileServer.psd1'
        }
    )
}

# Partial...
$configurationData = Import-OPPowerShellDataFile -Path "$scriptRoot\ConfigurationData\$(hostname).psd1"

# What is in configurationData now?
$configurationData

& "$scriptRoot\Partial\FileServer.ps1" -ConfigurationData $configurationData -OutputPath $scriptRoot


# Now we can also do conditional configuration based on what is in other metadata
