<#
.SYNOPSIS
    Remove Disable IPv6 Registry Setting
.DESCRIPTION
    This script removes the Disable IPv6 configuration by calling the deployment script with Uninstall parameter
    This will re-enable IPv6 to its default Windows state
.NOTES
    Author: Generated Script
    Date: 2025-10-29
    Removal Method: Calls Deploy script with Uninstall parameter
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$LogPath = "$env:TEMP\DisableIPv6_Removal.log"
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================
$deployScriptName = "Deploy-RegistrySetting_DisableIPv6.ps1"
# ============================================================================

# Function to write log messages
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogPath -Value $logMessage
}

try {
    Write-Log "=========================================="
    Write-Log "Disable IPv6 Configuration Removal"
    Write-Log "This will re-enable IPv6 to default state"
    Write-Log "=========================================="

    # Method 1: Use the Deploy script with Uninstall parameter (recommended)
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $deployScript = Join-Path -Path $scriptPath -ChildPath $deployScriptName

    if (Test-Path $deployScript) {
        Write-Log "Calling deployment script with Uninstall mode..."
        & $deployScript -DeploymentType 'Uninstall' -LogPath $LogPath
        $exitCode = $LASTEXITCODE

        Write-Log "=========================================="
        Write-Log "Removal completed with exit code: $exitCode"
        Write-Log "=========================================="

        exit $exitCode
    }
    else {
        throw "Deploy script not found: $deployScript"
    }
}
catch {
    Write-Log "=========================================="
    Write-Log "Removal failed: $($_.Exception.Message)"
    Write-Log "=========================================="
    exit 1
}
