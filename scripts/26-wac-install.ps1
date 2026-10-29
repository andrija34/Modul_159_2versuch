<#  Auftrag 06 – auf wac-andrija: RSAT installieren, Windows Admin Center installieren, Verbindung zum DC pruefen  #>
$ErrorActionPreference = 'Continue'
"== RSAT"
Install-WindowsFeature RSAT-AD-Tools, RSAT-ADDS, RSAT-AD-PowerShell, RSAT-DNS-Server, GPMC -IncludeAllSubFeature | Select-Object Success, RestartNeeded, @{n='Features';e={$_.FeatureResult.Name -join ', '}} | Format-List
Get-WindowsFeature RSAT-AD-Tools, RSAT-DNS-Server, GPMC | Format-Table Name, InstallState -AutoSize
"== RSAT-Test: Domaene + Objekte lesen"
Import-Module ActiveDirectory
Get-ADDomain | Format-List DNSRoot, NetBIOSName, DomainMode, PDCEmulator
Get-ADUser -Filter * -SearchBase 'OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159' | Measure-Object | Select-Object @{n='Benutzer in OU=Andrija_AG';e={$_.Count}}

"== Windows Admin Center"
$exe = "$env:TEMP\WindowsAdminCenter.exe"
if (-not (Get-Service WindowsAdminCenter -ErrorAction SilentlyContinue)) {
    Invoke-WebRequest 'https://aka.ms/WACDownload' -OutFile $exe -UseBasicParsing
    "Download: $([math]::Round((Get-Item $exe).Length/1MB,1)) MB"
    # Inno-Setup-Installer (WAC 2410+): still, ohne Rueckfragen; max. 20 Minuten warten
    $p = Start-Process $exe -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=C:\m159\wac-install.log" -PassThru
    if (-not $p.WaitForExit(1200000)) { "Installer laeuft nach 20 Min noch (PID $($p.Id))" } else { "Installer ExitCode: $($p.ExitCode)" }
    Get-Content C:\m159\wac-install.log -Tail 8 -ErrorAction SilentlyContinue
}
Get-Service WindowsAdminCenter*, ServerManagementGateway* -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType -AutoSize
Get-NetTCPConnection -State Listen -LocalPort 443 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
"HTTPS-Antwort lokal: $(curl.exe -k -s -o NUL -w '%{http_code}' https://localhost/)"
Get-NetFirewallRule -DisplayName '*Admin Center*' -ErrorAction SilentlyContinue | Format-Table DisplayName, Enabled, Direction, Action -AutoSize

"== WinRM zum DC"
Test-WSMan dc-andrija.ec2.andrija.m159 | Format-List wsmid, ProductVersion
Test-NetConnection dc-andrija.ec2.andrija.m159 -Port 5985 -WarningAction SilentlyContinue | Select-Object ComputerName, RemotePort, TcpTestSucceeded
