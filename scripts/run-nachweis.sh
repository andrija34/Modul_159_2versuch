aws s3 cp s3://$M159_BUCKET/logs/all-logs.txt s3://$M159_BUCKET/logs/run1-aufbau.txt >/dev/null
rm -f logs/*.txt
rl 10-nachtrag    runps dc-andrija 10-dc-nachtrag.ps1
rl 11-nachweis-dc runps dc-andrija 11-nachweis-dc.ps1
rl 12-nachweis-cl runps client-andrija 12-nachweis-client.ps1
m159_logs >/dev/null; echo NACHWEIS-DONE
