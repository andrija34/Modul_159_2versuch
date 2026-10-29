# Auftrag 07 – Fragenkatalog (Antworten)

**1. Was ist ein DIT, warum vorher erstellen?**
Der Directory Information Tree ist die grafische Darstellung des logischen Aufbaus des Verzeichnisses (Domäne → OUs → Objekte). Fehler in der Struktur fallen auf dem Papier auf, statt später OUs mit vielen Objekten, Verknüpfungen und Rechten umbauen zu müssen; zugleich ist er Dokumentation.

**2. DN eines Benutzers, von rechts nach links gelesen?**
`CN=Paul Roth,OU=Promoter_Benutzer,OU=Promoter,OU=Extern,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159` – von rechts: Domänenwurzel m159 → andrija → ec2 (= `ec2.andrija.m159`), darin OU Andrija_AG → Extern → Promoter → Promoter_Benutzer → Objekt „Paul Roth“. Die Schreibweise geht vom Objekt zur Wurzel, der Weg im Baum umgekehrt.

**3. Warum Benutzer und Computer in der untersten Ebene trennen?**
Jede GPO hat zwei Hauptbereiche (Computer- und Benutzerkonfiguration). Getrennte OUs erlauben, GPOs gezielt nur dort zu verknüpfen, wo sie wirken sollen – ohne Filter und mit besserer Übersicht und Performance.

**4. Reihenfolge der GPO-Anwendung?**
LSDOU: **L**okal → **S**tandort → **D**omäne → **O**Us von oben nach unten. Bei Widersprüchen gewinnt die zuletzt angewendete (nächstgelegene) Einstellung. Ausnahmen: *Erzwungen* (Enforced) setzt sich gegen tiefere durch, *Vererbung deaktivieren* blockiert übergeordnete (ausser erzwungene).

**5. Warum Passwortrichtlinie in der Default Domain Policy?**
Kontorichtlinien (Kennwort, Sperrung, Kerberos) für Domänenkonten werden nur aus GPOs auf **Domänenebene** übernommen und vom PDC-Emulator umgesetzt. Auf einer OU würden sie nur lokale Konten der Computer darin betreffen. Ausnahmen pro Gruppe → Fine-Grained Password Policies (PSO).

**6. Sicherheitsfilterung vs. Zielgruppenadressierung?**
Sicherheitsfilterung entscheidet über Berechtigungen (Lesen + Übernehmen), ob die **ganze GPO** für ein Benutzer-/Computerobjekt gilt. Zielgruppenadressierung (ILT) entscheidet innerhalb einer GPO für **einzelne Einstellungen** (nur bei Preferences), z. B. ein Laufwerk nur für eine Gruppe, IP-Bereich oder LDAP-Abfrage.

**7. WMI-Filter und sein Preis?**
Wendet die GPO nur an, wenn eine WQL-Abfrage auf dem Ziel wahr ist (z. B. Betriebssystemversion). Die Abfrage wird bei jeder GPO-Verarbeitung auf jedem Client ausgeführt → kostet Zeit bei Start/Anmeldung, bei tausend Clients spürbar; komplexe Abfragen (Win32_Product) sind besonders teuer.

**8. Eine GPO greift nicht – Vorgehen?**
1. `gpresult /r` (bzw. `/h report.html`) – wird die GPO angewendet oder verweigert (Filter, leer, deaktiviert)?
2. Verknüpfung + Ziel-OU prüfen: Liegt das Objekt wirklich in der OU? Ist der Link aktiviert, Vererbung blockiert?
3. Computer- vs. Benutzerkonfiguration: Ist die GPO an der richtigen OU (Benutzer-Einstellung an Benutzer-OU)?
4. Sicherheitsfilterung/WMI-Filter/Delegierung (Authentifizierte Benutzer Lesen).
5. `gpupdate /force`, Ereignisanzeige *GroupPolicy*-Log, Replikation/SYSVOL.

**9. Computer- oder Benutzerkonfiguration?**
Gilt es für das Gerät, egal wer sich anmeldet (Software, Firewall, Drucker-Treiber) → Computerkonfiguration, GPO an Computer-OU. Gilt es für die Person, egal an welchem Gerät (Laufwerke, Desktop-Links) → Benutzerkonfiguration, GPO an Benutzer-OU.

**10. Warum OU-Struktur nicht nach Organigramm?**
OUs dienen der Administration (Delegation, GPO-Verknüpfung), nicht der Abbildung von Hierarchien. Organigramme ändern sich häufig, jede Umstrukturierung würde OUs, Links und Rechte brechen. Zugehörigkeiten bildet man mit Gruppen ab, Verwaltung mit OUs.
