*[Italiano](README.it.md) | English*

# Windows De-Shittify

PowerShell tools to clean up a fresh Windows 11 install. Strips bloatware, OEM junk, telemetry, ads, and built-in nags.

---

## Prerequisites

### 1. Launch PowerShell as Administrator

Right-click the Start menu and select **Terminal (Admin)** or **Windows PowerShell (Admin)**.

### 2. Allow script execution

Run this command to allow locally downloaded scripts to execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

---

## Get the scripts

Select an install location (example: C:\Tools)

### Option A: Clone with Git

If you don't have Git, download and install it from: https://git-scm.com/install/windows (default installation options are fine).

Then clone the repository:
```powershell
git clone https://github.com/EdoFede/Windows-DeShittify.git
cd Windows-DeShittify
```

To update the scripts later:
```powershell
cd Windows-DeShittify
git pull
```

### Option B: Download manually

Download the latest release from: https://github.com/EdoFede/Windows-DeShittify/releases/latest

Extract the ZIP and open the folder in PowerShell.

> **Note:** releases are published manually and may not reflect the latest changes on the `main` branch. For the most up-to-date version, use the Git clone method.

---

## Automatic execution

Run `ApplyAll.ps1` to execute all cleanup steps in sequence (registry tweaks, package removal, program removal):
```powershell
.\ApplyAll.ps1
```

This is equivalent to running each individual script manually, one after the other.

---

## Manual execution

| Script | Description |
|---|---|
| `Apply-RegistryTweaks.ps1` | Applies registry modifications to disable telemetry, ads, Cortana, OneDrive sync, and UI nags |
| `Check-AppxPackages.ps1` | Scans installed Appx packages against pattern lists and reports which are present |
| `Remove-AppxPackages.ps1` | Uninstalls Appx packages matching pattern lists (bloatware, OEM apps, etc.) |
| `Remove-Programs.ps1` | Uninstalls programs that can't be removed via Appx (e.g. OneDrive, WinZip) |

---

### Apply-RegistryTweaks.ps1

Applies registry tweaks from `.reg.csv` files in the `RegLists/` directory. Each file uses a pipe-separated format:

```
Action | Key | Value | Type | Data
```

Supported actions:
- **ADD** — creates or updates a registry value (requires all 5 fields)
- **DELETE** — removes a registry value or entire key (requires Action + Key, optionally Value)

Lines starting with `#` are comments and are ignored.

**Example list file:**
```
# Disable telemetry data collection
ADD | HKLM\Software\Policies\Microsoft\Windows\DataCollection | AllowTelemetry | REG_DWORD | 0

# Remove a specific value
DELETE | HKCU\Software\SomeApp | UnwantedSetting
```

By default, the script shows a preview of all changes and asks for confirmation before applying.

**Parameters:**

| Parameter | Description |
|---|---|
| `-ListFiles` | Use only specific list files instead of all (e.g. `disable-telemetry.reg.csv`) |
| `-Exclude` | Exclude entries where key+value matches a regex |
| `-Force` | Skip the confirmation prompt |

**Examples:**
```powershell
# Apply only telemetry tweaks
.\Apply-RegistryTweaks.ps1 -ListFiles disable-telemetry.reg.csv

# Apply all tweaks except OneDrive-related
.\Apply-RegistryTweaks.ps1 -Exclude "OneDrive"

# Apply everything without confirmation
.\Apply-RegistryTweaks.ps1 -Force
```

**Included list files:**

| File | Description | Entries |
|---|---|---|
| `disable-telemetry.reg.csv` | Telemetry, CEIP, data collection, advertising ID, SmartScreen | 8 |
| `disable-ads-suggestions.reg.csv` | Content delivery, suggested apps, lock screen spotlight, subscribed content | 19 |
| `disable-cortana-search.reg.csv` | Cortana, Bing search, search box, device history | 6 |
| `disable-onedrive.reg.csv` | OneDrive sync, metered network, sync notifications | 4 |
| `disable-ui-nags.reg.csv` | Edge help sticker, People bar, Store auto-download | 3 |

---

### Check-AppxPackages.ps1

Scans installed Appx packages against pattern lists and reports which ones are present on the system. Useful to check what bloatware is currently installed before removing anything.

Lists are loaded from `.txt` files in the `AppLists/` directory, one pattern per line. Patterns use wildcard matching (e.g. `*Bing*`). Lines starting with `#` are comments and are ignored.

**Example list file:**
```
# Bloatware
*3DBuilder*
*Advertising.Xaml*
*MinecraftUWP*
```

**Parameters:**

| Parameter | Description |
|---|---|
| `-ListFiles` | Use only specific list files instead of all (e.g. `bloatware.txt,oem.txt`) |

**Examples:**
```powershell
# Check all lists
.\Check-AppxPackages.ps1

# Check only bloatware
.\Check-AppxPackages.ps1 -ListFiles bloatware.txt
```

**Included list files:**

| File | Description | Patterns |
|---|---|---|
| `3rd-party.txt` | Third-party apps (Amazon, Spotify, Facebook, Toshiba, Realtek, games...) | 17 |
| `bloatware.txt` | Preinstalled junk, ads, widgets, 3D viewer, Bing, Game Assist... | 19 |
| `microsoft-apps.txt` | Standalone Microsoft products (Office, Teams, Xbox, Zune, YourPhone...) | 10 |
| `windows-apps.txt` | Windows built-in apps (Photos, Camera, Alarms, Feedback Hub...) | 7 |

---

### Remove-AppxPackages.ps1

Uninstalls Appx packages matching patterns from the same list files in `AppLists/` (see [Check-AppxPackages.ps1](#check-appxpackagesps1) for the list format).

By default, the script removes packages for all users and removes provisioned packages (preventing reinstallation for new users). It shows a preview and asks for confirmation before proceeding.

**Parameters:**

| Parameter | Description |
|---|---|
| `-ListFiles` | Use only specific list files instead of all (e.g. `bloatware.txt,oem.txt`) |
| `-Exclude` | Exclude patterns matching a regex from removal |
| `-CurrentUserOnly` | Remove only for the current user, skip provisioned packages |
| `-Force` | Skip the confirmation prompt |

**Examples:**
```powershell
# Remove only bloatware
.\Remove-AppxPackages.ps1 -ListFiles bloatware.txt

# Remove everything except Photos and Camera
.\Remove-AppxPackages.ps1 -Exclude "Photos|Camera"

# Remove only for current user, excluding Xbox
.\Remove-AppxPackages.ps1 -CurrentUserOnly -Exclude "Xbox"

# Remove all without confirmation
.\Remove-AppxPackages.ps1 -Force
```

---

### Remove-Programs.ps1

Uninstalls programs that cannot be removed via Appx (e.g. OneDrive, WinZip). Reads `.prog.csv` files from the `ProgLists/` directory using a pipe-separated format:

```
Method | Name/Command
```

Supported methods:

| Method | Description |
|---|---|
| `WINGET` | Uninstalls via `winget uninstall` |
| `PACKAGE` | Uninstalls via `Get-Package` / `Uninstall-Package` (PackageManagement) |
| `CIM` | Uninstalls via CIM/WMI `Win32_Product` (supports wildcards) |
| `CUSTOM` | Runs the provided command as-is |

Lines starting with `#` are comments and are ignored.

**Example list file:**
```
# OneDrive
WINGET | Microsoft.OneDrive
```

By default, the script shows a preview and asks for confirmation before proceeding.

**Parameters:**

| Parameter | Description |
|---|---|
| `-ListFiles` | Use only specific list files instead of all (e.g. `microsoft.prog.csv`) |
| `-Exclude` | Exclude entries matching a regex from removal |
| `-Force` | Skip the confirmation prompt |

**Examples:**
```powershell
# Remove only Microsoft programs
.\Remove-Programs.ps1 -ListFiles microsoft.prog.csv

# Remove all except OneDrive
.\Remove-Programs.ps1 -Exclude "OneDrive"

# Remove all without confirmation
.\Remove-Programs.ps1 -Force
```

**Included list files:**

| File | Description | Entries |
|---|---|---|
| `microsoft.prog.csv` | Microsoft programs (OneDrive) | 1 |
