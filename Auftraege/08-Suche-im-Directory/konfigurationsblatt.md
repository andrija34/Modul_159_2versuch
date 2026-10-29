# Konfigurationsblatt: Verzeichnisanbindung der Firewall

## Formular 1 – Sophos Firewall, Server type: Active Directory

| Feld in der Oberfläche | Ihr Wert | Woher |
|---|---|---|
| Server type | Active Directory | vorgegeben |
| Server name | `AD_ec2_andrija_m159` | eigene Namenskonvention |
| Server IP/domain | `dc-andrija.ec2.andrija.m159` (10.0.0.10) | Setup-Sheet Kap. 7 |
| Connection security | **SSL/TLS** | Teil 5 |
| Port | **636** | Teil 5 |
| NetBIOS domain | `EC2` | Auftrag 03 |
| ADS username | `svc_fw_ldap` | Teil 5 (Dienstkonto) |
| Password | *nicht eingetragen – siehe Setup-Sheet/Secrets* | Setup-Sheet |
| Validate server certificate | **Ja** (Root-CA des AD in der Firewall importiert) | Teil 5 |
| Display name attribute | `displayName` | Teil 2 |
| Email address attribute | `mail` | Teil 2 |
| Domain name | `ec2.andrija.m159` | Auftrag 03 |
| Search queries | `OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159` | Teil 1 |

**Begründung Search queries:** Die Firewall soll nur den Firmenast sehen, in dem alle Mitarbeitenden liegen – nicht Systemcontainer, Admin- und Dienstkonten (Least Privilege, weniger Treffer, schnellere Suche).

## Formular 2 – OPNsense, LDAP mit Extended Query

| Feld in der Oberfläche | Ihr Wert | Woher |
|---|---|---|
| Hostname or IP address | `dc-andrija.ec2.andrija.m159` | Setup-Sheet Kap. 7 |
| Port value | `636` | Teil 5 |
| Transport | SSL – Encrypted | Teil 5 |
| Protocol version | 3 | vorgegeben |
| Bind credentials – User DN | `CN=svc_fw_ldap,OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159` | Teil 5 |
| Bind credentials – Password | *nicht eingetragen – siehe Setup-Sheet/Secrets* | Setup-Sheet |
| Search scope | Entire Subtree | Teil 2 |
| Base DN | `DC=ec2,DC=andrija,DC=m159` | Teil 1 |
| Authentication containers | `OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159` | Auftrag 07 (DIT) |
| Extended Query | `(&(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))` | Teil 3.3 |
| User naming attribute | `sAMAccountName` | Teil 2 |

## Begründungen Teil 5

**Dienstkonto:** Eigenes Dienstkonto `svc_fw_ldap` in `OU=Dienstkonten`.
- *Nicht* ein bestehender Administrator: Das Passwort liegt in der Firewall-Konfiguration; wird sie kompromittiert, hätte ein Angreifer die ganze Domäne.
- *Nicht* anonym: AD erlaubt anonyme Suchen standardmässig nicht, und man müsste das Verzeichnis für alle öffnen.
- Rechte: Nur Mitglied von *Domänen-Benutzer* → Standard-Leserechte auf Benutzer-/Gruppenobjekte genügen für Bind + Suche inkl. `memberOf` und `userAccountControl`. Kein Schreibrecht, keine Adminrechte, keine interaktive Anmeldung (GPO „Lokal anmelden verweigern“), Kennwort lang und zufällig.

**Port 389 oder 636:** Bei einem Simple Bind über 389 gehen DN **und Passwort im Klartext** über das Netz – jeder, der mitliest, hat danach das Dienstkonto. LDAPS (636) verschlüsselt die gesamte Verbindung mit TLS; mit *Validate server certificate = Ja* ist zudem sichergestellt, dass die Firewall wirklich mit dem DC spricht. Ab Windows Server 2025 werden unsignierte Simple Binds ohnehin abgelehnt. Voraussetzung: DC-Zertifikat (AD CS).

## Abnahme

**Antwort 1:** Aufs VPN kommen alle **aktiven** Benutzer, die direkt oder verschachtelt zu **G_Extern** gehören. Trefferzahl Teil 3.3: **1** – Paul Roth (`proth`). Nicht aufs VPN: alle internen Benutzer (skeller, bhuber, glang), deaktivierte Externe und alle Admin-/Dienstkonten.

**Antwort 2:** Ein neuer Promoter wird im AD angelegt und in G_Promoter aufgenommen – er ist damit automatisch (über G_Promoter → G_Extern) im Filterergebnis. Niemand muss dieses Blatt oder die Firewall anfassen. Dasselbe gilt für eine neue externe Abteilung, deren Gruppe in G_Extern aufgenommen wird (Test 2).
