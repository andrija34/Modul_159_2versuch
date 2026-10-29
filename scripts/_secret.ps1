# Gemeinsame Hilfsfunktion: Geheimnis aus AWS SSM Parameter Store (SecureString) lesen,
# sonst interaktiv abfragen. Geheimnisse stehen nie im Skript oder im Repository.
function Get-M159Secret([string]$Name, [string]$Prompt) {
    try {
        $v = (Get-SSMParameter -Name $Name -WithDecryption $true -Region us-east-1 -ErrorAction Stop).Value
        return (ConvertTo-SecureString $v -AsPlainText -Force)
    } catch { return (Read-Host $Prompt -AsSecureString) }
}
