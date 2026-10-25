// Pantalla para publicar un evento nuevo con su primera edición (RF03, RF04).
// Formulario centrado con scroll, validación de convocatorias y manejo de errores.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/enums.dart';
import '../../../core/errores.dart';
import '../../../core/formato.dart';
import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../modelos/convocatoria.dart';
import '../modelos/edicion.dart';
import '../modelos/evento.dart';

class PantallaPublicarEvento extends StatefulWidget {
  const PantallaPublicarEvento({super.key});

  @override
  State<PantallaPublicarEvento> createState() => _PantallaPublicarEventoState();
}

class _PantallaPublicarEventoState extends State<PantallaPublicarEvento> {
  final _formKey = GlobalKey<FormState>();

  // Controladores sección Evento
  final _nombreEventoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _entidadController = TextEditingController();
  TipoEvento _tipoEvento = TipoEvento.hackathon;

  // Controladores sección Primera Edición
  final _nombreEdicionController = TextEditingController();
  final _lugarController = TextEditingController();
  final _otraUniversidadController = TextEditingController();
  Modalidad _modalidad = Modalidad.presencial;
  String _universidadOpcion = ''; // '' = Independiente / abierto a todas

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Convocatorias
  bool _buscaVoluntarios = true;
  bool _recibeAsistentes = true;

  final _cuposVoluntariosController = TextEditingController(text: '10');
  final _enlaceVoluntariosController = TextEditingController();
  final _beneficiosVoluntariosController = TextEditingController();
  DateTime? _fechaLimiteVoluntarios;

  final _cuposAsistentesController = TextEditingController(text: '50');
  final _enlaceAsistentesController = TextEditingController();
  DateTime? _fechaLimiteAsistentes;

  bool _guardando = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _sugerirUniversidadPerfil();
  }

  @override
  void dispose() {
    _nombreEventoController.dispose();
    _descripcionController.dispose();
    _entidadController.dispose();
    _nombreEdicionController.dispose();
    _lugarController.dispose();
    _otraUniversidadController.dispose();
    _cuposVoluntariosController.dispose();
    _enlaceVoluntariosController.dispose();
    _beneficiosVoluntariosController.dispose();
    _cuposAsistentesController.dispose();
    _enlaceAsistentesController.dispose();
    super.dispose();
  }

  /// Carga la universidad del perfil del usuario para sugerirla como entidad sin bloquear.
  Future<void> _sugerirUniversidadPerfil() async {
    try {
      final uid = Servicios.auth.usuarioActual?.uid;
      if (uid == null || uid.isEmpty) return;

      final usuario = await Servicios.usuario.obtener(uid);
      if (usuario != null && mounted) {
        if (_entidadController.text.trim().isEmpty && usuario.universidad.isNotEmpty) {
          setState(() {
            _entidadController.text = usuario.universidad;
          });
        }
      }
    } catch (_) {
      // Si falla la sugerencia o no hay conexión de Auth no bloquea al usuario
    }
  }

  /// Auto-sugiere el nombre de la edición al escribir el nombre del evento si está vacío.
  void _onNombreEventoCambiado(String valor) {
    final anio = DateTime.now().year;
    if (_nombreEdicionController.text.trim().isEmpty ||
        _nombreEdicionController.text.endsWith('$anio')) {
      if (valor.trim().isNotEmpty) {
        _nombreEdicionController.text = '${valor.trim()} $anio';
      }
    }
  }

  /// Selector combinado de fecha y hora.
  Future<DateTime?> _seleccionarFechaHora(
    BuildContext context, {
    required DateTime? valorActual,
    DateTime? fechaMinima,
  }) async {
    final ahora = DateTime.now();
    final fechaBase = valorActual ?? fechaMinima ?? ahora;

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaBase,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 5),
      helpText: 'Selecciona la fecha',
      confirmText: 'Continuar',
      cancelText: 'Cancelar',
    );

    if (fecha == null || !context.mounted) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaBase),
      helpText: 'Selecciona la hora',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );

    if (hora == null) return null;

    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  /// Valida y publica el evento con su primera edición en Firestore.
  Future<void> _publicar() async {
    setState(() => _errorMensaje = null);

    // Validación de formulario base
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar al menos una convocatoria activa
    if (!_buscaVoluntarios && !_recibeAsistentes) {
      setState(() {
        _errorMensaje = 'Debes activar al menos una convocatoria (voluntarios o asistentes).';
      });
      return;
    }

    // Validar fechas de la edición
    if (_fechaInicio == null) {
      setState(() => _errorMensaje = 'Selecciona la fecha y hora de inicio de la edición.');
      return;
    }
    if (_fechaFin == null) {
      setState(() => _errorMensaje = 'Selecciona la fecha y hora de fin de la edición.');
      return;
    }
    if (!_fechaFin!.isAfter(_fechaInicio!)) {
      setState(() => _errorMensaje = 'La fecha de fin debe ser posterior a la de inicio.');
      return;
    }

    final uid = Servicios.auth.usuarioActual?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() => _errorMensaje = 'No se encontró la sesión del usuario.');
      return;
    }

    setState(() => _guardando = true);

    try {
      // 1. Construir modelo de Evento padre
      final evento = Evento(
        id: '',
        nombre: _nombreEventoController.text.trim(),
        tipo: _tipoEvento,
        descripcion: _descripcionController.text.trim(),
        entidad: _entidadController.text.trim(),
        administradores: [uid],
      );

      // 2. Construir Convocatoria para Voluntarios
      final convVoluntarios = _buscaVoluntarios
          ? Convocatoria(
              abierta: true,
              cupos: int.parse(_cuposVoluntariosController.text.trim()),
              ocupados: 0,
              beneficios: _beneficiosVoluntariosController.text.trim().isEmpty
                  ? null
                  : _beneficiosVoluntariosController.text.trim(),
              fechaLimite: _fechaLimiteVoluntarios,
              enlaceExterno: _enlaceVoluntariosController.text.trim().isEmpty
                  ? null
                  : _enlaceVoluntariosController.text.trim(),
            )
          : const Convocatoria.cerrada();

      // 3. Construir Convocatoria para Asistentes
      final convAsistentes = _recibeAsistentes
          ? Convocatoria(
              abierta: true,
              cupos: int.parse(_cuposAsistentesController.text.trim()),
              ocupados: 0,
              fechaLimite: _fechaLimiteAsistentes,
              enlaceExterno: _enlaceAsistentesController.text.trim().isEmpty
                  ? null
                  : _enlaceAsistentesController.text.trim(),
            )
          : const Convocatoria.cerrada();

      // Universidad sede
      final universidadFinal = _universidadOpcion == 'Otra'
          ? _otraUniversidadController.text.trim()
          : _universidadOpcion;

      // 4. Construir modelo de Edición
      final edicion = Edicion(
        id: '',
        eventoId: '',
        eventoNombre: evento.nombre,
        tipo: evento.tipo,
        nombre: _nombreEdicionController.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        lugar: _lugarController.text.trim(),
        modalidad: _modalidad,
        universidad: universidadFinal,
        estado: EstadoEdicion.abierta,
        organizadores: [uid],
        voluntarios: convVoluntarios,
        asistentes: convAsistentes,
      );

      // 5. Llamada atómica al backend
      await Servicios.edicion.crearEventoConPrimeraEdicion(
        evento: evento,
        edicion: edicion,
        uid: uid,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ErrorNegocio catch (e) {
      if (mounted) {
        setState(() => _errorMensaje = e.mensaje);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        if (e.code == 'permission-denied' || e.toString().contains('permission-denied')) {
          setState(() => _errorMensaje = 'No tienes permiso para esta acción.');
        } else {
          setState(() => _errorMensaje = 'Ocurrió un error. Intenta de nuevo.');
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('permission-denied')) {
          setState(() => _errorMensaje = 'No tienes permiso para esta acción.');
        } else {
          setState(() => _errorMensaje = 'Ocurrió un error. Intenta de nuevo.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: Text(
          'Publicar evento',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
        backgroundColor: AppColors.superficie,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textoPrincipal),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.borde),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ContenidoCentrado(
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
                  // ── SECCIÓN 1: EVENTO ────────────────────────────────────
                  _buildTituloSeccion(
                    numero: '1',
                    titulo: 'Datos generales del evento',
                  ),
                  const SizedBox(height: 16),

                  // Nombre del evento
                  TextFormField(
                    controller: _nombreEventoController,
                    onChanged: _onNombreEventoCambiado,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del evento *',
                      hintText: 'Ej. HackSan, Ciclo de Ponencias...',
                      prefixIcon: Icon(Icons.event_outlined, color: AppColors.textoSecundario),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el nombre del evento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tipo de evento
                  DropdownButtonFormField<TipoEvento>(
                    isExpanded: true,
                    initialValue: _tipoEvento,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evento *',
                      prefixIcon: Icon(Icons.category_outlined, color: AppColors.textoSecundario),
                    ),
                    items: TipoEvento.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.etiqueta),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _tipoEvento = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del evento *',
                      hintText: '¿De qué trata la iniciativa o qué impacto busca?',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa una descripción del evento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Entidad organizadora
                  TextFormField(
                    controller: _entidadController,
                    decoration: const InputDecoration(
                      labelText: 'Entidad organizadora *',
                      hintText: 'Ej. Club de Sistemas · UNSA',
                      prefixIcon: Icon(Icons.corporate_fare_outlined, color: AppColors.textoSecundario),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa la entidad u organización responsable';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── SECCIÓN 2: PRIMERA EDICIÓN ───────────────────────────
                  _buildTituloSeccion(
                    numero: '2',
                    titulo: 'Primera edición',
                  ),
                  const SizedBox(height: 16),

                  // Nombre de la edición
                  TextFormField(
                    controller: _nombreEdicionController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la edición *',
                      hintText: 'Ej. HackSan 2026',
                      prefixIcon: Icon(Icons.bookmark_border_rounded, color: AppColors.textoSecundario),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el nombre de la edición';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fechas de inicio y fin
                  Row(
                    children: [
                      // Fecha y hora inicio
                      Expanded(
                        child: _SelectorFecha(
                          label: 'Inicio *',
                          fecha: _fechaInicio,
                          onTap: () async {
                            final f = await _seleccionarFechaHora(
                              context,
                              valorActual: _fechaInicio,
                            );
                            if (f != null) {
                              setState(() {
                                _fechaInicio = f;
                                if (_fechaFin == null || !_fechaFin!.isAfter(f)) {
                                  _fechaFin = f.add(const Duration(hours: 4));
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Fecha y hora fin
                      Expanded(
                        child: _SelectorFecha(
                          label: 'Fin *',
                          fecha: _fechaFin,
                          onTap: () async {
                            final f = await _seleccionarFechaHora(
                              context,
                              valorActual: _fechaFin,
                              fechaMinima: _fechaInicio,
                            );
                            if (f != null) {
                              setState(() => _fechaFin = f);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lugar
                  TextFormField(
                    controller: _lugarController,
                    decoration: const InputDecoration(
                      labelText: 'Lugar físico o enlace *',
                      hintText: 'Ej. Auditorio de Ingeniería, Pabellón de Sistemas...',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textoSecundario),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa el lugar o sede de la edición';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Modalidad
                  DropdownButtonFormField<Modalidad>(
                    isExpanded: true,
                    initialValue: _modalidad,
                    decoration: const InputDecoration(
                      labelText: 'Modalidad *',
                      prefixIcon: Icon(Icons.devices_outlined, color: AppColors.textoSecundario),
                    ),
                    items: Modalidad.values.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m.etiqueta),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _modalidad = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Universidad sede
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _universidadOpcion,
                    decoration: const InputDecoration(
                      labelText: 'Universidad sede',
                      prefixIcon: Icon(Icons.school_outlined, color: AppColors.textoSecundario),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '',
                        child: Text('Independiente / Abierto a todas'),
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
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _universidadOpcion = val);
                      }
                    },
                  ),
                  if (_universidadOpcion == 'Otra') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _otraUniversidadController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la institución *',
                        hintText: 'Ej. Tecsup, UTP, La Salle...',
                        prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.textoSecundario),
                      ),
                      validator: (v) {
                        if (_universidadOpcion == 'Otra' && (v == null || v.trim().isEmpty)) {
                          return 'Ingresa el nombre de la institución';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  // ── CONVOCATORIAS ────────────────────────────────────────
                  _buildTituloSeccion(
                    numero: '3',
                    titulo: 'Convocatorias de participación',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activa al menos una opción para recibir postulantes.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Convocatoria: Voluntarios ───────────────────────────
                  Material(
                    color: _buscaVoluntarios
                        ? AppColors.primaryContainer.withValues(alpha: 0.35)
                        : AppColors.fondo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _buscaVoluntarios ? AppColors.primary : AppColors.borde,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          title: Text(
                            'Buscar voluntarios',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                          subtitle: Text(
                            'Apoyo en logística, acreditación, staff y organización',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          value: _buscaVoluntarios,
                          activeThumbColor: AppColors.textoPrincipal,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _buscaVoluntarios = val),
                        ),
                        if (_buscaVoluntarios) ...[
                          const Divider(height: 1, thickness: 1, color: AppColors.borde),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Cupos de voluntarios
                                TextFormField(
                                  controller: _cuposVoluntariosController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    labelText: 'Cupos para voluntarios *',
                                    hintText: 'Ej. 10',
                                    prefixIcon: Icon(Icons.people_alt_outlined, color: AppColors.textoSecundario),
                                  ),
                                  validator: (v) {
                                    if (!_buscaVoluntarios) return null;
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) {
                                      return 'Los cupos deben ser un número mayor a 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Fecha límite voluntarios
                                _SelectorFechaConLimpiar(
                                  label: 'Fecha límite de postulación (opcional)',
                                  fecha: _fechaLimiteVoluntarios,
                                  onSeleccionar: () async {
                                    final f = await _seleccionarFechaHora(
                                      context,
                                      valorActual: _fechaLimiteVoluntarios,
                                    );
                                    if (f != null) {
                                      setState(() => _fechaLimiteVoluntarios = f);
                                    }
                                  },
                                  onLimpiar: () {
                                    setState(() => _fechaLimiteVoluntarios = null);
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Beneficios
                                TextFormField(
                                  controller: _beneficiosVoluntariosController,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Beneficios e incentivos (opcional)',
                                    hintText: 'Ej. Certificación, refrigerio, networking...',
                                    alignLabelWithHint: true,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Enlace externo voluntarios
                                TextFormField(
                                  controller: _enlaceVoluntariosController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enlace externo opcional (Google Form, etc.)',
                                    hintText: 'https://forms.gle/...',
                                    prefixIcon: Icon(Icons.link_rounded, color: AppColors.textoSecundario),
                                  ),
                                  validator: (v) {
                                    if (!_buscaVoluntarios || v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    final link = v.trim();
                                    if (!link.startsWith('http://') && !link.startsWith('https://')) {
                                      return 'El enlace debe comenzar con http:// o https://';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Convocatoria: Asistentes ────────────────────────────
                  Material(
                    color: _recibeAsistentes
                        ? AppColors.primaryContainer.withValues(alpha: 0.35)
                        : AppColors.fondo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _recibeAsistentes ? AppColors.primary : AppColors.borde,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          title: Text(
                            'Recibir asistentes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                          subtitle: Text(
                            'Participantes del público general o estudiantes inscritos',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          value: _recibeAsistentes,
                          activeThumbColor: AppColors.textoPrincipal,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _recibeAsistentes = val),
                        ),
                        if (_recibeAsistentes) ...[
                          const Divider(height: 1, thickness: 1, color: AppColors.borde),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Cupos de asistentes
                                TextFormField(
                                  controller: _cuposAsistentesController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    labelText: 'Cupos para asistentes *',
                                    hintText: 'Ej. 50',
                                    prefixIcon: Icon(Icons.group_outlined, color: AppColors.textoSecundario),
                                  ),
                                  validator: (v) {
                                    if (!_recibeAsistentes) return null;
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) {
                                      return 'Los cupos deben ser un número mayor a 0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Fecha límite asistentes
                                _SelectorFechaConLimpiar(
                                  label: 'Fecha límite de inscripción (opcional)',
                                  fecha: _fechaLimiteAsistentes,
                                  onSeleccionar: () async {
                                    final f = await _seleccionarFechaHora(
                                      context,
                                      valorActual: _fechaLimiteAsistentes,
                                    );
                                    if (f != null) {
                                      setState(() => _fechaLimiteAsistentes = f);
                                    }
                                  },
                                  onLimpiar: () {
                                    setState(() => _fechaLimiteAsistentes = null);
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Enlace externo asistentes
                                TextFormField(
                                  controller: _enlaceAsistentesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enlace externo opcional (Google Form, etc.)',
                                    hintText: 'https://forms.gle/...',
                                    prefixIcon: Icon(Icons.link_rounded, color: AppColors.textoSecundario),
                                  ),
                                  validator: (v) {
                                    if (!_recibeAsistentes || v == null || v.trim().isEmpty) {
                                      return null;
                                    }
                                    final link = v.trim();
                                    if (!link.startsWith('http://') && !link.startsWith('https://')) {
                                      return 'El enlace debe comenzar con http:// o https://';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mensaje de error general si ocurre
                  if (_errorMensaje != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.estadoRechazadaFondo,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMensaje!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botón primario Publicar
                  ElevatedButton(
                    onPressed: _guardando ? null : _publicar,
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.textoPrincipal,
                            ),
                          )
                        : const Text('Publicar evento'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye un encabezado de sección numerado y estilizado.
  Widget _buildTituloSeccion({required String numero, required String titulo}) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            numero,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titulo,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Selector de fecha con apariencia de campo de texto del sistema de diseño.
class _SelectorFecha extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final VoidCallback onTap;

  const _SelectorFecha({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textoSecundario),
        ),
        child: Text(
          fecha != null ? fechaCorta(fecha!) : 'Seleccionar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: fecha != null ? FontWeight.w600 : FontWeight.w400,
            color: fecha != null ? AppColors.textoPrincipal : AppColors.placeholder,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Selector de fecha con botón de limpiar para campos opcionales.
class _SelectorFechaConLimpiar extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final VoidCallback onSeleccionar;
  final VoidCallback onLimpiar;

  const _SelectorFechaConLimpiar({
    required this.label,
    required this.fecha,
    required this.onSeleccionar,
    required this.onLimpiar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onSeleccionar,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.event_available_outlined, size: 18, color: AppColors.textoSecundario),
              ),
              child: Text(
                fecha != null ? fechaCorta(fecha!) : 'Sin fecha límite',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: fecha != null ? FontWeight.w600 : FontWeight.w400,
                  color: fecha != null ? AppColors.textoPrincipal : AppColors.placeholder,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (fecha != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Limpiar fecha',
            icon: const Icon(Icons.clear_rounded, color: AppColors.textoSecundario),
            onPressed: onLimpiar,
          ),
        ],
      ],
    );
  }
}
