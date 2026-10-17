# Sistema Visual Web (Escritorio 1440 × 900 px) — Súmate

Sistema de diseño adaptado a plataforma Web de escritorio (resolución base 1440 × 900 px) para **Súmate**, plataforma de convocatorias cívicas y académicas para estudiantes universitarios en Arequipa, Perú (17 a 25 años).

---

## 1. Identidad y Filosofía de Diseño
- **Estilo:** Material Design 3 cálido, cívico, minimalista y orgánico.
- **Enfoque de producto:** Catálogo cívico y de voluntariado/asistencia. **Sin mecánicas de red social** (0% feed, 0% likes, 0% comentarios, 0% seguidores y 0% chat).
- **Tratamiento visual:** Sin fotos de stock de personas ni ilustraciones recargadas; uso prioritario de espacio en blanco, tipografía expresiva, geometría pura e iconografía Material Symbols redondeada.

---

## 2. Paleta Cromática y Tokens Semánticos

| Rol | Token | Código Hex | Aplicación y Reglas |
|---|---|---|---|
| **Primario** | `primary` | `#ABC270` | Verde Sabio. Cabeceras institucionales, rellenos de elementos seleccionados y switches activos. |
| **Contenedor Tonal** | `primary-container` | `#EEF3DC` | Fondo de píldora de navegación activa, hovers suaves y contenedores destacados. |
| **Secundario** | `secondary` | `#FEC868` | Mostaza Claro. Botón de acción principal (CTA) y botones destacados. **Texto siempre en `#473C33`**. |
| **Acento** | `accent` | `#FDA769` | Coral Suave. Tilde de la «ú» en logotipo «Súmate», insignias (badges) y etiquetas de alerta. **Texto siempre en `#473C33`**. |
| **Neutro Oscuro** | `text-primary` | `#473C33` | Café Expreso. Títulos, encabezados, iconos destacados y textos de alto contraste. **0% negro puro (`#000000`)**. |
| **Neutro Secundario**| `text-secondary`| `#6B5F54` | Subtítulos, metadatos, iconos inactivos y placeholders. |
| **Fondo Global** | `background` | `#FBF8F1` | Fondo general cálido del área de contenido. |
| **Superficie** | `surface` | `#FFFFFF` | Fondo de tarjetas, riel lateral y modales. |
| **Borde / Contorno** | `outline-variant` | `#E5E0D3` | Divisores, bordes de tarjeta de 1 px y delimitadores de campos. |

### Reglas Inviolables de Contraste y Accesibilidad:
1. **Regla de Legibilidad sobre Color:** El texto sobre fondos **Verde Sabio (`#ABC270`)**, **Mostaza Claro (`#FEC868`)** y **Coral Suave (`#FDA769`)** es **estrictamente Café Expreso (`#473C33`)**, **NUNCA blanco**.
2. **Uso del Verde Sabio:** El Verde Sabio **no se utiliza como color de texto**, color de icono independiente ni borde de enfoque sobre fondos claros.
3. **Cero Negro Puro:** Prohibido el uso de `#000000`. Todo el tono oscuro neutro está compuesto por Café Expreso (`#473C33`).

---

## 3. Estados de Postulación (Triple Codificación: Color + Icono + Texto)
Todos los badges de estado deben cumplir con la pauta de no depender únicamente del color para transmitir información:

- **Enviada / En espera:**
  - *Fondo:* `#FFF0CF`
  - *Texto e Icono:* `#7A5200`
  - *Icono obligatorio:* `schedule` (reloj redondeado) + etiqueta *"Enviada"* o *"En revisión"*.
- **Aceptada:**
  - *Fondo:* `#E3EFCB`
  - *Texto e Icono:* `#2F6B2F`
  - *Icono obligatorio:* `check_circle` (check redondeado) + etiqueta *"Aceptada"*.
- **Rechazada:**
  - *Fondo:* `#FBE3DC`
  - *Texto e Icono:* `#A8321F`
  - *Icono obligatorio:* `cancel` (cruz en círculo redondeada) + etiqueta *"Rechazada"*.

---

## 4. Tipografía y Escala (Plus Jakarta Sans)

- **Fuente Primaria:** `Plus Jakarta Sans`, sans-serif.
- **Jerarquía:**
  - *Display / Logotipo:* 800 (ExtraBold) — Logotipo institucional en Café Expreso con tilde de la "ú" en Coral (`#FDA769`).
  - *Títulos de Cabecera (H1):* 800 (ExtraBold), 28–32 px, interlineado 1.2, color `#473C33`.
  - *Títulos de Sección / Tarjeta (H2/H3):* 700 (Bold), 18–22 px, color `#473C33`.
  - *Cuerpo Principal:* 400 (Regular) y 500 (Medium), 14–16 px, color `#473C33`.
  - *Metadatos y Badges:* 600 (SemiBold), 12–13 px.

---

## 5. Arquitectura y Estructura Global Desktop (1440 × 900 px)

### A. Riel de Navegación Lateral Fijo (Sidebar Expandido)
- **Ancho:** `240 px` fijo a la izquierda, altura completa `100vh`.
- **Superficie:** Fondo `#FFFFFF` con borde derecho sutil de 1 px `#E5E0D3`.
- **Cabecera de Marca (Superior):**
  - Margen superior y padding horizontal de 24 px.
  - Logotipo **«Súmate»** en tipografía Plus Jakarta Sans 800 en Café Expreso (`#473C33`), con la tilde de la **«ú»** en Coral Suave (`#FDA769`).
  - Indicador institucional de sede: Píldora sutil «Arequipa».
- **Destinos de Navegación (4 ítems ordenados):**
  1. **Explorar** (`icon: explore`)
  2. **Postulaciones** (`icon: assignment_turned_in`)
  3. **Mis eventos** (`icon: event`) — Incorpora un badge Material 3 en Coral Suave (`#FDA769`) con el número **«5»** en Café Expreso.
  4. **Perfil** (`icon: person`)
- **Estilos de Navegación:**
  - *Destino Activo:* Píldora completa con fondo `#EEF3DC`, icono relleno en `#473C33` y texto en Plus Jakarta Sans negrita (700) en `#473C33`.
  - *Destinos Inactivos:* Icono de contorno en `#6B5F54` y etiqueta en `#6B5F54` (500). Hover con fondo tonal suave `#F5F3EC` o `#EEF3DC/50`.
- **Bloque de Usuario (Pie del Sidebar):**
  - Fijado al fondo del riel lateral con borde superior sutil `#E5E0D3`.
  - Avatar circular con iniciales **«CQ»** en Café sobre fondo Coral suave o Verde Sabio.
  - Nombre: **Camila Quispe** (500) y rol universitario: **Estudiante (UNSA)** (12 px, `#6B5F54`).

### B. Área de Contenido Principal (Derecha)
- **Fondo:** `#FBF8F1` cálido continuo.
- **Dimensiones:** Ocupa el ancho restante (`calc(100vw - 240px)`), centrado con un contenedor interior con `max-width: 1200px` y padding horizontal de 32 px.
- **Banda de Cabecera Institucional:**
  - Banda superior destacada con fondo **Verde Sabio (`#ABC270`)** y esquinas inferiores redondeadas de **24 px** (`rounded-b-[24px]`).
  - Título principal en Plus Jakarta Sans 800 en Café Expreso (`#473C33`).
  - Pastilla institucional traslúcida «SÚMATE AREQUIPA» sobre el título.

---

## 6. Componentes UI, Cuadrícula y Estados

- **Sistema de Cuadrícula (Grid):** Cuadrícula de 12 columnas con separaciones (gutters) de 24 px para organización de tarjetas y catálogos.
- **Tarjetas (Cards):**
  - Fondo blanco puro (`#FFFFFF`).
  - Esquinas redondeadas de **16 px** (`rounded-2xl`).
  - Borde perimetral fino de 1 px en `#E5E0D3` sin sombras pesadas (sombra suave difusa M3 `box-shadow: 0 1px 3px rgba(71,60,51,0.06)`).
- **Campos de Formulario e Inputs:**
  - Esquinas redondeadas de **12 px** (`rounded-xl`).
  - Altura mínima accesible de **44 px**.
  - Borde en `#E5E0D3` y fondo `#FFFFFF` o `#FDFCF9`.
- **Botones:**
  - *Botón Principal (Filled):* Fondo Mostaza Claro (`#FEC868`), texto Café Expreso (`#473C33`) 700, esquinas redondeadas de 12 o 16 px, altura mínima de 44 px. Hover con brillo cálido o elevación M3 sutil.
  - *Botón Tonal / Secundario:* Fondo Verde Tonal (`#EEF3DC`), texto Café Expreso (`#473C33`).
  - *Botón Outlined:* Borde Café de 1.5 px `#473C33`, texto `#473C33`.
- **Estados Interactivos y Accesibilidad:**
  - *Hover:* Transición suave a fondo tonal `#EEF3DC` o realce de borde.
  - *Foco por Teclado (Focus Visible):* Anillo de enfoque de **2 px en Café Expreso (`#473C33`)** con desplazamiento/offset de 2 px (`outline: 2px solid #473C33; outline-offset: 2px`).
  - *Objetivos de Clic:* Mínimo estricto de **44 × 44 px** para todos los elementos interactivos.
