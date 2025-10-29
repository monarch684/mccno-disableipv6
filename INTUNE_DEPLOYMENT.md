# Intune Deployment Guide - Disable IPv6

This guide provides step-by-step instructions for deploying the Disable IPv6 registry configuration via Microsoft Intune as a Win32 app.

## Package Information

**Package File:** `Deploy-RegistrySetting_DisableIPv6.intunewin`
**Location:** `Output/Deploy-RegistrySetting_DisableIPv6.intunewin`
**Registry Path:** `HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters`
**Registry Value:** `DisabledComponents = 0xFF`
**Detection Method:** Custom PowerShell script checking registry value

---

## What This Does

This deployment disables IPv6 on Windows 11 devices by setting the `DisabledComponents` registry value to `0xFF` (255 in decimal), which disables all IPv6 components according to Microsoft documentation.

**Microsoft Reference:** [Configure IPv6 in Windows](https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows)

**Reboot Requirement:** Yes - A system reboot is required for the IPv6 configuration change to take full effect.

---

## Prerequisites

- Access to Microsoft Intune admin center
- Global Administrator or Intune Administrator role
- The `.intunewin` package file from the Output folder
- Target devices running Windows 10 1607 or later (tested on Windows 11)

---

## Deployment Steps

### 1. Upload the Application Package

1. Sign in to the **Microsoft Intune admin center** (https://intune.microsoft.com)
2. Navigate to **Apps** > **Windows** > **Add**
3. Select **Windows app (Win32)** from the app type dropdown
4. Click **Select**

### 2. App Information

Click **Select app package file** and upload:
- **File:** `Deploy-RegistrySetting_DisableIPv6.intunewin`

Fill in the following details:

| Field | Value |
|-------|-------|
| **Name** | Disable IPv6 Configuration |
| **Description** | Disables IPv6 on Windows devices by setting the DisabledComponents registry value to 0xFF |
| **Publisher** | IT Department |
| **App version** | 1.0 |
| **Category** | Computer Management |
| **Show this as a featured app in the Company Portal** | No |
| **Information URL** | https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-ipv6-in-windows |
| **Privacy URL** | (Optional) |
| **Developer** | IT Department |
| **Owner** | IT Department |
| **Notes** | Registry-based configuration to disable IPv6. Requires reboot. |

Click **Next**

### 3. Program Configuration

Configure the installation and uninstallation commands:

| Field | Value |
|-------|-------|
| **Install command** | `powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySetting_DisableIPv6.ps1"` |
| **Uninstall command** | `powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySetting_DisableIPv6.ps1" -DeploymentType Uninstall` |
| **Install behavior** | System |
| **Device restart behavior** | Determine behavior based on return codes |
| **Return codes** | Use default values (0 = Success, 3010 = Soft reboot, 1707 = Success, 1 = Hard reboot, 1603 = Hard reboot) |

**Note:** The script returns exit code 3010 to indicate a reboot is required.

Click **Next**

### 4. Requirements

Set the minimum requirements for installation:

| Field | Value |
|-------|-------|
| **Operating system architecture** | 64-bit |
| **Minimum operating system** | Windows 10 1607 |

**Additional requirement rules:** None required

Click **Next**

### 5. Detection Rules

Configure how Intune detects if the configuration is applied:

1. **Rules format:** Use a custom detection script
2. Click **Add** under Detection rules
3. Select **Use a custom detection script**
4. **Script file:** Upload `Detect-RegistrySetting_DisableIPv6.ps1`
5. **Run script as 32-bit process on 64-bit clients:** No
6. **Enforce script signature check:** No
7. Click **OK**

**Detection Logic:** The script checks if `HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\DisabledComponents` equals `0xFF`

Click **Next**

### 6. Dependencies

No dependencies are required for this configuration.

Click **Next**

### 7. Supersedence

If you are replacing an older IPv6 configuration method, you can configure supersedence here. Otherwise, skip this section.

Click **Next**

### 8. Assignments

Assign the configuration to groups:

**Required Assignments:**
- Click **Add group** under Required
- Search for and select the target group(s) that require IPv6 to be disabled
- Click **Select**

**Available for enrolled devices:**
- Not recommended for this type of configuration

**Uninstall:**
- (Optional) Add groups from which IPv6 should be re-enabled

**End user notifications:**
- Show all toast notifications (users will be notified of pending reboot)

**Installation deadline:**
- As soon as possible (or set a custom deadline)
- Consider allowing grace period for reboot

**Restart grace period:**
- Set appropriate grace period (e.g., 240 minutes) to allow users to save work before reboot

Click **Next**

### 9. Review + Create

1. Review all settings to ensure they are correct
2. Click **Create**

---

## Monitoring Deployment

### Check Deployment Status

1. Navigate to **Apps** > **Windows**
2. Find **Disable IPv6 Configuration** in the list
3. Click on the application
4. Select **Device install status** or **User install status** to monitor deployment

### View Installation Logs on Client Devices

Logs can be found at:
- **Intune Management Extension Log:** `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- **Deployment Log:** `%TEMP%\DisableIPv6_Deployment.log`

---

## Verification

After deployment and reboot, verify the configuration:

### On the Client Device:

1. **Check registry value:**
   ```powershell
   Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents"
   ```
   Should return: `DisabledComponents : 255` (0xFF in hex)

2. **Run detection script manually:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "Detect-RegistrySetting_DisableIPv6.ps1"
   echo $LASTEXITCODE  # Should return 0 if configured correctly
   ```

3. **Verify IPv6 is disabled (after reboot):**
   ```powershell
   # Check if IPv6 addresses are present on network adapters
   Get-NetAdapterBinding -ComponentID ms_tcpip6 | Select-Object Name, DisplayName, Enabled

   # IPv6 binding should still be present but not functional
   ipconfig /all  # Should show no IPv6 addresses
   ```

4. **Alternative verification:**
   ```powershell
   # Test IPv6 connectivity (should fail)
   Test-NetConnection -ComputerName "ipv6.google.com" -InformationLevel Detailed
   ```

---

## Troubleshooting

### Common Issues

**Issue:** Configuration shows as "Not Installed" in Intune
- **Solution:** Check that the detection script is uploaded correctly and returns exit code 0 when the registry value is set
- Verify registry path: `HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters`
- Verify value name: `DisabledComponents`
- Verify value data: `255` (0xFF)

**Issue:** Configuration applied but IPv6 still works
- **Solution:** Verify that the device has been rebooted
- The registry change requires a full system reboot to take effect
- Check if pending reboot is blocking the change

**Issue:** Installation succeeds but detection fails
- **Solution:** Run detection script manually to see detailed output
- Verify the registry value was actually set correctly
- Check for Group Policy conflicts that might override the setting

**Issue:** Users are not rebooting their devices
- **Solution:** Adjust restart grace period in Intune assignment
- Consider using device restart behavior: "Force a restart"
- Communicate reboot requirement to users in advance

### Getting Support

1. Check Intune deployment logs on the client device
2. Review deployment log: `%TEMP%\DisableIPv6_Deployment.log`
3. Verify registry value manually using Registry Editor (regedit.exe)
4. Contact IT support with log files if issues persist

---

## Rebuilding the Package

If you need to update the scripts and rebuild the package:

1. Edit the PowerShell scripts in the repository folder as needed
2. Run the build script:
   ```powershell
   cd C:\git-repo\mccno-disableipv6
   .\Build-IntunePackage.ps1
   ```
3. Upload the new `.intunewin` file from the Output folder to Intune
4. Update the app version in Intune if applicable

---

## Re-enabling IPv6

To re-enable IPv6 via Intune, assign the application to a group with **Uninstall** intent. The uninstall command will remove the `DisabledComponents` registry value, returning IPv6 to its default enabled state.

**Manual re-enablement:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File "Deploy-RegistrySetting_DisableIPv6.ps1" -DeploymentType Uninstall
```

Or manually via registry:
```powershell
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Force
```

**Note:** A reboot is required after re-enabling IPv6 as well.

---

## DisabledComponents Values Reference

For reference, here are the different values for the DisabledComponents registry entry:

| Value (Hex) | Value (Dec) | Description |
|-------------|-------------|-------------|
| 0x00 | 0 | Enable all IPv6 components (default) |
| 0x01 | 1 | Disable IPv6 on tunnel interfaces |
| 0x10 | 16 | Disable IPv6 on non-tunnel interfaces |
| 0x11 | 17 | Disable IPv6 on all non-tunnel interfaces and IPv6 tunnel interfaces |
| 0x20 | 32 | Prefer IPv4 over IPv6 |
| **0xFF** | **255** | **Disable all IPv6 components (used in this deployment)** |

**This deployment uses 0xFF (255) to completely disable all IPv6 components.**

---

## Additional Information

- **Configuration Type:** Registry-based
- **Install behavior:** System (runs as SYSTEM account)
- **Reboot required:** Yes (exit code 3010)
- **User experience:** Silent configuration, reboot notification shown to user
- **Detection method:** Custom PowerShell script checking registry value
- **Uninstall behavior:** Removes registry value to restore default IPv6 state

---

## Security Considerations

**Note:** Disabling IPv6 is not recommended by Microsoft in most scenarios. IPv6 is an integral component of Windows and many features depend on it. Only disable IPv6 if you have a specific business or technical requirement.

Consider these points before deployment:
- Some Windows features may not function correctly with IPv6 disabled
- DirectAccess requires IPv6
- Some Microsoft services prefer IPv6
- Future applications may require IPv6

**Recommendation:** Instead of disabling IPv6, consider preferring IPv4 over IPv6 by setting DisabledComponents to 0x20 (32).

---

**Created:** 2025-10-29
**Repository:** https://github.com/yourusername/mccno-disableipv6
**Version:** 1.0
