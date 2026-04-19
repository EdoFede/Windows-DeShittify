# Prerequisites

Always launch Powershell/Terminal **As Administrator**

## Install Git (optional)

Installing Git is optional. It is only needed if you want to easily pull future updates to the scripts.

Download and install Git for Windows from: https://git-scm.com/install/windows

During installation, the default options are fine for most users.

## Download the scripts

**With Git:** clone the repository:
```powershell
git clone https://github.com/EdoFede/Windows-DeShittify.git
cd Windows-DeShittify
```

**Without Git:** download the repository as a ZIP from GitHub and extract it.

## Update the scripts

If you cloned the repository with Git, you can pull the latest changes at any time:
```powershell
cd Windows-DeShittify
git pull
```

## Allow scripts
```powershell
Set-ExecutionPolicy Unrestricted
```

## Usage

### Check installed packages

Run `Check-AppxPackages.ps1` to see which packages from the lists are currently installed:
```powershell
.\Check-AppxPackages.ps1
```

### Remove packages

Run `Remove-AppxPackages.ps1` to uninstall matching packages:
```powershell
.\Remove-AppxPackages.ps1
```

By default, the script shows a list of packages that will be removed and asks for confirmation before proceeding. It removes packages for all users and removes provisioned packages (preventing reinstallation for new users).

**Options:**

| Parameter | Description |
|---|---|
| `-ListFiles bloatware.txt,oem.txt` | Use only specific list files instead of all |
| `-Exclude "Photos\|Camera"` | Exclude patterns matching a regex from removal |
| `-CurrentUserOnly` | Remove only for the current user, skip provisioned packages |
| `-Force` | Skip the confirmation prompt and proceed directly |

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

## App Lists

Pattern lists used by `Check-AppxPackages.ps1` are stored in the `AppLists/` directory:

| File | Description | Patterns |
|---|---|---|
| `3rd-party.txt` | Third-party apps (Amazon, Spotify, Facebook, Toshiba, Realtek, games...) | 17 |
| `bloatware.txt` | Preinstalled junk, ads, widgets, 3D viewer, Bing, Game Assist... | 19 |
| `microsoft-apps.txt` | Standalone Microsoft products (Office, Teams, Xbox, Zune, YourPhone...) | 10 |
| `windows-apps.txt` | Windows built-in apps (Photos, Camera, Alarms, Feedback Hub...) | 8 |
