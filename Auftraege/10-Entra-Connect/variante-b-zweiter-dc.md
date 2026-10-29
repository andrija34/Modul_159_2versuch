# Auftrag 10 – Variante B: Zweiter Domain Controller & Replikation

Wird umgesetzt, falls kein Microsoft-Cloud-Zugang besteht.

## Teil A – Zweiter DC

| Wert | Planung |
|---|---|
| Hostname | `dc2-andrija.ec2.andrija.m159` |
| IP / Subnetz | 10.0.16.10 / m159-public-1b (andere AZ → Ausfallsicherheit) |
| DNS | bevorzugt **10.0.0.10** (DC1), alternativ 127.0.0.1 |
| SG | m159-sg-dc |

```powershell
.\02-init.ps1 -Hostname dc2-andrija   # + Neustart
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 10.0.0.10,127.0.0.1
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
Install-ADDSDomainController -DomainName ec2.andrija.m159 -InstallDns -Credential (Get-Credential EC2\Administrator) `
   -SafeModeAdministratorPassword (Read-Host -AsSecureString 'DSRM') -Force   # KEINE neue Gesamtstruktur
```
**DNS-Einstellung:** DC2 zeigt zuerst auf DC1, weil er beim Heraufstufen und nach Neustarts die AD-Zone von einem funktionierenden DC braucht (sonst „Inselbildung“, wenn er nur auf sich selbst zeigt und seine Zone noch leer ist). DC1 zeigt später auf DC2 als sekundären DNS.

## Teil B – Replikation prüfen

`repadmin /replsummary`, `repadmin /showrepl`, `netdom query fsmo` auf beiden DCs (Ausgaben als Screenshots).

**Namenskontext (Naming Context/Partition):** Ein eigenständig replizierter Teil der AD-Datenbank. Es gibt mehrere, weil sie unterschiedliche Replikationsreichweiten haben: *Domain* (Objekte der Domäne, alle DCs der Domäne), *Configuration* (Standorte, Dienste – ganzer Forest), *Schema* (Klassen/Attribute – ganzer Forest), dazu Anwendungspartitionen *DomainDnsZones* / *ForestDnsZones* für AD-integrierte DNS-Zonen.

## Teil C – Beweis

1. Auf DC1 `New-ADUser andrija-repl-test` → auf DC2 `Get-ADUser andrija-repl-test -Server dc2-andrija` bis vorhanden, Zeit notieren (innerhalb eines Standorts ca. 15 s Änderungsbenachrichtigung).
2. Auf DC2 `Set-ADUser andrija-repl-test -Description 'geaendert auf DC2'` → `repadmin /syncall /AdeP` → auf DC1 `Get-ADUser … -Server dc-andrija -Properties Description`.

## Teil D – Ausfalltest

DC1 herunterfahren → am Client als skeller anmelden → `nltest /dsgetdc:ec2.andrija.m159` und `echo %LOGONSERVER%` → erwartet `\\DC2-ANDRIJA`. Voraussetzung: Client hat **beide** DNS-Server eingetragen (10.0.0.10, 10.0.16.10), sonst scheitert die DC-Suche. DC1 starten, `repadmin /replsummary`.

## Teil E – Entscheide

- **FSMO:** In einer kleinen Single-Domain-Umgebung bleiben alle fünf Rollen auf DC1 (Microsoft-Empfehlung für kleine Umgebungen: weniger Komplexität). Ausfall: *PDC-Emulator* sofort spürbar (Zeit, Passwortänderungen, Kontosperrungen) → ggf. auf DC2 übertragen; *RID-Master* erst, wenn der RID-Pool erschöpft ist; *Schema/Domain Naming/Infrastructure* selten benötigt. Bei längerem Ausfall Rollen mit `Move-ADDirectoryServerOperationMasterRole` übertragen bzw. übernehmen (seize).
- **Global Catalog:** Ja, auch DC2 – in einer Single-Domain-Umgebung kostet das praktisch nichts, und ohne erreichbaren GC funktionieren Anmeldung (universelle Gruppen) und UPN-Anmeldung nicht. Dagegen spräche nur mehr Replikationsverkehr in Multi-Domain-Forests.
- **DNS:** DC2 trägt ebenfalls DNS (AD-integriert, repliziert automatisch). Clients: DNS1 = 10.0.0.10, DNS2 = 10.0.16.10 – fällt einer aus, löst der andere die SRV-Records auf.

## Fragenkatalog
Die Fragen 1–10 aus [fragen.md](fragen.md) beziehen sich auf Variante A. Für Variante B dienen die Erklärungen oben (Namenskontext, FSMO, GC, DNS) als Antworten.
