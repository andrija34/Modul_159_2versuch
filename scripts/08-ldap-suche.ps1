<#
  Auftrag 08 – Suche im Directory: Suchen, Firewall-Filter, Tests, Dienstkonto, GPO mit LDAP-Zielgruppe.
  Auf dem DC.  Die Ausgaben (Filter + Trefferzahl) werden in die Doku uebernommen.
#>
param([ValidateSet('Suchen','Tests','Dienstkonto','GPO')] [string] $Teil = 'Suchen')
Import-Module ActiveDirectory
$base   = (Get-ADDomain).DistinguishedName                      # DC=ec2,DC=andrija,DC=m159
$firma  = "OU=Andrija_AG,$base"
$extern = (Get-ADGroup G_Extern).DistinguishedName             # CN=G_Extern,OU=Gruppen,OU=Andrija_AG,...
$prom   = (Get-ADGroup G_Promoter).DistinguishedName

$IN_CHAIN = '1.2.840.113556.1.4.1941'   # LDAP_MATCHING_RULE_IN_CHAIN  (verschachtelte Gruppen)
$BIT_AND  = '1.2.840.113556.1.4.803'    # LDAP_MATCHING_RULE_BIT_AND   (Bitmaske)

function Zeige($Titel, $Filter, $SearchBase = $base, $Scope = 'Subtree') {
    $r = @(Get-ADObject -LDAPFilter $Filter -SearchBase $SearchBase -SearchScope $Scope)
    "`n### $Titel`nFilter: $Filter`nBase: $SearchBase  Scope: $Scope`nTreffer: $($r.Count)"
    $r | ForEach-Object { "  - $($_.DistinguishedName)" }
}

switch ($Teil) {
'Suchen' {
    Zeige '2.1 Promoter ueber Anmeldenamen' '(&(objectCategory=person)(objectClass=user)(sAMAccountName=proth))'
    $buch = "OU=Buchhaltung,OU=Intern,$firma"
    Zeige '2.2 Benutzer Buchhaltung (OneLevel)' '(&(objectCategory=person)(objectClass=user))' $buch 'OneLevel'
    Zeige '2.2 Benutzer Buchhaltung (Subtree)'  '(&(objectCategory=person)(objectClass=user))' $buch 'Subtree'
    Zeige '2.3 Alle Gruppen der Domain' '(objectClass=group)'
    "DN der Gruppe extern: $extern"

    Zeige '3.1 Direkte Mitglieder von G_Promoter' "(&(objectCategory=person)(objectClass=user)(memberOf=$prom))"
    Zeige '3.2a naiv: memberOf=G_Extern'       "(&(objectCategory=person)(objectClass=user)(memberOf=$extern))"
    Zeige '3.2b korrigiert: IN_CHAIN G_Extern' "(&(objectCategory=person)(objectClass=user)(memberOf:$IN_CHAIN`:=$extern))"
    $fw = "(&(objectCategory=person)(objectClass=user)(memberOf:$IN_CHAIN`:=$extern)(!(userAccountControl:$BIT_AND`:=2)))"
    Zeige '3.3 FIREWALL-FILTER: extern + aktiv' $fw
}
'Tests' {
    $fw = "(&(objectCategory=person)(objectClass=user)(memberOf:$IN_CHAIN`:=$extern)(!(userAccountControl:$BIT_AND`:=2)))"
    "== Test 1: Promoter deaktivieren"
    Disable-ADAccount proth;  Zeige 'nach Disable' $fw
    Enable-ADAccount  proth;  Zeige 'nach Enable'  $fw

    "== Test 2: zweite externe Abteilung"
    New-ADGroup -Name 'G_Externe_Berater' -GroupScope Global -GroupCategory Security -Path "OU=Gruppen,$firma"
    Add-ADGroupMember G_Extern -Members G_Externe_Berater
    $pw = ConvertTo-SecureString ([guid]::NewGuid().ToString() + 'aA1!') -AsPlainText -Force
    New-ADUser -Name 'Test Berater' -SamAccountName 'tberater' -Path "OU=Promoter_Benutzer,OU=Promoter,OU=Extern,$firma" -AccountPassword $pw -Enabled $true
    Add-ADGroupMember G_Externe_Berater -Members tberater
    Zeige 'mit Externe Berater (Filter unveraendert)' $fw
    # Aufraeumen
    Remove-ADUser tberater -Confirm:$false
    Remove-ADGroup G_Externe_Berater -Confirm:$false
    Zeige 'nach Aufraeumen' $fw
}
'Dienstkonto' {
    # Eigenes Dienstkonto, nur Domaenen-Benutzer (Standard-Leserechte), kein Admin, kein interaktives Login
    . (Join-Path $PSScriptRoot '_secret.ps1')
    $pw = Get-M159Secret '/m159/svc_fw_ldap' 'Kennwort svc_fw_ldap (Secrets-Ablage)'
    New-ADUser -Name 'svc_fw_ldap' -SamAccountName 'svc_fw_ldap' -UserPrincipalName "svc_fw_ldap@$((Get-ADDomain).DNSRoot)" `
        -Path "OU=Dienstkonten,$firma" -Description 'Bind-Konto Firewall VPN (nur lesen)' `
        -AccountPassword $pw -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true
    # Interaktive Anmeldung/RDP verweigern: in GPO "Lokal anmelden verweigern" aufnehmen (GUI), Mitgliedschaften pruefen:
    Get-ADPrincipalGroupMembership svc_fw_ldap | Select-Object Name
    Get-ADUser svc_fw_ldap | Select-Object DistinguishedName
}
'GPO' {
    # Teil 4: Desktop-Verknuepfung zur VPN-Anleitung, Zielgruppe = LDAP-Abfrage (Item-Level-Targeting).
    # Wichtig: ILT "LDAP-Abfrage" greift, sobald die Abfrage IRGENDEIN Ergebnis liefert. Darum wird der Filter
    # mit %LogonUser% auf den angemeldeten Benutzer eingeschraenkt – sonst bekaemen alle die Verknuepfung.
    Import-Module GroupPolicy
    $fqdn = (Get-ADDomain).DNSRoot
    $ilt  = "(&amp;(sAMAccountName=%LogonUser%)(objectCategory=person)(objectClass=user)(memberOf:$IN_CHAIN`:=$extern)(!(userAccountControl:$BIT_AND`:=2)))"
    $g = Get-GPO -Name 'U_Andrija_AG_Verknuepfung_VPN' -ErrorAction SilentlyContinue
    if (-not $g) { $g = New-GPO -Name 'U_Andrija_AG_Verknuepfung_VPN' -Comment 'VPN-Anleitung nur fuer aktive Externe (LDAP-ILT)' }
    $dir = "\\$fqdn\SYSVOL\$fqdn\Policies\{$($g.Id)}\User\Preferences\Shortcuts"
    New-Item -ItemType Directory $dir -Force | Out-Null
    $uid = "{$([guid]::NewGuid().ToString().ToUpper())}"
    @"
<?xml version="1.0" encoding="utf-8"?>
<Shortcuts clsid="{872ECB34-B2EC-401b-A585-D32574AA90EE}"><Shortcut clsid="{4F2F7C55-2790-433e-8127-0739D1CFA327}" name="VPN-Anleitung" status="VPN-Anleitung" image="2" changed="$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))" uid="$uid"><Properties pidl="" targetType="FILESYSTEM" action="U" comment="VPN-Anleitung" shortcutKey="0" startIn="" arguments="" iconIndex="0" targetPath="\\dc-andrija.$fqdn\Extern\VPN-Anleitung.txt" iconPath="" window="" shortcutPath="%DesktopDir%\VPN-Anleitung"/><Filters><FilterLdap bool="AND" not="0" searchFilter="$ilt" binding="LDAP:" variableName="" attribute=""/></Filters></Shortcut></Shortcuts>
"@ | Set-Content "$dir\Shortcuts.xml" -Encoding UTF8
    Set-Content 'C:\Daten\Extern\VPN-Anleitung.txt' 'VPN-Anleitung fuer den Aussendienst (Test M159 Auftrag 08)'
    $ad = Get-ADObject "CN={$($g.Id)},CN=Policies,CN=System,$base" -Properties versionNumber
    $ver = [int]$ad.versionNumber + 65536
    Set-ADObject $ad -Replace @{ gPCUserExtensionNames='[{C418DD9D-0D14-4EFB-8FBF-CFE535C8FAC7}{CEFFA6E2-E3BD-421B-852C-6F6A79A59BC1}]'; versionNumber=$ver }
    $ini = "\\$fqdn\SYSVOL\$fqdn\Policies\{$($g.Id)}\GPT.INI"
    (Get-Content $ini) -replace 'Version=\d+',"Version=$ver" | Set-Content $ini
    New-GPLink -Guid $g.Id -Target $firma -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
    "GPO angelegt. Test: als proth und als skeller anmelden -> gpupdate /force; gpresult /r /scope user"
}
}
