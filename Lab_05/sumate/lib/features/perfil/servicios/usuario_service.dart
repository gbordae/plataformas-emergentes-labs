// lib/features/perfil/servicios/usuario_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../perfil/modelos/usuario.dart';

/// Servicio para gestionar el perfil de usuario en Firestore.
///
/// Permite obtener, escuchar en tiempo real y actualizar el documento
/// `usuarios/{uid}`. El correo y uid no pueden modificarse a través de
/// `actualizar` (se consideran inmutables una vez creados).
class UsuarioService {
  final FirebaseFirestore _firestore;

  UsuarioService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene el usuario con el [uid] especificado.
  ///
  /// Devuelve `null` si el documento no existe.
  Future<Usuario?> obtener(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromFirestore(doc);
  }

  /// Escucha cambios del usuario en tiempo real.
  ///
  /// Emite `null` si el documento se elimina.
  Stream<Usuario?> escuchar(String uid) {
    return _firestore.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Usuario.fromFirestore(snap);
    });
  }

  /// Actualiza los campos editables del [usuario] en Firestore.
  ///
  /// No permite modificar `correo` ni `uid`.
  Future<void> actualizar(Usuario usuario) async {
    final data = usuario.toMap();
    await _firestore.collection('usuarios').doc(usuario.uid).update(data);
  }
}
