<#
 ============================================================
  01 · Red y nombre del servidor        (W-Server)
  Ejecutar en PowerShell como administrador.
 ============================================================
#>

# Tarjeta de red activa
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1

# IP estática, gateway y DNS (el servidor será su propio DNS)
New-NetIPAddress -InterfaceAlias $nic.Name -IPAddress 10.7.1.10 -PrefixLength 24 -DefaultGateway 10.7.1.1
Set-DnsClientServerAddress -InterfaceAlias $nic.Name -ServerAddresses 10.7.1.10

# Permitir ping (ICMPv4 de entrada)
New-NetFirewallRule -DisplayName "Permitir ping ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow

# Nombre del equipo (reinicia el servidor)
Rename-Computer -NewName "W-Server" -Restart

# --- Verificación (después del reinicio) ---
# ipconfig /all
# ping 10.7.1.1
# hostname
# Get-WmiObject Win32_ComputerSystem | Select-Object Name, Domain
