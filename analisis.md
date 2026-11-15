# 1. Análisis de Necesidades y Diseño de Infraestructura

## 1.1 Justificación de Servicios
Para soportar la operación administrativa y los servicios al ciudadano de la Cámara de Comercio de Armenia y del Quindío, se requiere una infraestructura tecnológica robusta, segura y de alta disponibilidad. En primer lugar, se ha decidido implementar la plataforma PaaS Dokploy apoyada en el proxy inverso Traefik. Esta combinación permite el alojamiento eficiente del sitio web institucional bajo el protocolo seguro HTTPS, garantizando que el portal de trámites y la consulta de requisitos operen con confidencialidad. Como motor de base de datos se utilizará PostgreSQL, un sistema relacional de código abierto reconocido por su integridad transaccional, el cual es ideal para almacenar el registro mercantil y los datos sensibles de los afiliados sin comprometer el rendimiento.

Por otro lado, la legalidad y la auditoría son pilares en una Cámara de Comercio. Por ello, se implementará un servidor de tiempo (NTP) nativo en Linux, asegurando una sincronización horaria exacta en toda la red. Esto es vital para que las marcas de tiempo en las transacciones web, la emisión de certificados y los registros en la base de datos tengan validez legal y trazabilidad. En cuanto al manejo de la información interna, se configurará NFS como un repositorio centralizado de documentos legales, cuyo acceso será exclusivo y optimizado para los servidores Linux de la entidad.

Finalmente, para el entorno de trabajo diario de los funcionarios, se desplegará un servidor Samba que permitirá al personal administrativo colaborar y compartir documentos ofimáticos desde estaciones de trabajo Windows y macOS. La seguridad de acceso a todos estos recursos internos estará centralizada mediante NIS (Network Information Service), evitando la administración descentralizada de credenciales. El ecosistema se completa con la implementación de CUPS, un servidor de impresión que centralizará y gestionará las colas de impresión para la emisión física de certificados mercantiles en las oficinas de atención presencial.

## 1.2 Requisitos Técnicos

| Servicio | Dominio / IP | Puerto | Protocolo | Tipo de Servicio |
| :--- | :--- | :--- | :--- | :--- |
| **Web Server** | `camara.villadastudios.com` | 80/443 | HTTP/HTTPS | Dokploy (Contenedor) |
| **PostgreSQL** | Interna (Dokploy) | 5432 | TCP | Dokploy (Contenedor) |
| **Panel Admin** | `35.225.203.150` | 3000 | TCP | Dokploy UI |
| **NTP** | Red Local / IP Servidor | 123 | UDP | Linux Nativo |
| **NFS** | Red Local / IP Servidor | 2049 | TCP/UDP | Linux Nativo |
| **NIS** | Red Local / IP Servidor | 111 / YPSERV | TCP/UDP | Linux Nativo |
| **CUPS** | Red Local / IP Servidor | 631 | TCP | Linux Nativo |
| **Samba** | Red Local / IP Servidor | 139/445 | TCP | Linux Nativo |