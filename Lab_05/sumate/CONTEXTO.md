# CONTEXTO DEL PROYECTO: Súmate

> Léelo completo antes de escribir código. Si algo contradice lo que se te pide, avisa antes de implementar.

## 1. Resumen
**Súmate** es una app multiplataforma (Android + web) que conecta **organizadores, voluntarios y asistentes** de eventos de cualquier universidad o institución de Arequipa (hackathons, ponencias, lanzamientos, campañas, conferencias abiertas, etc.). La motivación del usuario es **networking, experiencia, aprendizaje y certificados** (útiles para LinkedIn). No es bolsa de trabajo ni de prácticas, y **no es una red social**.

Contexto académico: Laboratorio 5 del curso Plataformas Emergentes (UNSA, Ingeniería de Sistemas). App multiplataforma en Flutter que resuelve un problema real con enfoque de proyección social. Se evalúa: funcionalidades, diseño minimalista, correspondencia entre funciones e interfaces, conocimiento aplicado (uso de componentes del framework), originalidad y calidad del informe.

## 2. Problema (árbol resumido)
**Problema central:** los estudiantes de Arequipa se enteran tarde o nunca de oportunidades de voluntariado y eventos abiertos, y los organizadores tienen dificultad para conseguir voluntarios y asistentes.

- **Causas:** convocatorias dispersas en WhatsApp/afiches; formularios repetidos con los mismos datos; no hay espacio común entre universidades; los organizadores no conocen las habilidades de los postulantes; no hay registro ordenado de participaciones y certificados.
- **Efectos:** eventos con pocos voluntarios o asistentes; estudiantes sin acceso a experiencia y networking; selección lenta y desordenada; participaciones difíciles de demostrar.
- **Proyección social:** acceso equitativo a oportunidades de formación y voluntariado, y vínculo entre universidades y comunidad.

## 3. Stack
- Flutter (Dart), plataformas: Android y web. Una sola base de código.
- Firebase: Authentication (correo y contraseña) y Cloud Firestore.
- Paquetes: `firebase_core`, `firebase_auth`, `cloud_firestore`.
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
  nombre, correo, universidad, carrera, ciclo,
  habilidades[], intereses[]

eventos/{eventoId}                  // la marca / serie
  nombre, tipo (hackathon | ponencia | lanzamiento | campaña | conferencia | otro),
  descripcion, entidad, administradores[uid]

ediciones/{edicionId}               // cada realización
  eventoId, nombre, fechaInicio, fechaFin,
  lugar, modalidad (presencial | remoto | híbrido), universidad,
  estado (abierta | cerrada | finalizada),
  organizadores[uid],
  voluntarios: { abierta, cupos, beneficios, fechaLimite, enlaceExterno }
  asistentes:  { abierta, cupos, fechaLimite, enlaceExterno }

postulaciones/{edicionId_usuarioId_rol}
  edicionId, usuarioId, rol (voluntario | asistente),
  estado (enviada | aceptada | rechazada),
  asistio (bool), fecha
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

## 9. Reglas de trabajo para el agente
- Trabaja **un módulo a la vez**; al terminar, indícame cómo probarlo y espera mi confirmación antes de seguir.
- Estructura sugerida por módulos: `lib/features/{auth,perfil,eventos,postulaciones,historial}/` con subcarpetas simples (modelos, servicios, pantallas). Sin sobreingeniería.
- Mantén los nombres de campos **exactamente** como en la sección 5.
- Debe funcionar en Android y en web (`flutter run -d chrome`).
- Usa Material 3 y diseño minimalista; respeta las capturas de referencia de `docs/diseno/` si existen.
- Código comentado donde ayude a entender: soy estudiante y debo poder explicarlo.
- No agregues funciones fuera de los requisitos sin preguntarme.
- Escribe las reglas de seguridad de Firestore (`firestore.rules`) acordes al RNF04 antes de terminar el proyecto.
- Datos de ejemplo (seed) para la demo: algunos eventos de distintas universidades.

## 10. Estado actual
- [x] Proyecto Flutter creado
- [ ] Firebase conectado (Auth + Firestore)
- [ ] Prototipo de pantallas (Google Stitch) en `docs/diseno/`
- [ ] Módulo 1: Autenticación y perfil
- [ ] Módulo 2: Convocatorias
- [ ] Módulo 3: Postulaciones
- [ ] Módulo 4: Historial y constancias
- [ ] Reglas de Firestore
- [ ] Datos de ejemplo
- [ ] Probado en Android y web
- [ ] Subido a GitHub

*(Actualizar esta sección al terminar cada paso.)*