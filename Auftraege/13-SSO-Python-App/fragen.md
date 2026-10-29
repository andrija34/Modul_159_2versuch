# Auftrag 13 – Fragenkatalog (Antworten)

**1. OIDC-Ablauf Schritt für Schritt?**
(1) Browser ruft `http://localhost:5000/` auf → (2) App leitet mit `client_id`, `redirect_uri`, `scope`, `state` zu `login.microsoftonline.com/<tenant>/oauth2/v2.0/authorize` weiter → (3) Benutzer meldet sich bei Entra ID an (oder SSO) und stimmt zu → (4) Entra leitet zur Callback-URL `/callback?code=…&state=…` zurück → (5) App tauscht den Code mit Client-ID + Secret am Token-Endpunkt gegen Access-/ID-Token → (6) App ruft mit dem Access-Token Microsoft Graph `/me` auf und zeigt das Profil. Das Passwort sieht die App nie.

**2. Client ID, Client Secret, Tenant ID?**
Tenant-ID benennt das Verzeichnis (welcher Entra-Tenant), Client-ID identifiziert die App, das Client Secret authentifiziert die App beim Token-Tausch. Geheim ist nur das Secret → gehört in `.env` bzw. Key Vault, nie in Code/Repo.

**3. Warum 127.0.0.1 → Redirect-URI-Mismatch?**
Entra vergleicht die übergebene Redirect-URI exakt (String-Vergleich) mit der registrierten. `http://127.0.0.1:5000/callback` ≠ `http://localhost:5000/callback` → Fehler AADSTS50011.

**4. Unterschied der drei Login-Tests?**
Manuell: Passwort (+ ggf. MFA) wird eingegeben. Token-basiert: Browser hat bereits eine Entra-Session (Cookie von der M365-Anmeldung) → kein Passwort. Kerberos/WIA bzw. PRT: Domänen-/hybrid-joined Gerät, der Browser verwendet die Windows-Anmeldung (Kerberos-Ticket bzw. Primary Refresh Token) → kein Prompt, ohne vorherige Web-Anmeldung.

**5. Redirect-/Callback-URI, warum sicherheitsrelevant?**
Adresse, an die der IdP nach dem Login Code/Token schickt. Nur registrierte URIs sind erlaubt – sonst könnte ein Angreifer eine eigene Rücksprungadresse unterschieben und Codes/Tokens abgreifen (Token-Diebstahl, Kontoübernahme).

**6. Warum Secret nicht ins Repo, wie geschützt?**
Mit dem Secret kann sich jeder als die App ausgeben und Tokens anfordern; im (öffentlichen) Repo wäre es für alle lesbar und bliebe in der Git-Historie. Schutz: nur in `.env`, `.env` in `.gitignore`, im Repo nur `.env.example`; Secret mit kurzer Laufzeit, bei Leak sofort widerrufen.

**7. Was erhält die App nach dem Login?**
Einen Authorization Code, den sie gegen ein ID-Token (Claims zur Identität: name, oid, preferred_username, tid) und ein Access-Token (für Graph, Scope User.Read) tauscht. Sie vertraut der Signatur des IdP und prüft keine Passwörter selbst.

**8. OIDC/OAuth vs. Kerberos-SSO?**
OIDC: token-basiert, über HTTPS/Redirects mit einem IdP, funktioniert im Internet und über Organisationsgrenzen. Kerberos: ticket-basiert, im AD/LAN über den KDC (Port 88), braucht Sichtverbindung zum DC und Domänenmitgliedschaft. Beide erreichen SSO, auf unterschiedlichen Wegen.

**9. Warum WIA-SSO nur bei domain-/hybrid-joined Client mit öffentlichem UPN?**
WIA nutzt die bestehende Windows-Anmeldung. Ohne Join gibt es keine Kerberos-/PRT-Identität, die der Browser senden kann. Und der Benutzer muss in Entra unter dem öffentlichen UPN existieren, damit die Windows-Identität dem Cloud-Konto zugeordnet werden kann (mit `@ec2.andrija.m159` gäbe es keine Zuordnung).

**10. Reale Situation für IdP-Anbindung?**
Eine Firma entwickelt ein internes Webportal: statt eigener Benutzerverwaltung (Passwort-Hashing, Reset, MFA) übernimmt Entra ID den Login. Vorteile: zentrales SSO, MFA/Conditional Access, Konten werden mit dem Austritt automatisch gesperrt, keine Passwörter in der App.
