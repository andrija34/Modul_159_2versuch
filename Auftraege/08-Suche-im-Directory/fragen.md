# Auftrag 08 – Fragenkatalog (Antworten)

**1. Was passiert bei einem LDAP-Bind?**
Der Client meldet sich mit einer Identität (Simple Bind mit DN+Passwort oder SASL/Kerberos) am Verzeichnis an. Danach entscheidet der DC anhand der ACLs, welche Objekte und Attribute sichtbar sind. Ohne Bind: anonym → im AD fast nichts erlaubt.

**2. Base-DN?**
Einstiegspunkt der Suche im Baum. Jeder Teil des Domainnamens wird eine `DC=`-Komponente: `ec2.andrija.m159` → `DC=ec2,DC=andrija,DC=m159`.

**3. Scope One Level vs. Subtree?**
Scope = Suchtiefe ab Base-DN. *Base* nur das Objekt selbst, *One Level* nur direkte Kinder, *Subtree* der ganze Teilbaum. Bei `OU=Buchhaltung` liefert One Level 0 Treffer (dort liegen nur die Unter-OUs), Subtree findet bhuber in `OU=Buchhaltung_Benutzer`.

**4. Verschachtelter Filter Klammer für Klammer?**
`(&(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,…)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))`
`&` UND über alles · Benutzerobjekte · Mitglied (verschachtelt) von G_Extern · `!` NICHT · Bit 2 (deaktiviert) gesetzt. Präfixnotation: Operator steht vor den Bedingungen; `|` wäre ODER.

**5. Einzelnes Bit prüfen?**
Mit der Vergleichsregel **LDAP_MATCHING_RULE_BIT_AND** `1.2.840.113556.1.4.803` (bzw. `…804` BIT_OR): `(userAccountControl:1.2.840.113556.1.4.803:=2)`. Nötig, weil `userAccountControl` viele Flags in einer Zahl bündelt (2 = deaktiviert, 65536 = Passwort läuft nie ab, 512 = normales Konto) – ein Gleichheitsvergleich würde bei jeder anderen Flag-Kombination versagen.

**6. Warum findet memberOf=extern die Promoter nicht?**
`memberOf` enthält nur direkte Mitgliedschaften: proth → G_Promoter. Mitglied von G_Extern ist die Gruppe G_Promoter, nicht proth. Lösung: `LDAP_MATCHING_RULE_IN_CHAIN` `1.2.840.113556.1.4.1941` durchläuft die Gruppenkette. Naiv: 0 Treffer, korrigiert: 1 Treffer (proth).

**7. Warum auf extern statt Promoter?**
„extern“ ist das fachliche Kriterium (Zugriff von aussen). Eine neue externe Abteilung wird nur in G_Extern aufgenommen – Filter und Firewall bleiben unverändert. Bei einem Filter auf Promoter müsste man die Firewall anpassen.

**8. Einfacher Bind über 389 vs. LDAPS?**
Über 389 sind Bind-DN und Passwort im Klartext lesbar (Sniffing). LDAPS verschlüsselt die gesamte Verbindung per TLS auf Port 636 (und authentifiziert den Server über das Zertifikat).

**9. Rechte des Firewall-Dienstkontos?**
Nur Lesen auf Benutzer- und Gruppenobjekte (Standard für Domänen-Benutzer). Kein Schreibrecht, keine Adminrechte, keine interaktive Anmeldung – die Firewall muss nur finden und prüfen, nichts verändern.

**10. Warum kein Domänenadmin als Bind-Konto?**
Das Passwort liegt in der Konfiguration der Applikation und ist nur so sicher wie diese (Backups, Admins der Firewall, Schwachstellen). Eine kompromittierte Applikation gäbe sonst volle Kontrolle über die Domäne. Least Privilege.

**11. Nachweis, dass der Filter nicht zufällig stimmt?**
Gegentests: (1) proth deaktivieren → er verschwindet; (2) neue Gruppe Externe Berater in G_Extern mit Testbenutzer → erscheint ohne Filteränderung. Zusätzlich liefern interne Benutzer (skeller) keinen Treffer.

**12. Wo produktiv eingepflegt, wie geprüft?**
Als Zielgruppenadressierung vom Typ **LDAP-Abfrage** in der GPO `U_Andrija_AG_Verknuepfung_VPN` (eingeschränkt mit `%LogonUser%`). Prüfung mit `gpresult /r` bei proth (Verknüpfung kommt an) **und** bei skeller (bleibt aus).
