# Auftrag 04 – Fragenkatalog (Antworten)

**1. Welche Berechtigung gilt bei unterschiedlichen Freigabe- und NTFS-Rechten?**
Beim Netzwerkzugriff werden beide ausgewertet, es gilt die **restriktivere**. Lokal (direkt am Server) greift nur NTFS. Praxis: Freigabe grosszügig (Jeder = Ändern), NTFS präzise.

**2. AGDLP?**
**A**ccount (Benutzer) → **G**lobal Group (Rolle/Abteilung) → **D**omain **L**ocal Group (Ressource + Recht) → **P**ermission (nur die DL-Gruppe steht in der ACL). Beispiel: skeller → G_Sekretariat → DL_FS_Buchhaltung_R → Lesen auf `Abteilungen\Buchhaltung`.

**3. Warum keine Berechtigungen direkt an Benutzer?**
Nicht skalierbar und nicht nachvollziehbar: Bei Eintritt, Austritt oder Abteilungswechsel müssten alle betroffenen Ordner-ACLs angepasst werden. Mit Gruppen genügt eine Mitgliedschaftsänderung; Rechte bleiben dokumentierbar.

**4. Access Based Enumeration?**
ABE blendet Ordner/Dateien aus, für die kein Leserecht besteht. Ohne ABE sieht der Benutzer alle Ordner (z. B. „GL“) und erhält erst beim Öffnen eine Fehlermeldung – er erfährt so, dass es sie gibt. Mit ABE sieht er nur, was er öffnen darf.

**5. Gruppenbereich einer eigenen Gruppe?**
`G_Buchhaltung`: Bereich **Global**, Typ Sicherheit – bündelt Benutzer einer Rolle; globale Gruppen können Mitglieder nur aus der eigenen Domäne enthalten, aber überall verwendet werden. `DL_FS_Buchhaltung_C`: **Domänenlokal** – nur für Berechtigungen auf Ressourcen in der eigenen Domäne, kann globale Gruppen (auch aus vertrauten Domänen) aufnehmen. Passt zu AGDLP.

**6. Verschieben vs. Kopieren innerhalb desselben Laufwerks?**
Verschieben innerhalb desselben Volumes ändert nur den Verzeichniseintrag – die Datei behält ihre expliziten Berechtigungen (vererbte Rechte werden am neuen Ort neu berechnet, sofern Vererbung aktiv). Kopieren erzeugt eine neue Datei, die die Berechtigungen des Zielordners erbt. (Verschieben auf ein anderes Volume = Kopieren + Löschen → erbt ebenfalls.)

**7. Vererbung, wann unterbrechen?**
Unterordner übernehmen die Rechte des übergeordneten Ordners. Unterbrechen, wenn ein Bereich abweichend geschützt werden muss (z. B. `C:\Daten`, damit „Benutzer“ von `C:\` nicht erben). Beim Deaktivieren fragt Windows: geerbte Einträge **in explizite umwandeln** oder **alle geerbten entfernen**. Sollte die Ausnahme bleiben, da es die Komplexität erhöht.

**8. Vollzugriff erlaubt + Schreiben verweigert?**
Ein explizites **Verweigern** gewinnt gegen Erlauben – der Benutzer kann nicht schreiben. Deshalb Verweigern nur gezielt einsetzen; es wirkt auch für Admins in der Gruppe und ist schwer nachzuvollziehen. (Ausnahme: explizites Erlauben schlägt geerbtes Verweigern.)

**9. Wie wurde geprüft, dass die Berechtigungen greifen?**
Mit echten Benutzerkonten am Client (skeller, glang, proth), nicht als Administrator: erlaubter Zugriff (glang schreibt in Pool) und verweigerter Zugriff (skeller kann in Buchhaltung nicht schreiben, proth sieht Intern nicht). Zusätzlich „Effektiver Zugriff“ in den erweiterten Sicherheitseinstellungen. Als Admin hätte der Test keine Aussagekraft.

**10. Person in zwei Abteilungen?**
Sie wird Mitglied beider globalen Abteilungsgruppen (z. B. G_Sekretariat und G_Buchhaltung). Ausdrücklich **nicht**: neue Berechtigungen auf Ordnern setzen oder Sonderrechte direkt am Benutzerkonto vergeben.
