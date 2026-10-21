# CONTEXTO DEL PROYECTO: Súmate

> Léelo completo antes de escribir código. Si algo contradice lo que se te pide, avisa antes de implementar.

## 1. Resumen
**Súmate** (nombre definitivo) es una app multiplataforma (Android + web) que conecta **organizadores, voluntarios y asistentes** de eventos de cualquier universidad o institución de Arequipa (hackathons, ponencias, lanzamientos, campañas, conferencias abiertas, etc.). La motivación del usuario es **networking, experiencia, aprendizaje y certificados** (útiles para LinkedIn). No es bolsa de trabajo ni de prácticas, y **no es una red social**.

Contexto académico: Laboratorio 5 del curso Plataformas Emergentes (UNSA, Ingeniería de Sistemas). App multiplataforma en Flutter que resuelve un problema real con enfoque de proyección social. Se evalúa: funcionalidades, diseño minimalista, correspondencia entre funciones e interfaces, conocimiento aplicado (uso de componentes del framework), originalidad y calidad del informe.

## 2. Problema (árbol resumido)
**Problema central:** los estudiantes de Arequipa se enteran tarde o nunca de oportunidades de voluntariado y eventos abiertos, y los organizadores tienen dificultad para conseguir voluntarios y asistentes.

- **Causas:** convocatorias dispersas en WhatsApp/afiches; formularios repetidos con los mismos datos; no hay espacio común entre universidades; los organizadores no conocen las habilidades de los postulantes; no hay registro ordenado de participaciones y certificados.
- **Efectos:** eventos con pocos voluntarios o asistentes; estudiantes sin acceso a experiencia y networking; selección lenta y desordenada; participaciones difíciles de demostrar.
- **Proyección social:** acceso equitativo a oportunidades de formación y voluntariado, y vínculo entre universidades y comunidad.

## 3. Stack
- Flutter (Dart), plataformas: Android y web. Una sola base de código.
- Firebase: Authentication (correo y contraseña) y Cloud Firestore.
- Paquetes: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_fonts` (Plus Jakarta Sans).
- Proyecto creado con `flutter create --platforms=android,web sumate`.
- Firebase configurado con `flutterfire configure` (genera `lib/firebase_options.dart`).

## 4. Decisiones de diseño
- **Un solo tipo de cuenta.** Cualquier usuario puede postular y publicar. "Organizador" es un **permiso sobre un evento o edición**, no un rol de cuenta.
- **Evento (serie/marca) vs. Edición (realización concreta).** Evento = "Hack4Edu". Edición = "Hack4Edu 2026". Los eventos únicos son un evento con una sola edición; el formulario "Nuevo evento" crea ambos a la vez.
- Cada edición tiene sus propios `organizadores`, así el líder puede cambiar cada año sin perder el historial. El evento tiene `administradores` (pueden crear nuevas ediciones).
- La **convocatoria** no es una colección: son los objetos `voluntarios` y `asistentes` dentro de la edición.
- Solo los organizadores publican convocatorias. Los demás buscan, postulan y hacen seguimiento. **Sin feed, comentarios, likes, seguidores ni chat.**
- Si el organizador ya tiene un Google Form, puede poner `enlaceExterno` y la app redirige a él.
- UI minimalista, fácil de aprender, máximo 3 toques para postular.

## 5. Modelo de datos (Firestore)

```
usuarios/{uid}
  nombre, correo, universidad (opcional, '' = independiente), carrera,
  ciclo (opcional), habilidades[], intereses[]

eventos/{eventoId}                  // la marca / serie
  nombre, tipo (hackathon | ponencia | lanzamiento | campana | conferencia | otro),
  descripcion, entidad, administradores[uid]

ediciones/{edicionId}               // cada realización
  eventoId, eventoNombre*, tipo*,   // *copiados del evento (denormalizados)
  nombre, fechaInicio, fechaFin,
  lugar, modalidad (presencial | remoto | hibrido), universidad (opcional),
  estado (abierta | cerrada | finalizada),
  organizadores[uid],
  voluntarios: { abierta, cupos, ocupados, beneficios, fechaLimite?, enlaceExterno? }
  asistentes:  { abierta, cupos, ocupados, fechaLimite?, enlaceExterno? }

postulaciones/{edicionId_usuarioId_rol}
  edicionId, usuarioId, rol (voluntario | asistente),
  estado (enviada | aceptada | rechazada),
  asistio (bool), fecha,
  perfil: { nombre, correo, universidad, carrera, ciclo, habilidades[] },  // snapshot al postular
  eventoNombre, edicionNombre, fechaInicio, lugar                          // denormalizados
```

Notas:
- El id de la postulación evita duplicados (un usuario no puede postular dos veces con el mismo rol a la misma edición).
- El historial de participaciones = postulaciones con `asistio == true`.
- Si un evento solo busca voluntarios, `asistentes.abierta = false`.

## 6. Requisitos funcionales
Prioridad: **A** = MVP, **B** = si hay tiempo, **P** = pendiente (solo se documenta en el informe).

| Código | Requisito | Prior. |
|---|---|---|
| RF01 | Registro e inicio de sesión (correo y contraseña) | A |
| RF02 | Perfil con universidad, carrera, ciclo, habilidades e intereses | A |
| RF03 | Crear evento (serie) y su primera edición con tipo, descripción, fecha, lugar o modalidad, convocatoria de voluntarios y/o asistentes (cupos, beneficios, fecha límite) | A |
| RF04 | Enlace externo opcional (p. ej. Google Form) | A |
| RF05 | Listado de convocatorias con filtros por tipo, universidad, fecha y modalidad | A |
| RF06 | Detalle de la convocatoria | A |
| RF07 | Postular o inscribirse con un toque, usando los datos del perfil | A |
| RF08 | Ver el estado de mis postulaciones | A |
| RF09 | El organizador ve a los postulantes con sus habilidades y acepta o rechaza | A |
| RF10 | El organizador marca quién participó realmente | A |
| RF11 | Historial de participaciones con constancia digital | A |
| RF12 | Guardar convocatorias en favoritos | B |
| RF13 | Recordatorios de fecha límite y del evento | B |
| RF14 | Editar o cerrar mis ediciones y crear una nueva edición a partir de una anterior | B |
| RF15 | Asignar o cambiar los organizadores de una edición | B |
| RF16 | Registro de asistencia por QR | P |
| RF17 | Constancia descargable en PDF | P |
| RF18 | Calificar la experiencia del evento | P |

## 7. Requisitos no funcionales
- RNF01 Usabilidad: interfaz minimalista, máximo 3 toques para postular.
- RNF02 Multiplataforma: Android y navegador web desde un mismo código.
- RNF03 Rendimiento: listas cargan en menos de 3 s con conexión normal.
- RNF04 Seguridad: Firebase Auth y reglas de Firestore (cada usuario edita solo lo suyo; solo los organizadores de una edición la modifican y ven sus postulantes).
- RNF05 Disponibilidad: servicio en la nube (Firebase).
- RNF06 Escalabilidad: se pueden sumar universidades y tipos de evento sin cambiar código.
- RNF07 Privacidad: el perfil solo se comparte con los organizadores de las ediciones a las que se postula.
- RNF08 Mantenibilidad: código organizado por módulos.

## 8. Módulos y orden de desarrollo
1. **Autenticación y perfil** (RF01, RF02)
2. **Convocatorias** (RF03, RF04, RF05, RF06)
3. **Postulaciones** (RF07, RF08, RF09, RF10)
4. **Historial y constancias** (RF11)
5. Extras B si hay tiempo (RF12 a RF15)

## 9. Pantallas diseñadas y su módulo
Referencias en `docs/diseno/mobile/` y `docs/diseno/web/` (`screen.png`). Hay 12 pantallas en cada plataforma.

| Pantalla (carpeta) | Módulo | Requisitos |
|---|---|---|
| inicio_de_sesión, crear_cuenta | 1 Auth y perfil | RF01 |
| perfil | 1 Auth y perfil | RF02 |
| explorar_convocatorias | 2 Convocatorias | RF05 |
| detalle_convocatoria | 2 y 3 | RF06, RF07 |
| publicar_evento (paso 1: evento, paso 2: primera edición) | 2 Convocatorias | RF03, RF04 |
| mis_eventos (eventos y ediciones del organizador) | 2 Convocatorias | RF03, RF14 |
| detalle_convocatoria_organizador | 2 y 3 | RF09, RF14 |
| gestión_de_postulantes | 3 Postulaciones | RF09, RF10 |
| mis_postulaciones | 3 Postulaciones | RF08 |
| mis_postulaciones_historial | 4 Historial | RF11 |

**Navegación principal (4 destinos, igual en móvil y web):** Explorar, Postulaciones, Mis eventos, Perfil. "Publicar evento" (pasos 1 y 2) se abre desde **Mis eventos** con un botón mostaza (FAB). "Detalle de convocatoria organizador" y "Gestión de postulantes" se abren desde una edición en Mis eventos.

## 10. Sistema de diseño
Fuentes: `docs/diseno/mobile/.../warm_civic_m3/DESIGN.md` (móvil) y `docs/diseno/web/s_mate_civic_desktop/DESIGN.md` (web).

**Regla de oro:** los colores de marca son los hex de esta sección. El bloque YAML de los DESIGN.md (primario #52651E, etc.) es autogenerado por Stitch y NO se usa. No usar `ColorScheme.fromSeed`; construir el `ColorScheme` a mano con estos valores. Prohibido el negro puro (#000000).

### Paleta
| Rol | Nombre | Hex |
|---|---|---|
| Primary | Verde Sabio | #ABC270 |
| Primary container | | #EEF3DC (hover/variante: #E3EFCB) |
| Secondary / CTA | Mostaza Claro | #FEC868 (pressed móvil #E8B355, hover web #F5BF5D) |
| Secondary container | | #FFF0CF |
| Tertiary / acento | Coral Suave | #FDA769 |
| Tertiary container | | #FBE3DC |
| Texto principal / on-primary / on-secondary / on-tertiary | Café Expreso | #473C33 |
| Texto secundario | | #6B5F54 |
| Placeholder (web) | | #A59B90 |
| Fondo | Crema | #FBF8F1 |
| Superficie / tarjetas | Blanco | #FFFFFF |
| Bordes y divisores | | #E5E0D3 |
| Error / texto de error | | #A8321F |

Reglas de contraste:
- Sobre #ABC270, #FEC868, #FDA769 y los contenedores tonales, texto e íconos siempre en #473C33, nunca blanco.
- **#ABC270 solo como relleno estructural** (píldora de navegación activa, tabs, toggles, chips seleccionados, app bar). Nunca como color de texto, ícono suelto ni borde de foco sobre fondo claro.
- Botón deshabilitado: fondo #E5E0D3, texto #6B5F54.

### Estados de postulación (siempre ícono + texto + contenedor, nunca solo color)
| Estado | Contenedor | Texto/ícono | Ícono |
|---|---|---|---|
| aceptada | #E3EFCB | #2F6B2F | check_circle |
| rechazada | #FBE3DC | #A8321F | cancel |
| enviada (en espera) | #FFF0CF | #7A5200 | schedule |

### Tipografía
Plus Jakarta Sans (paquete `google_fonts`).
- Móvil: display 34/800, headline-lg 26/700, headline-md 22/700, headline-sm 18/700, title 16/700, body-lg 16/400, body-md 14/400, body-sm 12/500, label-lg 14/700, label-md 12/600, label-sm 11/600.
- Amplio: H1 800 de 28 a 32 px; el resto igual que móvil.
- Wordmark "Súmate": #473C33 en negrita, con la tilde de la "ú" en Coral #FDA769.

### Forma y espaciado
- Radios: tarjetas y hojas 16 px; inputs y botones 12 px (FAB 16); chips, indicadores de navegación y badges en píldora (9999).
- Grilla de 8 pt (subgrilla 4). Separación entre grupos 24 px, entre secciones 32 px.
- Móvil: margen horizontal 20 px, gutter 16 px, padding de tarjetas 16 px. Amplio: margen 32 px, gutter 24 px, padding de tarjetas 20 px.
- Profundidad por superficie (#FFFFFF sobre #FBF8F1) y borde de 1 px #E5E0D3. Móvil: tarjetas sin sombra; solo hojas modales y barra inferior llevan `0 -4 16 rgba(71,60,51,.04)`. Amplio: sombras en la sección de responsive.

### Componentes
- **Botón primario:** alto 48, fondo #FEC868, texto #473C33 peso 700, radio 12.
- **Tarjeta de evento:** blanca, radio 16, borde 1 px. Cabecera con etiqueta de categoría (#FBE3DC) y favorito; título en negrita; filas de metadatos (fecha, lugar, organizador) con íconos en #6B5F54; pie con cupos o fecha límite y acción.
- **Chips de filtro:** píldora, alto 32. Inactivo: blanco con borde #E5E0D3. Seleccionado: fondo #EEF3DC, borde #ABC270, ícono check de 16 px.
- **Campos de texto:** alto 52 en móvil y 48 en amplio, radio 12, fondo blanco, borde 1 px #E5E0D3. **Foco:** borde 2 px #473C33 + anillo externo 2 px #FEC868 (nunca verde). **Error:** 1.5 px #A8321F con texto de ayuda en el mismo color.
- **Badge de estado:** píldora, ícono 16 + texto 12/600. Móvil: alto 28, padding 4x10. Amplio: padding 6x14.
- **App bar:** fondo #ABC270 o #FBF8F1 con insignia verde; título en #473C33.
- **Barra inferior (móvil, <600 px):** alto 72, blanca, borde superior; 4 destinos: Explorar (`explore`), Postulaciones (`assignment_turned_in`), Mis eventos (`event`), Perfil (`person`); indicador píldora #EEF3DC de 64x32; activo en #473C33 peso 700, inactivo #6B5F54 peso 500.
- **Íconos:** Material Symbols Rounded (en Flutter, `Icons.*_rounded`), rellenos en estado activo.

### Uso de los archivos de diseño
- `screen.png` es la referencia visual: replicar estructura, jerarquía y espaciado.
- `code.html` (HTML/Tailwind) NO se copia ni se convierte; solo sirve para consultar medidas.
- Implementar todo en un único `ThemeData` central (`lib/core/theme/`) y widgets reutilizables (tarjeta de evento, badge de estado, chip de filtro).

## 11. Diseño responsive
Fuentes: `docs/diseno/web/s_mate_civic_desktop/DESIGN.md` y las capturas de `docs/diseno/web/`. Mismo código para móvil y web; solo cambia el layout.

### Breakpoints (centralizar en una sola utilidad, p. ej. `lib/core/responsive.dart`)
- **Compacto** (<600 px): móvil. `NavigationBar` inferior con 4 destinos, lista de 1 columna, márgenes 20 px.
- **Medio** (600 a 1023 px): `NavigationRail` compacto (solo íconos), grilla de 2 columnas, márgenes 24 px.
- **Amplio** (>=1024 px): `NavigationRail` extendido de 240 px fijo, grilla de 3 columnas, márgenes 32 px.

(El punto intermedio de 1024 px es una decisión de implementación, no viene del diseño de Stitch.)

### Layout amplio (referencia: 1440x900)
- Riel izquierdo de 240 px: fondo #FFFFFF, borde derecho 1 px #E5E0D3. Cabecera con el wordmark "Súmate".
- Ítem de navegación: alto mín. 44, padding horizontal 16, radio 12. Inactivo: texto e ícono #6B5F54 (peso 500). Hover: #EEF3DC al 50%. Activo: píldora #EEF3DC, texto #473C33 peso 700, ícono relleno #473C33.
 Activo: relleno píldora #ABC270, texto #473C33 semibold, ícono relleno.
- Contenido: contenedor centrado de ancho máx. 1200 px, margen 32 px, grilla de 12 columnas con gutter 24 px (`GridView` con `maxCrossAxisExtent` o `Wrap`).
  - Tarjetas de convocatoria: 4 columnas (3 por fila).
  - Detalle: tarjeta principal de 8 columnas + panel lateral de 4 columnas (postulación y datos clave).
  - Formularios (login, registro, publicar evento): centrados, ancho máx. 480 a 560 px.
- Filtros de Explorar: panel lateral o fila de chips visible (en móvil, chips con hoja inferior).
- Objetivos táctiles de 44x44 px mínimo en todo elemento clickeable.
- Riel, cabecera: wordmark "Súmate" y una píldora sutil "Arequipa". Pie del riel: bloque de usuario con borde superior 1 px #E5E0D3, avatar circular con iniciales (fondo #FDA769 o #ABC270, texto #473C33), nombre (peso 500) y "Estudiante (universidad)" en 12 px #6B5F54. El ítem "Mis eventos" lleva un contador coral (#FDA769) con la cantidad de elementos pendientes.
- Área de contenido: fondo #FBF8F1. Cada pantalla principal abre con una banda de cabecera #ABC270 con esquinas inferiores de 24 px, título en #473C33 peso 800 (28 a 32 px) y una píldora pequeña "SÚMATE AREQUIPA" sobre el título.
- Tarjetas amplias: sombra suave `0 1px 3px rgba(71,60,51,.06)` (usar esta en lugar de la de la sección anterior si se prefiere más plano).
- Escala amplia de títulos: H1 800 de 28 a 32 px, H2/H3 700 de 18 a 22 px, cuerpo 14 a 16 px, metadatos y badges 600 de 12 a 13 px.

### Controles específicos de la versión amplia
- Botón primario / FAB: #FEC868, texto #473C33 peso 700, alto mín. 48, padding horizontal 24, hover #F5BF5D, FAB radio 16.
- Botón secundario: fondo #EEF3DC, texto #473C33 peso 600, hover #E3EFCB.
- Botón contorno: transparente, borde 1.5 px #473C33, texto #473C33, hover #FBF8F1.
- Contador de notificaciones: #FDA769, texto #473C33, peso 700, píldora.
- Checkbox/radio: 20 px, borde 2 px #6B5F54; marcado = relleno #FEC868 con check #473C33.
- Switch: pista 52x32, radio 16; inactivo #E5E0D3 con pulgar #6B5F54; activo #ABC270 con pulgar #473C33.
- Sombras (solo en amplio): tarjeta `0 2 6 -1 rgba(71,60,51,.05)`; hover `0 6 16 -2 rgba(71,60,51,.08)`; FAB y diálogos `0 12 28 -4 rgba(71,60,51,.12)`.
- Foco de teclado (botones, chips, ítems de navegación): anillo 2 px #473C33 con offset 2 px. En inputs se mantiene el foco de la sección 10.

### Implementación
`LayoutBuilder` en un `AppShell` que elige `NavigationBar` o `NavigationRail` según el ancho. Los destinos y rutas se definen una sola vez y los usan ambos. Probar en Chrome redimensionando la ventana (390, 800 y 1440 px) y en el emulador.

## 12. Reglas de trabajo para el agente
- Trabaja **un módulo a la vez**; al terminar, indícame cómo probarlo y espera mi confirmación antes de seguir.
- Estructura sugerida: `lib/core/{theme,responsive}` y `lib/features/{auth,perfil,eventos,postulaciones,historial}/` con subcarpetas simples (modelos, servicios, pantallas). Sin sobreingeniería.
- Mantén los nombres de campos **exactamente** como en la sección 5.
- Debe funcionar en Android y en web (`flutter run -d chrome`).
- Usa Material 3 y sigue la sección 10 (sistema de diseño), la sección 11 (responsive) y las capturas de `docs/diseno/`. No copies `code.html`.
- Código comentado donde ayude a entender: soy estudiante y debo poder explicarlo.
- No agregues funciones fuera de los requisitos sin preguntarme.
- Escribe las reglas de seguridad de Firestore (`firestore.rules`) acordes al RNF04 antes de terminar el proyecto.
- Datos de ejemplo (seed) para la demo: algunos eventos de distintas universidades.

## 13. Estado actual

### Infraestructura y diseño
- [x] Proyecto Flutter creado
- [x] Repositorio en GitHub conectado
- [x] Prototipo de pantallas (Google Stitch) en `docs/diseno/` (12 móvil + 12 web)
- [x] Nombre y paleta definidos (Súmate, Warm Civic)
- [x] Diseño responsive definido (móvil y web)
- [x] Firebase conectado (Auth + Firestore), verificado en Chrome
- [x] Emulador de Firebase configurado (auth 9099, firestore 8080) y usado para probar

### BACK (capa de datos, sin UI final)
- [x] Paso 2: enums y modelos + tests (`lib/core/enums.dart`, `features/*/modelos/`)
- [x] Paso 3: AuthService y UsuarioService (probado con emulador)
- [x] Paso 4: EventoService y EdicionService + reglas de eventos y ediciones (probado con emulador)
- [x] Paso 5: PostulacionService + reglas de postulaciones (implementado con pantalla de prueba)
- [x] Paso 6: consolidar `firestore.rules`, índices y despliegue
- [x] Paso 7: seed de datos de ejemplo (SeedDemoScreen)
- [ ] Paso 8: pantalla de prueba final / revisión

### FRONT (UI)
- [ ] Base: tema central, `responsive.dart`, `AppShell`
- [ ] Módulo 1: Autenticación y perfil (RF01, RF02)
- [ ] Módulo 2: Convocatorias (RF03 a RF06)
- [ ] Módulo 3: Postulaciones (RF07 a RF10)
- [ ] Módulo 4: Historial y constancias (RF11)
- [ ] Extras B (RF12 a RF15)

### Cierre
- [ ] Probado en Android y web
- [ ] Subido a GitHub (el código ya se sube por paso; falta la entrega final)

### Pendientes técnicos anotados
- Paso 6: en `eventos`, el `update` debe validarse contra `resource.data.administradores` (el paso 5 lo corrige; verificar).
- `editar()` no puede borrar `beneficios` ni `enlaceExterno` una vez puestos (aceptable por ahora).
- RF15: la colección `usuarios` es privada, así que asignar organizadores por correo necesitará un índice mínimo `correo → uid` (decidir al llegar a esa pantalla).
- El navegador muestra avisos rojos en modo debug (assertion de `viewInsets`, fuentes Noto); son del motor de Flutter web, no del código.

*(Actualizar esta sección al terminar cada paso.)*