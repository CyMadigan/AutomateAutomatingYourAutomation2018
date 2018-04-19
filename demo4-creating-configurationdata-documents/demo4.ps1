#region DPS

throw "Hey, Dory! Forgot to use F8?"

#endregion

# No need for copy-pasting ConfigurationData
$scriptRoot = "$repoLocation\demo4-creating-configurationdata-documents"

ise "$scriptRoot\Functions\New-OPDscLcmConfigurationFile.ps1"

# Create a new ConfigurationData document
. "$scriptRoot\Functions\New-OPDscLcmConfigurationFile.ps1"
New-OPDscLcmConfigurationFile -ComputerName (hostname) -RoleName FileServer -Path "$scriptRoot\ConfigurationData" -Description 'Demo for PSCONF' -TechnicalOwner WINDOWS -RefreshMode Push

ise "$scriptRoot\ConfigurationData\$(hostname).psd1"

# How to update ConfigurationData
. "$scriptRoot\Functions\Update-OPDscLcmConfigurationFile.ps1"

Update-OPDscLcmConfigurationFile -ComputerName (hostname) -Description 'New' -Path "$scriptRoot\ConfigurationData"

# The function used to handle the updates to the ConfigurationData document:
ise "$scriptRoot\Functions\Update-OPDscLcmConfigurationFile.ps1"


# We can also update the metadata for our roles - arrays get merged by default:
Push-Location -Path "$scriptRoot\ConfigurationData"

Update-OPDscLcmConfigurationFile -ComputerName (hostname) -Sections @{NodeConfig = @{Adminlist = @('ServerAdmins2')}}


# We can change that behaviour by using SectionUpdatePreference Replace (with great power...)
Update-OPDscLcmConfigurationFile -ComputerName (hostname) -Sections @{NodeConfig = @(@{Adminlist = @('ServerAdmins2')})} -SectionUpdatePreference Replace

Pop-Location

# Our sections are defined by classes - how about generating functions from them...?
ise "$scriptRoot\Functions\New-OPModule.ps1"
ise "$scriptRoot\Functions\New-OPDscMetaClassModule.ps1"

. "$scriptRoot\Functions\New-OPModule.ps1"
. "$scriptRoot\Functions\New-OPModule.ps1"

New-OPDscMetaClassModule -Path "$scriptRoot\Partial" -OutputDirectory $repoLocation
Import-Module -Name $repoLocation\DscMetaClassModule

# Commands in module are using same validations/types as classes, preventing issues with generated items
Get-Command -Module DscMetaClassModule
Get-Command -Name New-OPDscMetaFileServerObject -Syntax

# When we run one of them and miss a property - prompt will help us avoid error
New-OPDscMetaShareObject -ShareName Meta -DirectoryName Meta

# Generating sections is almost bullet-proof
$section = New-OPDscMetaFileServerObject -RootPath C:\DSCFileServer -Share @(
    New-OPDscMetaShareObject -ShareName Meta -DirectoryName Meta -Ensure Present -ApplyDefaultPermissions $true -FullControlPrincipals BUILTIN\Administrators -ModifyPrincipals @() -ReadOnlyPrincipals @()
) -ApplyDefaultRootPermissions $true

$section.FileServer
$section.FileServer.Share

# We just need to pass generated sections to Update-OPDscLcmConfigurationFile function with correct Update Preference
Update-OPDscLcmConfigurationFile -ComputerName (hostname) -Sections $section -Path "$scriptRoot\ConfigurationData" -SectionUpdatePreference Replace

ise "$scriptRoot\ConfigurationData\$(hostname).psd1"
