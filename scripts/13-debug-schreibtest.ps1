<#  Fehlersuche Schreibtest (Client): Fehlermeldung beim Schreiben als glang ausgeben  #>
. (Join-Path $PSScriptRoot '_secret.ps1')
$pw = Get-M159Secret '/m159/userpw' 'Kennwort'
$cred = New-Object System.Management.Automation.PSCredential('EC2\glang', $pw)
net use * /delete /y 2>$null | Out-Null
New-PSDrive -Name W -PSProvider FileSystem -Root '\\dc-andrija.ec2.andrija.m159\Pool' -Credential $cred -ErrorAction Stop | Out-Null
try { Set-Content 'W:\test-glang.txt' 'Test' -ErrorAction Stop; 'Schreiben OK'; Get-Item 'W:\test-glang.txt' | Select-Object FullName, Length; Remove-Item 'W:\test-glang.txt' }
catch { 'FEHLER: ' + $_.Exception.GetType().FullName + ' - ' + $_.Exception.Message }
try { [IO.File]::WriteAllText('\\dc-andrija.ec2.andrija.m159\Pool\test2-glang.txt', 'x'); 'IO.File OK'; Remove-Item '\\dc-andrija.ec2.andrija.m159\Pool\test2-glang.txt' }
catch { 'FEHLER IO: ' + $_.Exception.Message }
net use
Remove-PSDrive W -Force
