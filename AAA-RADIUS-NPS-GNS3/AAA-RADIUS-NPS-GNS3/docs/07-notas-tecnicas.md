# 📝 07 · Notas técnicas

[⬅ Anterior](06-pruebas-y-evidencias.md) · [Volver al README](../README.md)

## Detalles de configuración que conviene conocer

| Tema | Nota |
|---|---|
| **PAP en NPS** | El login de administración de IOS usa PAP. En las políticas se habilita únicamente *Autenticación sin cifrado (PAP, SPAP)*. La contraseña viaja ofuscada con el secreto compartido |
| **Orden de las políticas** | NPS aplica la primera política que coincide. Van de mayor a menor nivel (10, 5, 0) y por encima de las dos políticas por defecto, que deniegan el acceso |
| **`Cisco-AV-Pair`** | `shell:priv-lvl=N` es el atributo que lleva el nivel de privilegio. Se acompaña de `Service-Type = Login` |
| **`aaa authorization console`** | Necesario para que la consola respete la autorización de RADIUS |
| **`no privilege level`** | Las imágenes de GNS3 pueden traer `privilege level 15` en `line con 0` y `line aux 0`. Se quita para que el nivel lo decida NPS |
| **Orden de `privilege exec`** | Primero se asignan los comandos de nivel 10 y al final `privilege exec level 5 show`, para que la palabra `show` quede disponible en el nivel 5 |
| **`ip radius source-interface`** | La IP de origen debe coincidir con la del cliente RADIUS registrado en NPS |
| **`login block-for`** | Es obligatorio para poder usar `login on-success log` y `login on-failure log`. Tras 3 fallos en 60 s se bloquean los intentos por `vty` durante 30 s |
| **Respaldo local** | `group NPS-GRP local` usa el usuario local solo cuando el servidor **no responde**. Si NPS responde con un rechazo, el acceso se deniega |
| **`running-config` por nivel** | Un usuario de nivel 10 ve solo las partes de la configuración que su nivel puede usar. La configuración completa se obtiene con nivel 15 |

## Cliente SSH con IOS antiguos

El router (IOS 12.4) y el switch ofrecen algoritmos antiguos que el cliente OpenSSH de Windows 10 desactiva por defecto. Para conectarse:

```text
:: Router R1
ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -oHostKeyAlgorithms=+ssh-rsa -oCiphers=+aes128-cbc -oMACs=+hmac-sha1 admin@10.7.1.1

:: Switch SW-1
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa -oMACs=+hmac-sha1 admin@10.7.1.2
```

## Limitaciones

- RADIUS no permite **autorizar comando por comando**. Para eso se necesita **TACACS+**; en este laboratorio los comandos de cada nivel se definen con `privilege`.
- El `enable secret` es local: quien lo conozca puede subir a nivel 15 desde cualquier nivel.
- El servidor RADIUS es único, sin redundancia.

## Mejoras posibles

- Migrar la autorización a **TACACS+** para controlar comandos.
- Validar también el `enable` con RADIUS.
- Agregar un segundo servidor NPS para alta disponibilidad.
- Enviar los logs a un servidor **syslog** y sincronizar la hora con **NTP**.
- Proteger el tráfico de administración con un certificado y métodos EAP donde el equipo lo permita.
