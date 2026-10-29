<#
  Auftrag 09 – Vorbereitung: OU-Struktur fuer den Import + CSV-Datei.  Auf dem DC.
#>
Import-Module ActiveDirectory
$root = (Get-ADDomain).DistinguishedName
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq 'OU=User,$root'")) {
    New-ADOrganizationalUnit -Name 'User' -Path $root
}
foreach ($ou in 'IT','Marketing','Support') {
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq 'OU=$ou,OU=User,$root'")) {
        New-ADOrganizationalUnit -Name $ou -Path "OU=User,$root"
    }
}
New-Item -ItemType Directory -Path 'C:\Temp' -Force | Out-Null
@'
Vorname,Nachname,Abteilung
Hans,Muster,IT
Petra,Beispiel,Marketing
Lars,Lustig,Support
'@ | Set-Content -Path 'C:\Temp\mitarbeiter.csv' -Encoding UTF8
Get-Content C:\Temp\mitarbeiter.csv
