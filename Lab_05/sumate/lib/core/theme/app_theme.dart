// Configuración del tema central de Súmate (Material 3).
// Construido manualmente respetando la paleta Warm Civic y las escalas tipográficas
// de Plus Jakarta Sans según la sección 10 y 11 de CONTEXTO.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Tema principal en modo claro para la aplicación.
  static ThemeData get tema {
    // ── ColorScheme construido a mano (sin ColorScheme.fromSeed) ───────────────
    // Todos los on* van en Café Expreso (#473C33), según reglas de contraste.
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textoPrincipal,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.textoPrincipal,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textoPrincipal,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.textoPrincipal,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.textoPrincipal,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.textoPrincipal,
      error: AppColors.error,
      onError: AppColors.superficie,
      errorContainer: AppColors.tertiaryContainer,
      onErrorContainer: AppColors.error,
      surface: AppColors.superficie,
      onSurface: AppColors.textoPrincipal,
      onSurfaceVariant: AppColors.textoSecundario,
      outline: AppColors.borde,
      outlineVariant: AppColors.borde,
    );

    // ── Escala tipográfica con Plus Jakarta Sans ───────────────────────────────
    // Se construye directamente con TextTheme de Flutter (sin .plusJakartaSansTextTheme())
    // porque google_fonts 9.x lleva su propio material_ui y sus tipos TextTheme no
    // son compatibles con el TextTheme del SDK de Flutter.
    // Display 34/800, Headline-lg 26/700, Headline-md 22/700, Headline-sm 18/700,
    // Title 16/700, Body-lg 16/400, Body-md 14/400, Body-sm 12/500,
    // Label-lg 14/700, Label-md 12/600, Label-sm 11/600.
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.textoPrincipal,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textoPrincipal,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textoPrincipal,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textoPrincipal,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textoPrincipal,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textoPrincipal,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textoPrincipal,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textoSecundario,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textoPrincipal,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textoPrincipal,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textoSecundario,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.fondo,

      // ── Botones ─────────────────────────────────────────────────────────────
      // Botón relleno/elevado: alto 48, fondo #FEC868, texto #473C33 peso 700, radio 12.
      // Deshabilitado: fondo #E5E0D3 y texto #6B5F54.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.borde;
            if (states.contains(WidgetState.pressed)) return AppColors.secondaryPressed;
            if (states.contains(WidgetState.hovered)) return AppColors.secondaryHover;
            return AppColors.secondary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.textoSecundario;
            return AppColors.textoPrincipal;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.borde;
            if (states.contains(WidgetState.pressed)) return AppColors.secondaryPressed;
            if (states.contains(WidgetState.hovered)) return AppColors.secondaryHover;
            return AppColors.secondary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.textoSecundario;
            return AppColors.textoPrincipal;
          }),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      // Botón delineado: borde 1.5 px #473C33, texto #473C33, radio 12.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          foregroundColor: const WidgetStatePropertyAll(AppColors.textoPrincipal),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.textoPrincipal, width: 1.5),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // ── Campos de texto ─────────────────────────────────────────────────────
      // Alto ~52, radio 12, fondo blanco, borde 1 px #E5E0D3.
      // Foco: borde 2 px #473C33 (NUNCA verde).
      // Error: 1.5 px #A8321F con texto de ayuda en el mismo color.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.placeholder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borde, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.textoPrincipal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2.0),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.error,
          fontSize: 12,
        ),
      ),

      // ── Tarjetas ────────────────────────────────────────────────────────────
      // Blanca, radio 16, borde 1 px #E5E0D3, sin sombra, sin tinte de superficie.
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borde, width: 1.0),
        ),
      ),

      // ── Chips ───────────────────────────────────────────────────────────────
      // Píldora, alto 32; inactivo blanco con borde #E5E0D3; seleccionado fondo #EEF3DC,
      // borde #ABC270, check de 16 px.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.superficie,
        selectedColor: AppColors.primaryContainer,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.borde, width: 1.0),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textoPrincipal,
        ),
        checkmarkColor: AppColors.textoPrincipal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),

      // ── Barra de navegación inferior (móvil) ────────────────────────────────
      // Alto 72, fondo blanco, indicador píldora #EEF3DC de 64x32,
      // etiqueta activa #473C33 peso 700, inactiva #6B5F54 peso 500.
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.superficie,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textoSecundario,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.textoPrincipal, size: 24);
          }
          return const IconThemeData(color: AppColors.textoSecundario, size: 24);
        }),
      ),

      // ── Riel de navegación (medio y amplio) ──────────────────────────────────
      // Fondo blanco, indicador #EEF3DC, mismos colores de texto e íconos.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.superficie,
        indicatorColor: AppColors.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textoPrincipal,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textoSecundario,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppColors.textoPrincipal,
          size: 24,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textoSecundario,
          size: 24,
        ),
      ),

      // ── Botón flotante de acción (FAB) ──────────────────────────────────────
      // Fondo #FEC868, ícono #473C33, radio 16.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textoPrincipal,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Barra de aplicación (AppBar) ────────────────────────────────────────
      // Fondo #FBF8F1, título #473C33, sin elevación.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fondo,
        foregroundColor: AppColors.textoPrincipal,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Iconos de la barra de estado oscuros sobre fondo crema (Android edge-to-edge).
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textoPrincipal,
        ),
      ),
    );
  }
}
