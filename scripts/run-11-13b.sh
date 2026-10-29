rm -f logs/*.txt
rl 16-profile runps dc-andrija 16-roaming-profiles.ps1
rl 13b-iis    runps dc-andrija 13b-iis-kerberos.ps1
rl 17-test    runps client-andrija 17-test-iis.ps1
m159_logs >/dev/null; echo R4-DONE
