import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums.dart';
import '../../perfil/modelos/usuario.dart';

/// Snapshot del perfil del usuario en el momento de postular.
///
/// Se guarda dentro de la postulación para que el organizador vea los datos
/// tal como estaban al postular, sin que cambios posteriores en el perfil
/// alteren lo que el organizador ya revisó.
class PerfilPostulante {
  final String nombre;
  final String correo;
  final String universidad;
  final String carrera;
  final int? ciclo;
  final List<String> habilidades;

  const PerfilPostulante({
    required this.nombre,
    required this.correo,
    this.universidad = '',
    this.carrera = '',
    this.ciclo,
    this.habilidades = const [],
  });

  /// Crea el snapshot desde el [Usuario] actual.
  factory PerfilPostulante.desdeUsuario(Usuario usuario) {
    return PerfilPostulante(
      nombre: usuario.nombre,
      correo: usuario.correo,
      universidad: usuario.universidad,
      carrera: usuario.carrera,
      ciclo: usuario.ciclo,
      habilidades: List<String>.from(usuario.habilidades),
    );
  }

  /// Tolerante a Map nulo o campos faltantes.
  factory PerfilPostulante.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PerfilPostulante(nombre: '', correo: '');
    }
    return PerfilPostulante(
      nombre: map['nombre'] as String? ?? '',
      correo: map['correo'] as String? ?? '',
      universidad: map['universidad'] as String? ?? '',
      carrera: map['carrera'] as String? ?? '',
      ciclo: map['ciclo'] as int?,
      habilidades: List<String>.from(map['habilidades'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'universidad': universidad,
      'carrera': carrera,
      'ciclo': ciclo,
      'habilidades': habilidades,
    };
  }
}

/// Postulación de un usuario a una edición con un rol específico.
///
/// El [id] es determinista: `{edicionId}_{usuarioId}_{rol.name}`,
/// lo que impide que un usuario postule dos veces con el mismo rol
/// a la misma edición (regla de negocio clave).
///
/// Denormaliza [eventoNombre], [edicionNombre], [fechaInicio] y [lugar]
/// para poder listar "Mis postulaciones" sin leer la edición completa.
class Postulacion {
  final String id;
  final String edicionId;
  final String usuarioId;
  final RolPostulacion rol;
  final EstadoPostulacion estado;
  final bool asistio; // el organizador marca si participó realmente
  final DateTime fecha; // fecha en que se creó la postulación
  final PerfilPostulante perfil; // snapshot del perfil al postular

  // Campos denormalizados para listar sin leer la edición
  final String eventoNombre;
  final String edicionNombre;
  final DateTime fechaInicio;
  final String lugar;

  const Postulacion({
    required this.id,
    required this.edicionId,
    required this.usuarioId,
    required this.rol,
    this.estado = EstadoPostulacion.enviada,
    this.asistio = false,
    required this.fecha,
    required this.perfil,
    required this.eventoNombre,
    required this.edicionNombre,
    required this.fechaInicio,
    required this.lugar,
  });

  /// Id determinista que evita postulaciones duplicadas.
  /// Formato: `{edicionId}_{usuarioId}_{rol.name}`
  static String construirId(
      String edicionId, String usuarioId, RolPostulacion rol) {
    return '${edicionId}_${usuarioId}_${rol.name}';
  }

  // ── Deserialización ─────────────────────────────────────────────────────

  factory Postulacion.fromMap(Map<String, dynamic> map, {required String id}) {
    return Postulacion(
      id: id,
      edicionId: map['edicionId'] as String? ?? '',
      usuarioId: map['usuarioId'] as String? ?? '',
      rol: RolPostulacion.desde(map['rol'] as String?),
      estado: EstadoPostulacion.desde(map['estado'] as String?),
      asistio: map['asistio'] as bool? ?? false,
      fecha: (map['fecha'] as Timestamp).toDate(),
      perfil: PerfilPostulante.fromMap(
          map['perfil'] as Map<String, dynamic>?),
      eventoNombre: map['eventoNombre'] as String? ?? '',
      edicionNombre: map['edicionNombre'] as String? ?? '',
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      lugar: map['lugar'] as String? ?? '',
    );
  }

  factory Postulacion.fromFirestore(DocumentSnapshot doc) {
    return Postulacion.fromMap(
        doc.data() as Map<String, dynamic>? ?? {}, id: doc.id);
  }

  // ── Serialización ───────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'edicionId': edicionId,
      'usuarioId': usuarioId,
      'rol': rol.name,
      'estado': estado.name,
      'asistio': asistio,
      'fecha': Timestamp.fromDate(fecha),
      'perfil': perfil.toMap(),
      'eventoNombre': eventoNombre,
      'edicionNombre': edicionNombre,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'lugar': lugar,
    };
  }
}
