function Update-OPDscLcmConfigurationFile {
    <#
            .Synopsis
            Function used to update file (ComputerName.psd1) used when generating MOF documents for Local Configuration Manager (LCM)

            .Description
            As part of automating processes around DSC we want to keep LCM configuration (in form of ConfigurationData files) in the repository.
            This function can be used to update psd1 in consistent manner.

            .Example
            Update-OPDscLcmConfigurationFile -ComputerName Server1 -Path f:\scripts\DscLcm\ConfigurationData -AddRole FileServer
            Updates file f:\scripts\DscLcm\ConfigurationData\Server1.psd1 that contains ConfigurationData with additional role (FileServer)

    #>

    [CmdletBinding(
            DefaultParameterSetName = 'withoutsections',
            SupportsShouldProcess,
            ConfirmImpact = 'Low'
    )]
    [OutputType([System.IO.FileInfo])]
    param (
        # Name of the computer for which configuration will be updated.
        [Parameter(
                Mandatory
        )]
        [String]$ComputerName,

        # Name of the Role(s) that should be added to updated configuration file.
        [String[]]$AddRole = @(),

        # Name of the Role(s) that should be removed from updated configuration file.
        [String[]]$RemoveRole,

        # Path to directory where the configuration file is stored (file has to exist).
        [ValidateScript({
                    Test-Path -LiteralPath $_ -PathType Container
        })]
        [String]$Path = $PWD.ProviderPath,

        # Comment for the configuration, required if generated configuration shouldn't be used (when -SkipConfiguration parameter is provided).
        [String]$Description,

        # Technical Owner of the machine
        [ValidateSet('WINDOWS')]
        [string]$TechnicalOwner,

        # Thumbprint (CertificateId) of the certificate used by LCM.
        [String]$Thumbprint,

        # How often (in minutes) LCM attempts to obtain the configuration from the pull server.
        [ValidateRange(30, 44640)]
        [Int]$RefreshFrequencyMins,

        # How often (in minutes) LCM ensures that the configuration is in the desired state.
        [ValidateRange(15, 44640)]
        [Int]$ConfigurationModeFrequencyMins,

        # How long (in days) does the LCM need to keep dsc configuration status files.
        [ValidateRange(1, 10)]
        [Int]$StatusRetentionTimeInDays,

        # Switch to set LCM in RebootNodeIfNeeded mode - not recommended for production servers!
        [Alias('RebootIfNeeded')]
        [switch]$RebootNodeIfNeeded,
        
        # Switch to set LCM in PSDscAllowDomainUser mode - not recommended for production servers!
        [Alias('AllowDomainUser')]
        [switch]$PSDscAllowDomainUser,

        # Switch to set LCM in PSDscAllowPlainTextPassword mode - not recommended for production servers!
        [Alias('AllowPlainTextPassword')]
        [switch]$PSDscAllowPlainTextPassword,

        # Switch to prevent generating MOF for nodes that are not yet controlled with DSC.
        [switch]$SkipConfiguration,

        # Refresh mode of LCM. Possible values: Pull, Push, Disabled.
        [ValidateSet(
                'Pull',
                'Push',
                'Disabled'
        )]
        [String]$RefreshMode,

        # Configuration mode of LCM. Possible values: ApplyAndAutoCorrect, ApplyAndMonitor, ApplyOnly
        [ValidateSet(
                'ApplyAndAutoCorrect',
                'ApplyAndMonitor',
                'ApplyOnly'
        )]
        [String]$ConfigurationMode,

        # Debug mode of LCM. Possible values: None, All, ForceModuleImport
        [ValidateSet(
                'None',
                'All',
                'ForceModuleImport'
        )]
        [String]$DebugMode,
        
        # Pull Server that node is using.
        [String]$PullServer,

        # Action after mid-config reboot. Possible values: ContinueConfiguration, StopConfiguration
        [ValidateSet(
                'ContinueConfiguration',
                'StopConfiguration'
        )]
        [String]$ActionAfterReboot,


        # Additional sections for metadata in the form of a hashtable
        [Hashtable]$Sections,

        # Merge strategy for sections. Merge (default): combine the given data with the existing data. Replace: Replace metadata with given data in hashtable.
        [ValidateSet(
            'Merge',
            'Replace'
        )]
        [String]$SectionUpdatePreference = 'Merge'
    )

    # We want to update the file - so it has to exist...
    $filePath = "$Path\$ComputerName.psd1"

    try {
        $allData = Import-PowerShellDataFile -Path $filePath -ErrorAction Stop
    } catch {
        throw "Failed to read file $filePath - $_"
    }

    $updateSections = @{}
    if ($allData.Keys.Count -gt 1) {
        foreach ($key in $allData.Keys.Where({$_ -ne 'AllNodes'})) {
            $updateSections[$key] = $allData.$key
        }
    }

    Function Update-ConfigurationValue {
        <#
            .SYNOPSIS
            Internal function to update hashtable. Output is a scriptblock which can be executed to update the values in the hashtable.
        #>
        [CmdletBinding(SupportsShouldProcess)]
        [OutputType([scriptblock])]
        param (
            [Parameter(Mandatory)]
            [hashtable]$Reference,

            [Parameter(Mandatory)]
            $Item,

            [Parameter(Mandatory)]
            $ItemName,

            [Parameter(Mandatory)]
            [hashtable]$Sections
        )

        foreach($subKey in $Item.Keys) {
            try{
                $typeFullName = $Item.$subKey.GetType().FullName
            }
            catch {
                Write-Verbose $_
            }
            
            if($typeFullName -in 'System.Collections.Hashtable', 'System.Object[]' -and $item.$subkey[0].GetType().FullName -eq 'System.Collections.Hashtable') {
                Update-ConfigurationValue -Reference $Reference -Item $item.$subkey -ItemName "$ItemName.$subKey" -Sections $Sections
            }
            else {
                # Used inline scriptblock as ItemName can contain multiple levels of properties and we need to access those even though they are in a single string
                $accessProperty = '$Sections.{0}.{1}' -f $ItemName, $subKey
                $getNewValueScript = [scriptblock]::Create($accessProperty)
            
                if($updatedValue = $getNewValueScript.InvokeReturnAsIs()) {
                    $getnewValueType = ([scriptblock]::Create("$accessProperty.GetType()")).Invoke().FullName

                    $isArray = $false
                    if($getnewValueType -eq 'System.Object[]') {
                        [array]$updatedValue += $Item.$subKey
                        $isArray = $true
                    }
                    
                    if($PSCmdlet.ShouldProcess('ConfigurationData', "Set $accessProperty to $updatedValue")) {
                        if($isArray) {
                            $setProperty = ('$updateSections.{0}.Foreach({{$_.{1} += {2} }})' -f $ItemName, $subKey, $accessProperty)
                        }
                        else {
                            $setProperty = ('$updateSections.{0}.Foreach({{$_.{1} = {2} }})' -f $ItemName, $subKey, $accessProperty)
                        }
                        $setProperty
                    }
                }
            }
        }
    }

    if($SectionUpdatePreference -eq 'Merge') {
        $setNewValueScript = foreach ($key in $Sections.Keys.Where({$_ -ne 'AllNodes'})) {
            Update-ConfigurationValue -Reference $updateSections -Item $updateSections[$key] -ItemName $key -Sections $Sections
        }

        [scriptblock]::Create($setNewValueScript -join "`r`n").Invoke()
    }
    elseif($SectionUpdatePreference -eq 'Replace') {
        foreach ($key in $Sections.Keys.Where({$_ -ne 'AllNodes'})) {
            $updateSections[$key] = $Sections.$key
        }
    }

    $currentData = $allData.AllNodes[0]

    # We need to update certain parameters: if something is not specified we use information from the file. For RoleName we just modify collection based on -(Add|Remove)Role
    # Creating hash table that will be used to call New-OPDscLcmConfigurationFile - first mandatory parameters...
    
    $splat = @{
        ErrorAction = 'Stop'
        ComputerName = $ComputerName
        Path = $Path
    }

    $splat.RoleName = 
    if ($AddRole -or $RemoveRole) {
        @($currentData.RoleName | Where-Object { $_ -notIn $RemoveRole -and $_ -notIn $AddRole }) + $AddRole | Sort-Object
    } else {
        $currentData.RoleName | Sort-Object
    }

    $splat.RefreshMode = 
    if ($RefreshMode) {
        $RefreshMode
    } else {
        $currentData.RefreshMode
    }

    if ($RefreshFrequencyMins) {
        $splat.RefreshFrequencyMins = $RefreshFrequencyMins
    } elseif ($currentData.Contains('RefreshFrequencyMins')) {
        $splat.RefreshFrequencyMins = $currentData.RefreshFrequencyMins
    }

    $splat.ConfigurationMode = 
    if ($ConfigurationMode) {
        $ConfigurationMode
    } else {
        $currentData.ConfigurationMode
    }

    if ($ConfigurationModeFrequencyMins) {
        $splat.ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
    } elseif ($currentData.Contains('ConfigurationModeFrequencyMins')) {
        $splat.ConfigurationModeFrequencyMins = $currentData.ConfigurationModeFrequencyMins
    }

    if ($StatusRetentionTimeInDays) {
        $splat.StatusRetentionTimeInDays = $StatusRetentionTimeInDays
    } elseif ($currentData.Contains('StatusRetentionTimeInDays')) {
        $splat.StatusRetentionTimeInDays = $currentData.StatusRetentionTimeInDays
    }

    $splat.DebugMode = 
    if ($DebugMode) {
        $DebugMode
    } else {
        $currentData.DebugMode
    }

    $splat.PSDscAllowDomainUser = 
    if ($PSBoundParameters.ContainsKey('PSDscAllowDomainUser')) {
        $PSDscAllowDomainUser
    } else {
        $currentData.PSDscAllowDomainUser
    }
    
    $splat.PSDscAllowPlainTextPassword = 
    if ($PSBoundParameters.ContainsKey('PSDscAllowPlainTextPassword')) {
        $PSDscAllowPlainTextPassword
    } else {
        $currentData.PSDscAllowPlainTextPassword
    }
    
    $splat.RebootNodeIfNeeded = 
    if ($PSBoundParameters.ContainsKey('RebootNodeIfNeeded')) {
        $RebootNodeIfNeeded
    } else {
        $currentData.RebootNodeIfNeeded
    }

    $splat.Thumbprint = 
    if ($Thumbprint) {
        $Thumbprint
    } else {
        $currentData.CertificateID
    }

    if ($Description) {
        $splat.Description = $Description
    }

    if ($TechnicalOwner) {
        $splat.TechnicalOwner = $TechnicalOwner
    }

    if ($PullServer) {
        $splat.PullServer = $PullServer
    } elseif ($currentData.Contains('PullServer')) {
        $splat.PullServer = $currentData.PullServer
    }

    if ($ActionAfterReboot) {
        $splat.ActionAfterReboot = $ActionAfterReboot
    } elseif ($currentData.Contains('ActionAfterReboot')) {
        $splat.ActionAfterReboot = $currentData.ActionAfterReboot
    }

    if ($PSBoundParameters.ContainsKey('SkipConfiguration')) {
        $splat.SkipConfiguration = $SkipConfiguration
    } elseif ($currentData.Contains('SkipConfiguration')) {
        $splat.SkipConfiguration = $currentData.SkipConfiguration
    }
    
    
    if ($updateSections.Keys.Count) {
        $splat.Sections = $updateSections
    }

    if ($PSCmdlet.ShouldProcess(
            $filePath,
            "Save LCM configuration for $ComputerName"
    )) {
        try {
            New-OPDscLcmConfigurationFile @splat
        } catch {
            throw "Failed to save information for $ComputerName to $filePath - $_"
        }
    }
}
