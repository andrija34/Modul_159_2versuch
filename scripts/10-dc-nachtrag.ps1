<#
  Nachtrag auf dem DC nach dem ersten Lauf (Korrekturen aus dem Log):
   - AGDLP: direkte Eintraege der globalen Gruppen auf Sekretariat/Buchhaltung entfernen, DL-Gruppen in OU=Gruppen
   - Drucker mit vorhandenem Treiber anlegen
   - Auftrag 07 Teil 1: Passwortrichtlinie in der Default Domain Policy (Komplexitaet aus, max. Kennwortalter 0)
#>
Import-Module ActiveDirectory, GroupPolicy
$dom = Get-ADDomain; $root = $dom.DistinguishedName; $fqdn = $dom.DNSRoot
$grpOU = "OU=Gruppen,OU=Andrija_AG,$root"

# --- AGDLP bereinigen ------------------------------------------------------------------
Get-ADGroup -Filter 'Name -like "DL_FS_*"' | Where-Object { $_.DistinguishedName -notlike "*$grpOU" } | Move-ADObject -TargetPath $grpOU
foreach ($p in 'C:\Daten\Abteilungen\Sekretariat','C:\Daten\Abteilungen\Buchhaltung') {
    icacls $p /remove:g 'EC2\G_GL' 'EC2\G_Sekretariat' 'EC2\G_Buchhaltung' 'EC2\G_Promoter' | Out-Null
    "== $p"; icacls $p
}
Get-ADGroup -Filter 'Name -like "DL_FS_*"' | ForEach-Object {
    '{0,-22} {1,-12} Mitglieder: {2}' -f $_.Name, $_.GroupScope, ((Get-ADGroupMember $_ | ForEach-Object Name) -join ', ')
}

# --- Drucker ----------------------------------------------------------------------------
$drv = (Get-PrinterDriver | Where-Object Name -match 'PDF|XPS|PS Class' | Select-Object -First 1).Name
"Verwendeter Treiber: $drv"
foreach ($p in 'Drucker_Farbe','Drucker_SW') {
    $port = if ($p -eq 'Drucker_Farbe') { 'IP_10.0.0.201' } else { 'IP_10.0.0.202' }
    if (-not (Get-Printer -Name $p -ErrorAction SilentlyContinue)) {
        Add-Printer -Name $p -DriverName $drv -PortName $port -Shared -ShareName $p
    }
    Set-PrintConfiguration -PrinterName $p -Color ($p -eq 'Drucker_Farbe') -ErrorAction SilentlyContinue
}
Get-Printer | Where-Object Name -like 'Drucker_*' | Format-Table Name, DriverName, PortName, Shared, ShareName
foreach ($p in 'Drucker_Farbe','Drucker_SW') { '{0}: Farbe = {1}' -f $p, (Get-PrintConfiguration -PrinterName $p).Color }

# --- Passwortrichtlinie in der Default Domain Policy -----------------------------------
$ddp  = Get-GPO -Name 'Default Domain Policy'
$inf  = "\\$fqdn\SYSVOL\$fqdn\Policies\{$($ddp.Id)}\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"
$txt  = Get-Content $inf -Encoding Unicode
$txt  = $txt -replace '^PasswordComplexity = \d+', 'PasswordComplexity = 0' -replace '^MaximumPasswordAge = -?\d+', 'MaximumPasswordAge = 0'
Set-Content $inf $txt -Encoding Unicode
$ad   = Get-ADObject "CN={$($ddp.Id)},CN=Policies,CN=System,$root" -Properties versionNumber
$ver  = [int]$ad.versionNumber + 1          # Computer-Version (untere 16 Bit)
Set-ADObject $ad -Replace @{ versionNumber = $ver }
$ini  = "\\$fqdn\SYSVOL\$fqdn\Policies\{$($ddp.Id)}\GPT.INI"
(Get-Content $ini) -replace 'Version=\d+', "Version=$ver" | Set-Content $ini
gpupdate /target:computer /force | Out-Null
Start-Sleep 10
Get-Content $inf -Encoding Unicode | Select-String 'Password'
Get-ADDefaultDomainPasswordPolicy | Format-List ComplexityEnabled, MaxPasswordAge, MinPasswordLength
