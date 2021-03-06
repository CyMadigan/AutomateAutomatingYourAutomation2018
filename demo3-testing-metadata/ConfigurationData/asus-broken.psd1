﻿@{
    AllNodes = @(
        @{
            CertificateId = ''
            ConfigurationMode = 'ApplyAndMonitor'
            DebugMode = 'None'
            NodeName = 'asus-broken'
            RebootNodeIfNeeded = $False
            RefreshMode = 'Push'
            RoleName = @('FileServer')
            StatusRetentionTimeInDays = 1
        }
    )
    FileServer = @(
        @{
            ApplyDefaultRootPermissions = 'False'
            RootPath = 'C:\DSCFileServer'
            Share = @(
                @{
                    DirectoryName = 'Meta'
                    Ensure = 'Presen'
                    ShareName = 'Meta'
                }
            )
        }
    )
}

