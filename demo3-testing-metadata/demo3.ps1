#region DPS

throw "Hey, Dory! Forgot to use F8?"

#endregion

# The need for metadata
Get-SmbShare -Name Meta -ErrorAction SilentlyContinue | Remove-SmbShare -Confirm:$false
Remove-Item C:\DSCFileServer\ -Recurse -ErrorAction SilentlyContinue
$scriptRoot = "$repoLocation\demo3-testing-metadata"

# A look at the classes for our metadata
ise "$scriptRoot\Partial\FileServer.classes.ps1"


# A look at the script used for testing:
ise "$scriptRoot\PreBuildTests\LCM\ConfigurationData.Tests.ps1"


# Now we can run the tests against our configuration
Invoke-Pester -Script @{
    Path = "$scriptRoot\PreBuildTests\LCM\ConfigurationData.Tests.ps1" 
    Parameters = @{
        Path = "$scriptRoot\ConfigurationData\$(hostname).psd1" 
        SourcePath = $scriptRoot
    }
}

# What happens if we mess up the configuration?
ise "$scriptRoot\ConfigurationData\$(hostname)-broken.psd1"
Invoke-Pester -Script @{
    Path = "$scriptRoot\PreBuildTests\LCM\ConfigurationData.Tests.ps1"
    Parameters = @{
        Path = "$scriptRoot\ConfigurationData\$(hostname)-broken.psd1" 
        SourcePath = $scriptRoot
    }
}

# Partial configurations themselves are tested as well
ise "$scriptRoot\PreBuildTests\Partial\Partial.Tests.ps1"

# Test results:
Invoke-Pester -Script @{
    Path = "$scriptRoot\PreBuildTests\Partial\Partial.Tests.ps1" 
    Parameters = @{
        Path = "$scriptRoot\Partial\FileServer.ps1" 
        SourcePath = $scriptRoot
    }
}
