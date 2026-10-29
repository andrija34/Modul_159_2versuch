<#  GUI-Nachweise: Programme in der angemeldeten Benutzersitzung starten und Bildschirmfotos erstellen.
    Laeuft als SYSTEM (SSM) und startet pro Aufnahme eine geplante Aufgabe "nur interaktiv" im Kontext des angemeldeten Benutzers.
    -Set <Name> (siehe $sets) - Bilder -> C:\m159\gui\<name>.png und S3 pub/shots/<computer>-<benutzer>-<name>.png
    -RoamingDatei: Testdatei auf dem Desktop anlegen - -Logoff: Benutzer danach abmelden  #>
param([string]$Set, [string]$Url, [switch]$RoamingDatei, [switch]$Logoff)
$sets = @{
  'benutzer' = @(
    'desktop~~(New-Object -ComObject Shell.Application).MinimizeAll()~~8',
    'dieserpc~~Start-Process explorer.exe shell:MyComputerFolder~~8',
    'gpresult~~Start-Process cmd.exe -ArgumentList ''/k title gpresult & whoami & gpresult /r /scope user''~~25',
    'drucker~~Start-Process powershell.exe -ArgumentList ''-NoExit -Command "whoami; Get-Printer | Format-Table Name,DriverName,PortName,Shared -AutoSize"''~~12'
  )
  'admin' = @(
    'dsa~~Start-Process dsa.msc~~15~~{DOWN}{DOWN}{MULTIPLY}',
    'gpmc~~Start-Process gpmc.msc~~20~~{DOWN}{MULTIPLY}',
    'dns~~Start-Process dnsmgmt.msc~~15~~{DOWN}{MULTIPLY}',
    'aufgaben~~Start-Process taskschd.msc~~15~~{DOWN}',
    'servermanager~~Start-Process ServerManager.exe~~45'
  )
  'admin2' = @(
    'dsa2~~Start-Process dsa.msc~~20~~{DOWN}|{DOWN}|{RIGHT}|{DOWN}|{MULTIPLY}',
    'dns2~~Start-Process dnsmgmt.msc~~20~~{DOWN}|{RIGHT}|{DOWN}|{RIGHT}|{DOWN}|{DOWN}'
  )
  'sso' = @(
    'intranet-sso~~Start-Process msedge.exe -ArgumentList ''--no-first-run'',''--start-maximized'',''http://dc-andrija.ec2.andrija.m159/''~~25'
  )
  'roaming' = @(
    'roaming-desktop~~(New-Object -ComObject Shell.Application).MinimizeAll()~~8',
    'roaming-datei~~Start-Process notepad.exe -ArgumentList ([Environment]::GetFolderPath(''Desktop'') + ''\Roaming-Test.txt'')~~8'
  )
  'wac' = @(
    'rsat-dsa~~Start-Process dsa.msc~~20~~{DOWN}|{DOWN}|{RIGHT}|{DOWN}|{MULTIPLY}',
    'wac~~Start-Process msedge.exe -ArgumentList ''--no-first-run'',''--start-maximized'',''https://wac-andrija.ec2.andrija.m159/''~~60'
  )
  'einstieg' = @(
    'mittelerde-icacls~~Start-Process powershell.exe -ArgumentList ''-NoExit -Command "icacls C:\Mittelerde /t /q"''~~10',
    'mittelerde-voelker~~(New-Object -ComObject Shell.Application).Namespace("C:\Mittelerde").ParseName("V$([char]0xF6)lker").InvokeVerb("properties")~~6~~ACT:Properties|^{TAB}|^{TAB}|%v|SLEEP5',
    'mittelerde-elben~~(New-Object -ComObject Shell.Application).Namespace("C:\Mittelerde\V$([char]0xF6)lker").ParseName("Elben").InvokeVerb("properties")~~6~~ACT:Properties|^{TAB}|^{TAB}|%v|SLEEP5',
    'nslookup-root~~Start-Process cmd.exe -ArgumentList ''/k title nslookup & (echo exit | nslookup) & nslookup -type=NS . 8.8.8.8''~~15',
    'nslookup-ch~~Start-Process cmd.exe -ArgumentList ''/k title nslookup ch & nslookup -type=NS ch. 198.41.0.4 & nslookup -type=NS ch. 8.8.8.8''~~15'
  )
  'ldp' = @(
    'ldp~~Start-Process ldp.exe~~8~~^n|SLEEP2|dc-andrija.ec2.andrija.m159|{ENTER}|SLEEP4|SHOT:connect|^b|SLEEP2|{ENTER}|SLEEP4|SHOT:bind|^t|SLEEP2|DC=ec2,DC=andrija,DC=m159|{ENTER}|SLEEP4|^s|SLEEP2|OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159|{TAB}|^a|{(}&{(}objectCategory=person{)}{(}objectClass=user{)}{(}sAMAccountName=proth{)}{)}|%s|SLEEP1|SHOT:suche|%r|SLEEP5|{ESC}|SLEEP2'
  )
  'zip' = @(
    'gpme-7zip~~Start-Process gpme.msc -ArgumentList ''/gpobject:"LDAP://CN={%GPO%},CN=Policies,CN=System,DC=ec2,DC=andrija,DC=m159"''~~15~~{HOME}|{DOWN}|{DOWN}|{RIGHT}|SLEEP1|{DOWN}|{RIGHT}|SLEEP1|{DOWN}|SLEEP2|SHOT:vorher|+{F10}|SLEEP2|SHOT:menu|n|SLEEP1|{RIGHT}|{ENTER}|SLEEP5|SHOT:datei|\\dc-andrija.ec2.andrija.m159\Software$\7z-x64.msi|SLEEP1|SHOT:pfad|{ENTER}|SLEEP10|SHOT:deploy|{ENTER}|SLEEP15'
  )
  'authentik' = @(
    'ak~~Start-Process msedge.exe -ArgumentList ''--no-first-run'',''--hide-crash-restore-bubble'',''--start-maximized'',''%URL%''~~20~~SLEEP5|^{SUBTRACT}|^{SUBTRACT}|SLEEP2|SHOT:login|^l|SLEEP1|http://10.0.0.40:9000/if/admin/#/administration/overview|{ENTER}|SLEEP10|SHOT:overview|^l|SLEEP1|http://10.0.0.40:9000/if/admin/#/identity/users|{ENTER}|SLEEP10|SHOT:users|^l|SLEEP1|http://10.0.0.40:9000/if/admin/#/core/sources|{ENTER}|SLEEP10|SHOT:sources|^l|SLEEP1|http://10.0.0.40:9000/if/admin/#/core/applications|{ENTER}|SLEEP10|SHOT:apps|^l|SLEEP1|http://10.0.0.40:9000/if/admin/#/core/providers|{ENTER}|SLEEP10|SHOT:providers|^l|SLEEP1|http://10.0.0.40:9000/if/admin/#/policy/policies|{ENTER}|SLEEP10|SHOT:policies'
  )
}
$Shots = if ($Set) { $sets[$Set] } else { @() }
if ($Set -eq 'zip') { $gid = (Get-GPO -Name 'C_Domain_Software_7-Zip').Id.ToString(); $Shots = $Shots | ForEach-Object { $_ -replace '%GPO%', $gid }; "GPO-ID $gid" }
if ($Url) { $Shots = $Shots | ForEach-Object { $_.Replace('%URL%', $Url) } }
if ($Set -eq 'wac') {
    # selbstsigniertes WAC-Zertifikat lokal als vertrauenswuerdig eintragen (nur fuer die Anzeige im Browser auf dem Server selbst)
    $c = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq 'CN=WindowsAdminCenterSelfSigned' } | Select-Object -First 1
    if ($c) { $st = New-Object Security.Cryptography.X509Certificates.X509Store('Root','LocalMachine'); $st.Open('ReadWrite'); $st.Add($c); $st.Close(); "WAC-Zertifikat vertraut: $($c.Thumbprint)" }
}
$ErrorActionPreference = 'Continue'
$dir = 'C:\m159\gui'; New-Item $dir -ItemType Directory -Force | Out-Null
icacls $dir /grant '*S-1-5-11:(OI)(CI)M' | Out-Null
$user = (Get-CimInstance Win32_ComputerSystem).UserName
if (-not $user) { "Kein Benutzer an der Konsole angemeldet"; exit 1 }
"Angemeldet: $user"
$bucket = (Get-SSMParameter -Name /m159/bucket -Region us-east-1).Value
function Invoke-AsUser([string]$code, [int]$timeout = 120) {
    $f = Join-Path $dir ("t{0}.ps1" -f (Get-Random)); Set-Content $f $code -Encoding UTF8
    $a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$f`""
    $p = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName 'M159-GUI' -Action $a -Principal $p -Force | Out-Null
    Start-ScheduledTask 'M159-GUI'; Start-Sleep 3
    $t0 = Get-Date
    while ((Get-ScheduledTask 'M159-GUI').State -eq 'Running' -and ((Get-Date) - $t0).TotalSeconds -lt $timeout) { Start-Sleep 2 }
    Unregister-ScheduledTask 'M159-GUI' -Confirm:$false
}
$cap = @'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W { [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c); }
"@
function Shot($file) {
  $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
'@
foreach ($s in $Shots) {
    $n, $cmd, $w, $keys = $s -split '~~'; if (-not $w) { $w = 15 }
    $u = ($user -split '\\')[-1].ToLower(); $file = Join-Path $dir "$u-$n.png"; Remove-Item ($file -replace '\.png$','*.png') -ErrorAction SilentlyContinue
    $code = $cap + @"

`$before = (Get-Process).Id
$cmd
Start-Sleep $w
`$neu = Get-Process | Where-Object { `$before -notcontains `$_.Id -and `$_.MainWindowHandle -ne 0 } | Select-Object -Last 1
if (`$neu) { [W]::ShowWindow(`$neu.MainWindowHandle, 3) | Out-Null; [W]::SetForegroundWindow(`$neu.MainWindowHandle) | Out-Null; Start-Sleep 2 }
`$base = '$($file -replace '\.png$','')'
foreach (`$k in ('$($keys -replace "'","''")' -split '\|')) {
  if (-not `$k) { continue }
  if (`$k -like 'SLEEP*') { Start-Sleep ([int]`$k.Substring(5)) }
  elseif (`$k -like 'SHOT:*') { Shot (`$base + '-' + `$k.Substring(5) + '.png') }
  elseif (`$k -like 'ACT:*') { `$ws = New-Object -ComObject WScript.Shell; for (`$i=0; `$i -lt 10 -and -not `$ws.AppActivate(`$k.Substring(4)); `$i++) { Start-Sleep 1 }; Start-Sleep 1 }
  else { [System.Windows.Forms.SendKeys]::SendWait(`$k); Start-Sleep 1 }
}
Start-Sleep 3
Shot '$file'
Get-Process | Where-Object { `$before -notcontains `$_.Id -and `$_.Name -notin 'explorer','sihost','ctfmon','RuntimeBroker' } | Stop-Process -Force -ErrorAction SilentlyContinue
"@
    Invoke-AsUser $code ([int]$w + 180)
    if (-not (Test-Path $file)) { "FEHLT $n" }
    Get-ChildItem $dir -Filter "$u-$n*.png" | ForEach-Object {
        $key = "pub/shots/$($env:COMPUTERNAME.ToLower())-$($_.Name)"
        Write-S3Object -BucketName $bucket -Key $key -File $_.FullName -Region us-east-1
        "OK  $($_.Name)  ($([math]::Round($_.Length/1KB)) KB) -> s3://$bucket/$key"
    }
}
if ($RoamingDatei) {
    Invoke-AsUser '"Roaming-Test erstellt auf $env:COMPUTERNAME am $(Get-Date -Format s) von $env:USERNAME" | Set-Content "$([Environment]::GetFolderPath(''Desktop''))\Roaming-Test.txt"' 60
    "Roaming-Testdatei angelegt"
}
if ($Logoff) { Invoke-AsUser 'shutdown.exe /l /f' 30; "Abgemeldet" }
