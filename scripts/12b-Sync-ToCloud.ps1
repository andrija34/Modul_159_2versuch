<#
  Auftrag 12 Variante B – lokales Archiv nach S3 synchronisieren.
  .\12b-Sync-ToCloud.ps1              -> Sync ausfuehren
  .\12b-Sync-ToCloud.ps1 -Registrieren -> geplante Aufgabe alle 15 Min. anlegen
#>
param([switch]$Registrieren)
$Quelle = 'C:\CompanyArchive'
$Ziel   = 's3://tbz-m159-backup-milosevic/CompanyArchive'
$Log    = 'C:\Scripts\s3-sync.log'
$aws    = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'

if ($Registrieren) {
    New-Item -ItemType Directory C:\Scripts -Force | Out-Null
    if ($PSCommandPath -ne 'C:\Scripts\12b-Sync-ToCloud.ps1') { Copy-Item $PSCommandPath C:\Scripts\12b-Sync-ToCloud.ps1 -Force }
    $action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\12b-Sync-ToCloud.ps1'
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
    Register-ScheduledTask -TaskName 'M159-S3-Backup' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest -Force
    return
}

"$(Get-Date -Format s) Start Sync $Quelle -> $Ziel" | Add-Content $Log
& $aws s3 sync $Quelle $Ziel --no-progress 2>&1 | Add-Content $Log
"$(Get-Date -Format s) Ende (ExitCode $LASTEXITCODE)" | Add-Content $Log
