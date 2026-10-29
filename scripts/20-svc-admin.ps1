<#  Auftrag 10B/05B – temporaeres Admin-Dienstkonto fuer DC-Heraufstufung (DC2) und AD-CS-Installation.
    Wird nach Abschluss deaktiviert (-Deaktivieren). Kennwort liegt nur im SSM Parameter Store.  #>
param([switch]$Deaktivieren)
Import-Module ActiveDirectory
. (Join-Path $PSScriptRoot '_secret.ps1')
if ($Deaktivieren) { Disable-ADAccount svc_m159admin; Get-ADUser svc_m159admin | Select-Object SamAccountName, Enabled; return }
$ou = 'OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159'
if (-not (Get-ADUser -Filter "SamAccountName -eq 'svc_m159admin'")) {
    New-ADUser -Name svc_m159admin -SamAccountName svc_m159admin -UserPrincipalName 'svc_m159admin@ec2.andrija.m159' -Path $ou `
        -Description 'Temporaer: DC2-Heraufstufung / AD CS (wird danach deaktiviert)' `
        -AccountPassword (Get-M159Secret '/m159/svc_admin' 'Kennwort svc_m159admin') -Enabled $true -PasswordNeverExpires $true
} else { Enable-ADAccount svc_m159admin }
Add-ADGroupMember 'Domain Admins'     -Members svc_m159admin
Add-ADGroupMember 'Enterprise Admins' -Members svc_m159admin
Get-ADPrincipalGroupMembership svc_m159admin | Select-Object Name
