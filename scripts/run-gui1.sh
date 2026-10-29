# GUI-Nachweise Teil 1: skeller am Client (Laufwerke, CRM, gpresult, Drucker, Roaming-Datei), danach proth; Admin-Konsolen am DC
source scripts/m159.sh
m159_upload
runcmd dc-andrija 'Enable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
rl gui-d1 runps dc-andrija 30-gui-session.ps1 -User svc_m159admin
sleep 120; waitssm dc-andrija 0; sleep 60
rl gui-c1 runps client-andrija 30-gui-session.ps1 -User skeller
sleep 120; waitssm client-andrija 0; sleep 60
rl gui-c2 runps client-andrija 31-gui-shot.ps1 -Set benutzer -RoamingDatei -Logoff; m159_logs
rl gui-d2 runps dc-andrija 31-gui-shot.ps1 -Set admin -Logoff; m159_logs
rl gui-c3 runps client-andrija 30-gui-session.ps1 -User proth
sleep 150; waitssm client-andrija 0; sleep 60
rl gui-c4 runps client-andrija 31-gui-shot.ps1 -Set benutzer -Logoff
rl gui-p  runcmd dc-andrija 'Get-ChildItem C:\Daten\Profiles -Directory | ft Name,LastWriteTime -a; Get-ChildItem C:\Daten\Profiles\skeller* -Recurse -Filter Roaming-Test.txt -ErrorAction SilentlyContinue | % { $_.FullName; Get-Content $_.FullName }'
runcmd dc-andrija 'Disable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
m159_logs
aws s3 ls s3://$M159_BUCKET/pub/shots/
echo GUI1-DONE
