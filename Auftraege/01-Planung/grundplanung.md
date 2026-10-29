### 1.4 Grundplanung der Umgebung

#### Ziel

Ich plane die Domänennamen, Servernamen und IP-Adressen
meiner Active-Directory-Umgebung.

Die festgelegten Werte dienen als Grundlage für die spätere
Einrichtung in AWS.

#### Allgemeine Angaben

| Feld | Wert |
|---|---|
| Vorname | Andrija |
| Nachname | Milosevic |
| Klasse | PE24c |
| Git-Repository | https://github.com/andrija34/Modul_159 |

#### Geplante Domänen

| Verwendung | Domänenname |
|---|---|
| Fiktive Basisdomäne für das Labor | andrija.m159 |
| Selbst betriebenes Active Directory auf EC2 | ec2.andrija.m159 |
| AWS Managed Microsoft AD für Auftrag 05 | aws.andrija.m159 |
| Öffentliche Domain als UPN-Suffix | Wird nach der Registrierung ergänzt |

Die beiden AD-Domänen erhalten unterschiedliche Namen,
damit die selbst betriebene Umgebung und das AWS Managed AD
eindeutig unterschieden werden können.

Die öffentliche Domain für die spätere Entra-ID-Anbindung
wird separat registriert und ergänzt.

#### Geplantes AWS-Netzwerk

Die Umgebung wird in der AWS-Region `us-east-1` aufgebaut.

| Komponente | Name | Netzwerk | Availability Zone |
|---|---|---|---|
| VPC | m159-vpc | 10.0.0.0/16 | – |
| Öffentliches Subnetz 1 | m159-public-1a | 10.0.0.0/20 | us-east-1a |
| Öffentliches Subnetz 2 | m159-public-1b | 10.0.16.0/20 | us-east-1b |
| Privates Subnetz 1 | m159-private-1a | 10.0.128.0/20 | us-east-1a |
| Privates Subnetz 2 | m159-private-1b | 10.0.144.0/20 | us-east-1b |

Alle Subnetze liegen innerhalb des VPC-Netzes und
überschneiden sich nicht.

Die beiden privaten Subnetze sind für das spätere
AWS Managed Microsoft AD vorgesehen.

Die von AWS vergebenen VPC- und Subnetz-IDs werden
nach der Erstellung ergänzt.

#### Geplante EC2-Instanzen

| Funktion | Hostname | Private IP | Subnetz |
|---|---|---|---|
| Domain Controller mit DNS | dc-andrija | 10.0.0.10 | m159-public-1a |
| Client für Anmeldung und Tests | client-andrija | 10.0.0.20 | m159-public-1a |
| Windows Admin Center für Auftrag 06 | wac-andrija | 10.0.0.30 | m159-public-1a |

Für die EC2-Instanzen wird Windows Server verwendet.
Eine Windows-Server-Instanz übernimmt im Labor die Clientrolle.

Der Verwaltungsserver wird beim entsprechenden Auftrag ergänzt.

#### Geplante vollständige Computernamen

| Hostname | Geplanter FQDN nach dem Domänenbeitritt |
|---|---|
| dc-andrija | dc-andrija.ec2.andrija.m159 |
| client-andrija | client-andrija.ec2.andrija.m159 |
| wac-andrija | wac-andrija.aws.andrija.m159 |

#### DNS-Planung

- Der Domain Controller übernimmt DNS für `ec2.andrija.m159`.
- Der Client verwendet die private DC-Adresse `10.0.0.10` als DNS-Server.
- Der Verwaltungsserver verwendet später die DNS-Adressen
  des AWS Managed AD. Diese werden nach dessen Erstellung ergänzt.

#### Begründung

Die Hostnames zeigen die jeweilige Aufgabe des Servers.

Die privaten IP-Adressen passen zum vorgesehenen Subnetz
und unterscheiden sich eindeutig voneinander.

Für den Domain Controller ist eine gleichbleibende private
IP-Adresse vorgesehen, damit der Client seinen DNS-Server
dauerhaft erreichen kann.

Die öffentlichen Subnetze ermöglichen den geplanten
administrativen Zugang. Dafür werden später öffentliche
IP-Adressen, eine Route zum Internet Gateway und passende
Security-Group-Regeln eingerichtet.

#### Status

Die Grundplanung ist festgelegt.

Cloud-Zugang, Sicherheitsgruppen, Benutzer und weitere
erst später verfügbare Angaben werden schrittweise ergänzt.
