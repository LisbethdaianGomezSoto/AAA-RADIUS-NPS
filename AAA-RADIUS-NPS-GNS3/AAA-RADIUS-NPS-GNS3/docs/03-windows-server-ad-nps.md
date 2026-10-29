# 🏢 03 · Windows Server: Active Directory y NPS

[⬅ Anterior](02-arquitectura-y-diagramas.md) · [Volver al README](../README.md) · [Siguiente ➡](04-router-r1.md)

> Todos los comandos de esta sección están en [`scripts/windows/`](../scripts/windows/). Se ejecutan en **PowerShell como administrador** en `W-Server`.

| Paso | Qué se hace | Script |
|:---:|---|---|
| 1 | Red y nombre del servidor | [`01-red-y-nombre.ps1`](../scripts/windows/01-red-y-nombre.ps1) |
| 2 | Active Directory y dominio | [`02-active-directory.ps1`](../scripts/windows/02-active-directory.ps1) |
| 3 | OU, grupos y usuarios | [`03-ou-grupos-usuarios.ps1`](../scripts/windows/03-ou-grupos-usuarios.ps1) |
| 4 | NPS, clientes RADIUS, firewall y auditoría | [`04-nps.ps1`](../scripts/windows/04-nps.ps1) |
| 5 | Políticas de red (interfaz gráfica) | Esta página |
| 6 | Verificación | [`05-verificacion.ps1`](../scripts/windows/05-verificacion.ps1) |

---

## 3.1 Red y nombre del servidor

```powershell
$nic = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $nic.Name -IPAddress 10.7.1.10 -PrefixLength 24 -DefaultGateway 10.7.1.1
Set-DnsClientServerAddress -InterfaceAlias $nic.Name -ServerAddresses 10.7.1.10
New-NetFirewallRule -DisplayName "Permitir ping ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow
Rename-Computer -NewName "W-Server" -Restart
```

Configuración de red del servidor y conectividad con el router:

![Red del servidor](img/10-ps-red.png)

Nombre del equipo y dominio:

![Nombre y dominio](img/11-ps-hostname.png)

---

## 3.2 Active Directory Domain Services

Se instala el rol y se crea un bosque nuevo con el dominio `lab.local`.

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -InstallDns `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "Passw0rd2026!" -AsPlainText -Force) `
  -Force
```

![Instalación del rol AD DS](img/12-ps-install-adds.png)

![Creación del bosque lab.local](img/13-ps-forest.png)

Verificación del dominio y de los servicios `NTDS`, `DNS` y `Netlogon`:

```powershell
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode
Get-Service NTDS, DNS, Netlogon | Select-Object Name, Status
```

![Verificación del dominio](img/14-ps-verifica-dominio.png)

---

## 3.3 OU, grupos y usuarios

Se crea la unidad organizativa `Admins-Red`, los tres grupos de seguridad (`NIVEL-0`, `NIVEL-5`, `NIVEL-10`) y un usuario por nivel.

```powershell
New-ADOrganizationalUnit -Name "Admins-Red" -Path "DC=lab,DC=local"
$ou = "OU=Admins-Red,DC=lab,DC=local"

foreach ($n in 0,5,10) {
    New-ADGroup -Name "NIVEL-$n" -GroupScope Global -GroupCategory Security -Path $ou
}

$pass = ConvertTo-SecureString "Passw0rd2026!" -AsPlainText -Force
foreach ($n in 0,5,10) {
    New-ADUser -Name "user$n" -SamAccountName "user$n" `
        -UserPrincipalName "user$n@lab.local" `
        -AccountPassword $pass -Enabled $true `
        -PasswordNeverExpires $true -Path $ou
    Add-ADGroupMember -Identity "NIVEL-$n" -Members "user$n"
}
```

![OU, grupos y usuarios](img/15-ps-ou-grupos-usuarios.png)

Verificación de la OU, los SID de los grupos y los usuarios:

![Verificación de AD](img/16-ps-verifica-ad.png)

Membresías de cada grupo:

![Membresías](img/17-ps-membresias.png)

Vista gráfica en *Usuarios y equipos de Active Directory* (`dsa.msc`):

![Usuarios y equipos de AD](img/22-ad-usuarios-equipos.png)

![Propiedades del grupo NIVEL-5](img/22b-ad-grupo-nivel5.png)

---

## 3.4 NPS y clientes RADIUS

```powershell
Install-WindowsFeature NPAS -IncludeManagementTools
netsh nps add registeredserver

New-NpsRadiusClient -Name "R1"   -Address "10.7.1.1" -SharedSecret "Radius2026!" -VendorName "Cisco"
New-NpsRadiusClient -Name "SW-1" -Address "10.7.1.2" -SharedSecret "Radius2026!" -VendorName "Cisco"
```

![Instalación y registro de NPS](img/18-ps-install-nps.png)

![Clientes RADIUS por PowerShell](img/19-ps-clientes-radius.png)

Vista de los clientes en la consola de NPS (`nps.msc`):

![Clientes RADIUS en NPS](img/23-nps-clientes.png)

### Firewall y auditoría

```powershell
New-NetFirewallRule -DisplayName "RADIUS UDP 1812-1813" -Direction Inbound -Protocol UDP -LocalPort 1812,1813 -Action Allow
auditpol /set /subcategory:"{0CCE9243-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
```

La auditoría del *Servidor de directivas de redes* genera los eventos **6272** (acceso concedido) y **6273** (acceso denegado).

![Firewall y auditoría](img/20-ps-firewall-auditoria.png)

---

## 3.5 Políticas de red

Se crean **tres políticas**, una por nivel. Cada una:

1. **Condición:** el usuario pertenece al grupo de Windows del nivel (`LAB\NIVEL-X`).
2. **Permiso:** *Acceso concedido*.
3. **Autenticación:** solo *Autenticación sin cifrado (PAP, SPAP)*.
4. **Configuración estándar:** `Service-Type = Login`.
5. **Configuración específica del proveedor:** `Cisco-AV-Pair` con el nivel de privilegio.

**Cómo crearlas en `nps.msc`:** *Directivas → Directivas de red → Nueva* → asistente (nombre, condiciones, permiso, métodos de autenticación, restricciones y configuración).

| Política | Orden | Grupo | Cisco-AV-Pair |
|---|:---:|---|---|
| `Acceso-Nivel-10` | 1 | `LAB\NIVEL-10` | `shell:priv-lvl=10` |
| `Acceso-Nivel-5` | 2 | `LAB\NIVEL-5` | `shell:priv-lvl=5` |
| `Acceso-Nivel-0` | 3 | `LAB\NIVEL-0` | `shell:priv-lvl=0` |

Las políticas se ordenan de mayor a menor nivel y quedan por encima de las dos políticas por defecto, que deniegan el acceso.

![Lista de políticas de red](img/24-nps-politicas-lista.png)

### Acceso-Nivel-10

| Condiciones | Autenticación | Cisco-AV-Pair |
|---|---|---|
| ![N10 condiciones](img/25a-nps-n10-condiciones.png) | ![N10 autenticación](img/25b-nps-n10-autenticacion.png) | ![N10 Cisco-AV-Pair](img/25c-nps-n10-cisco-av-pair.png) |

### Acceso-Nivel-5

| Condiciones | Autenticación | Cisco-AV-Pair |
|---|---|---|
| ![N5 condiciones](img/25d-nps-n5-condiciones.png) | ![N5 autenticación](img/25e-nps-n5-autenticacion.png) | ![N5 Cisco-AV-Pair](img/25f-nps-n5-cisco-av-pair.png) |

### Acceso-Nivel-0

| Condiciones | Autenticación | Cisco-AV-Pair |
|---|---|---|
| ![N0 condiciones](img/25g-nps-n0-condiciones.png) | ![N0 autenticación](img/25h-nps-n0-autenticacion.png) | ![N0 Cisco-AV-Pair](img/25i-nps-n0-cisco-av-pair.png) |

### Resumen final de cada política

| Nivel 10 | Nivel 5 | Nivel 0 |
|---|---|---|
| ![Resumen N10](img/26a-nps-resumen-n10.png) | ![Resumen N5](img/26b-nps-resumen-n5.png) | ![Resumen N0](img/26c-nps-resumen-n0.png) |

### Verificación por consola

```powershell
netsh nps show np | Select-String -Pattern 'Nombre\s+=|Orden de procesamiento|Condition0\s+0x1023|Cisco-AV-Pair'
Get-ADGroup -Filter 'Name -like "NIVEL-*"' | Select-Object Name, SID
```

El SID de cada condición coincide con el SID del grupo correspondiente:

![Resumen de políticas y SID](img/21-ps-politicas-resumen.png)

<details>
<summary>📎 Salida completa de <code>netsh nps show np</code></summary>

![netsh nps 1](img/21a-ps-politicas-netsh-1.png)

![netsh nps 2](img/21b-ps-politicas-netsh-2.png)

![netsh nps 3](img/21c-ps-politicas-netsh-3.png)

</details>

---

## 3.6 Accounting en NPS

En *Cuentas → Configurar cuentas* se elige **registrar en un archivo de texto en el equipo local**. Los registros quedan en `C:\Windows\System32\LogFiles\IN*.log`.

![Cuentas en NPS](img/27-nps-cuentas.png)

Contenido del archivo de accounting (sesiones de `R1` y `SW-1`):

```powershell
Get-ChildItem C:\Windows\System32\LogFiles\IN*.log
Get-Content (Get-ChildItem C:\Windows\System32\LogFiles\IN*.log | Select-Object -Last 1).FullName -Tail 5
```

![Log de accounting](img/28-nps-log-accounting.png)
