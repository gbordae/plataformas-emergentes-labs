import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums.dart';

/// Evento = la marca o serie (p. ej. "Hack4Edu").
///
/// Cada evento puede tener varias ediciones (realizaciones concretas).
/// Los [administradores] son los uids que pueden crear nuevas ediciones.
class Evento {
  final String id;
  final String nombre;
  final TipoEvento tipo;
  final String descripcion;
  final String entidad; // organización responsable
  final List<String> administradores; // uids con permiso de crear ediciones

  const Evento({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.entidad,
    this.administradores = const [],
  });

  Evento copyWith({
    String? id,
    String? nombre,
    TipoEvento? tipo,
    String? descripcion,
    String? entidad,
    List<String>? administradores,
  }) => Evento(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    tipo: tipo ?? this.tipo,
    descripcion: descripcion ?? this.descripcion,
    entidad: entidad ?? this.entidad,
    administradores: administradores ?? this.administradores,
  );

  // ── Deserialización ─────────────────────────────────────────────────────

  factory Evento.fromMap(Map<String, dynamic> map, {required String id}) {
    return Evento(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      tipo: TipoEvento.desde(map['tipo'] as String?),
      descripcion: map['descripcion'] as String? ?? '',
      entidad: map['entidad'] as String? ?? '',
      administradores: List<String>.from(map['administradores'] ?? []),
    );
  }

  factory Evento.fromFirestore(DocumentSnapshot doc) {
    return Evento.fromMap(doc.data() as Map<String, dynamic>? ?? {}, id: doc.id);
  }

  // ── Serialización ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'tipo': tipo.name, // se guarda el name ASCII
      'descripcion': descripcion,
      'entidad': entidad,
      'administradores': administradores,
    };
  }
}
