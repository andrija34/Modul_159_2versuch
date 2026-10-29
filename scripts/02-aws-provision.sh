#!/bin/bash
# Auftrag 02 – AWS-Umgebung gemaess Planung per AWS CLI (Learner-Lab-Terminal, us-east-1)
set -e
export AWS_DEFAULT_REGION=us-east-1
MYIP=${MYIP:?"MYIP=<oeffentliche IP>/32 setzen"}
tag() { aws ec2 create-tags --resources "$1" --tags Key=Name,Value="$2"; }

# Idempotent: vorhandene Ressourcen (per Name-Tag) wiederverwenden
byname() { aws ec2 $1 --filters Name=tag:Name,Values=$2 --query "$3" --output text; }
VPC=$(byname describe-vpcs m159-vpc 'Vpcs[0].VpcId')
if [ "$VPC" = "None" ] || [ -z "$VPC" ]; then
  VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text); tag $VPC m159-vpc
fi
aws ec2 modify-vpc-attribute --vpc-id $VPC --enable-dns-hostnames
IGW=$(byname describe-internet-gateways m159-igw 'InternetGateways[0].InternetGatewayId')
if [ "$IGW" = "None" ] || [ -z "$IGW" ]; then
  IGW=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text); tag $IGW m159-igw
  aws ec2 attach-internet-gateway --vpc-id $VPC --internet-gateway-id $IGW
fi
mk() { S=$(byname describe-subnets $3 'Subnets[0].SubnetId')
  if [ "$S" = "None" ] || [ -z "$S" ]; then S=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block $1 --availability-zone $2 --query Subnet.SubnetId --output text); tag $S $3; fi; echo $S; }
PUB1=$(mk 10.0.0.0/20   us-east-1a m159-public-1a)
PUB2=$(mk 10.0.16.0/20  us-east-1b m159-public-1b)
PRI1=$(mk 10.0.128.0/20 us-east-1a m159-private-1a)
PRI2=$(mk 10.0.144.0/20 us-east-1b m159-private-1b)
for S in $PUB1 $PUB2; do aws ec2 modify-subnet-attribute --subnet-id $S --map-public-ip-on-launch; done
RTP=$(byname describe-route-tables m159-rtb-public 'RouteTables[0].RouteTableId')
if [ "$RTP" = "None" ] || [ -z "$RTP" ]; then
  RTP=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text); tag $RTP m159-rtb-public
  aws ec2 create-route --route-table-id $RTP --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW >/dev/null
  for S in $PUB1 $PUB2; do aws ec2 associate-route-table --route-table-id $RTP --subnet-id $S >/dev/null; done
fi
RTI=$(byname describe-route-tables m159-rtb-private 'RouteTables[0].RouteTableId')
if [ "$RTI" = "None" ] || [ -z "$RTI" ]; then
  RTI=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text); tag $RTI m159-rtb-private
  for S in $PRI1 $PRI2; do aws ec2 associate-route-table --route-table-id $RTI --subnet-id $S >/dev/null; done
fi

SGDC=$(aws ec2 create-security-group --group-name m159-sg-dc --description "M159 Domain Controller" --vpc-id $VPC --query GroupId --output text); tag $SGDC m159-sg-dc
SGCL=$(aws ec2 create-security-group --group-name m159-sg-client --description "M159 Client/WAC" --vpc-id $VPC --query GroupId --output text); tag $SGCL m159-sg-client
r() { aws ec2 authorize-security-group-ingress --group-id $1 --ip-permissions "IpProtocol=$2,FromPort=$3,ToPort=$4,IpRanges=[{CidrIp=$5,Description=\"$6\"}]" >/dev/null; }
r $SGDC tcp 3389 3389 $MYIP "RDP nur eigene IP"
for p in "tcp 53 53 DNS" "udp 53 53 DNS" "tcp 88 88 Kerberos" "udp 88 88 Kerberos" "tcp 135 135 RPC-EPM" "tcp 139 139 NetBIOS" \
         "tcp 389 389 LDAP" "udp 389 389 LDAP" "tcp 445 445 SMB" "tcp 464 464 Kerberos-PW" "udp 464 464 Kerberos-PW" \
         "tcp 636 636 LDAPS" "tcp 3268 3269 GlobalCatalog" "tcp 49152 65535 RPC-dynamisch" "udp 123 123 NTP"; do
  set -- $p; r $SGDC $1 $2 $3 10.0.0.0/16 "$4"; done
aws ec2 authorize-security-group-ingress --group-id $SGDC --ip-permissions 'IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=10.0.0.0/16,Description="ICMP"}]' >/dev/null
r $SGDC tcp 5985 5986 10.0.0.30/32 "WinRM nur WAC"
r $SGCL tcp 3389 3389 $MYIP "RDP nur eigene IP"
for c in 10.0.0.0/20 10.0.128.0/20 10.0.144.0/20; do
  for p in "tcp 88 88 Kerberos" "tcp 135 135 RPC-EPM" "tcp 139 139 NetBIOS" "tcp 389 389 LDAP" "udp 53 53 DNS" "tcp 445 445 SMB" "tcp 49152 65535 RPC-dynamisch"; do
    set -- $p; r $SGCL $1 $2 $3 $c "$4"; done
  aws ec2 authorize-security-group-ingress --group-id $SGCL --ip-permissions "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=$c,Description=\"ICMP\"}]" >/dev/null
done

AMI=$(aws ssm get-parameter --name /aws/service/ami-windows-latest/Windows_Server-2025-English-Full-Base --query Parameter.Value --output text)
run() { aws ec2 run-instances --image-id $AMI --instance-type t3.medium --key-name vockey \
  --subnet-id $PUB1 --private-ip-address $2 --security-group-ids $3 --iam-instance-profile Name=LabInstanceProfile \
  --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=40,VolumeType=gp3}' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" --query 'Instances[0].InstanceId' --output text; }
IDC=$(run dc-andrija 10.0.0.10 $SGDC)
ICL=$(run client-andrija 10.0.0.20 $SGCL)
aws ec2 modify-instance-attribute --instance-id $IDC --disable-api-termination
aws ec2 wait instance-running --instance-ids $IDC $ICL
for i in $IDC $ICL; do A=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text); aws ec2 associate-address --instance-id $i --allocation-id $A >/dev/null; done
echo "VPC=$VPC PUB1=$PUB1 PUB2=$PUB2 PRI1=$PRI1 PRI2=$PRI2 SGDC=$SGDC SGCL=$SGCL IDC=$IDC ICL=$ICL" | tee ~/m159-ids.txt
aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,PrivateIpAddress,PublicIpAddress,State.Name]' --output table
