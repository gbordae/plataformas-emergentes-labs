// Cabecera visual superior para pantallas de Súmate.
// En pantallas amplias y medias (>=600 px): muestra una banda de color #ABC270
// con esquinas inferiores redondeadas a 24 px, píldora "SÚMATE AREQUIPA" y título peso 800.
// En móvil compacto (<600 px): muestra un título limpio integrado directamente sobre fondo crema.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../responsive.dart';
import '../theme/app_colors.dart';

class CabeceraPantalla extends StatelessWidget {
  final String titulo;
  final String? subtitulo;

  const CabeceraPantalla({
    super.key,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final tamano = Responsive.tamano(context);
    final esCompacto = tamano == TamanoPantalla.compacto;

    // En pantallas compactas (móvil): cabecera minimalista sobre fondo crema.
    // SafeArea(bottom: false) evita que el título quede bajo el reloj/batería.
    // El margen horizontal es el mismo que filtros y tarjetas (responsive.dart).
    if (esCompacto) {
      final margen = Responsive.margenHorizontal(context);
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(margen, 16, margen, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textoPrincipal,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitulo!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // En pantallas medias y amplias: banda verde sabio con esquinas inferiores redondeadas.
    // El padding superior incluye la barra de estado; el horizontal lo pone ContenidoCentrado
    // (evita duplicar el margen de 24/32 px).
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        0,
        28 + MediaQuery.paddingOf(context).top,
        0,
        28,
      ),
      child: ContenidoCentrado(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Píldora sutil superior "SÚMATE AREQUIPA"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.superficie.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'SÚMATE AREQUIPA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textoPrincipal,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitulo!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textoPrincipal.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
