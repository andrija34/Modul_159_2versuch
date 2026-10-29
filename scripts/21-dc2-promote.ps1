<#  Auftrag 10 Variante B – dc2-andrija als zusaetzlichen DC in ec2.andrija.m159 heraufstufen (KEINE neue Gesamtstruktur)  #>
. (Join-Path $PSScriptRoot '_secret.ps1')
$if = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
# DNS: zuerst DC1 (AD-Zone muss beim Heraufstufen von einem funktionierenden DC kommen), danach sich selbst
Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 10.0.0.10, 127.0.0.1
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools | Select-Object Success, RestartNeeded
$cred = New-Object System.Management.Automation.PSCredential('EC2\svc_m159admin', (Get-M159Secret '/m159/svc_admin' 'Kennwort svc_m159admin'))
Import-Module ADDSDeployment
Install-ADDSDomainController -DomainName 'ec2.andrija.m159' -InstallDns -Credential $cred -SiteName 'Default-First-Site-Name' `
    -SafeModeAdministratorPassword (Get-M159Secret '/m159/dsrm' 'DSRM') -NoRebootOnCompletion -Force -WarningAction SilentlyContinue |
    Select-Object Status, Message
exit 3010
