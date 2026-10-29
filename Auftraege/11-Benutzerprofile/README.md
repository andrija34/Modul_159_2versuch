# Auftrag 11 – Servergespeicherte Benutzerprofile

Fragen: [fragen.md](fragen.md)

Für den Gerätewechsel-Test wird temporär ein zweiter Client `client2-andrija` (10.0.0.21, Init-Skript + Join wie Auftrag 02/03) erstellt und danach terminiert.

## 1. Roaming Profiles (Grundlage)

- Ordner `C:\Daten\Profiles` (in der Matrix vorgesehen), Freigabe **`Profiles$`**:
  - Freigabe: *Authentifizierte Benutzer* = Vollzugriff (Ändern genügt).
  - NTFS (Microsoft-Empfehlung): Vererbung aus; *Ersteller-Besitzer* Vollzugriff (nur Unterordner/Dateien); *G_Intern*, *G_Extern* „Ordner auflisten / Daten lesen + Ordner erstellen“ (nur dieser Ordner); SYSTEM + Administratoren Vollzugriff.
- Benutzerkonto → Profil → Profilpfad `\\dc-andrija.ec2.andrija.m159\Profiles$\%username%` (für skeller, glang):
  ```powershell
  'skeller','glang' | ForEach-Object { Set-ADUser $_ -ProfilePath "\\dc-andrija.ec2.andrija.m159\Profiles$\$_" }
  ```
- Test: an Client 1 anmelden → `Testmigration.txt` auf Desktop → abmelden → `Profiles$\skeller.V6\Desktop` enthält die Datei → an Client 2 anmelden → Datei ist da. (`sysdm.cpl` → Benutzerprofile → Typ *Servergespeichert*.)

## 2. Folder Redirection (Alternative zu 1)

GPO `U_Intern_Ordnerumleitung` an `OU=Intern`: Benutzerkonfiguration → Richtlinien → Windows-Einstellungen → Ordnerumleitung → *Desktop* und *Dokumente* → Einfach → „Einen Ordner für jeden Benutzer im Stammpfad erstellen“ → `\\dc-andrija.ec2.andrija.m159\Redirect$`. Vorteil: nur diese Ordner werden umgeleitet, nichts wird bei der An-/Abmeldung kopiert.

## 3. FSLogix Profile Container (Vertiefung)

1. FSLogix (`FSLogixAppsSetup.exe`) auf den Clients installieren (bzw. per GPO/7-Zip-Methode verteilen).
2. Freigabe `\\dc-andrija.ec2.andrija.m159\FSLogix$` (NTFS wie Profiles$).
3. ADMX `fslogix.admx/adml` in `\\ec2.andrija.m159\SYSVOL\…\Policies\PolicyDefinitions` kopieren.
4. GPO `C_Andrija_AG_FSLogix` (Computer): FSLogix → Profile Containers → *Enabled* = 1, *VHD Locations* = `\\dc-andrija…\FSLogix$`, *Volume type* VHDX, *Delete local profile when FSLogix profile should apply* = 1, *Flip Flop Profile Directory Name* = 1. (Benutzer mit Roaming-Profilpfad dafür vorher zurücksetzen.)
5. Test: Anmeldung → in der Freigabe entsteht `skeller_S-1-5-…\Profile_skeller.VHDX`; `frx list-redirects` zeigt die Einbindung; Gerätewechsel-Test wie oben.

## 4. OneDrive Known Folder Move (laut Auftrag)

Voraussetzung: Entra-Connect-Sync (Auftrag 10) und eine Lizenz mit **OneDrive for Business** für die Testbenutzer. Azure for Students enthält standardmässig keine M365-Lizenzen – falls im Tenant keine verfügbar ist, wird das dokumentiert (Screenshot Lizenzen) und die Roaming-/FSLogix-Lösung gilt als Umsetzung.

1. Als skeller am Client: `Testmigration.txt` auf dem lokalen Desktop, abmelden.
2. OneDrive-ADMX (`%localappdata%\Microsoft\OneDrive\<version>\adm\OneDrive.admx`) in den Central Store.
3. GPO `U_Intern_OneDrive_KFM` an `OU=Intern` (Benutzerkonfiguration → Administrative Vorlagen → OneDrive):
   - *Silently sign in users to the OneDrive sync app with their Windows credentials* (bzw. Computer-Teil) – aktiviert
   - *Silently move Windows known folders to OneDrive* – aktiviert, Tenant-ID
   - *Prevent users from redirecting their Windows known folders back to their PC* – aktiviert
   - *Prompt users to move Windows known folders to OneDrive* – deaktiviert
   - Tenant-URL `https://<tenant>-my.sharepoint.com`
4. Anmelden → OneDrive startet automatisch, Desktop inkl. Testmigration.txt liegt in OneDrive.
5. Client 2: Datei vorhanden; `VonPC2.txt` erstellen → erscheint auf Client 1.

## 5. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Freigabe Profiles$ + NTFS | `images/11-profiles-share.png` | ⏳ |
| Profilpfad im AD + Profiltyp „Servergespeichert“ | `images/11-profilpfad.png` | ⏳ |
| Gerätewechsel-Test Client1 → Client2 → Client1 | `images/11-roaming-*.png` | ⏳ |
| FSLogix VHDX in der Freigabe | `images/11-fslogix.png` | ⏳ |
| OneDrive KFM bzw. Lizenz-Nachweis | `images/11-onedrive.png` | ⏳ |
