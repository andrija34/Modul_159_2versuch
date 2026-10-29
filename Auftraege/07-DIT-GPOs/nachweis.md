# Auftrag 07 – Nachweis (Umsetzung 27.10.2026)

Skripte: `07-dit.ps1`, `07-gpos.ps1`, Korrekturen in `10-dc-nachtrag.ps1`, `14-dc-nachtrag2.ps1`, `15-dc-passwortrichtlinie.ps1`.

## DIT im AD (Get-ADOrganizationalUnit)

```text
OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Buchhaltung,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=GL,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Sekretariat,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
OU=Buchhaltung_Benutzer,OU=Buchhaltung,OU=Intern,...    OU=Buchhaltung_Computer,OU=Buchhaltung,OU=Intern,...
OU=GL_Benutzer,OU=GL,OU=Intern,...                      OU=GL_Computer,OU=GL,OU=Intern,...
OU=Promoter_Benutzer,OU=Promoter,OU=Extern,...          OU=Promoter_Computer,OU=Promoter,OU=Extern,...
OU=Sekretariat_Benutzer,OU=Sekretariat,OU=Intern,...    OU=Sekretariat_Computer,OU=Sekretariat,OU=Intern,...
```
Struktur = DIT-Diagramm ([README](README.md)). Alle Benutzer und der Client liegen in ihren Blatt-OUs (siehe Nachweis Auftrag 04 / 03).

## Teil 1 – Passwortrichtlinie (Default Domain Policy)

```text
GPO-Bericht Default Domain Policy:   PasswordComplexity false   MaximumPasswordAge 4294967295 (= läuft nie ab)
Wirksame Domänenrichtlinie:          ComplexityEnabled : False   MaxPasswordAge : 00:00:00
```
Nur die Kennwortrichtlinie wurde geändert (GptTmpl.inf `[System Access]`), sonst nichts.

## GPOs und Verknüpfungen (Get-GPInheritance)

```text
DC=ec2,DC=andrija,DC=m159                     -> Default Domain Policy, C_Domain_Software_7-Zip
OU=Andrija_AG                                 -> U_Andrija_AG_Laufwerk_Pool, U_Andrija_AG_Verknuepfung_CRM,
                                                 U_Andrija_AG_Drucker, U_Andrija_AG_Verknuepfung_VPN
OU=Intern                                     -> U_Intern_Laufwerk_Intern
OU=Extern                                     -> U_Extern_Laufwerk_Extern
OU=Promoter,OU=Extern                         -> U_Promoter_Textdatei_kopieren   (WMI-Filter WMI_Nur_Windows10)
OU=Promoter_Benutzer                          -> U_Promoter_Laufwerk_Abteilung
OU=GL_Benutzer                                -> U_GL_Laufwerk_Abteilung
OU=Buchhaltung_Benutzer                       -> U_Buchhaltung_Laufwerk_Abteilung
OU=Sekretariat_Benutzer                       -> U_Sekretariat_Laufwerk_Abteilung
```

## Teil 3 – Sicherheitsfilterung CRM-Verknüpfung

Authentifizierte Benutzer: nur `GpoRead`; `G_Intern`: `GpoApply` (Lesen + Übernehmen).

## Teil 4 – WMI-Filter

```text
msWMI-Name  : WMI_Nur_Windows10
msWMI-Parm2 : 1;3;10;83;WQL;root\CIMv2;SELECT * FROM Win32_OperatingSystem WHERE Version LIKE "10.%" AND ProductType = "1";
GPO U_Promoter_Textdatei_kopieren -> WmiFilter: WMI_Nur_Windows10
Datei C:\Daten\Pool\WMI-Filter.txt angelegt
```

## Teil 5 – Drucker

```text
Name           DriverName                    PortName       Shared ShareName
Drucker_SW     Microsoft PCL6 Class Driver   IP_10.0.0.202  True   Drucker_SW
Drucker_Farbe  Microsoft PCL6 Class Driver   IP_10.0.0.201  True   Drucker_Farbe
Drucker_Farbe: Standard Farbe = True
Drucker_SW:    Standard Farbe = False
```
Fehleranalyse: Der zuerst gewählte Treiber „Microsoft PS Class Driver“ ist auf Server 2025 nicht vorinstalliert, „Microsoft Print To PDF“ lässt sich nicht an einen TCP/IP-Port binden (HRESULT 0x80070bce). Lösung: `Add-PrinterDriver "Microsoft PCL6 Class Driver"` aus `ntprint.inf`.

## Teil 6 – Software (Vorbereitung)

```text
\\dc-andrija.ec2.andrija.m159\Software$  -> 7z-x64.msi (1'996'800 Bytes, 7-Zip 25.01)
Gruppe 7-Zip (Global) -> Mitglied CLIENT-ANDRIJA
GPO C_Domain_Software_7-Zip auf Domäne verknüpft, Sicherheitsfilter: 7-Zip = GpoApply
```

## Noch offen (benötigt eine interaktive Anmeldung bzw. die GPMC-Oberfläche)

| Punkt | Warum offen | Vorgehen |
|---|---|---|
| Laufwerke / CRM-Link / Drucker beim Benutzer | Benutzer-GPOs werden nur bei einer interaktiven Anmeldung verarbeitet – ich gebe keine Kennwörter in Anmeldemasken ein | Andrija meldet sich per RDP als skeller und proth am Client an → `gpupdate /force`, `gpresult /r /scope user`, Screenshot Explorer/Desktop |
| `gpresult /h gpo.html` (WMI-Test) | dito, als proth | `gpresult /h C:\Temp\gpo.html` → ins Repo |
| Drucker-Video | dito | Drucker löschen, `gpupdate /force`, mit Xbox Game Bar aufnehmen |
| ~~7-Zip-Paket zuweisen~~ | **erledigt 29.10.2026**, siehe unten | – |


## GUI-Nachweise
Bildschirmfotos (Laufwerke, CRM-Link intern/extern, Drucker, GPMC, OUs): [GUI-Nachweise](../GUI-Nachweise.md#auftrag-07--dit-gpos-laufwerke-crm-drucker)

## 7-Zip-Softwareverteilung (erledigt 29.10.2026)

Das Paket wurde im GPO-Editor zugewiesen (Bilder: [GUI-Nachweise](../GUI-Nachweise.md#auftrag-07--7-zip-per-softwareverteilung)). Kontrolle auf dem DC:

```
Machine\Applications\{5A1DBA43-AD5B-4F39-AA87-C43D8D0B344D}.aas   757 Bytes
displayName : 7-Zip 25.01 (x64 edition)
msiFileList : {0:\\dc-andrija.ec2.andrija.m159\Software$\7z-x64.msi}
```

Danach `client-andrija` zweimal neu gestartet:

```
DisplayName    : 7-Zip 25.01 (x64 edition)
DisplayVersion : 25.01.00.0
InstallDate    : 20261029
301  The assignment of application 7-Zip 25.01 (x64 edition) from policy C_Domain_Software_7-Zip succeeded.
302  The install of application 7-Zip 25.01 (x64 edition) from policy C_Domain_Software_7-Zip succeeded.
308  Changes to software installation settings were applied successfully.
```

Hinweis: `gpupdate /force` wartet nach einer Softwarezuweisung auf die Rückfrage „Neustart? (J/N)“ und blockiert so SSM-Befehle. Deshalb habe ich den Neustart direkt ausgelöst.
