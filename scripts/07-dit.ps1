<#
  Auftrag 07 – DIT im AD anlegen und Objekte verschieben.  Auf dem DC.
  Struktur (siehe Auftraege/07-DIT-GPOs/dit.drawio.svg):
    DC=ec2,DC=andrija,DC=m159
     └ OU=Andrija_AG
        ├ OU=Intern
        │   ├ OU=Sekretariat → OU=Sekretariat_Benutzer | OU=Sekretariat_Computer
        │   ├ OU=Buchhaltung → OU=Buchhaltung_Benutzer | OU=Buchhaltung_Computer
        │   └ OU=GL          → OU=GL_Benutzer          | OU=GL_Computer
        ├ OU=Extern
        │   └ OU=Promoter    → OU=Promoter_Benutzer    | OU=Promoter_Computer
        ├ OU=Gruppen
        └ OU=Dienstkonten
#>
Import-Module ActiveDirectory
$root = (Get-ADDomain).DistinguishedName      # DC=ec2,DC=andrija,DC=m159

function New-OUSafe([string]$Name, [string]$Path) {
    $dn = "OU=$Name,$Path"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $true
    }
    return $dn
}

$firma  = New-OUSafe 'Andrija_AG' $root
$intern = New-OUSafe 'Intern'     $firma
$extern = New-OUSafe 'Extern'     $firma
$grp    = New-OUSafe 'Gruppen'    $firma
$svc    = New-OUSafe 'Dienstkonten' $firma

$abt = @{ Sekretariat=$intern; Buchhaltung=$intern; GL=$intern; Promoter=$extern }
foreach ($a in $abt.Keys) {
    $ou = New-OUSafe $a $abt[$a]
    New-OUSafe "$($a)_Benutzer" $ou | Out-Null
    New-OUSafe "$($a)_Computer" $ou | Out-Null
}

# Benutzer verschieben
$map = @{ skeller='Sekretariat'; bhuber='Buchhaltung'; glang='GL'; proth='Promoter' }
foreach ($u in $map.Keys) {
    $a = $map[$u]
    $ziel = "OU=$($a)_Benutzer,OU=$a,$($abt[$a])"
    Get-ADUser $u | Move-ADObject -TargetPath $ziel
}

# Client in eine Computer-OU, Gruppen in OU=Gruppen
Get-ADComputer 'client-andrija' | Move-ADObject -TargetPath "OU=Sekretariat_Computer,OU=Sekretariat,$intern"
Get-ADGroup -Filter 'Name -like "G_*" -or Name -like "DL_*" -or Name -like "GG_*"' | Move-ADObject -TargetPath $grp

# Kontrolle: DN je Objekt
Get-ADOrganizationalUnit -SearchBase $firma -Filter * | Sort-Object DistinguishedName | Select-Object DistinguishedName
Get-ADUser -Filter * -SearchBase $firma | Select-Object SamAccountName, DistinguishedName
Get-ADComputer client-andrija | Select-Object DistinguishedName
