<#  Auftrag 10 Variante B – DC1 bekommt DC2 als sekundaeren DNS-Server  #>
$if = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 127.0.0.1, 10.0.16.10
(Get-DnsClientServerAddress -InterfaceAlias $if -AddressFamily IPv4).ServerAddresses
