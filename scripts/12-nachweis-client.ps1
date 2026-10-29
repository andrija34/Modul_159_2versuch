<#  Nachweise auf dem Client: Domaene, RDP-Gruppen, Berechtigungstests als echte Benutzer (Netzwerkzugriff)  #>
. (Join-Path $PSScriptRoot '_secret.ps1')
"===== 03: Client"
Get-CimInstance Win32_ComputerSystem | Format-List Name, Domain, PartOfDomain
nslookup client-andrija.ec2.andrija.m159
nslookup 10.0.0.20
"===== 03: lokale Gruppen (RDP-Konzept)"
"Administratoren:";       Get-LocalGroupMember -SID 'S-1-5-32-544' | ForEach-Object { '  ' + $_.Name }
"Remotedesktopbenutzer:"; Get-LocalGroupMember -SID 'S-1-5-32-555' | ForEach-Object { '  ' + $_.Name }
"===== 04: Berechtigungstests (SMB-Zugriff mit dem jeweiligen Benutzerkonto)"
$pw = Get-M159Secret '/m159/userpw' 'Kennwort Testbenutzer'
$dc = 'dc-andrija.ec2.andrija.m159'
function Test-Zugriff($user, $unc) {
    $cred = New-Object System.Management.Automation.PSCredential("EC2\$user", $pw)
    $name = 'T' + (Get-Random -Maximum 9999)
    try {
        New-PSDrive -Name $name -PSProvider FileSystem -Root $unc -Credential $cred -ErrorAction Stop | Out-Null
        $lesen = try { Get-ChildItem "$($name):\" -ErrorAction Stop | Out-Null; 'JA' } catch { 'NEIN' }
        # Schreiben direkt per UNC (die SMB-Sitzung laeuft mit den Anmeldedaten des Benutzers aus New-PSDrive)
        $f = "$unc\test-$user-$(Get-Date -Format HHmmss).txt"
        $schreiben = try { [IO.File]::WriteAllText($f, 'Test'); [IO.File]::Delete($f); 'JA' } catch { 'NEIN' }
        $sicht = (Get-ChildItem "$($name):\" -Directory -ErrorAction SilentlyContinue | ForEach-Object Name) -join ','
        Remove-PSDrive $name -Force
    } catch { $lesen = 'NEIN (Zugriff verweigert)'; $schreiben = 'NEIN'; $sicht = '' }
    '{0,-8} {1,-50} Lesen={2,-24} Schreiben={3,-5} sichtbare Ordner: {4}' -f $user, $unc, $lesen, $schreiben, $sicht
    net use * /delete /y 2>$null | Out-Null
}
Test-Zugriff skeller "\\$dc\Abteilungen\Buchhaltung"   # erwartet: Lesen JA, Schreiben NEIN
Test-Zugriff glang   "\\$dc\Pool"                      # erwartet: Schreiben JA
Test-Zugriff proth   "\\$dc\Intern"                    # erwartet: kein Zugriff
Test-Zugriff proth   "\\$dc\Abteilungen"               # ABE: proth sieht nur Promoter, Sekretariat, Buchhaltung (R)
Test-Zugriff skeller "\\$dc\Abteilungen"               # ABE: skeller sieht nur Sekretariat, Buchhaltung
Test-Zugriff bhuber  "\\$dc\Abteilungen\Buchhaltung"   # erwartet: Schreiben JA
"===== Computer-GPOs"
gpupdate /target:computer /force | Out-Null
gpresult /r /scope computer
