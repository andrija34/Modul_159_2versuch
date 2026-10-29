<#  Auftrag 13 B – Korrektur: geerbte Regel "Allow * (alle Benutzer)" entfernen, nur G_Intranet_Users zulassen  #>
Import-Module WebAdministration
@'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <security>
      <authorization>
        <clear />
        <add accessType="Allow" roles="EC2\G_Intranet_Users" />
      </authorization>
    </security>
  </system.webServer>
</configuration>
'@ | Set-Content C:\inetpub\wwwroot\web.config -Encoding UTF8
Get-WebConfiguration -Filter /system.webServer/security/authorization/* -PSPath 'IIS:\Sites\Default Web Site' | Select-Object accessType, users, roles
