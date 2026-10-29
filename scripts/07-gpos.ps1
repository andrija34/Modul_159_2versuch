<#
  Auftrag 07 (+08) – GPOs anlegen, verknuepfen, filtern und Gruppenrichtlinien-Einstellungen (GPP) schreiben.
  Auf dem DC als Domaenen-Admin.  Teile 1 (Passwortrichtlinie), 5 (Drucker-Treiber/Standardwerte)
  und 6 (Softwareinstallation MSI) werden zusaetzlich in der GPMC-Oberflaeche gemacht/geprueft (Screenshots).

  Namenskonvention (Kapitel 5.4):  <U|C>_<Wirkungsbereich>_<Zweck>
     U = Benutzerkonfiguration, C = Computerkonfiguration
#>
Import-Module ActiveDirectory, GroupPolicy
$dom    = (Get-ADDomain)
$root   = $dom.DistinguishedName
$fqdn   = $dom.DNSRoot
$dc     = "dc-andrija.$fqdn"
$firma  = "OU=Andrija_AG,$root"
$intern = "OU=Intern,$firma"
$extern = "OU=Extern,$firma"
$sysvol = "\\$fqdn\SYSVOL\$fqdn\Policies"

# ---------- Hilfsfunktionen fuer Group Policy Preferences ---------------------------------
$CSE = @{   # Client-Side-Extension + Snap-in GUID (Benutzerseite)
    Drives    = '[{5794DAFD-BE60-433F-88A2-1A31939AC01F}{2EA1A81B-48E5-45E9-8BB7-A6E3AC170006}]'
    Shortcuts = '[{C418DD9D-0D14-4EFB-8FBF-CFE535C8FAC7}{CEFFA6E2-E3BD-421B-852C-6F6A79A59BC1}]'
    Files     = '[{7150F9BF-48AD-4DA4-A49C-29EF4A8369BA}{3BAE7E51-E3F4-41D0-853D-9BB9FD47605F}]'
    Printers  = '[{BC75B1ED-5833-4858-9BB8-CBF0B166DF9D}{A8C42CEA-CDB8-4388-97F4-5831F933DA84}]'
}
function Get-Or-NewGPO([string]$Name, [string]$Kommentar) {
    $g = Get-GPO -Name $Name -ErrorAction SilentlyContinue
    if (-not $g) { $g = New-GPO -Name $Name -Comment $Kommentar }
    return $g
}
function Set-GPPXml {
    param($Gpo, [ValidateSet('Drives','Shortcuts','Files','Printers')] $Typ, [string]$Xml)
    $dir = "$sysvol\{$($Gpo.Id)}\User\Preferences\$Typ"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -Path "$dir\$Typ.xml" -Value $Xml -Encoding UTF8
    # Extension im GPO-Objekt registrieren + Benutzer-Versionsnummer erhoehen
    $adGpo = Get-ADObject "CN={$($Gpo.Id)},CN=Policies,CN=System,$root" -Properties gPCUserExtensionNames, versionNumber
    $ext = @(); if ($adGpo.gPCUserExtensionNames) { $ext = [regex]::Matches($adGpo.gPCUserExtensionNames, '\[[^\]]+\]').Value }
    if ($ext -notcontains $CSE[$Typ]) { $ext += $CSE[$Typ] }
    $neu = ($ext | Sort-Object) -join ''
    $ver = [int]$adGpo.versionNumber + 65536
    Set-ADObject $adGpo -Replace @{ gPCUserExtensionNames = $neu; versionNumber = $ver }
    $ini = "$sysvol\{$($Gpo.Id)}\GPT.INI"
    (Get-Content $ini) -replace 'Version=\d+', "Version=$ver" | Set-Content $ini
}
function New-Uid { "{$([guid]::NewGuid().ToString().ToUpper())}" }
$jetzt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
function Drive-Xml($Letter, $Pfad, $Label) {
@"
<?xml version="1.0" encoding="utf-8"?>
<Drives clsid="{8FDDCC1A-0C3C-43cd-A6B4-71A6DF20DA8C}"><Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}" name="$($Letter):" status="$($Letter):" image="2" changed="$jetzt" uid="$(New-Uid)"><Properties action="U" thisDrive="NOCHANGE" allDrives="NOCHANGE" userName="" path="$Pfad" label="$Label" persistent="1" useLetter="1" letter="$Letter"/></Drive></Drives>
"@
}

# ---------- Teil 2: Netzlaufwerke (Verknuepfung auf passende OU, KEINE Zielgruppenadressierung) --
$laufwerke = @(
    @{ Name='U_Andrija_AG_Laufwerk_Pool';      Link=$firma;                                Letter='P'; Pfad="\\$dc\Pool";                    Label='Pool' }
    @{ Name='U_Intern_Laufwerk_Intern';        Link=$intern;                               Letter='I'; Pfad="\\$dc\Intern";                  Label='Intern' }
    @{ Name='U_Extern_Laufwerk_Extern';        Link=$extern;                               Letter='E'; Pfad="\\$dc\Extern";                  Label='Extern' }
    @{ Name='U_Sekretariat_Laufwerk_Abteilung'; Link="OU=Sekretariat_Benutzer,OU=Sekretariat,$intern"; Letter='A'; Pfad="\\$dc\Abteilungen\Sekretariat"; Label='Sekretariat' }
    @{ Name='U_Buchhaltung_Laufwerk_Abteilung'; Link="OU=Buchhaltung_Benutzer,OU=Buchhaltung,$intern"; Letter='A'; Pfad="\\$dc\Abteilungen\Buchhaltung"; Label='Buchhaltung' }
    @{ Name='U_GL_Laufwerk_Abteilung';          Link="OU=GL_Benutzer,OU=GL,$intern";                   Letter='A'; Pfad="\\$dc\Abteilungen\GL";          Label='GL' }
    @{ Name='U_Promoter_Laufwerk_Abteilung';    Link="OU=Promoter_Benutzer,OU=Promoter,$extern";       Letter='A'; Pfad="\\$dc\Abteilungen\Promoter";    Label='Promoter' }
)
foreach ($l in $laufwerke) {
    $g = Get-Or-NewGPO $l.Name "Netzlaufwerk $($l.Letter): -> $($l.Pfad)"
    Set-GPPXml $g Drives (Drive-Xml $l.Letter $l.Pfad $l.Label)
    New-GPLink -Guid $g.Id -Target $l.Link -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
}

# ---------- Teil 3: Desktop-Verknuepfung Web-CRM mit positiver Sicherheitsfilterung --------
$crm = Get-Or-NewGPO 'U_Andrija_AG_Verknuepfung_CRM' 'Desktop-Link https://crm.webapp.ch nur fuer G_Intern'
Set-GPPXml $crm Shortcuts @"
<?xml version="1.0" encoding="utf-8"?>
<Shortcuts clsid="{872ECB34-B2EC-401b-A585-D32574AA90EE}"><Shortcut clsid="{4F2F7C55-2790-433e-8127-0739D1CFA327}" name="Web-CRM" status="Web-CRM" image="2" changed="$jetzt" uid="$(New-Uid)"><Properties pidl="" targetType="URL" action="U" comment="Web-CRM" shortcutKey="0" startIn="" arguments="" iconIndex="0" targetPath="https://crm.webapp.ch" iconPath="" window="" shortcutPath="%DesktopDir%\Web-CRM"/></Shortcut></Shortcuts>
"@
New-GPLink -Guid $crm.Id -Target $firma -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
# Authentifizierte Benutzer: nur noch Lesen (kein "Uebernehmen"), G_Intern: Lesen + Uebernehmen
Set-GPPermission -Guid $crm.Id -TargetName 'Authenticated Users' -TargetType Group -PermissionLevel GpoRead -Replace -ErrorAction SilentlyContinue
Set-GPPermission -Guid $crm.Id -TargetName 'G_Intern' -TargetType Group -PermissionLevel GpoApply

# ---------- Teil 4: WMI-Filter "nur Windows 10" + Datei kopieren fuer OU Promoter ----------
New-Item -ItemType File -Path 'C:\Daten\Pool\WMI-Filter.txt' -Force | Out-Null
$wmiName  = 'WMI_Nur_Windows10'
$wmiQuery = 'SELECT * FROM Win32_OperatingSystem WHERE Version LIKE "10.%" AND ProductType = "1"'
$wmiCont  = "CN=SOM,CN=WMIPolicy,CN=System,$root"
$wmi = Get-ADObject -SearchBase $wmiCont -Filter "msWMI-Name -eq '$wmiName'" -ErrorAction SilentlyContinue
if (-not $wmi) {
    $id  = (New-Uid)
    $now = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss.ffffff-000')
    $parm = "1;3;10;$($wmiQuery.Length);WQL;root\CIMv2;$wmiQuery;"
    New-ADObject -Name $id -Type 'msWMI-Som' -Path $wmiCont -OtherAttributes @{
        'msWMI-Name'=$wmiName; 'msWMI-Parm1'='Erkennt nur Windows-10/11-Clients (ProductType 1)';
        'msWMI-Parm2'=$parm; 'msWMI-ID'=$id; 'msWMI-Author'='Administrator@'+$fqdn;
        'instanceType'=4; 'showInAdvancedViewOnly'='TRUE';
        'msWMI-ChangeDate'=$now; 'msWMI-CreationDate'=$now }
    $wmi = Get-ADObject -SearchBase $wmiCont -Filter "msWMI-Name -eq '$wmiName'"
}
$txt = Get-Or-NewGPO 'U_Promoter_Textdatei_kopieren' 'Kopiert WMI-Filter.txt nach %TEMP% (nur Win10 via WMI-Filter)'
Set-GPPXml $txt Files @"
<?xml version="1.0" encoding="utf-8"?>
<Files clsid="{215B2E53-57CE-475c-80FE-9EEC14635851}"><File clsid="{50BE44C8-567A-4ed1-B1D0-9234FE1F38AF}" name="WMI-Filter.txt" status="WMI-Filter.txt" image="2" changed="$jetzt" uid="$(New-Uid)" userContext="1" bypassErrors="1"><Properties action="U" fromPath="\\$dc\Pool\WMI-Filter.txt" targetPath="%TempDir%\WMI-Filter.txt" readOnly="0" archive="1" hidden="0" suppress="0"/></File></Files>
"@
New-GPLink -Guid $txt.Id -Target "OU=Promoter,$extern" -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
$wmiId = $wmi.Name
Set-ADObject "CN={$($txt.Id)},CN=Policies,CN=System,$root" -Replace @{ gPCWQLFilter = "[$fqdn;$wmiId;0]" }

# ---------- Teil 5: Drucker freigeben + per UNC verteilen ----------------------------------
foreach ($p in 'Drucker_Farbe','Drucker_SW') {
    $port = if ($p -eq 'Drucker_Farbe') { '10.0.0.201' } else { '10.0.0.202' }
    if (-not (Get-PrinterPort -Name "IP_$port" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name "IP_$port" -PrinterHostAddress $port }
    if (-not (Get-Printer -Name $p -ErrorAction SilentlyContinue)) {
        Add-Printer -Name $p -DriverName ((Get-PrinterDriver | Where-Object Name -match 'PDF|XPS|PS Class' | Select-Object -First 1).Name) -PortName "IP_$port" -Shared -ShareName $p
    }
    $farbe = $p -eq 'Drucker_Farbe'
    Set-PrintConfiguration -PrinterName $p -Color $farbe          # Standardwerte: Farbe / Schwarzweiss
}
$drk = Get-Or-NewGPO 'U_Andrija_AG_Drucker' 'Verteilt Drucker_Farbe und Drucker_SW per UNC'
$sp = foreach ($p in 'Drucker_Farbe','Drucker_SW') {
    "<SharedPrinter clsid=`"{9A5E9697-9095-436d-A0EE-4D128FDFBCE5}`" name=`"$p`" status=`"$p`" image=`"2`" changed=`"$jetzt`" uid=`"$(New-Uid)`" userContext=`"1`" bypassErrors=`"1`"><Properties action=`"U`" comment=`"`" path=`"\\$dc\$p`" location=`"`" default=`"0`" skipLocal=`"0`" deleteAll=`"0`" persistent=`"0`" deleteMaps=`"0`" port=`"`"/></SharedPrinter>"
}
Set-GPPXml $drk Printers "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n<Printers clsid=`"{1F577D12-3D1B-471e-A1B7-060317597B9C}`">$($sp -join '')</Printers>"
New-GPLink -Guid $drk.Id -Target $firma -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null

# ---------- Teil 6 (Vorbereitung): Softwarefreigabe + Gruppe 7-Zip ------------------------
New-Item -ItemType Directory -Path 'C:\Software' -Force | Out-Null
if (-not (Get-SmbShare -Name 'Software$' -ErrorAction SilentlyContinue)) {
    $everyone = (New-Object Security.Principal.SecurityIdentifier 'S-1-1-0').Translate([Security.Principal.NTAccount]).Value
    New-SmbShare -Name 'Software$' -Path 'C:\Software' -ReadAccess $everyone | Out-Null
}
icacls C:\Software /grant '*S-1-1-0:(OI)(CI)RX' '*S-1-5-11:(OI)(CI)RX' | Out-Null
if (-not (Get-ADGroup -Filter "Name -eq '7-Zip'")) {
    New-ADGroup -Name '7-Zip' -GroupScope Global -GroupCategory Security -Path "OU=Gruppen,$firma" -Description 'Computer, die 7-Zip erhalten'
}
Add-ADGroupMember '7-Zip' -Members (Get-ADComputer 'client-andrija')
# 7-Zip MSI herunterladen (x64)
$msi = 'C:\Software\7z-x64.msi'
if (-not (Test-Path $msi)) { Invoke-WebRequest 'https://www.7-zip.org/a/7z2501-x64.msi' -OutFile $msi -UseBasicParsing }
$sw = Get-Or-NewGPO 'C_Domain_Software_7-Zip' 'Softwareinstallation 7-Zip (zugewiesen) - Paket in der GPMC hinzufuegen'
New-GPLink -Guid $sw.Id -Target $root -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
# Softwareinstallation kennt keine Zielgruppenadressierung (ILT gibt es nur bei GPP) ->
# Einschraenkung auf die Computergruppe "7-Zip" ueber Sicherheitsfilterung:
Set-GPPermission -Guid $sw.Id -TargetName 'Authenticated Users' -TargetType Group -PermissionLevel GpoRead -Replace -ErrorAction SilentlyContinue
Set-GPPermission -Guid $sw.Id -TargetName '7-Zip' -TargetType Group -PermissionLevel GpoApply

Get-GPO -All | Where-Object DisplayName -match '^(U|C)_' | Sort-Object DisplayName | Format-Table DisplayName, GpoStatus, WmiFilter
