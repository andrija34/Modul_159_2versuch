# GUI-Nachweise Teil 3: WAC mit vertrautem Zertifikat, dsa.msc mit aufgeklappter Firmen-OU
source scripts/m159.sh
m159_upload
runcmd dc-andrija 'Enable-ADAccount svc_m159admin'
rl gui3-a runps wac-andrija 30-gui-session.ps1 -User svc_m159admin; sleep 100; waitssm wac-andrija 0; sleep 50
rl gui3-b runps wac-andrija 31-gui-shot.ps1 -Set wac -Logoff
runps wac-andrija 30-gui-session.ps1 -Aus >/dev/null
runcmd dc-andrija 'Disable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
bash scripts/gallery.sh
echo GUI3-DONE
