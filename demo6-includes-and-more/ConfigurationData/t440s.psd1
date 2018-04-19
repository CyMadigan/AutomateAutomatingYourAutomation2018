@{
    AllNodes = @(
        @{
            CertificateId = ''
            ConfigurationMode = 'ApplyAndMonitor'
            DebugMode = 'None'
            NodeName = 'T440s'
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
    Include = @(
        @{
            FileName = '.\includes\FileServer.psd1'
        }
    )
    NodeConfig = @(
        @{
            AdminList = @('ServerAdmins')
            TimeZone = 'W. Europe Standard Time'
        }
    )
}

