<#
  Auftrag 13 Variante B – IIS mit Windows-Authentifizierung (Kerberos) und Gruppen-Autorisierung. Auf dc-andrija.
#>
Install-WindowsFeature Web-Server, Web-Windows-Auth, Web-Url-Auth -IncludeManagementTools
Import-Module WebAdministration, ActiveDirectory

Set-Content C:\inetpub\wwwroot\index.html '<!doctype html><meta charset="utf-8"><h1>Willkommen im gesch&uuml;tzten Intranet der Andrija AG!</h1>' -Encoding UTF8

$site = 'IIS:\Sites\Default Web Site'
Set-WebConfigurationProperty -Filter /system.webServer/security/authentication/anonymousAuthentication -PSPath 'IIS:\' -Location 'Default Web Site' -Name enabled -Value $false
Set-WebConfigurationProperty -Filter /system.webServer/security/authentication/windowsAuthentication  -PSPath 'IIS:\' -Location 'Default Web Site' -Name enabled -Value $true

# Gruppe + Autorisierung (URL Authorization)
if (-not (Get-ADGroup -Filter "Name -eq 'G_Intranet_Users'")) {
    New-ADGroup -Name G_Intranet_Users -GroupScope Global -GroupCategory Security -Path 'OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159'
}
Add-ADGroupMember G_Intranet_Users -Members skeller
# Autorisierung in der web.config der Site: <clear/> entfernt die geerbte Server-Regel "Allow *"
@'
<?xml version="1.0" encoding="UTF-8"?>
<configuration><system.webServer><security><authorization>
  <clear />
  <add accessType="Allow" roles="EC2\G_Intranet_Users" />
</authorization></security></system.webServer></configuration>
'@ | Set-Content C:\inetpub\wwwroot\web.config -Encoding UTF8

Get-WebConfiguration -Filter /system.webServer/security/authorization/* -PSPath 'IIS:\' -Location 'Default Web Site' | Select-Object accessType, users, roles
setspn -L dc-andrija      # HTTP-SPN ist ueber HOST/ abgedeckt (Site laeuft als ApplicationPoolIdentity/Computerkonto)

# Intranet-Zone per GPO (Site-zu-Zonen-Zuweisung) fuer den Browser-SSO-Test
Import-Module GroupPolicy
$g = Get-GPO -Name 'U_Andrija_AG_Intranetzone' -ErrorAction SilentlyContinue
if (-not $g) { $g = New-GPO -Name 'U_Andrija_AG_Intranetzone' -Comment 'http://dc-andrija.ec2.andrija.m159 = Lokales Intranet (SSO)' }
Set-GPRegistryValue -Guid $g.Id -Key 'HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey' `
    -ValueName 'http://dc-andrija.ec2.andrija.m159' -Type String -Value '1' | Out-Null
New-GPLink -Guid $g.Id -Target 'OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159' -LinkEnabled Yes -ErrorAction SilentlyContinue | Out-Null
Get-WebConfigurationProperty -Filter /system.webServer/security/authentication/anonymousAuthentication -PSPath 'IIS:\' -Location 'Default Web Site' -Name enabled | Select-Object @{n='Anonymous';e={$_.Value}}
Get-WebConfigurationProperty -Filter /system.webServer/security/authentication/windowsAuthentication  -PSPath 'IIS:\' -Location 'Default Web Site' -Name enabled | Select-Object @{n='WindowsAuth';e={$_.Value}}
