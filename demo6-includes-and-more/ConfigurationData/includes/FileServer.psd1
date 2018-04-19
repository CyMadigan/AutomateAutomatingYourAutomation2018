@{
    FileServer = @(
        @{
            RootPath  = 'C:\DSCFileServer' 
            ApplyDefaultRootPermissions = $true
            Share  = @(
                @{
                    ShareName = 'Meta' 
                    DirectoryName = 'Meta' 
                    Ensure = 'Present' 
                    ApplyDefaultPermissions = $true 
                    FullControlPrincipals = 'Contoso\Users' 
                    ModifyPrincipals = @() 
                    ReadOnlyPrincipals = @()
                }
            )
        }
    )
}