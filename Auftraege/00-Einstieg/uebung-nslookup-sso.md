# Übungen – NSLOOKUP & DNS, SSO in verschiedenen Situationen

## NSLOOKUP & DNS

Praktisch ausgeführt am 29.10.2026 auf `client-andrija` (als Einzelbefehle `nslookup -type=NS <Name> <Server>`, gleichwertig zur interaktiven Sitzung).

![nslookup Root](../../images/00-nslookup-root.png)

Standardserver ist der DC (`dc-andrija.ec2.andrija.m159`, 10.0.0.10). Die NS-Abfrage auf „.“ über 8.8.8.8 liefert die 13 Root-Server a–m, als *Non-authoritative answer*.

![nslookup ch](../../images/00-nslookup-ch.png)

Der Root-Server 198.41.0.4 antwortet für `ch.` ohne den Hinweis „Non-authoritative“: Er delegiert an a/b/d/e/f.nic.ch und liefert die Glue-Records (IPv4 und IPv6). Dieselbe Abfrage über 8.8.8.8 ergibt *Non-authoritative answer*.

```
nslookup
> server 8.8.8.8
> set type=NS
> .
> server 198.41.0.4
> ch.
> server 8.8.8.8
> ch.
```

**Mit welchem DNS-Server arbeitet NSLOOKUP standardmässig?**
Mit dem ersten (bevorzugten) DNS-Server der Netzwerkkarte (`ipconfig /all`) – am Client 10.0.0.10 (mein DC). Angezeigt als „Standardserver“ beim Start.

**NS-Abfrage auf „.“** – Ergebnis: die 13 Root-Nameserver `a.root-servers.net` bis `m.root-servers.net`. „.“ ist die Wurzel des DNS-Namensraums; diese Server sind für die Root-Zone autoritativ und verweisen auf die TLD-Server.

**Server 198.41.0.4 (a.root-servers.net), NS-Abfrage auf „ch.“** – Ergebnis: die Nameserver der TLD `.ch` (z. B. `a.nic.ch`, `b.nic.ch`, `d.nic.ch`, `e.nic.ch`, `f.nic.ch` – betrieben von SWITCH) inkl. Glue-Records (IP-Adressen). Der Root-Server delegiert die Zone `ch.` an diese Server (Referral).

**Warum bei 8.8.8.8 „Nicht autorisierende Antwort“, beim Root-Server nicht?**
Der Root-Server hält die Delegation für `ch.` selbst in seiner Zonendatei – er liefert die Information aus erster Hand (autoritativ für die Delegationsdaten bzw. als Referral). 8.8.8.8 ist ein rekursiver Resolver: Er hat die Antwort bei anderen Servern erfragt und gibt sie aus seinem **Cache** weiter, ist für `ch.` aber nicht zuständig → „Nicht autorisierende Antwort“.

## SSO in verschiedenen Situationen

**Aufgabe 1 – Netzlaufwerk (klassisches AD)**
1. Der Benutzer meldet sich mit seinem **Passwort** an Windows an.
2. Windows holt beim Domain Controller ein **Ticket-Granting**-Ticket (TGT).
3. Beim Zugriff auf den Fileserver fragt Windows beim Domain Controller ein **Service**-Ticket für diesen Server an.
4. Windows übergibt das Ticket an den **Fileserver**.
5. Der Server prüft das Ticket und erlaubt den Zugriff auf die **Dateien**.

**Aufgabe 2 – Word Online über Windows-Session (Entra ID)**
1. Der Benutzer meldet sich an Windows an und erhält ein Primary **Refresh** Token (PRT).
2. Im Browser ruft er **word**.office.com auf.
3. Der Browser sendet im Hintergrund eine Anfrage an den Identity Provider (**Entra** ID).
4. Entra ID prüft den PRT und stellt ein **Access** Token für Word Online aus.
5. Der Benutzer ist ohne zusätzliche Eingabe von Benutzername und Passwort in **Word** eingeloggt.

**Aufgabe 3 – Word Online nach Login auf anderer Webseite (Cookie-SSO)**
1. Beim ersten Login bei Outlook gibt der Benutzer Benutzername, Passwort und ggf. **MFA** ein.
2. Der Identity Provider (Entra ID) gibt dem Browser ein **Session-Cookie**.
3. Der Benutzer ruft word.office.com auf, und der Browser schickt automatisch den gespeicherten **Cookie** mit.
4. Entra ID erkennt den Benutzer und stellt direkt ein neues Access Token für **Word** aus.
5. Der Benutzer ist nun ohne erneute Eingabe auch in Word Online **angemeldet**.
