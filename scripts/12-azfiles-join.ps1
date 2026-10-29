<#
  Auftrag 12 – Storage Account als Computerobjekt im lokalen AD registrieren (AD DS Auth fuer Azure Files)
  Auf dc-andrija als Domaenen-Admin, PowerShell 5.1 als Administrator.
#>
$ResourceGroup  = 'rg-m159'
$StorageAccount = 'andrijam159files'
$OU             = 'OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159'
$downloadPath   = 'C:\AzFilesHybrid'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $downloadPath -Force | Out-Null
if (-not (Test-Path "$downloadPath\AzFilesHybrid.zip")) {
    Invoke-WebRequest -Uri 'https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.3/AzFilesHybrid.zip' `
        -OutFile "$downloadPath\AzFilesHybrid.zip" -UseBasicParsing
    Expand-Archive "$downloadPath\AzFilesHybrid.zip" -DestinationPath $downloadPath -Force
}
Get-ChildItem $downloadPath -Recurse | Unblock-File
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
Set-Location $downloadPath
.\CopyToPSPath.ps1
Import-Module AzFilesHybrid -Force
Get-Command -Module AzFilesHybrid | Select-Object -First 10        # Schritt 1

Connect-AzAccount                                                  # Schritt 2 (Login im Browser durch Andrija)
Select-AzSubscription -SubscriptionName 'Azure for Students'

Join-AzStorageAccount -ResourceGroupName $ResourceGroup -StorageAccountName $StorageAccount `
    -DomainAccountType ComputerAccount -OrganizationalUnitDistinguishedName $OU   # Schritt 3

# Schritt 4: Verifizieren
Get-ADComputer $StorageAccount -Properties ServicePrincipalNames | Format-List Name, DistinguishedName, ServicePrincipalNames
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccount -ResourceGroupName $ResourceGroup -Verbose
(Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).AzureFilesIdentityBasedAuth.ActiveDirectoryProperties
