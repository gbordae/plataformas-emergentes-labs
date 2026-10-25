// Utilidades responsive para Súmate.
// Define breakpoints (compacto, medio, amplio), márgenes y columnas
// según la sección 11 de CONTEXTO.md.

import 'package:flutter/material.dart';

/// Categoría de tamaño de pantalla según el ancho disponible.
enum TamanoPantalla {
  /// Móvil (<600 px).
  compacto,

  /// Tablet o pantalla mediana (600 a 1023 px).
  medio,

  /// Desktop o pantalla ancha (>=1024 px).
  amplio,
}

/// Helpers globales para diseño responsive.
class Responsive {
  Responsive._();

  /// Determina la categoría del tamaño de pantalla a partir del [BuildContext].
  static TamanoPantalla tamano(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho < 600) return TamanoPantalla.compacto;
    if (ancho < 1024) return TamanoPantalla.medio;
    return TamanoPantalla.amplio;
  }

  /// Determina la categoría del tamaño a partir del ancho numérico directo.
  static TamanoPantalla tamanoPorAncho(double ancho) {
    if (ancho < 600) return TamanoPantalla.compacto;
    if (ancho < 1024) return TamanoPantalla.medio;
    return TamanoPantalla.amplio;
  }

  /// Margen horizontal según breakpoint:
  /// Compacto: 20 px, Medio: 24 px, Amplio: 32 px.
  static double margenHorizontal(BuildContext context) {
    switch (tamano(context)) {
      case TamanoPantalla.compacto:
        return 20.0;
      case TamanoPantalla.medio:
        return 24.0;
      case TamanoPantalla.amplio:
        return 32.0;
    }
  }

  /// Columnas recomendadas para grillas de tarjetas:
  /// Compacto: 1 columna, Medio: 2 columnas, Amplio: 3 columnas.
  static int columnasGrilla(BuildContext context) {
    switch (tamano(context)) {
      case TamanoPantalla.compacto:
        return 1;
      case TamanoPantalla.medio:
        return 2;
      case TamanoPantalla.amplio:
        return 3;
    }
  }

  /// Espaciado (gutter) recomendado entre tarjetas:
  /// Compacto/Medio: 16 px, Amplio: 24 px.
  static double gutter(BuildContext context) {
    switch (tamano(context)) {
      case TamanoPantalla.compacto:
      case TamanoPantalla.medio:
        return 16.0;
      case TamanoPantalla.amplio:
        return 24.0;
    }
  }
}

/// Widget que centra su [child] con un ancho máximo de 1200 px
/// y aplica el margen horizontal según el breakpoint activo.
class ContenidoCentrado extends StatelessWidget {
  final Widget child;
  final double anchoMaximo;
  final EdgeInsetsGeometry? paddingAdicional;

  const ContenidoCentrado({
    super.key,
    required this.child,
    this.anchoMaximo = 1200.0,
    this.paddingAdicional,
  });

  @override
  Widget build(BuildContext context) {
    final margenH = Responsive.margenHorizontal(context);

    Widget contenido = Padding(
      padding: EdgeInsets.symmetric(horizontal: margenH),
      child: child,
    );

    if (paddingAdicional != null) {
      contenido = Padding(
        padding: paddingAdicional!,
        child: contenido,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: contenido,
      ),
    );
  }
}
