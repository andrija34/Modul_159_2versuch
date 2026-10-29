rm -f logs/*.txt
rl 18-iisfix runps dc-andrija 18-iis-fix.ps1
rl 17-test2  runps client-andrija 17-test-iis.ps1
m159_logs >/dev/null; echo R5-DONE
