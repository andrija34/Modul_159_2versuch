<#
  Auftrag 03 – Client (client-andrija) in die Domaene ec2.andrija.m159 aufnehmen
  Auf dem Client als lokaler Administrator ausfuehren.
#>
$Domain = 'ec2.andrija.m159'
$DC     = 'dc-andrija.ec2.andrija.m159'

$if = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 10.0.0.10

# Vorab-Tests (Dokumentation): DNS + benoetigte Ports
Resolve-DnsName "_ldap._tcp.dc._msdcs.$Domain" -Type SRV
foreach ($p in 53, 88, 135, 139, 389, 445) {
    $r = Test-NetConnection -ComputerName $DC -Port $p -WarningAction SilentlyContinue
    '{0,-5} {1}' -f $p, $r.TcpTestSucceeded
}

# Join (fragt nach Domaenen-Admin-Anmeldedaten), Computerkonto landet in CN=Computers
. (Join-Path $PSScriptRoot '_secret.ps1')
# Join-Konto 'svc_join' (nur Recht 'Computer zur Domaene hinzufuegen', angelegt in 03-dc-promote -Phase Konfig)
$cred = New-Object System.Management.Automation.PSCredential('EC2\svc_join', (Get-M159Secret '/m159/svc_join' 'Kennwort EC2\svc_join'))
Add-Computer -DomainName $Domain -Credential $cred -Force
exit 3010   # Neustart (unter SSM Run Command; interaktiv: Restart-Computer)
