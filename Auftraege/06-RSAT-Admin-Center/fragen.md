# Auftrag 06 – Fragenkatalog (Antworten)

**1. Was sind RSAT, warum vom Arbeitsplatz aus?**
Remote Server Administration Tools = Verwaltungskonsolen (dsa.msc, gpmc.msc, dnsmgmt.msc, AD-PowerShell) für Serverrollen auf einem Client/Verwaltungsserver. Jede interaktive Anmeldung am DC hinterlässt Anmeldeinformationen (Hashes/Tickets im LSASS-Speicher) und erhöht das Risiko; Remote-Verwaltung ist der Normalfall.

**2. Jump Host?**
Ein einzelner, besonders gehärteter und überwachter Einstiegspunkt. Nur er ist von aussen erreichbar, alle anderen Systeme nur über ihn → Angriffsfläche auf ein System reduziert.

**3. Gewählter Weg von aussen?**
WAC im öffentlichen Subnetz, HTTPS 443 (und RDP) ausschliesslich von meiner öffentlichen IP. Grund: kein kostenpflichtiges NAT-Gateway nötig, trotzdem nicht offen fürs Internet. Produktiv würde ich Jump Host/VPN wählen.

**4. Warum ist ein selbstsigniertes Zertifikat problematisch?**
Die Verbindung ist verschlüsselt, aber es gibt keine überprüfbare Vertrauenskette – der Browser warnt, Benutzer gewöhnen sich ans Wegklicken, und ein Man-in-the-Middle mit eigenem Zertifikat wäre nicht erkennbar.

**5. Wer darf sich am WAC anmelden?**
Nur dedizierte, personenbezogene Admin-Konten (Gateway-Administratoren). Keine Standardbenutzer, keine geteilten Konten – sonst ist nach einem Vorfall nicht nachvollziehbar, wer was getan hat.

**6. Prinzip der geringsten Rechte – wo angewendet?**
Nur so viele Rechte wie nötig: WinRM 5985/5986 nur von 10.0.0.30, 443/3389 nur von meiner IP, Managed AD mit delegiertem `admin` statt Domänen-Admin, Bind-/Dienstkonten ohne Adminrechte.

**7. DC aus dem Managed AD hinzufügen?**
Nötig wären Netzwerkerreichbarkeit (WinRM) und Admin-Anmeldedaten auf dem DC. AWS gibt aber keinen Admin-/RDP-/WinRM-Zugriff auf die Managed-DCs ab – deshalb ist das nicht möglich; verwaltet wird nur über RSAT innerhalb der delegierten OU. Hinzugefügt wird nur der EC2-DC.

**8. Was protokollieren?**
Anmeldungen an Verwaltungssystemen (4624/4625, RDP 1149), Änderungen an Konten und Gruppen (4720, 4728, 4732, 4738), GPO-Änderungen (5136), WAC-Gateway-Log, Zugriffe von aussen (VPC Flow Logs). Und: Logs zentral sammeln und tatsächlich auswerten (SIEM/Alerting).

**9. RDP auf dem DC für alle freigeben?**
Der DC ist das wichtigste System – wer ihn kompromittiert, besitzt die ganze Domäne (alle Hashes, GPOs). Ein offener RDP-Port wird automatisiert angegriffen. Alternative: RSAT/WAC vom Verwaltungsserver, RDP nur für Domänen-Admins und nur über Jump Host/eigene IP.

**10. Übergabe an eine Nachfolgerin?**
Zugangswege und deren Einschränkungen (SG-Regeln, IPs), verwendete Konten und deren Rechte (admin, Gateway-Admins, Dienstkonten), Hostnamen/IPs, Besonderheiten der Absicherung (Zertifikat, WinRM-Einschränkung, Trust). Passwörter nicht in die Doku, sondern separat über einen sicheren Kanal (Passwortmanager).
