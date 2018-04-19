[CmdletBinding()]
param (
    [hashtable]$ConfigurationData,
    [string]$OutputPath
)

$partialName = Get-Item -LiteralPath $MyInvocation.MyCommand.Path | ForEach-Object BaseName
$nodeName = $ConfigurationData.AllNodes.NodeName
$configurationName = "$partialName.$nodeName"

Configuration $configurationName {
    node $nodeName {
        foreach ($configurationDataItem in $ConfigurationData.$partialName) {
            foreach ($user in $configurationDataItem.AdminList) {
                # Admins...                
            }

            # TimeZone...
        }    
    }
}

& $configurationName @PSBoundParameters
