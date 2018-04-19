@{
    AllNodes = @(
        @{
            CertificateId = ''
            ConfigurationMode = 'ApplyAndMonitor'
            DebugMode = 'None'
            NodeName = 'asus'
            RebootNodeIfNeeded = $False
            RefreshMode = 'Push'
            RoleName = @('FileServer')
            StatusRetentionTimeInDays = 1
        }
    )
    FileServer = @(
        @{
            ApplyDefaultRootPermissions = $True
            RootPath = 'C:\DSCFileServer'
            Share = @(
                @{
                    DirectoryName = 'Meta'
                    Ensure = 'Present'
                    ShareName = 'Meta'
                }
            )
        }
    )
}

