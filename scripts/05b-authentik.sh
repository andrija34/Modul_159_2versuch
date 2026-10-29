#!/bin/bash
# Auftrag 05 Variante B – Authentik auf idp-andrija (Ubuntu 24.04) per SSM (AWS-RunShellScript, laeuft als root)
# Phase "install": Docker + Authentik; Phase "config": LDAP Source, Sync, OIDC-App, Policy, Tests (alles ueber die API)
set -u
export PATH=$PATH:/snap/bin
PHASE=${1:-install}
REGION=us-east-1
gp() { aws ssm get-parameter --region $REGION --name "$1" --with-decryption --query Parameter.Value --output text; }
cd /opt/authentik 2>/dev/null || { mkdir -p /opt/authentik && cd /opt/authentik; }
if [ "$PHASE" = install ]; then
  command -v aws >/dev/null || snap install aws-cli --classic >/dev/null
  if ! command -v docker >/dev/null; then apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io docker-compose-v2 >/dev/null; fi
  docker --version; docker compose version
  [ -f docker-compose.yml ] || curl -fsSL -o docker-compose.yml https://goauthentik.io/docker-compose.yml
  if [ ! -f .env ]; then
    { echo "PG_PASS=$(openssl rand -hex 24)"
      echo "AUTHENTIK_SECRET_KEY=$(openssl rand -hex 48)"
      echo "AUTHENTIK_BOOTSTRAP_PASSWORD=$(gp /m159/akadmin)"
      echo "AUTHENTIK_BOOTSTRAP_TOKEN=$(gp /m159/ak_token)"
      echo "AUTHENTIK_BOOTSTRAP_EMAIL=akadmin@andrija.m159"
      echo "AUTHENTIK_ERROR_REPORTING__ENABLED=false"; } > .env
    chmod 600 .env
  fi
  # DC-Name aufloesen (Ubuntu nutzt den VPC-DNS, nicht den AD-DNS)
  cat > docker-compose.override.yml <<'Y'
services:
  server:
    extra_hosts: ["dc-andrija.ec2.andrija.m159:10.0.0.10"]
  worker:
    extra_hosts: ["dc-andrija.ec2.andrija.m159:10.0.0.10"]
Y
  docker compose pull -q && docker compose up -d
  for i in $(seq 1 60); do curl -fs http://localhost:9000/-/health/ready/ >/dev/null && break; sleep 10; done
  docker compose ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}'
  echo "Version: $(curl -s -H "Authorization: Bearer $(gp /m159/ak_token)" http://localhost:9000/api/v3/admin/version/ | jq -r .version_current)"
  echo "== LDAPS zum DC (TLS-Handshake, Zertifikat)"
  openssl s_client -connect 10.0.0.10:636 -servername dc-andrija.ec2.andrija.m159 </dev/null 2>/dev/null | openssl x509 -noout -subject -enddate -ext subjectAltName
  exit 0
fi

# ---------------- token ----------------
# Fallback, falls der Bootstrap-Blueprint kein API-Token angelegt hat: Token fuer akadmin direkt per "ak shell" setzen
if [ "$PHASE" = token ]; then
  cat > /opt/authentik/token.py <<'PY'
import os
from authentik.core.models import Token, TokenIntents, User, Group
u, created = User.objects.get_or_create(username="akadmin", defaults=dict(name="authentik Default Admin", email="akadmin@andrija.m159"))
u.set_password(os.environ["AK_PW"]); u.is_active = True; u.save()
g, _ = Group.objects.get_or_create(name="authentik Admins")
g.is_superuser = True; g.save()
g.users.add(u)
t, c = Token.objects.update_or_create(identifier="m159-api-token", defaults=dict(user=u, intent=TokenIntents.INTENT_API, expiring=False, description="M159 Automatisierung"))
t.key = os.environ["AK_TOKEN"]; t.save()
u = User.objects.get(pk=u.pk)
print("akadmin neu:", created, "| Superuser:", u.is_superuser, "| Gruppen:", [x.name for x in u.groups.all()], "| Token:", Token.objects.filter(identifier="m159-api-token").exists())
PY
  docker compose exec -T -e AK_TOKEN="$(gp /m159/ak_token)" -e AK_PW="$(gp /m159/akadmin)" worker ak shell -c "$(cat /opt/authentik/token.py)" 2>&1 | grep -v "^{" | tail -6
  echo "API-Test: $(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $(gp /m159/ak_token)" http://localhost:9000/api/v3/core/users/me/)"
  exit 0
fi

if [ "$PHASE" = debug ]; then
  cat > /opt/authentik/debug.py <<'PY'
from authentik.core.models import User, Group, Token
try:
    from authentik import get_full_version; print("Version:", get_full_version())
except Exception as e: print("Version?", e)
u = User.objects.get(username="akadmin")
print("akadmin is_superuser:", u.is_superuser, "active:", u.is_active, "type:", getattr(u, "type", "?"))
print("Gruppen:", [(g.name, g.is_superuser, g.users.filter(pk=u.pk).exists()) for g in Group.objects.all()])
print("Tokens:", [(t.identifier, t.intent, t.user.username, t.expiring) for t in Token.objects.all()])
print("Benutzer:", [(x.username, x.type, x.is_superuser, [g.name for g in x.groups.all()] if hasattr(x,"groups") else "-") for x in User.objects.all()])
try:
    from authentik.rbac.models import Role
    print("Rollen:", [(r.name, [f.name for f in r._meta.get_fields()][:12]) for r in Role.objects.all()][:5])
except Exception as e: print("Rollen?", e)
ag = Group.objects.get(name="authentik Admins")
print("Admins-Felder:", {f.name: getattr(ag, f.name, None) for f in Group._meta.concrete_fields})
print("Admins-Rollen:", list(ag.roles.all()) if hasattr(ag, "roles") else "-")
PY
  docker compose exec -T worker ak shell -c "$(cat /opt/authentik/debug.py)" 2>&1 | grep -v '^{' | tail -12
  curl -s -H "Authorization: Bearer $(gp /m159/ak_token)" http://localhost:9000/api/v3/core/users/me/ | head -c 400; echo
  docker compose logs server 2>&1 | grep -i -E 'bootstrap|akadmin' | tail -5 | cut -c1-300
  exit 0
fi

if [ "$PHASE" = test ]; then
  TOKEN=$(gp /m159/ak_token); API=http://localhost:9000/api/v3
  j() { curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$@"; }
  echo "== Sync-Status LDAP Source"
  j "$API/sources/ldap/ad-ec2/sync/status/" | jq -c '{is_running, last_sync: (.last_sync // null)}' 2>/dev/null
  echo "== Benutzer aus dem AD (Pfad goauthentik.io/sources/...)"
  j "$API/core/users/?page_size=200" | jq -r '.results[] | select(.path | test("sources")) | "\(.username)\t\(.path)\t\(.groups_obj | map(.name) | join(","))"'
  echo "== Gruppen-Mapping: memberOf der AD-Gruppe mitsynchronisieren (fuer verschachtelte Gruppen G_GL -> G_Intern)"
  GMAP=$(j "$API/propertymappings/source/ldap/?name=M159%20Gruppe%20memberOf" | jq -r '.results[0].pk // empty')
  [ -z "$GMAP" ] && GMAP=$(j -X POST $API/propertymappings/source/ldap/ -d "$(jq -n '{name:"M159 Gruppe memberOf", expression:"mo = ldap.get(\"memberOf\", [])\nif isinstance(mo, str):\n    mo = [mo]\nreturn {\"attributes\": {\"memberOf\": list(mo)}}"}')" | jq -r .pk)
  GM=$(j "$API/sources/ldap/ad-ec2/" | jq -c --arg m "$GMAP" '(.group_property_mappings + [$m]) | unique')
  j -X PATCH $API/sources/ldap/ad-ec2/ -d "{\"group_property_mappings\": $GM}" | jq -c '{group_property_mappings}'
  docker compose -f /opt/authentik/docker-compose.yml -f /opt/authentik/docker-compose.override.yml --project-directory /opt/authentik exec -T worker ak ldap_sync ad-ec2 >/dev/null 2>&1
  for i in $(seq 1 18); do sleep 10; [ "$(j "$API/core/groups/?name=G_GL" | jq -r '.results[0].attributes.memberOf | length')" -gt 0 ] 2>/dev/null && break; done
  j "$API/core/groups/?page_size=100" | jq -r '.results[] | select(.attributes.memberOf != null and (.attributes.memberOf|length) > 0) | "\(.name) -> \(.attributes.memberOf | map(split(",")[0]) | join(", "))"'
  echo "== Gruppe G_Intern (AD-Attribute)"
  j "$API/core/groups/?name=G_Intern&include_users=true" | jq -c '.results[0] | {name, users: (.users_obj // [] | map(.username)), dn: .attributes.distinguishedName, member: .attributes.member}'
  echo "== Expression Policy: Mitglied (auch verschachtelt) von G_Intern"
  POL=$(j "$API/policies/expression/?name=M159%20Intern%20(verschachtelt)" | jq -r '.results[0].pk // empty')
  EXPR='# Zugriff nur fuer interne Mitarbeitende: direkte oder verschachtelte Mitgliedschaft in G_Intern (AD)
ziel = "cn=g_intern,ou=gruppen,ou=andrija_ag,dc=ec2,dc=andrija,dc=m159"
for g in request.user.ak_groups.all():
    if g.name == "G_Intern":
        return True
    mo = g.attributes.get("memberOf", [])
    if isinstance(mo, str):
        mo = [mo]
    if any(m.lower() == ziel for m in mo):
        return True
ak_message("Kein Mitglied von G_Intern")
return False'
  BODY=$(jq -n --arg e "$EXPR" '{name:"M159 Intern (verschachtelt)", expression:$e, execution_logging:true}')
  if [ -z "$POL" ]; then POL=$(j -X POST $API/policies/expression/ -d "$BODY" | jq -r .pk); else j -X PATCH $API/policies/expression/$POL/ -d "$BODY" >/dev/null; fi
  APP=$(j "$API/core/applications/intranet-oidc/" | jq -r .pk)
  for b in $(j "$API/policies/bindings/?target=$APP" | jq -r '.results[].pk'); do j -X DELETE $API/policies/bindings/$b/; done
  j -X POST $API/policies/bindings/ -d "$(jq -n --arg t "$APP" --arg p "$POL" '{target:$t, policy:$p, order:0, enabled:true, negate:false, timeout:30}')" | jq -c '{order, policy, enabled}'
  echo "== Autorisierung pro Benutzer (check_access)"
  for u in skeller bhuber glang proth; do
    ID=$(j "$API/core/users/?username=$u" | jq -r '.results[0].pk // empty')
    printf '%-8s %s\n' $u "$(j "$API/core/applications/intranet-oidc/check_access/?for_user=$ID" | jq -c '{passing, messages}')"
  done
  echo "== Login-Test (Flow-Executor, Passwortpruefung per LDAP-Bind am DC)"
  UPW=$(gp /m159/userpw); F=$API/flows/executor/default-authentication-flow/
  for pw in RICHTIG FALSCH; do
    CJ=$(mktemp); P=$UPW; [ $pw = FALSCH ] && P='Falsch123!'
    curl -s -c $CJ -b $CJ "$F?query=" >/dev/null
    R1=$(curl -s -L -c $CJ -b $CJ -H 'Content-Type: application/json' "$F?query=" -d '{"component":"ak-stage-identification","uid_field":"skeller"}')
    echo "Passwort $pw – nach Identifikation: $(echo "$R1" | jq -c '{component, response_errors}' 2>/dev/null || echo "$R1" | head -c 200)"
    if [ "$(echo "$R1" | jq -r .component)" = "ak-stage-identification" ]; then
      R1=$(curl -s -L -c $CJ -b $CJ -H 'Content-Type: application/json' "$F?query=" -d "$(jq -n --arg p "$P" '{component:"ak-stage-identification",uid_field:"skeller",password:$p}')")
    else
      R1=$(curl -s -L -c $CJ -b $CJ -H 'Content-Type: application/json' "$F?query=" -d "$(jq -n --arg p "$P" '{component:"ak-stage-password",password:$p}')")
    fi
    echo "Passwort $pw – Ergebnis: $(echo "$R1" | jq -c '{component, to, response_errors}' 2>/dev/null || echo "$R1" | head -c 200)"
    echo "Passwort $pw – Sitzung: $(curl -s -b $CJ $API/core/users/me/ | jq -r '.user.username // "keine"')"
    rm -f $CJ
  done
  echo "== Ereignisse (letzte Logins)"
  j "$API/events/events/?action=login&ordering=-created&page_size=3" | jq -r '.results[] | "\(.created) \(.action) \(.user.username)"'
  j "$API/events/events/?action=login_failed&ordering=-created&page_size=3" | jq -r '.results[] | "\(.created) \(.action) \(.context.username // .user.username)"'
  exit 0
fi

# ---------------- config ----------------
TOKEN=$(gp /m159/ak_token); B=$(gp /m159/bucket)
API=http://localhost:9000/api/v3
j() { curl -s -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$@"; }
echo "== Warten auf Bootstrap-Token (Blueprint wird vom Worker angewendet)"
for i in $(seq 1 6); do [ "$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" $API/core/users/me/)" = 200 ] && break; sleep 10; done
echo "API-Status: $(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" $API/core/users/me/)  Version: $(j $API/admin/version/ | jq -r .version_current)"
aws s3 cp --region $REGION s3://$B/pub/dc-ldaps.pem /opt/authentik/dc-ldaps.pem >/dev/null
echo "== Zertifikat des DC als Verification Certificate importieren"
CERT=$(j "$API/crypto/certificatekeypairs/?name=DC-LDAPS" | jq -r '.results[0].pk // empty')
[ -z "$CERT" ] && CERT=$(j -X POST $API/crypto/certificatekeypairs/ -d "$(jq -n --rawfile c /opt/authentik/dc-ldaps.pem '{name:"DC-LDAPS",certificate_data:$c}')" | jq -r .pk)
j "$API/crypto/certificatekeypairs/$CERT/" | jq '{name, cert_subject, cert_expiry, fingerprint_sha256}'
echo "== Property Mappings"
PM=$(j "$API/propertymappings/source/ldap/?page_size=100")
UM=$(echo "$PM" | jq -c '[.results[] | select(.managed != null) | select(.managed | test("ldap/default|ldap/ms-")) | .pk]')
GM=$(echo "$PM" | jq -c '[.results[] | select(.managed == "goauthentik.io/sources/ldap/default-name") | .pk]')
echo "$PM" | jq -r '.results[] | select(.managed != null) | .name'
echo "== LDAP Source"
BINDPW=$(gp /m159/svc_authentik)
SRC=$(jq -n --arg pw "$BINDPW" --arg cert "$CERT" --argjson um "$UM" --argjson gm "$GM" '{
  name:"AD ec2.andrija.m159", slug:"ad-ec2", enabled:true,
  server_uri:"ldaps://dc-andrija.ec2.andrija.m159:636", peer_certificate:$cert,
  bind_cn:"CN=svc_authentik_ldap,OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159", bind_password:$pw,
  base_dn:"OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159", additional_user_dn:"", additional_group_dn:"",
  user_object_filter:"(&(objectClass=user)(!(objectClass=computer)))", group_object_filter:"(objectClass=group)",
  group_membership_field:"member", object_uniqueness_field:"objectSid",
  sync_users:true, sync_users_password:false, sync_groups:true, start_tls:false,
  user_property_mappings:$um, group_property_mappings:$gm }')
if j "$API/sources/ldap/ad-ec2/" | jq -e .pk >/dev/null 2>&1; then j -X PATCH $API/sources/ldap/ad-ec2/ -d "$SRC" | jq '{slug, server_uri, base_dn, bind_cn}'
else j -X POST $API/sources/ldap/ -d "$SRC" | jq '{slug, server_uri, base_dn, bind_cn}'; fi
echo "== Verbindungsstatus"; j "$API/sources/ldap/ad-ec2/debug/" >/dev/null 2>&1; j "$API/sources/ldap/ad-ec2/sync/status/" | jq -c . 2>/dev/null
echo "== Sync (ak ldap_sync)"
docker compose exec -T worker ak ldap_sync ad-ec2 2>&1 | tail -5
sleep 20
echo "== Synchronisierte Benutzer"
j "$API/core/users/?page_size=100&path=goauthentik.io/sources/ad-ec2" | jq -r '.results[] | "\(.username)\t\(.name)\t\(.groups_obj | map(.name) | join(","))"'
echo "== Synchronisierte Gruppen"
j "$API/core/groups/?page_size=100" | jq -r '.results[] | select(.attributes.distinguishedName != null) | "\(.name)\t\(.users | length) Mitglieder"'
echo "== Login-Test skeller (Passwort wird per LDAP-Bind am DC geprueft)"
UPW=$(gp /m159/userpw); CJ=$(mktemp)
F=$API/flows/executor/default-authentication-flow/
curl -s -c $CJ -b $CJ "$F?query=" | jq -r '.component'
curl -s -c $CJ -b $CJ -H 'Content-Type: application/json' -X POST "$F?query=" -d '{"component":"ak-stage-identification","uid_field":"skeller"}' | jq -r '.component'
R=$(curl -s -c $CJ -b $CJ -H 'Content-Type: application/json' -X POST "$F?query=" -d "$(jq -n --arg p "$UPW" '{component:"ak-stage-password",password:$p}')")
echo "$R" | jq -r '"Ergebnis: \(.component) \(.to // "") \(.response_errors // "" | tostring)"'
echo "Session-Benutzer: $(curl -s -b $CJ $API/core/users/me/ | jq -r '.user.username')"
echo "== Login-Test mit falschem Passwort"
CJ2=$(mktemp)
curl -s -c $CJ2 -b $CJ2 "$F?query=" >/dev/null
curl -s -c $CJ2 -b $CJ2 -H 'Content-Type: application/json' -X POST "$F?query=" -d '{"component":"ak-stage-identification","uid_field":"skeller"}' >/dev/null
curl -s -c $CJ2 -b $CJ2 -H 'Content-Type: application/json' -X POST "$F?query=" -d '{"component":"ak-stage-password","password":"Falsch123!"}' | jq -r '"Ergebnis: \(.component) \(.response_errors // "" | tostring)"'
rm -f $CJ $CJ2
echo "== OIDC-Provider + Anwendung"
AF=$(j "$API/flows/instances/?slug=default-provider-authorization-implicit-consent" | jq -r '.results[0].pk')
IF=$(j "$API/flows/instances/?slug=default-provider-invalidation-flow" | jq -r '.results[0].pk // empty')
SK=$(j "$API/crypto/certificatekeypairs/?name=authentik%20Self-signed%20Certificate" | jq -r '.results[0].pk')
SCOPES=$(j "$API/propertymappings/provider/scope/?page_size=50" | jq -c '[.results[] | select(.managed | test("openid|email|profile")) | .pk]')
PROV=$(j "$API/providers/oauth2/?name=Intranet%20OIDC" | jq -r '.results[0].pk // empty')
PBODY=$(jq -n --arg af "$AF" --arg inv "$IF" --arg sk "$SK" --argjson sc "$SCOPES" '{name:"Intranet OIDC", authorization_flow:$af, client_type:"confidential",
  redirect_uris:[{matching_mode:"strict", url:"http://localhost:5000/callback"}], signing_key:$sk, property_mappings:$sc, sub_mode:"user_username"} + (if $inv != "" then {invalidation_flow:$inv} else {} end)')
[ -z "$PROV" ] && PROV=$(j -X POST $API/providers/oauth2/ -d "$PBODY" | tee /tmp/prov.json | jq -r '.pk // empty')
[ -z "$PROV" ] && cat /tmp/prov.json
j "$API/providers/oauth2/$PROV/" | jq '{name, client_type, client_id, redirect_uris, issuer: "http://<idp>:9000/application/o/intranet-oidc/"}'
j "$API/core/applications/intranet-oidc/" | jq -e .pk >/dev/null 2>&1 || \
  j -X POST $API/core/applications/ -d "$(jq -n --argjson p "$PROV" '{name:"Andrija AG Intranet", slug:"intranet-oidc", provider:$p, policy_engine_mode:"any"}')" | jq '{name, slug, provider}'
APP=$(j "$API/core/applications/intranet-oidc/" | jq -r .pk)
GI=$(j "$API/core/groups/?name=G_Intern" | jq -r '.results[0].pk')
j "$API/policies/bindings/?target=$APP" | jq -e '.results | length > 0' >/dev/null || \
  j -X POST $API/policies/bindings/ -d "$(jq -n --arg t "$APP" --arg g "$GI" '{target:$t, group:$g, order:0, enabled:true, negate:false, timeout:30}')" | jq '{order, group, enabled}'
echo "== OIDC Discovery"
curl -s http://localhost:9000/application/o/intranet-oidc/.well-known/openid-configuration | jq '{issuer, authorization_endpoint, token_endpoint, userinfo_endpoint}'
echo "== Autorisierung: Zugriff auf 'Andrija AG Intranet' (Policy-Binding G_Intern)"
for u in skeller bhuber glang proth; do
  ID=$(j "$API/core/users/?username=$u" | jq -r '.results[0].pk // empty'); [ -z "$ID" ] && { echo "$u nicht synchronisiert"; continue; }
  printf '%-8s %s\n' $u "$(j "$API/core/applications/intranet-oidc/check_access/?for_user=$ID" | jq -c '{passing, messages}')"
done
