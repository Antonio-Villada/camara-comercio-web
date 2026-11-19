# Proyecto Final: Administración de Infraestructura de TI

**Caso de Estudio:** Cámara de Comercio de Armenia y del Quindío

## Equipo de Trabajo
* Iván Ramiro Bañol Motato
* Jesús Antonio Villada Morales
* Jefferson Rubio
* Johana Valentina Orlas Pachón

**Institución:** Universidad del Quindío  
**Facultad:** Ingeniería de Sistemas y Computación  
**Asignatura:** Administración de Infraestructura de TI  
**Fecha:** Noviembre de 2026  

## Resumen del Proyecto
Este repositorio contiene el análisis de necesidades, diseño de arquitectura, scripts de configuración y documentación técnica de la infraestructura de TI implementada para la **Cámara de Comercio de Armenia y del Quindío**. La solución centraliza los servicios web, base de datos, compartición de archivos, impresión en red, sincronización horaria y autenticación unificada de usuarios.

El despliegue se realizó sobre una instancia en **Google Cloud Platform (GCP)** con **Ubuntu 24.04 LTS (Noble Numbat)** (`2 vCPUs`, `4 GB RAM`, `40 GB disco`). Se utilizó **Dokploy** (PaaS sobre Docker y Traefik) para alojar el portal institucional con HTTPS y la base de datos PostgreSQL, integrado con servicios nativos de Linux (**NTPsec, NFS, NIS, CUPS y Samba**). Adicionalmente, se implementaron los puntos opcionales de seguridad y continuidad operativa: **Firewall UFW, Backup automático local con Cron, Monitoreo con alertas en GCP y soporte multi-contenedor con Docker Compose**.

## Acceso a los Servicios Principales
* **Portal Web Institucional (HTTPS):** `https://camara.villadastudios.com`
* **Panel de Administración Dokploy:** `http://35.225.203.150:3000`
* **Servidor de Impresión CUPS:** `https://35.225.203.150:631`
* **Base de Datos PostgreSQL:** Red interna de Docker (puerto `5432` aislado del exterior)

## Estructura del Repositorio
```text
proyecto-final/
├── analisis.md              # Análisis de necesidades, requisitos y diagrama embebido
├── diagrama.mmd             # Código fuente del diagrama de arquitectura (Mermaid)
├── documentacion.md         # Instalación, verificación, solución de problemas y extras
├── README.md                # Resumen general e instrucciones de verificación
├── capturas/                # Evidencias gráficas de todos los servicios funcionando
└── codigo/                  # Código web, Dockerfile y script de respaldo automático
    ├── Dockerfile
    ├── index.html
    └── backup_camara.sh
```

## Instrucciones Rápidas de Verificación
Para validar el estado de toda la infraestructura desde la terminal SSH del servidor (`infra-camara-server`):

```bash
# 1. Contenedores activos (Dokploy, Traefik, Web y PostgreSQL)
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. Verificación HTTPS del portal institucional
curl -I https://camara.villadastudios.com

# 3. Estado de los servicios nativos Linux
sudo systemctl status ntpsec nfs-kernel-server smbd ypserv ypbind cups --no-pager

# 4. Pruebas funcionales de NTP y NIS
ntpq -p
ypcat passwd

# 5. Verificación de Firewall UFW y Backup automático programado
sudo ufw status
sudo crontab -l && ls -lh /var/backups/camara
```