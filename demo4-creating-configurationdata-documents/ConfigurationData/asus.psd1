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
    ExternalConfiguration = @(
        @{
            Cname = ''
            Description = 'Demo for PSCONF'
            OtherCnames = @()
            TechnicalOwner = 'WINDOWS'
        }
    )
    NodeConfig = @(
        @{
            AdminList = @('ServerAdmins')
            TimeZone = 'W. Europe Standard Time'
        }
    )
}

