<#  Auftrag 10 Variante B – nach Heraufstufung auf dc2-andrija: feste IP, DNS-Reihenfolge, Pruefungen  #>
$if = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
$ip = (Get-NetIPAddress -InterfaceAlias $if -AddressFamily IPv4).IPAddress
"== IP: $ip"
Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 10.0.0.10, 127.0.0.1
"== DC-Liste"; Get-ADDomainController -Filter * | Format-Table Name, IPv4Address, Site, IsGlobalCatalog, OperationMasterRoles -AutoSize
"== FSMO";     netdom query fsmo
"== Namenskontexte"; (Get-ADRootDSE).namingContexts
"== DNS-Zonen auf DC2"; Get-DnsServerZone | Where-Object { -not $_.IsAutoCreated } | Format-Table ZoneName, ZoneType, IsDsIntegrated, ReplicationScope -AutoSize
"== repadmin /replsummary"; repadmin /replsummary
"== repadmin /showrepl";    repadmin /showrepl
"== dcdiag (Kurz)";         dcdiag /test:replications /test:advertising /q; "dcdiag ExitCode $LASTEXITCODE (leer = keine Fehler)"
