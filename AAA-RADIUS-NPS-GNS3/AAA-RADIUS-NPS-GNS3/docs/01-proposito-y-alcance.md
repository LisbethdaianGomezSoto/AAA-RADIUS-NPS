# 🎯 01 · Propósito y alcance

[⬅ Volver al README](../README.md) · [Siguiente ➡](02-arquitectura-y-diagramas.md)

## Propósito

Este laboratorio demuestra cómo **centralizar la autenticación, la autorización y el registro (AAA)** del acceso administrativo a equipos de red. Los dispositivos Cisco no guardan las cuentas de los administradores: delegan la validación en un servidor **RADIUS (Network Policy Server de Windows)**, que consulta **Active Directory** y devuelve el **nivel de privilegio** que corresponde al grupo del usuario.

### ¿Por qué es importante?

| Sin AAA centralizado | Con AAA centralizado (este laboratorio) |
|---|---|
| Usuarios y claves repetidos en cada equipo | Una sola cuenta en Active Directory |
| Cambiar una clave implica entrar a cada dispositivo | Se cambia una vez en el dominio |
| Todos los administradores tienen el mismo acceso | Cada grupo recibe un nivel de privilegio distinto |
| Poca trazabilidad | Registro de quién entró, cuándo y desde qué equipo |

## Objetivos

1. Desplegar un servidor **Windows Server** con **Active Directory** y los grupos de nivel **0**, **5** y **10**.
2. Instalar y configurar **NPS** con un cliente RADIUS por equipo y una política de red por nivel.
3. Configurar **R1** y **SW-1** como clientes RADIUS con seguridad AAA en todos sus niveles (autenticación, autorización y accounting).
4. Crear un **usuario local** en cada equipo y habilitar **SSH**.
5. Aplicar la autenticación y autorización por RADIUS **solo a los puertos de consola y auxiliar**.
6. Habilitar **logs** de autenticación, autorización y RADIUS.
7. Verificar el funcionamiento y documentar la evidencia.

## Alcance

**Incluye**

- Topología de 4 nodos en GNS3 (servidor, switch, router y PC administradora).
- Servidor con AD DS (dominio `lab.local`) y NPS.
- Router y switch Cisco con AAA, privilegios por nivel, logs y SSH.
- Scripts de PowerShell y comandos de Cisco usados en la implementación.
- Pruebas funcionales y evidencias.

**No incluye**

- Autorización por comando (requiere TACACS+, no RADIUS).
- Métodos EAP / 802.1X.
- Alta disponibilidad del servidor RADIUS.

## Requisitos de la práctica

| Dispositivo | Requisito |
|---|---|
| **1 Router** | Seguridad en todos los niveles de autenticación y autorización · RADIUS como cliente · usuario local · autenticación y autorización solo en consola y auxiliar · logs de autenticación, autorización y RADIUS · servicio SSH |
| **1 Switch** | Los mismos requisitos que el router |
| **1 Servidor** | Active Directory con 1 grupo nivel 0, 1 grupo nivel 5 y 1 grupo nivel 10 · servicio NPS |

## Entorno

| Elemento | Detalle |
|---|---|
| Emulador | GNS3 |
| Servidor | Windows Server 2019 (nombre `W-Server`, dominio `lab.local`) |
| Router | Cisco 2691 · IOS 12.4(25d) |
| Switch | Cisco IOSv-L2 |
| PC administradora | Windows 10 (`WS0701-1`) |
| Red | `10.7.1.0/24` |

## Credenciales de laboratorio

> ⚠️ Son credenciales **solo de laboratorio**. No las uses en entornos reales.

| Dónde | Usuario | Clave |
|---|---|---|
| Consola de R1 y SW-1 (vía RADIUS) | `user0`, `user5`, `user10` | `Passw0rd2026!` |
| Usuario local y SSH de R1 y SW-1 | `admin` | `Cisco2026!` |
| Modo privilegiado (`enable`) | n/a | `Enable2026!` |
| Secreto compartido RADIUS | n/a | `Radius2026!` |
| Restauración de AD (DSRM) | n/a | `Passw0rd2026!` |
