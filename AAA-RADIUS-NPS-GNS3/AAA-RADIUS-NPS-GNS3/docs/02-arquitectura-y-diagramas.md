# 🧭 02 · Arquitectura y diagramas

[⬅ Anterior](01-proposito-y-alcance.md) · [Volver al README](../README.md) · [Siguiente ➡](03-windows-server-ad-nps.md)

## 1. Topología

<div align="center">
<img src="diagramas/topologia-neon.svg" alt="Topología" width="90%"/>
</div>

Topología tal como se ve en GNS3:

![Topología en GNS3](img/01-topologia.png)

### Diagrama lógico

```mermaid
flowchart TB
  classDef srv fill:#0b0f1a,stroke:#ff2bd6,color:#ff2bd6,stroke-width:2px
  classDef sw fill:#0b0f1a,stroke:#00e5ff,color:#00e5ff,stroke-width:2px
  classDef rt fill:#0b0f1a,stroke:#39ff14,color:#39ff14,stroke-width:2px
  classDef pc fill:#0b0f1a,stroke:#ffd400,color:#ffd400,stroke-width:2px

  subgraph LAN["Red 10.7.1.0/24 · dominio lab.local"]
    SRV["Windows Server<br/>AD DS + NPS<br/>10.7.1.10"]:::srv
    SW["SW-1<br/>10.7.1.2"]:::sw
    R1["R1<br/>10.7.1.1"]:::rt
    PC["WS0701-1<br/>10.7.1.20"]:::pc
  end

  SRV --- SW
  R1 --- SW
  PC --- SW
  R1 -. "RADIUS 1812/1813" .-> SRV
  SW -. "RADIUS 1812/1813" .-> SRV
```

## 2. Plan de direccionamiento

| Equipo | Interfaz | IP | Máscara | Gateway |
|---|---|---|---|---|
| W-Server | `e0` | 10.7.1.10 | 255.255.255.0 | 10.7.1.1 |
| SW-1 | `Vlan1` | 10.7.1.2 | 255.255.255.0 | 10.7.1.1 |
| R1 | `f0/0` | 10.7.1.1 | 255.255.255.0 | n/a |
| WS0701-1 | `e0` | 10.7.1.20 | 255.255.255.0 | 10.7.1.1 |

## 3. Flujo de una autenticación

<div align="center">
<img src="diagramas/flujo-aaa.svg" alt="Flujo AAA" width="95%"/>
</div>

```mermaid
sequenceDiagram
  autonumber
  actor U as Usuario
  participant D as R1 / SW-1
  participant N as NPS
  participant A as Active Directory
  U->>D: login por consola (usuario + clave)
  D->>N: Access-Request (PAP) · UDP 1812
  N->>A: valida credenciales y grupo
  A-->>N: usuario válido · miembro de NIVEL-X
  N-->>D: Access-Accept + Cisco-AV-Pair shell:priv-lvl=X
  D-->>U: sesión con nivel de privilegio X
  D->>N: Accounting Start · UDP 1813
  U->>D: exit
  D->>N: Accounting Stop
```

## 4. ¿Qué pasa si el servidor no responde?

```mermaid
flowchart TD
  classDef ok fill:#0b0f1a,stroke:#39ff14,color:#39ff14
  classDef no fill:#0b0f1a,stroke:#ff2bd6,color:#ff2bd6
  classDef q fill:#0b0f1a,stroke:#00e5ff,color:#00e5ff

  L[Login por consola]:::q --> Q{¿NPS responde?}:::q
  Q -- Sí --> V{¿Credenciales válidas?}:::q
  V -- Sí --> OK["Acceso con el nivel que indica NPS"]:::ok
  V -- No --> NO["Acceso denegado"]:::no
  Q -- No --> LOC["Se usa el usuario local admin · nivel 15"]:::ok
```

## 5. Niveles de privilegio

```mermaid
flowchart LR
  classDef user fill:#0b0f1a,stroke:#ffd400,color:#ffd400
  classDef grp fill:#0b0f1a,stroke:#39ff14,color:#39ff14
  classDef pol fill:#0b0f1a,stroke:#ff2bd6,color:#ff2bd6
  classDef cmd fill:#0b0f1a,stroke:#00e5ff,color:#00e5ff

  u0([user0]):::user --> g0[NIVEL-0]:::grp --> p0["Acceso-Nivel-0<br/>priv-lvl=0"]:::pol --> c0["disable · enable · exit · help · logout"]:::cmd
  u5([user5]):::user --> g5[NIVEL-5]:::grp --> p5["Acceso-Nivel-5<br/>priv-lvl=5"]:::pol --> c5["ping · show ip interface brief · show version"]:::cmd
  u10([user10]):::user --> g10[NIVEL-10]:::grp --> p10["Acceso-Nivel-10<br/>priv-lvl=10"]:::pol --> c10["show running-config · show logging · configure terminal"]:::cmd
```

| Usuario | Grupo de AD | Política de NPS | Orden | Cisco-AV-Pair |
|---|---|---|:---:|---|
| `user10` | `NIVEL-10` | `Acceso-Nivel-10` | 1 | `shell:priv-lvl=10` |
| `user5` | `NIVEL-5` | `Acceso-Nivel-5` | 2 | `shell:priv-lvl=5` |
| `user0` | `NIVEL-0` | `Acceso-Nivel-0` | 3 | `shell:priv-lvl=0` |

## 6. Decisiones de diseño

| Decisión | Motivo |
|---|---|
| RADIUS solo en `con 0` y `aux 0` | Cumple el requisito de limitar autenticación y autorización a esos puertos |
| Líneas `vty` con usuario local | SSH siempre disponible, aunque el servidor falle |
| Listas con nombre (`CON_AUX_AUTH`, `VTY_LOCAL`) | Permiten aplicar cada método solo donde corresponde |
| Respaldo local (`group NPS-GRP local`) | Acceso de emergencia si NPS no responde |
| Autenticación PAP en NPS | Es el método que usa IOS para el login de administración |
| Políticas ordenadas de mayor a menor nivel | Si un usuario está en varios grupos, recibe el nivel más alto |
