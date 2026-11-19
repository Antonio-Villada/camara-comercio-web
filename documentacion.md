# Documentación Técnica de Servicios de Infraestructura

## Justificación de Versiones y Entorno de Despliegue

La rúbrica del proyecto establece como requisito el uso de **Ubuntu Server 22.04/24.04 LTS** con al menos `2 vCPUs`, `4 GB de RAM` y `40 GB de disco`. Para esta implementación se decidió utilizar **Ubuntu 24.04 LTS (Noble Numbat)** en una máquina virtual aprovisionada en **Google Cloud Platform (GCP)** (`infra-camara-server`, IP pública `35.225.203.150`), en lugar de un hipervisor local, con base en los siguientes criterios:

1. **Continuidad del Entorno:** Se aprovechó la instancia aprovisionada y validada durante el Entregable 2 (Infraestructura Base), preservando la estabilidad de la plataforma Dokploy, los contenedores y el enrutamiento DNS/SSL ya configurados.
2. **Colaboración en Equipo:** El alojamiento en la nube permitió que todos los integrantes del equipo (Iván, Jesús, Jefferson y Johana) trabajaran de forma remota y concurrente sobre el mismo servidor mediante SSH y el panel web, agilizando pruebas y resolución de incidentes.
3. **Vigencia Tecnológica:** Ubuntu 24.04 LTS ofrece soporte a largo plazo (hasta 2029) y paquetes actualizados, alineando la infraestructura con estándares modernos de producción.

La adopción de Ubuntu 24.04 LTS implicó adaptaciones puntuales respecto a guías diseñadas para versiones anteriores (como la transición de `ntp` a `ntpsec`, la declaración manual del dominio en `nis` y la gestión del puerto 631 mediante `cups.socket`). Para documentar y validar estas adaptaciones se consultaron la documentación oficial de Dokploy, los manuales de Ubuntu (`manpages.ubuntu.com`), la documentación oficial de CUPS (`cups.org`), la documentación oficial de Samba (`samba.org`) y foros técnicos de la comunidad Ubuntu (*Ask Ubuntu*).

---

## 1. Plataforma de Contenedores, Sitio Web Institucional y Base de Datos (Dokploy)

Para centralizar el despliegue de aplicaciones y persistencia de datos se instaló **Dokploy**, el cual gestiona Docker y el proxy inverso **Traefik**.

### Procedimiento de instalación y configuración
1. Se verificaron los recursos de la máquina virtual (`2 vCPUs`, `4 GB RAM`, `40 GB disco`) y se instaló Dokploy ejecutando el script oficial:
```bash
free -h
df -h /
nproc
curl -sSL https://dokploy.com/install.sh | sh
```
2. Se creó el servicio de base de datos **PostgreSQL** desde el panel de Dokploy (`http://35.225.203.150:3000`), manteniéndolo aislado en la red interna de Docker (puerto `5432` sin exposición pública).
3. Se desplegó el sitio web institucional de la Cámara de Comercio mediante el archivo `codigo/Dockerfile` (basado en `nginx:alpine`) y `codigo/index.html`.
4. En el proveedor DNS (Cloudflare) se configuró un registro tipo `A` para `camara.villadastudios.com` apuntando a `35.225.203.150`, se vinculó el dominio en Dokploy habilitando HTTPS con **Let's Encrypt** y se configuró el modo SSL/TLS en **Full (Strict)**.

### Verificación y Pruebas
Se verificó que los contenedores de Dokploy, Traefik y PostgreSQL estuvieran en ejecución y que el dominio respondiera por HTTPS con certificado válido:
```bash
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
ping -c 4 camara.villadastudios.com
curl -I https://camara.villadastudios.com
```

![Recursos del servidor y contenedores Dokploy](capturas/01_dokploy_recursos.png)
![Verificación HTTPS del portal institucional](capturas/02_web_https.png)

---

## 2. Servidor de Tiempo (NTP / NTPsec)

Para garantizar la coherencia temporal de los logs de auditoría, certificados y transacciones en base de datos, se implementó el servicio de sincronización horaria. En Ubuntu 24.04 LTS, el paquete clásico `ntp` fue reemplazado por **`ntpsec`**.

### Procedimiento de instalación y configuración
Se instaló el paquete `ntpsec`:
```bash
sudo apt install ntpsec -y
```

Se verificó y configuró el archivo `/etc/ntpsec/ntp.conf` declarando el pool global de sincronización:
```text
server pool.ntp.org iburst
```

Finalmente, se habilitó e inició el servicio:
```bash
sudo systemctl enable --now ntpsec
```

### Verificación y Pruebas
Se validó el estado del demonio y la tabla de sincronización horaria con `ntpq -p`:
```bash
sudo systemctl status ntpsec
ntpq -p
```
En la salida de `ntpq -p`, el servidor registra sincronización activa (`reach 377`, `stratum 2`) con el servidor de tiempo de alta precisión de Google Cloud (`*metadata.google.internal`) junto con la configuración del servicio, mostrando métricas estables de `delay`, `offset` y `jitter`.

![Estado del servicio NTPsec y tabla ntpq](capturas/03_ntp_estado.png)

---

## 3. Compartición de Archivos para Entornos Linux (NFS)

Para centralizar el repositorio de documentos legales y administrativos utilizados por sistemas Linux de la entidad, se implementó **NFS** (*Network File System*).

### Procedimiento de instalación y configuración
Se instaló el servidor NFS y se creó el directorio compartido:
```bash
sudo apt install nfs-kernel-server -y
sudo mkdir -p /srv/nfs/empresa
```

Se configuró la regla de exportación en `/etc/exports` habilitando lectura/escritura y escritura síncrona para el entorno de red en la nube:
```bash
echo "/srv/nfs/empresa *(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
```

Se recargó la tabla de exportaciones y se habilitó el servicio:
```bash
sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server
```

### Verificación y Pruebas
Se comprobó el registro de la exportación y el estado del servicio en `systemd`:
```bash
sudo exportfs -v
sudo systemctl status nfs-kernel-server
```
El comando de estado confirmó `Active: active (exited)` con código de salida `0/SUCCESS`, que es el estado operativo normal de la unidad `nfs-server.service` en Ubuntu 24.04 una vez cargados los módulos y exportaciones en el kernel.

![Estado del servicio NFS y exportaciones](capturas/04_nfs_estado.png)

---

## 4. Compartición de Archivos Multiplataforma (Samba)

Para permitir el trabajo colaborativo desde estaciones de trabajo Windows y macOS de los funcionarios administrativos, se desplegó un servidor **Samba**.

### Procedimiento de instalación y configuración
Se instalaron los paquetes del servidor y utilidades cliente, y se creó el directorio del recurso compartido:
```bash
sudo apt install samba smbclient -y
sudo mkdir -p /srv/samba/empresa
```

Se restringió el acceso creando un grupo autorizado y agregando al usuario administrador:
```bash
sudo groupadd sambausers
sudo usermod -aG sambausers root
```

Se añadió el bloque del recurso compartido al final de `/etc/samba/smb.conf`:
```ini
[empresa]
   path = /srv/samba/empresa
   browseable = yes
   writable = yes
   guest ok = no
   valid users = @sambausers
```

Se estableció la contraseña de red del usuario Samba y se habilitaron los demonios `smbd` y `nmbd`:
```bash
sudo smbpasswd -a root
sudo systemctl enable --now smbd nmbd
```

### Verificación y Pruebas
Se comprobó que el servicio estuviera activo y aceptando conexiones, además de validar el recurso compartido localmente:
```bash
sudo systemctl status smbd
smbclient //localhost/empresa -U root -c "ls"
```

![Estado del servicio Samba smbd](capturas/05_samba_estado.png)

---

## 5. Servicio de Autenticación Centralizada (NIS)

Para centralizar la administración de credenciales en los servicios internos, se implementó **NIS** (*Network Information Service*) bajo el dominio `empresa.local`, configurando los componentes de servidor (`ypserv`) y cliente (`ypbind`).

### Procedimiento de instalación y configuración
Se instaló el metapaquete NIS y se configuró el servidor local en `/etc/yp.conf`:
```bash
sudo apt install nis -y
echo "ypserver localhost" | sudo tee -a /etc/yp.conf
```

Se registró el nombre de dominio NIS en memoria y de forma persistente:
```bash
sudo domainname empresa.local
echo "empresa.local" | sudo tee /etc/defaultdomain
```

Se habilitaron los demonios `rpcbind` y `ypserv`, se compilaron los mapas maestros de usuarios y finalmente se activó el cliente `ypbind`:
```bash
sudo systemctl enable --now rpcbind ypserv
sudo /usr/lib/yp/ypinit -m
sudo systemctl enable --now ypbind
```

### Verificación y Pruebas
Se comprobó la consulta de usuarios a través de la base de datos NIS:
```bash
ypcat passwd
```
La salida retornó correctamente el listado de cuentas del sistema gestionadas bajo el dominio `empresa.local`.

![Verificación de usuarios en NIS con ypcat passwd](capturas/06_nis_ypcat.png)

---

## 6. Servidor de Impresión (CUPS)

La gestión centralizada de impresoras y colas para la emisión de certificados mercantiles se implementó con **CUPS**.

### Procedimiento de instalación y configuración
Se instaló el paquete `cups` y se otorgaron permisos de administración mediante el grupo `lpadmin`:
```bash
sudo apt install cups -y
sudo usermod -aG lpadmin root
sudo usermod -aG lpadmin antonio_viillada_7
```

Para evitar el conflicto del puerto `631` con la activación por socket en Ubuntu 24.04, se detuvo y deshabilitó `cups.socket`:
```bash
sudo systemctl stop cups.socket
sudo systemctl disable cups.socket
```

Se habilitó el servicio principal, se permitió la administración y compartición remota y se reinició el demonio:
```bash
sudo systemctl enable --now cups
sudo cupsctl --remote-any --remote-admin --share-printers
sudo systemctl restart cups.service
```

### Verificación y Pruebas
Se validó que el planificador de impresión estuviera activo y escuchando en red:
```bash
sudo systemctl status cups
```
El resultado confirmó el estado `Active: active (running)` con el mensaje `Status: "Scheduler is running..."`.

![Estado del servicio de impresión CUPS](capturas/07_cups_estado.png)

---

## 7. Solución de Problemas Encontrados

Durante el despliegue sobre Ubuntu 24.04 LTS en Google Cloud Platform se presentaron tres incidentes técnicos reales que fueron diagnosticados y resueltos:

### 7.1. Bucle de Redirección SSL (`ERR_TOO_MANY_REDIRECTS`) en Dokploy
Al habilitar HTTPS con Let's Encrypt en Dokploy para `camara.villadastudios.com`, el navegador devolvió el error `ERR_TOO_MANY_REDIRECTS`. La causa fue un conflicto de cifrado entre Traefik (que redirigía automáticamente HTTP hacia HTTPS) y Cloudflare, que operaba en modo SSL **Flexible** (conectándose al servidor origen por HTTP plano). El incidente se resolvió cambiando el modo SSL/TLS en el panel de Cloudflare a **Full (Strict)**, garantizando cifrado extremo a extremo con certificado válido.

### 7.2. Fallo de Inicialización de la Base de Datos NIS (`Local domain name not set`)
Tras instalar `nis`, el comando `ypcat passwd` falló con *"Local domain name not set"* y `ypinit -m` devolvió *"RPC: Program not registered"*. En Ubuntu 24.04 el instalador no persistió automáticamente el dominio NIS, impidiendo que `ypserv` se registrara en `rpcbind`. Se solucionó declarando manualmente el dominio (`domainname empresa.local` y `/etc/defaultdomain`), habilitando `rpcbind` e `ypserv` en orden, reconstruyendo los mapas con `/usr/lib/yp/ypinit -m` y activando posteriormente `ypbind`.

### 7.3. Conflicto de Puertos en CUPS (`status=1/FAILURE`)
Al habilitar el acceso remoto de CUPS con `cupsctl --remote-any --remote-admin --share-printers`, el servicio falló al reiniciar (`code=exited, status=1/FAILURE`). El diagnóstico reveló que `cups.socket` retenía el puerto `631` por defecto en Ubuntu 24.04, generando colisión con el demonio principal `cupsd`. Se resolvió deteniendo y deshabilitando `cups.socket` (`systemctl stop cups.socket && systemctl disable cups.socket`) y reiniciando `cups.service`, que quedó operativo en estado `active (running)`.

---

## 8. Servicios Adicionales (Puntos Opcionales)

Para reforzar la seguridad perimetral, disponibilidad y observabilidad de la infraestructura, se implementaron los cuatro puntos opcionales de la rúbrica:

### 8.1. Backup Automático Local (PostgreSQL y Directorios Compartidos)
Se desarrolló el script `/usr/local/bin/backup_camara.sh` (también respaldado en `codigo/backup_camara.sh`) y se programó en `cron` para ejecutarse diariamente a las 2:00 AM, generando copias comprimidas de PostgreSQL (`pg_dumpall` desde Docker) y de los directorios `/srv/nfs/empresa` y `/srv/samba/empresa`, con política automática de retención de 7 días.

```bash
sudo mkdir -p /var/backups/camara
sudo chmod +x /usr/local/bin/backup_camara.sh
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup_camara.sh >> /var/log/backup_camara.log 2>&1") | sudo crontab -
```

**Verificación:**
```bash
sudo /usr/local/bin/backup_camara.sh
sudo crontab -l && ls -lh /var/backups/camara
```

![Verificación de tarea cron y respaldos generados](capturas/08_backup_cron.png)

### 8.2. Monitoreo con Alertas (Google Cloud Monitoring)
En la consola de **Google Cloud Monitoring > Alerting** se creó una política de alerta para la instancia `infra-camara-server` evaluando la métrica `VM Instance > Instance > CPU utilization` con umbral superior al **85%** (`> 0.85`) y canal de notificación por correo electrónico hacia el equipo administrador.

![Política de alertas de monitoreo en GCP](capturas/09_monitoreo_gcp.png)

### 8.3. Docker Compose para Servicios Multi-Contenedor
A través de la plataforma **Dokploy** se habilitó y validó la orquestación de stacks multi-contenedor mediante **Docker Compose**, complementando los servicios contenerizados del portal institucional y la base de datos PostgreSQL.

![Servicio Docker Compose desplegado en Dokploy](capturas/10_docker_compose.png)

### 8.4. Firewall Perimetral (UFW)
Se configuró el cortafuegos **UFW** con política predeterminada de denegación entrante (`deny incoming`), asegurando primero la regla SSH (`22/tcp`) para evitar pérdida de acceso remoto, y habilitando únicamente los puertos estrictamente necesarios para los servicios desplegados:

```bash
sudo ufw allow ssh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80,443/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 123/udp
sudo ufw allow 2049
sudo ufw allow 111
sudo ufw allow 139,445/tcp
sudo ufw allow 631/tcp
sudo ufw enable
sudo ufw status
```

![Estado activo y reglas del firewall UFW](capturas/11_ufw_status.png)