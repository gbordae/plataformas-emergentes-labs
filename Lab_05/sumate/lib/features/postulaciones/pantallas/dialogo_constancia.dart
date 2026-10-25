// Diálogo de constancia digital de participación (RF11).
// Se abre con showConstancia() pasando una Postulacion.
// Diseño sobrio: fondo blanco, borde 1 px #E5E0D3, radio 16, sin negro puro.
// Ancho máximo 420 px. Sin PDF.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/formato.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/wordmark_sumate.dart';
import '../modelos/postulacion.dart';

/// Abre el diálogo de constancia digital a partir de una [Postulacion].
void mostrarConstancia(BuildContext context, Postulacion postulacion) {
  showDialog<void>(
    context: context,
    builder: (_) => _DialogoConstancia(postulacion: postulacion),
  );
}

class _DialogoConstancia extends StatelessWidget {
  final Postulacion postulacion;

  const _DialogoConstancia({required this.postulacion});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Sin color ni elevación propios; el Container lo define
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.superficie, // blanco
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde, width: 1.0), // borde crema
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Título del diálogo
              Text(
                'Constancia de participación',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Separador decorativo superior
              const Divider(color: AppColors.borde),
              const SizedBox(height: 20),

              // Nombre del participante en destacado
              Text(
                postulacion.perfil.nombre.isNotEmpty
                    ? postulacion.perfil.nombre
                    : 'Participante',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textoPrincipal,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Texto principal de la constancia
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textoSecundario,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'participó como '),
                    TextSpan(
                      text: postulacion.rol.etiqueta,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    const TextSpan(text: ' en\n'),
                    TextSpan(
                      text: postulacion.eventoNombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    TextSpan(text: ' – ${postulacion.edicionNombre}'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Metadatos: fecha y lugar
              _FilaDato(
                icono: Icons.calendar_today_rounded,
                texto: fechaCorta(postulacion.fechaInicio),
              ),
              const SizedBox(height: 6),
              _FilaDato(
                icono: Icons.location_on_rounded,
                texto: postulacion.lugar.isNotEmpty
                    ? postulacion.lugar
                    : 'Lugar no especificado',
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.borde),
              const SizedBox(height: 16),

              // Wordmark Súmate al pie
              const WordmarkSumate(fontSize: 20),
              const SizedBox(height: 6),

              // Nota pequeña de generación digital
              Text(
                'Constancia digital generada por Súmate',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.placeholder,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Botón cerrar (sin ancho infinito por estar en un Column)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de metadato con ícono y texto para la constancia.
class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _FilaDato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: AppColors.textoSecundario),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textoSecundario,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
