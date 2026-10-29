<#  Nachweise auf dem DC (Ausgaben werden in die Doku uebernommen)  #>
Import-Module ActiveDirectory, GroupPolicy, DnsServer
$root = (Get-ADDomain).DistinguishedName
"===== 03: Domaene / Forest"
Get-ADDomain | Format-List DNSRoot, NetBIOSName, DomainMode, PDCEmulator
Get-ADForest | Format-List Name, ForestMode, RootDomain
"===== 03: DNS-Zonen + Weiterleitung"
Get-DnsServerZone | Format-Table ZoneName, ZoneType, IsDsIntegrated, IsReverseLookupZone -AutoSize
(Get-DnsServerForwarder).IPAddress.IPAddressToString
"===== 03: Reverse-Records"
Get-DnsServerResourceRecord -ZoneName '0.0.10.in-addr.arpa' -RRType Ptr | Format-Table HostName, @{n='PTR';e={$_.RecordData.PtrDomainName}} -AutoSize
"===== 03: Computerkonten"
Get-ADComputer -Filter * | Format-Table Name, DistinguishedName -AutoSize
"===== 03: RDP-Gruppen"
foreach ($g in 'GG_RDP_Admins','GG_RDP_Users') { '{0}: {1}' -f $g, ((Get-ADGroupMember $g | ForEach-Object SamAccountName) -join ', ') }
"===== 07: OU-Struktur (DIT)"
Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Andrija_AG,$root" | Sort-Object { ($_.DistinguishedName -split ',').Count }, DistinguishedName | ForEach-Object { $_.DistinguishedName }
"===== 04/07: Benutzer mit DN und Gruppen"
Get-ADUser -Filter * -SearchBase "OU=Andrija_AG,$root" -Properties MemberOf, Department, UserPrincipalName |
  ForEach-Object { '{0,-12} {1,-12} {2}' -f $_.SamAccountName, $_.Department, $_.DistinguishedName; '             Gruppen: ' + (($_.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace 'CN=' }) -join ', ') }
"===== 04: Gruppen"
Get-ADGroup -Filter * -SearchBase "OU=Gruppen,OU=Andrija_AG,$root" | Sort-Object Name | ForEach-Object {
  '{0,-22} {1,-12} {2}' -f $_.Name, $_.GroupScope, ((Get-ADGroupMember $_ | ForEach-Object Name) -join ', ') }
"===== 04: Freigaben + Freigabeberechtigungen"
Get-SmbShare | Where-Object Path -like 'C:\*' | Where-Object Name -notin 'ADMIN$','C$','IPC$','NETLOGON','SYSVOL' | ForEach-Object {
  '{0,-12} {1,-28} ABE={2}' -f $_.Name, $_.Path, $_.FolderEnumerationMode
  Get-SmbShareAccess $_.Name | ForEach-Object { '             {0} {1} {2}' -f $_.AccountName, $_.AccessControlType, $_.AccessRight } }
"===== 07: Passwortrichtlinie"
Get-ADDefaultDomainPasswordPolicy | Format-List ComplexityEnabled, MaxPasswordAge, MinPasswordLength
"===== 07: GPO-Verknuepfungen je OU"
$ous = @($root) + (Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Andrija_AG,$root" | ForEach-Object DistinguishedName)
foreach ($ou in $ous) { $l = (Get-GPInheritance -Target $ou).GpoLinks; if ($l) { $ou; $l | ForEach-Object { '      -> ' + $_.DisplayName } } }
"===== 07: Sicherheitsfilterung"
foreach ($g in 'U_Andrija_AG_Verknuepfung_CRM','C_Domain_Software_7-Zip') { "-- $g"; Get-GPPermission -Name $g -All | Format-Table Trustee, Permission -AutoSize | Out-String -Width 200 }
"===== 07: WMI-Filter"
Get-ADObject -SearchBase "CN=SOM,CN=WMIPolicy,CN=System,$root" -Filter * -Properties msWMI-Name, msWMI-Parm2 | Format-List msWMI-Name, msWMI-Parm2
(Get-GPO 'U_Promoter_Textdatei_kopieren').WmiFilter | Format-List Name, Description
"===== 07: Drucker / Software"
Get-Printer | Where-Object Shared | Format-Table Name, ShareName, DriverName, PortName -AutoSize
Get-ChildItem C:\Software | Format-Table Name, Length
"===== 08: Dienstkonto"
Get-ADUser svc_fw_ldap -Properties MemberOf, PasswordNeverExpires, Description | Format-List DistinguishedName, Enabled, PasswordNeverExpires, Description, MemberOf
"===== 09: Import-Benutzer"
Get-ADUser -Filter * -SearchBase "OU=User,$root" | Format-Table SamAccountName, DistinguishedName -AutoSize
