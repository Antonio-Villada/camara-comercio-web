# Documentación Técnica de Servicios de Infraestructura

## Justificación de Versiones y Entorno de Despliegue
La rúbrica del proyecto establece como requisito el uso de **Ubuntu Server 22.04/24.04 LTS**. Para esta implementación, se tomó la decisión estratégica de utilizar **Ubuntu 24.04 LTS (Noble Numbat)** alojado en Google Cloud Platform (GCP), en lugar de una máquina virtual local. Esta decisión se fundamenta en los siguientes aspectos:

1. **Continuidad del Entorno:** Se aprovechó la instancia aprovisionada y configurada exitosamente durante el Entregable 2 (Infraestructura Base), garantizando la estabilidad de la plataforma Dokploy ya desplegada.
2. **Colaboración en Equipo:** El despliegue en la nube mediante GCP permitió que todos los miembros del equipo (Iván, Jesús, Jefferson y Johana) tuvieran acceso simultáneo y remoto a la misma terminal SSH y al panel de control, facilitando la colaboración en tiempo real y la resolución conjunta de los problemas técnicos.
3. **Vigencia Tecnológica:** El uso de Ubuntu 24.04 LTS asegura el acceso a los repositorios de paquetes más recientes y brinda soporte a largo plazo (hasta 2029), alineando el proyecto con los estándares actuales de la industria.

La adopción de Ubuntu 24.04 LTS requirió ciertas adaptaciones respecto a la guía original (basada en versiones anteriores). Para ello, se investigó la sintaxis correcta en los foros de la comunidad de Ubuntu (Ask Ubuntu) y en la documentación oficial de los proyectos (Linux man pages, CUPS documentation).

---

## 1. Plataforma de Contenedores y Web Institucional
Para el despliegue del sitio web institucional y el motor de base de datos PostgreSQL, se utilizó **Dokploy** como gestor de infraestructura. La aplicación web fue empaquetada mediante un archivo `Dockerfile` basado en el servidor web Nginx, exponiendo el tráfico interno. Se configuró un proxy inverso nativo, asignando el subdominio `camara.villadastudios.com` y asegurando el tráfico mediante un certificado SSL emitido por Let's Encrypt, operando en conjunto con el modo estricto de Cloudflare.

---

## 2. Servidor de Tiempo (NTP)
Para mantener la coherencia temporal de los logs de auditoría y las transacciones de la Cámara de Comercio, se configuró el Network Time Protocol (NTP).

### Procedimiento de instalación y configuración
Se instaló el paquete actualizado para Ubuntu 24.04 (`ntpsec`) mediante:
```bash
sudo apt install ntpsec -y
```

Se modificó el archivo principal de configuración (`/etc/ntpsec/ntp.conf`) para incluir la sincronización con el pool global:
```text
server pool.ntp.org iburst
```

Finalmente, se habilitó y reinició el servicio para aplicar los cambios:
```bash
sudo systemctl enable --now ntpsec
```

### Verificación y Pruebas
Se utilizó la herramienta de monitoreo de red `ntpq` con la bandera `-p` para comprobar la comunicación con los servidores. La tabla de resultados mostró métricas estables de alcance, retraso y fluctuación. *(Ver captura de evidencia en la carpeta `capturas/`)*.

---

## 3. Compartición de Archivos para Entornos Linux (NFS)
Para habilitar la transferencia centralizada de archivos legales exclusivos del ecosistema Linux, se implementó el servicio NFS (Network File System).

### Procedimiento de instalación y configuración
Se instaló el paquete del servidor y se aprovisionó el directorio raíz:
```bash
sudo apt install nfs-kernel-server -y
sudo mkdir -p /srv/nfs/empresa
```

Se configuraron los permisos de exportación inyectando la directiva de acceso en el archivo de control. Se utilizó un comodín de red (`*`) para evitar bloqueos en el entorno cloud, junto con los parámetros requeridos de lectura/escritura y sincronización:
```bash
echo "/srv/nfs/empresa *(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
```

Se aplicó la configuración y se habilitó el servicio:
```bash
sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server
```

### Verificación y Pruebas
Se comprobó la correcta exportación del directorio y el funcionamiento del servicio mediante `systemctl status nfs-kernel-server`, arrojando un estado `active (running)`. *(Ver captura de evidencia en la carpeta `capturas/`)*.

---

## 4. Compartición de Archivos Multiplataforma (Samba)
Para garantizar el trabajo colaborativo de los funcionarios administrativos desde estaciones Windows y macOS, se desplegó un servidor Samba.

### Procedimiento de instalación y configuración
Se instalaron los paquetes del servidor y utilidades cliente, y se creó el directorio destino:
```bash
sudo apt install samba smbclient -y
sudo mkdir -p /srv/samba/empresa
```

Se aisló el acceso únicamente a usuarios autorizados creando el grupo de red y vinculando al administrador:
```bash
sudo groupadd sambausers
sudo usermod -aG sambausers root
```

Se configuró el recurso compartido añadiendo el siguiente bloque al archivo `/etc/samba/smb.conf`:
```ini
[empresa]
   path = /srv/samba/empresa
   browseable = yes
   writable = yes
   guest ok = no
   valid users = @sambausers
```

Se asignó la credencial de red mediante `sudo smbpasswd -a root` y se reiniciaron los demonios `smbd` y `nmbd` para aplicar los cambios.

### Verificación y Pruebas
Se comprobó la disponibilidad del servicio ejecutando `systemctl status smbd`, el cual mostró el estado "ready to serve connections...". *(Ver captura de evidencia `image_a3de66.png` en la carpeta `capturas/`)*.

---

## 5. Servicio de Autenticación Centralizada (NIS)
Para centralizar la gestión de credenciales, se implementó el protocolo de información de red (NIS), separando los componentes de servidor (`ypserv`) y cliente (`ypbind`) según la arquitectura de Ubuntu 24.04.

### Procedimiento de instalación y configuración
Se instaló el metapaquete NIS:
```bash
sudo apt install nis -y
```

Se inyectó la configuración de apuntamiento local en el archivo cliente:
```bash
echo "ypserver localhost" | sudo tee -a /etc/yp.conf
```

Para evitar fallos en la inicialización, se forzó el registro persistente del nombre de dominio NIS (`empresa.local`):
```bash
sudo domainname empresa.local
echo "empresa.local" | sudo tee /etc/defaultdomain
```

Se habilitaron los demonios del servidor y el asignador de puertos:
```bash
sudo systemctl enable --now rpcbind ypserv
```

Se construyeron los mapas maestros de la base de datos de usuarios:
```bash
sudo /usr/lib/yp/ypinit -m
```

Finalmente, se encendió el cliente local para leer la nueva base de datos:
```bash
sudo systemctl enable --now ypbind
```

### Verificación y Pruebas
Se validó la disponibilidad de las credenciales de red ejecutando `ypcat passwd`, comando que retornó la lista completa de usuarios del sistema. *(Ver captura de evidencia en la carpeta `capturas/`)*.

---

## 6. Servidor de Impresión (CUPS)
La administración de colas de impresión se delegó al sistema CUPS.

### Procedimiento de instalación y configuración
Se instaló el servidor de impresión y se asignaron privilegios de administración:
```bash
sudo apt install cups -y
sudo usermod -aG lpadmin root
sudo usermod -aG lpadmin antonio_viillada_7
```

Se solucionó el conflicto de puertos nativo de Ubuntu 24.04 deshabilitando el socket por defecto del sistema:
```bash
sudo systemctl stop cups.socket
sudo systemctl disable cups.socket
```

Se reinició el servicio principal y se configuró el puerto 631 para administración y compartición remota:
```bash
sudo systemctl enable --now cups
sudo cupsctl --remote-any --remote-admin --share-printers
```

### Verificación y Pruebas
Se verificó que el servicio estuviese activo y escuchando conexiones externas utilizando `systemctl status cups`, mostrando el estado "Scheduler is running...". *(Ver captura de evidencia en la carpeta `capturas/`)*.

---

## 7. Solución de Problemas Encontrados

Durante la implementación técnica del proyecto, se presentaron y resolvieron los siguientes incidentes:

### Bucle de Redirección SSL en Dokploy
Al activar el certificado SSL/TLS de Let's Encrypt en Dokploy para el dominio `camara.villadastudios.com`, el portal quedó inaccesible arrojando un error `ERR_TOO_MANY_REDIRECTS`. Esto se debió a un conflicto de cifrado entre el proxy Traefik (Dokploy) y la CDN de Cloudflare (configurada en modo "Flexible"), lo que generó un bucle infinito de redirección de HTTP a HTTPS. La incidencia se solucionó accediendo al panel SSL/TLS de Cloudflare y modificando el modo de encriptación a "Full (Strict)".

### Fallo en la Inicialización de la Base de Datos NIS
Tras instalar el paquete `nis`, el comando `ypcat passwd` falló indicando *"Local domain name not set"*, y la inicialización de la base maestra con `ypinit -m` devolvió el error *"RPC: Program not registered"*. La causa fue que Ubuntu 24.04 no guardó el nombre de dominio de forma persistente, impidiendo el arranque del demonio `ypserv`. Se solucionó documentando y aplicando un procedimiento manual para declarar el dominio (`domainname empresa.local`), levantar los servicios rpcbind e ypserv, y finalmente inicializar la base de datos de usuarios (`/usr/lib/yp/ypinit -m`).

### Conflicto de Puertos en el Servidor de Impresión CUPS
Al intentar habilitar la administración remota de CUPS mediante `cupsctl --remote-any`, el servicio colapsó (`status=1/FAILURE`). El análisis reveló que el puerto 631 estaba bloqueado por un componente en segundo plano nativo de Ubuntu 24.04 (`cups.socket`), creando un choque de servicios. Para resolverlo, se detuvo y deshabilitó el socket nativo de Ubuntu (`systemctl stop cups.socket`), permitiendo así reiniciar el demonio de impresión (`systemctl restart cups.service`), el cual tomó el control del puerto de manera exitosa.