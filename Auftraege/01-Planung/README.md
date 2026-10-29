# Auftrag 01 – Planung AD & Cloud Setup Sheet

> Ziel: Vollständige, begründete Planung aller Parameter der Umgebung, bevor etwas installiert wird.
> Die ursprüngliche Grundplanung (Teil 1.4) liegt unverändert in [grundplanung.md](grundplanung.md).
> Fragenkatalog: [fragen.md](fragen.md)

**Wichtig – Geheimnisse:** Passwörter, Client Secrets und Trust-Passwörter stehen **nicht** in diesem Repository.
Sie werden in einer separaten, lokalen Datei `geheim/setup-secrets.txt` (per `.gitignore` ausgeschlossen) bzw. im Passwortmanager abgelegt.
In der Doku steht an diesen Stellen nur `‹siehe Secrets-Ablage›`.

---

## 1. Übersicht Umgebung

| Komponente | Zweck | Auftrag |
|---|---|---|
| 1× Windows Server 2025 (DC) auf AWS EC2 | Erster Domain Controller + DNS für `ec2.andrija.m159` | 03 |
| 1× Windows Server 2025 (Client) auf AWS EC2 | Client-Rolle (AWS bietet keine Windows-Client-AMIs) | 03 |
| 1× Windows Server 2025 (Admin Center) auf AWS EC2 | Verwaltung AWS Managed AD (RSAT + WAC) | 06 |
| AWS Managed Microsoft AD `aws.andrija.m159` | Zweite AD-Welt mit Forest-Trust zur EC2-Domäne | 05 |
| Entra ID Tenant (Azure for Students) + Entra Connect | Hybride Identität, Hybrid Join | 10–13 |
| Öffentliche Domain (dynv6) als UPN-Suffix | Einheitlicher Anmeldename On-Prem/Cloud | 10 |

Fallback (Varianten B), falls Azure for Students oder das Lab-Budget nicht reicht:
05 → Authentik (Linux-EC2 `idp-andrija`), 10 → zweiter DC `dc2-andrija`, 12 → S3-Backup, 13 → IIS + Kerberos.

## 2. Allgemeine Angaben

| Feld | Wert |
|---|---|
| Vorname | Andrija |
| Nachname | Milosevic |
| Klasse | PE24c |
| Dokumentation (Git-Repository) | https://github.com/andrija34/Modul_159 |

## 3. Ressourcen

| Feld | Wert | Begründung |
|---|---|---|
| AD Second-Level-Domäne (fiktiv) | `andrija.m159` | Eigener, eindeutiger Namensraum; `.m159` ist keine öffentliche TLD → keine Kollision mit Internet-DNS |
| Geplante öffentliche Domain (UPN) | `andrija-m159.v6.rocks` (bei dynv6 zu registrieren, Auftrag 10) | Verifizierbar in Entra ID; getrennt vom internen Namen |
| Azure Education Account | Privates Konto mit Azure for Students (80 $) – Nachweis siehe Kap. 11 | Eigener Tenant mit Global-Admin-Rechten |
| Azure Education Account Passwort | ‹siehe Secrets-Ablage› | Kein Passwort im Repo |

## 4. AWS VPC Setup (Region us-east-1)

Alle Instanzen liegen in einem öffentlichen Subnetz; RDP ist nur von der eigenen öffentlichen IP erreichbar (siehe Kap. 5). Alle AD-Ports sind nur innerhalb der VPC offen.
Es wird **kein NAT-Gateway** angelegt (Kosten); nur falls eine Instanz im privaten Subnetz Internet braucht (Auftrag 06), wird es temporär erstellt und danach gelöscht.

| Komponente | ID (nach Erstellung) | CIDR | Name | AZ |
|---|---|---|---|---|
| VPC | vpc-09238dc9f9e472a33 | 10.0.0.0/16 | m159-vpc | – |
| Öffentliches Subnetz 1 | subnet-0493de1c4a1045496 | 10.0.0.0/20 | m159-public-1a | us-east-1a |
| Öffentliches Subnetz 2 | subnet-0e17b549d0942c036 | 10.0.16.0/20 | m159-public-1b | us-east-1b |
| Privates Subnetz 1 | subnet-0f6fc08c6f1c84ef4 | 10.0.128.0/20 | m159-private-1a | us-east-1a |
| Privates Subnetz 2 | subnet-045a63f2040f37b07 | 10.0.144.0/20 | m159-private-1b | us-east-1b |
| Internet Gateway | (m159-igw) | – | m159-igw | – |

Begründung: Zwei Subnetze in zwei AZs pro Typ, weil AWS Managed AD zwingend zwei Subnetze in verschiedenen AZs verlangt. /20 lässt ausreichend Adressen und ist leicht merkbar.

## 5. AWS Sicherheitsgruppen

`MEINE-IP/32` = öffentliche IP des Laptops beim Einrichten: eigene IP als /32 (aus Datenschutzgründen hier nicht ausgeschrieben; bei IP-Wechsel SG-Regel anpassen). SG-IDs: m159-sg-dc = sg-05addfb2fe672b565, m159-sg-client = sg-04ee9adad1797e372. (Namen dürfen in AWS nicht mit `sg-` beginnen, daher `m159-sg-…`.) VPC-intern = `10.0.0.0/16`.

### SG `m159-sg-dc` (Domain Controller)

| Regeltyp | Port(e) | Quelle | Zweck |
|---|---|---|---|
| RDP | 3389/TCP | MEINE-IP/32 | Administration (bewusst **nicht** 0.0.0.0/0) |
| DNS | 53/TCP+UDP | 10.0.0.0/16 | Namensauflösung, SRV-Records |
| Kerberos | 88/TCP+UDP | 10.0.0.0/16 | Authentifizierung |
| RPC Endpoint Mapper | 135/TCP | 10.0.0.0/16 | RPC-Dienste (Join, Replikation, Trust) |
| NetBIOS Session | 139/TCP | 10.0.0.0/16 | Legacy, beim Join teilweise genutzt |
| LDAP | 389/TCP+UDP | 10.0.0.0/16 | Verzeichniszugriff, DC-Locator (UDP) |
| SMB | 445/TCP | 10.0.0.0/16 | SYSVOL/NETLOGON (GPOs), Freigaben |
| Kerberos PW Change | 464/TCP+UDP | 10.0.0.0/16 | Passwortänderung |
| LDAPS | 636/TCP | 10.0.0.0/16 | Verschlüsseltes LDAP (Auftrag 05B/08) |
| Global Catalog | 3268/TCP | 10.0.0.0/16 | Forest-weite Suche |
| Global Catalog SSL | 3269/TCP | 10.0.0.0/16 | GC über TLS |
| WinRM | 5985–5986/TCP | 10.0.0.30/32 | Windows Admin Center (Auftrag 06) |
| RPC dynamisch | 49152–65535/TCP | 10.0.0.0/16 | Dynamische RPC-Ports |
| ICMP | alle | 10.0.0.0/16 | Ping/Diagnose |

### SG `m159-sg-client` (Client, WAC)

| Regeltyp | Port(e) | Quelle | Zweck |
|---|---|---|---|
| RDP | 3389/TCP | MEINE-IP/32 | Administration / Tests |
| Kerberos | 88/TCP | 10.0.0.0/20, 10.0.128.0/20, 10.0.144.0/20 | Authentifizierung |
| RPC | 135/TCP | dito | RPC Endpoint Mapper |
| NetBIOS | 139/TCP | dito | Legacy |
| LDAP | 389/TCP | dito | Verzeichnis |
| DNS | 53/UDP | dito | Namensauflösung |
| SMB | 445/TCP | dito | Datei-/Druckerfreigabe, GPO |
| RPC dynamisch | 49152–65535/TCP | dito | RPC |
| HTTPS | 443/TCP | MEINE-IP/32 | nur WAC-Instanz (Auftrag 06) |
| ICMP | alle | dito | Ping |

## 6. Active Directory Umgebung

### On-Premises AD (AWS EC2)

| Feld | Wert | Begründung |
|---|---|---|
| AD Third-Level-Domäne 1 | `ec2.andrija.m159` | Subdomain der eigenen Basisdomäne, eindeutig von `aws.andrija.m159` unterscheidbar |
| NetBIOS-Name | `EC2` | Vorschlag der Promotion, ≤ 15 Zeichen |
| Gesamtstruktur-/Domänenfunktionsebene | Windows Server 2025 (bzw. höchste angebotene) | Alle DCs sind 2025 |
| Öffentlicher UPN-Suffix (später) | `andrija-m159.v6.rocks` | Muss in Entra ID verifiziert sein |
| Domänenadministrator | `Administrator` | – |
| Kennwort Domänenadministrator | ‹siehe Secrets-Ablage› | |
| DSRM-/Demote-Kennwort | ‹siehe Secrets-Ablage› | |
| DNS-Weiterleitung | `9.9.9.9` (Quad9) | Datenschutz (Schweizer Stiftung, keine Profilbildung) + blockiert bekannte Malware-Domains |

### Entra ID

| Feld | Wert |
|---|---|
| Entra ID Domain | `‹tenant›.onmicrosoft.com` (nach Aktivierung eintragen) |
| Azure Global Administrator | ‹Konto nach Aktivierung› |
| Kennwort Azure Administrator | ‹siehe Secrets-Ablage› |
| Entra Connect Server | `dc-andrija` (DC aus EC2-AD) |

### AWS Managed AD

| Feld | Wert |
|---|---|
| AD Third-Level-Domäne 2 | `aws.andrija.m159` (NetBIOS `AWS`) |
| Trust-Typ | Forest Trust, zweiseitig (Tree-Root-Konstellation laut Vorlage) |
| AWS Managed Admin User | `admin` |
| AWS Managed Admin Passwort | ‹siehe Secrets-Ablage› |
| DNS-Server 1 / 2 | ‹nach Erstellung des Directorys› |
| Trust-Passwort | ‹siehe Secrets-Ablage› |
| Subnetz 1 | m159-private-1a (10.0.128.0/20) |
| Subnetz 2 | m159-private-1b (10.0.144.0/20) |

## 7. EC2-Instanzen

| Komponente | Hostname / FQDN | Elastic IP | Private IP | Subnetz | DNS 1 | DNS 2 | Lokaler Admin | Kennwort |
|---|---|---|---|---|---|---|---|---|
| IaaS DC | `dc-andrija.ec2.andrija.m159` | 52.44.104.115 | 10.0.0.10 | m159-public-1a | 127.0.0.1 → später 10.0.0.10 | – | Administrator | ‹Secrets› |
| Client | `client-andrija.ec2.andrija.m159` | 100.27.159.175 | 10.0.0.20 | m159-public-1a | 10.0.0.10 | – | Administrator | ‹Secrets› |
| Admin Center | `wac-andrija.aws.andrija.m159` | ‹folgt› | 10.0.0.30 | m159-public-1a | AWS-DNS 1 | AWS-DNS 2 | Administrator | ‹Secrets› |
| *(Var. B 05)* Authentik | `idp-andrija` (Ubuntu) | – | 10.0.0.40 | m159-public-1a | 10.0.0.10 | – | ubuntu (Key) | – |
| *(Var. B 10)* zweiter DC | `dc2-andrija.ec2.andrija.m159` | – | 10.0.16.10 | m159-public-1b | 10.0.0.10 | 127.0.0.1 | Administrator | ‹Secrets› |

Instanztyp: `t3.medium` (2 vCPU, 4 GB) für DC/Client/WAC – Windows Server mit 2 GB ist für GUI + AD zu knapp. Root-Volume 30 GB gp3.
Die Instanzen tragen in AWS den gleichen Namen wie der Hostname.

## 8. Abteilungen & Benutzer

| # | Abteilung | Benutzername (sAMAccountName) | Vorname | Nachname | Kennwort | Bereich |
|---|---|---|---|---|---|---|
| 1 | Sekretariat | `skeller` | Sandra | Keller | ‹Secrets› | intern |
| 2 | Buchhaltung | `bhuber` | Beat | Huber | ‹Secrets› | intern |
| 3 | GL (Geschäftsleitung) | `glang` | Gabriel | Lang | ‹Secrets› | intern |
| 4 | Promoter | `proth` | Paul | Roth | ‹Secrets› | extern |

UPN zuerst `‹user›@ec2.andrija.m159`, ab Auftrag 10 `‹user›@andrija-m159.v6.rocks`.

### Gruppenkonzept (Kurzfassung, Details Auftrag 04)

| Gruppe | Bereich | Mitglieder |
|---|---|---|
| `G_Sekretariat`, `G_Buchhaltung`, `G_GL`, `G_Promoter` | Global, Sicherheit | Benutzer der Abteilung |
| `G_Intern` | Global, Sicherheit | G_Sekretariat, G_Buchhaltung, G_GL |
| `G_Extern` | Global, Sicherheit | G_Promoter |

## 9. Python-App-Registration (Entra ID, Auftrag 13)

| Name | Wert |
|---|---|
| Directory (tenant) ID | ‹nach Registrierung› |
| Application (client) ID | ‹nach Registrierung› |
| Client Secret | ‹nur in `.env` / Secrets-Ablage – nie im Repo› |

## 10. Hinweise / Reihenfolge

1. Lokale Domain zuerst (Aufträge 02–04, 07–09), öffentlicher UPN-Suffix erst in Auftrag 10.
2. Auftrag 05/06 (Managed AD, ca. 18 $/Woche) gemäss Vorgabe **am Schluss** und nur so lange wie nötig betreiben.
3. Vor jedem grösseren Eingriff (Promotion, GPOs, Trust) einen EBS-Snapshot erstellen.
4. Instanzen nach jeder Lab-Session stoppen (Learner Lab stoppt sie zusätzlich beim Session-Ende).

## 11. Cloud-Bereitschaft

| Schritt | Nachweis | Status |
|---|---|---|
| Azure for Students aktivieren | Azure-Portal → Abonnements (geprüft am 27.10.2026): **Azure for Students**, ID `a5aeece9-1cd9-467d-810d-3a4e0f3ec920`, Rolle Besitzer, Status **Aktiv**, Kosten 0.00 | ✅ |
| Entra-ID-Tenant aufrufen | Verzeichnis „Standardverzeichnis“, Domäne `andrijaakistokakigmail.onmicrosoft.com` (privates Konto, nicht TBZ) | ✅ (Screenshot Tenant-Übersicht mit Tenant-ID folgt – die Browser-Erweiterung darf auf portal.azure.com noch keine Screenshots machen) |

Damit sind die Aufträge 10–13 in der Hauptvariante möglich. Plan B wären die Varianten B (siehe Kap. 1).
