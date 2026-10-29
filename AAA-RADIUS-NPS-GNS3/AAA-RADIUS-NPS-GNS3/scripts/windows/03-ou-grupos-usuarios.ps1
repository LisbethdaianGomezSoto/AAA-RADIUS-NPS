<#
 ============================================================
  03 · OU, grupos y usuarios            (W-Server)
  Grupos: NIVEL-0, NIVEL-5, NIVEL-10   ·   Usuarios: user0, user5, user10
 ============================================================
#>
Import-Module ActiveDirectory

# Unidad organizativa
New-ADOrganizationalUnit -Name "Admins-Red" -Path "DC=lab,DC=local"
$ou = "OU=Admins-Red,DC=lab,DC=local"

# Grupos de seguridad globales
foreach ($n in 0,5,10) {
    New-ADGroup -Name "NIVEL-$n" -GroupScope Global -GroupCategory Security -Path $ou
}

# Usuarios (uno por nivel) y pertenencia al grupo correspondiente
$pass = ConvertTo-SecureString "Passw0rd2026!" -AsPlainText -Force
foreach ($n in 0,5,10) {
    New-ADUser -Name "user$n" -SamAccountName "user$n" `
        -UserPrincipalName "user$n@lab.local" `
        -AccountPassword $pass -Enabled $true `
        -PasswordNeverExpires $true -Path $ou
    Add-ADGroupMember -Identity "NIVEL-$n" -Members "user$n"
}

# --- Verificación ---
Get-ADOrganizationalUnit -Identity $ou | Select-Object Name, DistinguishedName
Get-ADGroup -SearchBase $ou -Filter * | Select-Object Name, GroupScope, GroupCategory
Get-ADUser  -SearchBase $ou -Filter * | Select-Object Name, SamAccountName, Enabled
foreach ($n in 0,5,10) { "NIVEL-$n :"; Get-ADGroupMember "NIVEL-$n" | Select-Object Name }
