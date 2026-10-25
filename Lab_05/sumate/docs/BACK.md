# Auditoría de Backend de Súmate para el Front

> Documento técnico de referencia basado **exclusivamente en el código real** existente en `lib/`, `firestore.rules`, `firestore.indexes.json`, `pubspec.yaml`, scripts de seed y tests.

---

## 1. Resumen y estructura

### 1.1 Árbol de carpetas de `lib/` (hasta 2 niveles en `features/` y `core/`)
```text
lib/
├── firebase_options.dart               # Configuración oficial de Firebase para Android y Web
├── main.dart                           # Punto de entrada, emuladores y pantalla de arranque
├── core/
│   ├── enums.dart                      # Enums del dominio con serialización ASCII y etiquetas UI
│   └── errores.dart                    # Excepción de dominio ErrorNegocio
├── features/
│   ├── auth/
│   │   └── servicios/
│   │       └── auth_service.dart       # Autenticación con FirebaseAuth y creación en usuarios
│   ├── eventos/
│   │   ├── modelos/
│   │   │   ├── convocatoria.dart       # Objeto anidado de cupos y fechas para voluntarios/asistentes
│   │   │   ├── edicion.dart            # Documento de realización concreta de un evento
│   │   │   └── evento.dart             # Documento de marca/serie de evento padre
│   │   └── servicios/
│   │       ├── edicion_service.dart    # Operaciones CRUD y batch de ediciones
│   │       └── evento_service.dart     # Lectura de eventos padre y misEventos
│   ├── perfil/
│   │   ├── modelos/
│   │   │   └── usuario.dart            # Modelo de perfil de usuario en colección usuarios
│   │   └── servicios/
│   │       └── usuario_service.dart    # Lectura, stream y actualización de perfil
│   └── postulaciones/
│       ├── modelos/
│       │   └── postulacion.dart        # Documento de postulación y snapshot PerfilPostulante
│       └── servicios/
│           └── postulacion_service.dart# Transacciones de postulación, revisión y asistencia
└── pruebas/
    ├── prueba_back.dart                # Pantalla de arnés de regresión integral (Paso 8)
    └── seed_demo.dart                  # Pantalla de siembra idempotente de 8 eventos de demo
```

### 1.2 Dependencias en `pubspec.yaml`
| Paquete | Versión declarada | Propósito real en el código |
|---|---|---|
| `flutter` | `sdk: flutter` | Framework UI y componentes base de Flutter |
| `cupertino_icons` | `^1.0.8` | Íconos de estilo Cupertino (incluido por plantilla) |
| `firebase_core` | `^5.0.0` | Inicialización del entorno de Firebase (`Firebase.initializeApp`) |
| `firebase_auth` | `^7.0.0` | Autenticación con email/password, tokens y sesión de usuario |
| `cloud_firestore` | `^7.0.0` | Base de datos NoSQL documental, transacciones, batches y snapshots |
| `google_fonts` | `^9.0.0` | Carga de tipografía *Plus Jakarta Sans* |
| `flutter_test` (dev) | `sdk: flutter` | Harness de pruebas unitarias para modelos |
| `flutter_lints` (dev) | `^6.0.0` | Reglas recomendadas de análisis estático de código Dart |

### 1.3 Estado de `main.dart`
- **Inicialización de Firebase:** Ejecuta `WidgetsFlutterBinding.ensureInitialized()` y `Firebase.initializeApp(...)`.
- **Modo emulador (`usarEmulador = true`):** Conecta `FirebaseAuth.instance.useAuthEmulator` al puerto `9099` y `FirebaseFirestore.instance.useFirestoreEmulator` al puerto `8080`. Para Android usa `10.0.2.2` y para Web usa `localhost`.
- **Widget raíz:** Corre un `MaterialApp` directo sin `ThemeData` centralizado, sin rutas configuradas y sin componentes del diseño Stitch.
- **Pantalla mostrada:** Alterna según `modoSeed` entre `SeedDemoScreen()` y `PruebaBackScreen()`. También contiene una clase `AuthDemoApp` de prueba manual no invocada en el `main()`.

---

## 2. Modelo de datos real

### 2.1 Colección `usuarios`
- **ID del documento:** UID de Firebase Auth (`request.auth.uid`).
- **Propósito:** Perfil privado de estudiante/organizador.

| Campo | Tipo Dart | Tipo Firestore | Obligatorio / Opcional | Valor por defecto | Descripción |
|---|---|---|---|---|---|
| *(id doc)* | `String` (en memoria: `uid`) | Document Key | Obligatorio | UID auth | UID del usuario autenticado |
| `nombre` | `String` | `string` | Obligatorio | `''` | Nombre completo del usuario |
| `correo` | `String` | `string` | Obligatorio | - | Correo electrónico institucional o personal |
| `universidad` | `String` | `string` | Opcional | `''` | Siglas o nombre de universidad (`''` = independiente) |
| `carrera` | `String` | `string` | Opcional | `''` | Escuela profesional o carrera |
| `ciclo` | `int?` | `number` / `null` | Opcional | `null` | Ciclo actual de estudios (número entero) |
| `habilidades` | `List<String>` | `array` | Opcional | `[]` | Lista de habilidades técnicas o blandas |
| `intereses` | `List<String>` | `array` | Opcional | `[]` | Temas de interés del estudiante |

### 2.2 Colección `eventos`
- **ID del documento:** Auto-generado por Firestore (`_firestore.collection('eventos').doc().id`).
- **Propósito:** Marca o serie general del evento (p. ej. "Hack4Edu").

| Campo | Tipo Dart | Tipo Firestore | Obligatorio / Opcional | Valor por defecto | Descripción |
|---|---|---|---|---|---|
| `nombre` | `String` | `string` | Obligatorio | `''` | Nombre genérico de la serie |
| `tipo` | `TipoEvento` (enum) | `string` | Obligatorio | `TipoEvento.otro` | Categoría (`hackathon`, `ponencia`, etc.) |
| `descripcion` | `String` | `string` | Obligatorio | `''` | Descripción general de la serie de eventos |
| `entidad` | `String` | `string` | Obligatorio | `''` | Organización responsable o club estudiantil |
| `administradores` | `List<String>` | `array` | Obligatorio | `[]` | UIDs autorizados a crear ediciones bajo este evento |

### 2.3 Colección `ediciones`
- **ID del documento:** Auto-generado por Firestore (`_firestore.collection('ediciones').doc().id`).
- **Propósito:** Realización concreta con fechas, lugar y convocatorias.

| Campo | Tipo Dart | Tipo Firestore | Obligatorio / Opcional | Valor por defecto | Descripción |
|---|---|---|---|---|---|
| `eventoId` | `String` | `string` | Obligatorio | `''` | ID del documento `eventos` padre |
| `eventoNombre` | `String` | `string` | Obligatorio | `''` | **Denormalizado**: nombre del evento padre |
| `tipo` | `TipoEvento` (enum) | `string` | Obligatorio | `TipoEvento.otro` | **Denormalizado**: categoría del evento padre |
| `nombre` | `String` | `string` | Obligatorio | `''` | Nombre de la edición (ej. "HackSan 2026") |
| `fechaInicio` | `DateTime` | `timestamp` | Obligatorio | - | Fecha y hora de inicio de la edición |
| `fechaFin` | `DateTime` | `timestamp` | Obligatorio | - | Fecha y hora de culminación de la edición |
| `lugar` | `String` | `string` | Obligatorio | `''` | Dirección, campus o aula de realización |
| `modalidad` | `Modalidad` (enum) | `string` | Obligatorio | `Modalidad.presencial` | `presencial`, `remoto` o `hibrido` |
| `universidad` | `String` | `string` | Opcional | `''` | Universidad sede (`''` = abierto a todas) |
| `estado` | `EstadoEdicion` (enum)| `string` | Obligatorio | `EstadoEdicion.abierta`| `abierta`, `cerrada` o `finalizada` |
| `organizadores` | `List<String>` | `array` | Obligatorio | `[]` | UIDs con permisos de gestión de esta edición |
| `voluntarios` | `Convocatoria` (map) | `map` | Obligatorio | Objeto cerrado | Mapa con cupos y reglas para voluntarios |
| `voluntarios.abierta` | `bool` | `boolean` | Obligatorio | `false` | Indica si recibe voluntarios |
| `voluntarios.cupos` | `int` | `number` | Obligatorio | `0` | Capacidad máxima de voluntarios |
| `voluntarios.ocupados` | `int` | `number` | Obligatorio | `0` | Voluntarios actualmente aceptados |
| `voluntarios.beneficios` | `String?` | `string` / omite | Opcional | `null` | Certificación, networking, almuerzo, etc. |
| `voluntarios.fechaLimite`| `DateTime?` | `timestamp` / omite | Opcional | `null` | Límite para postular como voluntario |
| `voluntarios.enlaceExterno`| `String?`| `string` / omite | Opcional | `null` | Enlace externo opcional |
| `asistentes` | `Convocatoria` (map) | `map` | Obligatorio | Objeto cerrado | Mapa con cupos y reglas para asistentes |
| `asistentes.abierta` | `bool` | `boolean` | Obligatorio | `false` | Indica si recibe asistentes |
| `asistentes.cupos` | `int` | `number` | Obligatorio | `0` | Capacidad máxima de asistentes |
| `asistentes.ocupados` | `int` | `number` | Obligatorio | `0` | Asistentes inscritos hasta el momento |
| `asistentes.fechaLimite` | `DateTime?` | `timestamp` / omite | Opcional | `null` | Límite para postular como asistente |
| `asistentes.enlaceExterno`| `String?` | `string` / omite | Opcional | `null` | Formulario externo de registro |

### 2.4 Colección `postulaciones`
- **ID del documento:** Determinista: `"{edicionId}_{usuarioId}_{rol.name}"`.
- **Propósito:** Registro de postulación o inscripción y snapshot del perfil.

| Campo | Tipo Dart | Tipo Firestore | Obligatorio / Opcional | Valor por defecto | Descripción |
|---|---|---|---|---|---|
| `edicionId` | `String` | `string` | Obligatorio | `''` | ID de la edición correspondiente |
| `usuarioId` | `String` | `string` | Obligatorio | `''` | UID del usuario que postula |
| `rol` | `RolPostulacion` | `string` | Obligatorio | - | `voluntario` o `asistente` |
| `estado` | `EstadoPostulacion`| `string` | Obligatorio | `enviada` (vol) / `aceptada` (asi) | `enviada`, `aceptada` o `rechazada` |
| `asistio` | `bool` | `boolean` | Obligatorio | `false` | Confirmación presencial marcada por organizador |
| `fecha` | `DateTime` | `timestamp` | Obligatorio | `DateTime.now()` | Momento en que se envió la postulación |
| `perfil` | `PerfilPostulante` | `map` | Obligatorio | - | **Snapshot** inmutable del perfil al postular |
| `perfil.nombre` | `String` | `string` | Obligatorio | `''` | Nombre copiado al postular |
| `perfil.correo` | `String` | `string` | Obligatorio | `''` | Correo copiado al postular |
| `perfil.universidad` | `String` | `string` | Opcional | `''` | Universidad copiada al postular |
| `perfil.carrera` | `String` | `string` | Opcional | `''` | Carrera copiada al postular |
| `perfil.ciclo` | `int?` | `number` / `null` | Opcional | `null` | Ciclo copiado al postular |
| `perfil.habilidades` | `List<String>` | `array` | Opcional | `[]` | Habilidades copiadas al postular |
| `eventoNombre` | `String` | `string` | Obligatorio | `''` | **Denormalizado**: nombre del evento |
| `edicionNombre` | `String` | `string` | Obligatorio | `''` | **Denormalizado**: nombre de la edición |
| `fechaInicio` | `DateTime` | `timestamp` | Obligatorio | - | **Denormalizado**: fecha de inicio de la edición |
| `lugar` | `String` | `string` | Obligatorio | `''` | **Denormalizado**: lugar de la edición |

### 2.5 Enums del dominio (`lib/core/enums.dart`)
| Enum Dart | Valor guardado en Firestore (`.name`) | Etiqueta en UI (`.etiqueta`) | Método deserialización segura |
|---|---|---|---|
| `TipoEvento.hackathon` | `'hackathon'` | `'Hackathon'` | `TipoEvento.desde(val)` (fallback: `otro`) |
| `TipoEvento.ponencia` | `'ponencia'` | `'Ponencia'` | |
| `TipoEvento.lanzamiento`| `'lanzamiento'` | `'Lanzamiento'` | |
| `TipoEvento.campana` | `'campana'` *(sin tilde)* | `'Campaña'` *(con tilde)* | |
| `TipoEvento.conferencia`| `'conferencia'` | `'Conferencia'` | |
| `TipoEvento.otro` | `'otro'` | `'Otro'` | |
| `Modalidad.presencial` | `'presencial'` | `'Presencial'` | `Modalidad.desde(val)` (fallback: `presencial`) |
| `Modalidad.remoto` | `'remoto'` | `'Remoto'` | |
| `Modalidad.hibrido` | `'hibrido'` *(sin tilde)* | `'Híbrido'` *(con tilde)* | |
| `EstadoEdicion.abierta` | `'abierta'` | `'Abierta'` | `EstadoEdicion.desde(val)` (fallback: `abierta`) |
| `EstadoEdicion.cerrada` | `'cerrada'` | `'Cerrada'` | |
| `EstadoEdicion.finalizada`| `'finalizada'` | `'Finalizada'` | |
| `RolPostulacion.voluntario`| `'voluntario'` | `'Voluntario'` | `RolPostulacion.desde(val)` (fallback: `asistente`)|
| `RolPostulacion.asistente` | `'asistente'` | `'Asistente'` | |
| `EstadoPostulacion.enviada`| `'enviada'` | `'En espera'` | `EstadoPostulacion.desde(val)` (fallback: `enviada`) |
| `EstadoPostulacion.aceptada`| `'aceptada'` | `'Aceptada'` | |
| `EstadoPostulacion.rechazada`| `'rechazada'` | `'Rechazada'` | |

---

## 3. Modelos Dart

### 3.1 `Usuario` (`lib/features/perfil/modelos/usuario.dart`)
- **Constructores:**
  - `const Usuario({required String uid, required String nombre, required String correo, String universidad = '', String carrera = '', int? ciclo, List<String> habilidades = const [], List<String> intereses = const []})`
- **Deserialización:** `Usuario.fromMap(Map<String, dynamic> map, {required String id})`, `Usuario.fromFirestore(DocumentSnapshot doc)`.
- **Serialización:** `Map<String, dynamic> toMap()` (excluye `uid`).
- **Métodos auxiliares:** `Usuario copyWith({String? nombre, String? universidad, String? carrera, int? ciclo, List<String>? habilidades, List<String>? intereses})` (protege `uid` y `correo`).

### 3.2 `Evento` (`lib/features/eventos/modelos/evento.dart`)
- **Constructores:**
  - `const Evento({required String id, required String nombre, required TipoEvento tipo, required String descripcion, required String entidad, List<String> administradores = const []})`
- **Deserialización:** `Evento.fromMap(Map<String, dynamic> map, {required String id})`, `Evento.fromFirestore(DocumentSnapshot doc)`.
- **Serialización:** `Map<String, dynamic> toMap()` (`tipo.name`).
- **Métodos auxiliares:** `Evento copyWith({...})`.

### 3.3 `Convocatoria` (`lib/features/eventos/modelos/convocatoria.dart`)
- **Constructores:**
  - `const Convocatoria({required bool abierta, required int cupos, int ocupados = 0, String? beneficios, DateTime? fechaLimite, String? enlaceExterno})`
  - `const Convocatoria.cerrada()`
- **Deserialización:** `Convocatoria.fromMap(Map<String, dynamic>? map)` (retorna `Convocatoria.cerrada()` si es null).
- **Serialización:** `Map<String, dynamic> toMap()` (convierte `fechaLimite` a `Timestamp`).
- **Métodos auxiliares:** `Convocatoria copyWith({...})`.
- **Getters de lógica de negocio útiles para UI:**
  - `bool get hayCupo => ocupados < cupos;`
  - `bool get vencida => fechaLimite != null && fechaLimite!.isBefore(DateTime.now());`
  - `bool get admitePostulaciones => abierta && hayCupo && !vencida;`

### 3.4 `Edicion` (`lib/features/eventos/modelos/edicion.dart`)
- **Constructores:**
  - `const Edicion({required String id, required String eventoId, required String eventoNombre, required TipoEvento tipo, required String nombre, required DateTime fechaInicio, required DateTime fechaFin, required String lugar, required Modalidad modalidad, String universidad = '', EstadoEdicion estado = EstadoEdicion.abierta, List<String> organizadores = const [], Convocatoria voluntarios = const Convocatoria.cerrada(), Convocatoria asistentes = const Convocatoria.cerrada()})`
- **Deserialización:** `Edicion.fromMap(Map<String, dynamic> map, {required String id})`, `Edicion.fromFirestore(DocumentSnapshot doc)`.
- **Serialización:** `Map<String, dynamic> toMap()`.
- **Métodos auxiliares:** `Edicion copyWith({...})`.
- **Getters y lógica de negocio:**
  - `Convocatoria convocatoriaDe(RolPostulacion rol) => rol == RolPostulacion.voluntario ? voluntarios : asistentes;`
  - `bool get finalizadaEfectiva => estado == EstadoEdicion.finalizada || DateTime.now().isAfter(fechaFin);`
  - `bool admitePostulaciones(RolPostulacion rol) => estado == EstadoEdicion.abierta && !finalizadaEfectiva && convocatoriaDe(rol).admitePostulaciones;`

### 3.5 `PerfilPostulante` y `Postulacion` (`lib/features/postulaciones/modelos/postulacion.dart`)
- **PerfilPostulante:**
  - Constructores: `PerfilPostulante({...})`, `PerfilPostulante.desdeUsuario(Usuario usuario)`, `PerfilPostulante.fromMap(Map<String, dynamic>? map)`.
  - Serialización: `toMap()`.
- **Postulacion:**
  - Constructor: `const Postulacion({required String id, required String edicionId, required String usuarioId, required RolPostulacion rol, EstadoPostulacion estado = EstadoPostulacion.enviada, bool asistio = false, required DateTime fecha, required PerfilPostulante perfil, required String eventoNombre, required String edicionNombre, required DateTime fechaInicio, required String lugar})`.
  - Generador determinista: `static String construirId(String edicionId, String usuarioId, RolPostulacion rol) => '${edicionId}_${usuarioId}_${rol.name}';`
  - Deserialización: `Postulacion.fromMap(...)`, `Postulacion.fromFirestore(...)`.
  - Serialización: `toMap()`.

---

## 4. Servicios

Instanciación: constructores estándar que permiten inyección opcional de `FirebaseAuth` o `FirebaseFirestore`, con fallback a `instance`. No usan singletons estáticos ni Service Locator.

### 4.1 `AuthService` (`lib/features/auth/servicios/auth_service.dart`)
| Método | Firma exacta | Tipo | Qué hace | Errores que lanza | RF | Pantallas |
|---|---|---|---|---|---|---|
| `cambiosSesion` | `Stream<User?> get cambiosSesion` | Stream | Emite cambios de auth | Ninguno | RF01 | AppShell / AuthGate |
| `usuarioActual` | `User? get usuarioActual` | Getter | Usuario en memoria | Ninguno | RF01 | Toda la UI |
| `registrar` | `Future<void> registrar({required String nombre, required String correo, required String password})` | Future | Crea usuario en Auth y doc inicial en `usuarios` | `AuthError('...')` con traducción en español | RF01 | Crear cuenta |
| `iniciarSesion` | `Future<void> iniciarSesion({required String correo, required String password})` | Future | Login en Auth | `AuthError('...')` con traducción en español | RF01 | Inicio de sesión |
| `cerrarSesion` | `Future<void> cerrarSesion()` | Future | Cierra sesión (`signOut()`) | Errores nativos de Auth | RF01 | Perfil |
| `enviarRecuperacionContrasena` | `Future<void> enviarRecuperacionContrasena(String correo)` | Future | Envía email de restablecimiento de contraseña (`sendPasswordResetEmail`) | `AuthError('...')` con traducción en español | RF01 | Inicio de sesión |

### 4.2 `UsuarioService` (`lib/features/perfil/servicios/usuario_service.dart`)
| Método | Firma exacta | Tipo | Qué hace | Errores que lanza | RF | Pantallas |
|---|---|---|---|---|---|---|
| `obtener` | `Future<Usuario?> obtener(String uid)` | Future | Lee perfil por UID | `FirebaseException` si falla | RF02 | Perfil, Postular |
| `escuchar` | `Stream<Usuario?> escuchar(String uid)` | Stream | Escucha perfil en tiempo real | Emite `null` si no existe | RF02 | Perfil |
| `actualizar`| `Future<void> actualizar(Usuario usuario)` | Future | Actualiza perfil en `usuarios/{uid}` | `FirebaseException` | RF02 | Perfil |

### 4.3 `EventoService` (`lib/features/eventos/servicios/evento_service.dart`)
| Método | Firma exacta | Tipo | Qué hace | Errores que lanza | RF | Pantallas |
|---|---|---|---|---|---|---|
| `obtener` | `Future<Evento?> obtener(String eventoId)` | Future | Lee evento padre por ID | `FirebaseException` | RF06 | Detalle convocatoria |
| `misEventos` | `Future<List<Evento>> misEventos(String uid)` | Future | `where('administradores', arrayContains: uid)` | `FirebaseException` | RF03, RF14 | Mis eventos |

### 4.4 `EdicionService` (`lib/features/eventos/servicios/edicion_service.dart`)
| Método | Firma exacta | Tipo | Qué hace | Errores que lanza | RF | Pantallas |
|---|---|---|---|---|---|---|
| `crear` | `Future<String> crear(Edicion edicion)` | Future | Crea doc `ediciones` asignando ID | `FirebaseException` | RF03 | Publicar edición |
| `obtener` | `Future<Edicion?> obtener(String id)` | Future | Lee edición por ID | `FirebaseException` | RF06 | Detalle convocatoria |
| `listarAbiertas` | `Future<List<Edicion>> listarAbiertas({TipoEvento? tipo, String? universidad, Modalidad? modalidad, DateTime? fechaDesde})` | Future | Consulta catálogo general con `estado == 'abierta'` en Firestore y filtros opcionales en cliente | `FirebaseException` | RF05 | Explorar convocatorias |
| `misEdicionesAbiertas` | `Future<List<Edicion>> misEdicionesAbiertas(String uid)` | Future | Filtra `organizadores arrayContains uid` y `estado == 'abierta'` | `FirebaseException` | RF14 | Mis eventos (activos) |
| `misEdicionesAbiertasFiltros` | `Future<List<Edicion>> misEdicionesAbiertasFiltros(String uid, {TipoEvento? tipo})` | Future | Mismo que anterior más filtro opcional `tipo` | `FirebaseException` | RF14 | Mis eventos (filtro) |
| `misEdiciones` | `Future<List<Edicion>> misEdiciones(String uid)` | Future | Todas las ediciones del organizador (`organizadores arrayContains uid`) | `FirebaseException` | RF14 | Mis eventos |
| `editar` | `Future<void> editar(Edicion edicion)` | Future | Actualiza campos de la edición | `ErrorNegocio('Edición no encontrada')` | RF14 | Editar convocatoria |
| `cerrar` | `Future<void> cerrar(String id)` | Future | Cambia `estado` a `'cerrada'` | `ErrorNegocio('Edición no encontrada')` | RF14 | Detalle organizador |
| `reabrir` | `Future<void> reabrir(String id)` | Future | Cambia `estado` a `'abierta'` | `ErrorNegocio('Edición no encontrada')` | RF14 | Detalle organizador |
| `crearNuevaEdicionDesde` | `Future<String> crearNuevaEdicionDesde(String sourceId)` | Future | Clona edición reseteando contadores y fecha límite | `ErrorNegocio('Edición origen no encontrada')` | RF14 | Detalle organizador |
| `crearEventoConPrimeraEdicion` | `Future<String> crearEventoConPrimeraEdicion({required Evento evento, required Edicion edicion, required String uid})` | Future | **Batch**: crea `eventos/{id}` y `ediciones/{id}` atómicamente | `FirebaseException` | RF03 | Publicar evento (paso 1 y 2) |

### 4.5 `PostulacionService` (`lib/features/postulaciones/servicios/postulacion_service.dart`)
| Método | Firma exacta | Tipo | Qué hace | Errores que lanza | RF | Pantallas |
|---|---|---|---|---|---|---|
| `postular` | `Future<String> postular({required String edicionId, required RolPostulacion rol, required String uid})` | Future | Transacción: valida cupo, plazo, duplicado; setea postulación e incrementa ocupados de asistentes | `ErrorNegocio('...')` (ver sección 5) | RF07 | Detalle convocatoria |
| `obtener` | `Future<Postulacion?> obtener(String id)` | Future | Lee postulación por ID determinista | `FirebaseException` | RF08 | Detalle postulación |
| `misPostulaciones` | `Future<List<Postulacion>> misPostulaciones(String uid)` | Future | Lee por `usuarioId == uid` y ordena fecha desc en cliente | `FirebaseException` | RF08 | Mis postulaciones |
| `contarPendientes` | `Future<int> contarPendientes(String edicionId)` | Future | Conteo agregado `count()` de postulaciones en `estado == 'enviada'` respetando `edicionId` | `FirebaseException` | RF09, RF14 | Mis eventos, Detalle organizador |
| `postulantesDeEdicion` | `Future<List<Postulacion>> postulantesDeEdicion(String edicionId, {RolPostulacion? rol, EstadoPostulacion? estado})` | Future | Lee por `edicionId == id`, filtra rol/estado y ordena en cliente | `FirebaseException` | RF09 | Gestión postulantes |
| `responder` | `Future<void> responder(String postulacionId, EstadoPostulacion nuevo)` | Future | Transacción: acepta/rechaza voluntario actualizando cupos | `ErrorNegocio('...')` | RF09 | Gestión postulantes |
| `marcarAsistio` | `Future<void> marcarAsistio(String postulacionId, bool asistio)` | Future | Transacción: actualiza flag `asistio` validando fecha de inicio | `ErrorNegocio('...')` | RF10 | Gestión postulantes |
| `cancelar` | `Future<void> cancelar(String postulacionId, String uid)` | Future | Transacción: el dueño borra su postulación si es cancelable; asistente resta 1 a `asistentes.ocupados` | `ErrorNegocio('...')` | RF08 | Mis postulaciones |
| `historial` | `Future<List<Postulacion>> historial(String uid)` | Future | Reutiliza `misPostulaciones`, filtra `asistio == true` y ordena `fechaInicio` desc | `FirebaseException` | RF11 | Historial |

---

## 5. Manejo de errores

### 5.1 Excepciones personalizadas y mensajes exactos
Existen dos clases de error en el backend:
1. **`AuthError` (`lib/features/auth/servicios/auth_service.dart`)**:
   - `toString()` devuelve `"AuthError: $mensaje"`.
   - Mensajes exactos producidos por el mapeador interno:
     - `'El correo electrónico no tiene un formato válido.'` (code: `invalid-email`)
     - `'El correo electrónico ya está en uso.'` (code: `email-already-in-use`)
     - `'La contraseña es demasiado débil.'` (code: `weak-password`)
     - `'No existe un usuario con ese correo.'` (code: `user-not-found`)
     - `'Contraseña incorrecta.'` (code: `wrong-password`)
     - `'Credencial inválida.'` (code: `invalid-credential`)
     - `'Demasiados intentos fallidos. Intenta más tarde.'` (code: `too-many-requests`)
     - `'Error de autenticación: <mensaje original>'` (cualquier otro código no contemplado)
     - `'No se pudo obtener el uid del usuario recién creado.'` (si el registro no arrojó UID)

2. **`ErrorNegocio` (`lib/core/errores.dart`)**:
   - `toString()` devuelve directamente su propiedad `mensaje`.
   - Mensajes exactos producidos en servicios:
     - `'Edición no encontrada'` (en `editar`, `cerrar`, `reabrir`)
     - `'Edición origen no encontrada'` (en `crearNuevaEdicionDesde`)
     - `'La edición no existe'` (en `postular`)
     - `'Ya postulaste a esta convocatoria como Voluntario'` o `'Ya postulaste a esta convocatoria como Asistente'` (en `postular`)
     - `'La edición no está abierta'` (en `postular`)
     - `'La edición ya finalizó'` (en `postular`)
     - `'La convocatoria de voluntarios está cerrada'` o `'La convocatoria de asistentes está cerrada'` (en `postular`)
     - `'El plazo de postulación ya venció'` (en `postular`)
     - `'Cupo de voluntarios lleno'` o `'Cupo de asistentes lleno'` (en `postular` y `responder`)
     - `'El nuevo estado debe ser aceptada o rechazada'` (en `responder`)
     - `'Postulación no encontrada'` (en `responder`, `marcarAsistio`, `cancelar`)
     - `'Solo se responden postulaciones de voluntarios'` (en `responder`)
     - `'No se puede cambiar el estado: ya asistió'` (en `responder`)
     - `'Solo se marca asistencia en postulaciones aceptadas'` (en `marcarAsistio`)
     - `'No se puede marcar asistencia antes de la fecha de inicio'` (en `marcarAsistio`)
     - `'No puedes cancelar esta postulación'` (en `cancelar`, uid distinto)
     - `'Ya se registró tu asistencia'` (en `cancelar`)
     - `'Tu postulación ya fue aceptada; contacta al organizador para cancelarla'` (en `cancelar`, voluntario aceptado)
     - `'No se puede cancelar una postulación rechazada'` (en `cancelar`)
     - `'El evento ya comenzó'` (en `cancelar`, asistente con fechaInicio alcanzada)
     - `'Edición no encontrada'` (en `cancelar`, si falta la edición del asistente)

### 5.2 Errores de Firestore
- Si una operación no cumple `firestore.rules`, lanza un `FirebaseException` con `code: 'permission-denied'`. Los servicios **no capturan silenciosamente** las violaciones de reglas, por lo que la UI debe atrapar `FirebaseException` o verificar previamente los permisos.
- Si falta un índice compuesto, lanza `FirebaseException` con `code: 'failed-precondition'`.

---

## 6. Reglas de negocio que la UI NO debe repetir

1. **Cupos:**
   - Asistentes: se validan e incrementan en +1 de forma atómica durante la postulación (`postular()`).
   - Voluntarios: **no** se descuentan al postular (quedan en `enviada`). Se validan e incrementan en +1 cuando el organizador los aprueba (`responder(..., aceptada)`). Si el organizador rechaza a un voluntario previamente aceptado, el back restaura el cupo (-1).
2. **Fecha límite de postulación:**
   - Evaluada por `Convocatoria.vencida` (`fechaLimite.isBefore(DateTime.now())`). Si venció, el back rechaza la postulación.
3. **Duplicados:**
   - El ID determinista `edicionId_usuarioId_rol` y la verificación transaccional impiden físicamente postular dos veces con el mismo rol a una edición. Sí está permitido postular como voluntario y como asistente en la misma edición.
4. **Roles para aceptar/rechazar:**
   - La función `responder()` **solo** procesa postulaciones de voluntarios. Los asistentes ingresan directamente en estado `aceptada`.
5. **Marcado de asistencia (`asistio`):**
   - Requiere que la postulación esté `aceptada` y que la hora actual sea `>= fechaInicio`. De lo contrario, la transacción aborta.
6. **Edición cerrada y finalizada:**
   - `Edicion.finalizadaEfectiva` se activa automáticamente en memoria si `DateTime.now().isAfter(fechaFin)`, bloqueando postulaciones incluso si el organizador olvidó marcar `estado = finalizada`.
7. **Cancelar postulación (`cancelar`):**
   - Solo el dueño (`usuarioId == uid`). Tras el borrado el id determinista queda libre y puede volver a postular.
   - Voluntario: solo `estado == enviada` y `asistio == false`. No toca cupos.
   - Asistente: solo `asistio == false` y `ahora < fechaInicio`. En la misma transacción resta 1 a `asistentes.ocupados` (sin bajar de 0) y borra el documento.
   - No se puede cancelar voluntario aceptado o rechazado, ni ninguna postulación con `asistio == true`.

---

## 7. Reglas de seguridad (`firestore.rules`)

### 7.1 Resumen de reglas
| Colección | Lectura | Creación | Actualización | Borrado |
|---|---|---|---|---|
| `usuarios/{uid}` | Solo dueño (`request.auth.uid == uid`) | Solo dueño y `correo == auth.token.email` | Solo dueño y no cambia correo | Prohibido (`false`) |
| `eventos/{id}` | Cualquier autenticado | Autenticado si se incluye en `administradores` | Solo administradores actuales | Prohibido (`false`) |
| `ediciones/{id}` | Cualquier autenticado | Autenticado si es admin de evento padre, se incluye en `organizadores`, contadores = 0 y estado = `'abierta'` | 1) Organizadores de la edición.<br>2) Postulante asistente en transacción atómica (+1 cupo).<br>3) Postulante no organizador, solo `-1` a `asistentes.ocupados` (>= 0) al borrar su postulación de asistente en la misma transacción. | Prohibido (`false`) |
| `postulaciones/{pid}` | Dueño de la postulación O cualquier organizador de la edición | Dueño (`usuarioId == auth.uid`), ID determinista, edición abierta y rol abierto | Solo organizadores de la edición (solo campos `estado` y `asistio`) | Dueño, `asistio == false`, y (voluntario `enviada` o asistente con `request.time < fechaInicio`) |

### 7.2 Permisos por tipo de actor
- **Usuario anónimo (`request.auth == null`):** No puede leer ni escribir absolutamente nada en ninguna colección.
- **Usuario autenticado estándar:**
  - Puede leer cualquier evento o edición.
  - Solo puede leer y editar su propio perfil `usuarios/{auth.uid}`.
  - Puede crear su propia postulación en `postulaciones`.
  - Puede listar sus propias postulaciones (`where usuarioId == auth.uid`).
  - **No puede** leer `postulaciones` ajenas ni listar postulantes de ediciones donde no sea organizador (recibirá `permission-denied`).
- **Organizador de una edición:**
  - Puede actualizar los datos de la edición (manteniendo invariantes de cupos).
  - Puede leer todas las postulaciones de su edición mediante `where edicionId == id`.
  - Puede actualizar `estado` y `asistio` de sus postulantes.
- **Administrador de evento:**
  - Puede actualizar el documento del evento y crear nuevas ediciones asociadas al mismo.

### 7.3 Restricción crítica para consultas de postulantes
Las reglas exigen evaluar si el usuario autenticado está en `edicionDe(resource.data.edicionId).organizadores`. Por tanto, una consulta a `postulaciones` **solo es admitida si incluye el filtro exacto:**
```dart
_firestore.collection('postulaciones').where('edicionId', isEqualTo: edicionId)
```
Si la UI intenta consultar postulaciones sin este filtro o con filtros incompatibles, Firestore denegará la lectura.

---

## 8. Consultas e índices

### 8.1 Consultas ejecutadas por los servicios
1. `usuarios.doc(uid).get()`
2. `eventos.where('administradores', arrayContains: uid)`
3. `ediciones.where('organizadores', arrayContains: uid).where('estado', isEqualTo: 'abierta')`
4. `ediciones.where('organizadores', arrayContains: uid).where('estado', isEqualTo: 'abierta').where('tipo', isEqualTo: tipo.name)`
5. `ediciones.where('organizadores', arrayContains: uid)`
6. `postulaciones.where('usuarioId', isEqualTo: uid)`
7. `postulaciones.where('edicionId', isEqualTo: edicionId)`
8. `ediciones.where('estado', isEqualTo: 'abierta')` (en `EdicionService.listarAbiertas`)
9. `postulaciones.where('edicionId', isEqualTo: edicionId).where('estado', isEqualTo: 'enviada').count()` (en `PostulacionService.contarPendientes`)

### 8.2 Contenido de `firestore.indexes.json`
El archivo se encuentra actualmente con índices automáticos:
```json
{
  "indexes": [],
  "fieldOverrides": []
}
```
*Nota sobre índices:* Las consultas 8 y 9 utilizan filtros de igualdad sencillos (`estado == 'abierta'`, y `edicionId == X` con `estado == 'enviada'`), los cuales están cubiertos por los índices de campo único automáticos de Firestore. No se requieren índices compuestos adicionales.

### 8.3 Consulta de Explorar Convocatorias (RF05)
- **Implementación en el servicio:** `EdicionService.listarAbiertas({tipo, universidad, modalidad, fechaDesde})` consulta `ediciones.where('estado', isEqualTo: 'abierta')` en Firestore.
- **Filtros en cliente:** Los filtros opcionales de categoría (`tipo`), universidad (`universidad`), modalidad (`modalidad`) y rango de fechas (`fechaDesde`) se procesan en la lista resultante en memoria del cliente Dart, evitando crear y mantener índices compuestos combinatorios.
- **Paginación:** No existe paginación por cursores; el listado completo de convocatorias abiertas se procesa y pagina si fuera necesario en la vista.

---

## 9. Autenticación y sesión

### 9.1 Flujo exacto de registro y login
1. **Registro:**
   - Llama a `FirebaseAuth.instance.createUserWithEmailAndPassword`.
   - Crea inmediatamente el documento `usuarios/{cred.user.uid}` con `nombre`, `correo` y listas vacías.
   - Si la escritura del documento en Firestore falla, el servicio ejecuta `current.delete()` en Firebase Auth para evitar cuentas huérfanas.
2. **Login:** Llama a `FirebaseAuth.instance.signInWithEmailAndPassword`.
3. **Logout:** Llama a `FirebaseAuth.instance.signOut()`.
4. **Recuperación de contraseña:** Implementado en `AuthService.enviarRecuperacionContrasena(correo)`, que delega en `sendPasswordResetEmail` y traduce los errores al formato `AuthError` en español.
5. **Exposición del usuario:**
   - Síncrono: `authService.usuarioActual` (`User?`).
   - Reactivo: `authService.cambiosSesion` (`Stream<User?>`).
6. **Detección de perfil incompleto:**
   - La UI debe leer `usuarioService.obtener(user.uid)`.
   - Se considera incompleto si `usuario.carrera.isEmpty` o `usuario.universidad.isEmpty`.
7. **Usuario en Auth sin documento en `usuarios`:**
   - `UsuarioService.obtener()` retorna `null`.
   - `PostulacionService.postular()` maneja este escenario creando un objeto temporal `Usuario(uid: uid, nombre: '', correo: '')` para no bloquear la postulación.

---

## 10. Seed y pruebas

### 10.1 Siembra de datos (`lib/pruebas/seed_demo.dart`)
- **Ejecución:** En `main.dart`, configurar `modoSeed = true` y ejecutar la app.
- **Idempotencia:** Consulta previamente `misEventos(uid)` del usuario de demo y omite cualquier evento cuyo nombre ya exista.
- **Credenciales del usuario Demo:**
  - Correo: `demo@sumate.pe`
  - Contraseña: `123456`
  - Nombre: `'Organización Demo'`
- **Eventos que siembra (8 eventos con sus ediciones):**
  1. *Hack4Edu* (Hackathon, UNSA) - Híbrido, 10 voluntarios, 60 asistentes.
  2. *Ciclo de Ponencias en IA* (Ponencia, UCSM) - Presencial, 120 asistentes (sin voluntarios).
  3. *Lanzamiento Startup Arequipa* (Lanzamiento, General) - Presencial, 6 voluntarios, 80 asistentes.
  4. *Campaña de Reforestación Chilina* (Campaña, UCSP) - Presencial, 25 voluntarios (sin asistentes).
  5. *Conferencia de Ciberseguridad* (Conferencia, UNSA) - Remoto, 200 asistentes con Google Forms externo.
  6. *Feria de Proyectos Tecnológicos* (Otro, General) - Presencial, 8 voluntarios, 100 asistentes.
  7. *Taller de Diseño UX* (Ponencia, UCSM) - Híbrido, 4 voluntarios, 30 asistentes.
  8. *Voluntariado Banco de Alimentos* (Campaña, General) - Presencial, 15 voluntarios.

### 10.2 Cuentas de prueba en la regresión (`lib/pruebas/prueba_back.dart`)
- Todas usan contraseña `'123456'`:
  - `prueba@sumate.pe` (organizador principal)
  - `otro@sumate.pe` y `otro2@sumate.pe` (usuarios ajenos para pruebas de seguridad)
  - `vol@sumate.pe` (postulante a voluntariado)
  - `asi@sumate.pe` (postulante a asistente)

### 10.3 Tests existentes (`test/modelos_test.dart`)
- Se ejecutan con `flutter test`. Cubren 7 casos unitarios sobre deserialización de `Edicion`, cálculo de `hayCupo` y `vencida` en `Convocatoria`, determinismo de ID en `Postulacion.construirId` y fallbacks en `TipoEvento.desde`.

### 10.4 Despliegue de reglas e índices
- Comandos CLI:
  ```bash
  firebase deploy --only firestore:rules
  firebase deploy --only firestore:indexes
  ```
- **Estado de despliegue:** VERIFICAR. Las reglas e índices están validados en el emulador local.

---

## 11. Consideraciones para el Front

1. **Fechas y zonas horarias:**
   - En Firestore se almacenan como `Timestamp` UTC.
   - En Dart son `DateTime` locales (`.toDate()`).
   - La UI debe formatear usando `DateTime` local (GMT-5 Arequipa) mostrando días de la semana y horas (ej. `"sáb 22 nov · 9:00"`).
2. **Manejo de nulos en la UI:**
   - `ciclo` puede ser `null`.
   - `beneficios`, `fechaLimite` y `enlaceExterno` son `null` si no se especificaron.
   - `universidad` vacía (`''`) representa un evento o perfil sin filiación universitaria exclusiva ("Abierto / Independiente").
3. **Transacciones:**
   - `postular`, `responder` y `marcarAsistio` usan `runTransaction`. Si la conexión es inestable, pueden reintentar automáticamente o fallar si cambian los cupos en simultáneo.
4. **Estado de requisitos (RF01 - RF18):**
   | Requisito | Estado en el Back | Detalle |
   |---|---|---|
   | RF01 (Auth) | **Completo** | Login y registro con perfil inicial |
   | RF02 (Perfil) | **Completo** | Campos académicos, habilidades e intereses |
   | RF03 (Crear evento + edición) | **Completo** | Batch atómico en `EdicionService` |
   | RF04 (Enlace externo) | **Completo** | Soportado en modelo y reglas |
   | RF05 (Explorar) | **Completo** | Implementado con `EdicionService.listarAbiertas()` |
   | RF06 (Detalle) | **Completo** | Métodos `obtener` en `Edicion` y `Evento` |
   | RF07 (Postular) | **Completo** | Transacción con validación y snapshot |
   | RF08 (Mis postulaciones) | **Completo** | Listado con ordenamiento en cliente |
   | RF09 (Gestión postulantes) | **Completo** | Filtros y respuesta transaccional |
   | RF10 (Marcar asistencia) | **Completo** | Transacción con validación temporal |
   | RF11 (Historial) | **Completo** | Filtrado de asistencias confirmadas |
   | RF12 (Favoritos) | **Sin implementar** | No hay colección ni campo de favoritos |
   | RF13 (Recordatorios) | **Sin implementar** | No hay lógica de notificaciones |
   | RF14 (Editar/cerrar/clonar) | **Completo** | Soportado en `EdicionService` |
   | RF15 (Asignar organizadores) | **Sin implementar** | No hay método de asignación |
   | RF16 (Asistencia QR) | **Pendiente** | Fuera de alcance de código |
   | RF17 (PDF constancia) | **Pendiente** | Fuera de alcance de código |
   | RF18 (Calificaciones) | **Pendiente** | Fuera de alcance de código |

---

## 12. Mapa Pantalla → Backend

| # | Pantalla | Servicios y métodos consumidos | Datos mostrados según diseño Stitch | ¿Back los provee? / **BRECHA** |
|---|---|---|---|---|
| 1 | `inicio_de_sesion` | `AuthService.iniciarSesion`, `enviarRecuperacionContrasena` | Inputs correo, contraseña; botón recuperar contraseña | Sí, totalmente provisto. |
| 2 | `crear_cuenta` | `AuthService.registrar` | Nombre, correo universitario, contraseña, confirmación | Sí, totalmente provisto. |
| 3 | `perfil` | `UsuarioService.obtener`, `actualizar`, `AuthService.cerrarSesion` | Datos personales, carrera, ciclo, habilidades (chips), intereses | Sí, totalmente provisto. |
| 4 | `explorar_convocatorias` | `EdicionService.listarAbiertas` | Tarjetas con título, tipo, fecha, universidad, modalidad, cupos disponibles | Sí, provisto con `listarAbiertas()` y filtros en cliente. |
| 5 | `detalle_convocatoria` | `EdicionService.obtener`, `EventoService.obtener`, `PostulacionService.postular`, `cancelar` | Descripción, beneficios, fecha límite, cupos restantes, botones de postulación, acción "Cancelar postulación" | Sí, provisto combinando edición, evento y postulaciones. |
| 6 | `publicar_evento` (paso 1) | Datos en memoria / formulario | Nombre serie, categoría, descripción corta, institución organizadora | Sí, alimenta el paso 2. |
| 7 | `publicar_evento_paso_2` | `EdicionService.crearEventoConPrimeraEdicion` | Nombre edición, fecha, hora, lugar, modalidad, cupos, beneficios | Sí, ejecuta el batch atómico con éxito. |
| 8 | `mis_eventos` | `EdicionService.misEdiciones`, `PostulacionService.contarPendientes` | Tabs "Activos" y "Pasados", contadores de postulantes y badge "X por revisar" | Sí, `contarPendientes(edicionId)` provee el conteo de postulaciones en espera. |
| 9 | `detalle_convocatoria_organizador`| `EdicionService.obtener`, `cerrar`, `reabrir`, `PostulacionService.postulantesDeEdicion` | Métricas (18 postulantes, 6 aceptados, 5 por revisar), editar, cerrar | Sí, leyendo la lista de postulantes de la edición. |
| 10 | `gestion_de_postulantes` | `PostulacionService.postulantesDeEdicion`, `responder`, `marcarAsistio` | Filtros (Todos, En espera, Aceptados), snapshot de perfil, botones aceptar/rechazar y check asistió | Sí, totalmente provisto por el backend. |
| 11 | `mis_postulaciones` | `PostulacionService.misPostulaciones`, `escucharMisPostulaciones` | Tarjetas con estado (aceptada, enviada, rechazada), datos de edición denormalizados | Sí, totalmente provisto por el backend. |
| 12 | `mis_postulaciones_historial` | `PostulacionService.historial` | Eventos con asistencia confirmada, horas cumplidas, botón constancia | **BRECHA**: El diseño muestra "Cumpliste 16 horas de voluntariado". El modelo `Postulacion` no registra horas dedicadas (solo el flag booleano `asistio`). |

---

## 13. Discrepancias y riesgos

1. **Horas de voluntariado en Historial:**
   - `mis_postulaciones_historial` muestra horas de participación en las tarjetas ("Cumpliste 16 horas"), pero el backend solo almacena `asistio: true/false`.
2. **Favoritos (RF12):**
   - Varios diseños muestran un ícono de marcador/favorito (`bookmark_border`). No existe soporte en Firestore ni en los modelos para almacenar favoritos de usuarios.
