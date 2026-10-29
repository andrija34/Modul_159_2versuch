# Auftrag 10 – Fragenkatalog (Antworten)

**1. Was synchronisiert Entra Connect, in welche Richtung?**
Benutzer, Gruppen, Kontakte und (für Hybrid Join) Geräte aus dem lokalen AD nach Entra ID. Das On-Prem-AD ist die führende Quelle („Source of Authority“), Entra ID das Abbild (Writeback nur optional, z. B. Passwort-Writeback).

**2. Password Hash Synchronization?**
Übertragen wird nicht das Klartextpasswort, sondern ein Hash des NT-Hashes (per Salt und 1000× PBKDF2/HMAC-SHA256 abgeleitet). Entra ID kann damit die Anmeldung in der Cloud selbst prüfen – gleiches Passwort wie On-Prem, auch wenn der DC offline ist.

**3. Warum muss der UPN-Suffix zu einer verifizierten Domain passen?**
Entra akzeptiert nur UPNs mit verifizierten Domains. Sonst wird der Benutzer als `skeller@<tenant>.onmicrosoft.com` angelegt – unterschiedliche Anmeldenamen On-Prem/Cloud, SSO und Benutzerfreundlichkeit leiden. `ec2.andrija.m159` ist nicht verifizierbar (keine öffentliche Domain), deshalb `andrija-m159.v6.rocks`.

**4. Initial- vs. Delta-Sync?**
Initial (Full) gleicht alle Objekte ab – nach Installation oder Änderungen an Filterung/Regeln. Delta überträgt nur Änderungen seit dem letzten Lauf und läuft automatisch alle 30 Minuten. `Start-ADSyncSyncCycle -PolicyType Initial | Delta`.

**5. Hybrid Join vs. reiner Entra Join?**
Hybrid: Gerät ist in der lokalen Domäne **und** in Entra ID registriert (zwei Verzeichnisse) – GPOs + Cloud-SSO/Conditional Access. Entra Join: nur in Entra ID, keine lokale Domäne, Verwaltung über Intune.

**6. Nachweis Hybrid Join?**
`dsregcmd /status` → Device State: `AzureAdJoined : YES` und `DomainJoined : YES`; zusätzlich Gerät in Entra mit Jointyp „Microsoft Entra hybrid joined“.

**7. Passwortänderung im AD – sofort in der Cloud gültig?**
Nicht zwingend sofort: Die Passwort-Hash-Synchronisation läuft separat etwa alle 2 Minuten (Delta der übrigen Attribute alle 30 Min.). Nach dieser kurzen Verzögerung gilt das neue Passwort auch in der Cloud.

**8. Warum bleibt das lokale AD führend?**
Eine einzige Quelle der Wahrheit vermeidet Duplikate und widersprüchliche Attribute; synchronisierte Objekte sind in Entra ohnehin schreibgeschützt. Verwaltung bleibt zentral (Skripte, Gruppen, GPOs).

**9. Rolle der Gruppenrichtlinie beim Hybrid Join?**
Der Service Connection Point (SCP) im AD teilt den Clients Tenant und Registrierungsdienst mit; die GPO „Domänencomputer als Geräte registrieren“ lässt die geplante Aufgabe *Automatic-Device-Join* auf allen Clients die Registrierung automatisch durchführen – ohne Handarbeit pro Gerät.

**10. Reale Situation für Hybrid?**
Eine Firma mit bestehendem AD (Fileserver, GPOs, Fachanwendungen mit Kerberos) will Microsoft 365 (Exchange Online, Teams, OneDrive) nutzen: Hybrid erlaubt eine Identität für beide Welten und eine schrittweise Migration in die Cloud.
