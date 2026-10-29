<#  Auftrag 10 Variante B – Client: beide DCs als DNS, DC-Locator-Test. -Nur Test: nur nltest  #>
param([switch]$NurTest)
$if = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
if (-not $NurTest) { Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 10.0.0.10, 10.0.16.10 }
"== DNS-Server Client"; (Get-DnsClientServerAddress -InterfaceAlias $if -AddressFamily IPv4).ServerAddresses
"== SRV-Records"; Resolve-DnsName _ldap._tcp.dc._msdcs.ec2.andrija.m159 -Type SRV -DnsOnly -ErrorAction SilentlyContinue | Where-Object Type -eq SRV | Format-Table NameTarget, Port -AutoSize
"== Ping DC1/DC2"; foreach ($h in 'dc-andrija','dc2-andrija') { '{0,-12} {1}' -f $h, (Test-Connection $h -Count 1 -Quiet) }
"== nltest /dsgetdc (neu suchen)"; nltest /dsgetdc:ec2.andrija.m159 /force
"== Secure Channel"; nltest /sc_query:ec2.andrija.m159
