<#  Auftrag 11 – Servergespeicherte Profile (DC): Freigabe Profiles$ mit empfohlenen Rechten, Profilpfad fuer skeller + glang  #>
Import-Module ActiveDirectory, SmbShare
$pfad = 'C:\Daten\Profiles'
New-Item -ItemType Directory -Path $pfad -Force | Out-Null
$auth = (New-Object Security.Principal.SecurityIdentifier 'S-1-5-11').Translate([Security.Principal.NTAccount]).Value
if (-not (Get-SmbShare -Name 'Profiles$' -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name 'Profiles$' -Path $pfad -FullAccess $auth -CachingMode None | Out-Null
}
# NTFS nach Microsoft-Empfehlung: Ersteller-Besitzer Vollzugriff (nur Unterordner/Dateien),
# Benutzer der Firma: Ordner auflisten/Daten lesen + Ordner erstellen (nur dieser Ordner)
icacls $pfad /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-3-0:(OI)(CI)(IO)F' | Out-Null
icacls $pfad /grant 'EC2\G_Intern:(RD,AD,X,RA)' 'EC2\G_Extern:(RD,AD,X,RA)' | Out-Null
foreach ($u in 'skeller','glang') {
    Set-ADUser $u -ProfilePath "\\dc-andrija.ec2.andrija.m159\Profiles$\$u"
}
"== Freigabe";  Get-SmbShare 'Profiles$' | Format-List Name, Path, CachingMode; Get-SmbShareAccess 'Profiles$' | Format-Table AccountName, AccessRight
"== NTFS";      icacls $pfad
"== Profilpfade"; Get-ADUser -Filter "SamAccountName -eq 'skeller' -or SamAccountName -eq 'glang'" -Properties ProfilePath | Format-Table SamAccountName, ProfilePath -AutoSize
