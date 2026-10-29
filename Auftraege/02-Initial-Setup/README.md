# Auftrag 02 – Initial Setup (AWS + Windows-Grundeinstellungen)

Planung: [../01-Planung/README.md](../01-Planung/README.md) · Fragen: [fragen.md](fragen.md) · Skript: [`scripts/02-init.ps1`](../../scripts/02-init.ps1)

## 1. AWS-Umgebung gemäss Planung

### 1.1 VPC und Subnetze (VPC-Assistent „VPC and more“)

| Einstellung | Wert |
|---|---|
| Name tag auto-generation | `m159` |
| IPv4 CIDR | 10.0.0.0/16 |
| Availability Zones | 2 (us-east-1a, us-east-1b) |
| Public subnets | 2 → 10.0.0.0/20, 10.0.16.0/20 |
| Private subnets | 2 → 10.0.128.0/20, 10.0.144.0/20 |
| NAT gateways | **None** (Kosten; bei Bedarf in Auftrag 06 temporär) |
| VPC endpoints | None |
| DNS hostnames / resolution | aktiviert |

Danach Subnetze gemäss Planung umbenennen (`m159-public-1a` …) und bei den öffentlichen Subnetzen *Auto-assign public IPv4* aktivieren.

### 1.2 Security Groups

`m159-sg-dc` und `m159-sg-client` exakt nach Planung Kap. 5. RDP nur von der eigenen öffentlichen IP (`MEINE-IP/32`), alle AD-Ports nur aus der VPC.

### 1.3 EC2-Instanzen

| Name (= Hostname) | AMI | Typ | Subnetz | Private IP (manuell gesetzt) | SG |
|---|---|---|---|---|---|
| dc-andrija | Windows Server 2025 Base | t3.medium | m159-public-1a | 10.0.0.10 | m159-sg-dc |
| client-andrija | Windows Server 2025 Base | t3.medium | m159-public-1a | 10.0.0.20 | m159-sg-client |

Bei *Network settings → Advanced → Primary IP* die IP manuell eintragen, sonst vergibt AWS eine zufällige Adresse. Key Pair `vockey` (Learner Lab) zum Entschlüsseln des Administrator-Passworts. Danach je eine Elastic IP zuweisen, damit sich die öffentliche IP beim Stoppen nicht ändert.

## 2. Windows-Einstellungen (Core & Desktop)

Per RDP auf jede Instanz, PowerShell als Administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\02-init.ps1 -Hostname dc-andrija      # bzw. client-andrija
Restart-Computer
```

| Anforderung | Umsetzung im Skript | Prüfung |
|---|---|---|
| Hostname | `Rename-Computer` | `hostname` |
| Ping erlauben | Firewall-Regel ICMPv4 Echo Request, alle Profile | `ping 10.0.0.10` vom Client |
| Tastatur CH | `Set-WinUserLanguageList de-CH`, Region/Zeitzone Schweiz | Sprachleiste |
| IE ESC aus (Desktop) | Registry Active Setup `IsInstalled=0` | Server Manager → Lokaler Server |
| IPv6 aus | `Disable-NetAdapterBinding ms_tcpip6` | `ncpa.cpl` → Eigenschaften |
| Dateiendungen anzeigen | `HideFileExt=0` | Explorer |
| Freigabeassistent aus | `SharingWizardOn=0` | Ordneroptionen |
| Geschützte Systemdateien + alle Dateien | `ShowSuperHidden=1`, `Hidden=1` | Ordneroptionen |
| Verknüpfungen CMD/PS | `New-Shortcut` (aktueller + Default-Benutzer) | Desktop |
| Desktopsymbole | `HideDesktopIcons\NewStartPanel` = 0 | Desktop |

## 3. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| VPC-Übersicht mit 4 Subnetzen | `images/02-vpc.png` | ⏳ |
| Security Group Regeln DC / Client | `images/02-sg-dc.png`, `images/02-sg-client.png` | ⏳ |
| EC2-Instanzen mit Namen + privaten IPs | `images/02-ec2.png` | ⏳ |
| `ipconfig /all` + `hostname` auf beiden Servern | `images/02-ipconfig-dc.png`, `images/02-ipconfig-client.png` | ⏳ |
| Ping DC ↔ Client | `images/02-ping.png` | ⏳ |
| Ordneroptionen + Desktop | `images/02-explorer.png` | ⏳ |

⏳ = wird nach dem Login ins AWS Learner Lab erstellt.
