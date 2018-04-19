function New-OPDscLcmConfigurationFile {
    <#
            .Synopsis
            Function used to generate file (ComputerName.psd1) used when generating MOF documents for Local Configuration Manager (LCM)

            .Description
            As part of automating processes around DSC we want to keep LCM configuration (in form of ConfigurationData files) in the repository.
            This function can be used to generate psd1 in consistent manner.

            .Example
            New-OPDscLcmConfigurationFile -ComputerName server1 -Path D:\scripts\DscLcm\ConfigurationData
    #>

    [CmdletBinding(
            DefaultParameterSetName = 'withoutsections',
            SupportsShouldProcess,
            ConfirmImpact = 'Low'
    )]
    [OutputType([System.IO.FileInfo])]
    param (
        # Name of the computer for which configuration will be generated.
        [Parameter(
                Mandatory
        )]
        [String]$ComputerName,

        # Name of the role(s) that should be applied to the configured computer.
        [String[]]$RoleName,

        # Path to directory where the configuration file should be stored (file name will be appended automagically).
        [ValidateScript({
                    Test-Path -LiteralPath $_ -PathType Container
        })]
        [String]$Path = $PWD.ProviderPath,

        # Comment for the configuration, required if generated configuration shouldn't be used (when -SkipConfiguration parmaeter is provided).
        [Parameter(
                Mandatory,
                ParameterSetName = 'withoutsections'
        )]
        [Parameter(
                ParameterSetName = 'withsections'
        )]
        [String]$Description,

        # Technical Owner of the machine
        [Parameter(
                Mandatory,
                ParameterSetName = 'withoutsections'
        )]
        [Parameter(
                ParameterSetName = 'withsections'
        )]
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
        [Int]$StatusRetentionTimeInDays = 1,
        
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

        # Refresh mode of LCM. Possible values: Pull (default), Push, Disabled.
        [ValidateSet(
                'Pull',
                'Push',
                'Disabled'
        )]
        [String]$RefreshMode = 'Pull',

        # Configuration mode of LCM. Possible values: ApplyAndAutoCorrect (default), ApplyAndMonitor, ApplyOnly
        [ValidateSet(
                'ApplyAndAutoCorrect',
                'ApplyAndMonitor',
                'ApplyOnly'
        )]
        [String]$ConfigurationMode = 'ApplyAndMonitor',

        # Debug mode of LCM. Possible values: None (default), All, ForceModuleImport
        [ValidateSet(
                'None',
                'All',
                'ForceModuleImport'
        )]
        [String]$DebugMode = 'None',
        
        # Pull Server that node is using.
        [ValidateSet(
                'Test',
                'Prod'
        )]
        [String]$PullServer = 'Prod',

        # Action after mid-config reboot. Possible values: ContinueConfiguration, StopConfiguration
        [ValidateSet(
                'ContinueConfiguration',
                'StopConfiguration'
        )]
        [String]$ActionAfterReboot,

        # Additional sections, such as NodeConfig, NetConfig in a form of hashtable
        [Parameter(
                Mandatory,
                ParameterSetName = 'withsections'
        )]
        [Hashtable]$Sections
    )

    function Add-Line {
        [CmdletBinding(
                DefaultParameterSetName = 'line'
        )]
        param (
            [Parameter(Mandatory)]
            [System.Text.StringBuilder]$StringBuilder,
            
            [Parameter(ParameterSetName = 'line', Mandatory)]
            [String]$Line,
            
            [Parameter(ParameterSetName = 'Item', Mandatory)]
            [string]$Key,
            
            [Parameter(ParameterSetName = 'Item', Mandatory)]
            [AllowEmptyString()]
            $Value,

            [Parameter(Mandatory)]
            [int]$IndentLevel
        )
        
        if ($Key) {
            
            $itemCount = 0
            if ($Value -is [array]){
                $itemCount = $Value.Count -1
                $itemType = $Value[0]
            }
            else {
                $itemType = $Value
            }
            # Get data type from nested objects, so we can write the proper datatype
            # Allowing the nested datatype to be an array of objects
            # This will produce '{0}' for single string and '{0}', '{1}', '{2}' for an array of three
            $valueTemplate = Switch ($itemType) {
                {$_ -eq $null}      { "" }
                {$_ -is [int]}      {   "{" + (0..$itemCount -join "}, {")   + "}"  }
                {$_ -is [boolean]}  { "`${" + (0..$itemCount -join "}, `${") + "}"  }
                {$_ -is [datetime]} {  "'{" + (0..$itemCount -join ":s}', '{") + ":s}'" }
                default             {  "'{" + (0..$itemCount -join "}', '{") + "}'" }
            }
            if ($Value -is [array])  {
                $valueTemplate = '@(' + $valueTemplate + ')'
            }
            $Line = ('{0} = ' -f $Key) + ($valueTemplate -f $Value)
        }
        $null = $StringBuilder.AppendLine("$('    ' * $IndentLevel)$Line")
    }
    Function Add-PowerShellDataItem {
        Param(
            [Parameter(Mandatory)]
            [System.Text.StringBuilder]$StringBuilder,
        
            [Parameter(Mandatory)]
            [String]$Key,
        
            [Parameter(Mandatory)]
            $ConfigurationDataItem,
            
            [Parameter()]
            [int]$IndentLevel
            
        )
           
        $lineSplat = @{
            StringBuilder = $stringBuilder
            indentLevel = $indentLevel
        }
        if($ConfigurationDataItem -is [System.Array] -and $ConfigurationDataItem[0] -is [Hashtable]) {
                    
            Add-Line @lineSplat -Line "$Key = @("
                    
            $lineSplat.indentLevel++
            # in the sort-object there is a foreach loop that will produce a string containing keys and values in a sorted manner, with Name always first.
            $ConfigurationDataItem | Sort-Object -Property {$_['Name'] + '          ' + ($(foreach ($sortItemKey in ($_.Keys | Sort-Object)){$sortItemKey + '=' + $_[$sortItemKey] + '                   '}))} | ForEach-Object {
                        
                Add-Line @lineSplat -Line "@{"
                $nestedConfigurationDataItem = $_
                        
                $lineSplat.indentLevel++
                if ($_.ContainsKey('Name')){
                    Add-PowerShellDataItem @lineSplat -ConfigurationDataItem $nestedConfigurationDataItem['Name'] -Key 'Name'
                }
                $_.Keys | Where-Object {$_ -ne 'Name'} | Sort-Object | ForEach-Object {
                    Add-PowerShellDataItem @lineSplat -ConfigurationDataItem $nestedConfigurationDataItem[$_] -Key $_
                }
                $lineSplat.indentLevel--
                
                Add-Line @lineSplat -Line "}"
            }
            $lineSplat.indentLevel--
                    
            Add-Line @lineSplat -Line ")"
        }
        else {
            Add-Line @lineSplat -Key $Key -Value $configurationDataItem
        }
    }
    
    $stringBuilder = New-Object System.Text.StringBuilder
    $lineSplat = @{
        StringBuilder = $stringBuilder
        indentLevel = 0
    }

    Add-Line @lineSplat -Line '@{'

    $lineSplat.indentLevel++
    
    $RoleName = $RoleName | Sort-Object -Unique
    if (-not $RoleName) {
        throw "Configuration needs at least one role!"
    }
    $AllNodes = @{
        NodeName = $ComputerName
        RoleName = $RoleName
        RefreshMode = $RefreshMode
        ConfigurationMode = $ConfigurationMode
        DebugMode = $DebugMode
        CertificateId = $Thumbprint
        RebootNodeIfNeeded = [bool]$RebootNodeIfNeeded
        StatusRetentionTimeInDays = $StatusRetentionTimeInDays 
    }
    if($RefreshMode -eq 'Pull') {
        $AllNodes.PullServer = $PullServer
    }
    if($PSDscAllowDomainUser) {
        $AllNodes.PSDscAllowDomainUser = [bool]$PSDscAllowDomainUser
    }
    if($PSDscAllowPlainTextPassword) {
        $AllNodes.PSDscAllowPlainTextPassword = [bool]$PSDscAllowPlainTextPassword
    }
    if ($SkipConfiguration) {
        $AllNodes.SkipConfiguration = $true
    }
    if ($RefreshFrequencyMins) {
        $AllNodes.RefreshFrequencyMins = $RefreshFrequencyMins 
    }
    if ($ConfigurationModeFrequencyMins) {
        $AllNodes.ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins 
    }
    if ($ActionAfterReboot) {
        $AllNodes.ActionAfterReboot = $ActionAfterReboot
    }
    
    Add-PowerShellDataItem @lineSplat -ConfigurationDataItem @($AllNodes) -Key 'AllNodes'
    
    if (-not $Sections) {
        $Sections = @{}
    }
    
    if (-not $Sections.ContainsKey('ExternalConfiguration')){
        if (-not $Description -or -not $TechnicalOwner){
            throw 'Technical Owner or Description is not provided'
        }
        $Sections['ExternalConfiguration'] = @(
            @{
                Cname = ''
                Description = $Description
                OtherCnames = @()
                TechnicalOwner = $TechnicalOwner
            }
        )
    }
    else {
        if ($TechnicalOwner) {
            $Sections['ExternalConfiguration'][0].TechnicalOwner = $TechnicalOwner
        }
        if (-not $Sections['ExternalConfiguration'][0].TechnicalOwner) {
            throw 'No Technical owner defined for this server'
        }

        if ($Description) {
            $Sections['ExternalConfiguration'][0].Description = $Description
        }
        if (-not $Sections['ExternalConfiguration'][0].Description) {
            throw 'No Description defined for this server'
        }
    }
    
    if (-not $Sections.ContainsKey('NodeConfig')){
        $Sections['NodeConfig'] = @(
            @{
                AdminList = @('ServerAdmins')
                TimeZone = 'W. Europe Standard Time'
            }
        )
    }
    
    foreach ($key in $($Sections.Keys.Where({$_ -NE 'AllNodes'})| Sort-Object)) {
        Add-PowerShellDataItem @lineSplat -ConfigurationDataItem $Sections[$key] -Key $key
    }
        
    $lineSplat.indentLevel--
    Add-Line @lineSplat -Line '}'
    $filePath = "$Path\$ComputerName.psd1"
    if ($PSCmdlet.ShouldProcess(
            $filePath,
            "Save LCM configuration for $ComputerName"
    )) {
        try {
            $stringBuilder.ToString() | Set-Content -LiteralPath $filePath -Encoding UTF8 -Force -ErrorAction Stop
            Get-Item -LiteralPath $filePath -ErrorAction Stop
        } catch {
            throw "Failed to save information for $ComputerName to $filePath - $_"
        }
    }
}