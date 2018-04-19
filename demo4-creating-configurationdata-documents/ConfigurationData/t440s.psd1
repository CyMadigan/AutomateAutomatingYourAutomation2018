@{
    AllNodes = @(
        @{
            CertificateId = ''
            ConfigurationMode = 'ApplyAndMonitor'
            DebugMode = 'None'
            NodeName = 'T440s'
            RebootNodeIfNeeded = $False
            RefreshMode = 'Push'
            RoleName = @('FileServer')
            StatusRetentionTimeInDays = 1
        }
    )
    ExternalConfiguration = @(
        @{
            Cname = ''
            Description = 'New'
            OtherCnames = @()
            TechnicalOwner = 'WINDOWS'
        }
    )
    FileServer = @(
        @{
            ApplyDefaultRootPermissions = $True
            RootPath = 'C:\DSCFileServer'
            Share = @(
                @{
                    ApplyDefaultPermissions = $True
                    DirectoryName = 'Meta'
                    Ensure = 'Present'
                    FullControlPrincipals = @('BUILTIN\Administrators')
                    ModifyPrincipals = @()
                    ReadOnlyPrincipals = @()
                    ShareName = 'Meta'
                }
            )
        }
    )
    NodeConfig = @(
        @{
            Adminlist = @('ServerAdmins2')
        }
    )
}

