// Logotipo textual (wordmark) de Súmate.
// Muestra "Súmate" en negrita (#473C33) con la letra "ú" coloreada en coral (#FDA769)
// para destacar la identidad de marca de forma limpia y nítida.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class WordmarkSumate extends StatelessWidget {
  final double fontSize;

  const WordmarkSumate({
    super.key,
    this.fontSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.textoPrincipal,
          letterSpacing: -0.5,
        ),
        children: const [
          TextSpan(text: 'S'),
          // Letra "ú" completa en coral suave (#FDA769) para dar el acento de marca característico
          TextSpan(
            text: 'ú',
            style: TextStyle(color: AppColors.tertiary),
          ),
          TextSpan(text: 'mate'),
        ],
      ),
    );
  }
}
