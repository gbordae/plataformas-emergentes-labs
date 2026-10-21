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
    final query = await _firestore
        .collection('postulaciones')
        .where('usuarioId', isEqualTo: uid)
        .get();

    final lista = query.docs
        .map((d) => Postulacion.fromFirestore(d))
        .toList();

    // Orden descendente por fecha (más reciente primero)
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
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
    final query = await _firestore
        .collection('postulaciones')
        .where('edicionId', isEqualTo: edicionId)
        .get();

    var lista = query.docs
        .map((d) => Postulacion.fromFirestore(d))
        .toList();

    // Filtros opcionales en el cliente
    if (rol != null) {
      lista = lista.where((p) => p.rol == rol).toList();
    }
    if (estado != null) {
      lista = lista.where((p) => p.estado == estado).toList();
    }

    // Orden ascendente por fecha (primero los más antiguos)
    lista.sort((a, b) => a.fecha.compareTo(b.fecha));
    return lista;
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

  // ── RF11: Historial de participaciones ──────────────────────────────────
  /// Reutiliza misPostulaciones y filtra en el cliente por asistio == true.
  /// Ordena por fechaInicio descendente (los eventos más recientes primero).
  Future<List<Postulacion>> historial(String uid) async {
    final todas = await misPostulaciones(uid);
    final participaciones = todas.where((p) => p.asistio).toList();
    participaciones.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    return participaciones;
  }
}
