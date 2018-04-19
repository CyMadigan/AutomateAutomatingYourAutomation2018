Function New-OPDscMetaFileServerObject {
    <#
        .SYNOPSIS
        Create a new FileServer object for use in DSC metadata

        .DESCRIPTION
        This function generates a new object of type FileServer. The result of this function is a new object 
        which can be passed to Update-OPDscLcmConfigurationFile to add the role FileServer to the server.

        .EXAMPLE
    #>

    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
    [OutputType([System.Collections.Hashtable])]
    Param (
		# The RootPath for partial meta class FileServer
		[Parameter(Mandatory)]
		[System.Management.Automation.ValidatePatternAttribute('^[A-z]:\\')]
		[System.IO.DirectoryInfo]$RootPath,

		# The ApplyDefaultRootPermissions for partial meta class FileServer
		[Parameter(Mandatory)]
		[System.Boolean]$ApplyDefaultRootPermissions,

		# The Share for partial meta class FileServer
		[Parameter(Mandatory)]
		[System.Management.Automation.AllowEmptyCollectionAttribute()]
		[object[]]$Share
    )

    If($PSCmdlet.ShouldProcess('','Create new DSC Meta object of type FileServer')){
        [hashtable]@{
            FileServer = @(
                [hashtable]$PSBoundParameters
            )
        }
    }
}
