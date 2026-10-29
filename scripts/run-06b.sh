# Auftrag 06 – Nachtrag: ADWS (9389) VPC-intern, WinRM auf dem DC nur vom WAC, Pruefung
source scripts/m159.sh
aws ec2 authorize-security-group-ingress --group-id sg-05addfb2fe672b565 --ip-permissions 'IpProtocol=tcp,FromPort=9389,ToPort=9389,IpRanges=[{CidrIp=10.0.0.0/16,Description="AD Web Services (RSAT/PowerShell) VPC-intern"}]' >/dev/null && echo "SG 9389 ok"
m159_upload
rl 06-winrm runps dc-andrija 27-dc-winrm.ps1
rl 06-check runps wac-andrija 29-wac-check.ps1; m159_logs
echo R6D-DONE
