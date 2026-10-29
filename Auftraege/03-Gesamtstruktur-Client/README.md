# Auftrag 03 – Gesamtstruktur (erster DC) & Client

Fragen: [fragen.md](fragen.md) · Skripte: [`03-dc-promote.ps1`](../../scripts/03-dc-promote.ps1), [`03-client-join.ps1`](../../scripts/03-client-join.ps1), [`03-rdp-konzept.ps1`](../../scripts/03-rdp-konzept.ps1)

## 1. AD DS installieren und DC promoten (dc-andrija)

1. Statische IP 10.0.0.10/20, Gateway 10.0.0.1, DNS 127.0.0.1 (DC ist sein eigener DNS).
2. Server-Manager → Rollen hinzufügen → **Active Directory-Domänendienste** (+ DNS).
3. Server zum DC heraufstufen → **Neue Gesamtstruktur hinzufügen**, Stammdomäne `ec2.andrija.m159`.
4. Funktionsebene Windows Server 2025, DNS-Server + Globaler Katalog angehakt, DSRM-Kennwort ‹Secrets›.
5. NetBIOS-Name `EC2`, Standardspeicherorte (`C:\Windows\NTDS`, `C:\Windows\SYSVOL`) belassen, Neustart.

Gleiches Ergebnis per Skript: `.\03-dc-promote.ps1 -Phase Promote`, nach dem Neustart `-Phase Konfig`.

## 2. DNS

| Anforderung | Umsetzung |
|---|---|
| Weiterleitung 9.9.9.9 | DNS-Manager → Server → Eigenschaften → Weiterleitungen (`Set-DnsServerForwarder 9.9.9.9`) |
| Forward-Zone | `ec2.andrija.m159` + `_msdcs.ec2.andrija.m159` entstehen bei der Promotion automatisch (AD-integriert) |
| Reverse-Zonen je Subnetz | `0.0.10.in-addr.arpa` (public-1a), `16.0.10.in-addr.arpa` (public-1b), `128.0.10.in-addr.arpa` (private-1a), `144.0.10.in-addr.arpa` (private-1b) – AD-integriert, nur sichere dynamische Updates. Pro /20 wird der jeweils genutzte /24-Bereich angelegt, in dem die Hosts liegen. |
| PTR-Records | DC: A-Record → Eigenschaften → „Zugehörigen PTR aktualisieren“; Client nach Join ebenso (`ipconfig /registerdns`) |
| Test vorwärts/rückwärts | `nslookup dc-andrija.ec2.andrija.m159` → 10.0.0.10 · `nslookup 10.0.0.10` → dc-andrija.ec2.andrija.m159 |

**Warum 9.9.9.9 statt 8.8.8.8?** Quad9 wird von einer gemeinnützigen Stiftung mit Sitz in der Schweiz betrieben (Schweizer Datenschutzrecht), speichert keine personenbezogenen IP-Logs und blockiert bekannte Malware-/Phishing-Domains (Threat-Intelligence). Google (8.8.8.8) ist kommerziell, ohne Malware-Filter, und Anfragedaten fliessen in ein werbefinanziertes Ökosystem.

**Warum Reverse-Zonen bei AWS wichtig sind:** Ohne eigene Reverse-Zone beantwortet der AWS-Resolver PTR-Anfragen mit `ip-10-0-0-10.ec2.internal` – der Reverse-Lookup liefert dann einen falschen FQDN.

## 3. AD-Papierkorb

Active Directory-Verwaltungscenter → Domäne → **Papierkorb aktivieren** (oder `Enable-ADOptionalFeature 'Recycle Bin Feature'`). Prüfung: `Get-ADOptionalFeature -Filter 'Name -like "Recycle*"'` zeigt `EnabledScopes`.

## 4. Client in die Domäne

1. DNS des Clients auf **10.0.0.10** setzen (nicht AWS-DNS, nicht 8.8.8.8).
2. Ports prüfen: `Test-NetConnection dc-andrija.ec2.andrija.m159 -Port 88/135/139/389/445` und SRV-Record `_ldap._tcp.dc._msdcs.ec2.andrija.m159`.
3. `sysdm.cpl` → Ändern → Domäne `ec2.andrija.m159` → `EC2\Administrator` → Neustart.
4. Computerkonto erscheint in `CN=Computers` (später in Auftrag 07 verschoben), PTR des Clients aktualisieren.

Anmeldeformen: `.\Administrator` bzw. `client-andrija\Administrator` = lokal · `EC2\skeller` = Domäne via NetBIOS · `skeller@ec2.andrija.m159` = Domäne via UPN/DNS.

## 5. RDP-Konzept

| Gruppe (global) | Mitglieder | Zuweisung auf dem Client | Wirkung |
|---|---|---|---|
| `GG_RDP_Admins` | Administrator (+ künftige Admin-Konten) | lokale Gruppe **Administratoren** | RDP + volle lokale Adminrechte |
| `GG_RDP_Users` | Testbenutzer skeller, bhuber, glang, proth | lokale Gruppe **Remotedesktopbenutzer** | Nur RDP-Anmeldung, keine Adminrechte |

- Auf dem **DC** ist RDP nur für Domänen-Admins erlaubt (Standard), normale Benutzer nie.
- Von aussen ist RDP nur von meiner öffentlichen IP erlaubt (Security Group), NLA bleibt aktiv.
- Schritt 1: Gruppen im AD anlegen (`.\03-rdp-konzept.ps1 -Teil DC`). Schritt 2: auf dem Client `sysdm.cpl` → Remote → Benutzer auswählen → `GG_RDP_Users` (bzw. `-Teil Client`).
- Später (Auftrag 07) liesse sich das zentral über eine GPO „Eingeschränkte Gruppen“ abbilden.

## 6. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Server-Manager mit AD DS / DNS | `images/03-servermanager.png` | ⏳ |
| DNS-Weiterleitung 9.9.9.9 | `images/03-dns-forwarder.png` | ⏳ |
| Forward- + Reverse-Zonen | `images/03-dns-zonen.png` | ⏳ |
| `nslookup` vorwärts + rückwärts (DC und Client) | `images/03-nslookup.png` | ⏳ |
| AD-Papierkorb aktiviert | `images/03-papierkorb.png` | ⏳ |
| Client-Join (Willkommen in der Domäne) + `sysdm.cpl` | `images/03-join.png` | ⏳ |
| Client in dsa.msc | `images/03-dsa-client.png` | ⏳ |
| RDP-Konzept Schritt 1 + 2 | `images/03-rdp-1.png`, `images/03-rdp-2.png` | ⏳ |
