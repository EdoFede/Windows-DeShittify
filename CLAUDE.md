# Windows DeShittify

PowerShell tools to clean up a fresh Windows 11 install. Strips bloatware, OEM junk, telemetry, ads, and built-in nags.

## What this project does
- Registry tweaks to disable telemetry, ads, Cortana, OneDrive sync, and content delivery suggestions
- Uninstalls bloatware UWP/Appx packages (games, social apps, OEM crapware, MS junk)
- Removes provisioned packages to prevent reinstallation for new users
- Cleans up leftover shortcuts and OEM software (WinZip, etc.)

## Reference
- `[OLD] Win 11 - Pulizia.md` — original manual command sequence (Italian), used as the basis for building proper scripts
- `README.md` — user-facing prerequisites and usage instructions

## Notes
- All scripts must run in an elevated PowerShell session (Run as Administrator)
- Target OS: Windows 11
