<#
.SYNOPSIS
    Builds Intune package for Disable IPv6 deployment
.DESCRIPTION
    This script packages the deployment scripts into an .intunewin file for Intune deployment
.NOTES
    Author: Generated Script
    Date: 2025-10-29
    Requires: IntuneWinAppUtil.exe (located at C:\Intune\IntuneWinAppUtil.exe)
    Download from: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION SECTION
# ============================================================================
$setupFile = "Deploy-RegistrySetting_DisableIPv6.ps1"
$intuneToolPath = "C:\Intune\IntuneWinAppUtil.exe"

$requiredFiles = @(
    "Deploy-RegistrySetting_DisableIPv6.ps1",
    "Detect-RegistrySetting_DisableIPv6.ps1",
    "Remove-RegistrySetting_DisableIPv6.ps1"
)
# ============================================================================

try {
    Write-Host "=========================================="
    Write-Host "Building Intune Package for Disable IPv6"
    Write-Host "=========================================="

    # Define paths
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $sourceFolder = $scriptPath
    $outputFolder = Join-Path -Path $scriptPath -ChildPath "Output"

    # Validate IntuneWinAppUtil.exe exists
    if (-not (Test-Path $intuneToolPath)) {
        throw "IntuneWinAppUtil.exe not found at: $intuneToolPath`nPlease download from: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
    }

    # Validate source files exist
    Write-Host "`nValidating required files..."
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $sourceFolder -ChildPath $file
        if (Test-Path $filePath) {
            Write-Host "  [OK] $file"
        }
        else {
            Write-Host "  [MISSING] $file"
            $missingFiles += $file
        }
    }

    if ($missingFiles.Count -gt 0) {
        throw "Missing required files: $($missingFiles -join ', ')"
    }

    # Create output folder if it doesn't exist
    if (-not (Test-Path $outputFolder)) {
        Write-Host "`nCreating output folder: $outputFolder"
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Build the .intunewin package
    Write-Host "`nPackaging files..."
    Write-Host "Source folder: $sourceFolder"
    Write-Host "Setup file: $setupFile"
    Write-Host "Output folder: $outputFolder"

    $arguments = @(
        "-c", "`"$sourceFolder`""
        "-s", "`"$setupFile`""
        "-o", "`"$outputFolder`""
        "-q"
    )

    Write-Host "`nRunning IntuneWinAppUtil.exe..."
    $process = Start-Process -FilePath $intuneToolPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        # The tool creates the file without .ps1 extension
        $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($setupFile)
        $intunewinFile = Join-Path -Path $outputFolder -ChildPath "$baseFileName.intunewin"

        if (Test-Path $intunewinFile) {
            $fileInfo = Get-Item $intunewinFile
            Write-Host "`n=========================================="
            Write-Host "SUCCESS: Intune package created"
            Write-Host "Package location: $intunewinFile"
            Write-Host "Package size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB"
            Write-Host "=========================================="
            Write-Host "`nNext steps:"
            Write-Host "1. Review INTUNE_DEPLOYMENT.md for deployment instructions"
            Write-Host "2. Upload the .intunewin file to Microsoft Intune admin center"
            Write-Host "3. Configure detection script: Detect-RegistrySetting_DisableIPv6.ps1"
            exit 0
        }
        else {
            throw "Package creation completed but .intunewin file not found at: $intunewinFile"
        }
    }
    else {
        throw "IntuneWinAppUtil.exe failed with exit code: $($process.ExitCode)"
    }
}
catch {
    Write-Host "`n=========================================="
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "=========================================="
    exit 1
}
