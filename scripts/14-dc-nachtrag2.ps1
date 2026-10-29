<#  Nachtrag 2 (DC): PTR fuer Client, Drucker mit TCP/IP-faehigem Treiber, Passwortrichtlinie pruefen  #>
Import-Module ActiveDirectory, DnsServer
"== PTR Client"
Add-DnsServerResourceRecordPtr -ZoneName '0.0.10.in-addr.arpa' -Name '20' -PtrDomainName 'client-andrija.ec2.andrija.m159.' -ErrorAction SilentlyContinue
Get-DnsServerResourceRecord -ZoneName '0.0.10.in-addr.arpa' -RRType Ptr | Format-Table HostName, @{n='PTR';e={$_.RecordData.PtrDomainName}} -AutoSize
nslookup 10.0.0.20

"== Drucker"
"Verfuegbare Treiber im Treiberspeicher:"
pnputil /enum-drivers /class Printer | Select-String 'Original Name|Provider' | Select-Object -First 10
foreach ($d in 'Microsoft PCL6 Class Driver','Microsoft PS Class Driver','Generic / Text Only','Microsoft enhanced Point and Print compatibility driver') {
    try { Add-PrinterDriver -Name $d -ErrorAction Stop; "Treiber installiert: $d"; $drv = $d; break } catch { "nicht verfuegbar: $d" }
}
if (-not $drv) { $drv = (Get-PrinterDriver | Where-Object { $_.Name -notmatch 'PDF|XPS|Remote Desktop' } | Select-Object -First 1).Name }
"Verwendeter Treiber: $drv"
foreach ($p in 'Drucker_Farbe','Drucker_SW') {
    $port = if ($p -eq 'Drucker_Farbe') { 'IP_10.0.0.201' } else { 'IP_10.0.0.202' }
    if (-not (Get-Printer -Name $p -ErrorAction SilentlyContinue)) {
        try { Add-Printer -Name $p -DriverName $drv -PortName $port -Shared -ShareName $p -ErrorAction Stop } catch { "Add-Printer $p : $($_.Exception.Message)" }
    }
    Set-PrintConfiguration -PrinterName $p -Color ($p -eq 'Drucker_Farbe') -ErrorAction SilentlyContinue
}
Get-Printer | Format-Table Name, DriverName, PortName, Shared, ShareName -AutoSize
foreach ($p in 'Drucker_Farbe','Drucker_SW') { try { '{0}: Standard Farbe = {1}' -f $p, (Get-PrintConfiguration -PrinterName $p -ErrorAction Stop).Color } catch {} }

"== Passwortrichtlinie"
gpupdate /target:computer /force | Out-Null
Start-Sleep 15
Get-ADDefaultDomainPasswordPolicy | Format-List ComplexityEnabled, MaxPasswordAge, MinPasswordLength
