$allData = @(
    @{
        Par = 'One'
        Val = 'OldVal'
        Song = @(
            @{
                Title = 'My Title'
                Genre = 'Dance'
                Artist = @(
                    @{
                        Name = 'Armin'
                        Country = 'Netherlands'
                    }
                )
                Album = @(
                    @{
                        Producer = @{
                            Label = 'MyMother'
                            Country = 'Germany'
                            Nonsense = 'Approved'
                        }
                    }
                )
            }
        )
    }
)


$Sections = @{
    Song = @{
        Genre = 'House'
        Artist = @{
            Name = 'Armin van Buuren'
        }
        Album  = @{
            Producer = @{
                Label = 'NotMyMother'
            }
        }
    }
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
    [OutputType('Scriptblock')]
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
        if($Item.$subKey.GetType().FullName -eq 'System.Collections.Hashtable' -or $Item.$subKey.GetType().FullName -eq 'System.Object[]') {
            Update-ConfigurationValue -Reference $Reference -Item $item.$subkey -ItemName "$ItemName.$subKey" -Sections $Sections
        }
        else {
            $accessProperty = '$Sections.{0}.{1}' -f $ItemName, $subKey
            $getNewValueScript = [scriptblock]::Create($accessProperty)
            
            if($updatedValue = $getNewValueScript.InvokeReturnAsIs()) {
                if($PSCmdlet.ShouldProcess('ConfigurationData', "Set $accessProperty to $updatedValue")) {
                    $setProperty = ('$updateSections.{0}.Foreach({{$_.{1} = {2} }})' -f $ItemName, $subKey, $accessProperty)
                    $setProperty
                }
            }
        }
    }
}

$setNewValueScript = foreach ($key in $Sections.Keys.Where({$_ -ne 'AllNodes'})) {
    Update-ConfigurationValue -Reference $updateSections -Item $updateSections[$key] -ItemName $key -Sections $Sections
}

[scriptblock]::Create($setNewValueScript -join "`r`n").Invoke()



$updateSections