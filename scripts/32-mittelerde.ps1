<#  Auftrag 00 - Uebung Berechtigungen (Mittelerde) auf client-andrija praktisch nachvollziehen (laeuft als SYSTEM via SSM).
    Hinweis: PowerShell 5.1 liest Skripte ohne BOM als ANSI -> Umlaut per [char]0xF6.  #>
$ErrorActionPreference = 'Continue'
$v = "C:\Mittelerde\V$([char]0xF6)lker"
'Zwerge','Elben','Menschen' | ForEach-Object { New-Item -ItemType Directory -Path "$v\$_" -Force | Out-Null }
if (-not (Get-LocalGroup -Name Menschen -ErrorAction SilentlyContinue)) { New-LocalGroup -Name Menschen -Description 'M159 Uebung Mittelerde' | Out-Null }
icacls C:\Mittelerde /grant 'Menschen:(OI)(CI)RX' | Out-Null
"== 1) Menschen auf Mittelerde gesetzt -> alle Unterordner erben:"
foreach ($p in 'C:\Mittelerde', $v, "$v\Elben", "$v\Menschen", "$v\Zwerge") {
  (Get-Acl $p).Access | Where-Object { $_.IdentityReference -like '*Menschen' } | ForEach-Object { "{0,-28} {1,-22} geerbt={2}" -f ($p -replace '.*\\',''), $_.FileSystemRights, $_.IsInherited }
}
"== 2) Elben und Zwerge: Vererbung deaktivieren (konvertieren) und Menschen entfernen"
foreach ($n in 'Elben','Zwerge') {
  icacls "$v\$n" /inheritance:d | Out-Null
  icacls "$v\$n" /remove:g Menschen | Out-Null
}
foreach ($p in "$v\Elben", "$v\Menschen", "$v\Zwerge") {
  $a = Get-Acl $p
  "{0,-10} Vererbung geschuetzt={1}  Menschen vorhanden={2}" -f ($p -replace '.*\\',''), $a.AreAccessRulesProtected, [bool]($a.Access | Where-Object { $_.IdentityReference -like '*Menschen' })
}
