#!/bin/bash
# Teil 1: 12B, Instanzen DC2/WAC, WAC-Installation (ohne neue Admin-Konten/Freigaben)
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
m159_upload
echo "== 12B auf DC1"
rl 12b runps dc-andrija 19-s3-backup-test.ps1; m159_logs
waitssm dc2-andrija 30; waitssm wac-andrija 0
rl 10-init runps dc2-andrija 02-init.ps1 -Hostname dc2-andrija
rl 06-init runps wac-andrija 02-init.ps1 -Hostname wac-andrija; m159_logs
waitssm wac-andrija 60
rl 06-join runps wac-andrija 03-client-join.ps1; m159_logs
waitssm wac-andrija 60
rl 06-wac runps wac-andrija 26-wac-install.ps1; m159_logs
echo R6A-DONE
