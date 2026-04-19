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

## App Lists

Pattern lists used by `Check-AppxPackages.ps1` are stored in the `AppLists/` directory:

| File | Description | Patterns |
|---|---|---|
| `3rd-party.txt` | Third-party apps (Amazon, Spotify, Facebook, Toshiba, Realtek, games...) | 17 |
| `bloatware.txt` | Preinstalled junk, ads, widgets, 3D viewer, Bing, Game Assist... | 19 |
| `microsoft-apps.txt` | Standalone Microsoft products (Office, Teams, Xbox, Zune, YourPhone...) | 10 |
| `windows-apps.txt` | Windows built-in apps (Photos, Camera, Alarms, Feedback Hub...) | 8 |
