@{
    AllNodes = @(
        @{
            CertificateId = ''
            ConfigurationMode = 'ApplyAndMonitor'
            DebugMode = 'None'
            NodeName = 't440s'
            RebootNodeIfNeeded = $False
            RefreshMode = 'Push'
            RoleName = @('FileServer', 'NodeConfig')
            StatusRetentionTimeInDays = 1
        }
    )
    ExternalConfiguration = @(
        @{
            Cname = ''
            Description = 'Demo for PSCONF'
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
            AdminList = @('ServerAdmins')
            TimeZone = 'W. Europe Standard Time'
        }
    )
}

