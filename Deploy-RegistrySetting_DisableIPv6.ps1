<#
.SYNOPSIS
    Deploy Disable IPv6 Registry Setting
.DESCRIPTION
    This script configures Windows 11 to disable IPv6 by setting the DisabledComponents registry value
.NOTES
    Author: Generated Script
    Date: 2025-10-29
    Registry: HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters
    Value: DisabledComponents = 0xFF (Disable all IPv6 components)
    Reference: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [string]$DeploymentType = 'Install',

    [Parameter()]
    [string]$LogPath = "$env:TEMP\DisableIPv6_Deployment.log"
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================
$applicationName = "Disable IPv6 Configuration"
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$registryValueName = "DisabledComponents"
$registryValueData = 0xFF  # Disable all IPv6 components
$registryValueType = "DWord"
# ============================================================================

# Function to write log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage
}

# ============================================================================
# DEPLOYMENT FUNCTIONS
# ============================================================================

# Function to install (disable IPv6)
function Install-Application {
    try {
        Write-Log "Installing $applicationName..."
        Write-Log "Registry Path: $registryPath"
        Write-Log "Registry Value: $registryValueName = $registryValueData (0xFF)"

        # Ensure the registry path exists
        if (-not (Test-Path $registryPath)) {
            Write-Log "Creating registry path: $registryPath"
            New-Item -Path $registryPath -Force | Out-Null
        }

        # Set the DisabledComponents registry value
        Write-Log "Setting registry value to disable IPv6..."
        New-ItemProperty -Path $registryPath `
            -Name $registryValueName `
            -Value $registryValueData `
            -PropertyType $registryValueType `
            -Force | Out-Null

        # Verify the setting was applied
        $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue
        if ($currentValue.$registryValueName -eq $registryValueData) {
            Write-Log "IPv6 has been successfully disabled"
            Write-Log "Current value: $($currentValue.$registryValueName) (0x$([Convert]::ToString($currentValue.$registryValueName, 16).ToUpper()))"
            Write-Log "NOTE: A system reboot is required for this change to take full effect"

            # Return 3010 to indicate reboot required
            return 3010
        }
        else {
            throw "Registry value was set but verification failed"
        }
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}

# Function to uninstall (re-enable IPv6)
function Uninstall-Application {
    try {
        Write-Log "Uninstalling $applicationName..."
        Write-Log "Re-enabling IPv6 by removing registry setting..."

        # Check if the registry path exists
        if (Test-Path $registryPath) {
            # Remove the DisabledComponents registry value
            $currentValue = Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue

            if ($null -ne $currentValue) {
                Write-Log "Removing registry value: $registryValueName"
                Remove-ItemProperty -Path $registryPath `
                    -Name $registryValueName `
                    -Force -ErrorAction SilentlyContinue

                Write-Log "IPv6 has been re-enabled (default Windows behavior)"
                Write-Log "NOTE: A system reboot is required for this change to take full effect"

                # Return 3010 to indicate reboot required
                return 3010
            }
            else {
                Write-Log "Registry value not found - IPv6 is already enabled"
                return 0
            }
        }
        else {
            Write-Log "Registry path not found - IPv6 is already enabled"
            return 0
        }
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}

# Function to repair (reapply IPv6 disable setting)
function Repair-Application {
    try {
        Write-Log "Repairing $applicationName..."
        Write-Log "Reapplying IPv6 disable configuration..."

        # Call Install function to reapply the setting
        return Install-Application
    }
    catch {
        Write-Log "ERROR: $($_.Exception.Message)"
        throw
    }
}

# ============================================================================
# MAIN DEPLOYMENT LOGIC
# ============================================================================

try {
    Write-Log "=========================================="
    Write-Log "$applicationName Deployment"
    Write-Log "Deployment Type: $DeploymentType"
    Write-Log "=========================================="

    # Get script directory
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

    $exitCode = 0

    # Process deployment
    switch ($DeploymentType) {
        'Install' {
            $exitCode = Install-Application
        }
        'Uninstall' {
            $exitCode = Uninstall-Application
        }
        'Repair' {
            $exitCode = Repair-Application
        }
    }

    # Return appropriate exit code
    if ($exitCode -eq 3010) {
        Write-Log "=========================================="
        Write-Log "Deployment completed - Reboot required"
        Write-Log "=========================================="
        exit 3010
    }
    elseif ($exitCode -ne 0) {
        Write-Log "=========================================="
        Write-Log "Deployment failed with exit code: $exitCode"
        Write-Log "=========================================="
        exit $exitCode
    }
    else {
        Write-Log "=========================================="
        Write-Log "Deployment completed successfully"
        Write-Log "=========================================="
        exit 0
    }
}
catch {
    Write-Log "=========================================="
    Write-Log "Deployment failed: $($_.Exception.Message)"
    Write-Log "=========================================="
    exit 1
}
