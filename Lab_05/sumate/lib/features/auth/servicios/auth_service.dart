// lib/features/auth/servicios/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../perfil/modelos/usuario.dart';

/// Excepción de dominio para errores de autenticación.
///
/// Se traduce el código de `FirebaseAuthException` a mensajes en español.
class AuthError implements Exception {
  final String mensaje;
  AuthError(this.mensaje);
  @override
  String toString() => 'AuthError: $mensaje';
}

/// Servicio de autenticación que encapsula FirebaseAuth y Firestore.
///
/// Se permite inyectar instancias (útiles en tests) o usar las
/// instancias por defecto (`FirebaseAuth.instance`, `FirebaseFirestore.instance`).
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream que notifica cambios en la sesión (login / logout).
  Stream<User?> get cambiosSesion => _auth.authStateChanges();

  /// Usuario actualmente autenticado o `null`.
  User? get usuarioActual => _auth.currentUser;

  /// Registra un nuevo usuario con email y contraseña.
  ///
  /// Si la escritura del documento de perfil falla, se elimina el usuario
  /// de Auth para evitar cuentas huérfanas.
  Future<void> registrar({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    try {
      // Crear cuenta en Firebase Auth.
      final cred = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) {
        throw AuthError('No se pudo obtener el uid del usuario recién creado.');
      }
      // Crear documento de perfil en Firestore.
      final usuario = Usuario(
        uid: uid,
        nombre: nombre,
        correo: correo,
        // los demás campos usan sus valores por defecto.
      );
      await _firestore.collection('usuarios').doc(uid).set(usuario.toMap());
    } on FirebaseAuthException catch (e) {
      throw AuthError(_mapFirebaseError(e));
    } catch (_) {
      // Si falla Firestore, borrar la cuenta creada.
      final current = _auth.currentUser;
      if (current != null) {
        await current.delete();
      }
      rethrow;
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<void> iniciarSesion({required String correo, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: correo, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthError(_mapFirebaseError(e));
    }
  }

  /// Cierra la sesión actual.
  Future<void> cerrarSesion() async => await _auth.signOut();

  /// Traduce los códigos de error de FirebaseAuth a mensajes legibles.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';
      case 'email-already-in-use':
        return 'El correo electrónico ya está en uso.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'user-not-found':
        return 'No existe un usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Credencial inválida.';
      case 'too-many-requests':
        return 'Demasiadas solicitudes, intente más tarde.';
      case 'network-request-failed':
        return 'Problema de red, verifique su conexión.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
    }
  }
}
