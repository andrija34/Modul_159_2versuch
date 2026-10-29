<#  Auftrag 07 Teil 1: Passwortrichtlinie (Default Domain Policy) – Kontrolle und Anwendung  #>
Import-Module ActiveDirectory, GroupPolicy
# Domaenenattribute an die GPO-Einstellungen angleichen (der PDC uebernimmt sonst erst beim naechsten Sicherheits-Refresh)
Set-ADDefaultDomainPasswordPolicy -Identity (Get-ADDomain).DNSRoot -ComplexityEnabled $false -MaxPasswordAge 0
secedit /refreshpolicy machine_policy /enforce 2>$null | Out-Null
"== Domaenen-Passwortrichtlinie (wirksam)"
Get-ADDefaultDomainPasswordPolicy | Format-List ComplexityEnabled, MaxPasswordAge, MinPasswordLength, PasswordHistoryCount
"== Einstellungen in der Default Domain Policy (GPO-Bericht)"
[xml]$r = Get-GPOReport -Name 'Default Domain Policy' -ReportType Xml
$r.GPO.Computer.ExtensionData.Extension.Account | Where-Object { $_.Type -eq 'Password' } | Format-Table Name, SettingNumber, SettingBoolean -AutoSize
