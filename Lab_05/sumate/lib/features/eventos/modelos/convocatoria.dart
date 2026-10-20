import 'package:cloud_firestore/cloud_firestore.dart';

/// Convocatoria para voluntarios o asistentes dentro de una edición.
///
/// No es una colección separada en Firestore: es un objeto anidado
/// dentro del documento de la edición (campos `voluntarios` y `asistentes`).
class Convocatoria {
  final bool abierta;
  final int cupos;
  final int ocupados;
  final String? beneficios; // solo relevante para voluntarios
  final DateTime? fechaLimite; // null = sin límite de fecha
  final String? enlaceExterno; // p. ej. un Google Form externo

  const Convocatoria({
    required this.abierta,
    required this.cupos,
    this.ocupados = 0,
    this.beneficios,
    this.fechaLimite,
    this.enlaceExterno,
  });

  /// Convocatoria cerrada por defecto (sin cupos ni datos).
  const Convocatoria.cerrada()
      : abierta = false,
        cupos = 0,
        ocupados = 0,
        beneficios = null,
        fechaLimite = null,
        enlaceExterno = null;

  // ── Getters de lógica de negocio ────────────────────────────────────────

  /// ¿Quedan cupos disponibles?
  bool get hayCupo => ocupados < cupos;

  /// ¿Ya pasó la fecha límite?
  bool get vencida => fechaLimite != null && fechaLimite!.isBefore(DateTime.now());

  /// ¿Se pueden recibir postulaciones? (abierta + cupo + no vencida)
  bool get admitePostulaciones => abierta && hayCupo && !vencida;

  // ── Deserialización ─────────────────────────────────────────────────────

  /// Si el [map] es null (la edición no tiene esa convocatoria),
  /// devuelve una convocatoria cerrada.
  factory Convocatoria.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Convocatoria.cerrada();
    return Convocatoria(
      abierta: map['abierta'] as bool? ?? false,
      cupos: map['cupos'] as int? ?? 0,
      ocupados: map['ocupados'] as int? ?? 0,
      beneficios: map['beneficios'] as String?,
      // Firestore envía las fechas como Timestamp
      fechaLimite: (map['fechaLimite'] as Timestamp?)?.toDate(),
      enlaceExterno: map['enlaceExterno'] as String?,
    );
  }

  // ── Serialización ───────────────────────────────────────────────────────

  /// Convierte a Map para Firestore. Los campos opcionales solo se incluyen
  /// si tienen valor (enlaceExterno tampoco si está vacío).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'abierta': abierta,
      'cupos': cupos,
      'ocupados': ocupados,
    };
    if (beneficios != null) map['beneficios'] = beneficios;
    if (fechaLimite != null) map['fechaLimite'] = Timestamp.fromDate(fechaLimite!);
    if (enlaceExterno != null && enlaceExterno!.isNotEmpty) {
      map['enlaceExterno'] = enlaceExterno;
    }
    return map;
  }
}
