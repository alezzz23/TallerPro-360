Especificación de Requerimientos de Producto (PRD): Ecosistema Digital TallerPro360

1. Visión General y Objetivos del Producto

El propósito de este ecosistema es digitalizar y estandarizar la operación de talleres automotrices, transformando la gestión informal en un proceso de "Blindaje Legal" y alta rentabilidad. El sistema no es solo una herramienta administrativa, sino un motor de procesos diseñado para garantizar que el taller sea productivo, transparente y defendible ante cualquier litigio legal.

Pilares Estratégicos

* Productividad Operativa: Eliminación de cuellos de botella mediante la sincronización en tiempo real entre el asesor de servicio, el técnico y el asesor de repuestos.
* Rentabilidad y Conversión de Ventas: Uso de la "Recepción Activa" como herramienta de venta objetiva (ej. uso de probadores de líquido de frenos frente al cliente) para incrementar el ticket promedio mediante evidencia.
* Blindaje Legal y Trazabilidad: Protección total del establecimiento mediante la "Transferencia de Responsabilidad Crítica", documentando el estado exacto de entrada y salida para asegurar que el taller "nunca pierda en una corte".

2. Perfiles de Usuario (User Personas)

Rol	Responsabilidad Principal	Herramienta Clave / Acceso
Asesor de Servicio	Gestión de clientes, recepción activa, venta cruzada y cumplimiento de la agenda.	App Móvil (Gestión de Campo)
Técnico Mecánico	Diagnóstico preciso, ejecución de reparaciones y generación de evidencia técnica.	App Móvil (Módulo de Taller)
Asesor de Repuestos	Gestión del "embudo" de partes, cotización con proveedores y control de inventario.	Panel Web (Gestión de Compras)
Dueño / Administrador	Supervisión de KPIs de alto nivel y rentabilidad neta desde cualquier ubicación.	Dashboard Remote (Acceso Ubicuo)
Cliente Final	Aprobación granular de presupuestos y seguimiento transparente del proceso.	Interfaz Web (Vía WhatsApp Link)

3. Módulo de Agendamiento y Registro Inicial

FR-01: Gestión de Agenda por Bloques. El sistema SHALL permitir el agendamiento de citas en bloques de tiempo configurables (ej. intervalos de 15 minutos). Esto es mandatorio para mitigar el estrés del asesor de servicio y evitar el colapso operativo en horas pico.

FR-02: Registro de Ingreso con Dictado por Voz. La interfaz móvil SHALL integrar funcionalidad de dictado (Voice-to-Text) para capturar el motivo de la visita, optimizando la agilidad en la recepción.

FR-03: Datos Mandatorios del Vehículo. Para proceder con la Orden de Servicio (OS), el sistema SHALL exigir: Marca, Modelo/Prototipo, Matrícula (Placa) y Kilometraje. Una vez registrados, estos datos SHALL persistir para visitas futuras, eliminando la redundancia en la captura de datos.

4. Recepción Activa y Transferencia de Responsabilidad

Este módulo constituye el núcleo de protección legal del taller. Se basa en el principio de que cualquier daño no documentado al ingreso es responsabilidad del taller ante la ley.

FR-04: Checklist de Recepción Avanzada. El sistema SHALL obligar al registro de:

* Nivel de Fluidos Comparativo: Registro de niveles de aceite, refrigerante y líquido de frenos al ingreso.
* Inventario de Pertenencias: Confirmación de llanta de repuesto, kit de carretera, herramientas, botiquín y extintor.
* Documentación Recibida: Registro específico de documentos físicos dejados por el cliente (Seguro, Tarjeta de Propiedad).

FR-05: Documentación de Daños Pre-existentes. El asesor SHALL marcar visualmente en la aplicación cualquier daño estético (ej. golpe en capó). El sistema SHALL requerir que el cliente reconozca digitalmente estos daños para liberar al taller de responsabilidad.

FR-06: Evidencia Fotográfica de Perímetro. La aplicación SHALL forzar la toma de fotografías de los cuatro ángulos del vehículo y de los puntos críticos reportados antes de finalizar el ingreso.

5. Módulo de Diagnóstico Técnico y Hallazgos Adicionales

FR-07: Flujo de Diagnóstico Individual. El sistema SHALL presentar al técnico cada motivo de ingreso de forma independiente para su diagnóstico detallado.

FR-08: Reporte de Nuevas Fallas. El técnico SHALL tener acceso a un botón de "Reportar Hallazgo Adicional". El sistema SHALL permitir asignar estos nuevos hallazgos a diferentes técnicos si la especialidad lo requiere (ej. un mecánico reportando una falla eléctrica).

FR-09: Gestión de Evidencia Técnica. El sistema SHALL permitir la carga de hasta 10 fotos por hallazgo.

* Persistencia de Sesión: El sistema SHALL garantizar que, si la aplicación se cierra o pierde conexión durante la carga, los datos no se pierdan. Se recomienda la captura previa en galería y carga posterior para máxima estabilidad.

6. Gestión de Repuestos y Cálculo Automático de Márgenes

El Asesor de Repuestos actúa como el controlador del flujo de trabajo. El sistema SHALL enviar notificaciones Push automáticas al Asesor de Repuestos en el momento exacto en que un técnico finaliza un diagnóstico.

FR-10: Lógica de Precios y Margen sobre Venta. El sistema SHALL automatizar el cálculo de precios para evitar errores humanos.

* Fórmula Mandatoria: Si el costo es 100 y el margen deseado es 30%, el sistema SHALL calcular el precio de venta antes de impuestos como **142.85** ($100 / (1 - 0.70)), no como $130.
* Diferenciación de Origen: El sistema SHALL distinguir entre repuestos de "Stock" (vinculados a facturas de compra previas) y "Compra por Pedido" (donde se solicita ingresar el costo del proveedor en tiempo real).

FR-11: Shop Supplies. El sistema SHALL permitir la adición de cargos por insumos menores (Shop Supplies) para la recuperación de costos operativos indirectos.

7. Aprobación Digital y Estrategia de Comunicación

FR-12: Sincronización de Contactos WhatsApp. Al enviar la cotización, el sistema SHALL incluir una instrucción mandatoria para que el cliente guarde el número corporativo del taller. Esto es crítico para activar el link de aprobación y habilitar futuras campañas de marketing evitando filtros de spam.

FR-13: Registro de Rechazo Crítico. Si un cliente rechaza una reparación catalogada como "De Seguridad" (ej. manguera de radiador a punto de estallar o frenos desgastados), el sistema SHALL:

1. Generar un log permanente con marca de tiempo.
2. Emitir una advertencia legal explícita en el visor del cliente.
3. Incluir dicho rechazo en el documento PDF final para blindaje legal en caso de fallas posteriores.

8. Control de Calidad (QC) y Entrega

FR-14: Verificación Basada en Aprobación. El checklist de QC SHALL poblarse dinámicamente utilizando únicamente los ítems que el cliente aprobó. No se exigirá verificación de ítems rechazados.

FR-15: Segundo Punto de Transferencia. Al finalizar el QC, el sistema SHALL requerir un registro final de kilometraje y niveles de fluidos de salida para comparación con los datos de ingreso.

FR-16: Notificación Automática de Listo. El sistema SHALL disparar un mensaje de WhatsApp automatizado al cliente en el momento en que el vehículo aprueba el QC y pasa a la fase de entrega.

9. Facturación y Encuesta NPS

FR-17: Cuentas por Cobrar (CxC). El sistema SHALL permitir marcar facturas como "Venta a Crédito", manteniendo un saldo pendiente vinculado al perfil del cliente.

FR-18: Encuesta de Satisfacción Mandatoria. El sistema SHALL bloquear el cierre total de la orden hasta que se active la encuesta NPS (Net Promoter Score). El asesor SHALL capturar la percepción del cliente sobre: Atención, Instalaciones, Tiempos, Precios y Probabilidad de Recomendación (1-10) antes de la entrega física de las llaves.

10. Analytics y Trazabilidad de Auditoría

El sistema SHALL mantener un "Reporte de Operaciones" detallado con los siguientes KPIs y logs:

Reporte	Requerimiento de Datos (Audit Log)
Trazabilidad Total	Registro segundo-a-segundo: Quién registró, quién aprobó, qué dispositivo se usó, cambios de estatus.
Rentabilidad Neta	Cálculo real: Venta final - Costo de repuestos - Mano de obra técnica.
Productividad Técnica	Horas producidas vs. Horas disponibles; ingresos generados por técnico.
Matriz de Pareto	Identificación de las 5 fallas o quejas más recurrentes para toma de decisiones.
Ticket Promedio	Valor medio de las órdenes de servicio por mes vencido.

11. Reglas de Negocio y Restricciones Técnicas

* Restricción de Flujo: El sistema SHALL impedir el inicio de reparaciones si no existe una firma o aprobación digital registrada en el sistema.
* Sincronización en Tiempo Real: Los cambios realizados en el panel web (oficina) SHALL reflejarse instantáneamente en los dispositivos móviles (taller) y viceversa.
* Persistencia Histórica: Todos los registros, incluyendo fotos de diagnósticos de años anteriores, SHALL ser almacenados de forma permanente y ser consultables por matrícula para casos de garantías o demandas legales recurrentes.
