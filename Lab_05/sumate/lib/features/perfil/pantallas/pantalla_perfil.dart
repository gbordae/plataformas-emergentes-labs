// Pantalla de Perfil de usuario en Súmate (RF02).
// Permite visualizar y editar la información académica, habilidades e intereses,
// así como cerrar la sesión activa.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cabecera_pantalla.dart';
import '../modelos/usuario.dart';

class PantallaPerfil extends StatelessWidget {
  const PantallaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Servicios.auth.usuarioActual?.uid;

    // Si por algún motivo no hay sesión, se muestra el estado vacío
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.fondo,
        body: Center(
          child: Text(
            'No se encontró tu perfil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
      );
    }

    // Escucha en tiempo real el documento del usuario en Firestore
    return StreamBuilder<Usuario?>(
      stream: Servicios.usuarios.escuchar(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.fondo,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.textoPrincipal),
            ),
          );
        }

        final usuario = snapshot.data;
        if (usuario == null) {
          return Scaffold(
            backgroundColor: AppColors.fondo,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No se encontró tu perfil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async => await Servicios.auth.cerrarSesion(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }

        return _FormularioPerfil(usuario: usuario);
      },
    );
  }
}

/// Formulario interactivo para editar los campos del perfil.
class _FormularioPerfil extends StatefulWidget {
  final Usuario usuario;

  const _FormularioPerfil({required this.usuario});

  @override
  State<_FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<_FormularioPerfil> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _carreraController;
  late TextEditingController _cicloController;
  late TextEditingController _otraUniversidadController;

  final TextEditingController _nuevaHabilidadController = TextEditingController();
  final TextEditingController _nuevoInteresController = TextEditingController();

  late String _universidadOpcion;
  late List<String> _habilidades;
  late List<String> _intereses;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _inicializarCampos();
  }

  void _inicializarCampos() {
    _nombreController = TextEditingController(text: widget.usuario.nombre);
    _carreraController = TextEditingController(text: widget.usuario.carrera);
    _cicloController = TextEditingController(
      text: widget.usuario.ciclo?.toString() ?? '',
    );

    // Determinar la opción de universidad a seleccionar
    final u = widget.usuario.universidad.trim();
    if (u.isEmpty) {
      _universidadOpcion = 'Independiente';
      _otraUniversidadController = TextEditingController();
    } else if (['UNSA', 'UCSM', 'UCSP'].contains(u)) {
      _universidadOpcion = u;
      _otraUniversidadController = TextEditingController();
    } else {
      _universidadOpcion = 'Otra';
      _otraUniversidadController = TextEditingController(text: u);
    }

    _habilidades = List<String>.from(widget.usuario.habilidades);
    _intereses = List<String>.from(widget.usuario.intereses);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _carreraController.dispose();
    _cicloController.dispose();
    _otraUniversidadController.dispose();
    _nuevaHabilidadController.dispose();
    _nuevoInteresController.dispose();
    super.dispose();
  }

  // Extrae 1 o 2 letras para las iniciales del avatar
  String _obtenerIniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'U';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  // Agrega una nueva habilidad a la lista
  void _agregarHabilidad() {
    final texto = _nuevaHabilidadController.text.trim();
    if (texto.isNotEmpty && !_habilidades.contains(texto)) {
      setState(() {
        _habilidades.add(texto);
        _nuevaHabilidadController.clear();
      });
    }
  }

  // Agrega un nuevo interés a la lista
  void _agregarInteres() {
    final texto = _nuevoInteresController.text.trim();
    if (texto.isNotEmpty && !_intereses.contains(texto)) {
      setState(() {
        _intereses.add(texto);
        _nuevoInteresController.clear();
      });
    }
  }

  // Guarda los cambios actualizando el documento en Firestore
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    // Calcular la universidad a guardar
    String univFinal;
    if (_universidadOpcion == 'Independiente') {
      univFinal = '';
    } else if (_universidadOpcion == 'Otra') {
      univFinal = _otraUniversidadController.text.trim();
    } else {
      univFinal = _universidadOpcion;
    }

    // Calcular ciclo opcional
    int? cicloNum;
    final cicloTexto = _cicloController.text.trim();
    if (cicloTexto.isNotEmpty) {
      cicloNum = int.tryParse(cicloTexto);
    }

    final actualizado = widget.usuario.copyWith(
      nombre: _nombreController.text.trim(),
      universidad: univFinal,
      carrera: _carreraController.text.trim(),
      ciclo: cicloNum,
      habilidades: _habilidades,
      intereses: _intereses,
    );

    try {
      await Servicios.usuarios.actualizar(actualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado con éxito'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cambios: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carreraVacia = _carreraController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CabeceraPantalla(
              titulo: 'Perfil',
              subtitulo: 'Gestiona tu información académica y habilidades',
            ),
            const SizedBox(height: 24),
            ContenidoCentrado(
              anchoMaximo: 560,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar circular con iniciales (#FDA769 y #473C33)
                      Center(
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.tertiary,
                          child: Text(
                            _obtenerIniciales(_nombreController.text),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nombre destacado y correo de solo lectura
                      Center(
                        child: Text(
                          _nombreController.text.isNotEmpty
                              ? _nombreController.text
                              : widget.usuario.nombre,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textoPrincipal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          widget.usuario.correo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tarjeta de aviso suave si la carrera está vacía (no bloqueante)
                      if (carreraVacia) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.textoPrincipal,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Completa tu carrera y habilidades para que los organizadores te conozcan mejor.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textoPrincipal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Campo: Nombre completo
                      TextFormField(
                        controller: _nombreController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textoSecundario),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo: Universidad (Selector con opciones UNSA, UCSM, UCSP, Otra o Independiente)
                      DropdownButtonFormField<String>(
                        initialValue: _universidadOpcion,
                        decoration: const InputDecoration(
                          labelText: 'Universidad / Institución',
                          prefixIcon: Icon(Icons.school_outlined, color: AppColors.textoSecundario),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Independiente',
                            child: Text('Independiente (sin universidad)'),
                          ),
                          DropdownMenuItem(
                            value: 'UNSA',
                            child: Text('UNSA (San Agustín)'),
                          ),
                          DropdownMenuItem(
                            value: 'UCSM',
                            child: Text('UCSM (Santa María)'),
                          ),
                          DropdownMenuItem(
                            value: 'UCSP',
                            child: Text('UCSP (San Pablo)'),
                          ),
                          DropdownMenuItem(
                            value: 'Otra',
                            child: Text('Otra institución...'),
                          ),
                        ],
                        onChanged: (nuevaOpcion) {
                          if (nuevaOpcion != null) {
                            setState(() => _universidadOpcion = nuevaOpcion);
                          }
                        },
                      ),

                      // Campo de texto libre si seleccionó "Otra"
                      if (_universidadOpcion == 'Otra') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _otraUniversidadController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la institución',
                            hintText: 'Ej. Tecsup, UTP, La Salle...',
                            prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.textoSecundario),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Campo: Carrera
                      TextFormField(
                        controller: _carreraController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Carrera o especialidad',
                          hintText: 'Ej. Ingeniería de Sistemas',
                          prefixIcon: Icon(Icons.menu_book_outlined, color: AppColors.textoSecundario),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo: Ciclo (numérico, opcional)
                      TextFormField(
                        controller: _cicloController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ciclo actual (opcional)',
                          hintText: 'Ej. 5',
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textoSecundario),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final n = int.tryParse(val.trim());
                            if (n == null || n < 1 || n > 14) {
                              return 'Ingresa un ciclo válido (número)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Sección Habilidades ─────────────────────────────────────
                      Text(
                        'Habilidades',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agrega habilidades técnicas o blandas para tus postulaciones.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chips de habilidades existentes
                      if (_habilidades.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _habilidades.map((hab) {
                            return Chip(
                              label: Text(hab),
                              deleteIcon: const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () {
                                setState(() => _habilidades.remove(hab));
                              },
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No has agregado habilidades todavía.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textoSecundario,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Fila para ingresar una nueva habilidad
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nuevaHabilidadController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _agregarHabilidad(),
                              decoration: const InputDecoration(
                                hintText: 'Ej. Flutter, Liderazgo, Diseño...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _agregarHabilidad,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Sección Intereses ───────────────────────────────────────
                      Text(
                        'Intereses',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Temas de eventos o convocatorias en los que deseas participar.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chips de intereses existentes (con acento en contenedor coral)
                      if (_intereses.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _intereses.map((interes) {
                            return Chip(
                              backgroundColor: AppColors.tertiaryContainer,
                              label: Text(interes),
                              deleteIcon: const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () {
                                setState(() => _intereses.remove(interes));
                              },
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No has agregado intereses todavía.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textoSecundario,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Fila para ingresar un nuevo interés
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nuevoInteresController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _agregarInteres(),
                              decoration: const InputDecoration(
                                hintText: 'Ej. Hackathons, Robótica, IA...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _agregarInteres,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Botón primario: Guardar cambios
                      FilledButton(
                        onPressed: _guardando ? null : _guardarCambios,
                        child: _guardando
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
                                  Icon(Icons.check_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Guardar cambios'),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Botón secundario/contorno: Cerrar sesión
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Servicios.auth.cerrarSesion();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Margen inferior para no tapar "Cerrar sesión" con la barra de navegación.
            SizedBox(height: 36 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
