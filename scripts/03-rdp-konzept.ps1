<#
  Auftrag 03 – RDP-Konzept mit zwei AD-Gruppen
  Teil A (auf dem DC): Gruppen anlegen
  Teil B (auf dem Client): Gruppen manuell in lokale Gruppen aufnehmen
#>
param([ValidateSet('DC','Client')] [string] $Teil = 'DC')

if ($Teil -eq 'DC') {
    Import-Module ActiveDirectory
    # GG_RDP_Admins  -> lokale Administratoren auf Clients (Vollzugriff via RDP)
    # GG_RDP_Users   -> nur RDP-Anmeldung ("Remotedesktopbenutzer"), keine Adminrechte
    New-ADGroup -Name 'GG_RDP_Admins' -GroupScope Global -GroupCategory Security `
        -Description 'Admins: RDP + lokale Adminrechte auf Clients'
    New-ADGroup -Name 'GG_RDP_Users'  -GroupScope Global -GroupCategory Security `
        -Description 'Benutzer: RDP-Anmeldung auf Clients ohne Adminrechte'
    Add-ADGroupMember 'GG_RDP_Admins' -Members 'Administrator'
    # Testbenutzer (existieren ab Auftrag 04): Sekretariat + GL duerfen per RDP auf den Client
    Add-ADGroupMember 'GG_RDP_Users'  -Members 'skeller','glang' -ErrorAction SilentlyContinue
}
else {
    # Lokale Gruppen-SIDs statt Namen (sprachunabhaengig)
    Add-LocalGroupMember -SID 'S-1-5-32-544' -Member 'EC2\GG_RDP_Admins'   # Administratoren
    Add-LocalGroupMember -SID 'S-1-5-32-555' -Member 'EC2\GG_RDP_Users'    # Remotedesktopbenutzer
    Get-LocalGroupMember -SID 'S-1-5-32-555'
}
