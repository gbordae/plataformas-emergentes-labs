// lib/features/eventos/servicios/edicion_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errores.dart';
import '../modelos/edicion.dart';
import '../modelos/evento.dart';
import '../modelos/convocatoria.dart';
import '../../../core/enums.dart';

class EdicionService {
  final FirebaseFirestore _firestore;

  EdicionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> crear(Edicion edicion) async {
    final docRef = _firestore.collection('ediciones').doc();
    final data = edicion.copyWith(id: docRef.id).toMap();
    await docRef.set(data);
    return docRef.id;
  }

  Future<Edicion?> obtener(String id) async {
    final doc = await _firestore.collection('ediciones').doc(id).get();
    if (!doc.exists) return null;
    return Edicion.fromFirestore(doc);
  }

  Future<List<Edicion>> misEdicionesAbiertas(String uid) async {
    final query = await _firestore
        .collection('ediciones')
        .where('organizadores', arrayContains: uid)
        .where('estado', isEqualTo: EstadoEdicion.abierta.name)
        .get();
    return query.docs.map((d) => Edicion.fromFirestore(d)).toList();
  }

  Future<List<Edicion>> misEdicionesAbiertasFiltros(String uid, {TipoEvento? tipo}) async {
    var col = _firestore.collection('ediciones')
        .where('organizadores', arrayContains: uid)
        .where('estado', isEqualTo: EstadoEdicion.abierta.name);
    if (tipo != null) {
      col = col.where('tipo', isEqualTo: tipo.name);
    }
    final query = await col.get();
    return query.docs.map((d) => Edicion.fromFirestore(d)).toList();
  }

  Future<List<Edicion>> misEdiciones(String uid) async {
    final query = await _firestore
        .collection('ediciones')
        .where('organizadores', arrayContains: uid)
        .get();
    return query.docs.map((d) => Edicion.fromFirestore(d)).toList();
  }

  Future<void> editar(Edicion edicion) async {
    final docRef = _firestore.collection('ediciones').doc(edicion.id);
    final exists = await docRef.get();
    if (!exists.exists) throw ErrorNegocio('Edición no encontrada');
    await docRef.update(edicion.toMap());
  }

  Future<void> cerrar(String id) async {
    final docRef = _firestore.collection('ediciones').doc(id);
    final snap = await docRef.get();
    if (!snap.exists) throw ErrorNegocio('Edición no encontrada');
    await docRef.update({'estado': EstadoEdicion.cerrada.name});
  }

  Future<void> reabrir(String id) async {
    final docRef = _firestore.collection('ediciones').doc(id);
    final snap = await docRef.get();
    if (!snap.exists) throw ErrorNegocio('Edición no encontrada');
    await docRef.update({'estado': EstadoEdicion.abierta.name});
  }

  Future<String> crearNuevaEdicionDesde(String sourceId) async {
    final source = await obtener(sourceId);
    if (source == null) throw ErrorNegocio('Edición origen no encontrada');
    // Build new Convocatoria objects without fechaLimite and reset ocupados
    final nuevaVoluntarios = Convocatoria(
      abierta: source.voluntarios.abierta,
      cupos: source.voluntarios.cupos,
      ocupados: 0,
      beneficios: source.voluntarios.beneficios,
      fechaLimite: null,
      enlaceExterno: source.voluntarios.enlaceExterno,
    );
    final nuevaAsistentes = Convocatoria(
      abierta: source.asistentes.abierta,
      cupos: source.asistentes.cupos,
      ocupados: 0,
      // asistentes no tienen beneficios
      fechaLimite: null,
      enlaceExterno: source.asistentes.enlaceExterno,
    );
    final nueva = Edicion(
      id: '',
      eventoId: source.eventoId,
      eventoNombre: source.eventoNombre,
      tipo: source.tipo,
      nombre: source.nombre,
      fechaInicio: source.fechaInicio,
      fechaFin: source.fechaFin,
      lugar: source.lugar,
      modalidad: source.modalidad,
      universidad: source.universidad,
      estado: source.estado,
      organizadores: source.organizadores,
      voluntarios: nuevaVoluntarios,
      asistentes: nuevaAsistentes,
    );
    final newId = await crear(nueva);
    return newId;
  }

  /// Crea un evento y su primera edición en una transacción.
  /// Devuelve el ID de la edición creada.
  Future<String> crearEventoConPrimeraEdicion({
    required Evento evento,
    required Edicion edicion,
    required String uid,
  }) async {
    final batch = _firestore.batch();
    final eventoRef = _firestore.collection('eventos').doc();
    final eventoData = evento.copyWith(id: eventoRef.id).toMap();
    batch.set(eventoRef, eventoData);
    final edicionRef = _firestore.collection('ediciones').doc();
    final edicionData = edicion.copyWith(
      id: edicionRef.id,
      eventoId: eventoRef.id,
      eventoNombre: evento.nombre,
      organizadores: [uid],
    ).toMap();
    batch.set(edicionRef, edicionData);
    await batch.commit();
    return edicionRef.id;
  }
}
