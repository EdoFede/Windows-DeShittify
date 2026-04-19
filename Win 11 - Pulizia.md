
- Installa tutti gli updates

- Esegui Powershell (COME AMMINISTRATORE) e incolla questi comandi:

```
Set-ExecutionPolicy Unrestricted
```

```powershell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableSoftLanding" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableMeteredNetworkFileSync" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "PreventNetworkTrafficPreUserSignIn" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v "DisableHelpSticker" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "HidePeopleBar" /t REG_DWORD /d 1 /f

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "CortanaEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "DeviceHistoryEnabled" /t REG_DWORD /d 0 /f

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SlideshowEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-88000326Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions" /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps" /f

reg add "HKCU\Software\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t REG_DWORD /d 2 /f

reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\MRT" /v "DontOfferThroughWUAU" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsAccessAccountInfo" /t REG_DWORD /d 2 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f

sleep 2

FORFILES /P $env:WINDIR\servicing\Packages /M Microsoft-Windows-InternetExplorer-*11.*.mum /c "cmd /c echo Uninstalling package @fname && start /w pkgmgr /up:@fname /norestart /quiet"
sleep 2
FORFILES /P $env:WINDIR\servicing\Packages /M Microsoft-Windows-QuickAssist*.mum /c "cmd /c echo Uninstalling package @fname && start /w pkgmgr /up:@fname /norestart /quiet"
sleep 2
FORFILES /P $env:WINDIR\servicing\Packages /M Microsoft-Windows-MediaPlayer*.mum /c "cmd /c echo Uninstalling package @fname && start /w pkgmgr /up:@fname /norestart /quiet"
sleep 2
taskkill /f /im OneDrive.exe
C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall

sleep 2

$AppsList = 
"*3DBuilder*",
"*Advertising.Xaml*",
"*Amazon*",
"*AutodeskSketchBook*",
"*BubbleWitch*",
"*CandyCrush*",
"*DisneyMagicKingdoms*",
"*dynabookSupportUtility*",
"*Facebook*",
"*Fitbit*",
"*Houzz*",
"*MarchofEmpires*",
"*MinecraftUWP*",
"*MixedReality.Portal*",
"*Office.OneNote*",
"*OneConnect*",
"*Phototastic*",
"*Print3D*",
"*RealtekAudioControl*",
"*RoyalRevolt*",
"*Spotify*",
"*TOSHIBAManual*",
"*Twitter*",
"*Wallet*",
"*Windows.MiracastView*",
"Clipchamp.Clipchamp*",
"Microsoft.Bing*",
"Microsoft.Edge.GameAssist*",
"Microsoft.GamingApp*",
"Microsoft.GetHelp*",
"Microsoft.Getstarted*",
"Microsoft.Messaging*",
"Microsoft.MicrosoftSolitaireCollection*",
"Microsoft.Outlook*",
"Microsoft.StartExperiencesApp*",
"Microsoft.Todos*",
"Microsoft.WidgetsPlatformRuntime*",
"Microsoft.Windows.People*",
"Microsoft.Windows.Photos*",
"Microsoft.WindowsAlarms*",
"Microsoft.WindowsCamera*",
"Microsoft.windowscommunicationsapps*",
"Microsoft.WindowsFeedbackHub*",
"Microsoft.WindowsSoundRecorder*",
"Microsoft.Xbox*",
"Microsoft.YourPhone*",
"Microsoft.Zune*",
"Microsoft3DViewer*",
"MicrosoftOfficeHub*",
"MicrosoftStickyNotes*",
"MicrosoftWindows.Client.WebExperience*",
"MicrosoftWindows.CrossDevice*",
"MSTeams*"


ForEach ($App in $AppsList)
{
	$Packages = Get-AppxPackage | Where-Object {$_.Name -like $App}
	if ($Packages -ne $null)
	{
		Write-Host "Removing Appx Package: $App"
		ForEach ($Package in $Packages)
		{
			Remove-AppxPackage -package $Package.PackageFullName -ErrorAction SilentlyContinue
			sleep 5
		}
	}
	else
	{
		Write-Host "Unable to find package: $App"
	}
	
}
sleep 10
ForEach ($App in $AppsList)
{
    $Packages = Get-AppxPackage | Where-Object {$_.Name -like $App}
    if ($Packages -ne $null)
    {
        Write-Host "Removing Appx Package: $App"
        ForEach ($Package in $Packages)
        {
            Remove-AppxPackage -package $Package.PackageFullName -ErrorAction SilentlyContinue
            sleep 5
        }
    }
    else
    {
        Write-Host "Unable to find package: $App"
    }
    
}
sleep 5


ForEach ($App in $AppsList)
{
	$ProvisionedPackages = Get-AppxProvisionedPackage -online | Where-Object {$_.displayName -like $App}
	if ($ProvisionedPackages -ne $null)
	{
		Write-Host "Removing Appx Provisioned Package: $App"
		ForEach ($ProvisionedPackage in $ProvisionedPackages) {
			remove-AppxProvisionedPackage -online -packagename $ProvisionedPackage.PackageName -ErrorAction SilentlyContinue
			sleep 1
		}
    }
    else
    {
		Write-Host "Unable to find provisioned package: $App"
    }
}
sleep 10
ForEach ($App in $AppsList)
{
    $ProvisionedPackages = Get-AppxProvisionedPackage -online | Where-Object {$_.displayName -like $App}
    if ($ProvisionedPackages -ne $null)
    {
        Write-Host "Removing Appx Provisioned Package: $App"
        ForEach ($ProvisionedPackage in $ProvisionedPackages) {
            remove-AppxProvisionedPackage -online -packagename $ProvisionedPackage.PackageName -ErrorAction SilentlyContinue
            sleep 1
        }
    }
    else
    {
        Write-Host "Unable to find provisioned package: $App"
    }
}

rm 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Booking.com.url'
rm 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\IOLO.url'
rm 'C:\Users\Public\Desktop\Dynabook Services.url'

wmic --% product where 'name like "%winzip%"' call uninstall
sleep 2
```

- Disinstalla Office (tutti)
- Disintalla ExpressVPN






- Riavvia




### Altri comandi utili ###
Get-AppxPackage | Select Name, PackageFullName
Get-AppxPackage -allusers | Select Name, PackageFullName
Get-AppxProvisionedPackage -online | Select DisplayName, PackageName

Get-AppxPackage | Where-Object {$_.Name -like "*Microsoft.Windows.ParentalControls*"} |Remove-AppxPackage -ErrorAction SilentlyContinue



