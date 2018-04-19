Function New-OPDscMetaShareObject {
    <#
        .SYNOPSIS
        Create a new Share object for use in DSC metadata

        .DESCRIPTION
        This function generates a new object of type Share. The result of this function is a new object 
        which can be passed to Update-OPDscLcmConfigurationFile to add the role Share to the server.

        .EXAMPLE
    #>

    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
    [OutputType([System.Collections.Hashtable])]
    Param (
		# The Ensure for partial meta class Share
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidateSetAttribute('Absent','Present')]
		[System.String]$Ensure,

		# The ShareName for partial meta class Share
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidatePatternAttribute('^[A-z0-9]*$')]
		[System.String]$ShareName,

		# The DirectoryName for partial meta class Share
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidatePatternAttribute('^(\w)+$')]
		[System.String]$DirectoryName,

		# The ApplyDefaultPermissions for partial meta class Share
		[Parameter(Mandatory)]
		[System.Boolean]$ApplyDefaultPermissions,

		# The FullControlPrincipals for partial meta class Share
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidatePatternAttribute('^[A-z]{2,15}\\')]
		[System.Management.Automation.AllowEmptyCollectionAttribute()]
		[System.String[]]$FullControlPrincipals,

		# The ModifyPrincipals for partial meta class Share
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidatePatternAttribute('^[A-z]{2,15}\\')]
		[System.Management.Automation.AllowEmptyCollectionAttribute()]
		[System.String[]]$ModifyPrincipals,

		# The ReadOnlyPrincipals for partial meta class Share
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidatePatternAttribute('^[A-z]{2,15}\\')]
		[System.Management.Automation.AllowEmptyCollectionAttribute()]
		[System.String[]]$ReadOnlyPrincipals
    )

    If($PSCmdlet.ShouldProcess('','Create new DSC Meta object of type Share')){
        [hashtable]$PSBoundParameters
    }
}
