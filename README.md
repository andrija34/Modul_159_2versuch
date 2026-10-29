# Modul 159 – Directoryservices konfigurieren und in Betrieb nehmen

Andrija Milosevic · PE24c · TBZ
Umgebung: AWS Learner Lab (us-east-1) + Microsoft Entra ID (Azure for Students) · Domäne `ec2.andrija.m159`

## Übersicht und Stand

| # | Auftrag | Doku | Fragen | Umsetzung / Nachweise |
|---|---|---|---|---|
| 00 | Einstieg & Übungen | [Einstiegsfragen](Auftraege/00-Einstieg/einstiegsfragen.md) · [Berechtigungen](Auftraege/00-Einstieg/uebung-berechtigungen.md) · [NSLOOKUP/SSO](Auftraege/00-Einstieg/uebung-nslookup-sso.md) | ✅ | ✅ Praxis: Mittelerde-Berechtigungen + nslookup (Screenshots) |
| 01 | Planung | [README](Auftraege/01-Planung/README.md) | ✅ | ✅ Planung · ✅ Cloud-Bereitschaft (Azure for Students aktiv) |
| 02 | Initial Setup | [README](Auftraege/02-Initial-Setup/README.md) · [Nachweis](Auftraege/02-Initial-Setup/nachweis.md) | ✅ | ✅ VPC, SGs, EC2, Grundeinstellungen · ✅ Konsolen-Screenshots |
| 03 | Gesamtstruktur & Client | [README](Auftraege/03-Gesamtstruktur-Client/README.md) · [Nachweis](Auftraege/03-Gesamtstruktur-Client/nachweis.md) | ✅ | ✅ DC, DNS (9.9.9.9, Reverse-Zonen, nslookup beidseitig), Papierkorb, Client-Join, RDP-Konzept · ✅ Server-Manager/DNS-GUI |
| 04 | Freigaben, Laufwerke, Berechtigungen | [README](Auftraege/04-Freigaben-Berechtigungen/README.md) · [Nachweis](Auftraege/04-Freigaben-Berechtigungen/nachweis.md) | ✅ | ✅ Benutzer/Gruppen, Freigaben, NTFS, ABE, AGDLP, 6 Zugriffstests |
| 05 | AWS Managed AD (B: Authentik) | [README](Auftraege/05-AWS-Managed-AD/README.md) · [Variante B](Auftraege/05-AWS-Managed-AD/variante-b-authentik.md) · [Nachweis B](Auftraege/05-AWS-Managed-AD/nachweis-variante-b.md) | ✅ | ✅ Variante B: Authentik, LDAPS-Source, Sync, Login-Test, OIDC-App mit Policy (intern ✅ / extern ❌) · ✅ UI-Screenshots |
| 06 | RSAT & Admin Center | [README](Auftraege/06-RSAT-Admin-Center/README.md) · [Nachweis](Auftraege/06-RSAT-Admin-Center/nachweis.md) | ✅ | ✅ wac-andrija in Domäne, RSAT, WAC, WinRM nur vom WAC · ✅ RSAT- und WAC-Screenshots |
| 07 | DIT & GPOs | [README](Auftraege/07-DIT-GPOs/README.md) · [Nachweis](Auftraege/07-DIT-GPOs/nachweis.md) | ✅ | ✅ DIT, Passwortrichtlinie, GPOs inkl. Filter, Drucker · ✅ Benutzer-Tests skeller/proth (Laufwerke, CRM, Drucker) als GUI · ✅ 7-Zip zugewiesen und auf dem Client installiert |
| 08 | Suche im Directory | [README](Auftraege/08-Suche-im-Directory/README.md) · [Nachweis](Auftraege/08-Suche-im-Directory/nachweis.md) · [Konfigurationsblatt](Auftraege/08-Suche-im-Directory/konfigurationsblatt.md) | ✅ | ✅ alle Filter + beide Tests + Dienstkonto + GPO · ✅ gpresult skeller/proth (GUI) · ✅ ldp.exe (Bind, Tree, Subtree-Suche) |
| 09 | PowerShell Debugging | [README](Auftraege/09-Automation-Debugging/README.md) · [Nachweis](Auftraege/09-Automation-Debugging/nachweis.md) | ✅ | ✅ Original-Fehler, 2 Läufe (grün/gelb), Benutzer in OUs |
| 10 | Entra Connect (B: 2. DC) | [README](Auftraege/10-Entra-Connect/README.md) · [Variante B](Auftraege/10-Entra-Connect/variante-b-zweiter-dc.md) · [Nachweis B](Auftraege/10-Entra-Connect/nachweis-variante-b.md) | ✅ | ✅ Variante B: DC2 in AZ 1b, GC+DNS, Replikation beidseitig, Ausfalltest · Variante A bewusst nicht umgesetzt (B gewählt) |
| 11 | Servergespeicherte Profile | [README](Auftraege/11-Benutzerprofile/README.md) · [Nachweis](Auftraege/11-Benutzerprofile/nachweis.md) | ✅ | ✅ Profiles$, NTFS, Profilpfade, Roaming-Test an 2 Rechnern (GUI) |
| 12 | Azure Files (B: S3) | [README](Auftraege/12-Azure-Files/README.md) · [Variante B](Auftraege/12-Azure-Files/variante-b-aws-s3.md) · [Nachweis B](Auftraege/12-Azure-Files/nachweis-variante-b.md) | ✅ | ✅ Variante B: Bucket (privat, versioniert), Sync, Aufgabe alle 15 Min, Restore-Test, Screenshots |
| 13 | SSO Python App (A: Entra + B: IIS) | [README](Auftraege/13-SSO-Python-App/README.md) · [Variante B](Auftraege/13-SSO-Python-App/variante-b-iis-kerberos.md) · [Nachweis A](Auftraege/13-SSO-Python-App/nachweis-variante-a.md) · [Nachweis B](Auftraege/13-SSO-Python-App/nachweis-variante-b.md) | ✅ | ✅ Variante A: Entra-App-Registrierung + Login/SSO mit Graph-Profil · ✅ Variante B: IIS/Kerberos (401/200/401) + Browser-SSO (GUI) |

✅ erledigt · ⏳ offen

**GUI-Bildschirmfotos aller Aufträge:** [Auftraege/GUI-Nachweise.md](Auftraege/GUI-Nachweise.md) (Laufwerke, CRM-Link, Drucker, gpresult skeller/proth, Roaming auf 2. Rechner, Browser-SSO, ADUC/GPMC/DNS, Aufgabenplanung, WAC, AWS-Konsole)

## Struktur

- `Auftraege/<Nr>-<Name>/README.md` – Umsetzung, Begründungen, Nachweistabelle
- `Auftraege/<Nr>-<Name>/fragen.md` – Fragenkatalog mit Antworten
- `scripts/` – PowerShell-Skripte zu den Aufträgen (Kennwörter werden immer interaktiv abgefragt)
- `images/` – Screenshots, Diagramme, Videos

## Geheimnisse

Kennwörter, Trust-Passwort und Client Secret sind **nicht** im Repository (`.gitignore`: `geheim/`, `.env`). In der Doku stehen Platzhalter.

## KI-Einsatz

Das Design der README's wurde mit KI erstellt. Einige Aufträge wurden mit KI bescprochen, damit Sie mir Unklarheiten auflösen konnte. Die Scripts wurden von der KI überprüft und überarbeitet bevor man sie ausführte. Die Arbeitsweise mit den Scripts habe ich ausgewählt, da ich zurzeit dies im Betrieb sehr oft mache und mich auskenne in dem Bereich; alle technischen Nachweise stammen aus der eigenen AWS-/Azure-Umgebung.
