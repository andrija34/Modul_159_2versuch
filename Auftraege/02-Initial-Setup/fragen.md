# Auftrag 02 – Fragenkatalog (Antworten)

**1. Was ist eine Security Group, Unterschied zur Windows-Firewall?**
Eine Security Group ist eine zustandsbehaftete (stateful) Firewall von AWS auf Ebene der Netzwerkschnittstelle – sie filtert *vor* der Instanz, unabhängig vom Betriebssystem. Die Windows-Firewall filtert im Betriebssystem selbst. Beide sind hintereinander geschaltet: Eine Verbindung klappt nur, wenn **beide** den Verkehr erlauben (z. B. Ping: SG-Regel ICMP + Windows-Regel Echo Request).

**2. Welche Ports sind offen und wofür?**
Siehe Planung Kap. 5: 3389 RDP (nur eigene IP), 53 DNS, 88 Kerberos, 135 RPC-Endpoint-Mapper, 139 NetBIOS, 389 LDAP, 445 SMB (SYSVOL/GPO, Freigaben), 464 Kerberos-Passwortänderung, 636 LDAPS, 3268/3269 Global Catalog, 49152–65535 dynamische RPC-Ports, ICMP für Diagnose. Jeder Port hat einen Dienst; AD-Ports sind nur aus 10.0.0.0/16 erreichbar.

**3. Risiko RDP 3389 für 0.0.0.0/0, Alternative?**
Der Port ist weltweit erreichbar und wird innerhalb von Minuten von Scannern gefunden; es folgen automatisierte Passwort-/Brute-Force-Angriffe und Ausnutzung von RDP-Schwachstellen. Alternative: Quelle auf die eigene öffentliche IP (/32) beschränken, Zugang über einen Jump Host/Bastion, VPN oder AWS Systems Manager Session Manager / Fleet Manager.

**4. Private vs. öffentliche IP?**
Die private IP (z. B. 10.0.0.10) wird innerhalb der VPC für AD, DNS, SMB usw. verwendet. Die öffentliche IP dient nur dem Zugriff von aussen (RDP); AWS übersetzt sie per 1:1-NAT am Internet Gateway. Im Betriebssystem (`ipconfig`) ist nur die private Adresse sichtbar.

**5. Warum ändert sich die öffentliche IP nach Stopp, wie verhindern?**
Die automatisch zugewiesene öffentliche IP stammt aus dem AWS-Pool und wird beim Stoppen freigegeben. Mit einer **Elastic IP** wird eine statische öffentliche Adresse reserviert und fest der Instanz zugeordnet.

**6. Stop vs. Terminate?**
*Stop* fährt die Instanz herunter; EBS-Volume und Konfiguration bleiben, ein Neustart ist möglich (Speicher kostet weiter). *Terminate* löscht die Instanz endgültig und standardmässig das Root-Volume – nicht rückgängig zu machen. Deshalb aktiviere ich zusätzlich *Termination protection* für den DC.

**7. Wert von Snapshots, wann erstellen?**
Ein EBS-Snapshot schützt vor eigenen Fehlkonfigurationen (z. B. eine GPO, die die Anmeldung verhindert, oder ein fehlgeschlagener Trust). Erstellen vor grösseren Eingriffen (Promotion, GPOs, Entra Connect) und am Ende eines Arbeitstags.

**8. Stimmen AWS-Werte mit der Planung überein?**
Ja – Abgleich am Beispiel DC: Planung Kap. 7 „dc-andrija, 10.0.0.10, m159-public-1a“ ↔ EC2-Konsole Name `dc-andrija`, Private IPv4 10.0.0.10, Subnetz m159-public-1a (Screenshot `images/02-ec2.png`). Abweichungen würden in der Planung nachgeführt.

**9. Warum eindeutige Hostnamen/IPs, obwohl jeder eine eigene Umgebung hat?**
Bei gemeinsamer Fehlersuche, Screenshots und Abgaben ist sofort erkennbar, welche Umgebung gemeint ist (Hostname enthält meinen Namen). In der Praxis ist Eindeutigkeit Voraussetzung, um Netze zusammenzuschalten (VPN, Peering, Trusts) ohne Adress-/Namenskonflikte.

**10. Kosten über die Ferien?**
Laufende Instanzen kosten pro Stunde Rechenzeit, das Lab-Guthaben ist begrenzt und wäre schnell aufgebraucht. Gegenmassnahme: Instanzen stoppen (Learner Lab stoppt sie zusätzlich bei Sessionende), nicht benötigte Ressourcen (NAT-Gateway, Managed AD) löschen. EBS-Volumes, Snapshots und nicht zugewiesene Elastic IPs kosten auch im gestoppten Zustand.
