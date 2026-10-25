// Badge en píldora para estados de postulación de Súmate.
// Siempre combina contenedor + ícono (16 px) + texto (12/600), nunca solo color.
// Cumple con la tabla de estados de la sección 10 de CONTEXTO.md.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../enums.dart';
import '../theme/app_colors.dart';

class EstadoBadge extends StatelessWidget {
  final EstadoPostulacion estado;

  const EstadoBadge({
    super.key,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    // Configuración según el estado de la postulación
    final Color colorFondo;
    final Color colorContenido;
    final IconData icono;

    switch (estado) {
      case EstadoPostulacion.aceptada:
        colorFondo = AppColors.estadoAceptadaFondo;
        colorContenido = AppColors.estadoAceptadaTexto;
        icono = Icons.check_circle_rounded;
        break;
      case EstadoPostulacion.rechazada:
        colorFondo = AppColors.estadoRechazadaFondo;
        colorContenido = AppColors.estadoRechazadaTexto;
        icono = Icons.cancel_rounded;
        break;
      case EstadoPostulacion.enviada:
        colorFondo = AppColors.estadoEnviadaFondo;
        colorContenido = AppColors.estadoEnviadaTexto;
        icono = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(9999), // Forma píldora
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icono,
            size: 16,
            color: colorContenido,
          ),
          const SizedBox(width: 6),
          Text(
            estado.etiqueta,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorContenido,
            ),
          ),
        ],
      ),
    );
  }
}
