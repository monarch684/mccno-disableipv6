# Disable IPv6 - Intune Deployment Package

This repository contains a complete Microsoft Intune Win32 app deployment package for disabling IPv6 on Windows 10/11 devices via registry configuration.

## Overview

This deployment package configures Windows devices to disable all IPv6 components by setting the `DisabledComponents` registry value to `0xFF` (255). The configuration is deployed through Microsoft Intune as a Win32 application with proper detection and removal capabilities.

### Registry Configuration

- **Path:** `HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters`
- **Value:** `DisabledComponents`
- **Data:** `0xFF` (255 decimal) - Disables all IPv6 components
- **Type:** DWORD

### Important Notes

⚠️ **Reboot Required:** Changes take effect after a system reboot.

⚠️ **Microsoft Recommendation:** Disabling IPv6 is not recommended by Microsoft in most scenarios, as IPv6 is an integral component of Windows. Only disable IPv6 if you have a specific business or technical requirement.

## Files Included

| File | Description |
|------|-------------|
| **Deploy-RegistrySetting_DisableIPv6.ps1** | Main deployment script with Install/Uninstall/Repair functionality |
| **Detect-RegistrySetting_DisableIPv6.ps1** | Detection script for Intune compliance checking |
| **Remove-RegistrySetting_DisableIPv6.ps1** | Uninstallation wrapper script to re-enable IPv6 |
| **Build-IntunePackage.ps1** | Script to build the .intunewin package for Intune |
| **INTUNE_DEPLOYMENT.md** | Complete step-by-step deployment guide |
| **Output/Deploy-RegistrySetting_DisableIPv6.intunewin** | Pre-built Intune package (26.73 KB) |

## Quick Start

### Prerequisites

- Microsoft Intune admin center access
- Global Administrator or Intune Administrator role
- Windows 10 1607 or later on target devices
- IntuneWinAppUtil.exe (only needed if rebuilding package)

### Deployment Steps

1. **Download the package:**
   - Clone this repository or download the `.intunewin` file from the Output folder

2. **Upload to Intune:**
   - Go to https://intune.microsoft.com
   - Navigate to **Apps** > **Windows** > **Add** > **Windows app (Win32)**
   - Upload: `Output/Deploy-RegistrySetting_DisableIPv6.intunewin`

3. **Configure the app:**
   - **Install command:**
     ```
     powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySetting_DisableIPv6.ps1"
     ```
   - **Uninstall command:**
     ```
     powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySetting_DisableIPv6.ps1" -DeploymentType Uninstall
     ```

4. **Set detection rule:**
   - Use custom detection script
   - Upload: `Detect-RegistrySetting_DisableIPv6.ps1`

5. **Assign to groups:**
   - Assign to target device or user groups

For detailed deployment instructions, see [INTUNE_DEPLOYMENT.md](INTUNE_DEPLOYMENT.md)

## Testing Locally

Before deploying via Intune, you can test the scripts locally:

### Test Installation (Disable IPv6)
```powershell
.\Deploy-RegistrySetting_DisableIPv6.ps1 -DeploymentType Install
```

### Test Detection
```powershell
.\Detect-RegistrySetting_DisableIPv6.ps1
echo $LASTEXITCODE  # 0 = Disabled, 1 = Not Disabled
```

### Test Uninstallation (Re-enable IPv6)
```powershell
.\Deploy-RegistrySetting_DisableIPv6.ps1 -DeploymentType Uninstall
```

### Verify Configuration
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents"
```

## Rebuilding the Package

If you modify the scripts and need to rebuild the Intune package:

1. Ensure you have IntuneWinAppUtil.exe at `C:\Intune\IntuneWinAppUtil.exe`
   - Download from: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

2. Run the build script:
   ```powershell
   .\Build-IntunePackage.ps1
   ```

3. The new package will be created in the `Output/` directory

## DisabledComponents Values Reference

For reference, different values for the DisabledComponents registry entry:

| Hex Value | Decimal | Description |
|-----------|---------|-------------|
| 0x00 | 0 | Enable all IPv6 components (default) |
| 0x01 | 1 | Disable IPv6 on tunnel interfaces |
| 0x10 | 16 | Disable IPv6 on non-tunnel interfaces |
| 0x11 | 17 | Disable IPv6 on all non-tunnel interfaces and tunnel interfaces |
| 0x20 | 32 | Prefer IPv4 over IPv6 |
| **0xFF** | **255** | **Disable all IPv6 components (used in this package)** |

## Logs and Troubleshooting

### Log Locations

- **Deployment Log:** `%TEMP%\DisableIPv6_Deployment.log`
- **Removal Log:** `%TEMP%\DisableIPv6_Removal.log`
- **Intune Management Extension:** `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`

### Common Issues

**Issue:** Configuration applied but IPv6 still works
- **Solution:** Reboot the device. Registry changes require a restart to take effect.

**Issue:** Detection shows as "Not Installed" in Intune
- **Solution:** Verify the registry value is set correctly:
  ```powershell
  Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
  Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents"
  ```

For more troubleshooting steps, see [INTUNE_DEPLOYMENT.md](INTUNE_DEPLOYMENT.md#troubleshooting)

## Re-enabling IPv6

To re-enable IPv6:

1. **Via Intune:** Assign the app with **Uninstall** intent to the target groups
2. **Via Script:** Run `.\Deploy-RegistrySetting_DisableIPv6.ps1 -DeploymentType Uninstall`
3. **Manually:** Delete the registry value:
   ```powershell
   Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Force
   ```

**Note:** Reboot required after re-enabling IPv6.

## Exit Codes

The deployment script returns standard exit codes:

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success - No reboot required |
| 3010 | Success - Reboot required |
| 1 | Failure - See logs for details |

## Security Considerations

Before deploying this configuration, consider:

- Some Windows features may not function correctly with IPv6 disabled
- DirectAccess requires IPv6
- Some Microsoft services prefer IPv6
- Future applications may require IPv6

**Recommendation:** Consider using `DisabledComponents = 0x20` (32) to prefer IPv4 over IPv6 instead of completely disabling IPv6.

## References

- [Microsoft: Configure IPv6 in Windows](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows)
- [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool)
- [Microsoft Intune Documentation](https://learn.microsoft.com/en-us/mem/intune/)

## License

This project is provided as-is for use in enterprise environments.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Author

Generated with assistance from Claude Code.

---

**Version:** 1.0
**Last Updated:** 2025-10-29
**Tested On:** Windows 11 (22H2, 23H2)
