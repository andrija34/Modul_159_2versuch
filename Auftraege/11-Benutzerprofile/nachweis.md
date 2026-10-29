# Nachweis Auftrag 11 – Servergespeicherte Profile

Umgesetzt am 27.10.2026 über SSM Run Command (Skript: [`16-roaming-profiles.ps1`](../../scripts/16-roaming-profiles.ps1)).

## Freigabe `Profiles$` (dc-andrija)

```
Name        : Profiles$
Path        : C:\Daten\Profiles
CachingMode : None          # Offline-Dateien aus (Empfehlung für Roaming Profiles)

AccountName                      AccessRight
NT AUTHORITY\Authenticated Users Full
```

## NTFS (nach Microsoft-Empfehlung)

```
C:\Daten\Profiles EC2\G_Extern:(RD,AD,X,RA)      # nur dieser Ordner: auflisten + Ordner erstellen
                  EC2\G_Intern:(RD,AD,X,RA)
                  CREATOR OWNER:(OI)(CI)(IO)(F)  # jeder Benutzer besitzt nur seinen eigenen Profilordner
                  NT AUTHORITY\SYSTEM:(OI)(CI)(F)
                  BUILTIN\Administrators:(OI)(CI)(F)
Successfully processed 1 files; Failed processing 0 files
```

Vererbung ist deaktiviert, damit Benutzer die Profile anderer nicht sehen/öffnen können.

## Profilpfade

```
SamAccountName ProfilePath
glang          \\dc-andrija.ec2.andrija.m159\Profiles$\glang
skeller        \\dc-andrija.ec2.andrija.m159\Profiles$\skeller
```

## Ablauf des Anmeldetests

Der Roaming-Test braucht echte Anmeldungen:

1. Als `skeller` an `client-andrija` anmelden, Datei auf dem Desktop anlegen, Hintergrund ändern, abmelden.
2. Auf dem DC prüfen: Ordner `C:\Daten\Profiles\skeller.V6` wurde erstellt (Screenshot).
3. Anmeldung an einem zweiten Rechner (z. B. zweiter Client oder DC via RDP-Berechtigung) → Desktop-Datei und Hintergrund sind vorhanden (Screenshot).


## Anmeldetest (erledigt 28.10.2026)
skeller hat auf `client-andrija` die Datei `Roaming-Test.txt` auf dem Desktop erstellt und sich abgemeldet → Datei liegt in `C:\Daten\Profiles\skeller.V6\Desktop\` → Anmeldung auf `wac-andrija`: Datei ist auf dem Desktop. Bildschirmfotos: [GUI-Nachweise](../GUI-Nachweise.md#auftrag-11--servergespeicherte-profile-roaming)
