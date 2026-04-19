# Remove-Programs.ps1
# Removes programs using various methods (winget, PackageManagement, CIM, custom commands).
# Reads list files from the "ProgLists" directory.
# Usage:
#   .\Remove-Programs.ps1                                        # uses all .prog.csv files in ProgLists\
#   .\Remove-Programs.ps1 -ListFiles microsoft.prog.csv          # only specific lists
#   .\Remove-Programs.ps1 -Exclude "OneDrive|Office"             # exclude entries matching regex
#   .\Remove-Programs.ps1 -Force                                 # skip confirmation prompt

param(
    [string[]]$ListFiles,
    [string]$Exclude,
    [switch]$Force
)

# Check for Administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ListsDir  = Join-Path $ScriptDir "ProgLists"

if (-not (Test-Path $ListsDir)) {
    Write-Host "ERROR: ProgLists directory not found: $ListsDir" -ForegroundColor Red
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
    $Files = Get-ChildItem -Path $ListsDir -Filter "*.prog.csv"
}

if (-not $Files) {
    Write-Host "ERROR: No list files found." -ForegroundColor Red
    exit 1
}

# Parse entries from all list files
$Entries = @()
foreach ($File in $Files) {
    Write-Host "Loading list: $($File.Name)" -ForegroundColor Cyan
    $LineNum = 0
    foreach ($RawLine in (Get-Content -Path $File.FullName)) {
        $LineNum++
        $Line = $RawLine.Trim()
        if ($Line -eq "" -or $Line -match "^\s*#") { continue }

        $Parts = $Line -split "\s*\|\s*", 2
        if ($Parts.Count -lt 2) {
            Write-Host "WARNING: Invalid entry at $($File.Name):$LineNum (expected 2 fields) - skipping" -ForegroundColor Yellow
            continue
        }

        $Method = $Parts[0].ToUpper()
        $Name   = $Parts[1]

        if ($Method -notin @("WINGET", "PACKAGE", "CIM", "CUSTOM")) {
            Write-Host "WARNING: Unknown method '$Method' at $($File.Name):$LineNum - skipping" -ForegroundColor Yellow
            continue
        }

        $Entries += [PSCustomObject]@{
            Method = $Method
            Name   = $Name
            Source = "$($File.Name):$LineNum"
        }
    }
}

if ($Entries.Count -eq 0) {
    Write-Host "ERROR: No valid entries loaded from list files." -ForegroundColor Red
    exit 1
}

# Apply exclusion filter
if ($Exclude) {
    $Before = $Entries.Count
    $Entries = $Entries | Where-Object { $_.Name -notmatch $Exclude }
    $Excluded = $Before - $Entries.Count
    Write-Host "Excluded $Excluded entry/entries matching: $Exclude" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Loaded $($Entries.Count) entries from $($Files.Count) file(s)." -ForegroundColor Cyan

# --- Show preview and ask for confirmation ---
if (-not $Force) {
    Write-Host ""
    Write-Host "=== Programs to be removed ===" -ForegroundColor Cyan
    Write-Host ""

    foreach ($e in $Entries) {
        $label = switch ($e.Method) {
            "WINGET"  { "winget" }
            "PACKAGE" { "PackageMgmt" }
            "CIM"     { "CIM/WMI" }
            "CUSTOM"  { "custom cmd" }
        }
        Write-Host "  [$label]  $($e.Name)" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Total: $($Entries.Count) programs" -ForegroundColor Cyan
    Write-Host ""
    $Confirm = Read-Host "Proceed with removal? (y/N)"
    if ($Confirm -notmatch "^[yY]$") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# --- Remove programs ---
Write-Host "=== Removing programs ===" -ForegroundColor Cyan
Write-Host ""

$SuccessCount = 0
$FailedCount  = 0

foreach ($e in $Entries) {
    Write-Host "  [$($e.Method)]  $($e.Name)" -ForegroundColor Yellow

    try {
        switch ($e.Method) {
            "WINGET" {
                $output = winget uninstall $e.Name --silent --accept-source-agreements 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "winget exit code $LASTEXITCODE`: $output"
                }
                $SuccessCount++
            }
            "PACKAGE" {
                $pkg = Get-Package -Name $e.Name -ErrorAction Stop
                $pkg | Uninstall-Package -Force -ErrorAction Stop
                $SuccessCount++
            }
            "CIM" {
                $product = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like $e.Name }
                if (-not $product) {
                    throw "Program not found via CIM: $($e.Name)"
                }
                foreach ($p in $product) {
                    Invoke-CimMethod -InputObject $p -MethodName Uninstall -ErrorAction Stop | Out-Null
                }
                $SuccessCount++
            }
            "CUSTOM" {
                Invoke-Expression $e.Name
                if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                    throw "Command exit code $LASTEXITCODE"
                }
                $SuccessCount++
            }
        }
        Write-Host "    OK" -ForegroundColor Green
    } catch {
        Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $FailedCount++
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Removed: $SuccessCount   Failed: $FailedCount" -ForegroundColor $(if ($FailedCount -gt 0) { "Yellow" } else { "Green" })
