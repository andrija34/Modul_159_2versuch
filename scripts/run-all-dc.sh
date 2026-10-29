#!/bin/bash
# Reihenfolge der Auftraege 03-09 per SSM (in CloudShell nach "source scripts/m159.sh")

rl 04-benutzer   runps dc-andrija 04-benutzer-gruppen.ps1
rl 03-rdp-dc     runps dc-andrija 03-rdp-konzept.ps1 -Teil DC
rl 03-rdp-client runps client-andrija 03-rdp-konzept.ps1 -Teil Client
rl 04-matrix     runps dc-andrija 04-freigaben-ntfs.ps1 -Phase Matrix
rl 07-dit        runps dc-andrija 07-dit.ps1
rl 04-agdlp      runps dc-andrija 04-freigaben-ntfs.ps1 -Phase AGDLP
rl 07-gpos       runps dc-andrija 07-gpos.ps1
rl 08-dienstkonto runps dc-andrija 08-ldap-suche.ps1 -Teil Dienstkonto
rl 08-suchen     runps dc-andrija 08-ldap-suche.ps1 -Teil Suchen
rl 08-tests      runps dc-andrija 08-ldap-suche.ps1 -Teil Tests
rl 08-gpo        runps dc-andrija 08-ldap-suche.ps1 -Teil GPO
rl 09-vorb       runps dc-andrija 09-vorbereitung.ps1
rl 09-original runps dc-andrija 09-import-users-original.ps1
rl 09-lauf1      runps dc-andrija 09-import-users.ps1
rl 09-lauf2      runps dc-andrija 09-import-users.ps1
# Nachtrag + Nachweise
rl 10-nachtrag   runps dc-andrija 10-dc-nachtrag.ps1
rl 11-nachweis-dc runps dc-andrija 11-nachweis-dc.ps1
rl 12-nachweis-cl runps client-andrija 12-nachweis-client.ps1
