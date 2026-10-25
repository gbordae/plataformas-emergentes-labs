// Chip reutilizable para filtros en Súmate.
// Píldora de alto ~32 px.
// Inactivo: blanco con borde #E5E0D3.
// Seleccionado: fondo #EEF3DC, borde #ABC270, check de 16 px.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class FiltroChip extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final ValueChanged<bool>? onSelected;

  const FiltroChip({
    super.key,
    required this.label,
    required this.seleccionado,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.textoPrincipal,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w600,
        color: AppColors.textoPrincipal,
      ),
      backgroundColor: AppColors.superficie,
      selectedColor: AppColors.primaryContainer,
      shape: StadiumBorder(
        side: BorderSide(
          color: seleccionado ? AppColors.primary : AppColors.borde,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}
