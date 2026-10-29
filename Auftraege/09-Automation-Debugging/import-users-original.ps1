# BUG-REPORT: Dieses Skript sollte User aus einer CSV importieren
Import-Module ActiveDirectory

$csvPath = "C:\Temp\mitarbeiter.csv"
$users = Import-CSV $csvPath -Delimiter ";"

foreach ($row in $users) {

$sAMAccountName = $row.Vorname.Substring(0,1) + $row.Nachname
$userPrincipalName = "$sAMAccountName@it-tbz.local"
$targetOU = "OU=$row.Abteilung,OU=User,DC=it-tbz,DC=local"

Write-Host "Erstelle User: $sAMAccountName in OU: $targetOU"

New-ADUser -Name "$row.Vorname $row.Nachname" `
-SamAccountName $sAMAccountName `
-UserPrincipalName $userPrincipalName `
-Path $targetOU `
-AccountPassword (ConvertFrom-SecureString "Schule123" -AsPlainText -Force) `
-Enabled $true
}

