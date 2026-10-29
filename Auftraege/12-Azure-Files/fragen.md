# Auftrag 12 – Fragenkatalog (Antworten)

**1. Drei Identity-based-Access-Varianten, warum AD DS?**
AD DS (On-Prem-DC als KDC), Microsoft Entra Domain Services (verwaltete Domäne in Azure), Microsoft Entra Kerberos (Entra stellt Tickets aus). Entra Kerberos geht nur von Windows-Client-OS (mein Client ist ein Server), Entra DS kostet zusätzlich ohne Vorteil – daher AD DS.

**2. Join-AzStorageAccount?**
Registriert den Storage Account als Computerobjekt (mit SPN `cifs/<account>.file.core.windows.net` und Kennwort/Kerberos-Schlüssel) im lokalen AD und hinterlegt die Domäneninfos am Storage Account. Erst dadurch kann der lokale KDC ein Service-Ticket für den Share ausstellen.

**3. Port und Test?**
SMB über **TCP 445**; Test: `Test-NetConnection -ComputerName andrijam159files.file.core.windows.net -Port 445` → `TcpTestSucceeded : True`.

**4. GPO Host-zu-Realm-Mapping?**
Ordnet den Hostnamen `andrijam159files.file.core.windows.net` dem lokalen Realm `EC2.ANDRIJA.M159` zu. Ohne Mapping würde der Client den Realm aus dem Hostnamen/UPN-Suffix ableiten (falscher Realm) und der KDC findet kein passendes Computerkonto → Fallback/Fehler.

**5. Ablauf der Authentifizierung?**
Benutzer ist am Client mit Kerberos-TGT des lokalen DC angemeldet → beim Zugriff fordert der Client beim lokalen KDC ein Service-Ticket für `cifs/andrijam159files.file.core.windows.net` an (Computerobjekt aus Join-AzStorageAccount) → sendet das Ticket per SMB an Azure Files → Azure prüft das Ticket mit dem gemeinsamen Schlüssel, ermittelt über die synchronisierte Identität die RBAC-Rolle → Zugriff ohne Passworteingabe.

**6. Share-Rollen (RBAC) vs. NTFS?**
RBAC-Rollen wirken auf Share-Ebene (darf der Benutzer den Share überhaupt lesen/schreiben), Windows-ACLs (NTFS) innerhalb des Shares auf Ordner/Dateien. Beide werden ausgewertet, die restriktivere gewinnt – wie Freigabe- und NTFS-Rechte on-prem.

**7. Rollen Sekretariat/Buchhaltung?**
Sekretariat: *Storage File Data SMB Share Reader* (nur lesen). Buchhaltung: *Storage File Data SMB Share Contributor* (lesen, schreiben, löschen). Zuweisung nach Bedarf, Least Privilege.

**8. Test Read/Write?**
Aktiver Zugriffstest: als skeller lesen OK, `New-Item` → „Zugriff verweigert“; als bhuber Datei anlegen OK. Zusätzlich `klist` zeigt das cifs-Ticket. Die Rollenanzeige im Portal allein beweist nichts.

**9. Warum Entra Kerberos ungeeignet?**
Der Zugriff mit Entra Kerberos ist nur von Windows-Client-Betriebssystemen (Win10/11) möglich; mein Client ist ein Windows Server (AWS bietet keine Client-AMIs).

**10. Reale Situation für Azure Files?**
Firma ohne eigenen Serverraum/Backup-Infrastruktur, mehrere Standorte und Homeoffice, will den alten Fileserver ablösen: kein Hardware-/Patch-Aufwand, skalierbar, Snapshots/Backup als Dienst, in die bestehende Hybrid-Identität integriert (gleiche AD-Gruppen/NTFS).
