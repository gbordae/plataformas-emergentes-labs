// Tarjeta para mostrar la información y acciones de un postulante (RF09, RF10).
// Muestra perfil, rol, estado, fecha de postulación, habilidades y acciones contextuales.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../enums.dart';
import '../formato.dart';
import '../theme/app_colors.dart';
import '../../features/postulaciones/modelos/postulacion.dart';
import 'estado_badge.dart';

class PostulanteCard extends StatelessWidget {
  final Postulacion postulacion;
  final DateTime fechaInicioEdicion;
  final bool enProceso;
  final void Function(Postulacion, EstadoPostulacion)? onResponder;
  final void Function(Postulacion, bool)? onMarcarAsistio;

  const PostulanteCard({
    super.key,
    required this.postulacion,
    required this.fechaInicioEdicion,
    this.enProceso = false,
    this.onResponder,
    this.onMarcarAsistio,
  });

  /// Extrae las iniciales del nombre (hasta 2 letras).
  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final perfil = postulacion.perfil;
    final universidad =
        perfil.universidad.isNotEmpty ? perfil.universidad : 'Independiente';
    final carrera = perfil.carrera.isNotEmpty ? perfil.carrera : 'Sin carrera';
    final cicloStr = perfil.ciclo != null ? ' · Ciclo ${perfil.ciclo}' : '';
    final ahora = DateTime.now();
    final puedeMarcarAsistencia =
        ahora.isAfter(fechaInicioEdicion) || ahora.isAtSameMomentAs(fechaInicioEdicion);

    return Material(
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borde, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera: Avatar, datos del estudiante y badges de rol y estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    _iniciales(perfil.nombre),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil.nombre.isNotEmpty ? perfil.nombre : 'Postulante',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$universidad · $carrera$cicloStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textoSecundario,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        perfil.correo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Badge de rol
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: postulacion.rol == RolPostulacion.voluntario
                            ? AppColors.secondaryContainer
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        postulacion.rol.etiqueta,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    EstadoBadge(estado: postulacion.estado),
                  ],
                ),
              ],
            ),

            // Sección de habilidades (solo si hay elementos)
            if (perfil.habilidades.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: perfil.habilidades.map((habilidad) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      habilidad,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // Fecha de postulación
            Text(
              'Postuló el ${fechaCorta(postulacion.fecha)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textoSecundario,
              ),
            ),

            // Acciones según el estado y rol
            if (_tieneAcciones) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: AppColors.borde),
              const SizedBox(height: 10),
              if (enProceso)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else
                _buildAcciones(context, puedeMarcarAsistencia),
            ],
          ],
        ),
      ),
    );
  }

  /// Indica si esta postulación tiene alguna acción disponible.
  bool get _tieneAcciones {
    // Voluntario enviado -> Aceptar y Rechazar
    if (postulacion.rol == RolPostulacion.voluntario &&
        postulacion.estado == EstadoPostulacion.enviada) {
      return true;
    }
    // Postulación aceptada -> Marcar Asistió (y si es voluntario sin asistir, Rechazar)
    if (postulacion.estado == EstadoPostulacion.aceptada) {
      return true;
    }
    return false;
  }

  /// Construye los controles de acción (botones o checkbox de asistencia).
  Widget _buildAcciones(BuildContext context, bool puedeMarcarAsistencia) {
    // Caso 1: Voluntario en espera -> Botones Rechazar y Aceptar
    if (postulacion.rol == RolPostulacion.voluntario &&
        postulacion.estado == EstadoPostulacion.enviada) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onResponder?.call(
                postulacion,
                EstadoPostulacion.rechazada,
              ),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textoPrincipal,
                side: const BorderSide(color: AppColors.borde),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onResponder?.call(
                postulacion,
                EstadoPostulacion.aceptada,
              ),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Aceptar'),
            ),
          ),
        ],
      );
    }

    // Caso 2: Postulación aceptada (voluntario o asistente)
    if (postulacion.estado == EstadoPostulacion.aceptada) {
      final puedeRechazarVoluntario =
          postulacion.rol == RolPostulacion.voluntario && !postulacion.asistio;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Checkbox de asistencia
              InkWell(
                onTap: puedeMarcarAsistencia
                    ? () => onMarcarAsistio?.call(
                          postulacion,
                          !postulacion.asistio,
                        )
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: postulacion.asistio,
                      activeColor: AppColors.primary,
                      checkColor: AppColors.textoPrincipal,
                      onChanged: puedeMarcarAsistencia
                          ? (val) {
                              if (val != null) {
                                onMarcarAsistio?.call(postulacion, val);
                              }
                            }
                          : null,
                    ),
                    Text(
                      'Asistió al evento',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: puedeMarcarAsistencia
                            ? AppColors.textoPrincipal
                            : AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón Rechazar voluntario aceptado (solo si no asistió)
              if (puedeRechazarVoluntario)
                OutlinedButton.icon(
                  onPressed: () => onResponder?.call(
                    postulacion,
                    EstadoPostulacion.rechazada,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.borde),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),

          // Mensaje informativo si el evento aún no inicia
          if (!puedeMarcarAsistencia) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                'Disponible desde el inicio del evento (${fechaCorta(fechaInicioEdicion)})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
