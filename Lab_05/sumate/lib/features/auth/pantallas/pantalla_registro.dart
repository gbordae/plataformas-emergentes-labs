// Pantalla de registro de nuevos usuarios en Súmate (RF01).
// Crea la cuenta en Firebase Auth y su documento inicial en Firestore.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/wordmark_sumate.dart';
import '../servicios/auth_service.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _ocultarPassword = true;
  bool _ocultarConfirmar = true;
  bool _cargando = false;
  String? _mensajeError;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  // Registra al usuario y regresa a la raíz
  Future<void> _crearCuenta() async {
    setState(() => _mensajeError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await Servicios.auth.registrar(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );
      // Al registrar exitosamente, volver a la raíz.
      // AuthGate detectará la nueva sesión y mostrará AppShell directamente.
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on AuthError catch (e) {
      if (mounted) {
        setState(() => _mensajeError = e.mensaje);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _mensajeError = 'No se pudo crear la cuenta. Intenta de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      // SafeArea evita que el formulario quede bajo la barra de estado o de gestos.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ContenidoCentrado(
              anchoMaximo: 480,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera con Wordmark
                      const Center(child: WordmarkSumate(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu cuenta institucional o personal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo: Nombre completo
                      TextFormField(
                        controller: _nombreController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          hintText: 'Ej. Camila Quispe Mamani',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textoSecundario),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa tu nombre completo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Correo electrónico
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'tucorreo@universidad.edu.pe',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textoSecundario),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!valor.contains('@')) {
                            return 'Ingresa un correo válido con @';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _ocultarPassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textoSecundario),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textoSecundario,
                            ),
                            onPressed: () {
                              setState(() => _ocultarPassword = !_ocultarPassword);
                            },
                          ),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (valor.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Confirmar contraseña
                      TextFormField(
                        controller: _confirmarPasswordController,
                        obscureText: _ocultarConfirmar,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _crearCuenta(),
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textoSecundario),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultarConfirmar
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textoSecundario,
                            ),
                            onPressed: () {
                              setState(() => _ocultarConfirmar = !_ocultarConfirmar);
                            },
                          ),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (valor != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),

                      // Mensaje de error visible
                      if (_mensajeError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mensajeError!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botón crear cuenta
                      FilledButton(
                        onPressed: _cargando ? null : _crearCuenta,
                        child: _cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.textoPrincipal,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('Crear cuenta'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Enlace de regreso al login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Inicia sesión',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textoPrincipal,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
