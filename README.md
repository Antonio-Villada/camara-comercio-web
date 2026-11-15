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
Este repositorio contiene el diseño, justificación, arquitectura y documentación técnica de la infraestructura de TI implementada para la Cámara de Comercio de Armenia y del Quindío. El proyecto centraliza la gestión de servicios web, archivos, impresión, sincronización de tiempo y autenticación de usuarios. 

El despliegue se realizó en una instancia de Google Cloud Platform (GCP) utilizando **Ubuntu 24.04 LTS**. Se empleó **Dokploy** (PaaS) para la gestión del servidor web (Nginx) y la base de datos (PostgreSQL), junto con la implementación de servicios nativos de Linux (NTPsec, NFS, NIS, CUPS y Samba) para soportar la operación administrativa de la entidad.

## Estructura del Repositorio
* `analisis.md`: Análisis de necesidades, justificación y requerimientos técnicos.
* `diagrama.mmd`: Código fuente del diagrama de arquitectura (formato Mermaid).
* `documentacion.md`: Procedimientos de instalación, configuración, verificación y solución de problemas técnicos de todos los servicios.
* `capturas/`: Directorio con las evidencias gráficas del funcionamiento de los servicios.