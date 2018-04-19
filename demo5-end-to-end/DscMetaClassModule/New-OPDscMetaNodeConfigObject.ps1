Function New-OPDscMetaNodeConfigObject {
    <#
        .SYNOPSIS
        Create a new NodeConfig object for use in DSC metadata

        .DESCRIPTION
        This function generates a new object of type NodeConfig. The result of this function is a new object 
        which can be passed to Update-OPDscLcmConfigurationFile to add the role NodeConfig to the server.

        .EXAMPLE
    #>

    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
    [OutputType([System.Collections.Hashtable])]
    Param (
		# The AdminList for partial meta class NodeConfig
		[Parameter(Mandatory)]
		[System.String[]]$AdminList,

		# The TimeZone for partial meta class NodeConfig
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidateSetAttribute('"W. Europe Standard Time"')]
		[System.String]$TimeZone
    )

    If($PSCmdlet.ShouldProcess('','Create new DSC Meta object of type NodeConfig')){
        [hashtable]@{
            NodeConfig = @(
                [hashtable]$PSBoundParameters
            )
        }
    }
}
