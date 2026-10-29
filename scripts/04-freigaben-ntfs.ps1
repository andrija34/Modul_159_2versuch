<#
  Auftrag 04 – Ordner, Freigaben, NTFS-Berechtigungen (gruene Zeilen der Matrix) und ABE.  Auf dem DC.
  -Phase Matrix : Berechtigungen 1:1 gemaess Vorgabe-Matrix direkt an die globalen Gruppen
  -Phase AGDLP  : Abteilungen Sekretariat + Buchhaltung auf das eigene AGDLP-Konzept umbauen
#>
param([ValidateSet('Matrix','AGDLP')] [string] $Phase = 'Matrix')
Import-Module ActiveDirectory, SmbShare
$N = 'EC2'
$DomSid   = (Get-ADDomain).DomainSID.Value
$Everyone = (New-Object Security.Principal.SecurityIdentifier 'S-1-1-0').Translate([Security.Principal.NTAccount]).Value
$C = '(OI)(CI)M'     # Change  -> NTFS Aendern
$R = '(OI)(CI)RX'    # Read    -> NTFS Lesen & Ausfuehren

function Set-Acl-Neu {
    param([string]$Pfad, [hashtable]$Rechte)
    # Vererbung deaktivieren (ohne Kopie), dann Basis: Administratoren + SYSTEM Vollzugriff
    icacls $Pfad /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' | Out-Null
    # Benutzer / Domaenen-Benutzer entfernen (falls vorhanden)
    icacls $Pfad /remove:g '*S-1-5-32-545' "*$DomSid-513" 2>$null | Out-Null
    foreach ($k in $Rechte.Keys) { icacls $Pfad /grant:r "$N\$k`:$($Rechte[$k])" | Out-Null }
}

if ($Phase -eq 'Matrix') {
    $ordner = 'C:\Daten','C:\Daten\Pool','C:\Daten\Abteilungen',
              'C:\Daten\Abteilungen\Sekretariat','C:\Daten\Abteilungen\Buchhaltung',
              'C:\Daten\Abteilungen\Promoter','C:\Daten\Abteilungen\GL',
              'C:\Daten\Intern','C:\Daten\Extern'
    $ordner | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }

    # Freigaben: Jeder = Aendern, ABE aktiv
    $freigaben = @{ Daten='C:\Daten'; Pool='C:\Daten\Pool'; Abteilungen='C:\Daten\Abteilungen';
                    Intern='C:\Daten\Intern'; Extern='C:\Daten\Extern' }
    foreach ($f in $freigaben.Keys) {
        if (-not (Get-SmbShare -Name $f -ErrorAction SilentlyContinue)) {
            New-SmbShare -Name $f -Path $freigaben[$f] -ChangeAccess $Everyone -FolderEnumerationMode AccessBased | Out-Null
        }
        Set-SmbShare -Name $f -FolderEnumerationMode AccessBased -Force
    }

    # NTFS gemaess Matrix (nur Gruppen aus der eigenen Planung)
    Set-Acl-Neu 'C:\Daten'                          @{ 'G_GL'=$C; 'G_Buchhaltung'=$C }
    Set-Acl-Neu 'C:\Daten\Pool'                     @{ 'G_GL'=$C; 'G_Sekretariat'=$C; 'G_Buchhaltung'=$C; 'G_Promoter'=$C }
    Set-Acl-Neu 'C:\Daten\Abteilungen'              @{ 'G_GL'=$C; 'G_Sekretariat'=$R; 'G_Buchhaltung'=$R; 'G_Promoter'=$R }
    Set-Acl-Neu 'C:\Daten\Abteilungen\Sekretariat'  @{ 'G_GL'=$C; 'G_Sekretariat'=$C; 'G_Promoter'=$R }
    Set-Acl-Neu 'C:\Daten\Abteilungen\Buchhaltung'  @{ 'G_GL'=$C; 'G_Sekretariat'=$R; 'G_Buchhaltung'=$C; 'G_Promoter'=$R }
    Set-Acl-Neu 'C:\Daten\Abteilungen\Promoter'     @{ 'G_GL'=$C; 'G_Promoter'=$C }
    Set-Acl-Neu 'C:\Daten\Abteilungen\GL'           @{ 'G_GL'=$C }
    Set-Acl-Neu 'C:\Daten\Intern'                   @{ 'G_GL'=$C; 'G_Intern'=$C }
    Set-Acl-Neu 'C:\Daten\Extern'                   @{ 'G_GL'=$C; 'G_Extern'=$C }
}
else {
    # AGDLP: Account -> Global (Rolle) -> Domain Local (Ressource+Recht) -> Permission
    $dl = @{
        'DL_FS_Sekretariat_C' = @('G_GL','G_Sekretariat')
        'DL_FS_Sekretariat_R' = @('G_Promoter')
        'DL_FS_Buchhaltung_C' = @('G_GL','G_Buchhaltung')
        'DL_FS_Buchhaltung_R' = @('G_Sekretariat','G_Promoter')
    }
    foreach ($g in $dl.Keys) {
        if (-not (Get-ADGroup -Filter "Name -eq '$g'")) {
            New-ADGroup -Name $g -GroupScope DomainLocal -GroupCategory Security -Path ((Get-ADOrganizationalUnit -Filter "Name -eq 'Gruppen'").DistinguishedName) -Description "M159 Berechtigungsgruppe $g"
        }
        Add-ADGroupMember $g -Members $dl[$g]
    }
    # direkte Eintraege der globalen Gruppen entfernen (nur noch DL-Gruppen in der ACL)
    foreach ($p in 'C:\Daten\Abteilungen\Sekretariat','C:\Daten\Abteilungen\Buchhaltung') {
        icacls $p /remove:g "$N\G_GL" "$N\G_Sekretariat" "$N\G_Buchhaltung" "$N\G_Promoter" | Out-Null
    }
    Set-Acl-Neu 'C:\Daten\Abteilungen\Sekretariat' @{ 'DL_FS_Sekretariat_C'=$C; 'DL_FS_Sekretariat_R'=$R }
    Set-Acl-Neu 'C:\Daten\Abteilungen\Buchhaltung' @{ 'DL_FS_Buchhaltung_C'=$C; 'DL_FS_Buchhaltung_R'=$R }
}

# Kontrolle
Get-SmbShare | Where-Object Path -like 'C:\Daten*' | Format-Table Name, Path, FolderEnumerationMode
Get-ChildItem C:\Daten -Recurse -Directory | ForEach-Object { "`n== $($_.FullName)"; icacls $_.FullName }
