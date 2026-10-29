#!/bin/bash
# Auftrag 05 Variante B – Authentik (idp-andrija) gegen AD per LDAPS
source scripts/m159.sh
m159_setup; m159_upload
VPC=vpc-09238dc9f9e472a33; PUB1=subnet-0493de1c4a1045496
SGIDP=$(aws ec2 describe-security-groups --filters Name=group-name,Values=m159-sg-idp --query 'SecurityGroups[0].GroupId' --output text)
if [ "$SGIDP" = None ]; then
  SGIDP=$(aws ec2 create-security-group --group-name m159-sg-idp --description "M159 Authentik IdP (kein Inbound, Verwaltung via SSM)" --vpc-id $VPC --query GroupId --output text)
  aws ec2 create-tags --resources $SGIDP --tags Key=Name,Value=m159-sg-idp
fi
echo "SG idp: $SGIDP (keine Inbound-Regeln)"
if [ "$(iid idp-andrija)" = None ]; then
  AMI=$(aws ssm get-parameter --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id --query Parameter.Value --output text)
  aws ec2 run-instances --image-id $AMI --instance-type t3.medium --key-name vockey --subnet-id $PUB1 --private-ip-address 10.0.0.40 \
    --security-group-ids $SGIDP --iam-instance-profile Name=LabInstanceProfile \
    --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=20,VolumeType=gp3}' \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=idp-andrija}]" --query 'Instances[0].InstanceId' --output text
fi
rl 05-dc runps dc-andrija 28-ldaps-authentik-dc.ps1; m159_logs
waitssm idp-andrija 30
rl 05-install runsh idp-andrija 05b-authentik.sh install; m159_logs
rl 05-token  runsh idp-andrija 05b-authentik.sh token
rl 05-config runsh idp-andrija 05b-authentik.sh config
rl 05-test   runsh idp-andrija 05b-authentik.sh test; m159_logs
echo R05-DONE
