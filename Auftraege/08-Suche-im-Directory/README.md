# Auftrag 08 – Suche im Directory

Fragen: [fragen.md](fragen.md) · Skript: [`08-ldap-suche.ps1`](../../scripts/08-ldap-suche.ps1) · Abgabe Teil 5: [konfigurationsblatt.md](konfigurationsblatt.md)

Die Spalte „erwartet“ ist aus meiner Struktur hergeleitet; „Ist“ wird mit der Ausgabe von `08-ldap-suche.ps1` und Screenshots belegt.

## Teil 1 – Bind und Base-DN (ldp.exe)

1. Connection → Connect → `dc-andrija.ec2.andrija.m159`, Port **389**.
2. Connection → Bind → *Bind as currently logged on user* → `Authenticated as: 'EC2\Administrator'`.
3. View → Tree → Base-DN `DC=ec2,DC=andrija,DC=m159` → bis zu proth durchklicken.

- **Base-DN:** Domainname an den Punkten zerlegen, jeder Teil wird eine `DC=`-Komponente: `ec2.andrija.m159` → `DC=ec2,DC=andrija,DC=m159`.
- **Bind:** Anmeldung am Verzeichnis mit einer Identität (hier Kerberos/NTLM als angemeldeter Benutzer). Erst danach entscheidet der DC anhand der ACLs, welche Objekte/Attribute sichtbar sind. Ohne Bind wäre die Sitzung anonym – AD erlaubt anonym nur das Lesen des RootDSE, Suchen schlagen mit „Operations error / successful bind must be completed“ fehl.
- **DN eines Promoters:** `CN=Paul Roth,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159`

## Teil 2 – Drei Suchen

| # | Gesucht | Filter | Base / Scope | erwartet | Ist |
|---|---|---|---|---|---|
| 2.1 | Promoter über Anmeldenamen (ldp + PowerShell) | `(&(objectCategory=person)(objectClass=user)(sAMAccountName=proth))` | Domäne / Subtree | 1 | ⏳ |
| 2.2 | Benutzer Buchhaltung | `(&(objectCategory=person)(objectClass=user))` | `OU=Buchhaltung,OU=Intern,OU=Andrija_AG,…` / **One Level** | 0 | ⏳ |
| 2.2 | dito | dito | dito / **Subtree** | 1 (bhuber) | ⏳ |
| 2.3 | Alle Gruppen | `(objectClass=group)` | Domäne / Subtree | ~55 (Builtin + eigene) | ⏳ |

PowerShell 2.1: `Get-ADUser -LDAPFilter '(sAMAccountName=proth)'` – stellt dieselbe LDAP-Abfrage wie ldp.exe unter Browse → Search.

**One Level vs. Subtree:** One Level sucht nur die direkten Kinder der Base. Direkt unter `OU=Buchhaltung` liegen nur die OUs `Buchhaltung_Benutzer` und `Buchhaltung_Computer` – kein Benutzer → 0 Treffer. Subtree durchsucht den ganzen Teilbaum und findet bhuber in `OU=Buchhaltung_Benutzer`.

DN der Gruppe extern (aus 2.3): `CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159`

## Teil 3 – Filter für die Firewall

| # | Gesucht | Filter | erwartet | Ist |
|---|---|---|---|---|
| 3.1 | Direkte Mitglieder G_Promoter | `(&(objectCategory=person)(objectClass=user)(memberOf=CN=G_Promoter,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159))` | 1 | ⏳ |
| 3.2 naiv | memberOf = G_Extern | `(&(objectCategory=person)(objectClass=user)(memberOf=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159))` | **0** | ⏳ |
| 3.2 korrigiert | zu extern gehörend (verschachtelt) | `(&(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159))` | 1 | ⏳ |
| 3.3 | **extern + aktiv (Firewall)** | `(&(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))` | 1 (proth) | ⏳ |

Erklärung 3.3 Klammer für Klammer:
- `(& … )` – UND: alle folgenden Bedingungen müssen gelten (Präfixnotation, Operator vorne).
- `(objectCategory=person)(objectClass=user)` – nur Benutzerkonten (schliesst Computer aus, die auch `objectClass=user` haben).
- `(memberOf:1.2.840.113556.1.4.1941:=…G_Extern…)` – **LDAP_MATCHING_RULE_IN_CHAIN**: Mitgliedschaft über beliebig viele Gruppenebenen (proth → G_Promoter → G_Extern).
- `(!( … ))` – NICHT.
- `(userAccountControl:1.2.840.113556.1.4.803:=2)` – **LDAP_MATCHING_RULE_BIT_AND**: Bit 2 = ACCOUNTDISABLE gesetzt. Negiert → nur aktive Konten.

**Warum der naive Filter 0 liefert:** `memberOf` enthält nur direkte Mitgliedschaften. proth ist Mitglied von G_Promoter; Mitglied von G_Extern ist die Gruppe, nicht der Benutzer.

### Nachweis-Tests

| Test | Erwartung | Ist |
|---|---|---|
| 1: proth deaktivieren | verschwindet (0 Treffer), nach Aktivieren wieder 1 | ⏳ |
| 2: Gruppe `G_Externe_Berater` in G_Extern + Benutzer `tberater` | erscheint ohne Filteränderung (2 Treffer), danach aufgeräumt | ⏳ |

`.\08-ldap-suche.ps1 -Teil Tests`

**Warum extern statt Promoter:** Die Firewall interessiert nicht die Abteilung, sondern ob jemand von aussen arbeiten darf – genau das bildet G_Extern ab. Kommt eine zweite externe Abteilung dazu, wird nur deren Gruppe in G_Extern aufgenommen; Filter und Firewall-Konfiguration bleiben unverändert (Test 2 beweist das).

## Teil 4 – Filter wirksam machen (GPO mit LDAP-Zielgruppe)

GPO `U_Andrija_AG_Verknuepfung_VPN` (verknüpft mit `OU=Andrija_AG`), Desktop-Verknüpfung „VPN-Anleitung“ → `\\dc-andrija…\Extern\VPN-Anleitung.txt`, Register *Gemeinsam* → **Zielgruppenadressierung** → *LDAP-Abfrage*:

```
(&(sAMAccountName=%LogonUser%)(objectCategory=person)(objectClass=user)(memberOf:1.2.840.113556.1.4.1941:=CN=G_Extern,OU=Gruppen,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
```

Wichtige Erkenntnis: ILT „LDAP-Abfrage“ ist erfüllt, sobald die Abfrage **irgendein** Ergebnis liefert. Der reine Firewall-Filter findet immer proth – damit bekäme jeder Benutzer die Verknüpfung. Deshalb wird er mit `(sAMAccountName=%LogonUser%)` auf den angemeldeten Benutzer eingeschränkt.

Nachweis: als **proth** `gpupdate /force` + `gpresult /r /scope user` → Verknüpfung vorhanden; als **skeller** → keine Verknüpfung (Ereignis „Element wurde nicht angewendet, Zielgruppe falsch“).

## Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| ldp.exe Connect/Bind/Tree bis proth | `images/08-ldp-*.png` | ⏳ |
| Suchen 2.1–2.3 (ldp + PowerShell) | `images/08-suche-2-*.png` | ⏳ |
| Filter 3.1, 3.2 naiv/korrigiert, 3.3 | `images/08-filter-3-*.png` | ⏳ |
| Tests 1 + 2 | `images/08-test-*.png` | ⏳ |
| GPO-ILT + gpresult proth/skeller | `images/08-gpo-*.png` | ⏳ |
