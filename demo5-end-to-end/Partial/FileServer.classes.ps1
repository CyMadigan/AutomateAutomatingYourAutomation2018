class Share {
    [ValidateSet('Absent','Present')]
    [String]$Ensure
    
    # Regex: Valid name with only alphanumeric characters
    [ValidatePattern('^[A-z0-9]*$')]
    [String]$ShareName
    
    # Regex: Start with drive letter, followed by a folder name (can be 1 or more)
    [ValidatePattern('^(\w)+$')]
    [String]$DirectoryName
    
    [bool]$ApplyDefaultPermissions
    
    [ValidatePattern('^[A-z]{2,15}\\')]
    [AllowEmptyCollection()]
    [String[]]$FullControlPrincipals
    
    [ValidatePattern('^[A-z]{2,15}\\')]
    [AllowEmptyCollection()]
    [String[]]$ModifyPrincipals
    
    [ValidatePattern('^[A-z]{2,15}\\')]
    [AllowEmptyCollection()]
    [String[]]$ReadOnlyPrincipals
}

class FileServer {
    
    [ValidatePattern('^[A-z]:\\')]
    [System.IO.DirectoryInfo]$RootPath
    
    [bool]$ApplyDefaultRootPermissions
    
    [AllowEmptyCollection()]
    [Share[]]$Share
}

