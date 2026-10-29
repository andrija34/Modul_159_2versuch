# Auftrag 09 – Identity Management & PowerShell Debugging

Fragen: [fragen.md](fragen.md) · Original: [import-users-original.ps1](import-users-original.ps1) · **Repariert:** [`scripts/09-import-users.ps1`](../../scripts/09-import-users.ps1) · Vorbereitung: [`scripts/09-vorbereitung.ps1`](../../scripts/09-vorbereitung.ps1)

## 1. Vorbereitung

- OU `User` direkt unter `DC=ec2,DC=andrija,DC=m159`, darin `IT`, `Marketing`, `Support`.
- `C:\Temp\mitarbeiter.csv` exakt wie vorgegeben (komma-getrennt):
  ```
  Vorname,Nachname,Abteilung
  Hans,Muster,IT
  Petra,Beispiel,Marketing
  Lars,Lustig,Support
  ```

## 2. Fehlerprotokoll

Die Fehler 1, 2 und 4 wurden zusätzlich mit PowerShell 7 ausserhalb des AD reproduziert (echte Ausgaben, siehe Abschnitt 3).

| # | Art | Problem im Original | Symptom | Lösung |
|---|---|---|---|---|
| 1 | Konfiguration | `Import-CSV … -Delimiter ";"`, die Datei ist aber komma-getrennt | Ganze Zeile landet in **einer** Spalte `Vorname,Nachname,Abteilung`; `$row.Vorname` ist `$null` → „You cannot call a method on a null-valued expression“ bei `.Substring()` | `-Delimiter ','` |
| 2 | Syntax/String | `"OU=$row.Abteilung,…"` und `-Name "$row.Vorname $row.Nachname"` – in doppelten Anführungszeichen wird nur `$row` ersetzt | `OU=@{Vorname=Hans; Nachname=Muster; Abteilung=IT}.Abteilung,…` → ungültiger DN, Name unbrauchbar | Sub-Expression: `"OU=$($row.Abteilung),…"`, `"$($row.Vorname) $($row.Nachname)"` |
| 3 | Konfiguration | Fest verdrahtet `DC=it-tbz,DC=local` und UPN `@it-tbz.local` | „Directory object not found“ – OU existiert in meiner Domäne nicht | Dynamisch aus `(Get-ADDomain).DistinguishedName` bzw. `.DNSRoot` → `DC=ec2,DC=andrija,DC=m159`, `@ec2.andrija.m159` |
| 4 | Logik/Cmdlet | `ConvertFrom-SecureString "Schule123" -AsPlainText -Force` | „Cannot bind parameter 'SecureString'. Cannot convert … System.String to … SecureString“ | `ConvertTo-SecureString` erzeugt den von `-AccountPassword` verlangten SecureString |
| 5 | Logik | OU-Pfad muss exakt der angelegten Struktur entsprechen | – | `OU=<Abteilung>,OU=User,<Domäne>` = angelegte Struktur |
| 6 | Sicherheit | Passwort `Schule123` im Klartext im Skript/Repo | Jeder mit Lesezugriff (und die Git-Historie) kennt es | Startkennwort per `Read-Host -AsSecureString`, `-ChangePasswordAtLogon $true` |
| 7 | Robustheit | Keine Prüfung/Fehlerbehandlung | Zweiter Lauf bricht bei Duplikaten ab | Teil B: Existenzprüfung + `try/catch` |
| 8 | Kosmetik | sAMAccountName mit Grossbuchstaben (`HMuster`) | uneinheitlich | `.ToLower()` → `hmuster` |

## 3. Reproduktion (echte Ausgabe PowerShell 7.4)

```text
--- Bug 1: Delimiter ';' bei komma-getrennter CSV
Vorname,Nachname,Abteilung : Hans,Muster,IT
Vorname = []
FEHLER: You cannot call a method on a null-valued expression.
--- Bug 2: String ohne Sub-Expression
OU=@{Vorname=Hans; Nachname=Muster; Abteilung=IT}.Abteilung,OU=User,DC=it-tbz,DC=local
--- korrigiert
OU=IT,OU=User,DC=ec2,DC=andrija,DC=m159
Name: @{Vorname=Hans; Nachname=Muster; Abteilung=IT}.Vorname @{...}.Nachname
Name: Hans Muster
--- Bug 4: ConvertFrom-SecureString
FEHLER: Cannot bind parameter 'SecureString'. Cannot convert the value of type "System.String" to type "System.Security.SecureString".
--- korrigiert
System.Security.SecureString
```

## 4. Teil B – Existenzprüfung

```powershell
$existing = Get-ADUser -Filter "SamAccountName -eq '$sAMAccountName'" -ErrorAction SilentlyContinue
if ($existing) { Write-Host "WARNUNG: … wird uebersprungen." -ForegroundColor Yellow; continue }
New-ADUser … ; Write-Host "OK: … angelegt." -ForegroundColor Green
```
`Get-ADUser -Filter` statt `Get-ADUser -Identity`, weil `-Identity` bei nicht existierendem Benutzer eine Exception wirft; der Filter liefert einfach `$null`.

Test: 1. Lauf → 3× grün; 2. Lauf → 3× gelb (übersprungen).

## 5. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Fehlermeldungen des Originals auf dem DC | `images/09-original-fehler.png` | ⏳ |
| 1. Lauf: 3 grüne Erfolgsmeldungen | `images/09-lauf1.png` | ⏳ |
| 2. Lauf: 3 gelbe Warnungen | `images/09-lauf2.png` | ⏳ |
| dsa.msc: hmuster in IT, pbeispiel in Marketing, llustig in Support | `images/09-dsa.png` | ⏳ |
