// lib/features/postulaciones/servicios/postulacion_service.dart
//
// Servicio de postulaciones: usa transacciones para garantizar
// consistencia (cupos, duplicados) e id determinista para impedir
// que un mismo usuario postule dos veces con el mismo rol.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/enums.dart';
import '../../../core/errores.dart';
import '../../eventos/modelos/edicion.dart';
import '../../perfil/modelos/usuario.dart';
import '../modelos/postulacion.dart';

class PostulacionService {
  final FirebaseFirestore _firestore;

  PostulacionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── RF07: Postular ──────────────────────────────────────────────────────
  /// Crea una postulación dentro de UNA transacción que lee antes de
  /// escribir para validar reglas de negocio (duplicado, cupo, estado).
  /// Devuelve el id determinista de la postulación creada.
  Future<String> postular({
    required String edicionId,
    required RolPostulacion rol,
    required String uid,
  }) async {
    final postId = Postulacion.construirId(edicionId, uid, rol);
    final edicionRef = _firestore.collection('ediciones').doc(edicionId);
    final usuarioRef = _firestore.collection('usuarios').doc(uid);
    final postRef = _firestore.collection('postulaciones').doc(postId);

    await _firestore.runTransaction((tx) async {
      // Lecturas primero (requisito de Firestore para transacciones)
      final edicionSnap = await tx.get(edicionRef);
      final usuarioSnap = await tx.get(usuarioRef);
      final postSnap = await tx.get(postRef);

      // Validaciones de negocio
      if (!edicionSnap.exists) {
        throw ErrorNegocio('La edición no existe');
      }
      if (postSnap.exists) {
        throw ErrorNegocio('Ya postulaste a esta convocatoria como ${rol.etiqueta}');
      }

      final edicion = Edicion.fromFirestore(edicionSnap);

      // Distinguir por qué no admite postulaciones
      if (!edicion.admitePostulaciones(rol)) {
        if (edicion.estado != EstadoEdicion.abierta) {
          throw ErrorNegocio('La edición no está abierta');
        }
        if (edicion.finalizadaEfectiva) {
          throw ErrorNegocio('La edición ya finalizó');
        }
        final conv = edicion.convocatoriaDe(rol);
        if (!conv.abierta) {
          throw ErrorNegocio('La convocatoria de ${rol.etiqueta.toLowerCase()}s está cerrada');
        }
        if (conv.vencida) {
          throw ErrorNegocio('El plazo de postulación ya venció');
        }
        if (!conv.hayCupo) {
          throw ErrorNegocio('Cupo de ${rol.etiqueta.toLowerCase()}s lleno');
        }
      }

      // Snapshot del perfil al momento de postular
      final usuario = usuarioSnap.exists
          ? Usuario.fromFirestore(usuarioSnap)
          : Usuario(uid: uid, nombre: '', correo: '');

      final ahora = DateTime.now();

      // Asistentes se aceptan automáticamente; voluntarios quedan en espera
      final estado = rol == RolPostulacion.asistente
          ? EstadoPostulacion.aceptada
          : EstadoPostulacion.enviada;

      final postulacion = Postulacion(
        id: postId,
        edicionId: edicionId,
        usuarioId: uid,
        rol: rol,
        estado: estado,
        asistio: false,
        fecha: ahora,
        perfil: PerfilPostulante.desdeUsuario(usuario),
        eventoNombre: edicion.eventoNombre,
        edicionNombre: edicion.nombre,
        fechaInicio: edicion.fechaInicio,
        lugar: edicion.lugar,
      );

      tx.set(postRef, postulacion.toMap());

      // Solo asistentes incrementan su contador al postular.
      // Los voluntarios se cuentan al ser ACEPTADOS por el organizador.
      if (rol == RolPostulacion.asistente) {
        tx.update(edicionRef, {
          'asistentes.ocupados': FieldValue.increment(1),
        });
      }
    });

    return postId;
  }

  // ── Obtener una postulación ─────────────────────────────────────────────

  Future<Postulacion?> obtener(String id) async {
    final doc = await _firestore.collection('postulaciones').doc(id).get();
    if (!doc.exists) return null;
    return Postulacion.fromFirestore(doc);
  }

  // ── RF08: Mis postulaciones ─────────────────────────────────────────────
  /// Un solo where (usuarioId), sin orderBy en Firestore.
  /// El orden por fecha descendente se aplica en el cliente para evitar
  /// crear un índice compuesto innecesario.
  Future<List<Postulacion>> misPostulaciones(String uid) async {
    final query = await _queryPorUsuario(uid).get();
    return _ordenarPorFechaDesc(_mapear(query.docs));
  }

  /// Misma consulta que [misPostulaciones], en tiempo real con snapshots().
  Stream<List<Postulacion>> escucharMisPostulaciones(String uid) {
    return _queryPorUsuario(uid).snapshots().map(
          (snap) => _ordenarPorFechaDesc(_mapear(snap.docs)),
        );
  }

  // ── RF09: Contar postulaciones pendientes (en espera) ───────────────────
  /// Devuelve el total de postulaciones en estado 'enviada' para una edición.
  /// Cumple la regla de Firestore al filtrar por edicionId.
  Future<int> contarPendientes(String edicionId) async {
    final aggregateQuery = await _queryPendientes(edicionId).count().get();
    return aggregateQuery.count ?? 0;
  }

  /// Conteo en vivo de postulaciones en espera (badge "por revisar").
  Stream<int> escucharCantidadPendientes(String edicionId) {
    return _queryPendientes(edicionId).snapshots().map((snap) => snap.docs.length);
  }

  // ── RF09: Postulantes de una edición ────────────────────────────────────
  /// Un solo where (edicionId), sin orderBy. Filtros de rol y estado
  /// se aplican en el cliente. Solo los organizadores podrán leerlo
  /// (lo imponen las reglas de Firestore).
  Future<List<Postulacion>> postulantesDeEdicion(
    String edicionId, {
    RolPostulacion? rol,
    EstadoPostulacion? estado,
  }) async {
    final query = await _queryPorEdicion(edicionId).get();
    return _filtrarYOrdenarPostulantes(_mapear(query.docs), rol: rol, estado: estado);
  }

  /// Misma consulta que [postulantesDeEdicion], en tiempo real con snapshots().
  Stream<List<Postulacion>> escucharPostulantesDeEdicion(
    String edicionId, {
    RolPostulacion? rol,
    EstadoPostulacion? estado,
  }) {
    return _queryPorEdicion(edicionId).snapshots().map(
          (snap) => _filtrarYOrdenarPostulantes(
            _mapear(snap.docs),
            rol: rol,
            estado: estado,
          ),
        );
  }

  // ── RF09: Responder postulación (aceptar/rechazar) ──────────────────────
  /// Transacción que lee la postulación y la edición antes de escribir.
  /// Solo aplica a voluntarios (los asistentes se aceptan solos).
  /// Si se acepta: exige cupo y suma +1 a voluntarios.ocupados.
  /// Si se rechaza habiendo estado aceptada: resta -1.
  Future<void> responder(
    String postulacionId,
    EstadoPostulacion nuevo,
  ) async {
    if (nuevo != EstadoPostulacion.aceptada &&
        nuevo != EstadoPostulacion.rechazada) {
      throw ErrorNegocio('El nuevo estado debe ser aceptada o rechazada');
    }

    final postRef = _firestore.collection('postulaciones').doc(postulacionId);

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw ErrorNegocio('Postulación no encontrada');

      final post = Postulacion.fromFirestore(postSnap);

      if (post.rol != RolPostulacion.voluntario) {
        throw ErrorNegocio('Solo se responden postulaciones de voluntarios');
      }
      if (post.asistio) {
        throw ErrorNegocio('No se puede cambiar el estado: ya asistió');
      }

      final edicionRef =
          _firestore.collection('ediciones').doc(post.edicionId);
      final edicionSnap = await tx.get(edicionRef);
      if (!edicionSnap.exists) throw ErrorNegocio('Edición no encontrada');

      final edicion = Edicion.fromFirestore(edicionSnap);

      // Aceptar voluntario: verificar cupo y sumar
      if (nuevo == EstadoPostulacion.aceptada &&
          post.estado != EstadoPostulacion.aceptada) {
        if (!edicion.voluntarios.hayCupo) {
          throw ErrorNegocio('Cupo de voluntarios lleno');
        }
        tx.update(edicionRef, {
          'voluntarios.ocupados': FieldValue.increment(1),
        });
      }

      // Rechazar voluntario que estaba aceptado: restar
      if (nuevo == EstadoPostulacion.rechazada &&
          post.estado == EstadoPostulacion.aceptada) {
        tx.update(edicionRef, {
          'voluntarios.ocupados': FieldValue.increment(-1),
        });
      }

      tx.update(postRef, {'estado': nuevo.name});
    });
  }

  // ── RF10: Marcar asistencia ─────────────────────────────────────────────
  /// Transacción: solo se puede marcar si el estado es aceptada.
  /// Al marcar true, se exige que la fechaInicio ya haya llegado.
  Future<void> marcarAsistio(String postulacionId, bool asistio) async {
    final postRef = _firestore.collection('postulaciones').doc(postulacionId);

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw ErrorNegocio('Postulación no encontrada');

      final post = Postulacion.fromFirestore(postSnap);

      if (post.estado != EstadoPostulacion.aceptada) {
        throw ErrorNegocio('Solo se marca asistencia en postulaciones aceptadas');
      }

      if (asistio && DateTime.now().isBefore(post.fechaInicio)) {
        throw ErrorNegocio('No se puede marcar asistencia antes de la fecha de inicio');
      }

      tx.update(postRef, {'asistio': asistio});
    });
  }

  // ── Cancelar postulación (dueño) ────────────────────────────────────────
  /// Borra la postulación del dueño si las reglas de negocio lo permiten.
  /// Voluntario: solo estado enviada y sin asistencia (no toca cupos).
  /// Asistente: solo si el evento no ha empezado; resta 1 a ocupados en la
  /// misma transacción. El id determinista queda libre para volver a postular.
  Future<void> cancelar(String postulacionId, String uid) async {
    final postRef = _firestore.collection('postulaciones').doc(postulacionId);

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        throw ErrorNegocio('Postulación no encontrada');
      }

      final post = Postulacion.fromFirestore(postSnap);

      if (post.usuarioId != uid) {
        throw ErrorNegocio('No puedes cancelar esta postulación');
      }
      if (post.asistio) {
        throw ErrorNegocio('Ya se registró tu asistencia');
      }

      if (post.rol == RolPostulacion.voluntario) {
        if (post.estado == EstadoPostulacion.aceptada) {
          throw ErrorNegocio(
            'Tu postulación ya fue aceptada; contacta al organizador para cancelarla',
          );
        }
        if (post.estado != EstadoPostulacion.enviada) {
          throw ErrorNegocio('No se puede cancelar una postulación rechazada');
        }
      } else {
        // Asistente: no se puede cancelar si el evento ya comenzó.
        if (!DateTime.now().isBefore(post.fechaInicio)) {
          throw ErrorNegocio('El evento ya comenzó');
        }

        final edicionRef =
            _firestore.collection('ediciones').doc(post.edicionId);
        final edicionSnap = await tx.get(edicionRef);
        if (!edicionSnap.exists) {
          throw ErrorNegocio('Edición no encontrada');
        }
        final edicion = Edicion.fromFirestore(edicionSnap);
        // No bajar ocupados por debajo de 0 si los datos estuvieran inconsistentes.
        if (edicion.asistentes.ocupados > 0) {
          tx.update(edicionRef, {
            'asistentes.ocupados': FieldValue.increment(-1),
          });
        }
      }

      tx.delete(postRef);
    });
  }

  // ── RF11: Historial de participaciones ──────────────────────────────────
  /// Reutiliza misPostulaciones y filtra en el cliente por asistio == true.
  /// Ordena por fechaInicio descendente (los eventos más recientes primero).
  Future<List<Postulacion>> historial(String uid) async {
    return _aHistorial(await misPostulaciones(uid));
  }

  /// Historial en vivo: misma consulta por usuarioId, filtro asistio en el cliente.
  Stream<List<Postulacion>> escucharHistorial(String uid) {
    return escucharMisPostulaciones(uid).map(_aHistorial);
  }

  // ── Consultas y mapeos compartidos (un solo where, sin orderBy) ─────────

  Query<Map<String, dynamic>> _queryPorUsuario(String uid) {
    return _firestore
        .collection('postulaciones')
        .where('usuarioId', isEqualTo: uid);
  }

  Query<Map<String, dynamic>> _queryPorEdicion(String edicionId) {
    return _firestore
        .collection('postulaciones')
        .where('edicionId', isEqualTo: edicionId);
  }

  Query<Map<String, dynamic>> _queryPendientes(String edicionId) {
    return _firestore
        .collection('postulaciones')
        .where('edicionId', isEqualTo: edicionId)
        .where('estado', isEqualTo: EstadoPostulacion.enviada.name);
  }

  List<Postulacion> _mapear(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map(Postulacion.fromFirestore).toList();
  }

  List<Postulacion> _ordenarPorFechaDesc(List<Postulacion> lista) {
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  List<Postulacion> _filtrarYOrdenarPostulantes(
    List<Postulacion> lista, {
    RolPostulacion? rol,
    EstadoPostulacion? estado,
  }) {
    var filtrada = lista;
    if (rol != null) {
      filtrada = filtrada.where((p) => p.rol == rol).toList();
    }
    if (estado != null) {
      filtrada = filtrada.where((p) => p.estado == estado).toList();
    }
    filtrada.sort((a, b) => a.fecha.compareTo(b.fecha));
    return filtrada;
  }

  List<Postulacion> _aHistorial(List<Postulacion> todas) {
    final participaciones = todas.where((p) => p.asistio).toList();
    participaciones.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return participaciones;
  }
}
