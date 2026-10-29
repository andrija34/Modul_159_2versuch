<#
  Auftrag 02 – Windows-Grundeinstellungen fuer neue EC2-Instanzen (DC, Client, WAC)
  Basiert auf dem Init-Skript der Lehrperson, erweitert um die restlichen Punkte des Auftrags.
  Aufruf (als Administrator):  .\02-init.ps1 -Hostname dc-andrija
#>
param(
    [Parameter(Mandatory)] [string] $Hostname
)

$ErrorActionPreference = 'Continue'

# --- 1) Desktop-Verknuepfungen (aktueller + Default-Benutzer) ---------------------------
$DefaultDesktop = Join-Path $env:SystemDrive 'Users\Default\Desktop'
$CurrentDesktop = [Environment]::GetFolderPath('Desktop')
foreach ($desk in @($DefaultDesktop, $CurrentDesktop) | Where-Object { $_ }) {
    if (-not (Test-Path $desk)) { New-Item -Path $desk -ItemType Directory -Force | Out-Null }
}
function New-Shortcut {
    param([string]$Path, [string]$Target, [string]$Arguments, [string]$IconLocation)
    $sc = (New-Object -ComObject WScript.Shell).CreateShortcut($Path)
    $sc.TargetPath = $Target
    if ($Arguments)    { $sc.Arguments = $Arguments }
    $sc.WorkingDirectory = Split-Path $Target
    if ($IconLocation) { $sc.IconLocation = $IconLocation }
    $sc.Save()
}
$control = "$env:SystemRoot\System32\control.exe"
$ps      = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$cmd     = "$env:SystemRoot\System32\cmd.exe"
foreach ($d in @($DefaultDesktop, $CurrentDesktop) | Where-Object { $_ }) {
    New-Shortcut "$d\PowerShell.lnk"           $ps      -IconLocation "$ps,0"
    New-Shortcut "$d\Eingabeaufforderung.lnk"  $cmd     -IconLocation "$cmd,0"
    New-Shortcut "$d\Netzwerkverbindungen.lnk" $control 'ncpa.cpl'
    New-Shortcut "$d\Remote Desktop.lnk"       "$env:SystemRoot\System32\mstsc.exe"
    New-Shortcut "$d\Systemeigenschaften.lnk"  $control 'sysdm.cpl'
    New-Shortcut "$d\Firewall.lnk"             $control '/name Microsoft.WindowsFirewall'
}

# --- 2) Desktopsymbole einblenden: Dieser PC, Systemsteuerung, Netzwerk ------------------
$icons = @{
    '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' = 0   # Dieser PC
    '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}' = 0   # Systemsteuerung
    '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' = 0   # Netzwerk
}
foreach ($hive in 'HKCU:', 'Registry::HKEY_USERS\.DEFAULT') {
    $p = "$hive\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
    New-Item -Path $p -Force | Out-Null
    foreach ($k in $icons.Keys) { New-ItemProperty -Path $p -Name $k -Value 0 -PropertyType DWord -Force | Out-Null }
}

# --- 3) Explorer: Dateiendungen, versteckte + geschuetzte Systemdateien, Freigabeassistent aus
foreach ($p in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced',
               'Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced') {
    New-Item -Path $p -Force | Out-Null
    New-ItemProperty $p -Name Hidden            -Value 1 -PropertyType DWord -Force | Out-Null  # alle Dateien anzeigen
    New-ItemProperty $p -Name ShowSuperHidden   -Value 1 -PropertyType DWord -Force | Out-Null  # geschuetzte Systemdateien
    New-ItemProperty $p -Name HideFileExt       -Value 0 -PropertyType DWord -Force | Out-Null  # Endungen anzeigen
    New-ItemProperty $p -Name SharingWizardOn   -Value 0 -PropertyType DWord -Force | Out-Null  # Freigabeassistent aus
}

# --- 4) Firewall: Ping (ICMPv4 Echo Request) fuer alle Profile ---------------------------
Get-NetFirewallRule -Name 'FPS-ICMP4-ERQ-In*','CoreNet-Diag-ICMP4-EchoRequest-In*' -ErrorAction SilentlyContinue |
    Enable-NetFirewallRule
if (-not (Get-NetFirewallRule -DisplayName 'M159 Ping erlauben' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName 'M159 Ping erlauben' -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow -Profile Any | Out-Null
}

# --- 5) Tastatur / Region / Zeitzone Schweiz -----------------------------------------------
$ll = New-WinUserLanguageList -Language de-CH
Set-WinUserLanguageList -LanguageList $ll -Force
Set-Culture de-CH
Set-WinSystemLocale de-CH
Set-WinHomeLocation -GeoId 223
Set-TimeZone -Id 'W. Europe Standard Time'
try { Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true } catch {}

# --- 6) IPv6 auf allen Adaptern deaktivieren ----------------------------------------------
Get-NetAdapter | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }

# --- 7) IE Enhanced Security Configuration aus (nur Desktop-Server mit GUI) ----------------
$esc = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components'
foreach ($k in '{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}', '{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}') {
    if (Test-Path "$esc\$k") { Set-ItemProperty "$esc\$k" -Name IsInstalled -Value 0 }
}

# --- 8) Hostname setzen (Neustart noetig) -------------------------------------------------
if ($env:COMPUTERNAME -ne $Hostname.ToUpper()) {
    Rename-Computer -NewName $Hostname -Force
    Write-Host "Hostname wird nach Neustart '$Hostname' sein." -ForegroundColor Yellow
}

Write-Host "Fertig. Neustart noetig." -ForegroundColor Green
# Unter AWS SSM Run Command fordert Exit-Code 3010 den Neustart an; interaktiv: Restart-Computer
if ($env:USERNAME -eq "$env:COMPUTERNAME$" -or $env:USERNAME -eq 'SYSTEM') { exit 3010 }
