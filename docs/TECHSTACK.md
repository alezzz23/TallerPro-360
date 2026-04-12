**Documento de Diseño Técnico: Stack Tecnológico (TechStack DOC)**

**1. Introducción y Visión General**
Este documento define la arquitectura y el stack tecnológico para la aplicación móvil de gestión de talleres mecánicos. El objetivo es construir un sistema robusto, con sincronización en tiempo real y capacidad de funcionamiento sin conexión (Offline-First), utilizando exclusivamente tecnologías de código abierto o independientes de proveedores específicos (sin Firebase ni Supabase). Además, la arquitectura está diseñada con componentes tipados y patrones claros para facilitar la generación de código mediante modelos de Inteligencia Artificial (LLMs).

**2. Arquitectura Frontend (Aplicación Móvil)**
*   **Framework:** **Flutter**. Permite compilar código nativo para iOS y Android con un único motor de renderizado, garantizando alta consistencia visual y rendimiento.
*   **Patrón de Arquitectura:** **MVVM (Model-View-ViewModel)** o **Clean Architecture**. MVVM divide la lógica en Modelo (datos), Vista (interfaz) y ViewModel (intermediario que maneja la lógica de presentación), lo que facilita el "data binding" y permite a los LLMs estructurar el código fácilmente.
*   **Gestión del Estado:** Dependiendo de la complejidad que se quiera manejar con el LLM, existen varias opciones en el ecosistema Flutter:
    *   **Riverpod:** Muy seguro, robusto y evita problemas de ciclo de vida del estado. Es ideal para proyectos medianos y grandes.
    *   **GetX:** Combina la gestión del estado, navegación e inyección de dependencias. Es muy fácil de implementar, altamente eficiente y requiere menos código "boilerplate", lo que lo hace extremadamente amigable para que un LLM lo programe rápidamente.
    *   **Bloc:** Basado en eventos y altamente escalable, separa muy bien la lógica de negocio de la UI, aunque su curva de aprendizaje y cantidad de código son mayores.
*   **Base de Datos Local (Modo Offline-First):** Se utilizará una base de datos integrada en el dispositivo (como SQLite con el paquete Drift o Couchbase Lite). El dispositivo considerará esta copia local como su fuente principal de datos para permitir que el técnico trabaje sin red. Al recuperar la conexión, los datos se sincronizan con la nube. Para la resolución de conflictos offline, se diseñará el estado local utilizando conceptos de **CRDTs (Conflict-Free Replicated Data Types)**, que garantizan que los datos converjan automáticamente sin conflictos al fusionarse.

**3. Arquitectura Backend y API**
*   **Lenguaje y Framework:** **Python con FastAPI** o **Node.js**. FastAPI es altamente recomendado para ser generado por LLMs gracias a su tipado fuerte (Pydantic), su velocidad y la generación automática de la documentación de la API.
*   **Comunicación en Tiempo Real:** **WebSockets**. Se utilizarán conexiones WebSocket para la comunicación bidireccional y persistente entre el cliente móvil y el servidor backend, lo cual es ideal para funciones en tiempo real orientadas al cliente (como notificaciones de cambio de estado de un vehículo).
*   **Gestión de Tareas en Segundo Plano:** El backend deberá manejar flujos asíncronos para evitar bloquear la ejecución. Las operaciones pesadas no se deben realizar como parte del ciclo de solicitud/respuesta original, garantizando que el sistema principal responda rápidamente.

**4. Base de Datos Principal (Nube/Servidor)**
*   **Motor Relacional:** **PostgreSQL**. Es una base de datos robusta, ideal para escenarios empresariales estructurados como el manejo de inventario, historial de vehículos y facturación.
*   **Capacidades de Tiempo Real:** Para sustituir el funcionamiento reactivo de Firebase/Supabase de forma nativa, el sistema utilizará la función **`pg_notify`** de PostgreSQL o una herramienta como **Hasura**. Hasura se puede acoplar a Postgres para exponer un servidor GraphQL instantáneo que maneja la transmisión de eventos en tiempo real sin requerir configuraciones complejas.

**5. Flujo de Datos y Sincronización (Data Flow)**
1.  **Operación Local:** El técnico mecánico ingresa datos (ej. diagnóstico) en la app. La app actualiza el estado local (ej. a través de GetX o Riverpod) y guarda el registro en la base de datos local SQLite.
2.  **Transmisión (En línea):** Si hay red, la aplicación emite los cambios al backend vía REST o WebSocket. 
3.  **Actualización en BD y Eventos:** El backend recibe los datos, los inserta en PostgreSQL. Postgres emite un evento mediante `pg_notify` alertando que la orden de servicio fue modificada.
4.  **Sincronización a otros clientes:** El servidor de WebSockets escucha este evento de la base de datos y envía un mensaje instantáneo a la pantalla del asesor de servicio, la cual se actualiza sin requerir recargar la página.

**6. Infraestructura y Despliegue (Deployment)**
*   El backend y la base de datos PostgreSQL pueden desplegarse mediante contenedores (Docker) en proveedores en la nube como AWS, Google Cloud o plataformas más económicas (ej. Render, Railway) para minimizar costos en la fase MVP.
*   Se pueden crear contenedores separados para la lógica de negocio, bases de datos e integraciones de IA (ej. servicios en Python que reciban identificadores de Postgres), asegurando un crecimiento escalable.
