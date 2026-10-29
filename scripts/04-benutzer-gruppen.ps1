<#
  Auftrag 04 – Benutzer und globale Gruppen gemaess Planung (Kap. 8) anlegen.  Auf dem DC ausfuehren.
  Das Startkennwort wird interaktiv abgefragt (steht NICHT im Skript / Repo).
#>
Import-Module ActiveDirectory
$UpnSuffix = 'ec2.andrija.m159'
. (Join-Path $PSScriptRoot '_secret.ps1')
$pw = Get-M159Secret '/m159/userpw' 'Startkennwort fuer die Testbenutzer (Secrets-Ablage)'

$benutzer = @(
    @{ Sam='skeller'; Vorname='Sandra';  Nachname='Keller'; Abteilung='Sekretariat' }
    @{ Sam='bhuber';  Vorname='Beat';    Nachname='Huber';  Abteilung='Buchhaltung' }
    @{ Sam='glang';   Vorname='Gabriel'; Nachname='Lang';   Abteilung='GL' }
    @{ Sam='proth';   Vorname='Paul';    Nachname='Roth';   Abteilung='Promoter' }
)

# Globale Sicherheitsgruppen: je Abteilung + intern/extern
foreach ($g in 'G_Sekretariat','G_Buchhaltung','G_GL','G_Promoter','G_Intern','G_Extern') {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'")) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Description "M159 Rollengruppe $g"
    }
}

foreach ($b in $benutzer) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($b.Sam)'")) {
        New-ADUser -Name "$($b.Vorname) $($b.Nachname)" -GivenName $b.Vorname -Surname $b.Nachname `
            -SamAccountName $b.Sam -UserPrincipalName "$($b.Sam)@$UpnSuffix" `
            -DisplayName "$($b.Vorname) $($b.Nachname)" -Department $b.Abteilung `
            -EmailAddress "$($b.Sam)@$UpnSuffix" `
            -AccountPassword $pw -Enabled $true -ChangePasswordAtLogon $false
    }
    Add-ADGroupMember "G_$($b.Abteilung)" -Members $b.Sam
}

# Abteilungsgruppen in intern / extern verschachteln
Add-ADGroupMember 'G_Intern' -Members 'G_Sekretariat','G_Buchhaltung','G_GL'
Add-ADGroupMember 'G_Extern' -Members 'G_Promoter'

# RDP am Client fuer die Testbenutzer (Auftrag 03 RDP-Konzept)
if (Get-ADGroup -Filter "Name -eq 'GG_RDP_Users'") {
    Add-ADGroupMember 'GG_RDP_Users' -Members 'skeller','bhuber','glang','proth'
}

# Kontrolle fuer die Doku
Get-ADGroup -Filter 'Name -like "G_*"' | ForEach-Object {
    [pscustomobject]@{ Gruppe=$_.Name; Bereich=$_.GroupScope; Mitglieder=(Get-ADGroupMember $_ | ForEach-Object Name) -join ', ' }
} | Format-Table -AutoSize
