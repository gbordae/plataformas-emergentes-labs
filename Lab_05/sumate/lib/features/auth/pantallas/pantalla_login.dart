// Pantalla de inicio de sesión de Súmate (RF01).
// Permite ingresar con correo y contraseña, recuperar contraseña o ir al registro.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/wordmark_sumate.dart';
import '../servicios/auth_service.dart';
import 'pantalla_registro.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _ocultarPassword = true;
  bool _cargando = false;
  String? _mensajeError;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Ejecuta el inicio de sesión contra Firebase Auth
  Future<void> _iniciarSesion() async {
    // Limpiar errores previos
    setState(() => _mensajeError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await Servicios.auth.iniciarSesion(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
      );
      // Al ser exitoso, AuthGate detectará el cambio de sesión automáticamente
    } on AuthError catch (e) {
      if (mounted) {
        setState(() => _mensajeError = e.mensaje);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _mensajeError = 'No se pudo iniciar sesión. Intenta de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // Muestra el diálogo modal para solicitar restablecimiento de contraseña
  void _mostrarDialogoRecuperacion() {
    final recuperacionController = TextEditingController(text: _correoController.text.trim());
    String? errorDialogo;
    String? exitoDialogo;
    bool enviando = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.superficie,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borde),
              ),
              title: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresa tu correo institucional o personal para enviarte un enlace de recuperación.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: recuperacionController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'ejemplo@universidad.edu.pe',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textoSecundario),
                    ),
                  ),
                  if (errorDialogo != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorDialogo!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (exitoDialogo != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      exitoDialogo!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.estadoAceptadaTexto,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    exitoDialogo != null ? 'Cerrar' : 'Cancelar',
                    style: const TextStyle(color: AppColors.textoSecundario),
                  ),
                ),
                if (exitoDialogo == null)
                  FilledButton(
                    onPressed: enviando
                        ? null
                        : () async {
                            final correo = recuperacionController.text.trim();
                            if (correo.isEmpty || !correo.contains('@')) {
                              setDialogState(() {
                                errorDialogo = 'Ingresa un correo electrónico válido.';
                              });
                              return;
                            }

                            setDialogState(() {
                              enviando = true;
                              errorDialogo = null;
                            });

                            try {
                              await Servicios.auth.enviarRecuperacionContrasena(correo);
                              setDialogState(() {
                                enviando = false;
                                exitoDialogo = 'Se envió un enlace a tu correo. Revisa tu bandeja.';
                              });
                            } on AuthError catch (e) {
                              setDialogState(() {
                                enviando = false;
                                errorDialogo = e.mensaje;
                              });
                            } catch (_) {
                              setDialogState(() {
                                enviando = false;
                                errorDialogo = 'No se pudo enviar el correo. Intenta más tarde.';
                              });
                            }
                          },
                    child: enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textoPrincipal,
                            ),
                          )
                        : const Text('Enviar enlace'),
                  ),
              ],
            );
          },
        );
      },
    );
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
                        'Encuentra tu próxima oportunidad en Arequipa',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo de correo electrónico
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

                      // Campo de contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _ocultarPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _iniciarSesion(),
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
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Enlace para recuperar contraseña
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _mostrarDialogoRecuperacion,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textoPrincipal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      // Mensaje de error visible si falló la autenticación
                      if (_mensajeError != null) ...[
                        const SizedBox(height: 12),
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

                      const SizedBox(height: 20),

                      // Botón principal de inicio de sesión
                      FilledButton(
                        onPressed: _cargando ? null : _iniciarSesion,
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
                                  Text('Iniciar sesión'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Enlace hacia pantalla de registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Aún no tienes cuenta? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantallaRegistro(),
                                ),
                              );
                            },
                            child: Text(
                              'Crear cuenta',
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
