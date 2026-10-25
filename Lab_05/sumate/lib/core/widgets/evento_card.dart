// Tarjeta de convocatoria/evento para listas y grillas en Súmate.
// Blanca, radio 16, borde 1 px (#E5E0D3), sin sombra, efecto InkWell con radio 16.
// Parámetros: categoria, titulo, fecha, lugar, organizador, pie (Widget) y onTap.
// SIN ícono de favorito (según especificación).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class EventoCard extends StatelessWidget {
  final String categoria;
  final String titulo;
  final String fecha;
  final String lugar;
  final String organizador;
  final Widget? pie;
  final VoidCallback? onTap;

  const EventoCard({
    super.key,
    required this.categoria,
    required this.titulo,
    required this.fecha,
    required this.lugar,
    required this.organizador,
    this.pie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borde, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera con etiqueta de categoría en contenedor terciario (#FBE3DC)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  categoria.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoPrincipal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Título del evento
              Text(
                titulo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Metadatos con íconos rounded en #6B5F54
              _FilaMetadato(
                icono: Icons.calendar_today_rounded,
                texto: fecha,
              ),
              const SizedBox(height: 6),
              _FilaMetadato(
                icono: Icons.location_on_rounded,
                texto: lugar,
              ),
              const SizedBox(height: 6),
              _FilaMetadato(
                icono: Icons.corporate_fare_rounded,
                texto: organizador,
              ),

              // Widget de pie opcional (cupos, acción, badges)
              if (pie != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: AppColors.borde),
                const SizedBox(height: 12),
                pie!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila simple con ícono y texto descriptivo en color secundario.
class _FilaMetadato extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _FilaMetadato({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icono, size: 16, color: AppColors.textoSecundario),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textoSecundario,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
