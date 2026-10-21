// lib/features/eventos/servicios/evento_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/evento.dart';

/// Servicio para gestionar eventos.
class EventoService {
  final FirebaseFirestore _firestore;

  EventoService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene un [Evento] por su ID.
  Future<Evento?> obtener(String eventoId) async {
    final doc = await _firestore.collection('eventos').doc(eventoId).get();
    if (!doc.exists) return null;
    return Evento.fromFirestore(doc);
  }

  /// Lista los eventos donde el usuario es administrador.
  /// No se aplica orderBy en la consulta; el cliente puede ordenar por nombre.
  Future<List<Evento>> misEventos(String uid) async {
    final query = await _firestore
        .collection('eventos')
        .where('administradores', arrayContains: uid)
        .get();
    return query.docs.map((d) => Evento.fromFirestore(d)).toList();
  }
}
