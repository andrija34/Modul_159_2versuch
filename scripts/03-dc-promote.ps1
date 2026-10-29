<#
  Auftrag 03 – Ersten DC einer neuen Gesamtstruktur einrichten (auf dc-andrija)
  Teil 1 (vor Neustart):  .\03-dc-promote.ps1 -Phase Promote
  Teil 2 (nach Neustart): .\03-dc-promote.ps1 -Phase Konfig
#>
param([ValidateSet('Promote','Konfig')] [string] $Phase = 'Promote')

. (Join-Path $PSScriptRoot '_secret.ps1')
$Domain  = 'ec2.andrija.m159'
$NetBIOS = 'EC2'

if ($Phase -eq 'Promote') {
    Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

    $dsrm = Get-M159Secret '/m159/dsrm' 'DSRM-Kennwort (Secrets-Ablage)'
    Install-ADDSForest -DomainName $Domain -DomainNetbiosName $NetBIOS `
        -InstallDns -SafeModeAdministratorPassword $dsrm `
        -DatabasePath 'C:\Windows\NTDS' -LogPath 'C:\Windows\NTDS' -SysvolPath 'C:\Windows\SYSVOL' `
        -NoRebootOnCompletion -Force   # Standardspeicherorte belassen
    exit 3010   # Neustart anfordern (SSM Run Command startet neu)
}
else {
    Import-Module ActiveDirectory, DnsServer

    # Statische IP 10.0.0.10/20, DNS = sich selbst (DC ist eigener DNS-Server)
    $if = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).Name
    $gw = (Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop | Select-Object -First 1
    if ((Get-NetIPInterface -InterfaceAlias $if -AddressFamily IPv4).Dhcp -eq 'Enabled') {
        Set-NetIPInterface -InterfaceAlias $if -Dhcp Disabled
        New-NetIPAddress -InterfaceAlias $if -IPAddress 10.0.0.10 -PrefixLength 20 -DefaultGateway $gw -ErrorAction SilentlyContinue | Out-Null
    }
    Set-DnsClientServerAddress -InterfaceAlias $if -ServerAddresses 127.0.0.1

    # DNS-Weiterleitung an Quad9
    Set-DnsServerForwarder -IPAddress 9.9.9.9 -PassThru

    # Reverse-Zonen pro genutztem Subnetzbereich (AD-integriert)
    foreach ($net in '10.0.0.0/24','10.0.16.0/24','10.0.128.0/24','10.0.144.0/24') {
        $zone = ($net -split '\.')[2] + '.0.10.in-addr.arpa'
        if (-not (Get-DnsServerZone -Name $zone -ErrorAction SilentlyContinue)) {
            Add-DnsServerPrimaryZone -NetworkId $net -ReplicationScope Forest -DynamicUpdate Secure
        }
    }

    # PTR fuer den DC selbst (A-Record existiert nach Promotion)
    Add-DnsServerResourceRecordPtr -ZoneName '0.0.10.in-addr.arpa' -Name '10' `
        -PtrDomainName "dc-andrija.$Domain." -ErrorAction SilentlyContinue
    ipconfig /registerdns | Out-Null

    # AD-Papierkorb aktivieren
    Enable-ADOptionalFeature -Identity 'Recycle Bin Feature' -Scope ForestOrConfigurationSet `
        -Target $Domain -Confirm:$false

    # Join-Konto (normaler Domaenenbenutzer; ms-DS-MachineAccountQuota erlaubt Domaenenbenutzern Joins)
    if (-not (Get-ADUser -Filter "SamAccountName -eq 'svc_join'")) {
        New-ADUser -Name 'svc_join' -SamAccountName 'svc_join' -Description 'Konto fuer Domaenenbeitritt (Lab)' `
            -AccountPassword (Get-M159Secret '/m159/svc_join' 'Kennwort svc_join') -Enabled $true -PasswordNeverExpires $true
    }

    # Tests fuer die Doku
    nslookup "dc-andrija.$Domain"
    nslookup 10.0.0.10
    Get-ADOptionalFeature -Filter 'Name -like "Recycle*"' | Format-List Name, EnabledScopes
}
