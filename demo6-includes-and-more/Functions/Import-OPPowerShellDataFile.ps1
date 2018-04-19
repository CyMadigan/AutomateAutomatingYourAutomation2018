function Import-OPPowerShellDataFile {
    <#
            .Synopsis
            Function used to import a powershell data file (ComputerName.psd1) that has an Include section that describes subsections to be loaded from a different file.

            .Description
            As we have parts of configurations which have to be the same across multiple machines, we allow Include sections that will describe the shared parts of configuration.
            This function can be used to import psd1 in consistent manner including the included subsections.

            .Example
            Import-OPPowershellDataFile -Path x:\repo\dsc\ConfigurationData\t440s.psd1
            Imports the file x:\repo\dsc\ConfigurationData\t440s.pds1 and returns an object containing all data in the file

            .Example
            Import-OPPowershellDataFile -Path x:\repo\dsc\ConfigurationData\asus.psd1
            Imports the file x:\repo\dsc\ConfigurationData\asus.psd1 and returns an object containing all data in the file, this will include the included sections in this file

    #>

    [CmdletBinding(DefaultParameterSetName = "ByPath", HelpUri = "https://go.microsoft.com/fwlink/?LinkID=623621")]
    [OutputType([Hashtable])]
    param(
        #Path to the file that needs to be imported, it's parent folder is used as relative pointer for extra files
        [Parameter(ParameterSetName = "ByPath", Position = 0)]
        [String[]] $Path,
        
        #Path to the file that needs to be imported, it's parent folder is used as relative pointer for extra files
        [Parameter(ParameterSetName = "ByLiteralPath", ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [String[]] $LiteralPath
    )
    
    process {
        foreach($resolvedPath in (Resolve-Path @PSBoundParameters))
        {
            try {
                $powershellDataFileContent = Import-PowerShellDataFile $resolvedPath -ErrorAction Stop
    
                $parentFolderPath = Resolve-Path @PSBoundParameters | Split-Path
    
                if ($powershellDataFileContent -and $powershellDataFileContent.Keys -contains 'Include' -and $powershellDataFileContent['Include'] -is [Array]) {
                    foreach ($includeItem in $powershellDataFileContent['Include']) {
                        if ($includeItem.Keys -contains 'FileName'){
                            $includePath = Join-Path $parentFolderPath -ChildPath $includeItem['FileName'] -Resolve
                            $powershellDataFileContent += (Import-PowerShellDataFile -LiteralPath $includePath -ErrorAction Stop)
                        }
                    }
                    $powershellDataFileContent.Remove('Include')
                }
                $powershellDataFileContent
            }
            catch {
                Write-Error ('The file at location {0} could not be imported with its includes - {1}' -f $resolvedPath, $_)
            }
        }
    }
} 
