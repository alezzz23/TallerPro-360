# Plan de Tareas — TallerPro 360

> Estado actual: **Fase de scaffolding**. Documentación completa, infraestructura Docker lista, pero 0% de lógica de negocio implementada.

---

## FASE 1 — Fundación Backend (API)

### 1.1 Configuración de Base de Datos y Migraciones
- [ ] Inicializar Alembic (`alembic init`)
- [ ] Configurar `alembic/env.py` con la conexión a PostgreSQL
- [ ] Crear session/engine de SQLModel en un módulo `database.py`
- [ ] Verificar conexión API ↔ PostgreSQL

### 1.2 Modelos de Dominio (SQLModel)
- [ ] `User` — id, nombre, email, password_hash, rol (TECNICO, ASESOR, JEFE_TALLER, ADMIN), activo
- [ ] `Customer` — id, nombre, teléfono, email, dirección, WhatsApp
- [ ] `Vehicle` — id, customer_id (FK), marca, modelo, placa, VIN, kilometraje, color
- [ ] `ServiceOrder` — id, vehicle_id (FK), advisor_id (FK), estado (RECEPCION, DIAGNOSTICO, APROBACION, REPARACION, QC, ENTREGA, CERRADA), fecha_ingreso, fecha_salida, kilometraje_ingreso, kilometraje_salida
- [ ] `ReceptionChecklist` — id, order_id (FK), nivel_aceite, nivel_refrigerante, nivel_frenos, llanta_repuesto, kit_carretera, botiquin, extintor, documentos_recibidos, firma_cliente_url
- [ ] `DamageRecord` — id, order_id (FK), ubicacion, descripcion, foto_url, reconocido_por_cliente
- [ ] `PerimeterPhoto` — id, order_id (FK), angulo (FRONTAL, TRASERO, IZQUIERDO, DERECHO), foto_url
- [ ] `DiagnosticFinding` — id, order_id (FK), technician_id (FK), motivo_ingreso, descripcion, tiempo_estimado, fotos (JSON array max 10)
- [ ] `Part` — id, finding_id (FK), nombre, origen (STOCK, PEDIDO), costo, margen, precio_venta, proveedor
- [ ] `Quotation` — id, order_id (FK), subtotal, impuestos, total, shop_supplies, descuento, estado (PENDIENTE, APROBADA, RECHAZADA), fecha_envio
- [ ] `QuotationItem` — id, quotation_id (FK), finding_id (FK), part_id, descripcion, mano_obra, costo_repuesto, precio_final
- [ ] `QualityCheck` — id, order_id (FK), inspector_id (FK), items_verificados (JSON), aprobado, fecha
- [ ] `Invoice` — id, order_id (FK), monto_total, metodo_pago, es_credito, saldo_pendiente, fecha
- [ ] `NPSSurvey` — id, order_id (FK), atencion, instalaciones, tiempos, precios, recomendacion (1-10), comentarios
- [ ] `AuditLog` — id, user_id, order_id, accion, detalle, dispositivo, timestamp
- [ ] `Appointment` — id, customer_id, vehicle_id, fecha, bloque_horario, motivo, estado
- [ ] Generar migración inicial con Alembic y aplicar

### 1.3 Autenticación y Autorización
- [ ] Instalar `python-jose` y `passlib[bcrypt]`
- [ ] Endpoint `POST /api/v1/auth/register`
- [ ] Endpoint `POST /api/v1/auth/login` → JWT token
- [ ] Dependency `get_current_user` para FastAPI
- [ ] Middleware de roles (TECNICO, ASESOR, JEFE_TALLER, ADMIN)
- [ ] Endpoint `GET /api/v1/auth/me`

### 1.4 CRUD de Entidades Base
- [ ] Routers: `customers.py`, `vehicles.py`, `users.py`
- [ ] `POST/GET/PUT/DELETE /api/v1/customers`
- [ ] `POST/GET/PUT/DELETE /api/v1/vehicles`
- [ ] `GET /api/v1/users` (solo admin)
- [ ] Schemas Pydantic de request/response para cada entidad
- [ ] Paginación genérica (limit/offset)

---

## FASE 2 — Flujo de Órdenes de Servicio

### 2.1 Agendamiento (FR-01, FR-02, FR-03)
- [ ] `POST /api/v1/appointments` — Crear cita con bloque horario
- [ ] `GET /api/v1/appointments?date=YYYY-MM-DD` — Listar citas del día
- [ ] `PUT /api/v1/appointments/{id}/cancel`
- [ ] Validación de conflicto de bloques horarios

### 2.2 Recepción Activa (FR-04, FR-05, FR-06)
- [ ] `POST /api/v1/orders` — Crear orden de servicio desde cita o walk-in
- [ ] `POST /api/v1/orders/{id}/reception-checklist` — Guardar checklist de recepción
- [ ] `POST /api/v1/orders/{id}/damages` — Registrar daños preexistentes con fotos
- [ ] `POST /api/v1/orders/{id}/perimeter-photos` — Subir fotos de 4 ángulos
- [ ] `POST /api/v1/orders/{id}/client-signature` — Registrar firma/aprobación digital del cliente
- [ ] Endpoint de subida de archivos (fotos) con almacenamiento local o S3
- [ ] Validación: no avanzar sin checklist + fotos de perímetro + firma

### 2.3 Diagnóstico Técnico (FR-07, FR-08, FR-09)
- [ ] `GET /api/v1/orders/{id}/findings` — Listar hallazgos
- [ ] `POST /api/v1/orders/{id}/findings` — Crear hallazgo con evidencia
- [ ] `PUT /api/v1/findings/{id}` — Actualizar hallazgo
- [ ] `POST /api/v1/findings/{id}/photos` — Subir hasta 10 fotos por hallazgo
- [ ] Asignación de hallazgo a técnico diferente si aplica
- [ ] Cambiar estado de orden a DIAGNOSTICO

### 2.4 Repuestos y Cotización (FR-10, FR-11, FR-12)
- [ ] `POST /api/v1/orders/{id}/quotation` — Generar cotización
- [ ] Lógica de cálculo de margen: `precio = costo / (1 - margen)`
- [ ] Diferenciación Stock vs. Pedido en repuestos
- [ ] Shop Supplies como cargo adicional
- [ ] `PUT /api/v1/quotations/{id}/discount` — Aplicar descuento y reenviar
- [ ] Generación de PDF de cotización

### 2.5 Aprobación Digital (FR-12, FR-13)
- [ ] `POST /api/v1/quotations/{id}/approve` — Cliente aprueba
- [ ] `POST /api/v1/quotations/{id}/reject` — Cliente rechaza (con log de razón)
- [ ] Registro de rechazo crítico de seguridad con advertencia legal
- [ ] Log permanente con timestamp para rechazos de seguridad
- [ ] Cambiar estado de orden a APROBACION → REPARACION

### 2.6 Control de Calidad (FR-14, FR-15, FR-16)
- [ ] `POST /api/v1/orders/{id}/qc` — Checklist dinámico con solo ítems aprobados
- [ ] Registro de kilometraje y fluidos de salida (segundo punto de transferencia)
- [ ] Comparación automática ingreso vs. salida
- [ ] Cambiar estado de orden a QC → ENTREGA

### 2.7 Facturación y NPS (FR-17, FR-18)
- [ ] `POST /api/v1/orders/{id}/invoice` — Generar factura
- [ ] Soporte para "Venta a Crédito" con saldo pendiente
- [ ] `POST /api/v1/orders/{id}/nps` — Capturar encuesta NPS
- [ ] Bloqueo: no cerrar orden sin NPS completada
- [ ] `PUT /api/v1/orders/{id}/close` — Cerrar orden

---

## FASE 3 — Tiempo Real y Notificaciones

### 3.1 WebSockets
- [ ] Configurar WebSocket endpoint en FastAPI (`/ws`)
- [ ] Broadcast de cambios de estado de orden en tiempo real
- [ ] Notificación Push al asesor de repuestos cuando técnico completa diagnóstico
- [ ] Autenticación de WebSocket con JWT token

### 3.2 PostgreSQL pg_notify
- [ ] Configurar triggers en Postgres para cambios de estado de orden
- [ ] Listener en backend que escucha `pg_notify` y reenvía por WebSocket
- [ ] Canal de eventos por tipo (orden, diagnóstico, cotización)

### 3.3 Integración WhatsApp
- [ ] Servicio de envío de mensajes WhatsApp (API Business o Twilio)
- [ ] Envío automático de link de aprobación de cotización
- [ ] Notificación automática de vehículo listo (FR-16)
- [ ] Instrucción de guardar número corporativo (FR-12)

---

## FASE 4 — Analytics y Auditoría

### 4.1 Sistema de Auditoría
- [ ] Middleware de logging automático (quién, qué, cuándo, dispositivo)
- [ ] Modelo `AuditLog` con registro segundo a segundo
- [ ] `GET /api/v1/audit?order_id=X` — Consultar trazabilidad

### 4.2 KPIs y Reportes
- [ ] `GET /api/v1/analytics/profitability` — Rentabilidad neta por orden
- [ ] `GET /api/v1/analytics/technician-productivity` — Horas producidas vs disponibles
- [ ] `GET /api/v1/analytics/pareto` — Top 5 fallas/quejas recurrentes
- [ ] `GET /api/v1/analytics/avg-ticket` — Ticket promedio mensual
- [ ] `GET /api/v1/analytics/dashboard` — Resumen ejecutivo para Admin/Dueño

---

## FASE 5 — Frontend Mobile (Flutter)

### 5.1 Arquitectura y Configuración
- [ ] Instalar dependencias: `riverpod`, `dio`, `go_router`, `drift`, `freezed`, `json_annotation`
- [ ] Configurar estructura de carpetas Clean Architecture:
  - `lib/core/` (theme, constants, utils, network)
  - `lib/features/` (auth, dashboard, reception, diagnosis, quotation, qc, billing)
  - `lib/shared/` (widgets, models compartidos)
- [ ] Configurar tema Material con paleta semántica (Azul=Pendiente, Amarillo=Proceso, Verde=Listo)
- [ ] Configurar `go_router` con rutas nombradas y guards de autenticación
- [ ] Cliente HTTP con Dio + interceptor JWT
- [ ] Configuración de Riverpod como state management

### 5.2 Autenticación
- [ ] Pantalla de Login (email + contraseña)
- [ ] Flujo de JWT: guardar token en secure storage
- [ ] Guard de navegación (redirigir a login si no hay sesión)
- [ ] Vista diferenciada por rol al iniciar sesión

### 5.3 Dashboard (Kanban Board)
- [ ] Pantalla principal tipo Kanban con columnas: Recepción → Diagnóstico → Aprobación → Reparación → QC → Entrega
- [ ] Tarjetas de vehículos con color semántico por estado
- [ ] Drag & drop para mover tarjetas entre fases (con permisos por rol)
- [ ] Filtros por técnico, asesor, fecha
- [ ] Badge de notificaciones no leídas

### 5.4 Recepción Activa
- [ ] Formulario de datos del vehículo (marca, modelo, placa, VIN, km)
- [ ] Autocompletado si el vehículo ya existe (por placa o VIN)
- [ ] Checklist interactivo de recepción (fluidos, pertenencias, documentos)
- [ ] Marcado visual de daños en diagrama del vehículo
- [ ] Captura de fotos de perímetro (4 ángulos obligatorios)
- [ ] Widget de firma digital del cliente
- [ ] Dictado por voz para motivo de visita (FR-02)

### 5.5 Diagnóstico (Vista Técnico)
- [ ] Lista de motivos de ingreso individuales
- [ ] Formulario por hallazgo: descripción, tiempo estimado, repuestos necesarios
- [ ] Galería de fotos por hallazgo (max 10)
- [ ] Botón "Reportar Hallazgo Adicional"
- [ ] Asignación de hallazgo a otro técnico

### 5.6 Cotización y Aprobación
- [ ] Vista del asesor: agregar costos, cálculo automático de margen e impuestos
- [ ] Preview de cotización antes de enviar
- [ ] Botón de enviar cotización por WhatsApp
- [ ] Vista del cliente (web): aprobar/rechazar ítems individualmente
- [ ] Flujo de descuento y reenvío si el cliente rechaza

### 5.7 Control de Calidad
- [ ] Checklist dinámico con solo ítems aprobados por el cliente
- [ ] Registro de km y fluidos de salida
- [ ] Comparación visual ingreso vs salida
- [ ] Botón de aprobación final por jefe de taller

### 5.8 Facturación y NPS
- [ ] Pantalla de generación de factura
- [ ] Selector de método de pago (efectivo, tarjeta, crédito)
- [ ] Formulario NPS con 5 categorías + escala 1-10
- [ ] Bloqueo de cierre sin NPS completada

### 5.9 Base de Datos Local (Offline-First)
- [ ] Configurar Drift (SQLite) para almacenamiento local
- [ ] Tablas espejo de las entidades principales
- [ ] Cola de sincronización: registrar operaciones offline
- [ ] Sync engine: enviar cola al servidor al recuperar conexión
- [ ] Resolución de conflictos básica (last-write-wins o CRDTs simplificado)

---

## FASE 6 — Interfaz Web (Panel Administrativo) (POR DISCUTIR)

### 6.1 Panel de Repuestos (Asesor de Repuestos)
- [ ] Decidir framework web (Flutter Web o React)
- [ ] Dashboard de partes pendientes por solicitar
- [ ] Gestión de proveedores y cotizaciones de repuestos
- [ ] Control de inventario (stock)

### 6.2 Dashboard Remoto (Dueño/Admin)
- [ ] KPIs en tiempo real (órdenes activas, ticket promedio, rentabilidad)
- [ ] Gráficas de productividad por técnico
- [ ] Pareto de fallas recurrentes
- [ ] Gestión de usuarios y roles

### 6.3 Portal del Cliente (Vía WhatsApp Link)
- [ ] Página web responsiva para aprobar/rechazar cotización
- [ ] Visualización del estado del vehículo en tiempo real
- [ ] Historial de servicios anteriores

---

## FASE 7 — Testing

### 7.1 Backend
- [ ] Tests unitarios de lógica de negocio (cálculo de márgenes, validaciones)
- [ ] Tests de integración de endpoints con `httpx` + `pytest`
- [ ] Tests de modelos y migraciones
- [ ] Coverage mínimo: 80%

### 7.2 Mobile
- [ ] Tests unitarios de providers/viewmodels (Riverpod)
- [ ] Tests de widgets (formularios, checklist, kanban)
- [ ] Tests de integración (flujo login → dashboard → recepción)
- [ ] Golden tests para consistencia visual

---

## FASE 8 — DevOps y Despliegue

### 8.1 CI/CD
- [x] GitHub Actions: lint + test en cada PR
- [x] Build automático de APK/IPA en merge a main
- [x] Deploy automático del backend a staging

### 8.2 Infraestructura de Producción
- [x] Dockerizar el backend FastAPI
- [x] Agregar servicio de backend al `compose.yml`
- [x] Configurar volúmenes para almacenamiento de fotos
- [x] Variables de entorno para producción (secrets)
- [x] Configurar HTTPS/TLS (Railway termina TLS; compose local queda en HTTP)
- [x] Backup automático de PostgreSQL

### 8.3 Monitoreo
- [x] Logging estructurado (JSON logs)
- [x] Health checks y alertas
- [x] Métricas de rendimiento del API

---

## Resumen por Fase

| Fase | Descripción | Complejidad |
|------|-------------|-------------|
| **1** | Fundación Backend (DB, Modelos, Auth, CRUD) | Alta |
| **2** | Flujo completo de Órdenes de Servicio | Muy Alta |
| **3** | Tiempo Real (WebSockets, pg_notify, WhatsApp) | Alta |
| **4** | Analytics y Auditoría | Media |
| **5** | Frontend Mobile completo (Flutter) | Muy Alta |
| **6** | Interfaz Web (Panel Admin + Portal Cliente) | Alta |
| **7** | Testing completo | Media |
| **8** | DevOps y Despliegue | Media |

---

## Dependencias entre Fases

```
Fase 1 ──→ Fase 2 ──→ Fase 3
  │            │          │
  │            ▼          │
  │        Fase 4 ◄───────┘
  │
  ▼
Fase 5 (puede iniciar en paralelo con Fase 2)
  │
  ▼
Fase 6
  │
  ▼
Fase 7 (continuo, desde Fase 1)
  │
  ▼
Fase 8
```

> **Nota:** Fase 5 (Flutter) puede comenzar en paralelo con Fase 2 una vez que Fase 1 esté completa, ya que los endpoints del backend se van construyendo incrementalmente.
