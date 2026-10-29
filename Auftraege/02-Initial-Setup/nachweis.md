# Auftrag 02 – Nachweis (Umsetzung 27.10.2026)

Umgesetzt im AWS Learner Lab per AWS CloudShell mit [`scripts/02-aws-provision.sh`](../../scripts/02-aws-provision.sh); Windows-Einstellungen per AWS Systems Manager (Run Command) mit [`scripts/02-init.ps1`](../../scripts/02-init.ps1). Die Instanzen haben das Instanzprofil `LabInstanceProfile`, dadurch sind sie in SSM verwaltet und brauchen für die Konfiguration kein offenes RDP.

## AWS-Ressourcen

| Ressource | ID |
|---|---|
| VPC m159-vpc (10.0.0.0/16) | vpc-09238dc9f9e472a33 |
| m159-public-1a (10.0.0.0/20) | subnet-0493de1c4a1045496 |
| m159-public-1b (10.0.16.0/20) | subnet-0e17b549d0942c036 |
| m159-private-1a (10.0.128.0/20) | subnet-0f6fc08c6f1c84ef4 |
| m159-private-1b (10.0.144.0/20) | subnet-045a63f2040f37b07 |
| m159-sg-dc | sg-05addfb2fe672b565 |
| m159-sg-client | sg-04ee9adad1797e372 |
| dc-andrija | i-075c3260597ac4833 · 10.0.0.10 · EIP 52.44.104.115 |
| client-andrija | i-00f15a77064032d85 · 10.0.0.20 · EIP 100.27.159.175 |

Ausgabe von `prov.sh` (CloudShell):

```text
| dc-andrija    | i-075c3260597ac4833 | 10.0.0.10 | 52.44.104.115  | running |
| client-andrija| i-00f15a77064032d85 | 10.0.0.20 | 100.27.159.175 | running |
```

![EC2-Instanzen](../../images/02-ec2.png)

![Security Group DC (eigene IP maskiert)](../../images/02-sg-dc.png)

Hinweis: AWS erlaubt keine SG-Namen, die mit `sg-` beginnen → Namen `m159-sg-dc` / `m159-sg-client` (Planung angepasst).

## SSM-Verwaltung

```text
| i-075c3260597ac4833 | Online | Microsoft Windows Server 2025 Datacenter |
| i-00f15a77064032d85 | Online | Microsoft Windows Server 2025 Datacenter |
```

## Windows-Einstellungen (Ausgabe nach Init + Neustart)

```text
>> dc-andrija  : hostname -> dc-andrija
   Get-NetAdapterBinding -ComponentID ms_tcpip6  ->  Ethernet  Enabled=False   (IPv6 aus)
   (Get-TimeZone).Id -> W. Europe Standard Time
>> client-andrija : hostname -> client-andrija
```

Erkenntnis bei der Umsetzung: Der Exit-Code 3010 (Neustart anfordern) wurde vom SSM-Wrapper zuerst nicht weitergegeben – der Hostname änderte sich deshalb erst nach einem manuellen Neustart. Korrektur im Helfer `runps`: `…; exit $LASTEXITCODE`.

## Offene Bildnachweise (GUI)

Explorer-Ordneroptionen/Desktop-Symbole sind per Registry gesetzt; GUI-Screenshots folgen bei der ersten RDP-Anmeldung (Anmeldung durch Andrija).
