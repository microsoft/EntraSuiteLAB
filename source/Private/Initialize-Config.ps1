# This file initializes the configuration for the EntraSuiteLAB module.

# Logging settings
# Logs are written to this folder by default: Get-PSFConfigValue -FullName psframework.logging.filesystem.logpath | Invoke-Item

$paramSetPSFLoggingProvider = @{
    Name         = 'logfile'
    InstanceName = 'EntraSuiteLAB'
    FilePath     = 'C:\Temp\EntraSuiteLABLogs\EntraSuiteLAB-%Date%.csv'
    Enabled      = $true
    Wait         = $true
    IncludeModules = 'EntraSuiteLAB'
}
Set-PSFLoggingProvider @paramSetPSFLoggingProvider


# Project settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'Project.Name' -Value 'EntraSuiteLAB' -Initialize -Validation string -Description 'The project name' -AllowDelete


# Entra ID settings


# Global Secure Access settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'GlobalSecureAccess.Enabled' -Value $true -Initialize -Validation bool -Description 'Enable Global Secure Access provisioning' -AllowDelete


# Others
