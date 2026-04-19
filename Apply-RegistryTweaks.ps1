# Apply-RegistryTweaks.ps1
# Applies registry tweaks from list files in the "RegLists" directory.
# Each list file uses a pipe-separated format: Action | Key | Value | Type | Data
# Usage:
#   .\Apply-RegistryTweaks.ps1                                        # applies all .reg.csv files in RegLists\
#   .\Apply-RegistryTweaks.ps1 -ListFiles disable-telemetry.reg.csv   # only specific lists
#   .\Apply-RegistryTweaks.ps1 -Exclude "Cortana|OneDrive"            # exclude entries matching regex
#   .\Apply-RegistryTweaks.ps1 -Force                                 # skip confirmation prompt

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
$ListsDir  = Join-Path $ScriptDir "RegLists"

if (-not (Test-Path $ListsDir)) {
    Write-Host "ERROR: RegLists directory not found: $ListsDir" -ForegroundColor Red
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
    $Files = Get-ChildItem -Path $ListsDir -Filter "*.reg.csv"
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

        $Parts = $Line -split "\s*\|\s*"
        $Action = $Parts[0].ToUpper()

        if ($Action -eq "ADD") {
            if ($Parts.Count -lt 5) {
                Write-Host "WARNING: Invalid ADD entry at $($File.Name):$LineNum (expected 5 fields) - skipping" -ForegroundColor Yellow
                continue
            }
            $Entries += [PSCustomObject]@{
                Action = "ADD"
                Key    = $Parts[1]
                Value  = $Parts[2]
                Type   = $Parts[3].ToUpper()
                Data   = $Parts[4]
                Source = "$($File.Name):$LineNum"
            }
        } elseif ($Action -eq "DELETE") {
            if ($Parts.Count -lt 2) {
                Write-Host "WARNING: Invalid DELETE entry at $($File.Name):$LineNum (expected at least 2 fields) - skipping" -ForegroundColor Yellow
                continue
            }
            $Entries += [PSCustomObject]@{
                Action = "DELETE"
                Key    = $Parts[1]
                Value  = if ($Parts.Count -ge 3 -and $Parts[2] -ne "") { $Parts[2] } else { $null }
                Type   = $null
                Data   = $null
                Source = "$($File.Name):$LineNum"
            }
        } else {
            Write-Host "WARNING: Unknown action '$Action' at $($File.Name):$LineNum - skipping" -ForegroundColor Yellow
        }
    }
}

if ($Entries.Count -eq 0) {
    Write-Host "ERROR: No valid entries loaded from list files." -ForegroundColor Red
    exit 1
}

# Apply exclusion filter (matches against key + value name)
if ($Exclude) {
    $Before = $Entries.Count
    $Entries = $Entries | Where-Object {
        $MatchStr = "$($_.Key)\$($_.Value)"
        $MatchStr -notmatch $Exclude
    }
    $Excluded = $Before - $Entries.Count
    Write-Host "Excluded $Excluded entry/entries matching: $Exclude" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Loaded $($Entries.Count) entries from $($Files.Count) file(s)." -ForegroundColor Cyan

# --- Show preview and ask for confirmation ---
if (-not $Force) {
    Write-Host ""
    Write-Host "=== Registry changes to be applied ===" -ForegroundColor Cyan
    Write-Host ""

    foreach ($e in $Entries) {
        if ($e.Action -eq "ADD") {
            $display = "  SET  $($e.Key) \ $($e.Value) = $($e.Data) ($($e.Type))"
            Write-Host $display -ForegroundColor White
        } else {
            if ($e.Value) {
                $display = "  DEL  $($e.Key) \ $($e.Value)"
            } else {
                $display = "  DEL  $($e.Key)  (entire key)"
            }
            Write-Host $display -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Total: $($Entries.Count) operations" -ForegroundColor Cyan
    Write-Host ""
    $Confirm = Read-Host "Proceed? (y/N)"
    if ($Confirm -notmatch "^[yY]$") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
    Write-Host ""
}

# --- Apply registry changes ---
Write-Host "=== Applying registry tweaks ===" -ForegroundColor Cyan
Write-Host ""

$SuccessCount = 0
$FailedCount  = 0

foreach ($e in $Entries) {
    if ($e.Action -eq "ADD") {
        Write-Host "  SET  $($e.Key) \ $($e.Value) = $($e.Data)" -ForegroundColor Yellow
        try {
            # Convert HKLM/HKCU to PowerShell registry paths
            $PSPath = $e.Key -replace "^HKLM\\", "HKLM:\" -replace "^HKCU\\", "HKCU:\"

            # Create key if it doesn't exist
            if (-not (Test-Path $PSPath)) {
                New-Item -Path $PSPath -Force | Out-Null
            }

            # Map registry type to PowerShell property type
            $PropertyType = switch ($e.Type) {
                "REG_DWORD"     { "DWord" }
                "REG_QWORD"    { "QWord" }
                "REG_SZ"       { "String" }
                "REG_EXPAND_SZ" { "ExpandString" }
                "REG_MULTI_SZ" { "MultiString" }
                "REG_BINARY"   { "Binary" }
                default        { "String" }
            }

            # Convert data to appropriate type
            $PropertyValue = switch ($e.Type) {
                "REG_DWORD"  { [int]$e.Data }
                "REG_QWORD"  { [long]$e.Data }
                default      { $e.Data }
            }

            Set-ItemProperty -Path $PSPath -Name $e.Value -Value $PropertyValue -Type $PropertyType -ErrorAction Stop
            $SuccessCount++
        } catch {
            Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
            $FailedCount++
        }
    } else {
        # DELETE
        if ($e.Value) {
            Write-Host "  DEL  $($e.Key) \ $($e.Value)" -ForegroundColor Yellow
        } else {
            Write-Host "  DEL  $($e.Key)  (entire key)" -ForegroundColor Yellow
        }
        try {
            $PSPath = $e.Key -replace "^HKLM\\", "HKLM:\" -replace "^HKCU\\", "HKCU:\"

            if ($e.Value) {
                # Delete a specific value
                Remove-ItemProperty -Path $PSPath -Name $e.Value -ErrorAction Stop
            } else {
                # Delete entire key
                Remove-Item -Path $PSPath -Recurse -ErrorAction Stop
            }
            $SuccessCount++
        } catch {
            Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
            $FailedCount++
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Successful: $SuccessCount   Failed: $FailedCount" -ForegroundColor $(if ($FailedCount -gt 0) { "Yellow" } else { "Green" })
