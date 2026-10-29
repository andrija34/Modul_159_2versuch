# Nachweis Auftrag 06 – RSAT-Tools & Windows Admin Center

Umgesetzt am 27.10.2026 per SSM Run Command: Instanz und Grundeinstellungen aus [`run-6a.sh`](../../scripts/run-6a.sh) / [`02-init.ps1`](../../scripts/02-init.ps1), Domänenbeitritt [`03-client-join.ps1`](../../scripts/03-client-join.ps1), Installation [`26-wac-install.ps1`](../../scripts/26-wac-install.ps1), WinRM auf dem DC [`27-dc-winrm.ps1`](../../scripts/27-dc-winrm.ps1), Prüfung [`29-wac-check.ps1`](../../scripts/29-wac-check.ps1), Ablauf [`run-06b.sh`](../../scripts/run-06b.sh).

**Anpassung an Variante B von Auftrag 05:** Weil kein AWS Managed AD erstellt wurde (Kosten), ist `wac-andrija` Mitglied der eigenen Domäne `ec2.andrija.m159`. Die RSAT-Konsolen verwalten deshalb `dc-andrija`. Ein Vorteil: Weil beide in derselben Domäne sind, läuft WinRM über Kerberos, und `TrustedHosts` muss nicht gesetzt werden.

## 1. Instanz und Domänenbeitritt

| Punkt | Wert |
|---|---|
| Instanz | `wac-andrija` (i-0bf2fc5a3de7730fb), Windows Server 2025, t3.medium |
| Netz | m159-public-1a, **10.0.0.30**, SG `m159-sg-client` |
| Grundeinstellungen | wie Auftrag 02 (Hostname, de-CH, Zeitzone, IPv6 aus, Ping) |
| Domäne | `ec2.andrija.m159` (Beitritt mit `svc_join`) |

```
Name         : WAC-ANDRIJA
Domain       : ec2.andrija.m159
PartOfDomain : True
DistinguishedName : CN=WAC-ANDRIJA,CN=Computers,DC=ec2,DC=andrija,DC=m159
```

## 2. RSAT

```
Success : True   RestartNeeded : No
Features: GPMC, RSAT, RSAT-AD-AdminCenter, RSAT-AD-PowerShell, RSAT-AD-Tools, RSAT-ADDS, RSAT-ADDS-Tools,
          RSAT-ADLDS, RSAT-DNS-Server, RSAT-Role-Tools
GPMC Installed · RSAT-AD-Tools Installed · RSAT-DNS-Server Installed
```

**RSAT-Test gegen den DC** (als Computerkonto, d. h. nur mit Leserechten):

```
== Ports zum DC     9389 True · 5985 True · 389 True · 88 True
DNSRoot     : ec2.andrija.m159      NetBIOSName : EC2
DomainMode  : Windows2025Domain     PDCEmulator : dc-andrija.ec2.andrija.m159
Benutzer in OU=Andrija_AG : 6
GPOs                      : 15
```

**Fehler & Lösung:** Beim ersten Lauf meldeten die AD-Cmdlets *„Unable to contact the server … Active Directory Web Services“*. Grund: Das AD-PowerShell-Modul und das Active Directory Administrative Center sprechen **AD Web Services auf TCP 9389**, und dieser Port fehlte in `m159-sg-dc`. Ich habe ihn nur VPC-intern (10.0.0.0/16) ergänzt, danach funktionierte alles.

## 3. Windows Admin Center

```
Download: 133.5 MB  (https://aka.ms/WACDownload, Installer ohne Rückfragen)
WindowsAdminCenter                   Running  Automatic
WindowsAdminCenterAccountManagement  Running  Manual
Port 443 abhörend (LocalAddress ::)
Zertifikat  : CN=WindowsAdminCenterSelfSigned, gültig bis 26.12.2026
HTTPS-Antwort lokal ohne Anmeldung: 403  → Gateway läuft, Zugriff erst nach Anmeldung
```

## 4. WinRM auf dem DC – nur vom WAC

```
Regel                     Profil           Aktiv  Remote
WINRM-HTTP-In-TCP         Domain, Private  True   10.0.0.30
WINRM-HTTP-In-TCP-PUBLIC  Public           True   10.0.0.30
Listener: Address = *, Transport = HTTP
Test-WSMan dc-andrija.ec2.andrija.m159 → wsmid …/wsmanidentity.xsd (erreichbar)
```

Zusätzlich lässt die SG `m159-sg-dc` TCP 5985–5986 **nur von 10.0.0.30/32** zu (seit Auftrag 02). Es gibt also zwei Schutzschichten: die AWS Security Group und die Windows-Firewall.

**Autorisierung geprüft:** `Invoke-Command` und `Get-DnsServerZone` vom WAC aus, ausgeführt als *Computerkonto* `WAC-ANDRIJA$`, enden mit **Access is denied**. Das ist gewollt: Netzwerk und Kerberos-Authentifizierung funktionieren, aber nur Administratoren dürfen den DC fernverwalten. Im WAC meldet man sich deshalb mit einem persönlichen Admin-Konto an.

## 5. Sicherheitsmassnahmen (umgesetzt)

| Massnahme | Umsetzung |
|---|---|
| Kein offener Admin-Port im Internet | Port 443 des WAC ist **nicht** in der SG geöffnet. Zugriff nur nach Freigabe auf die eigene IP (/32) oder per SSM-Portweiterleitung |
| WinRM nur intern | SG 5985/5986 nur von 10.0.0.30/32 + Windows-Firewall RemoteAddress 10.0.0.30 |
| ADWS nur intern | 9389 nur aus 10.0.0.0/16 |
| Least Privilege | Computerkonto bekommt keinen Fernzugriff (Access denied); Verwaltung nur mit persönlichem Admin-Konto |
| Zertifikat | selbstsigniert (Lab); produktiv: Zertifikat einer internen CA |
| Protokollierung | Ereignisprotokoll *WindowsAdminCenter*, Anmeldungen 4624/4625 auf dem DC |

## Offen (interaktiv, durch Andrija)

1. WAC im Browser öffnen: Port 443 kurz nur für die eigene IP freigeben **oder** `aws ssm start-session --target i-0bf2fc5a3de7730fb --document-name AWS-StartPortForwardingSession --parameters portNumber=443,localPortNumber=8443` → `https://localhost:8443`
2. Mit einem Domänen-Admin-Konto anmelden, `dc-andrija.ec2.andrija.m159` hinzufügen → Screenshots `images/06-wac-*.png`, `images/06-dc-im-wac.png`
3. RDP auf `wac-andrija` → `dsa.msc`, `gpmc.msc`, `dnsmgmt.msc` öffnen → Screenshot `images/06-rsat.png`


## GUI-Nachweise
RSAT (dsa.msc) und WAC im Browser: [GUI-Nachweise](../GUI-Nachweise.md#auftrag-06--rsat--wac)
