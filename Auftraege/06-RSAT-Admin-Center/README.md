# Auftrag 06 – RSAT-Tools & Windows Admin Center (WAC)

Fragen: [fragen.md](fragen.md)

## 1. Entscheid: Wo steht das Admin Center?

**Gewählt: öffentliches Subnetz `m159-public-1a`, 10.0.0.30, Zugriff von aussen nur per HTTPS (443) bzw. RDP (3389) von meiner öffentlichen IP.**

| Variante | Vorteil | Nachteil |
|---|---|---|
| Privates Subnetz + Jump Host / NAT | Kein direkter Internetzugang zum WAC | NAT-Gateway kostet (~1 $/Tag), zusätzlicher Jump Host nötig |
| **Öffentliches Subnetz, Quelle eingeschränkt** | Kein NAT nötig (Setup braucht Internet), einfacher Zugriff | Exponiert → muss über SG auf eine IP begrenzt werden |

Es gibt kein absolutes Richtig/Falsch: In Produktion wäre ein privates Subnetz mit VPN/Bastion besser. Im Lab ist die IP-Einschränkung auf /32 ein vertretbarer Kompromiss, der die Kosten des NAT-Gateways spart. Falls doch privat: NAT-Gateway im Public-Subnetz anlegen, Route `0.0.0.0/0 → nat-…` in der privaten Routing-Tabelle, nach dem Setup wieder löschen.

## 2. EC2-Instanz `wac-andrija`

Windows Server 2025, t3.medium, 10.0.0.30, SG `m159-sg-client` + 443 von MEINE-IP/32. Init-Skript aus Auftrag 02 mit `-Hostname wac-andrija`.

## 3. In die AWS-Managed-Domäne aufnehmen

```powershell
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses <AWS-DNS1>,<AWS-DNS2>
Add-Computer -DomainName aws.andrija.m159 -Credential AWS\admin -Restart
```
Ab dann mit `AWS\admin` anmelden (nicht mehr lokal) – ausser im WAC selbst, das sich weiterhin mit dem lokalen Administrator anmeldet.

## 4. RSAT

```powershell
Install-WindowsFeature -Name RSAT -IncludeAllSubFeature -IncludeManagementTools
```
Danach verfügbar: `dsa.msc`, `gpmc.msc`, `dnsmgmt.msc`. **Objekte im Managed AD bearbeiten:** dsa.msc → mit `aws.andrija.m159` verbinden → nur in der delegierten OU `OU=AWS,DC=aws,DC=andrija,DC=m159` (Unter-OUs *Users*, *Computers*) kann `admin` Benutzer/Gruppen/OUs anlegen, GPOs nur dort verknüpfen. Built-in-Container, Domain Controllers und Schema sind gesperrt.

## 5. Windows Admin Center installieren

```powershell
Get-ChildItem -Recurse -Path C:\ -Filter *AdminCenter*.exe -ErrorAction SilentlyContinue
```
Setup starten → Standardwerte (Express-Setup, Port 443, selbstsigniertes Zertifikat, „Allow access from any computer“ = *Remote access*) → Anmeldung `https://wac-andrija` bzw. `https://<Elastic-IP>` mit dem lokalen Administrator.

## 6. DC aus dem EC2-AD hinzufügen

WinRM auf `dc-andrija`:
```powershell
Enable-PSRemoting -Force
Set-NetFirewallRule -Name 'WINRM-HTTP-In-TCP-PUBLIC' -RemoteAddress 10.0.0.30 -Enabled True -Profile Domain,Private,Public -Action Allow
Test-WSMan dc-andrija.ec2.andrija.m159          # auf dem WAC-Server
```
SG `m159-sg-dc`: TCP 5985/5986 **nur von 10.0.0.30/32** (nicht 0.0.0.0/0). Weil der WAC-Server in der anderen Domäne ist, im WAC beim Hinzufügen „Andere Anmeldeinformationen“ `EC2\Administrator` verwenden und auf dem WAC `Set-Item WSMan:\localhost\Client\TrustedHosts dc-andrija.ec2.andrija.m159` setzen (bzw. via Trust mit Kerberos). Die Managed-AD-DCs lassen sich nicht hinzufügen (AWS erlaubt keinen Zugriff).

## 7. Sicherheitsmassnahmen (Dokumentation)

| Massnahme | Umsetzung |
|---|---|
| Zugriff von aussen nur von einer IP | SG: 443 + 3389 nur MEINE-IP/32 |
| WinRM nur intern | 5985/5986 nur von 10.0.0.30, Windows-Firewall RemoteAddress eingeschränkt |
| Personenbezogene Admin-Konten | WAC-Gateway-Zugriff nur für Gruppe *Gateway-Administratoren* (lokal) bzw. dedizierte Admins; keine geteilten Konten |
| Zertifikat | Selbstsigniert nur im Lab; produktiv Zertifikat einer internen/öffentlichen CA |
| Protokollierung | WAC-Ereignisprotokoll *Microsoft-ServerManagementExperience*, Anmeldungen (4624/4625) und Kontoänderungen (4720/4728) auf DC auswerten |
| Least Privilege | Managed AD: nur delegierte Rechte; WinRM auf eine Quelle beschränkt |

## 8. Nachweise

| Nachweis | Datei | Status |
|---|---|---|
| WAC-Instanz + Domänenbeitritt | `images/06-join.png` | ⏳ |
| RSAT-Konsolen mit aws.andrija.m159, angelegtes Testobjekt | `images/06-rsat.png` | ⏳ |
| WAC Installation (Schritte) + Login | `images/06-wac-*.png` | ⏳ |
| WinRM aktiv/Test-WSMan + DC im WAC verwaltet | `images/06-winrm.png`, `images/06-dc-im-wac.png` | ⏳ |
| SG-Regeln (443/3389/5985 eingeschränkt) | `images/06-sg.png` | ⏳ |
