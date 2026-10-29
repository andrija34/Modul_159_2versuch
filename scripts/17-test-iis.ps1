<#  Auftrag 13 Variante B – Test vom Client: Windows-Authentifizierung + Autorisierung ueber G_Intranet_Users  #>
. (Join-Path $PSScriptRoot '_secret.ps1')
$pw  = Get-M159Secret '/m159/userpw' 'Kennwort Testbenutzer'
$url = 'http://dc-andrija.ec2.andrija.m159/'
"== Anonym (ohne Anmeldedaten)"
try { $r = Invoke-WebRequest $url -UseBasicParsing -ErrorAction Stop; $r.StatusCode } catch { [int]$_.Exception.Response.StatusCode; $_.Exception.Response.Headers['WWW-Authenticate'] }
foreach ($u in 'skeller','proth') {
    "== Als $u"
    $cred = New-Object System.Management.Automation.PSCredential("EC2\$u", $pw)
    try { $r = Invoke-WebRequest $url -Credential $cred -UseBasicParsing -ErrorAction Stop; "HTTP $($r.StatusCode)"; ($r.Content -replace '<[^>]+>','').Trim() }
    catch { "HTTP " + [int]$_.Exception.Response.StatusCode + " " + $_.Exception.Response.StatusDescription }
}
"== Kerberos-Ticket fuer HTTP-Dienst (Computer-Kontext)"
klist get HTTP/dc-andrija.ec2.andrija.m159 2>&1 | Select-String 'Server|KerbTicket|HTTP' | Select-Object -First 4
