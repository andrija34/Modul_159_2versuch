<#  Auftrag 06 – auf dc-andrija: WinRM aktivieren, aber nur vom WAC-Server (10.0.0.30) erlauben  #>
Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
Get-NetFirewallRule -Name 'WINRM-HTTP-In-TCP*' | Set-NetFirewallRule -RemoteAddress 10.0.0.30 -Enabled True -Action Allow
Get-NetFirewallRule -Name 'WINRM-HTTP-In-TCP*' | ForEach-Object {
    [pscustomobject]@{ Regel=$_.Name; Profil=$_.Profile; Aktiv=$_.Enabled; Remote=($_ | Get-NetFirewallAddressFilter).RemoteAddress -join ',' } } | Format-Table -AutoSize
Get-Service WinRM | Select-Object Name, Status, StartType
winrm enumerate winrm/config/listener
