#!/bin/bash
# Auftrag 10 Variante B – zweiter DC (dc2-andrija), Replikation, Ausfalltest. Hintergrund: nohup bash scripts/run-10b.sh > run10b.log 2>&1 &
source scripts/m159.sh
m159_upload
rl 10-svc runps dc-andrija 20-svc-admin.ps1; m159_logs
waitssm dc2-andrija 0
rl 10-promote runps dc2-andrija 21-dc2-promote.ps1; m159_logs
echo "Heraufstufung abgeschlossen $(date +%T) – warte auf Neustart"
sleep 120; waitssm dc2-andrija 120
rl 10-konfig runps dc2-andrija 22-dc2-konfig.ps1; m159_logs
rl 10-dns1   runps dc-andrija 25-dc1-dns2.ps1
rl 10-repl   runps dc-andrija 23-repl-test.ps1; m159_logs
rl 10-client runps client-andrija 24-client-dns2.ps1; m159_logs
echo "== Ausfalltest: DC1 stoppen $(date +%T)"
IDC=$(iid dc-andrija); aws ec2 stop-instances --instance-ids $IDC >/dev/null; aws ec2 wait instance-stopped --instance-ids $IDC; echo "DC1 gestoppt $(date +%T)"
rl 10-ausfall runps client-andrija 24-client-dns2.ps1 -NurTest; m159_logs
aws ec2 start-instances --instance-ids $IDC >/dev/null; aws ec2 wait instance-running --instance-ids $IDC; echo "DC1 laeuft wieder $(date +%T)"
waitssm dc-andrija 120
rl 10-nachher runcmd dc2-andrija 'repadmin /replsummary; nltest /dsgetdc:ec2.andrija.m159 /force'
rl 10-svc-aus runps dc-andrija 20-svc-admin.ps1 -Deaktivieren; m159_logs
echo R10-DONE
