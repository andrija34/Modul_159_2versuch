# Auftrag 04 – Nachweis (Umsetzung 27.10.2026)

Skripte: `04-benutzer-gruppen.ps1`, `04-freigaben-ntfs.ps1 -Phase Matrix`, danach `-Phase AGDLP` (Korrektur in `10-dc-nachtrag.ps1`). Tests mit `12-nachweis-client.ps1`.

## Benutzer und Gruppen

```text
skeller  Sekretariat  CN=Sandra Keller,OU=Sekretariat_Benutzer,OU=Sekretariat,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
bhuber   Buchhaltung  CN=Beat Huber,OU=Buchhaltung_Benutzer,OU=Buchhaltung,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
glang    GL           CN=Gabriel Lang,OU=GL_Benutzer,OU=GL,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
proth    Promoter     CN=Paul Roth,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159

Gruppe               Bereich      Mitglieder
G_Sekretariat        Global       Sandra Keller
G_Buchhaltung        Global       Beat Huber
G_GL                 Global       Gabriel Lang
G_Promoter           Global       Paul Roth
G_Intern             Global       G_Sekretariat, G_Buchhaltung, G_GL
G_Extern             Global       G_Promoter
DL_FS_Sekretariat_C  DomainLocal  G_GL, G_Sekretariat
DL_FS_Sekretariat_R  DomainLocal  G_Promoter
DL_FS_Buchhaltung_C  DomainLocal  G_GL, G_Buchhaltung
DL_FS_Buchhaltung_R  DomainLocal  G_Promoter, G_Sekretariat
```

## Freigaben (Jeder = Ändern) + ABE

```text
Abteilungen  C:\Daten\Abteilungen  ABE=AccessBased   Everyone Allow Change
Daten        C:\Daten              ABE=AccessBased   Everyone Allow Change
Extern       C:\Daten\Extern       ABE=AccessBased   Everyone Allow Change
Intern       C:\Daten\Intern       ABE=AccessBased   Everyone Allow Change
Pool         C:\Daten\Pool         ABE=AccessBased   Everyone Allow Change
```

## NTFS (icacls, Vererbung aus, „Benutzer“/„Domänen-Benutzer“ entfernt)

```text
C:\Daten\Pool         EC2\G_Sekretariat:(OI)(CI)(M) EC2\G_Promoter:(OI)(CI)(M) EC2\G_GL:(OI)(CI)(M) EC2\G_Buchhaltung:(OI)(CI)(M) SYSTEM:(F) Administrators:(F)
C:\Daten\Abteilungen  EC2\G_Sekretariat:(RX) EC2\G_Promoter:(RX) EC2\G_GL:(M) EC2\G_Buchhaltung:(RX) SYSTEM:(F) Administrators:(F)
...\Abteilungen\GL        EC2\G_GL:(M)
...\Abteilungen\Promoter  EC2\G_Promoter:(M) EC2\G_GL:(M)
C:\Daten\Intern       EC2\G_GL:(M) EC2\G_Intern:(M)
C:\Daten\Extern       EC2\G_Extern:(M) EC2\G_GL:(M)
```

Nach dem AGDLP-Umbau (Sekretariat + Buchhaltung):
```text
C:\Daten\Abteilungen\Sekretariat  EC2\DL_FS_Sekretariat_C:(OI)(CI)(M)  EC2\DL_FS_Sekretariat_R:(OI)(CI)(RX)  SYSTEM:(F)  Administrators:(F)
C:\Daten\Abteilungen\Buchhaltung  EC2\DL_FS_Buchhaltung_C:(OI)(CI)(M)  EC2\DL_FS_Buchhaltung_R:(OI)(CI)(RX)  SYSTEM:(F)  Administrators:(F)
```
Fehleranalyse: Im ersten Lauf standen die globalen Gruppen zusätzlich noch direkt in der ACL (`icacls /grant:r` ersetzt nur Einträge desselben Prinzipals). Korrigiert mit `icacls /remove:g`; jetzt stehen nur noch die DL-Gruppen in der ACL.

## Berechtigungstests (echter SMB-Zugriff mit dem jeweiligen Benutzerkonto vom Client aus)

```text
skeller  \\dc-andrija.ec2.andrija.m159\Abteilungen\Buchhaltung  Lesen=JA   Schreiben=NEIN
glang    \\dc-andrija.ec2.andrija.m159\Pool                     Lesen=JA   Schreiben=JA
proth    \\dc-andrija.ec2.andrija.m159\Intern                   Lesen=NEIN Schreiben=NEIN   (Zugriff verweigert)
proth    \\dc-andrija.ec2.andrija.m159\Abteilungen              sichtbare Ordner: Buchhaltung,Promoter,Sekretariat   (ABE: GL ausgeblendet)
skeller  \\dc-andrija.ec2.andrija.m159\Abteilungen              sichtbare Ordner: Buchhaltung,Sekretariat            (ABE: GL + Promoter ausgeblendet)
bhuber   \\dc-andrija.ec2.andrija.m159\Abteilungen\Buchhaltung  Lesen=JA   Schreiben=JA
```
Alle Ergebnisse entsprechen der Matrix bzw. dem AGDLP-Konzept. Die ABE-Zeilen zeigen, dass jeder Benutzer nur die Ordner sieht, auf die er Leserecht hat.

Fehleranalyse Testskript: Beim ersten Testlauf meldete der Schreibtest überall „NEIN“. Ursache war nicht die Berechtigung, sondern ein Pfadfehler des PowerShell-PSDrive unter dem SYSTEM-Konto (`DirectoryNotFoundException …\Pool\…\Pool\…`). Schreiben per `[IO.File]` direkt auf den UNC-Pfad behebt das.
