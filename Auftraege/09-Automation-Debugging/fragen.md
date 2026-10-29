# Auftrag 09 – Fragenkatalog (Antworten)

**1. Warum Benutzer per Skript anlegen?**
Grosse Stückzahlen (z. B. 40 Lernende im August), einheitliche Namensregeln und Attribute, wiederholbar und nachvollziehbar, weniger Tippfehler; Grundlage für automatisierte Lifecycle-Prozesse (HR → AD → Entra ID).

**2. Delimiter, wie hat sich der Fehler geäussert?**
Trennzeichen zwischen den Feldern einer Zeile (`,` oder `;`). Import-Csv zerlegt jede Zeile an genau diesem Zeichen und nimmt die Kopfzeile als Eigenschaftsnamen. Mit `;` blieb jede Zeile in einer einzigen Spalte „Vorname,Nachname,Abteilung“, `$row.Vorname` war `$null`, und `.Substring()` warf „You cannot call a method on a null-valued expression“. Sichtbar gewesen wäre es sofort mit `$users | Format-List`.

**3. Warum `$($row.Vorname)` statt `$row.Vorname` im String?**
In doppelten Anführungszeichen findet nur eine einfache Variablenersetzung statt: eingesetzt wird `$row` (als `@{Vorname=…}`), `.Vorname` bleibt Text. `$( )` öffnet einen Teilausdruck, der im Ausdrucksmodus ausgewertet wird – erst dort greift der Eigenschaftszugriff; das Ergebnis wird in Text umgewandelt. In einfachen Anführungszeichen wird gar nichts ausgewertet.

**4. ConvertTo-SecureString, warum kein Text-Passwort?**
Wandelt Text in ein `SecureString`-Objekt um, das verschlüsselt im Speicher liegt und nicht versehentlich ausgegeben/geloggt wird. `-AccountPassword` verlangt bewusst diesen Typ. (`ConvertFrom-SecureString` macht das Gegenteil.)

**5. sAMAccountName, was bei Duplikat?**
Eindeutiger Pre-Windows-2000-Anmeldename in der Domäne (max. 20 Zeichen). Ein Duplikat lässt `New-ADUser` mit „The specified account already exists“ scheitern → Prüfung oder Namensregel (z. B. `hmuster2`, zweiter Buchstabe des Vornamens) nötig.

**6. Wie prüft das Skript die Existenz, warum wichtig?**
`Get-ADUser -Filter "SamAccountName -eq '…'"` vor dem Anlegen; existiert er → gelbe Warnung und überspringen. Dadurch ist das Skript idempotent: ein zweiter Lauf richtet keinen Schaden an und bricht nicht ab.

**7. Abbruch nach 2 von 5 Benutzern?**
Halbfertiger Zustand – weder vollständig noch leer. Dank Existenzprüfung kann man das Skript einfach erneut laufen lassen: die zwei vorhandenen werden übersprungen, die restlichen angelegt. Protokollierung (Konsole/Logdatei, `try/catch`) zeigt den Stand.

**8. Distinguished Name, wozu im Skript?**
Eindeutiger Pfad eines Objekts von unten nach oben (`CN=…,OU=IT,OU=User,DC=ec2,DC=andrija,DC=m159`). Das Skript übergibt ihn bei `-Path`, damit der Benutzer in der richtigen OU landet; stimmt er nicht exakt mit der AD-Struktur überein → „Directory object not found“.

**9. Welche Attribute, was fehlt im Betrieb?**
Gesetzt: Name, GivenName, Surname, DisplayName, sAMAccountName, UPN, Department, Passwort, Enabled, ChangePasswordAtLogon. Im Betrieb zusätzlich: mail, title, manager, employeeID/Personalnummer, company, office/telephone, Ablaufdatum für Temporäre – u. a. für Filter wie in Auftrag 08 und die Synchronisation nach Entra ID.

**10. Passwort im Klartext im Skript?**
Jeder mit Lesezugriff aufs Skript kennt es, und über Git bleibt es für immer in der Historie. Besser: Zufallspasswörter pro Benutzer, sicher übermitteln, `ChangePasswordAtLogon`; oder interaktive Abfrage / geschützte Ablage (SecretManagement, Passwortmanager).
