# Auftrag 05 – Variante B: Moderner IdP mit Authentik

Wird umgesetzt, falls AWS Managed AD im Learner Lab nicht verfügbar oder zu teuer ist.

## Teil A – Authentik bereitstellen

| Wert | Planung |
|---|---|
| Instanz | `idp-andrija`, Ubuntu Server 24.04, **t3.medium** (Authentik braucht ≥ 2 GB RAM) |
| Netz | m159-public-1a, 10.0.0.40, gleiche VPC wie der DC |
| SG `m159-sg-idp` | 22/TCP + 9443/TCP nur von MEINE-IP/32; Outbound zum DC 389/636 |
| SG `m159-sg-dc` zusätzlich | 389 + 636/TCP von 10.0.0.40/32 |

Warum gleiche VPC: Authentik muss den DC über die private IP per LDAP/LDAPS erreichen; LDAP darf nie ins Internet.

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-v2
mkdir ~/authentik && cd ~/authentik
wget https://goauthentik.io/docker-compose.yml
echo "PG_PASS=$(openssl rand -base64 36 | tr -d '\n')" >> .env
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')" >> .env
sudo docker compose pull && sudo docker compose up -d
# Ersteinrichtung: https://<public-ip>:9443/if/flow/initial-setup/  (akadmin-Passwort -> Secrets)
```

## Teil B – LDAP Source

- Bind-Konto `svc_authentik_ldap` in `OU=Dienstkonten` (nur Domänen-Benutzer = Leserechte, kein Admin; Least Privilege, da das Passwort in Authentik gespeichert ist).
- Directory → Federation & Social login → **LDAP Source**: Server URI `ldap://10.0.0.10` (später `ldaps://dc-andrija.ec2.andrija.m159`), Bind CN `CN=svc_authentik_ldap,OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159`, Base DN `OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159`, User object filter `(objectClass=user)`, Group object filter `(objectClass=group)`, Property mappings „authentik default LDAP Mapping …“ + „Active Directory Mapping“.
- Sync auslösen → Benutzer skeller, bhuber, glang, proth und Gruppen G_* erscheinen unter Directory → Users/Groups.
- Login-Test mit `skeller` (Passwort wird per LDAP-Bind gegen den DC geprüft).

## Teil C – LDAPS

Auf dem DC Zertifikat bereitstellen (AD CS „Enterprise CA“ installieren → DC erhält automatisch ein Domain-Controller-Zertifikat; LDAPS auf 636 aktiv). Root-CA in Authentik unter System → Certificates importieren und in der LDAP Source als Verification Certificate wählen; URI `ldaps://dc-andrija.ec2.andrija.m159:636`.
Ab Windows Server 2025 ist LDAP-Signing standardmässig erzwungen: unsignierte Simple Binds über 389 werden abgelehnt → LDAPS (oder StartTLS) ist Pflicht. Passwort-Rückschreiben ins AD geht nur verschlüsselt.

## Teil D – App per OIDC

Applications → Create with provider → **OAuth2/OIDC** z. B. für eine Test-App (Grafana oder `oauth2-proxy`/whoami-Container). Policy-Binding: Gruppe `G_Intern` → nur interne Benutzer erhalten Zugriff; Test mit `proth` (extern) → „Access denied“.

## Abgrenzung

| | AD-Forest-Trust (A) | Authentik-Föderation (B) |
|---|---|---|
| Zwischen | zwei ADs | AD (Quelle) und Web-IdP |
| Protokoll | Kerberos/NTLM | LDAP (Sync) + OIDC/SAML (App) |
| Richtung | zweiseitig möglich | einseitig, Authentik liest aus dem AD |
| Wer vertraut wem | Domäne ↔ Domäne | App vertraut dem IdP |

## Fragenkatalog Variante B

1. **AD bleibt führend**, weil Authentik nur aus dem AD synchronisiert und Passwörter per Bind am DC prüft; neue Benutzer werden im AD angelegt.
2. **Login technisch:** Authentik führt einen LDAP-Bind mit den eingegebenen Daten gegen den DC aus; nur bei Erfolg ist der Login gültig.
3. **LDAP vs. LDAPS:** LDAP überträgt den Bind (inkl. Passwort) im Klartext auf 389; LDAPS kapselt alles in TLS auf 636 mit Serverzertifikat – nötig, damit niemand mitlesen kann und für Passwort-Rückschreiben.
4. **Kein Trust**, weil Authentik kein AD/KDC ist; es bindet sich einseitig per LDAP an und föderiert Apps per Token.
5. **Authentifizierung** = Login gegen das AD; **Autorisierung** = Policy-Binding auf G_Intern entscheidet, ob die App sichtbar ist.
6. **Dediziertes Bind-Konto**, weil dessen Passwort in Authentik liegt; mit Adminrechten wäre ein Leak fatal – es braucht nur Lesen.
7. **Base DN** = Startpunkt der Synchronisation; zu hoch → Systemkonten/fremde Objekte, zu tief → Benutzer fehlen. Gewählt: `OU=Andrija_AG`.
8. **OIDC:** Redirect zum IdP → Login → Authorization Code zurück an die Callback-URL → App tauscht Code gegen ID-/Access-Token und vertraut dessen Signatur; das Passwort sieht die App nie.
9. **LDAP-Signing ab Server 2025:** unsignierte Binds werden abgelehnt; deshalb LDAPS mit Zertifikat.
10. **Reale Situation:** Moderne SaaS-/Web-Apps sprechen OIDC/SAML statt Kerberos/LDAP; ein IdP liefert zentral SSO, MFA und einheitliche Zugriffsregeln.
