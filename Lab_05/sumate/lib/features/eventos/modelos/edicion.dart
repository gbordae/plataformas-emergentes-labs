import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums.dart';
import 'convocatoria.dart';

/// Edición = una realización concreta de un evento (p. ej. "Hack4Edu 2026").
///
/// Denormaliza [eventoNombre] y [tipo] del evento padre para evitar
/// lecturas extra al listar ediciones. Cada edición tiene sus propios
/// [organizadores], independientes de los administradores del evento.
class Edicion {
  final String id;
  final String eventoId;
  final String eventoNombre; // denormalizado del evento
  final TipoEvento tipo; // denormalizado del evento
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String lugar;
  final Modalidad modalidad;
  final String universidad; // '' = abierto a cualquiera
  final EstadoEdicion estado;
  final List<String> organizadores; // uids con permiso de gestionar esta edición
  final Convocatoria voluntarios;
  final Convocatoria asistentes;

  const Edicion({
    required this.id,
    required this.eventoId,
    required this.eventoNombre,
    required this.tipo,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.lugar,
    required this.modalidad,
    this.universidad = '',
    this.estado = EstadoEdicion.abierta,
    this.organizadores = const [],
    this.voluntarios = const Convocatoria.cerrada(),
    this.asistentes = const Convocatoria.cerrada(),
  });

  // copyWith for Edicion
  Edicion copyWith({
    String? id,
    String? eventoId,
    String? eventoNombre,
    TipoEvento? tipo,
    String? nombre,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? lugar,
    Modalidad? modalidad,
    String? universidad,
    EstadoEdicion? estado,
    List<String>? organizadores,
    Convocatoria? voluntarios,
    Convocatoria? asistentes,
  }) => Edicion(
    id: id ?? this.id,
    eventoId: eventoId ?? this.eventoId,
    eventoNombre: eventoNombre ?? this.eventoNombre,
    tipo: tipo ?? this.tipo,
    nombre: nombre ?? this.nombre,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin ?? this.fechaFin,
    lugar: lugar ?? this.lugar,
    modalidad: modalidad ?? this.modalidad,
    universidad: universidad ?? this.universidad,
    estado: estado ?? this.estado,
    organizadores: organizadores ?? this.organizadores,
    voluntarios: voluntarios ?? this.voluntarios,
    asistentes: asistentes ?? this.asistentes,
  );

  // ── Lógica de negocio ───────────────────────────────────────────────────

  /// Devuelve la convocatoria correspondiente al [rol].
  Convocatoria convocatoriaDe(RolPostulacion rol) {
    return rol == RolPostulacion.voluntario ? voluntarios : asistentes;
  }

  /// La edición está efectivamente finalizada si su estado es [finalizada]
  /// o si la fecha de fin ya pasó (aunque el organizador no la haya cerrado).
  bool get finalizadaEfectiva =>
      estado == EstadoEdicion.finalizada || DateTime.now().isAfter(fechaFin);

  /// ¿Puede un usuario postular con este [rol]?
  /// Requiere que la edición esté abierta, no finalizada, y que la
  /// convocatoria específica admita postulaciones.
  bool admitePostulaciones(RolPostulacion rol) =>
      estado == EstadoEdicion.abierta &&
      !finalizadaEfectiva &&
      convocatoriaDe(rol).admitePostulaciones;

  // ── Deserialización ─────────────────────────────────────────────────────

  factory Edicion.fromMap(Map<String, dynamic> map, {required String id}) {
    return Edicion(
      id: id,
      eventoId: map['eventoId'] as String? ?? '',
      eventoNombre: map['eventoNombre'] as String? ?? '',
      tipo: TipoEvento.desde(map['tipo'] as String?),
      nombre: map['nombre'] as String? ?? '',
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (map['fechaFin'] as Timestamp).toDate(),
      lugar: map['lugar'] as String? ?? '',
      modalidad: Modalidad.desde(map['modalidad'] as String?),
      universidad: map['universidad'] as String? ?? '',
      estado: EstadoEdicion.desde(map['estado'] as String?),
      organizadores: List<String>.from(map['organizadores'] ?? []),
      voluntarios: Convocatoria.fromMap(
          map['voluntarios'] as Map<String, dynamic>?),
      asistentes: Convocatoria.fromMap(
          map['asistentes'] as Map<String, dynamic>?),
    );
  }

  factory Edicion.fromFirestore(DocumentSnapshot doc) {
    return Edicion.fromMap(doc.data() as Map<String, dynamic>? ?? {}, id: doc.id);
  }

  // ── Serialización ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'eventoId': eventoId,
      'eventoNombre': eventoNombre,
      'tipo': tipo.name,
      'nombre': nombre,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'lugar': lugar,
      'modalidad': modalidad.name,
      'universidad': universidad,
      'estado': estado.name,
      'organizadores': organizadores,
      'voluntarios': voluntarios.toMap(),
      'asistentes': asistentes.toMap(),
    };
  }
}
