// Puerta de enlace de autenticación (AuthGate) de Súmate.
// Escucha reactivamente los cambios de sesión de Firebase Auth.
// Si no hay sesión: muestra PantallaLogin.
// Si hay sesión confirmada: construye AppShell.
// Mientras espera la primera emisión del stream: muestra carga sobre fondo crema.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/servicios.dart';
import '../core/theme/app_colors.dart';
import '../features/auth/pantallas/pantalla_login.dart';
import 'app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Servicios.auth.cambiosSesion,
      builder: (context, snapshot) {
        // Mientras espera la confirmación del estado de sesión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.fondo,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.textoPrincipal,
              ),
            ),
          );
        }

        final user = snapshot.data;

        // Si no hay sesión activa, muestra login
        if (user == null) {
          return const PantallaLogin();
        }

        // Si hay sesión confirmada, muestra el AppShell principal
        return const AppShell();
      },
    );
  }
}
