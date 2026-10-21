// lib/core/errores.dart

/// Error de negocio personalizado con mensaje en español.
class ErrorNegocio implements Exception {
  final String mensaje;
  ErrorNegocio(this.mensaje);
  @override
  String toString() => mensaje;
}
