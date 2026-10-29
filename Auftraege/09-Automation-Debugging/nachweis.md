# Auftrag 09 – Nachweis auf dem DC (27.10.2026)

## Vorbereitung (`09-vorbereitung.ps1`)

```text
Vorname,Nachname,Abteilung
Hans,Muster,IT
Petra,Beispiel,Marketing
Lars,Lustig,Support
```
OU=User mit IT, Marketing, Support direkt unter `DC=ec2,DC=andrija,DC=m159`.

## Original-Skript auf dem DC (Fehler reproduziert)

```text
Erstelle User:  in OU: OU=@{Vorname,Nachname,Abteilung=Hans,Muster,IT}.Abteilung,OU=User,DC=it-tbz,DC=local
You cannot call a method on a null-valued expression.
At C:\m159\09-import-users-original.ps1:9 char:1
+ $sAMAccountName = $row.Vorname.Substring(0,1) + $row.Nachname
ConvertFrom-SecureString : Cannot bind parameter 'SecureString'. Cannot convert the "Schule123" value of type
"System.String" to type "System.Security.SecureString".
At C:\m159\09-import-users-original.ps1:19 char:44
```
Die Ausgabe zeigt alle drei Hauptfehler auf einmal: falscher Delimiter (die ganze Zeile steht in *einer* Spalte `Vorname,Nachname,Abteilung`), fehlende Sub-Expression (`@{...}.Abteilung`) und falsches Cmdlet (`ConvertFrom-SecureString`), dazu die fremde Domäne `it-tbz.local`.

## Repariertes Skript – 1. Lauf

```text
OK: hmuster in OU=IT,OU=User,DC=ec2,DC=andrija,DC=m159 angelegt.
OK: pbeispiel in OU=Marketing,OU=User,DC=ec2,DC=andrija,DC=m159 angelegt.
OK: llustig in OU=Support,OU=User,DC=ec2,DC=andrija,DC=m159 angelegt.
```

## Repariertes Skript – 2. Lauf (Existenzprüfung)

```text
WARNUNG: hmuster existiert bereits (CN=Hans Muster,OU=IT,OU=User,DC=ec2,DC=andrija,DC=m159) - wird uebersprungen.
WARNUNG: pbeispiel existiert bereits (CN=Petra Beispiel,OU=Marketing,OU=User,DC=ec2,DC=andrija,DC=m159) - wird uebersprungen.
WARNUNG: llustig existiert bereits (CN=Lars Lustig,OU=Support,OU=User,DC=ec2,DC=andrija,DC=m159) - wird uebersprungen.
```

## Kontrolle im AD

```text
SamAccountName DistinguishedName
hmuster        CN=Hans Muster,OU=IT,OU=User,DC=ec2,DC=andrija,DC=m159
pbeispiel      CN=Petra Beispiel,OU=Marketing,OU=User,DC=ec2,DC=andrija,DC=m159
llustig        CN=Lars Lustig,OU=Support,OU=User,DC=ec2,DC=andrija,DC=m159
```
(Grün/Gelb sind im SSM-Protokoll als Text sichtbar; der dsa.msc-Screenshot folgt bei der RDP-Sitzung.)
