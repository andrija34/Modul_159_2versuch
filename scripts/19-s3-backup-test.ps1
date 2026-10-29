<#  Auftrag 12 Variante B – S3-Backup auf dc-andrija: AWS CLI, Archiv, Sync, geplante Aufgabe, Disaster-Recovery-Test  #>
$ErrorActionPreference = 'Continue'
$aws = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'
if (-not (Test-Path $aws)) {
    Invoke-WebRequest https://awscli.amazonaws.com/AWSCLIV2.msi -OutFile "$env:TEMP\AWSCLIV2.msi" -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$env:TEMP\AWSCLIV2.msi`" /qn" -Wait
}
"== AWS CLI";   & $aws --version
& $aws configure set region us-east-1
"== Identitaet (Instanzrolle statt Access Keys)"; & $aws sts get-caller-identity --query Arn --output text

New-Item C:\CompanyArchive, C:\Scripts -ItemType Directory -Force | Out-Null
'Rechnung 2026-001, Kunde Muster AG, CHF 4''250.00'        | Set-Content C:\CompanyArchive\Rechnung_2026.txt
'Vertrag Kunde A – Laufzeit 2026-2028'                     | Set-Content C:\CompanyArchive\Vertrag_KundeA.txt
'Protokoll Geschaeftsleitung 27.10.2026'                   | Set-Content C:\CompanyArchive\Protokoll_GL.txt
Copy-Item "$PSScriptRoot\12b-Sync-ToCloud.ps1", "$PSScriptRoot\12b-Restore-FromCloud.ps1" C:\Scripts -Force

"== aws s3 ls (Verbindungstest)"; & $aws s3 ls
"== Sync";  & C:\Scripts\12b-Sync-ToCloud.ps1; Get-Content C:\Scripts\s3-sync.log -Tail 6
"== Geplante Aufgabe"
& C:\Scripts\12b-Sync-ToCloud.ps1 -Registrieren | Out-Null
$t = Get-ScheduledTask M159-S3-Backup
[pscustomobject]@{ Task=$t.TaskName; State=$t.State; User=$t.Principal.UserId; Intervall=$t.Triggers[0].Repetition.Interval; Aktion="$($t.Actions[0].Execute) $($t.Actions[0].Arguments)" } | Format-List
"== Bucket-Inhalt"; & $aws s3 ls s3://tbz-m159-backup-milosevic/CompanyArchive/

"== Disaster Recovery: Datei loeschen"
Remove-Item C:\CompanyArchive\Rechnung_2026.txt
"Vorhanden nach Loeschen: $(Test-Path C:\CompanyArchive\Rechnung_2026.txt)"
"== Restore"; & C:\Scripts\12b-Restore-FromCloud.ps1 -Datei Rechnung_2026.txt
"Inhalt: $(Get-Content C:\CompanyArchive\Rechnung_2026.txt)"
