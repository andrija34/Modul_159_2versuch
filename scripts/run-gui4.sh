source scripts/m159.sh
m159_upload
runcmd dc-andrija 'Enable-ADAccount svc_m159admin'
sess() { rl gui4-$1-a runps $1 30-gui-session.ps1 -User $2; sleep 100; waitssm $1 0; sleep 50; }
sess dc-andrija svc_m159admin;  rl gui4-dc  runps dc-andrija 31-gui-shot.ps1 -Set admin2 -Logoff
sess wac-andrija svc_m159admin; rl gui4-wac runps wac-andrija 31-gui-shot.ps1 -Set wac -Logoff
for i in dc-andrija wac-andrija; do runps $i 30-gui-session.ps1 -Aus >/dev/null; done
runcmd dc-andrija 'Disable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
bash scripts/gallery.sh
echo GUI4-DONE
