# Auftrag 12 – Variante B: Hybrid Cloud Storage & Backup mit AWS S3

Skripte: [`12b-Sync-ToCloud.ps1`](../../scripts/12b-Sync-ToCloud.ps1), [`12b-Restore-FromCloud.ps1`](../../scripts/12b-Restore-FromCloud.ps1)

## Setup

- S3 Bucket **`tbz-m159-backup-milosevic`** (us-east-1, Block Public Access = an, Versionierung an).
- IAM: Im **Learner Lab** dürfen keine IAM-User erstellt werden. Ersatz: Die Lab-Rolle **LabRole** über das Instanzprofil **LabInstanceProfile** an `dc-andrija` hängen → die AWS CLI erhält automatisch temporäre Credentials (sicherer als statische Access Keys, nichts muss gespeichert werden). In einem normalen Account: IAM-User `BackupAdmin`, programmatischer Zugriff, Policy idealerweise nur auf diesen Bucket statt AmazonS3FullAccess.
- `C:\CompanyArchive\` mit Testdateien.
- AWS CLI MSI installieren (`msiexec /i https://awscli.amazonaws.com/AWSCLIV2.msi /qn`), `aws configure` → nur Region `us-east-1` (Keys entfallen dank Instanzrolle).

## Teil A

```powershell
aws s3 ls                                            # Bucket-Liste = Verbindung ok
.\12b-Sync-ToCloud.ps1                                # aws s3 sync C:\CompanyArchive s3://…/CompanyArchive
```
Aufgabenplanung: Aufgabe `M159-S3-Backup`, Trigger alle 15 Minuten, Aktion `powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\12b-Sync-ToCloud.ps1`, als SYSTEM, „Unabhängig von der Benutzeranmeldung ausführen“ (siehe Skript, Parameter `-Registrieren`).

## Teil B – Disaster Recovery

```powershell
Remove-Item C:\CompanyArchive\Rechnung_2026.txt
.\12b-Restore-FromCloud.ps1 -Datei Rechnung_2026.txt    # aws s3 cp s3://…/CompanyArchive/Rechnung_2026.txt C:\CompanyArchive\
```

## Block- vs. Object-Storage

NTFS (Block-Storage auf EBS) verwaltet Dateien in einer Ordnerhierarchie mit ACLs, wird vom OS als Laufwerk eingebunden und erlaubt Teil-Änderungen. S3 (Object-Storage) speichert ganze Objekte mit Key + Metadaten in einem flachen Namensraum, Zugriff per HTTPS-API, nahezu unbegrenzt skalierbar und günstig – ideal für Backups/Archive, nicht für Live-Dateizugriff.

## Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Gefüllter Bucket in der Konsole | `images/12b-bucket.png` | ⏳ |
| Task Scheduler Job | `images/12b-task.png` | ⏳ |
| Restore-Test | `images/12b-restore.png` | ⏳ |
