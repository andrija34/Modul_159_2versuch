<#  Auftrag 06 – Pruefung auf wac-andrija: Domaene, RSAT gegen DC (ADWS 9389), WinRM, WAC-Dienst/Zertifikat  #>
"== Computer"; Get-CimInstance Win32_ComputerSystem | Format-List Name, Domain, PartOfDomain
"== Ports zum DC"
foreach ($p in 9389, 5985, 389, 88) { '{0,-5} {1}' -f $p, (Test-NetConnection dc-andrija.ec2.andrija.m159 -Port $p -WarningAction SilentlyContinue).TcpTestSucceeded }
"== RSAT (ActiveDirectory-Modul) gegen den DC"
Import-Module ActiveDirectory
Get-ADDomain -Server dc-andrija.ec2.andrija.m159 | Format-List DNSRoot, NetBIOSName, DomainMode, PDCEmulator
Get-ADUser -Filter * -SearchBase 'OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159' -Server dc-andrija.ec2.andrija.m159 | Measure-Object | Select-Object @{n='Benutzer in OU=Andrija_AG';e={$_.Count}}
Get-ADComputer wac-andrija -Server dc-andrija.ec2.andrija.m159 | Format-List Name, DistinguishedName, Enabled
"== DNS-Konsole (RSAT-DNS) gegen den DC"; Get-DnsServerZone -ComputerName dc-andrija.ec2.andrija.m159 | Where-Object { -not $_.IsAutoCreated } | Format-Table ZoneName, ZoneType, IsDsIntegrated -AutoSize
"== GPMC"; Get-GPO -All -Domain ec2.andrija.m159 -Server dc-andrija.ec2.andrija.m159 | Measure-Object | Select-Object @{n='GPOs';e={$_.Count}}
"== WinRM zum DC (Kerberos, Computerkonto)"; Invoke-Command -ComputerName dc-andrija.ec2.andrija.m159 -ScriptBlock { "$env:COMPUTERNAME, WinRM ok, $((Get-Service NTDS).Status)" } -ErrorAction Continue
"== Windows Admin Center"
Get-Service WindowsAdminCenter* | Format-Table Name, Status, StartType -AutoSize
$c = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match 'WindowsAdminCenter|wac' -or $_.FriendlyName -match 'Admin Center' } | Select-Object -First 1
if ($c) { $c | Format-List Subject, FriendlyName, NotAfter, Thumbprint }
"HTTPS-Antwort lokal (ohne Anmeldung): $(curl.exe -k -s -o NUL -w '%{http_code}' https://localhost/)"
Get-NetFirewallRule | Where-Object { $_.DisplayName -match 'Admin Center' } | ForEach-Object { [pscustomobject]@{Regel=$_.DisplayName; Aktiv=$_.Enabled; Port=($_ | Get-NetFirewallPortFilter).LocalPort} } | Format-Table -AutoSize
