# Auftrag 11 – Fragenkatalog (Antworten)

**1. Problem lokaler Profile, Lösung servergespeicherter Profile?**
Lokale Profile liegen nur auf einem PC – bei Gerätewechsel, Neuinstallation oder Defekt sind Desktop, Dokumente und Einstellungen weg bzw. fehlen. Servergespeicherte Profile liegen zentral und stehen an jedem Gerät zur Verfügung (und werden mitgesichert).

**2. Roaming Profile vs. Folder Redirection?**
Roaming Profile kopiert das gesamte Profil bei jeder An- und Abmeldung zwischen Server und PC (langsam bei grossen Profilen, Konfliktgefahr). Folder Redirection leitet nur bestimmte bekannte Ordner (Desktop, Dokumente …) direkt auf eine Freigabe um – nichts wird kopiert, man arbeitet direkt auf dem Server.

**3. FSLogix vs. Roaming Profiles?**
FSLogix speichert das Profil in einem VHD(X)-Container auf der Freigabe und hängt ihn bei der Anmeldung als Laufwerk ein – kein Kopieren. Vorteile: schnelle Anmeldung, weniger Profilkorruption, auch Caches (Outlook OST, Teams) wandern mit.

**4. OneDrive KFM?**
Known Folder Move leitet die bekannten Ordner **Desktop, Dokumente und Bilder** nach OneDrive for Business um und synchronisiert sie in die Cloud.

**5. Mechanismus der KFM-Migration?**
Über eine GPO mit den OneDrive-ADMX-Einstellungen („Silently move Windows known folders to OneDrive“ mit Tenant-ID, „Silently sign in users …“), verknüpft mit der OU der Testbenutzer (`OU=Intern`).

**6. Warum „Prevent users from redirecting … back to their PC“?**
Damit Benutzer die Umleitung nicht rückgängig machen und Daten wieder nur lokal speichern – das würde die Migration aushebeln, Daten wären nicht gesichert und nicht geräteübergreifend verfügbar.

**7. Nachweis geräteübergreifend?**
Datei auf Client 1 erstellt, am Client 2 mit demselben Benutzer angemeldet und geprüft, dass sie erscheint – und umgekehrt (`VonPC2.txt` auf Client 1). Ein Test auf nur einem Gerät beweist kein Roaming.

**8. Woher weiss OneDrive bei stiller Konfiguration, wer angemeldet ist?**
Es nutzt das primäre Windows-Konto: bei hybriden/Entra-Geräten das Primary Refresh Token (PRT) der Windows-Anmeldung – daher automatische Anmeldung ohne Eingabe (setzt Hybrid Join aus Auftrag 10 voraus).

**9. Wo liegen die Profildaten physisch?**
Roaming/FSLogix: auf der Freigabe des Fileservers (`Profiles$`/`FSLogix$` auf dc-andrija, AWS-EBS-Volume); OneDrive KFM: in SharePoint Online (Microsoft-Cloud) mit lokalem Cache. Verfügbar überall, aber abhängig von Netzwerk/Internet, dem Fileserver bzw. Tenant und Lizenz.

**10. Wann FSLogix, wann OneDrive KFM?**
FSLogix bei Terminalservern/VDI (Azure Virtual Desktop, RDS), wo viele Benutzer sich nacheinander auf wechselnden Session-Hosts anmelden. OneDrive KFM bei normalen (mobilen) Clients, wo es vor allem um die bekannten Benutzerordner und Offline-Arbeit geht.
