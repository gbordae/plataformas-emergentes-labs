// Punto de entrada de Súmate. Inicializa Firebase y monta AuthGate.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

// false = proyecto Firebase real (seed de demo ya desplegado).
// true = emuladores locales (Auth 9099, Firestore 8080). El host 10.0.2.2
// solo aplica en Android cuando esta bandera está en true.
const bool usarEmulador = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (usarEmulador) {
    final host = kIsWeb
        ? 'localhost'
        : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }

  runApp(MaterialApp(
    title: 'Súmate',
    theme: AppTheme.tema,
    debugShowCheckedModeBanner: false,
    home: const AuthGate(),
  ));
}
