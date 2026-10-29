<#  Auftrag 05 Variante B – auf dc-andrija: LDAPS-Zertifikat + Bind-Konto fuer Authentik
    Lab-Variante ohne Enterprise-CA: selbstsigniertes Serverzertifikat (Server Authentication) im Computerspeicher.
    Der DC verwendet es automatisch fuer LDAPS (636); Authentik vertraut genau diesem Zertifikat.  #>
Import-Module ActiveDirectory
. (Join-Path $PSScriptRoot '_secret.ps1')
$fqdn = 'dc-andrija.ec2.andrija.m159'
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$fqdn" -and $_.FriendlyName -eq 'M159 LDAPS' } | Select-Object -First 1
if (-not $cert) {
    $cert = New-SelfSignedCertificate -Subject "CN=$fqdn" -FriendlyName 'M159 LDAPS' -CertStoreLocation Cert:\LocalMachine\My `
        -KeyAlgorithm RSA -KeyLength 2048 -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears(2) `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1', "2.5.29.17={text}DNS=$fqdn&DNS=dc-andrija&IPAddress=10.0.0.10")
    # Selbst vertrauen (Root-Speicher), damit lokale Tests die Kette pruefen koennen
    $st = New-Object Security.Cryptography.X509Certificates.X509Store('Root','LocalMachine'); $st.Open('ReadWrite'); $st.Add($cert); $st.Close()
}
$cert | Format-List Subject, Thumbprint, NotAfter, @{n='SAN';e={($_.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' }).Format($false)}}, @{n='EKU';e={$_.EnhancedKeyUsageList.FriendlyName}}
# LDAP-Dienst das neue Zertifikat sofort laden lassen (statt Neustart)
$rd = [ADSI]'LDAP://localhost/RootDSE'; $rd.Put('renewServerCertificate', 1); $rd.SetInfo()
Start-Sleep 5
# Oeffentlichen Teil (PEM) fuer Authentik nach S3 legen
$pem = "-----BEGIN CERTIFICATE-----`n" + [Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks') + "`n-----END CERTIFICATE-----`n"
Set-Content C:\m159\dc-ldaps.pem $pem -Encoding Ascii
Write-S3Object -BucketName (Get-SSMParameter -Name /m159/bucket -Region us-east-1).Value -Key 'pub/dc-ldaps.pem' -File C:\m159\dc-ldaps.pem -Region us-east-1
"== LDAPS-Test lokal (Port 636, TLS-Handshake)"
$tcp = New-Object Net.Sockets.TcpClient($fqdn, 636)
$ssl = New-Object Net.Security.SslStream($tcp.GetStream(), $false, { $true })
$ssl.AuthenticateAsClient($fqdn)
"TLS: $($ssl.SslProtocol)  Zertifikat: $($ssl.RemoteCertificate.Subject)  Thumbprint: $($ssl.RemoteCertificate.GetCertHashString())"
$ssl.Dispose(); $tcp.Dispose()
"== LDAP-Signing-Anforderung (Server 2025)"
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Parameters' -Name LDAPServerIntegrity, LdapEnforceChannelBinding -ErrorAction SilentlyContinue | Select-Object LDAPServerIntegrity, LdapEnforceChannelBinding

"== Bind-Konto svc_authentik_ldap (nur Domaenen-Benutzer = Leserechte)"
$ou = 'OU=Dienstkonten,OU=Andrija_AG,DC=ec2,DC=andrija,DC=m159'
if (-not (Get-ADUser -Filter "SamAccountName -eq 'svc_authentik_ldap'")) {
    New-ADUser -Name svc_authentik_ldap -SamAccountName svc_authentik_ldap -UserPrincipalName 'svc_authentik_ldap@ec2.andrija.m159' -Path $ou `
        -Description 'Bind-Konto Authentik LDAP Source (nur lesen)' -AccountPassword (Get-M159Secret '/m159/svc_authentik' 'Kennwort svc_authentik_ldap') `
        -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true
}
Get-ADUser svc_authentik_ldap -Properties MemberOf | Format-List DistinguishedName, Enabled, @{n='Gruppen';e={(Get-ADPrincipalGroupMembership $_).Name -join ', '}}
"== G_Intern / G_Extern Mitglieder"
foreach ($g in 'G_Intern','G_Extern') { '{0}: {1}' -f $g, ((Get-ADGroupMember $g -Recursive).SamAccountName -join ', ') }
