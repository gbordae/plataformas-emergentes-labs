import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // Necesario antes de usar plugins (Firebase) en main().
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con la configuración generada por flutterfire.
  // DefaultFirebaseOptions.currentPlatform elige solo web o android.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PruebaConexionApp());
}

/// App temporal: solo comprueba que Firebase responde.
class PruebaConexionApp extends StatelessWidget {
  const PruebaConexionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PruebaConexionPantalla(),
    );
  }
}

class PruebaConexionPantalla extends StatefulWidget {
  const PruebaConexionPantalla({super.key});

  @override
  State<PruebaConexionPantalla> createState() => _PruebaConexionPantallaState();
}

class _PruebaConexionPantallaState extends State<PruebaConexionPantalla> {
  final List<String> _log = [];

  void _agregar(String texto) => setState(() => _log.add(texto));

  Future<void> _probar() async {
    setState(() => _log.clear());

    // 1) Firebase inicializado: debe mostrar el id del proyecto.
    _agregar('Firebase OK, proyecto: ${Firebase.app().options.projectId}');

    // 2) Auth: crea una sesión anónima temporal NO; solo comprobamos
    //    que el servicio responde (sin usuario aún es normal).
    final usuario = FirebaseAuth.instance.currentUser;
    _agregar('Auth OK, usuario actual: ${usuario?.uid ?? "ninguno (normal)"}');

    // 3) Firestore: intenta leer. En modo producción sin reglas,
    //    "permission-denied" también significa que HAY conexión.
    try {
      await FirebaseFirestore.instance.collection('eventos').limit(1).get();
      _agregar('Firestore OK: lectura permitida');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _agregar('Firestore OK: conectado (permission-denied es esperado '
            'hasta escribir las reglas)');
      } else {
        _agregar('Firestore ERROR: ${e.code} - ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Súmate: prueba de conexión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton(
              onPressed: _probar,
              child: const Text('Probar conexión'),
            ),
            const SizedBox(height: 16),
            for (final linea in _log) Text(linea),
          ],
        ),
      ),
    );
  }
}