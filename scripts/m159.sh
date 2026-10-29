#!/bin/bash
# Hilfsfunktionen fuer AWS CloudShell (Learner Lab):  source m159.sh
#   m159_setup                 -> S3-Bucket fuer Skripte + Secrets im SSM Parameter Store anlegen
#   m159_upload                -> ./scripts nach S3 kopieren
#   runps <Instanzname> <Skript.ps1> [Argumente]   -> Skript per SSM Run Command auf der Instanz ausfuehren
#   runcmd <Instanzname> '<PowerShell-Befehl>'       -> einzelnen Befehl ausfuehren
export AWS_DEFAULT_REGION=us-east-1
ACCT=$(aws sts get-caller-identity --query Account --output text)
export M159_BUCKET="m159-andrija-scripts-$ACCT"

m159_setup() {
  aws s3api head-bucket --bucket $M159_BUCKET 2>/dev/null || aws s3 mb s3://$M159_BUCKET
  for p in dsrm userpw svc_join svc_fw_ldap svc_admin svc_authentik akadmin ak_token; do
    if ! aws ssm get-parameter --name /m159/$p >/dev/null 2>&1; then
      aws ssm put-parameter --name /m159/$p --type SecureString --value "$(openssl rand -base64 15 | tr -d '/+=')aA1!" >/dev/null
      echo "Secret /m159/$p angelegt"
    fi
  done
  aws ssm put-parameter --name /m159/bucket --type String --value $M159_BUCKET --overwrite >/dev/null
}
m159_upload() { aws s3 sync ./scripts s3://$M159_BUCKET/scripts --delete --exclude '*.sh' >/dev/null && echo "Skripte hochgeladen"; }
iid() { aws ec2 describe-instances --filters Name=tag:Name,Values=$1 Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].InstanceId' --output text; }
_send() {  # $1=instance-name, $2=json-commands
  local id=$(iid $1)
  local cid=$(aws ssm send-command --instance-ids $id --document-name AWS-RunPowerShellScript \
      --parameters "$2" --timeout-seconds 3600 --query Command.CommandId --output text)
  echo ">> $1 ($id) Command $cid"
  while true; do
    sleep 5
    st=$(aws ssm get-command-invocation --command-id $cid --instance-id $id --query Status --output text 2>/dev/null)
    case "$st" in Success|Failed|Cancelled|TimedOut) break;; esac
  done
  aws ssm get-command-invocation --command-id $cid --instance-id $id --query '[Status,StandardOutputContent,StandardErrorContent]' --output text
}
runps() {
  local inst=$1 file=$2; shift 2
  local cmd="\$d='C:\\m159'; New-Item -ItemType Directory \$d -Force | Out-Null; Read-S3Object -BucketName $M159_BUCKET -KeyPrefix scripts -Folder \$d -Region us-east-1 | Out-Null; Set-Location \$d; & \"\$d\\$file\" $*; exit \$LASTEXITCODE"
  _send $inst "$(jq -cn --arg c "$cmd" '{commands:[$c]}')"
}
runcmd() { _send $1 "$(jq -cn --arg c "$2" '{commands:[$c]}')"; }

# Logging-Helfer: rl <name> <befehl...>  -> Ausgabe nach logs/<name>.txt;  m159_logs -> alle Logs nach S3
mkdir -p logs
rl() { local n=$1; shift; "$@" 2>&1 | tee logs/$n.txt; }
m159_logs() { cat logs/*.txt > /tmp/all-logs.txt; aws s3 cp /tmp/all-logs.txt s3://$M159_BUCKET/logs/all-logs.txt >/dev/null; }
# Warten, bis der SSM-Agent einer Instanz (wieder) online ist
waitssm() { local id; sleep ${2:-60}; for i in $(seq 1 90); do id=$(iid $1)
  [ "$(aws ssm describe-instance-information --filters Key=InstanceIds,Values=$id --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null)" = Online ] && { echo "$1 online"; return 0; }; sleep 10; done; echo "$1 NICHT online"; }
# Bash-Skript auf Linux-Instanz (AWS-RunShellScript) ausfuehren:  runsh <Instanz> <Skript.sh> [Argumente]
runsh() { local inst=$1 file=$2; shift 2
  aws s3 cp scripts/$file s3://$M159_BUCKET/scripts-linux/$file >/dev/null
  local id=$(iid $inst)
  local cid=$(aws ssm send-command --instance-ids $id --document-name AWS-RunShellScript --timeout-seconds 3600 \
    --parameters "$(jq -cn --arg c "export PATH=\$PATH:/snap/bin; command -v aws >/dev/null || snap install aws-cli --classic >/dev/null; command -v jq >/dev/null || (apt-get update -qq && apt-get install -y -qq jq >/dev/null); aws s3 cp s3://$M159_BUCKET/scripts-linux/$file /tmp/$file >/dev/null && bash /tmp/$file $*" '{commands:[$c]}')" --query Command.CommandId --output text)
  echo ">> $inst ($id) Command $cid"
  while true; do sleep 5; st=$(aws ssm get-command-invocation --command-id $cid --instance-id $id --query Status --output text 2>/dev/null)
    case "$st" in Success|Failed|Cancelled|TimedOut) break;; esac; done
  aws ssm get-command-invocation --command-id $cid --instance-id $id --query '[Status,StandardOutputContent,StandardErrorContent]' --output text; }
