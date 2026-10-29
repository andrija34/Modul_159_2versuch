# GUI-Nachweise Teil 2: Admin-Konsolen aufgeklappt, Browser-SSO, Roaming auf 2. Rechner, WAC
source scripts/m159.sh
m159_upload
runcmd dc-andrija 'Enable-ADAccount svc_m159admin'
sess() { rl gui-$1-$2-a runps $1 30-gui-session.ps1 -User $2; sleep 100; waitssm $1 0; sleep 50; }
sess dc-andrija svc_m159admin;   rl gui-dc2  runps dc-andrija 31-gui-shot.ps1 -Set admin -Logoff; m159_logs
sess client-andrija skeller;     rl gui-sso  runps client-andrija 31-gui-shot.ps1 -Set sso -Logoff; m159_logs
sess wac-andrija skeller;        rl gui-roam runps wac-andrija 31-gui-shot.ps1 -Set roaming -Logoff; m159_logs
sess wac-andrija svc_m159admin;  rl gui-wac  runps wac-andrija 31-gui-shot.ps1 -Set wac -Logoff; m159_logs
for i in dc-andrija client-andrija wac-andrija; do runps $i 30-gui-session.ps1 -Aus >/dev/null; done
runcmd dc-andrija 'Disable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
bash scripts/gallery.sh
echo GUI2-DONE
