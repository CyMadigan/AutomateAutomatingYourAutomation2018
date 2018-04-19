class NodeConfig {
    [String[]]
    $AdminList

    [String]
    [ValidateSet(
        'W. Europe Standard Time'
    )]
    $TimeZone
}