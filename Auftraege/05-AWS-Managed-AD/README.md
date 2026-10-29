# Auftrag 05 – AWS Managed Microsoft AD & Forest-Trust

Fragen: [fragen.md](fragen.md) · Alternative: [variante-b-authentik.md](variante-b-authentik.md)

> **Kosten:** AWS Managed AD (Standard Edition) kostet ca. 18 $/Woche. Gemäss Vorgabe wird Auftrag 05/06 am Ende des Moduls umgesetzt und das Directory danach gelöscht. Vor dem Erstellen wird geprüft, ob der Learner Lab den Dienst *Directory Service* erlaubt und genug Guthaben vorhanden ist. Falls nicht → Variante B (Authentik).

## 1. AWS Managed Microsoft AD erstellen

| Schritt | Einstellung |
|---|---|
| 1 | Directory Service → Set up directory → **AWS Managed Microsoft AD** |
| 2 | Edition **Standard**, DNS name `aws.andrija.m159`, NetBIOS `AWS`, Admin-Passwort ‹Secrets› (Benutzer `admin`) |
| 3 | VPC `m159-vpc`, Subnetze **m159-private-1a** + **m159-private-1b** |
| 4 | Review → Create (Dauer ca. 20–40 Min.) |
| 5 | Directory-Details: DNS-Adressen der beiden DCs notieren → Planung Kap. 6 |

## 2. Ports / Security Groups

AWS legt für das Directory eine eigene SG `d-xxxx_controllers` an. Für den Trust müssen beide Seiten sich erreichen:

| Richtung | Ports | Quelle / Ziel |
|---|---|---|
| EC2-DC → AWS-DCs (SG d-xxxx_controllers, Inbound) | 53, 88, 135, 389, 445, 464, 636, 3268–3269, 49152–65535 TCP; 53, 88, 123, 389, 464 UDP; ICMP | **nur 10.0.0.10/32** (mein DC) |
| AWS-DCs → EC2-DC (m159-sg-dc, Inbound) | gleiche Ports | **nur die beiden AWS-DC-IPs** bzw. 10.0.128.0/20 + 10.0.144.0/20 |
| Outbound der AWS-SG | alle → 10.0.0.10/32 | (Standard ist „All traffic“; eingeschränkt) |

Sicherheitsmassnahme: Keine Trust-Ports gegen 0.0.0.0/0, nur die jeweilige Gegenstelle. Die Managed-DCs liegen in privaten Subnetzen ohne öffentliche IP.

## 3. DNS – Bedingte Weiterleitungen

- **EC2-DC:** DNS-Manager → Bedingte Weiterleitungen → Neu: Domäne `aws.andrija.m159`, Master = die zwei AWS-DNS-IPs, „In AD speichern“.
  ```powershell
  Add-DnsServerConditionalForwarderZone -Name aws.andrija.m159 -MasterServers <AWS-DNS1>,<AWS-DNS2> -ReplicationScope Forest
  nslookup -type=SOA aws.andrija.m159
  ```
- **AWS-Seite:** Directory → Networking & security → *Conditional forwarders* → `ec2.andrija.m159` → 10.0.0.10.

## 4. Trust einrichten

**EC2-AD** (Active Directory-Domänen und -Vertrauensstellungen → Eigenschaften `ec2.andrija.m159` → Vertrauensstellungen → Neue Vertrauensstellung):
1. Name: `aws.andrija.m159` · 2. Typ: **Gesamtstruktur-Vertrauensstellung** · 3. Richtung: **Zweiseitig** · 4. Seiten: **Nur diese Domäne** · 5. Authentifizierung: gesamtstrukturweit · 6. Trust-Passwort ‹Secrets› · 7. Nicht bestätigen (Gegenseite fehlt noch).

**AWS-Seite** (Directory → Trust relationships → Add):
1. Type **Forest trust** · 2. Remote domain `ec2.andrija.m159` · 3. gleiches Trust-Passwort · 4. Direction **Two-way**, Conditional forwarder 10.0.0.10.

**Validierung** auf dem EC2-DC: Eigenschaften der Vertrauensstellung → **Überprüfen** → „Vertrauensstellung wurde bestätigt“; zusätzlich in der AWS-Konsole Status **Verified**. Funktionstest: `nltest /sc_verify:aws.andrija.m159` und einem Benutzer aus `AWS\admin` Leserechte auf eine Freigabe geben und Zugriff testen (Authentifizierung ≠ Autorisierung).

## 5. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Directory erstellt (Schritte 1–5) | `images/05-step1..5.png` | ⏳ |
| SG-Regeln Trust (eingeschränkt) | `images/05-sg.png` | ⏳ |
| Bedingte Weiterleitung + `nslookup -type=SOA` | `images/05-forwarder.png` | ⏳ |
| Trust EC2-Seite (7 Schritte) / AWS-Seite (4 Schritte) | `images/05-trust-*.png` | ⏳ |
| Trust validiert | `images/05-validate.png` | ⏳ |
