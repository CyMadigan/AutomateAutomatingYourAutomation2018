#region DPS

throw "Hey, Dory! Forgot to use F8?"

#endregion

#region Setting vars
. "$($psISE.CurrentFile.FullPath)\..\..\Get-FolderLocation.ps1"
#endregion


# Introduction to DSC Configurations
Get-SmbShare -Name Meta -ErrorAction SilentlyContinue | Remove-SmbShare -Confirm:$false
Remove-Item C:\DSCFileServer -Recurse -ErrorAction SilentlyContinue
$scriptRoot = "$repoLocation\demo1-partials-only"

# Let's have a look:
ise "$scriptRoot\Partial\FileServer.ps1"


# Generating the configuration
. "$scriptRoot\Partial\FileServer.ps1"

FileServer -OutputPath $scriptRoot

# .mof file generated:
ise "$scriptRoot\$(hostname).mof"


# Now we can apply this configuration to the host?
Start-DscConfiguration -Path $scriptRoot -Wait -Verbose


# Add some configuration to keep track of LCM configuration:
ise "$scriptRoot\ConfigurationData\$(hostname).psd1"

# To create a meta configuration we created a script:
ise "$scriptRoot\Buildscripts\New-LCMConfigurationBuild.ps1"

# Now we can generate a meta config
& "$scriptRoot\Buildscripts\New-LCMConfigurationBuild.ps1" -BuildPath $scriptRoot -SourcePath $scriptRoot

# What we generated:
Get-ChildItem "$scriptRoot\LCM" | ForEach-Object{ise $_.FullName}

# Apply the meta configuration to the LCM
Set-DscLocalConfigurationManager -Path "$scriptRoot\LCM"

Get-DscLocalConfigurationManager

# Now we can Publish our FileServer configuration to the LCM
Publish-DscConfiguration -Path $scriptRoot

# Run the configuration
Start-DscConfiguration -UseExisting -Wait -Verbose