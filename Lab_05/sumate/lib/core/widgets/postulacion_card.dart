// Tarjeta de postulación para las pestañas Activas e Historial.
// Muestra los datos denormalizados de la postulación sin leer colecciones extra.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/enums.dart';
import '../../core/formato.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/estado_badge.dart';
import '../../features/postulaciones/modelos/postulacion.dart';

/// Tarjeta usada en la pestaña "Activas": muestra EstadoBadge.
/// Tarjeta usada en la pestaña "Historial": muestra badge "Asististe" y botón "Ver constancia".
class PostulacionCard extends StatelessWidget {
  final Postulacion postulacion;

  /// Si es true, muestra badge "Asististe" + botón constancia en lugar de EstadoBadge.
  final bool esHistorial;

  final VoidCallback onTap;
  final VoidCallback? onVerConstancia;

  const PostulacionCard({
    super.key,
    required this.postulacion,
    required this.esHistorial,
    required this.onTap,
    this.onVerConstancia,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: nombre de la edición + badge de rol
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la edición como título principal
                  Expanded(
                    child: Text(
                      postulacion.edicionNombre,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Etiqueta de rol en contenedor terciario
                  _EtiquetaRol(rol: postulacion.rol),
                ],
              ),

              const SizedBox(height: 6),

              // Nombre del evento (serie/marca)
              Text(
                postulacion.eventoNombre,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textoSecundario,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Metadatos: fecha y lugar del evento
              _FilaMetadato(
                icono: Icons.calendar_today_rounded,
                texto: fechaCorta(postulacion.fechaInicio),
              ),
              const SizedBox(height: 5),
              _FilaMetadato(
                icono: Icons.location_on_rounded,
                texto: postulacion.lugar.isNotEmpty
                    ? postulacion.lugar
                    : 'Lugar por confirmar',
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borde),
              const SizedBox(height: 12),

              // Pie: badge de asistencia en historial, o estado en activas
              if (esHistorial)
                _PieHistorial(onVerConstancia: onVerConstancia)
              else
                EstadoBadge(estado: postulacion.estado),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de rol (Voluntario / Asistente) en contenedor terciario.
class _EtiquetaRol extends StatelessWidget {
  final RolPostulacion rol;
  const _EtiquetaRol({required this.rol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        rol.etiqueta,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textoPrincipal,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Fila de metadato con ícono y texto en color secundario.
class _FilaMetadato extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _FilaMetadato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 15, color: AppColors.textoSecundario),
        const SizedBox(width: 6),
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

/// Pie del Historial: badge verde "Asististe" + botón "Ver constancia".
class _PieHistorial extends StatelessWidget {
  final VoidCallback? onVerConstancia;
  const _PieHistorial({this.onVerConstancia});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Badge verde "Asististe": mismo estilo que EstadoBadge, colores fijos
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.estadoAceptadaFondo, // #E3EFCB
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.estadoAceptadaTexto, // #2F6B2F
              ),
              const SizedBox(width: 6),
              Text(
                'Asististe',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.estadoAceptadaTexto,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Botón de contorno "Ver constancia" (sin ancho infinito, no Size.fromHeight)
        OutlinedButton.icon(
          onPressed: onVerConstancia,
          icon: const Icon(Icons.workspace_premium_rounded, size: 16),
          label: const Text('Ver constancia'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: AppColors.textoPrincipal,
            side: const BorderSide(color: AppColors.borde, width: 1.5),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
