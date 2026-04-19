# Check-AppxPackages.ps1
# Scans installed Appx packages against pattern lists and reports matches.
# Lists are loaded from .txt files in the "AppLists" directory (one pattern per line).
# Usage:
#   .\Check-AppxPackages.ps1                   # loads all .txt files in AppLists\
#   .\Check-AppxPackages.ps1 -ListFiles bloatware.txt,oem.txt

param(
    [string[]]$ListFiles
)

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

Write-Host ""
Write-Host "Loaded $($AppsList.Count) unique patterns from $($Files.Count) file(s)." -ForegroundColor Cyan

# Pre-load package inventories once
Write-Host "Loading installed packages inventory..." -ForegroundColor Cyan
$UserPackages        = Get-AppxPackage                    -ErrorAction SilentlyContinue
$AllUsersPackages    = Get-AppxPackage -AllUsers           -ErrorAction SilentlyContinue
$ProvisionedPackages = Get-AppxProvisionedPackage -Online  -ErrorAction SilentlyContinue

$Results = foreach ($Pattern in $AppsList) {

    $MatchUser        = @($UserPackages        | Where-Object { $_.Name        -like $Pattern })
    $MatchAllUsers    = @($AllUsersPackages     | Where-Object { $_.Name        -like $Pattern })
    $MatchProvisioned = @($ProvisionedPackages  | Where-Object { $_.DisplayName -like $Pattern })

    $FoundNames = @(
        $MatchUser.Name
        $MatchAllUsers.Name
        $MatchProvisioned.DisplayName
    ) | Select-Object -Unique

    $Status = if ($FoundNames.Count -gt 0) { "PRESENT" } else { "ABSENT" }

    [PSCustomObject]@{
        Pattern      = $Pattern
        Status       = $Status
        User         = $MatchUser.Count
        AllUsers     = $MatchAllUsers.Count
        Provisioned  = $MatchProvisioned.Count
        MatchedNames = ($FoundNames -join ", ")
    }
}

# Colored table output
Write-Host ""
Write-Host "=== Pattern match report ===" -ForegroundColor Cyan
Write-Host ""

foreach ($r in $Results) {
    $color = if ($r.Status -eq "PRESENT") { "Green" } else { "DarkGray" }
    $line  = "{0,-45} {1,-8} U:{2,-3} A:{3,-3} P:{4,-3}  {5}" -f `
             $r.Pattern, $r.Status, $r.User, $r.AllUsers, $r.Provisioned, $r.MatchedNames
    Write-Host $line -ForegroundColor $color
}

# Summary
$Present = ($Results | Where-Object Status -eq "PRESENT").Count
$Absent  = ($Results | Where-Object Status -eq "ABSENT").Count
Write-Host ""
Write-Host "Total patterns: $($Results.Count)   Present: $Present   Absent: $Absent" -ForegroundColor Yellow
