# GUI-Nachweise Teil 6: Wiederholung ldp (Subtree), 7-Zip-Paket, Authentik in einer Edge-Sitzung
source scripts/m159.sh
m159_upload
aws s3 rm s3://$M159_BUCKET/pub/shots/ --recursive --exclude '*' --include '*-ldp*' --include '*gpme*' --include '*-ak*' >/dev/null; rm -f shots/*-ldp* shots/*gpme* shots/*-ak*
runcmd dc-andrija 'Enable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
sess() { rl gui6-$1-s runps $1 30-gui-session.ps1 -User svc_m159admin; sleep 100; waitssm $1 0; sleep 60; }
# 08 + 07 auf dem DC
sess dc-andrija; rl gui6-ldp runps dc-andrija 31-gui-shot.ps1 -Set ldp
rl gui6-zip runps dc-andrija 31-gui-shot.ps1 -Set zip -Logoff
rl gui6-zipcheck runcmd dc-andrija '$g=(Get-GPO C_Domain_Software_7-Zip).Id; Get-ChildItem "C:\Windows\SYSVOL\domain\Policies\{$g}\Machine\Applications" -ErrorAction SilentlyContinue | Select Name,Length; Get-ADObject -SearchBase "CN={$g},CN=Policies,CN=System,DC=ec2,DC=andrija,DC=m159" -LDAPFilter "(objectClass=packageRegistration)" -Properties displayName,msiFileList | Select displayName,msiFileList | Format-List'
# 05 Authentik-UI ueber wac-andrija (Port 9000 nur von wac-andrija, danach wieder weg)
SG=sg-05140a4833efabd6c
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 9000 --cidr 10.0.0.30/32 >/dev/null && echo "SG 9000 offen fuer 10.0.0.30"
sess wac-andrija
cat > scripts/ak-recovery.sh <<'S'
cd /opt/authentik && docker compose exec -T worker ak create_recovery_key 30 akadmin 2>/dev/null | grep -o '/recovery/use-token/[^ ]*' | tail -1
S
TOK=$(runsh idp-andrija ak-recovery.sh | grep -o '/recovery/use-token/[A-Za-z0-9/_-]*' | tail -1)
echo "Recovery-Pfad erhalten: ${TOK:+ja}"
rl gui6-ak runps wac-andrija 31-gui-shot.ps1 -Set authentik -Url "http://10.0.0.40:9000$TOK" -Logoff
aws ec2 revoke-security-group-ingress --group-id $SG --protocol tcp --port 9000 --cidr 10.0.0.30/32 >/dev/null && echo "SG 9000 wieder geschlossen"
for i in client-andrija dc-andrija wac-andrija; do runps $i 30-gui-session.ps1 -Aus >/dev/null; done
runcmd dc-andrija 'Disable-ADAccount svc_m159admin; (Get-ADUser svc_m159admin).Enabled'
# 7-Zip: Client zweimal neu starten, dann Installation pruefen
# Hinweis: gpupdate /force wartet nach Softwarezuweisung auf "Neustart (J/N)?" -> Neustart direkt ausloesen, ohne auf das Ergebnis zu warten
ID=$(iid client-andrija)
for r in 1 2; do aws ssm send-command --instance-ids $ID --document-name AWS-RunPowerShellScript --parameters '{"commands":["Start-Sleep 5; Restart-Computer -Force"]}' --query Command.CommandId --output text; sleep 60; waitssm client-andrija 30; sleep 90; done
sleep 60
rl gui6-zipclient runcmd client-andrija 'Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ? DisplayName -like "7-Zip*" | Select DisplayName,DisplayVersion,InstallDate | Format-List; Get-WinEvent -FilterHashtable @{LogName="Application";ProviderName="MsiInstaller";Id=1033} -MaxEvents 3 -ErrorAction SilentlyContinue | Select TimeCreated,Message | Format-List; Get-WinEvent -FilterHashtable @{LogName="Application";ProviderName="Application Management Group Policy"} -MaxEvents 3 -ErrorAction SilentlyContinue | Select TimeCreated,Id,Message | Format-List'
m159_logs
GAL='ldp|gpme|-ak' bash scripts/gallery.sh
echo GUI6-DONE
