# M159 – Einstiegsfragen (Antworten)

**Aus technischer Sicht ist ein Verzeichnisdienst nichts anderes als …**
… eine hierarchisch strukturierte, für Lesezugriffe optimierte Datenbank, die Informationen über Objekte (Benutzer, Computer, Ressourcen) zentral speichert und über ein Netzwerkprotokoll (LDAP) bereitstellt.

**4 Kernaufgaben eines Directory Service**
1. Zentrale Identitätsverwaltung (Benutzer, Gruppen, Computer)
2. Authentifizierung (Wer bist du? – Kerberos/NTLM)
3. Autorisierung / Zugriffssteuerung auf Ressourcen
4. Auffinden von Ressourcen (Suchen, Namensauflösung) und zentrale Konfiguration (GPOs)

**5 Objekte im Directory**
Benutzer, Gruppen, Computer, Drucker, freigegebene Ordner (+ OUs, Kontakte, Dienstkonten).

**5 Merkmale eines Directory Service**
Hierarchische Struktur (Baum), zentrale Datenhaltung, Replikation auf mehrere Server (verteilt, ausfallsicher), standardisiertes Zugriffsprotokoll (LDAP), Schema (definierte Objektklassen und Attribute), feingranulare Berechtigungen, leseoptimiert, skalierbar.

**Objekt, Attribut, Wert – korrekte Antworten**
- ☐ Benutzerattribute sind Eigenschaften von Computern – *falsch*
- ☑ Benutzerattribute haben einen Namen und einen Wert
- ☑ Das Benutzerpasswortattribut bestehend aus Namen und Wert ist ein Benutzerattribut
- ☑ Der Vorname ist ein Benutzerattribut
- ☐ Druckerobjekte haben keine Attribute – *falsch*

**Was ist eine Objektklasse?**
Eine im Schema definierte Vorlage, die festlegt, welche Attribute ein Objekt haben muss (mustContain) und kann (mayContain) – z. B. `user`, `group`, `computer`, `organizationalUnit`. Jedes Objekt ist eine Instanz einer Klasse.

**Zwei Nachteile**
Komplexität/Know-how-Bedarf bei Planung und Betrieb; zentraler Single Point of Failure/hochwertiges Angriffsziel (fällt er aus oder wird kompromittiert, betrifft es alles) – plus Kosten für Lizenzen/Server.

**IT-Situation, die einen Directory Service verlangt**
Ein KMU mit 80 Mitarbeitenden, 3 Standorten, Fileserver und Druckern: zentrale Konten, Single Sign-On, Berechtigungen über Gruppen, GPOs für einheitliche Konfiguration.

**IT-Situation ohne Directory Service**
Ein Einzelunternehmen mit zwei Laptops und Cloud-Diensten (lokale Konten genügen).

**Lokaler Administrator**
Konto in der lokalen SAM-Datenbank eines Rechners mit vollen Rechten nur auf diesem einen Gerät.

**Domänenadministrator**
Konto im AD (Mitglied „Domänen-Admins“) mit vollen Rechten auf allen DCs und – über die lokale Admin-Gruppe – auf allen Domänenmitgliedern.

**Aufgaben des Domänencontrollers**
Speichert und repliziert die AD-Datenbank (NTDS.dit), authentifiziert Benutzer/Computer (KDC für Kerberos), wendet Sicherheitsrichtlinien an, stellt SYSVOL/GPOs und meist DNS bereit, beantwortet LDAP-Abfragen.

**DC** = Domain Controller (Domänencontroller). **OU / OE** = Organizational Unit / Organisationseinheit.

**On-Premises** = Die IT läuft auf eigener Hardware in eigenen Räumen bzw. eigener Verantwortung (Gegenteil: Cloud/SaaS).

**MS AD DS vs. Entra ID**
AD DS: On-Prem-Verzeichnis, hierarchisch (OUs), Kerberos/NTLM/LDAP, GPOs, Domänen-Join. Entra ID: Cloud-Identitätsdienst (IDaaS), flach, Web-Protokolle (OIDC, OAuth 2.0, SAML), Conditional Access/MFA, Geräte über Intune, keine GPOs/LDAP/Kerberos im klassischen Sinn.

**Intune, MDM & MAM**
Intune ist Microsofts Cloud-Dienst für Endpoint-Management. MDM (Mobile Device Management) verwaltet das ganze Gerät (Richtlinien, Apps, Wipe). MAM (Mobile Application Management) schützt nur Firmen-Apps und -Daten (z. B. auf privaten Geräten, BYOD), ohne das Gerät zu verwalten.

**Tenant** = Eine eigene, isolierte Instanz von Entra ID/Microsoft 365 einer Organisation mit eigener Tenant-ID, Benutzern, Domains und Einstellungen.

**AD-Umgebung mit Entra-ID-Integration** = **Hybride Identität** (Hybrid-Umgebung, z. B. mit Entra Connect und Hybrid Join).
