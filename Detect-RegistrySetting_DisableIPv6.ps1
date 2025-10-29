<#
.SYNOPSIS
    Detect Disable IPv6 Registry Setting
.DESCRIPTION
    This script detects whether IPv6 has been disabled via the DisabledComponents registry value
    Returns exit code 0 if disabled (installed), 1 if not disabled (not installed)
.NOTES
    Author: Generated Script
    Date: 2025-10-29
    Detection Method: Checks for DisabledComponents registry value = 0xFF
    Registry Path: HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters
#>

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$registryValueName = "DisabledComponents"
$expectedValue = 0xFF  # Value that indicates IPv6 is fully disabled
# ============================================================================

try {
    Write-Host "Detecting Disable IPv6 configuration..."
    Write-Host "Registry Path: $registryPath"
    Write-Host "Registry Value: $registryValueName"
    Write-Host "Expected Value: $expectedValue (0xFF - Disable all IPv6 components)"

    # Check if the registry path exists
    if (Test-Path $registryPath) {
        Write-Host "Registry path found: $registryPath"

        # Get the registry value
        $regValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue

        if ($null -ne $regValue) {
            $currentValue = $regValue.$registryValueName
            $hexValue = "0x$([Convert]::ToString($currentValue, 16).ToUpper())"

            Write-Host "Current value: $currentValue ($hexValue)"

            # Check if the value matches the expected value
            if ($currentValue -eq $expectedValue) {
                Write-Host "IPv6 is DISABLED (configuration detected)"
                Write-Host "Application is installed (exit code 0)"

                # Exit code 0 = Detected/Installed
                exit 0
            }
            else {
                Write-Host "IPv6 DisabledComponents value exists but is not set to disable all components"
                Write-Host "Expected: $expectedValue (0xFF), Found: $currentValue ($hexValue)"
                Write-Host "Application is not installed (exit code 1)"

                # Exit code 1 = Not Detected/Not Installed
                exit 1
            }
        }
        else {
            Write-Host "Registry value not found: $registryValueName"
            Write-Host "IPv6 is ENABLED (default Windows configuration)"
            Write-Host "Application is not installed (exit code 1)"

            # Exit code 1 = Not Detected/Not Installed
            exit 1
        }
    }
    else {
        Write-Host "Registry path not found: $registryPath"
        Write-Host "IPv6 is ENABLED (default Windows configuration)"
        Write-Host "Application is not installed (exit code 1)"

        # Exit code 1 = Not Detected/Not Installed
        exit 1
    }
}
catch {
    Write-Host "Error during detection: $($_.Exception.Message)"
    Write-Host "Application is not installed (exit code 1)"
    exit 1
}
