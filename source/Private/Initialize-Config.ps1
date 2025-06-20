# This file initializes the configuration for the EntraSuiteLAB module.

# Project settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'Project.Name' -Value 'EntraSuiteLAB' -Initialize -Validation string -Description 'The project name' -AllowDelete


# Entra ID settings


# Global Secure Access settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'GlobalSecureAccess.Enabled' -Value $true -Initialize -Validation bool -Description 'Enable Global Secure Access provisioning' -AllowDelete


# Others
