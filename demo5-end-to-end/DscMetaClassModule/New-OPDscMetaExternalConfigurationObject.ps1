Function New-OPDscMetaExternalConfigurationObject {
    <#
        .SYNOPSIS
        Create a new ExternalConfiguration object for use in DSC metadata

        .DESCRIPTION
        This function generates a new object of type ExternalConfiguration. The result of this function is a new object 
        which can be passed to Update-OPDscLcmConfigurationFile to add the role ExternalConfiguration to the server.

        .EXAMPLE
    #>

    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
    [OutputType([System.Collections.Hashtable])]
    Param (
		# The Cname for partial meta class ExternalConfiguration
		[Parameter(Mandatory)]
		[System.String]$Cname,

		# The Description for partial meta class ExternalConfiguration
		[Parameter(Mandatory)]
		[System.String]$Description,

		# The OtherCnames for partial meta class ExternalConfiguration
		[Parameter(Mandatory)]
		[System.String[]]$OtherCnames,

		# The TechnicalOwner for partial meta class ExternalConfiguration
		[Parameter(Mandatory)]
		[System.String]$TechnicalOwner
    )

    If($PSCmdlet.ShouldProcess('','Create new DSC Meta object of type ExternalConfiguration')){
        [hashtable]@{
            ExternalConfiguration = @(
                [hashtable]$PSBoundParameters
            )
        }
    }
}
