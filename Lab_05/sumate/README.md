# Súmate

App multiplataforma (Android y web) que conecta organizadores, voluntarios y asistentes de eventos universitarios en Arequipa. Facilita convocatorias, postulaciones y constancias digitales de participación. No es bolsa de trabajo ni red social.

## Stack

- Flutter (Dart) para Android y web
- Firebase Authentication (correo y contraseña)
- Cloud Firestore
- Google Fonts (Plus Jakarta Sans)

## Cómo ejecutar

```bash
cd sumate
flutter pub get
flutter run -d chrome
```

Cuenta de demo: `demo@sumate.pe` / `123456`

La bandera `usarEmulador` en `lib/main.dart` está en `false`: la app usa el proyecto Firebase real (con el seed de demo ya desplegado). No hace falta el emulador local.

## Estructura de carpetas

```text
lib/
  main.dart                 # Entrada, Firebase y bandera de emulador
  app/                      # AuthGate y navegación (AppShell)
  core/                     # Tema, colores, enums, formato, widgets
  features/
    auth/                   # Login y registro
    perfil/                 # Perfil del usuario
    eventos/                # Explorar, publicar, mis eventos, detalle
    postulaciones/          # Mis postulaciones, gestión, constancia
```

## Fuera de alcance (esta entrega)

- Favoritos (RF12)
- Recordatorios (RF13)
- Código QR de asistencia (RF16)
- Constancia en PDF (RF17)
- Calificaciones de la experiencia (RF18)
- Asignar organizadores (RF15)
- Editar edición
