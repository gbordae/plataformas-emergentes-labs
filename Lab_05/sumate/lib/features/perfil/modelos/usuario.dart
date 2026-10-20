import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil del usuario registrado.
///
/// El [uid] es el id del documento en Firestore y NO se guarda como campo
/// dentro del documento (se recibe como parámetro en [fromMap]).
/// [universidad] vacía ('') significa "independiente" (sin universidad).
class Usuario {
  final String uid;
  final String nombre;
  final String correo;
  final String universidad; // '' = independiente
  final String carrera;
  final int? ciclo; // nullable porque es opcional
  final List<String> habilidades;
  final List<String> intereses;

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    this.universidad = '',
    this.carrera = '',
    this.ciclo,
    this.habilidades = const [],
    this.intereses = const [],
  });

  // ── Deserialización ─────────────────────────────────────────────────────

  /// Construye un [Usuario] desde un Map de Firestore.
  /// Tolerante a campos faltantes: usa valores por defecto.
  factory Usuario.fromMap(Map<String, dynamic> map, {required String id}) {
    return Usuario(
      uid: id,
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      universidad: map['universidad'] as String? ?? '',
      carrera: map['carrera'] as String? ?? '',
      ciclo: map['ciclo'] as int?,
      habilidades: List<String>.from(map['habilidades'] ?? []),
      intereses: List<String>.from(map['intereses'] ?? []),
    );
  }

  /// Atajo para construir desde un [DocumentSnapshot] de Firestore.
  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    return Usuario.fromMap(doc.data() as Map<String, dynamic>? ?? {}, id: doc.id);
  }

  // ── Serialización ───────────────────────────────────────────────────────

  /// Convierte a Map para guardar en Firestore. No incluye [uid]
  /// porque es el id del documento, no un campo.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'universidad': universidad,
      'carrera': carrera,
      'ciclo': ciclo,
      'habilidades': habilidades,
      'intereses': intereses,
    };
  }

  // ── copyWith ────────────────────────────────────────────────────────────

  /// Crea una copia con los campos editables modificados.
  /// [correo] y [uid] no se pueden editar.
  Usuario copyWith({
    String? nombre,
    String? universidad,
    String? carrera,
    int? ciclo,
    List<String>? habilidades,
    List<String>? intereses,
  }) {
    return Usuario(
      uid: uid,
      nombre: nombre ?? this.nombre,
      correo: correo, // no editable
      universidad: universidad ?? this.universidad,
      carrera: carrera ?? this.carrera,
      ciclo: ciclo ?? this.ciclo,
      habilidades: habilidades ?? this.habilidades,
      intereses: intereses ?? this.intereses,
    );
  }
}
