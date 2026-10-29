# Nachweis Auftrag 10 – Variante B: Zweiter Domain Controller & Replikation

Umgesetzt am 27.10.2026 per SSM Run Command. Ablauf: [`run-10b.sh`](../../scripts/run-10b.sh), Skripte [`20-svc-admin.ps1`](../../scripts/20-svc-admin.ps1), [`21-dc2-promote.ps1`](../../scripts/21-dc2-promote.ps1), [`22-dc2-konfig.ps1`](../../scripts/22-dc2-konfig.ps1), [`23-repl-test.ps1`](../../scripts/23-repl-test.ps1), [`24-client-dns2.ps1`](../../scripts/24-client-dns2.ps1), [`25-dc1-dns2.ps1`](../../scripts/25-dc1-dns2.ps1).

## Teil A – Zweiter DC

| Punkt | Wert |
|---|---|
| Instanz | `dc2-andrija` (i-0f165f072e6fd46c4), Windows Server 2025, t3.medium |
| Netz | **m159-public-1b (us-east-1b)**, 10.0.16.10 – andere Availability Zone als DC1 → Ausfallsicherheit |
| SG | `m159-sg-dc` |
| DNS beim Heraufstufen | 10.0.0.10 (DC1), danach 127.0.0.1 |
| Heraufstufung | `Install-ADDSDomainController -DomainName ec2.andrija.m159 -InstallDns` (zusätzlicher DC, **keine** neue Gesamtstruktur) |
| Anmeldedaten | temporäres Konto `svc_m159admin` (Domain + Enterprise Admins, Kennwort nur im SSM Parameter Store) → **nach dem Test deaktiviert** (`Enabled: False`) |

```
Name        IPv4Address IsGlobalCatalog OperationMasterRoles
DC2-ANDRIJA 10.0.16.10  True            {}
DC-ANDRIJA  10.0.0.10   True            {SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster}
dcdiag /test:replications /test:advertising → ExitCode 0 (keine Fehler)
```

**DNS:** DC2 hostet alle AD-integrierten Zonen automatisch (Replikation über die Anwendungspartitionen):

```
_msdcs.ec2.andrija.m159  Primary True Forest
0.0.10.in-addr.arpa      Primary True Forest   (+ 16/128/144.0.10.in-addr.arpa)
ec2.andrija.m159         Primary True Domain
```

DC1 zeigt jetzt auf `127.0.0.1, 10.0.16.10`, DC2 auf `10.0.0.10, 127.0.0.1`, der Client auf `10.0.0.10, 10.0.16.10`.

## Teil B – Replikation und Namenskontexte

```
== Namenskontexte (Partitionen)
DC=ec2,DC=andrija,DC=m159                       ← Domain (Benutzer, Gruppen, Computer)
CN=Configuration,DC=ec2,DC=andrija,DC=m159      ← Konfiguration (Standorte, Dienste) – ganzer Forest
CN=Schema,CN=Configuration,DC=ec2,...           ← Schema – ganzer Forest
DC=DomainDnsZones,DC=ec2,DC=andrija,DC=m159     ← DNS-Anwendungspartition (Domäne)
DC=ForestDnsZones,DC=ec2,DC=andrija,DC=m159     ← DNS-Anwendungspartition (Forest)

== repadmin /replsummary
Source DSA      largest delta  fails/total  %% error
DC-ANDRIJA      05m:13s        0 / 5        0
DC2-ANDRIJA     01m:47s        0 / 5        0
Destination DSA
DC-ANDRIJA      01m:47s        0 / 5        0
DC2-ANDRIJA     05m:13s        0 / 5        0

== repadmin /showrepl (Auszug DC2)
DC=ec2,DC=andrija,DC=m159               Default-First-Site-Name\DC-ANDRIJA via RPC  … was successful.
CN=Configuration,DC=ec2,DC=andrija,DC=m159  … was successful.
CN=Schema,CN=Configuration,…            … was successful.
```

5 Partitionen, 0 Fehler in beide Richtungen.

## Teil C – Beweis in beide Richtungen

```
== 1) Benutzer auf DC1 anlegen
angelegt auf dc-andrija um 16:19:02
auf dc2-andrija sichtbar nach 9 s: CN=andrija-repl-test,CN=Users,DC=ec2,DC=andrija,DC=m159
== 2) Aenderung auf DC2, Replikation erzwingen, Pruefung auf DC1
SyncAll terminated with no errors.  (5 Partitionen)
Description auf dc-andrija: 'geaendert auf DC2' (nach 0 s)
AttributeName  LastOriginatingChangeDirectoryServerIdentity
description    CN=NTDS Settings,CN=DC2-ANDRIJA,CN=Servers,CN=Default-First-Site-Name,…
```

- **DC1 → DC2:** Der neue Benutzer war nach **9 Sekunden** auf DC2. Grund: Innerhalb eines Standorts benachrichtigt ein DC seine Partner etwa 15 Sekunden nach einer Änderung.
- **DC2 → DC1:** Die Änderung auf DC2 war nach `repadmin /syncall /AdeP` sofort auf DC1. Die Replikations-Metadaten zeigen DC2 als Ursprung der Änderung → Multi-Master: Jeder DC ist beschreibbar.

## Teil D – Ausfalltest

```
== Normalbetrieb (Client)
DNS-Server Client: 10.0.0.10, 10.0.16.10
SRV _ldap._tcp.dc._msdcs: dc2-andrija:389, dc-andrija:389

== DC1 gestoppt (EC2 stop-instances 15:19:40 → gestoppt 15:20:14)
Ping dc-andrija False · dc2-andrija True
nltest /dsgetdc:ec2.andrija.m159 /force
DC: \\dc2-andrija.ec2.andrija.m159   Address: \\10.0.16.10
Flags: GC DS LDAP KDC TIMESERV WRITABLE DNS_DC …
The command completed successfully

== DC1 wieder gestartet → repadmin /replsummary auf DC2
DC-ANDRIJA  0 / 5 Fehler · DC2-ANDRIJA  0 / 5 Fehler
```

Während DC1 aus war, hat der Client über die SRV-Records DC2 als Anmelde- und Kerberos-Server gefunden (KDC, GC, WRITABLE). Nach dem Neustart hat DC1 ohne Fehler nachrepliziert.
Hinweis: `nltest /sc_query` zeigte weiterhin den zwischengespeicherten Secure Channel zu DC1. Dieser wird erst bei der nächsten Prüfung neu aufgebaut; die DC-Suche (`/dsgetdc /force`) ist der aussagekräftige Test.

## Teil E – Entscheide (umgesetzt)

- **FSMO:** Alle 5 Rollen bleiben auf DC1 (siehe `netdom query fsmo`). Bei einem längeren Ausfall würde zuerst der PDC-Emulator mit `Move-ADDirectoryServerOperationMasterRole` übertragen (bzw. übernommen).
- **Global Catalog:** auch auf DC2 (`IsGlobalCatalog True`, Flag `GC`). Sonst gäbe es bei einem Ausfall von DC1 keinen GC, und Anmeldung und UPN-Auflösung würden scheitern.
- **DNS:** DC2 mit AD-integriertem DNS; Clients haben beide DNS-Server eingetragen.

## Fehler & Lösung

Der SSM-Befehl der Heraufstufung blieb nach dem automatischen Neustart (Exit-Code 3010) auf *InProgress* stehen, obwohl der DC fertig war. Ich habe den Status direkt geprüft (`Get-ADDomainController`, `repadmin`) und den hängenden Befehl abgebrochen. Dasselbe Verhalten trat in Auftrag 06 auf (`wac-andrija`).
