<#
  Auftrag 12 Variante B – einzelne Datei aus S3 wiederherstellen.
  .\12b-Restore-FromCloud.ps1 -Datei Rechnung_2026.txt
#>
param([Parameter(Mandatory)][string]$Datei)
$Bucket = 's3://tbz-m159-backup-milosevic/CompanyArchive'
$aws    = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'
& $aws s3 cp "$Bucket/$Datei" "C:\CompanyArchive\$Datei"
Get-Item "C:\CompanyArchive\$Datei" | Format-List FullName, Length, LastWriteTime
