# Auftrag 12 – Netzlaufwerk to Azure Files Migration

Fragen: [fragen.md](fragen.md) · Alternative: [variante-b-aws-s3.md](variante-b-aws-s3.md) · Skripte: [`12-azfiles-join.ps1`](../../scripts/12-azfiles-join.ps1)

Gewählte Identitätsvariante: **AD DS** (On-Prem-KDC stellt das Kerberos-Ticket aus) – Entra Domain Services kostet zusätzlich ohne Vorteil, Entra Kerberos funktioniert nur von Windows-**Client**-Betriebssystemen (mein Client ist Windows Server).

## 1. Storage Account + Share

| Schritt | Einstellung |
|---|---|
| Storage Account | Resource Group `rg-m159`, Name `andrijam159files` (global eindeutig, nur Kleinbuchstaben/Ziffern), Region *Switzerland North*, Standard, **LRS** (günstigste Redundanz), Rest Standard |
| Share | Datenspeicher → Dateifreigaben → `daten`, Tier *Transaction optimized*, Kontingent 5 GiB |

**Verbindung über Storage-Account-Key** (Grundlage), am Client:
```powershell
Test-NetConnection -ComputerName andrijam159files.file.core.windows.net -Port 445
cmdkey /add:andrijam159files.file.core.windows.net /user:localhost\andrijam159files /pass:<Key aus Portal – nicht ins Repo>
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\andrijam159files.file.core.windows.net\daten" -Persist
```
Port 445 ausgehend muss in AWS (SG Outbound) und beim Provider offen sein.

## 2. Identitätsbasierter Zugriff mit AD DS

1. Storage Account → Dateifreigaben → *Identitätsbasierter Zugriff* → **Active Directory Domain Services** → Einrichten.
2. AzFilesHybrid auf `dc-andrija` (Skript `12-azfiles-join.ps1`):
   - Modul laden, `Get-Command -Module AzFilesHybrid`
   - `Connect-AzAccount` (Login im Browserfenster durch Andrija)
   - `Join-AzStorageAccount -ResourceGroupName rg-m159 -StorageAccountName andrijam159files -DomainAccountType ComputerAccount -OrganizationalUnitDistinguishedName 'OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159'`
   - Prüfen: Computerobjekt `andrijam159files` in `OU=Dienstkonten` (`Get-ADComputer andrijam159files -Properties ServicePrincipalNames` → SPN `cifs/andrijam159files.file.core.windows.net`), im Portal Status „Konfiguriert“.

## 3. GPO „Define host name-to-Kerberos realm mappings“

GPO `C_Andrija_AG_Kerberos_AzureFiles` (Computerkonfiguration → Administrative Vorlagen → System → Kerberos → *Zuordnungen von Hostnamen zu Kerberos-Bereichen definieren*): Bereich **`EC2.ANDRIJA.M159`** → Hostname `andrijam159files.file.core.windows.net`. Hintergrund: Benutzer melden sich mit dem Custom-UPN (`@andrija-m159.v6.rocks`) an, der Kerberos-Realm ist aber `EC2.ANDRIJA.M159`; ohne Mapping sucht der Client das Ticket im falschen Realm („KDC findet kein passendes Computerkonto“).

## 4. Rollen auf dem Share (RBAC) + Test

| Benutzer | Rolle (Share-Ebene) | Erwartung |
|---|---|---|
| skeller (Sekretariat) | Storage File Data SMB Share **Reader** | Lesen ✔ / Schreiben ✖ |
| bhuber (Buchhaltung) | Storage File Data SMB Share **Contributor** | Lesen + Schreiben ✔ |

Freigabe → Zugriffssteuerung (IAM) → Rollenzuweisung → synchronisierte Benutzer (Entra Connect, Auftrag 10). Zusätzlich NTFS innerhalb des Shares (beide Ebenen greifen, die restriktivere gewinnt).

Test am hybrid-joined Client (`dsregcmd /status` → AzureAdJoined/DomainJoined YES), angemeldet als skeller bzw. bhuber **ohne Passworteingabe**:
```powershell
klist purge; net use Z: \\andrijam159files.file.core.windows.net\daten
New-Item Z:\test-$env:USERNAME.txt     # skeller: Zugriff verweigert, bhuber: OK
klist                                    # Ticket für cifs/andrijam159files.file.core.windows.net
```

## 5. Entra Kerberos (nur Win11-Client, im Moment inaktiv)

Würde erfordern: Identitätsbasierter Zugriff → *Microsoft Entra Kerberos* aktivieren, Admin-Consent für die App des Storage Accounts, GPO „Cloud Kerberos Ticketing aktivieren“ auf Windows-11-Clients. In meiner Umgebung (Windows Server als Client) nicht anwendbar – dokumentiert, nicht umgesetzt.

## 6. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Storage Account + Share | `images/12-storage.png`, `images/12-share.png` | ⏳ |
| Verbindung mit Key, Port 445 Test | `images/12-key.png` | ⏳ |
| AzFilesHybrid / Connect / Join / AD-Objekt | `images/12-join-*.png` | ⏳ |
| GPO Realm-Mapping | `images/12-gpo.png` | ⏳ |
| Rollen IAM | `images/12-iam.png` | ⏳ |
| dsregcmd + SSO-Test skeller (Read) / bhuber (Write) | `images/12-test-*.png` | ⏳ |
