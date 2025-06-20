# EntraSuiteLAB Project Guidelines for GitHub Copilot

## Project Overview
EntraSuiteLAB is a PowerShell module that provides an automation solution for creating Entra Suite lab environments. It interacts with Microsoft Graph API to provision and configure Entra ID, Global Secure Access, Entra Identity Governance.

## Module Structure
```
EntraSuiteLAB/
├── source/
│   ├── Classes/            # Class definitions (numbered for load order)
│   ├── Enum/               # Enumeration definitions
│   ├── Private/            # Internal functions not exposed to users
│   │   └── Initialize-Config.ps1  # Module configuration initialization
│   ├── Public/             # Functions exported from the module
│   ├── en-US/              # Localization files
│   └── EntraSuiteLAB.psd1  # Module manifest
├── tests/                  # Test files
│   ├── QA/                 # Quality assurance tests
│   └── Unit/               # Unit tests
├── build.ps1               # Build script
└── build.yaml              # Build configuration
```

## Coding Standards

### Logging
- **Always use PSFramework for logging** instead of Write-Verbose, Write-Warning, etc.
- Use Write-PSFMessage for all logging with appropriate levels:

```powershell
# Examples of correct logging
Write-PSFMessage -Level Verbose -Message "Starting process for $Param"
Write-PSFMessage -Level Warning -Message "Resource not found" -Tag 'NotFound'
Write-PSFMessage -Level Error -Message "Operation failed" -ErrorRecord $_
```

- Common levels to use:
  - Verbose: Detailed tracing information
  - Debug: Debugging information
  - Information: Normal informational messages
  - Warning: Non-critical issues
  - Error: Errors that allow the function to continue
  - Critical: Critical errors that stop execution

### Configuration Management
- **All object names and configuration settings must be defined in Initialize-Config.ps1**
- Use Set-PSFConfig to define configuration items:

```powershell
# Example configuration format
Set-PSFConfig -Module EntraSuiteLAB -Name 'Area.ConfigName' -Value $defaultValue -Initialize -Validation $validationType -Description 'Description of this setting' -AllowDelete
```

- Access configuration using Get-PSFConfigValue:

```powershell
$configValue = Get-PSFConfigValue -FullName 'EntraSuiteLAB.Area.ConfigName'
```

### Microsoft Graph API Calls
- **Always use Invoke-EntraSuiteGraphRequest** for all Microsoft Graph API interactions
- Avoid direct calls to Invoke-MgGraphRequest or other methods
- Example usage:

```powershell
# Correct way to call Microsoft Graph API
$users = Invoke-EntraSuiteGraphRequest -Method GET -Uri '/users' -All

# Creating resources
$newGroup = Invoke-EntraSuiteGraphRequest -Method POST -Uri '/groups' -Body @{
    displayName = "Marketing Team"
    mailNickname = "marketing"
    mailEnabled = $false
    securityEnabled = $true
}

# Updating resources
Invoke-EntraSuiteGraphRequest -Method PATCH -Uri "/users/$userId" -Body @{
    officeLocation = "Building 1, Floor 2"
}
```

### Function Templates

#### Function Template
```powershell
function Verb-Noun
{
    <#
    .SYNOPSIS
    Short description of function purpose.

    .DESCRIPTION
    Detailed description of function purpose and functionality.

    .PARAMETER ParameterName
    Description of parameter.

    .EXAMPLE
    Verb-Noun -Parameter Value
    Example description.

    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([Type])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Type]
        $ParameterName
    )

    begin
    {
        Write-PSFMessage -Level Verbose -Message "Beginning $($MyInvocation.MyCommand)"
    }

    process
    {
        if ($PSCmdlet.ShouldProcess("Target", "Operation"))
        {
            try
            {
                # Main function logic
                Write-PSFMessage -Level Verbose -Message "Processing $ParameterName"
            }
            catch
            {
                Write-PSFMessage -Level Error -Message "Error in $($MyInvocation.MyCommand)" -ErrorRecord $_
                throw $_
            }
        }
    }

    end
    {
        Write-PSFMessage -Level Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
```

## Configuration Structure

Configure all EntraSuiteLAB settings in Initialize-Config.ps1 with the following organization:

```powershell
# Project settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'Project.Name' -Value 'EntraSuiteLAB' -Initialize -Validation string -Description 'The project name' -AllowDelete

# Entra ID settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'EntraID.Setting1' -Value 'Default1' -Initialize -Validation string -Description 'Description' -AllowDelete

# Global Secure Access settings
Set-PSFConfig -Module EntraSuiteLAB -Name 'GlobalSecureAccess.Enabled' -Value $true -Initialize -Validation boolean -Description 'Enable Global Secure Access provisioning' -AllowDelete

# Other settings organized by functional area
Set-PSFConfig -Module EntraSuiteLAB -Name 'Area.Setting' -Value $default -Initialize -Validation $type -Description 'Description' -AllowDelete
```

## Best Practices

1. **Use meaningful parameter names** that describe the purpose or content.
2. **Include Verb-Noun format** for all function names following PowerShell approved verbs.
3. **Include proper documentation** with every function (synopsis, description, parameters, examples).
4. **Use appropriate error handling** with try/catch blocks and PSFramework error logging.
5. **Follow ShouldProcess pattern** for functions that change state.
6. **Specify OutputType** for all functions.
7. **Use proper parameter validation** attributes.
8. **Keep functions focused** - each function should do one thing well.
9. **Use Invoke-EntraSuiteGraphRequest** for all Microsoft Graph API interactions to ensure consistent logging, error handling, and response processing.

## Required Module Dependencies

The module requires:
- PSFramework (1.12.346 or higher)
- Microsoft.Graph.Authentication (2.20.0 or higher)

Reference these dependencies appropriately in your code.
