// lib/main.dart
// Platform import removed for web compatibility
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'features/auth/servicios/auth_service.dart';
import 'features/perfil/servicios/usuario_service.dart';
import 'pruebas/prueba_back.dart';
import 'pruebas/seed_demo.dart';

// Cambiar a true para usar los emuladores locales
const bool usarEmulador = true;

// Modo de siembra de datos de ejemplo (seed demo).
// Para sembrar en la base de datos real de Firebase:
// 1. Poner usarEmulador = false y modoSeed = true.
// 2. Ejecutar la app (flutter run -d chrome).
// 3. Pulsar el botón "Sembrar datos de demo" en la pantalla.
// 4. Volver a dejar usarEmulador = true (o según se requiera) y modoSeed = false.
const bool modoSeed = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (usarEmulador) {
    // Seleccionar host según plataforma
    final host = kIsWeb
        ? 'localhost'
        : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: modoSeed ? const SeedDemoScreen() : const PruebaBackScreen(),
  ));
}

/// Aplicación de prueba que recorre los pasos solicitados.
class AuthDemoApp extends StatelessWidget {
  const AuthDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthDemoScreen(),
    );
  }
}

class AuthDemoScreen extends StatefulWidget {
  const AuthDemoScreen({super.key});

  @override
  State<AuthDemoScreen> createState() => _AuthDemoScreenState();
}

class _AuthDemoScreenState extends State<AuthDemoScreen> {
  final AuthService _authService = AuthService();
  final UsuarioService _usuarioService = UsuarioService();
  final List<String> _log = [];

  void _addLog(String mensaje) => setState(() => _log.add(mensaje));

  // 1️⃣ Registrar (o login si ya existe)
  Future<void> _registrarOLogin() async {
    const correo = 'prueba@sumate.pe';
    const password = '123456';
    const nombre = 'Prueba';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('✅ Registro exitoso');
    } on AuthError catch (e) {
      if (e.mensaje.contains('ya está en uso')) {
        // El usuario ya existe, intentar login
        try {
          await _authService.iniciarSesion(correo: correo, password: password);
          _addLog('⚠️ Usuario ya registrado, login exitoso');
        } on AuthError catch (e2) {
          _addLog('❌ Error al intentar login: ${e2.mensaje}');
        }
      } else {
        _addLog('❌ Error de registro: ${e.mensaje}');
      }
    }
  }

  // 2️⃣ Obtener perfil
  Future<void> _obtenerPerfil() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) {
      _addLog('❌ No hay usuario autenticado');
      return;
    }
    final usuario = await _usuarioService.obtener(uid);
    if (usuario == null) {
      _addLog('⚠️ No se encontró el perfil en Firestore');
    } else {
      _addLog('✅ Perfil obtenido: nombre=${usuario.nombre}, universidad=${usuario.universidad}, carrera=${usuario.carrera}, ciclo=${usuario.ciclo}, habilidades=${usuario.habilidades}, intereses=${usuario.intereses}');
    }
  }

  // 3️⃣ Actualizar perfil y volver a leer
  Future<void> _actualizarPerfil() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) {
      _addLog('❌ No hay usuario autenticado');
      return;
    }
    // Obtener el usuario actual
    final actual = await _usuarioService.obtener(uid);
    if (actual == null) {
      _addLog('⚠️ No se encontró perfil para actualizar');
      return;
    }
    // Crear nuevo objeto con los cambios solicitados
    final actualizado = actual.copyWith(
      universidad: 'UNSA',
      carrera: 'Ingeniería de Sistemas',
      ciclo: 5,
      habilidades: ['Flutter', 'Diseño'],
    );
    await _usuarioService.actualizar(actualizado);
    _addLog('✅ Perfil actualizado');
    // Leer de nuevo
    final relectura = await _usuarioService.obtener(uid);
    if (relectura != null) {
      _addLog('🔄 Perfil después de actualizar: universidad=${relectura.universidad}, carrera=${relectura.carrera}, ciclo=${relectura.ciclo}, habilidades=${relectura.habilidades}');
    }
  }

  // 4️⃣ Intentar registrar de nuevo el mismo correo
  Future<void> _registrarDuplicado() async {
    const correo = 'prueba@sumate.pe';
    const password = '123456';
    const nombre = 'Prueba';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('⚠️ Registro inesperado, el usuario ya existía pero se creó de nuevo');
    } on AuthError catch (e) {
      _addLog('✅ Error esperado al registrar duplicado: ${e.mensaje}');
    }
  }

  // 5️⃣ Cerrar sesión
  Future<void> _cerrarSesion() async {
    await _authService.cerrarSesion();
    _addLog('✅ Sesión cerrada');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Súmate: Demo Auth y Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _registrarOLogin, child: const Text('1️⃣ Registrar / Login')),
                ElevatedButton(onPressed: _obtenerPerfil, child: const Text('2️⃣ Obtener Perfil')),
                ElevatedButton(onPressed: _actualizarPerfil, child: const Text('3️⃣ Actualizar Perfil')),
                ElevatedButton(onPressed: _registrarDuplicado, child: const Text('4️⃣ Intentar Registro Duplicado')),
                ElevatedButton(onPressed: _cerrarSesion, child: const Text('5️⃣ Cerrar Sesión')),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Log:'),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log.join('\n')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}