#region DPS

throw "Hey, Dory! Forgot to use F8?"

#endregion

# The need for metadata
Get-SmbShare -Name Meta -ErrorAction SilentlyContinue | Remove-SmbShare -Confirm:$false
Remove-Item C:\DSCFileServer\ -Recurse -ErrorAction SilentlyContinue
$scriptRoot = "$repoLocation\demo2-the-need-for-metadata"

# Adding metadata to configuration
ise "$scriptRoot\ConfigurationData\$(hostname).psd1"


# Let's review the changed the partial:
ise "$scriptRoot\Partial\FileServer.ps1"


# Now we can build the configuration using our metadata
$configurationData = Import-PowerShellDataFile -Path "$scriptRoot\ConfigurationData\$(hostname).psd1"
& "$scriptRoot\Partial\FileServer.ps1" -ConfigurationData $configurationData -OutputPath $scriptRoot

# Now we need to update the metaconfiguration, since we now have a partial specific for this node!
& "$scriptRoot\Buildscripts\New-LCMConfigurationBuild.ps1" -BuildPath $scriptRoot -SourcePath $scriptRoot

Set-DscLocalConfigurationManager -Path "$scriptRoot\LCM"
Get-DscLocalConfigurationManager

# Publish the new configuration to the LCM
Publish-DscConfiguration -Path $scriptRoot

# Run the configuration
Start-DscConfiguration -UseExisting -Wait -Verbose