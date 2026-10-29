<#  Auftrag 10 Variante B – Replikationsbeweis in beide Richtungen (auf dc-andrija ausfuehren)  #>
Import-Module ActiveDirectory
. (Join-Path $PSScriptRoot '_secret.ps1')
$cred = New-Object System.Management.Automation.PSCredential('EC2\svc_m159admin', (Get-M159Secret '/m159/svc_admin' 'Kennwort svc_m159admin'))
$ou = 'OU=Intern,OU=Benutzer,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159'
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'" -ErrorAction SilentlyContinue)) { $ou = 'CN=Users,DC=ec2,DC=andrija,DC=m159' }
Get-ADUser -Filter "SamAccountName -eq 'andrija-repl-test'" | Remove-ADUser -Confirm:$false
Start-Sleep 20
"== 1) Benutzer auf DC1 anlegen"
$t0 = Get-Date
New-ADUser -Name 'andrija-repl-test' -SamAccountName 'andrija-repl-test' -Path $ou -Server dc-andrija -Enabled $false
"angelegt auf dc-andrija um $($t0.ToString('HH:mm:ss'))"
$u = $null
while (-not $u -and ((Get-Date) - $t0).TotalSeconds -lt 300) {
    $u = Get-ADUser -Filter "SamAccountName -eq 'andrija-repl-test'" -Server dc2-andrija -Credential $cred -ErrorAction SilentlyContinue
    if (-not $u) { Start-Sleep 2 }
}
"auf dc2-andrija sichtbar nach $([int]((Get-Date) - $t0).TotalSeconds) s: $($u.DistinguishedName)"
"== 2) Aenderung auf DC2, Replikation erzwingen, Pruefung auf DC1"
Set-ADUser 'andrija-repl-test' -Description 'geaendert auf DC2' -Server dc2-andrija -Credential $cred
$t1 = Get-Date
repadmin /syncall dc2-andrija /AdeP | Select-String 'SyncAll terminated|error' 
$d = $null
while ($d -ne 'geaendert auf DC2' -and ((Get-Date) - $t1).TotalSeconds -lt 300) {
    $d = (Get-ADUser 'andrija-repl-test' -Server dc-andrija -Properties Description).Description
    if ($d -ne 'geaendert auf DC2') { Start-Sleep 2 }
}
"Description auf dc-andrija: '$d' (nach $([int]((Get-Date) - $t1).TotalSeconds) s)"
Get-ADReplicationAttributeMetadata -Object (Get-ADUser 'andrija-repl-test').DistinguishedName -Server dc-andrija -Properties description |
    Format-Table AttributeName, LastOriginatingChangeDirectoryServerIdentity, LastOriginatingChangeTime, Version -AutoSize
"== replsummary"; repadmin /replsummary
