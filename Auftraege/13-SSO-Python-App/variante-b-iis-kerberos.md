# Auftrag 13 – Variante B: SSO mit IIS & Kerberos

Skript: [`13b-iis-kerberos.ps1`](../../scripts/13b-iis-kerberos.ps1)

## Vorbereitung (auf dc-andrija)

```powershell
Install-WindowsFeature Web-Server, Web-Windows-Auth -IncludeManagementTools
Set-Content C:\inetpub\wwwroot\index.html '<h1>Willkommen im geschützten Intranet der Andrija AG!</h1>' -Encoding UTF8
```
IIS-Manager → Default Web Site → Authentifizierung: **Anonym = Deaktiviert**, **Windows-Authentifizierung = Aktiviert** (Anbieter Negotiate vor NTLM).

## Teil A – Absicherung & Test

1. Client: `http://dc-andrija.ec2.andrija.m159` → Anmeldefenster erscheint.
   **Warum:** Browser senden Windows-Anmeldedaten automatisch nur an Sites der Zone *Lokales Intranet*. Ein FQDN mit Punkten wird als *Internet* eingestuft → der Browser fragt nach.
2. GPO `U_Andrija_AG_Intranetzone`: Benutzerkonfiguration → Administrative Vorlagen → Windows-Komponenten → Internet Explorer → Internetsystemsteuerung → Sicherheitsseite → *Liste der Site-zu-Zonen-Zuweisungen*: `http://dc-andrija.ec2.andrija.m159` = **1** (Intranet). Edge/Chrome übernehmen die Zonen.
3. `gpupdate /force`, Browser neu → Seite erscheint ohne Passwortabfrage. `klist` zeigt ein Ticket `HTTP/dc-andrija.ec2.andrija.m159` → Kerberos (nicht NTLM).

## Teil B – Autorisierung

- Gruppe `G_Intranet_Users` (OU=Gruppen), Mitglied skeller.
- IIS → Default Web Site → **.NET-Autorisierungsregeln** bzw. *Autorisierungsregeln* (Feature URL-Autorisierung): „Alle Benutzer zulassen“ entfernen, *Zulassen* Rolle `EC2\G_Intranet_Users`.
- Test mit proth (nicht in der Gruppe) → **401 Unauthorized** (401.2/401.3).

## Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| Seite ohne Anmeldefenster (Client-Browser) | `images/13b-sso.png` | ⏳ |
| IIS-Authentifizierungseinstellungen | `images/13b-auth.png` | ⏳ |
| 401 für nicht berechtigten Benutzer | `images/13b-401.png` | ⏳ |
