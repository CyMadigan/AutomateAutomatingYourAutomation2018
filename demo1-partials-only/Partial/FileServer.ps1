Configuration FileServer {

    Import-DscResource -ModuleName @{ ModuleName = 'PSDesiredStateConfiguration'; RequiredVersion = '1.1' }
    Import-DscResource -ModuleName @{ ModuleName = 'xSMBShare'; RequiredVersion = '2.0.0.0' }
    Import-DscResource -ModuleName @{ ModuleName = 'cNtfsAccessControl'; RequiredVersion = '1.3.0' }
    
    node $(hostname) {

        # Variables
        $rootFolder = 'C:\DSCFileServer'

        File "RootFolder" {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = $rootFolder
        }

        cNtfsPermissionEntry "RemoveAuthenticatedUsers" {
            Ensure = 'Absent'
            Principal = 'NT AUTHORITY\Authenticated Users'
            Path = $rootFolder
            DependsOn = '[File]RootFolder'
        }

        cNtfsPermissionEntry "RemoveBuiltinUsers" {
            Ensure = 'Absent'
            Principal = 'BUILTIN\Users'
            Path = $rootFolder
            DependsOn = '[File]RootFolder'
        }

        cNtfsPermissionEntry "FullAccessPermissionSystem" {
            Ensure = 'Present'
            Principal = 'NT AUTHORITY\SYSTEM'
            Path = $rootFolder
            DependsOn = '[File]RootFolder'

            AccessControlInformation = @(

                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        
        cNtfsPermissionEntry "FullAccessPermissionLocalAdministrators" {
            Ensure = 'Present'
            Principal = 'BUILTIN\Administrators'
            Path = $rootFolder
            DependsOn = '[File]RootFolder'

            AccessControlInformation = @(

                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }

        cNtfsPermissionsInheritance "PermissionsInheritance" {
            Path = $rootFolder
            Enabled = $true
            PreserveInherited = $false
            DependsOn = '[File]RootFolder'
        }

        # Create subfolders
        File MetaFolder {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = "$rootFolder\Meta"
        }

        xSmbShare MetaShare {
            Ensure = 'Present'
            Name   = 'Meta'
            Path = "$rootFolder\Meta"
            FullAccess = 'Everyone'
            DependsOn = "[File]MetaFolder"
        }
    }
}