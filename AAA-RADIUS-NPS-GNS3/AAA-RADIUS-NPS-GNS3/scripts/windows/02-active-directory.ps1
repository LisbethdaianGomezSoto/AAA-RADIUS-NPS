<#
 ============================================================
  02 · Active Directory Domain Services      (W-Server)
  Crea el bosque lab.local. El servidor se reinicia al terminar.
 ============================================================
#>

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -InstallDns `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "Passw0rd2026!" -AsPlainText -Force) `
  -Force

# --- Verificación (después del reinicio, como LAB\Administrador) ---
# Get-ADDomain | Select-Object Name, DNSRoot, DomainMode
# Get-Service NTDS, DNS, Netlogon | Select-Object Name, Status
