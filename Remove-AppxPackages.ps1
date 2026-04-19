# Remove-AppxPackages.ps1
# Removes Appx packages matching patterns from list files in the "AppLists" directory.
# Usage:
#   .\Remove-AppxPackages.ps1                                        # uses all lists, removes for all users + provisioned
#   .\Remove-AppxPackages.ps1 -ListFiles bloatware.txt,oem.txt       # only specific lists
#   .\Remove-AppxPackages.ps1 -Exclude "Photos|Camera"               # exclude patterns matching regex
#   .\Remove-AppxPackages.ps1 -CurrentUserOnly                       # remove only for current user, skip provisioned
#   .\Remove-AppxPackages.ps1 -Force                                 # skip confirmation prompt

param(
    [string[]]$ListFiles,
    [string]$Exclude,
    [switch]$CurrentUserOnly,
    [switch]$Force
)

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ListsDir  = Join-Path $ScriptDir "AppLists"

if (-not (Test-Path $ListsDir)) {
    Write-Host "ERROR: Lists directory not found: $ListsDir" -ForegroundColor Red
    exit 1
}

# Determine which list files to load
if ($ListFiles) {
    $Files = foreach ($f in $ListFiles) {
        $FullPath = Join-Path $ListsDir $f
        if (-not (Test-Path $FullPath)) {
            Write-Host "WARNING: List file not found, skipping: $FullPath" -ForegroundColor Yellow
            continue
        }
        Get-Item $FullPath
    }
} else {
    $Files = Get-ChildItem -Path $ListsDir -Filter "*.txt"
}

if (-not $Files) {
    Write-Host "ERROR: No list files found." -ForegroundColor Red
    exit 1
}

# Load patterns from all list files (skip comments and empty lines, deduplicate)
$AppsList = @()
foreach ($File in $Files) {
    Write-Host "Loading list: $($File.Name)" -ForegroundColor Cyan
    $Lines = Get-Content -Path $File.FullName |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" -and $_ -notmatch "^\s*#" }
    $AppsList += $Lines
}
$AppsList = $AppsList | Select-Object -Unique

if ($AppsList.Count -eq 0) {
    Write-Host "ERROR: No patterns loaded from list files." -ForegroundColor Red
    exit 1
}

# Apply exclusion filter
if ($Exclude) {
    $Before = $AppsList.Count
    $AppsList = $AppsList | Where-Object { $_ -notmatch $Exclude }
    $Excluded = $Before - $AppsList.Count
    Write-Host "Excluded $Excluded pattern(s) matching: $Exclude" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Loaded $($AppsList.Count) unique patterns from $($Files.Count) file(s)." -ForegroundColor Cyan

# --- Scan for matching packages ---
Write-Host "Scanning installed packages..." -ForegroundColor Cyan

$AppxToRemove = @()
foreach ($Pattern in $AppsList) {
    if ($CurrentUserOnly) {
        $Packages = Get-AppxPackage | Where-Object { $_.Name -like $Pattern }
    } else {
        $Packages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $Pattern }
    }
    if ($Packages) { $AppxToRemove += $Packages }
}
$AppxToRemove = $AppxToRemove | Sort-Object Name -Unique

$ProvToRemove = @()
if (-not $CurrentUserOnly) {
    foreach ($Pattern in $AppsList) {
        $ProvPackages = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $Pattern }
        if ($ProvPackages) { $ProvToRemove += $ProvPackages }
    }
    $ProvToRemove = $ProvToRemove | Sort-Object DisplayName -Unique
}

if ($AppxToRemove.Count -eq 0 -and $ProvToRemove.Count -eq 0) {
    Write-Host ""
    Write-Host "No matching packages found. Nothing to remove." -ForegroundColor Green
    exit 0
}

# --- Show preview and ask for confirmation ---
if (-not $Force) {
    Write-Host ""
    Write-Host "=== Packages to be removed ===" -ForegroundColor Cyan

    if ($AppxToRemove.Count -gt 0) {
        Write-Host ""
        if ($CurrentUserOnly) {
            Write-Host "Appx packages (current user):" -ForegroundColor Yellow
        } else {
            Write-Host "Appx packages (all users):" -ForegroundColor Yellow
        }
        foreach ($p in $AppxToRemove) {
            Write-Host "  - $($p.Name)" -ForegroundColor White
        }
    }

    if ($ProvToRemove.Count -gt 0) {
        Write-Host ""
        Write-Host "Provisioned packages:" -ForegroundColor Yellow
        foreach ($p in $ProvToRemove) {
            Write-Host "  - $($p.DisplayName)" -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "Total: $($AppxToRemove.Count) appx + $($ProvToRemove.Count) provisioned" -ForegroundColor Cyan
    Write-Host ""
    $Confirm = Read-Host "Proceed with removal? (y/N)"
    if ($Confirm -notmatch "^[yY]$") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# --- Remove Appx packages ---
if ($CurrentUserOnly) {
    Write-Host "=== Removing Appx packages (current user only) ===" -ForegroundColor Cyan
} else {
    Write-Host "=== Removing Appx packages (all users) ===" -ForegroundColor Cyan
}
Write-Host ""

$RemovedCount = 0
$FailedCount  = 0

foreach ($Package in $AppxToRemove) {
    Write-Host "  Removing: $($Package.Name)" -ForegroundColor Yellow
    try {
        if ($CurrentUserOnly) {
            Remove-AppxPackage -Package $Package.PackageFullName -ErrorAction Stop
        } else {
            Remove-AppxPackage -Package $Package.PackageFullName -AllUsers -ErrorAction Stop
        }
        $RemovedCount++
    } catch {
        Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $FailedCount++
    }
}

# --- Remove provisioned packages ---
$ProvRemovedCount = 0
$ProvFailedCount  = 0

if (-not $CurrentUserOnly) {
    Write-Host ""
    Write-Host "=== Removing provisioned packages ===" -ForegroundColor Cyan
    Write-Host ""

    foreach ($ProvPackage in $ProvToRemove) {
        Write-Host "  Removing provisioned: $($ProvPackage.DisplayName)" -ForegroundColor Yellow
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $ProvPackage.PackageName -ErrorAction Stop
            $ProvRemovedCount++
        } catch {
            Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
            $ProvFailedCount++
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Appx packages removed: $RemovedCount   Failed: $FailedCount" -ForegroundColor $(if ($FailedCount -gt 0) { "Yellow" } else { "Green" })
if (-not $CurrentUserOnly) {
    Write-Host "Provisioned packages removed: $ProvRemovedCount   Failed: $ProvFailedCount" -ForegroundColor $(if ($ProvFailedCount -gt 0) { "Yellow" } else { "Green" })
}
