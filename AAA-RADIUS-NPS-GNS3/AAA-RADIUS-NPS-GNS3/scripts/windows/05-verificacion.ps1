<#
 ============================================================
  05 · Verificación y logs               (W-Server)
  Solo consulta: no cambia ninguna configuración.
 ============================================================
#>

"--- Dominio y servicios ---"
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode
Get-Service NTDS, DNS, Netlogon | Select-Object Name, Status

"--- Grupos, SID y usuarios ---"
Get-ADGroup -Filter 'Name -like "NIVEL-*"' | Select-Object Name, SID
Get-ADUser  -Filter 'SamAccountName -like "user*"' | Select-Object Name, Enabled
foreach ($n in 0,5,10) { "NIVEL-$n :"; Get-ADGroupMember "NIVEL-$n" | Select-Object Name }

"--- NPS: clientes, servicio y puertos ---"
Get-NpsRadiusClient | Select-Object Name, Address
Get-Service ias | Select-Object Name, Status
Get-NetUDPEndpoint -LocalPort 1812,1813 | Select-Object LocalAddress, LocalPort

"--- NPS: resumen de políticas (orden, SID del grupo y Cisco-AV-Pair) ---"
netsh nps show np | Select-String -Pattern 'Nombre\s+=|Orden de procesamiento|Condition0\s+0x1023|Cisco-AV-Pair'

"--- Eventos de NPS: 6272 (concedido) y 6273 (denegado) ---"
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=6272} -MaxEvents 1 | Format-List TimeCreated, Message
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=6273} -MaxEvents 1 | Format-List TimeCreated, Message

"--- Accounting de NPS (archivo de texto) ---"
Get-ChildItem C:\Windows\System32\LogFiles\IN*.log
Get-Content (Get-ChildItem C:\Windows\System32\LogFiles\IN*.log | Select-Object -Last 1).FullName -Tail 5
