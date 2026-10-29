# Auftrag 03 – Fragenkatalog (Antworten)

**1. Was passiert bei der Promotion mit dem DNS?**
Die DNS-Serverrolle wird mitinstalliert, es entstehen die AD-integrierten Zonen `ec2.andrija.m159` und `_msdcs.ec2.andrija.m159`. Der Netlogon-Dienst registriert die DC-Dienste selbst als SRV-Records (`_ldap._tcp`, `_kerberos._tcp`, `_gc._tcp` …) und den A-Record des DC.

**2. Woher weiss ein Client, welcher Server sein DC ist?**
Über DNS (DC-Locator): Der Client fragt seinen konfigurierten DNS-Server nach dem SRV-Record `_ldap._tcp.dc._msdcs.ec2.andrija.m159`, erhält `dc-andrija` + Port 389 und löst dessen A-Record auf. Danach prüft er per CLDAP (UDP 389) den DC. Kein Broadcast.

**3. Wozu die Reverse-Lookup-Zone?**
Sie löst IP → Name über PTR-Records auf. Ohne sie liefert `nslookup 10.0.0.10` keinen (bzw. bei AWS einen falschen `ip-…ec2.internal`) Namen. Das betrifft Diagnose, Logs, manche Dienste (z. B. Kerberos mit Reverse-Lookup), nicht aber die Grundfunktion der Anmeldung.

**4. Was passiert beim Domain-Join?**
Im AD wird ein Computerkonto (`CN=CLIENT-ANDRIJA,CN=Computers`) mit SPNs angelegt. Der Client erhält ein eigenes Maschinenkennwort (wechselt alle 30 Tage) und baut damit einen sicheren Kanal (Secure Channel) zum DC auf. Domänen-Admins werden lokale Admins, Domänen-Benutzer lokale Benutzer. Der Computer ist nun selbst ein Sicherheitsprinzipal und kann GPOs erhalten.

**5. Warum nicht Router oder 8.8.8.8 als DNS am Client?**
Diese kennen die interne Zone `ec2.andrija.m159` und deren SRV-Records nicht. Der Client findet keinen DC → Join scheitert, Anmeldung nur mit zwischengespeicherten Anmeldeinformationen, keine GPOs. Internet-Namen löst der DC über seine Weiterleitung 9.9.9.9 ohnehin auf.

**6. Domäne, Struktur (Tree), Gesamtstruktur (Forest)?**
Domäne = Verwaltungs-, Sicherheits- und Replikationseinheit (z. B. `ec2.andrija.m159`). Tree = eine oder mehrere Domänen mit zusammenhängendem DNS-Namensraum (Parent/Child). Forest = äusserste Grenze mit gemeinsamem Schema, gemeinsamer Konfiguration und Global Catalog; transitive Vertrauensstellungen zwischen allen Domänen. Ich habe mit „Neue Gesamtstruktur“ einen Forest mit einem Tree und einer Domäne aufgebaut (`ec2.andrija.m159` ist zugleich Forest-Root).

**7. NSLOOKUP in beide Richtungen?**
Vorwärts: Name → IP über den **A-Record** (`nslookup dc-andrija.ec2.andrija.m159`). Rückwärts: IP → Name über den **PTR-Record** (`nslookup 10.0.0.10`), setzt die Reverse-Zone `0.0.10.in-addr.arpa` voraus.

**8. RDP-Konzept?**
Zwei globale AD-Gruppen: `GG_RDP_Admins` (lokale Admins auf Clients) und `GG_RDP_Users` (nur „Remotedesktopbenutzer“). Normale Benutzer dürfen nur auf den Client, nie auf den DC. Von aussen ist RDP per Security Group nur von meiner öffentlichen IP erreichbar, NLA aktiv. Begründung: Ein offener RDP-Port würde innerhalb von Stunden mit Brute-Force angegriffen; Zuweisung über Gruppen statt Einzelpersonen ist nachvollziehbar und skalierbar.

**9. Domänenadmin vs. lokaler Admin?**
Lokaler Admin: Konto in der lokalen SAM-Datenbank des einzelnen Rechners, nur dort gültig – funktioniert auch ohne DC-Verbindung. Domänenadmin: Konto im AD (NTDS.dit auf dem DC), gilt domänenweit und ist automatisch Mitglied der lokalen Administratoren aller Domänenmitglieder.

**10. Client findet die Domäne nicht – drei Prüfungen?**
1. DNS-Einstellung des Clients (`ipconfig /all`: zeigt DNS auf 10.0.0.10? `nslookup -type=SRV _ldap._tcp.dc._msdcs.ec2.andrija.m159`).
2. Erreichbarkeit des DC (`ping 10.0.0.10`, `Test-NetConnection -Port 389/88/445` – Security Group/Firewall).
3. Zeitabweichung (`w32tm /stripchart /computer:10.0.0.10`; Kerberos toleriert max. 5 Minuten).
Reihenfolge vom Schnellen/Häufigsten zum Komplexeren – DNS ist die häufigste Ursache.
