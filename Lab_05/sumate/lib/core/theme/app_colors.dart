// Constantes de color para la aplicación Súmate.
// Definidas según la paleta Warm Civic (sección 10 de CONTEXTO.md).
// Prohibido el uso de negro puro (#000000).

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Constructor privado para evitar instanciación

  // ── Colores de marca y contenedores ──────────────────────────────────────────
  /// Verde Sabio (#ABC270). Relleno estructural (píldoras, tabs, chips seleccionados).
  static const Color primary = Color(0xFFABC270);

  /// Verde Sabio contenedor (#EEF3DC).
  static const Color primaryContainer = Color(0xFFEEF3DC);

  /// Verde Sabio contenedor variante/hover (#E3EFCB).
  static const Color primaryContainerHover = Color(0xFFE3EFCB);

  /// Mostaza Claro (#FEC868). Color de acción principal / CTA.
  static const Color secondary = Color(0xFFFEC868);

  /// Mostaza pressed en móvil (#E8B355).
  static const Color secondaryPressed = Color(0xFFE8B355);

  /// Mostaza hover en web (#F5BF5D).
  static const Color secondaryHover = Color(0xFFF5BF5D);

  /// Mostaza contenedor (#FFF0CF).
  static const Color secondaryContainer = Color(0xFFFFF0CF);

  /// Coral Suave (#FDA769). Color terciario / acento (tilde de Súmate, notificaciones).
  static const Color tertiary = Color(0xFFFDA769);

  /// Coral contenedor (#FBE3DC).
  static const Color tertiaryContainer = Color(0xFFFBE3DC);

  // ── Textos y neutros ────────────────────────────────────────────────────────
  /// Café Expreso (#473C33). Texto principal y on-primary/secondary/tertiary.
  static const Color textoPrincipal = Color(0xFF473C33);

  /// Texto secundario (#6B5F54).
  static const Color textoSecundario = Color(0xFF6B5F54);

  /// Placeholder (#A59B90).
  static const Color placeholder = Color(0xFFA59B90);

  /// Crema (#FBF8F1). Fondo principal de la app.
  static const Color fondo = Color(0xFFFBF8F1);

  /// Superficie (#FFFFFF). Fondo de tarjetas y hojas.
  static const Color superficie = Color(0xFFFFFFFF);

  /// Bordes y divisores (#E5E0D3).
  static const Color borde = Color(0xFFE5E0D3);

  /// Error y texto de error (#A8321F).
  static const Color error = Color(0xFFA8321F);

  // ── Estados de postulación ──────────────────────────────────────────────────
  // Aceptada
  static const Color estadoAceptadaFondo = Color(0xFFE3EFCB);
  static const Color estadoAceptadaTexto = Color(0xFF2F6B2F);

  // Rechazada
  static const Color estadoRechazadaFondo = Color(0xFFFBE3DC);
  static const Color estadoRechazadaTexto = Color(0xFFA8321F);

  // Enviada (en espera)
  static const Color estadoEnviadaFondo = Color(0xFFFFF0CF);
  static const Color estadoEnviadaTexto = Color(0xFF7A5200);
}
