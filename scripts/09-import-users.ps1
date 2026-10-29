<#
  Auftrag 09 – Repariertes und erweitertes Import-Skript (Original: import-users.ps1 der Lehrperson)
  Voraussetzung: OU=User mit Unter-OUs IT, Marketing, Support direkt unter der Domaenenwurzel,
                 C:\Temp\mitarbeiter.csv (Komma-getrennt: Vorname,Nachname,Abteilung)
  Fehlerprotokoll: Auftraege/09-Automation-Debugging/README.md
#>
Import-Module ActiveDirectory

$csvPath   = 'C:\Temp\mitarbeiter.csv'
$domainDN  = (Get-ADDomain).DistinguishedName      # DC=ec2,DC=andrija,DC=m159  (Fix 3: statt DC=it-tbz,DC=local)
$upnSuffix = (Get-ADDomain).DNSRoot                # ec2.andrija.m159

# Fix 1: CSV ist komma-getrennt -> Delimiter ',' (Original: ';')
$users = Import-Csv -Path $csvPath -Delimiter ','

# Fix 4: Passwort korrekt in SecureString umwandeln (ConvertTo- statt ConvertFrom-SecureString)
#        und nicht im Klartext im Skript: interaktiv abfragen.
. (Join-Path $PSScriptRoot '_secret.ps1')
$startPw = Get-M159Secret '/m159/userpw' 'Startkennwort fuer neue Benutzer'

foreach ($row in $users) {
    $sAMAccountName    = ($row.Vorname.Substring(0,1) + $row.Nachname).ToLower()
    $userPrincipalName = "$sAMAccountName@$upnSuffix"
    # Fix 2 + 5: Sub-Expression $() und korrekte OU-Logik (OU=<Abteilung>,OU=User,<Domaene>)
    $targetOU          = "OU=$($row.Abteilung),OU=User,$domainDN"

    # Teil B: Existiert der Benutzer schon?
    $existing = Get-ADUser -Filter "SamAccountName -eq '$sAMAccountName'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "WARNUNG: $sAMAccountName existiert bereits ($($existing.DistinguishedName)) - wird uebersprungen." -ForegroundColor Yellow
        continue
    }

    try {
        New-ADUser -Name "$($row.Vorname) $($row.Nachname)" `
            -GivenName $row.Vorname -Surname $row.Nachname `
            -DisplayName "$($row.Vorname) $($row.Nachname)" `
            -SamAccountName $sAMAccountName `
            -UserPrincipalName $userPrincipalName `
            -Department $row.Abteilung `
            -Path $targetOU `
            -AccountPassword $startPw `
            -ChangePasswordAtLogon $true `
            -Enabled $true -ErrorAction Stop
        Write-Host "OK: $sAMAccountName in $targetOU angelegt." -ForegroundColor Green
    }
    catch {
        Write-Host "FEHLER bei $sAMAccountName : $($_.Exception.Message)" -ForegroundColor Red
    }
}
