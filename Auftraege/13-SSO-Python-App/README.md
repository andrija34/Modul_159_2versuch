# Auftrag 13 – SSO Python App (Entra ID / OIDC)

Fragen: [fragen.md](fragen.md) · Alternative: [variante-b-iis-kerberos.md](variante-b-iis-kerberos.md) · App: [sso-python-app/](sso-python-app/)

> Wichtig: SSO lässt sich mit Screenshots schlecht belegen → für die SSO-Tests wird ein **Video** aufgenommen, in dem kein Passwort-Prompt erscheint.

## 1. App starten (auf client-andrija)

```powershell
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.12.1/python-3.12.1-amd64.exe" -OutFile "python-installer.exe"
Start-Process -FilePath ".\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
# neue PowerShell
python --version
cd C:\sso-python-app
python -m venv venv
venv\Scripts\Activate
pip install -r requirements.txt
copy .env.example .env   # Werte eintragen (siehe 2.)
python app.py            # bzw. $env:FLASK_APP='app.py'; flask run
```
App läuft auf **http://localhost:5000**. Änderung an der Vorlage: `load_dotenv()` ergänzt, weil die `.env` sonst nur bei `flask run` geladen wird; `secret_key` aus der Umgebung. Funktionstest der Weiterleitung (ohne echte IDs): `GET /` → 302 auf `login.microsoftonline.com/…/authorize?…redirect_uri=http://localhost:5000/callback&scope=User.Read` ✔.

## 2. App-Registrierung in Entra ID

1. Entra Admin Center → App-Registrierungen → Neu: Name `M159-SSO-Andrija`, *Nur Konten in diesem Organisationsverzeichnis*, Umleitungs-URI **Web** `http://localhost:5000/callback`.
2. Zertifikate & Geheimnisse → Neuer geheimer Clientschlüssel (Ablauf 3 Monate) → **Value sofort** in die Secrets-Ablage/`.env` (später nicht mehr lesbar).
3. `.env`: `CLIENT_ID` (Anwendungs-ID), `CLIENT_SECRET`, `TENANT_ID` (Verzeichnis-ID). `.env` ist per `.gitignore` ausgeschlossen – im Repo liegt nur `.env.example`.

## 3. Login-Tests

| Test | Ablauf | Erwartung | Nachweis |
|---|---|---|---|
| A – Chrome Inkognito, manuell | `http://localhost:5000` (nicht 127.0.0.1 → sonst *AADSTS50011 Redirect URI mismatch*) → Benutzername + Passwort → Berechtigung *User.Read* akzeptieren | Profilseite „Login erfolgreich!“ mit Graph-Daten | Screenshots `13-a-*.png` |
| B – Chrome, token-basiertes SSO | Auf einem Gerät **ohne** Domänen-/Entra-Mitgliedschaft (z. B. mein Laptop) zuerst bei `https://m365.cloud.microsoft/` mit einem Entra-Benutzer anmelden, dann App öffnen | Kein Passwort-Prompt – Session-Cookie von login.microsoftonline.com wird wiederverwendet | Video `13-b.mp4` |
| C – Edge, Kerberos/WIA bzw. PRT-SSO | Am hybrid-joined Client als synchronisierter Benutzer mit öffentlichem UPN (`…@andrija-m159.v6.rocks`) anmelden, Edge öffnen, App aufrufen | Kein Prompt – Edge nutzt die Windows-Anmeldung (PRT) | Video `13-c.mp4` |

Für Test B läuft die App auf dem Laptop selbst (gleiche Redirect-URI `localhost`).

## 4. Nachweise

Erledigt am 28.10.2026: [nachweis-variante-a.md](nachweis-variante-a.md) (App-Registrierung, Secret geschwärzt, Consent, Login erfolgreich, SSO ohne Kennwort). Test C entfällt, weil 10A (Entra Connect) mit Variante B umgesetzt wurde.
