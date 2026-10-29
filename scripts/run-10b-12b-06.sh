#!/bin/bash
# Auftraege 12B, 10B, 06 – im Hintergrund:  nohup bash scripts/run-10b-12b-06.sh > run6.log 2>&1 &
source scripts/m159.sh
rm -f logs/*.txt
m159_setup
MYIP=${MYIP:?MYIP=<eigene-IP>/32 setzen}
SGDC=sg-05addfb2fe672b565; SGCL=sg-04ee9adad1797e372
PUB1=subnet-0493de1c4a1045496; PUB2=subnet-0e17b549d0942c036
echo "== S3 Backup-Bucket"
B=tbz-m159-backup-milosevic
aws s3api head-bucket --bucket $B 2>/dev/null || aws s3api create-bucket --bucket $B
aws s3api put-public-access-block --bucket $B --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-versioning --bucket $B --versioning-configuration Status=Enabled
aws s3api get-bucket-versioning --bucket $B; aws s3api get-public-access-block --bucket $B --output text
echo "== Neue Instanzen"
AMI=$(aws ssm get-parameter --name /aws/service/ami-windows-latest/Windows_Server-2025-English-Full-Base --query Parameter.Value --output text)
launch() { [ "$(iid $1)" != "None" ] && { echo "$1 existiert"; return; }
  aws ec2 run-instances --image-id $AMI --instance-type t3.medium --key-name vockey --subnet-id $2 --private-ip-address $3 \
   --security-group-ids $4 --iam-instance-profile Name=LabInstanceProfile \
   --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=40,VolumeType=gp3}' \
   --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" --query 'Instances[0].InstanceId' --output text; }
launch dc2-andrija $PUB2 10.0.16.10 $SGDC
launch wac-andrija $PUB1 10.0.0.30 $SGCL
aws ec2 authorize-security-group-ingress --group-id $SGCL --ip-permissions "IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=$MYIP,Description=\"WAC HTTPS nur eigene IP\"}]" >/dev/null 2>&1
m159_upload
echo "== 12B auf DC1"
rl 12b runps dc-andrija 19-s3-backup-test.ps1; m159_logs
rl 20-svc runps dc-andrija 20-svc-admin.ps1; m159_logs
waitssm dc2-andrija 30; waitssm wac-andrija 0
rl 10-init runps dc2-andrija 02-init.ps1 -Hostname dc2-andrija
rl 06-init runps wac-andrija 02-init.ps1 -Hostname wac-andrija; m159_logs
waitssm dc2-andrija 60; waitssm wac-andrija 0
rl 10-promote runps dc2-andrija 21-dc2-promote.ps1; m159_logs
rl 06-join runps wac-andrija 03-client-join.ps1; m159_logs
waitssm dc2-andrija 240
rl 10-konfig runps dc2-andrija 22-dc2-konfig.ps1; m159_logs
rl 10-dns1 runps dc-andrija 25-dc1-dns2.ps1
rl 10-repl runps dc-andrija 23-repl-test.ps1; m159_logs
rl 10-client runps client-andrija 24-client-dns2.ps1; m159_logs
echo "== 06"
waitssm wac-andrija 0
rl 06-winrm runps dc-andrija 27-dc-winrm.ps1
rl 06-wac runps wac-andrija 26-wac-install.ps1; m159_logs
echo "== 10 Ausfalltest: DC1 stoppen"
IDC=$(iid dc-andrija); aws ec2 stop-instances --instance-ids $IDC >/dev/null; aws ec2 wait instance-stopped --instance-ids $IDC; echo "DC1 gestoppt $(date +%T)"
rl 10-ausfall runps client-andrija 24-client-dns2.ps1 -NurTest; m159_logs
aws ec2 start-instances --instance-ids $IDC >/dev/null; aws ec2 wait instance-running --instance-ids $IDC; echo "DC1 laeuft $(date +%T)"
waitssm dc-andrija 120
rl 10-nachher runcmd dc2-andrija 'repadmin /replsummary; nltest /dsgetdc:ec2.andrija.m159 /force'; m159_logs
aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-09238dc9f9e472a33 --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,PrivateIpAddress,State.Name]' --output text
echo R6-DONE
