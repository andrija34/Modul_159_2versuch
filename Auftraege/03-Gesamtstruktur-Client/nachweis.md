# Auftrag 03 – Nachweis (Umsetzung 27.10.2026)

Ausgeführt per SSM Run Command: `03-dc-promote.ps1 -Phase Promote` → Neustart → `-Phase Konfig`, danach `03-client-join.ps1` und `03-rdp-konzept.ps1`. Kennwörter (DSRM, Join-Konto) liegen als SecureString im SSM Parameter Store (`/m159/...`), nicht im Repo.

## Promotion

```text
Success Restart Needed Exit Code Feature Result
True    No             Success   {Active Directory Domain Services, DNS Server...}
WARNING: A delegation for this DNS server cannot be created because the authoritative parent zone cannot be found ...
Message        : You must restart this computer to complete the operation.
Context        : DCPromo.General.4
RebootRequired : True
Status         : Success
```
(Die Delegations-Warnung ist erwartet: `andrija.m159` existiert als öffentliche Zone nicht.)

## Domäne / Forest

```text
DNSRoot     : ec2.andrija.m159
NetBIOSName : EC2
DomainMode  : Windows2025Domain
PDCEmulator : dc-andrija.ec2.andrija.m159
Name        : ec2.andrija.m159
ForestMode  : Windows2025Forest
```

## DNS: Weiterleitung, Zonen, nslookup in beide Richtungen

```text
Forwarder IPAddress : 9.9.9.9

ZoneName                 ZoneType IsDsIntegrated IsReverseLookupZone
_msdcs.ec2.andrija.m159  Primary  True           False
ec2.andrija.m159         Primary  True           False
0.0.10.in-addr.arpa      Primary  True           True
16.0.10.in-addr.arpa     Primary  True           True
128.0.10.in-addr.arpa    Primary  True           True
144.0.10.in-addr.arpa    Primary  True           True

PTR: 10 -> dc-andrija.ec2.andrija.m159.   20 -> client-andrija.ec2.andrija.m159.

nslookup dc-andrija.ec2.andrija.m159   -> Address: 10.0.0.10
nslookup 10.0.0.10                     -> Name: dc-andrija.ec2.andrija.m159
nslookup client-andrija.ec2.andrija.m159 (vom Client) -> 10.0.0.20
nslookup 10.0.0.20 (vom Client)        -> client-andrija.ec2.andrija.m159
```
Fehleranalyse: Beim ersten Test lieferte `nslookup 10.0.0.20` „Non-existent domain“, weil der Client seinen PTR nicht selbst registriert hatte. PTR nachgetragen (`Add-DnsServerResourceRecordPtr`), danach erfolgreich.

## AD-Papierkorb

```text
Name          : Recycle Bin Feature
EnabledScopes : {CN=Partitions,CN=Configuration,DC=ec2,DC=andrija,DC=m159, CN=NTDS Settings,CN=DC-ANDRIJA,...}
```

## Client-Join

Vorabtest vom Client (DNS auf 10.0.0.10):
```text
_ldap._tcp.dc._msdcs.ec2.andrija.m159  SRV  600  Answer  dc-andrija.ec2.andrija.m159  0 100 389
53 True  88 True  135 True  139 True  389 True  445 True
```
Nach dem Join:
```text
Name         : CLIENT-ANDRIJA
Domain       : ec2.andrija.m159
PartOfDomain : True
nltest /dsgetdc:ec2.andrija.m159
   DC: \\dc-andrija.ec2.andrija.m159   Address: \\10.0.0.10
   Flags: PDC GC DS LDAP KDC TIMESERV WRITABLE DNS_DC DNS_DOMAIN DNS_FOREST CLOSE_SITE ...
Computerkonto: CN=CLIENT-ANDRIJA,OU=Sekretariat_Computer,OU=Sekretariat,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
               (nach Auftrag 07 verschoben, ursprünglich CN=Computers)
```
Der Join lief mit dem Konto `svc_join` (normaler Domänenbenutzer; `ms-DS-MachineAccountQuota` = 10 erlaubt Domänenbenutzern Joins) – so musste das Domänen-Administratorkennwort nirgends verwendet werden.

## RDP-Konzept

AD (Schritt 1):
```text
GG_RDP_Admins: Administrator
GG_RDP_Users:  skeller, glang (+ bhuber, proth)
```
Client (Schritt 2), lokale Gruppen:
```text
Administratoren:       CLIENT-ANDRIJA\Administrator, EC2\Domain Admins, EC2\GG_RDP_Admins
Remotedesktopbenutzer: EC2\GG_RDP_Users
```
