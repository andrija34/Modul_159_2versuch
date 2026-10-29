<#  GUI-Nachweise: einmalige automatische Anmeldung eines Benutzers an der Konsole (fuer Screenshots per Skript).
    Kennwort kommt aus dem SSM Parameter Store, AutoLogonCount=1 -> Windows loescht Kennwort/Autologon nach der Anmeldung selbst.
    -Aus : Autologon-Werte entfernen.  #>
param([string]$User, [switch]$Aus)
. (Join-Path $PSScriptRoot '_secret.ps1')
$k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
if ($Aus) {
    Set-ItemProperty $k AutoAdminLogon '0'; Remove-ItemProperty $k DefaultPassword, AutoLogonCount -ErrorAction SilentlyContinue
    "Autologon entfernt"; return
}
$name = if ($User -eq 'svc_m159admin') { '/m159/svc_admin' } else { '/m159/userpw' }
$pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((Get-M159Secret $name 'Kennwort')))
Set-ItemProperty $k AutoAdminLogon '1'
Set-ItemProperty $k DefaultUserName $User
Set-ItemProperty $k DefaultDomainName 'EC2'
Set-ItemProperty $k DefaultPassword $pw
New-ItemProperty $k AutoLogonCount -Value 1 -PropertyType DWord -Force | Out-Null
# Edge ohne Ersteinrichtungs-Assistent, lokale Intranet-Seiten mit Windows-Anmeldung
New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' HideFirstRunExperience 1 -Type DWord
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' AuthServerAllowlist '*.ec2.andrija.m159,localhost' -Type String
# Server-Manager nicht automatisch oeffnen (stoert Screenshots)
New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Server\ServerManager' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Server\ServerManager' DoNotOpenAtLogon 1 -Type DWord
"Autologon fuer EC2\$User gesetzt - Neustart in 5 s"
shutdown.exe /r /t 5 /f /c "M159 GUI-Nachweis"
