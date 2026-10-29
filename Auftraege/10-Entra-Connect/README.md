# Auftrag 10 – MS Entra ID & MS Entra Connect (Hybrid Join)

Fragen: [fragen.md](fragen.md) · Alternative: [variante-b-zweiter-dc.md](variante-b-zweiter-dc.md)

Voraussetzung: Azure for Students aktiviert (Planung Kap. 11) und eigener Tenant mit Global Administrator. Der DC braucht Internetzugang (öffentliches Subnetz + Internet Gateway, Port 443 ausgehend).

## 1. Öffentliche Domain als Custom-UPN

1. Bei **dynv6.com** die Zone `andrija-m159.v6.rocks` registrieren.
2. Entra Admin Center → Einstellungen → **Domänennamen** → *Benutzerdefinierte Domäne hinzufügen* `andrija-m159.v6.rocks`.
3. Den angezeigten **TXT-Record** (`MS=ms…`) bei dynv6 in der Zone eintragen.
4. *Überprüfen* → Status „Überprüft“.
5. (Optional als primär festlegen.)

Im EC2-AD: *Active Directory-Domänen und -Vertrauensstellungen* → Eigenschaften → **Alternative UPN-Suffixe** → `andrija-m159.v6.rocks`, dann Benutzer umstellen:
```powershell
Get-ADUser -SearchBase 'OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159' -Filter * |
  ForEach-Object { Set-ADUser $_ -UserPrincipalName "$($_.SamAccountName)@andrija-m159.v6.rocks" }
```

## 2. Entra Connect (Sync) auf dc-andrija

| Schritt | Einstellung |
|---|---|
| 1 | Download *Microsoft Entra Connect* (AzureADConnect.msi) aus dem Entra Admin Center, IE ESC ist aus (Auftrag 02) |
| 2 | Installation → **Benutzerdefiniert** (bzw. Express) |
| 3 | UPN-Suffix-Übersicht: `andrija-m159.v6.rocks` = *Verified* (ohne Custom-Domain wäre `ec2.andrija.m159` „Not added“ → Benutzer erhielten `@…onmicrosoft.com`) |
| 4 | Anmeldemethode **Password Hash Synchronization** = Ja, *Enable single sign-on* |
| 5 | Mit Entra-Global-Admin verbinden, AD-Gesamtstruktur `ec2.andrija.m159` mit Enterprise-Admin (`EC2\Administrator`) → neues Konto `MSOL_…` |
| 6 | Filterung: nur OU **Andrija_AG** synchronisieren; Quellanker `mS-DS-ConsistencyGuid` |
| 7 | *Configuration complete* → Sync starten; in Entra unter Benutzer erscheinen skeller, bhuber, glang, proth mit *On-premises sync enabled = Yes* |

```powershell
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Initial   # alles
Start-ADSyncSyncCycle -PolicyType Delta     # nur Änderungen (läuft automatisch alle 30 Min.)
```

## 3. Hybrid Join (Microsoft Entra hybrid joined)

1. Entra Connect erneut starten → *Geräteoptionen konfigurieren* → **Microsoft Entra Hybrid Join konfigurieren**.
2. Gerätebetriebssysteme: Windows 10 oder neuer, domänengebunden.
3. SCP: Gesamtstruktur `ec2.andrija.m159`, Authentifizierungsdienst *Microsoft Entra ID*, Enterprise-Admin.
4. Computer-OU `OU=Sekretariat_Computer,…` in die Sync-Filterung aufnehmen.
5. GPO `C_Andrija_AG_Hybrid_Join`: Computerkonfiguration → Administrative Vorlagen → Windows-Komponenten → Geräteregistrierung → *Domänencomputer als Geräte registrieren* = Aktiviert. Am Client: `gpupdate /force`, neu starten bzw. Aufgabe *Automatic-Device-Join* auslösen, Delta-Sync.

Prüfung am Client:
```
dsregcmd /status
  AzureAdJoined : YES
  DomainJoined  : YES
  AzureAdPrt    : YES   (als synchronisierter Benutzer angemeldet)
```
In Entra → Geräte erscheint `CLIENT-ANDRIJA` mit Jointyp *Microsoft Entra hybrid joined*.

Hinweis: Der Client ist ein Windows Server 2025. Hybrid Join wird von Windows Server 2016+ unterstützt (Server Core ausgenommen); PRT/SSO-Funktionen sind auf Server teilweise eingeschränkt – Abweichungen werden dokumentiert.

## 4. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Custom Domain verifiziert (5 Schritte) | `images/10-domain-*.png` | ⏳ |
| UPN-Suffix im AD | `images/10-upn.png` | ⏳ |
| Entra Connect Schritte 1–7 | `images/10-connect-*.png` | ⏳ |
| Synchronisierte Benutzer in Entra | `images/10-users.png` | ⏳ |
| Hybrid Join Schritte + `dsregcmd /status` | `images/10-hybrid-*.png`, `images/10-dsregcmd.png` | ⏳ |
