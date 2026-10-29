# Auftrag 08 – Nachweis (Umsetzung 27.10.2026)

Ausgeführt mit `08-ldap-suche.ps1 -Teil Suchen | Tests | Dienstkonto | GPO` (Get-ADObject -LDAPFilter = dieselbe LDAP-Abfrage wie ldp.exe → Browse → Search). Echte Ausgaben:

## Teil 2

```text
### 2.1 Promoter ueber Anmeldenamen
Filter: (&(objectCategory=person)(objectClass=user)(sAMAccountName=proth))
Base: DC=ec2,DC=andrija,DC=m159 Scope: Subtree
Treffer: 1
  - CN=Paul Roth,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159

### 2.2 Benutzer Buchhaltung (OneLevel)
Base: OU=Buchhaltung,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159 Scope: OneLevel
Treffer: 0

### 2.2 Benutzer Buchhaltung (Subtree)
Treffer: 1
  - CN=Beat Huber,OU=Buchhaltung_Benutzer,OU=Buchhaltung,OU=Intern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159

### 2.3 Alle Gruppen der Domain
Filter: (objectClass=group)   Treffer: 64   (Builtin + Users-Container + 13 eigene Gruppen)
DN der Gruppe extern: CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
```

## Teil 3

```text
### 3.1 Direkte Mitglieder von G_Promoter
Filter: (&(objectCategory=person)(objectClass=user)(memberOf=CN=G_Promoter,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159))
Treffer: 1  - CN=Paul Roth,...

### 3.2a naiv: memberOf=G_Extern
Filter: (&(objectCategory=person)(objectClass=user)(memberOf=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159))
Treffer: 0

### 3.2b korrigiert: IN_CHAIN G_Extern
Filter: (&(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159))
Treffer: 1  - CN=Paul Roth,...

### 3.3 FIREWALL-FILTER: extern + aktiv
Filter: (&(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
Treffer: 1  - CN=Paul Roth,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
```

## Tests

```text
== Test 1: Promoter deaktivieren
### nach Disable   Treffer: 0
### nach Enable    Treffer: 1  - CN=Paul Roth,...

== Test 2: zweite externe Abteilung (G_Externe_Berater in G_Extern, Benutzer tberater)
### mit Externe Berater (Filter unveraendert)  Treffer: 2
  - CN=Paul Roth,...
  - CN=Test Berater,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
### nach Aufraeumen  Treffer: 1
```

## Dienstkonto

```text
DistinguishedName    : CN=svc_fw_ldap,OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159
Enabled              : True
PasswordNeverExpires : True
Description          : Bind-Konto Firewall VPN (nur lesen)
MemberOf             : {}        (nur primäre Gruppe Domänen-Benutzer → Standard-Leserechte)
```

## Teil 4 – GPO mit LDAP-Zielgruppe

`U_Andrija_AG_Verknuepfung_VPN` angelegt und auf `OU=Andrija_AG` verknüpft (siehe Nachweis 07). Die Wirkung (Verknüpfung bei proth, nicht bei skeller) wird mit `gpresult /r /scope user` nach einer interaktiven Anmeldung belegt → offen, siehe Nachweis 07 „Noch offen“.

## ldp.exe

Erledigt am 29.10.2026 (Connect, Bind, Tree und Search mit Subtree in einer echten Sitzung auf dem DC): [GUI-Nachweise](../GUI-Nachweise.md#auftrag-08--ldpexe)

![ldp Ergebnis](../../images/08-ldp-suche-ergebnis.png)


## GUI-Nachweise
gpresult skeller/proth als Bildschirmfoto: [GUI-Nachweise](../GUI-Nachweise.md#auftrag-08--gpresult-gpo-filterung)
