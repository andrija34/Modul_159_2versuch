# GUI-Nachweise (Bildschirmfotos aus den echten Sitzungen)

Aufgenommen am 28.10.2026. **Wie:** Der Benutzer wird einmalig automatisch an der Konsole angemeldet ([`30-gui-session.ps1`](../scripts/30-gui-session.ps1)). Das Kennwort kommt aus dem SSM Parameter Store, und mit `AutoLogonCount=1` löscht Windows Kennwort und Autologon nach der Anmeldung selbst. Danach startet [`31-gui-shot.ps1`](../scripts/31-gui-shot.ps1) die Programme in genau dieser Benutzersitzung (geplante Aufgabe „nur interaktiv“), fotografiert den Bildschirm (800×600, EC2-Konsolenauflösung) und meldet den Benutzer wieder ab. Das Admin-Konto `svc_m159admin` ist nur während der Aufnahmen aktiv und danach wieder **deaktiviert**.

## Einstieg – Übungen (Mittelerde, nslookup)

![Völker](../images/00-mittelerde-voelker.png) ![Elben](../images/00-mittelerde-elben.png) ![icacls](../images/00-mittelerde-icacls.png)
![nslookup Root](../images/00-nslookup-root.png) ![nslookup ch](../images/00-nslookup-ch.png)

Details: [Übung Berechtigungen](00-Einstieg/uebung-berechtigungen.md) · [Übung nslookup](00-Einstieg/uebung-nslookup-sso.md)

## Auftrag 05 B – Authentik-Weboberfläche

![Übersicht](../images/05b-ak-overview.png) ![Benutzer](../images/05b-ak-users.png) ![Quelle](../images/05b-ak-sources.png) ![Apps](../images/05b-ak-apps.png) ![Policies](../images/05b-ak-policies.png)

Details: [Nachweis 05 B](05-AWS-Managed-AD/nachweis-variante-b.md#weboberfläche-erledigt-29102026)

## Auftrag 02 – AWS-Umgebung

| | |
|---|---|
| ![EC2](../images/02-ec2.png) | 5 Instanzen (DC, DC2 in us-east-1b, Client, WAC, IdP), t3.medium, Security Groups |
| ![Subnetze](../images/02-vpc.png) | 4 Subnetze in 2 AZ: public-1a 10.0.0.0/20, public-1b 10.0.16.0/20, private-1a 10.0.128.0/20, private-1b 10.0.144.0/20 |
| ![SG DC](../images/02-sg-dc.png) | `m159-sg-dc`: AD-Ports nur aus 10.0.0.0/16, WinRM nur von 10.0.0.30/32, RDP nur von der eigenen IP (maskiert) |

## Auftrag 03 – DC

| | |
|---|---|
| ![Server-Manager](../images/03-servermanager.png) | Server-Manager auf `dc-andrija`: Rollen AD DS, DNS, Datei, IIS |
| ![DNS](../images/03-dns-manager.png) | DNS-Manager: Zone `ec2.andrija.m159` (AD-integriert) mit A-Records dc-andrija, dc2-andrija, client-andrija, wac-andrija und **zwei NS-Records** (DC1 + DC2) |

## Auftrag 06 – RSAT & WAC

| | |
|---|---|
| ![RSAT](../images/06-rsat-dsa.png) | `dsa.msc` auf `wac-andrija` (RSAT) – Firmen-OU `Andrija_AG` aufgeklappt |
| ![WAC](../images/06-wac.png) | Windows Admin Center unter `https://wac-andrija.ec2.andrija.m159` mit gültigem (lokal vertrautem) Zertifikat – Anmeldemaske des Gateways. Die Anmeldung selbst erfolgt mit einem persönlichen Admin-Konto (Kennworteingabe durch den Administrator). |

## Auftrag 07 – DIT, GPOs, Laufwerke, CRM, Drucker

| skeller (Sekretariat, intern) | proth (Promoter, extern) |
|---|---|
| ![skeller Desktop](../images/07-crm-skeller-desktop.png) **Web-CRM**-Verknüpfung vorhanden | ![proth Desktop](../images/07-laufwerke-proth-desktop.png) **kein** CRM-Link, dafür **VPN-Anleitung** |
| ![skeller Laufwerke](../images/07-laufwerke-skeller.png) A: Sekretariat, I: Intern, P: Pool | ![proth Laufwerke](../images/07-laufwerke-proth.png) A: Promoter, E: Extern, P: Pool |
| ![skeller Drucker](../images/07-drucker-skeller.png) Drucker_Farbe + Drucker_SW per GPO | ![proth Drucker](../images/07-drucker-proth.png) Drucker_Farbe + Drucker_SW per GPO |

| | |
|---|---|
| ![OUs](../images/07-ous-dsa.png) | `dsa.msc`: DIT `Andrija_AG` → Dienstkonten, Extern/Promoter, Gruppen, Intern/Buchhaltung, GL, Sekretariat (entspricht dem geplanten DIT) |
| ![GPMC](../images/07-gpmc.png) | GPMC: alle GPOs (C_/U_…), OU-Verknüpfungen und WMI-Filter `WMI_Nur_Windows10` |

## Auftrag 08 – gpresult (GPO-Filterung)

| skeller | proth |
|---|---|
| ![gpresult skeller](../images/08-gpo-gpresult-skeller.png) angewendet u. a. `U_Andrija_AG_Verknuepfung_VPN`, `U_Andrija_AG_Intranetzone`; Gruppen `Remote Desktop Users`, `G_Intranet_Users` | ![gpresult proth](../images/08-gpo-gpresult-proth.png) `U_Andrija_AG_Verknuepfung_CRM` → *Denied (Security)*, `U_Promoter_Textdatei_kopieren` → *Denied (WMI Filter)*; Gruppe `G_Extern` |

## Auftrag 11 – Servergespeicherte Profile (Roaming)

| | |
|---|---|
| ![Roaming Desktop](../images/11-roaming-desktop-wac.png) | skeller meldet sich am **zweiten Rechner** (`wac-andrija`) an: Die auf `client-andrija` erstellte Datei **Roaming-Test** liegt auf dem Desktop |
| ![Roaming Datei](../images/11-roaming-datei-wac.png) | Inhalt: „Roaming-Test erstellt auf CLIENT-ANDRIJA … von skeller“ |

Serverseitig: `C:\Daten\Profiles\skeller.V6\Desktop\Roaming-Test.txt` (Profil wurde beim Abmelden hochgeladen).

## Auftrag 12 B – Aufgabenplanung

![Aufgabe](../images/12b-task.png) `M159-S3-Backup`: *Ready*, Trigger alle 15 Minuten (im Bild ist zusätzlich die vorübergehende Aufnahme-Aufgabe `M159-GUI` zu sehen).

## Auftrag 13 B – Browser-SSO (Kerberos)

![SSO](../images/13b-browser-sso-skeller.png) skeller öffnet `http://dc-andrija.ec2.andrija.m159/` in Edge: Die geschützte Seite erscheint **ohne Kennwortabfrage**, die Anmeldung läuft automatisch über Kerberos (Intranetzone per GPO). Der Umlaut wird falsch angezeigt (`geschÃ¼tzten`): Windows PowerShell 5.1 liest Skripte ohne BOM als ANSI, dadurch wurde das „ü“ im Skript doppelt kodiert. Lösung: im Skript `&uuml;` statt „ü“ verwenden (korrigiert in `13b-iis-kerberos.ps1`).

## Auftrag 07 – 7-Zip per Softwareverteilung

![Deploy](../images/07-7zip-deploy.png) Im GPO-Editor `C_Domain_Software_7-Zip` → Computer Configuration → Policies → Software Settings → Software installation → New → Package → `\\dc-andrija.ec2.andrija.m159\Software$\7z-x64.msi` → **Assigned**.

![Paket](../images/07-7zip-gpme.png) Das Paket `7-Zip 25.01 (x64 edition)` ist zugewiesen (Quelle UNC-Pfad, nicht lokal).

## Auftrag 08 – ldp.exe

![Bind](../images/08-ldp-bind.png) Verbinden mit `dc-andrija.ec2.andrija.m159:389` und Bind als angemeldeter Benutzer (Negotiate). Ergebnis: `Authenticated as: 'EC2\svc_m159admin'`.

![Suche](../images/08-ldp-suche-dialog.png) ![Ergebnis](../images/08-ldp-suche-ergebnis.png) Strukturansicht ab `DC=ec2,DC=andrija,DC=m159`, Suche in `OU=Andrija_AG` mit Scope **Subtree** und dem Filter `(&(objectCategory=person)(objectClass=user)(sAMAccountName=proth))`. Ergebnis: 1 Treffer, `CN=Paul Roth,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,…`. Ein erster Versuch mit Scope *One Level* fand 0 Treffer, weil proth in einer Unter-OU liegt.
