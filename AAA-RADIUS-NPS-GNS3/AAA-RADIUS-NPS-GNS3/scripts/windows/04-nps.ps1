<#
 ============================================================
  04 · NPS: rol, clientes RADIUS, firewall y auditoría   (W-Server)
  Las POLÍTICAS DE RED se crean desde nps.msc (ver docs/03, sección 3.5).
 ============================================================
#>

# Rol Network Policy Server y registro en Active Directory
Install-WindowsFeature NPAS -IncludeManagementTools
netsh nps add registeredserver

# Clientes RADIUS: el router y el switch (mismo secreto compartido)
New-NpsRadiusClient -Name "R1"   -Address "10.7.1.1" -SharedSecret "Radius2026!" -VendorName "Cisco"
New-NpsRadiusClient -Name "SW-1" -Address "10.7.1.2" -SharedSecret "Radius2026!" -VendorName "Cisco"

# Firewall: autenticación (1812) y accounting (1813)
New-NetFirewallRule -DisplayName "RADIUS UDP 1812-1813" -Direction Inbound -Protocol UDP -LocalPort 1812,1813 -Action Allow

# Auditoría del Servidor de directivas de redes (eventos 6272 y 6273).
# Se usa el GUID de la subcategoría para que funcione en cualquier idioma de Windows.
auditpol /set /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable

# --- Verificación ---
Get-NpsRadiusClient | Select-Object Name, Address
Get-Service ias | Select-Object Name, Status
Get-NetUDPEndpoint -LocalPort 1812,1813 | Select-Object LocalAddress, LocalPort
Get-NetFirewallRule -DisplayName "RADIUS UDP 1812-1813" | Select-Object DisplayName, Enabled, Action
auditpol /get /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}"

# --- Políticas de red (interfaz gráfica: nps.msc) ---
#  Directivas > Directivas de red > Nueva   (una por nivel, en este orden: 10, 5, 0)
#    Condición ........ Grupos de Windows = LAB\NIVEL-X
#    Permiso .......... Acceso concedido
#    Autenticación .... solo "Autenticación sin cifrado (PAP, SPAP)"
#    Estándar ......... Service-Type = Login
#    Específico del proveedor > Cisco > Cisco-AV-Pair = shell:priv-lvl=X   (X = 10, 5 o 0)
#
#  Cuentas > Configurar cuentas > "Registrar en un archivo de texto en el equipo local"
