# Súmate - Ejecutable y Guía de Instalación (Lab 05)

## 1. Descripción y Versión
**Súmate** es una aplicación multiplataforma desarrollada en Flutter que conecta estudiantes con organizadores de voluntariados y eventos académicos o comunitarios en Arequipa, simplificando la postulación a convocatorias y la acreditación de participación.  
**Versión:** `1.0.0+1` (1.0.0)

## 2. Instalación en Android
- **Archivo ejecutable:** `sumate.apk` (~54.8 MB)
- **Versión mínima de Android:** Android 7.0 (Nougat, API nivel 24) o superior (`minSdkVersion = 24`).

### Pasos para instalar:
1. Copiar o transferir el archivo `sumate.apk` a la memoria del dispositivo móvil Android (mediante cable USB, almacenamiento en la nube, mensajería o descarga).
2. Localizar y abrir el archivo `sumate.apk` desde el explorador de archivos o la carpeta de descargas del teléfono.
3. Si el sistema muestra una advertencia de seguridad, habilitar la opción **"Permitir la instalación de aplicaciones desconocidas"** para la app o explorador desde donde se ejecuta.
4. Pulsar **Instalar** y, tras completarse la instalación, presionar **Abrir**.

## 3. Acceso a Versión Web
- **Enlace de Firebase Hosting:** `https://sumate-3f35e.web.app`

## 4. Video de Demostración
- **Enlace al video:** `https://drive.google.com/file/d/1lkwuBMT9diAjDrPFAuI-zqxcahUNmvYx/view?usp=drive_link`

## 5. Cuentas de Prueba
La aplicación está conectada al entorno en la nube de Firebase y cuenta con las siguientes credenciales preconfiguradas:

| Rol | Correo electrónico | Contraseña | Descripción / Propósito |
|---|---|---|---|
| **Organizador Demo** | `demo@sumate.pe` | `123456` | Organizador principal con los eventos y ediciones de demostración sembrados |
| **Organizador de Pruebas** | `prueba@sumate.pe` | `123456` | Cuenta para crear, publicar y administrar convocatorias |
| **Postulante Voluntario** | `vol@sumate.pe` | `123456` | Cuenta de estudiante para postular al rol de voluntario |
| **Postulante Asistente** | `asi@sumate.pe` | `123456` | Cuenta de estudiante para registrarse como asistente |

*Nota:* También es posible registrar cuentas nuevas directamente desde el formulario "Crear cuenta" de la app.

## 6. Enlace al Repositorio
- **Repositorio:** [https://github.com/gbordae/plataformas-emergentes-labs.git](https://github.com/gbordae/plataformas-emergentes-labs.git)
- **Ruta del proyecto:** `Lab_05/sumate`

## 7. Requerimientos de Red
> **Nota técnica:** La aplicación utiliza servicios en la nube de Firebase en producción (proyecto `sumate-3f35e`, Cloud Firestore y Firebase Authentication), por lo que **requiere conexión activa a internet** para el inicio de sesión, sincronización de convocatorias y registro de postulaciones.
