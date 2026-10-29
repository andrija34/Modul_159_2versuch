# Auftrag 01 – Fragenkatalog (Antworten)

**1. Warum sollte der interne AD-Domainname nicht identisch mit der öffentlichen Website-Domain sein?**
Ist der interne Name gleich wie die öffentliche Domain (Split-Brain), fragt ein Client im Büro den internen DC. Dieser ist für die Zone autoritativ, kennt aber den öffentlichen Webserver nicht – die Firmen-Website wäre intern nicht erreichbar. Man müsste alle öffentlichen Einträge (www, mail, …) intern doppelt pflegen; das ist aufwendig und fehleranfällig. Deshalb nutze ich `ec2.andrija.m159` intern und eine separate öffentliche Domain als UPN-Suffix.

**2. Welchen internen Domainnamen haben Sie gewählt, und was spricht gegen `.local`?**
`ec2.andrija.m159` (NetBIOS `EC2`) – eine Subdomain meiner eigenen Basisdomäne `andrija.m159`. `.local` ist für Multicast-DNS (mDNS/Bonjour, Avahi) reserviert; Macs, Drucker und Linux-Geräte lösen `.local` lokal per Multicast auf und kollidieren mit dem AD. Zudem stellen öffentliche CAs für `.local` keine Zertifikate mehr aus. Best Practice ist eine Subdomain einer selbst besessenen Domain (z. B. `ad.firma.ch`).

**3. Was ist ein FQDN? FQDN des geplanten DC?**
Fully Qualified Domain Name = Hostname + vollständiger Domainname bis zur Wurzel, eindeutig im DNS-Namensraum. Mein DC: `dc-andrija.ec2.andrija.m159`.

**4. Warum plant man IPs und Hostnamen vorab?**
DNS-Einträge, DNS-Einstellungen der Clients, Firewall-/Security-Group-Regeln, Trusts und Zertifikate hängen an diesen Werten. Eine spätere Änderung zieht viele Anpassungen nach sich. Planung verhindert Doppelvergaben und macht die Umgebung nachvollziehbar.

**5. DNS-Name vs. NetBIOS-Name der Domäne?**
DNS-Name `ec2.andrija.m159` ist hierarchisch und vollständig (für Kerberos, LDAP, DC-Locator). NetBIOS-Name `EC2` ist eine flache Kurzform (max. 15 Zeichen) aus Kompatibilitätsgründen, z. B. für die Anmeldung `EC2\skeller`.

**6. Warum braucht ein DC zwingend eine statische IP?**
Clients finden den DC über DNS-Einträge (A- und SRV-Records), die auf seine IP zeigen, und haben ihn als DNS-Server fest eingetragen. Ändert sich die IP, zeigen Einträge und Client-Konfigurationen ins Leere → keine Anmeldung, keine GPOs. In AWS setze ich die private IP 10.0.0.10 fest beim Erstellen der Instanz.

**7. Wohin gehören Client Secrets und Passwörter?**
Nicht ins Git-Repository (öffentlich, Git-Historie vergisst nichts) und nicht in KI-Prompts. Sie liegen in einer lokalen, per `.gitignore` ausgeschlossenen Datei bzw. im Passwortmanager; die App-Secrets in einer `.env`. In der Doku stehen nur Platzhalter.

**8. Was passiert, wenn man den AD-Domainnamen nachträglich ändern will?**
Mit `rendom.exe` ist ein Domain-Rename möglich, aber komplex und riskant: alle DCs und Clients müssen neu gestartet/angepasst werden, Zertifikate, Exchange/Anwendungen, GPO-Pfade und Trusts sind betroffen. In der Praxis baut man meist neu auf und migriert (z. B. mit ADMT).

**9. Was wurde bei der Cloud-Bereitschaft getestet, was ist Plan B?**
Getestet werden (1) die Aktivierung von Azure for Students und (2) der Zugriff auf den Entra-ID-Tenant mit Tenant-ID (Screenshots in Kap. 11 der Planung). Plan B: Bei einem Fehlschlag Fehlermeldung dokumentieren, Lehrperson informieren und die Varianten B nutzen (Authentik, zweiter DC, S3-Backup, IIS/Kerberos).

**10. Warum ist eine begründete Planung mehr wert als eine Werteliste?**
Begründungen machen Entscheide für Dritte und für eine spätere Übergabe nachvollziehbar und überprüfbar; beim Begründen fallen Fehler auf (z. B. ein DC ohne feste IP). Eine Nachfolgerin versteht, *warum* etwas so ist, und kann sicher ändern.
