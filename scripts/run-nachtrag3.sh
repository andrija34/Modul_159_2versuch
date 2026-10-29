rm -f logs/*.txt
rl 15-pw        runps dc-andrija 15-dc-passwortrichtlinie.ps1
rl 12-client    runps client-andrija 12-nachweis-client.ps1
m159_logs >/dev/null; echo N3-DONE
