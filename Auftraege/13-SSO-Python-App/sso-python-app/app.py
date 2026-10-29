"""SSO-App fuer M159 Auftrag 13 (Basis: Vorlage der Lehrperson).
Aenderungen gegenueber der Vorlage:
  - load_dotenv(): .env wird auch bei `python app.py` geladen (nicht nur bei `flask run`)
  - secret_key aus der Umgebung statt hart codiert 'randomkey'
  - Pruefung, ob CLIENT_ID/SECRET/TENANT_ID gesetzt sind
"""
import os
from dotenv import load_dotenv
from flask import Flask, render_template
from authlib.integrations.flask_client import OAuth

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", os.urandom(32))

CLIENT_ID = os.getenv("CLIENT_ID")
CLIENT_SECRET = os.getenv("CLIENT_SECRET")
TENANT_ID = os.getenv("TENANT_ID")
if not all([CLIENT_ID, CLIENT_SECRET, TENANT_ID]):
    raise SystemExit("CLIENT_ID, CLIENT_SECRET und TENANT_ID in .env eintragen (siehe .env.example)")

ACCESS_TOKEN_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
AUTHORIZE_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/authorize"

oauth = OAuth(app)
oauth.register(
    name="entra",
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    access_token_url=ACCESS_TOKEN_URL,
    authorize_url=AUTHORIZE_URL,
    client_kwargs={"scope": "User.Read"},
)


@app.route("/")
def login():
    # Muss exakt der in Entra ID registrierten Redirect-URI entsprechen (localhost, nicht 127.0.0.1)
    redirect_url = "http://localhost:5000/callback"
    return oauth.entra.authorize_redirect(redirect_url)


@app.route("/callback")
def callback():
    oauth.entra.authorize_access_token()
    resp = oauth.entra.get("https://graph.microsoft.com/v1.0/me")
    resp.raise_for_status()
    return render_template("profile.html", profile=resp.json())


if __name__ == "__main__":
    app.run(host="localhost", port=5000, debug=True)
