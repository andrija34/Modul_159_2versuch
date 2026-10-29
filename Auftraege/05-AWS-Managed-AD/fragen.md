# Auftrag 05 – Fragenkatalog (Antworten)

**1. Was ist eine Vertrauensstellung?**
Eine Domäne (vertrauende) akzeptiert die Authentifizierung der anderen (vertrauten) Domäne. Benutzer der vertrauten Domäne können Ressourcen der vertrauenden Domäne nutzen, ohne dort ein zweites Konto zu brauchen.

**2. Richtung des Trusts?**
Zweiseitige Gesamtstruktur-Vertrauensstellung zwischen `ec2.andrija.m159` und `aws.andrija.m159`: Benutzer beider Seiten können sich gegenüber Ressourcen der anderen Seite authentifizieren. Merksatz: Die Vertrauensrichtung ist der Zugriffsrichtung entgegengesetzt – vertraut EC2 → AWS, dürfen AWS-Benutzer auf EC2-Ressourcen zugreifen.

**3. Welche Ports braucht ein Trust?**
DNS 53 (TCP/UDP, DCs finden), Kerberos 88 (TCP/UDP), RPC 135 + dynamisch 49152–65535 (TCP), LDAP 389 (TCP/UDP), SMB 445 (TCP, Netlogon/Secure Channel), Kerberos-Passwort 464, Global Catalog 3268, NTP 123 UDP (Zeitsync). Es sind mehrere Dienste beteiligt, nicht nur ein Port.

**4. AWS Managed AD vs. eigener DC auf EC2?**
Managed AD: AWS betreibt zwei DCs (Patching, Backups, Hochverfügbarkeit, Replikation); ich bekomme nur eine delegierte OU und das Konto `admin` (AWS Delegated Administrators), **keine** Domänen-/Enterprise-Admin-Rechte, kein RDP auf die DCs, keine Schemaänderung nach Belieben. Eigener DC: volle Kontrolle, aber volle Verantwortung für Betrieb und Sicherheit.

**5. Warum Trust-Ports nicht gegen das Internet öffnen?**
Verzeichnisdienste sind hochwertige Angriffsziele (Passwort-Spraying, Kerberoasting, RPC-Schwachstellen). Die Gegenstelle hat bekannte IPs, also beschränke ich die SG-Regeln auf 10.0.0.10/32 bzw. die AWS-DC-IPs; die Managed-DCs stehen ohne öffentliche IP in privaten Subnetzen.

**6. Transitivität?**
Vertraut A B und B C, so vertraut A auch C. Gesamtstruktur-Vertrauensstellungen sind zwischen den Domänen der beiden Forests transitiv, aber **nicht** über einen dritten Forest hinweg; externe Trusts sind nicht transitiv.

**7. Kann ein Benutzer der anderen Domäne nun automatisch auf Freigaben zugreifen?**
Nein. Der Trust löst nur die **Authentifizierung** (wer bin ich). Für die **Autorisierung** müssen Berechtigungen vergeben werden – idealerweise globale Gruppe der Gegenseite in eine domänenlokale Gruppe aufnehmen (AGDLP über Domänengrenzen).

**8. Wie wurde nachgewiesen, dass der Trust funktioniert?**
Über „Überprüfen“ in *Active Directory-Domänen und -Vertrauensstellungen* (Bestätigung beider Richtungen), Status „Verified“ in der AWS-Konsole und `nltest /sc_verify:aws.andrija.m159`, zusätzlich Zugriffstest mit einem Konto der Gegenseite. Das Trust-Objekt allein beweist nur, dass es angelegt wurde.

**9. Warum DNS zwischen den Umgebungen?**
Für den Trust muss jede Seite die DCs der anderen über deren SRV-Records finden. Ohne Namensauflösung über die Domänengrenze scheitert der Aufbau. Daher bedingte Weiterleitungen: EC2-DC → AWS-DNS für `aws.andrija.m159`, AWS → 10.0.0.10 für `ec2.andrija.m159`.

**10. Reale Situation für einen Trust statt Zusammenlegung?**
Nach einer Firmenübernahme, bevor migriert wird; bei zwei Firmen einer Holding mit getrennter IT und unterschiedlichen Sicherheitsrichtlinien; bei einer Ressourcen-/Admin-Forest-Architektur (Red Forest) oder wenn eine Tochterfirma rechtlich eigenständig bleiben muss.
