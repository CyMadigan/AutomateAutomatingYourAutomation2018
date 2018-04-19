[CmdletBinding()]
param (
    [hashtable]$ConfigurationData,
    [string]$OutputPath
)

$partialName = Get-Item -LiteralPath $MyInvocation.MyCommand.Path | ForEach-Object BaseName
$nodeName = $ConfigurationData.AllNodes.NodeName
$configurationName = "$partialName.$nodeName"

Configuration $configurationName {

    Import-DscResource -ModuleName @{ ModuleName = 'PSDesiredStateConfiguration'; RequiredVersion = '1.1' }
    Import-DscResource -ModuleName @{ ModuleName = 'xSMBShare'; RequiredVersion = '2.0.0.0' }
    Import-DscResource -ModuleName @{ ModuleName = 'cNtfsAccessControl'; RequiredVersion = '1.3.0' }
    
    node $nodeName {

        foreach ($configurationDataItem in $ConfigurationData.$partialName) {

            $rootName = $configurationDataItem.RootPath -replace '[^A-Za-z0-9-]',$null

            If(-not($configurationDataItem.RootPath -match '^[A-z]:\\$')) {
                File "$($rootName)RootFolder" {
                    Ensure = 'Present'
                    Type = 'Directory'
                    DestinationPath = $configurationDataItem.RootPath
                }
            }

            If($configurationDataItem.ApplyDefaultRootPermissions) {
                cNtfsPermissionEntry "$($rootName)RemoveAuthenticatedUsers" {
                    Ensure = 'Absent'
                    Principal = 'NT AUTHORITY\Authenticated Users'
                    Path = $configurationDataItem.RootPath
                }

                cNtfsPermissionEntry "$($rootName)RemoveBuiltinUsers" {
                    Ensure = 'Absent'
                    Principal = 'BUILTIN\Users'
                    Path = $configurationDataItem.RootPath
                }

                cNtfsPermissionEntry "$($rootName)FullAccessPermissionSystem" {
                    Ensure = 'Present'
                    Principal = 'NT AUTHORITY\SYSTEM'
                    Path = $configurationDataItem.RootPath

                    AccessControlInformation = @(

                        cNtfsAccessControlInformation {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'FullControl'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                }

                cNtfsPermissionEntry "$($rootName)FullAccessPermissionLocalAdministrators" {
                    Ensure = 'Present'
                    Principal = 'BUILTIN\Administrators'
                    Path = $configurationDataItem.RootPath

                    AccessControlInformation = @(

                        cNtfsAccessControlInformation {
                            AccessControlType = 'Allow'
                            FileSystemRights = 'FullControl'
                            Inheritance = 'ThisFolderSubfoldersAndFiles'
                            NoPropagateInherit = $false
                        }
                    )
                }

                cNtfsPermissionsInheritance "$($rootName)PermissionsInheritance" {
                    Path = $configurationDataItem.RootPath
                    Enabled = $true
                    PreserveInherited = $false
                    DependsOn = "[cNtfsPermissionEntry]$($rootName)FullAccessPermissionSystem"
                }
            }

            foreach($share in $configurationDataItem.Share) {

                $shareName = $share.ShareName 
                $sharePath = Join-Path -Path $configurationDataItem.RootPath -ChildPath $share.DirectoryName

                if($share.Ensure -ne 'Present'){
                    xSmbShare $shareName {
                        Ensure = 'Absent'
                        Name   = $shareName
                        Path = $sharePath
                        FullAccess = 'Everyone'
                    }
                }
                else {

                    File "$($shareName)Folder" {
                        Ensure = 'Present'
                        Type = 'Directory'
                        DestinationPath = $sharePath
                    }

                    xSmbShare $shareName {
                        Ensure = 'Present'
                        Name   = $shareName
                        Path = $sharePath
                        FullAccess = 'Everyone'
                        DependsOn = "[File]$($shareName)Folder"
                    }

                    Foreach($principal in $share.FullControlPrincipals) {
                        $principalName = $principal -replace '[^A-Za-z0-9-]',$null
                        cNtfsPermissionEntry "$($shareName)$($principalName)FullAccessPermission" {
                            Ensure = 'Present'
                            Principal = $principal
                            Path = $sharePath

                            AccessControlInformation = @(

                                cNtfsAccessControlInformation {
                                    AccessControlType = 'Allow'
                                    FileSystemRights = 'FullControl'
                                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                                    NoPropagateInherit = $false
                                }
                            )
                            DependsOn = "[File]$($shareName)Folder"
                        }
                    }

                    Foreach($principal in $share.ModifyPrincipals) {
                        $principalName = $principal -replace '[^A-Za-z0-9-]',$null
                        cNtfsPermissionEntry "$($shareName)$($principalName)ModifyPermission" {

                            Ensure = 'Present'
                            Principal = $principal
                            Path = $sharePath

                            AccessControlInformation = @(

                                cNtfsAccessControlInformation {
                                    AccessControlType = 'Allow'
                                    FileSystemRights = 'Modify'
                                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                                    NoPropagateInherit = $false
                                }
                            )
                            DependsOn = "[File]$($shareName)Folder"
                        }
                    }

                    Foreach($principal in $share.ReadOnlyPrincipals) {
                        $principalName = $principal -replace '[^A-Za-z0-9-]',$null
                        cNtfsPermissionEntry "$($shareName)$($principalName)ReadOnlyPermission" {

                            Ensure = 'Present'
                            Principal = $principal
                            Path = $sharePath

                            AccessControlInformation = @(

                                cNtfsAccessControlInformation {
                                    AccessControlType = 'Allow'
                                    FileSystemRights = 'ReadAndExecute'
                                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                                    NoPropagateInherit = $false
                                }
                            )
                            DependsOn = "[File]$($shareName)Folder"
                        }
                    }
                }
            }
        }
    }
}

& $configurationName @PSBoundParameters