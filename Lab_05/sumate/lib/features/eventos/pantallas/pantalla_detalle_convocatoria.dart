// Pantalla de detalle de una convocatoria concreta (RF06, RF07).
// Permite postularse como voluntario y/o inscribirse como asistente.
// Detecta postulaciones previas, valida cupos y reglas en tiempo real,
// y se adapta responsivamente entre móvil (columna única) y desktop/tablet (8/12 + 4/12).

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
import '../../../core/widgets/estado_badge.dart';
import '../../perfil/modelos/usuario.dart';
import '../../postulaciones/modelos/postulacion.dart';
import '../modelos/convocatoria.dart';
import '../modelos/edicion.dart';
import '../modelos/evento.dart';

class PantallaDetalleConvocatoria extends StatefulWidget {
  final String edicionId;

  const PantallaDetalleConvocatoria({
    super.key,
    required this.edicionId,
  });

  @override
  State<PantallaDetalleConvocatoria> createState() =>
      _PantallaDetalleConvocatoriaState();
}

class _PantallaDetalleConvocatoriaState
    extends State<PantallaDetalleConvocatoria> {
  Edicion? _edicion;
  Evento? _evento;
  Postulacion? _postulacionVoluntario;
  Postulacion? _postulacionAsistente;
  Usuario? _usuario;

  bool _cargando = true;
  String? _error;
  bool _procesandoPostulacion = false;
  String? _cancelandoId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Carga paralela de edición, evento padre, postulaciones previas y perfil
  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final edicion = await Servicios.edicion.obtener(widget.edicionId);
      if (edicion == null) {
        if (mounted) {
          setState(() {
            _error = 'Convocatoria no encontrada.';
            _cargando = false;
          });
        }
        return;
      }

      final evento = await Servicios.evento.obtener(edicion.eventoId);
      final uid = Servicios.auth.usuarioActual?.uid;

      Postulacion? postVol;
      Postulacion? postAsi;
      Usuario? usuario;

      if (uid != null) {
        final idVol = Postulacion.construirId(
          widget.edicionId,
          uid,
          RolPostulacion.voluntario,
        );
        final idAsi = Postulacion.construirId(
          widget.edicionId,
          uid,
          RolPostulacion.asistente,
        );

        final resultados = await Future.wait([
          Servicios.postulaciones.obtener(idVol),
          Servicios.postulaciones.obtener(idAsi),
          Servicios.usuarios.obtener(uid),
        ]);

        postVol = resultados[0] as Postulacion?;
        postAsi = resultados[1] as Postulacion?;
        usuario = resultados[2] as Usuario?;
      }

      if (mounted) {
        setState(() {
          _edicion = edicion;
          _evento = evento;
          _postulacionVoluntario = postVol;
          _postulacionAsistente = postAsi;
          _usuario = usuario;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error al cargar los datos de la convocatoria.';
          _cargando = false;
        });
      }
    }
  }

  // Determina el texto explicativo cuando el botón de postular está deshabilitado
  String? _obtenerMotivoDeshabilitado(Edicion edicion, RolPostulacion rol) {
    if (edicion.finalizadaEfectiva) return 'La edición ya finalizó';
    if (edicion.estado != EstadoEdicion.abierta) return 'La edición no está abierta';

    final conv = edicion.convocatoriaDe(rol);
    if (!conv.abierta) {
      return 'La convocatoria de ${rol == RolPostulacion.voluntario ? "voluntarios" : "asistentes"} está cerrada';
    }
    if (conv.vencida) return 'El plazo de postulación ya venció';
    if (!conv.hayCupo) return 'Cupos agotados';

    return null;
  }

  // Diálogo de confirmación y transacción de postulación
  Future<void> _postular(RolPostulacion rol) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          rol == RolPostulacion.voluntario
              ? 'Postular como voluntario'
              : 'Inscribirme como asistente',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
        content: Text(
          'Se enviará tu perfil al organizador.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textoPrincipal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textoPrincipal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirmar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final uid = Servicios.auth.usuarioActual?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para postular.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _procesandoPostulacion = true);

    try {
      await Servicios.postulaciones.postular(
        edicionId: widget.edicionId,
        rol: rol,
        uid: uid,
      );

      if (!mounted) return;

      final mensajeExito = rol == RolPostulacion.voluntario
          ? '¡Listo! Tu postulación fue enviada'
          : 'Quedaste inscrito';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeExito),
          backgroundColor: AppColors.estadoAceptadaTexto,
        ),
      );

      await _cargarDatos();
    } on ErrorNegocio catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.mensaje),
          backgroundColor: AppColors.error,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final mensaje = (e.code == 'permission-denied' ||
              e.toString().contains('permission-denied'))
          ? 'No tienes permiso para esta acción.'
          : 'Ocurrió un error. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('permission-denied')
          ? 'No tienes permiso para esta acción.'
          : 'Ocurrió un error. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _procesandoPostulacion = false);
      }
    }
  }

  // Evalúa si una postulación admite ser cancelada desde la interfaz.
  // El backend (PostulacionService.cancelar) es la fuente de verdad.
  bool _puedeCancelar(Postulacion postulacion, Edicion edicion) {
    if (postulacion.asistio) return false;
    if (postulacion.rol == RolPostulacion.voluntario) {
      // rol voluntario: postulacion.estado == enviada y asistio == false
      return postulacion.estado == EstadoPostulacion.enviada;
    }
    // rol asistente: asistio == false y DateTime.now() < edicion.fechaInicio
    return DateTime.now().isBefore(edicion.fechaInicio);
  }

  // Diálogo de confirmación y transacción de cancelación de postulación (RF08)
  Future<void> _confirmarCancelar(
    Postulacion postulacion,
    Edicion edicion,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Cancelar tu postulación a ${edicion.nombre}?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Volver',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textoPrincipal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sí, cancelar',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final uid = Servicios.auth.usuarioActual?.uid;
    if (uid == null) return;

    setState(() => _cancelandoId = postulacion.id);

    try {
      await Servicios.postulaciones.cancelar(postulacion.id, uid);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Postulación cancelada',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.textoPrincipal,
            ),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Recarga el estado completo para actualizar badge, botón y cupos
      await _cargarDatos();
    } on ErrorNegocio catch (e) {
      if (!mounted) return;
      _mostrarMensajeError(e.mensaje);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = (e.code == 'permission-denied' ||
              e.toString().contains('permission-denied'))
          ? 'No tienes permiso para esta acción.'
          : 'Ocurrió un error. Intenta de nuevo.';
      _mostrarMensajeError(msg);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('permission-denied')
          ? 'No tienes permiso para esta acción.'
          : 'Ocurrió un error. Intenta de nuevo.';
      _mostrarMensajeError(msg);
    } finally {
      if (mounted) {
        setState(() => _cancelandoId = null);
      }
    }
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fila de metadato con icono
  Widget _construirFilaDato(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textoPrincipal,
                ),
                children: [
                  TextSpan(
                    text: '$titulo: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: valor,
                    style: const TextStyle(color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bloque para cada convocatoria (Voluntarios o Asistentes)
  Widget _construirBloqueConvocatoria({
    required RolPostulacion rol,
    required Convocatoria convocatoria,
    required Postulacion? postulacionPrevia,
    required Edicion edicion,
  }) {
    if (!convocatoria.abierta) return const SizedBox.shrink();

    final esVoluntario = rol == RolPostulacion.voluntario;
    final admite = edicion.admitePostulaciones(rol);
    final motivo = _obtenerMotivoDeshabilitado(edicion, rol);
    final haPostulado = postulacionPrevia != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del bloque y estado o botón de cancelar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    esVoluntario
                        ? Icons.volunteer_activism_rounded
                        : Icons.how_to_reg_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    esVoluntario ? 'Voluntarios' : 'Asistentes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                ],
              ),
              if (haPostulado)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EstadoBadge(estado: postulacionPrevia.estado),
                    // Solo se muestra si cumple los requisitos de negocio para cancelar
                    if (_puedeCancelar(postulacionPrevia, edicion)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: (_cancelandoId != null || _procesandoPostulacion)
                                ? null
                                : () => _confirmarCancelar(postulacionPrevia, edicion),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              foregroundColor: AppColors.textoPrincipal,
                              disabledForegroundColor: AppColors.textoSecundario,
                              side: const BorderSide(color: AppColors.borde, width: 1.5),
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _cancelandoId == postulacionPrevia.id
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Text('Cancelar postulación'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Cupos disponibles
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: AppColors.textoSecundario,
              ),
              const SizedBox(width: 8),
              Text(
                '${convocatoria.cupos - convocatoria.ocupados} de ${convocatoria.cupos} cupos disponibles',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textoPrincipal,
                ),
              ),
            ],
          ),

          // Fecha límite si existe
          if (convocatoria.fechaLimite != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.alarm_rounded,
                  size: 16,
                  color: AppColors.textoSecundario,
                ),
                const SizedBox(width: 8),
                Text(
                  textoFechaLimite(convocatoria.fechaLimite),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ],

          // Beneficios (solo voluntarios)
          if (esVoluntario &&
              convocatoria.beneficios != null &&
              convocatoria.beneficios!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Beneficios:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              convocatoria.beneficios!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textoSecundario,
                height: 1.3,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Botón de postulación o aviso de postulado
          if (!haPostulado) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: (admite && !_procesandoPostulacion && _cancelandoId == null)
                    ? () => _postular(rol)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textoPrincipal,
                  disabledBackgroundColor: AppColors.borde,
                  disabledForegroundColor: AppColors.textoSecundario,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _procesandoPostulacion
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textoPrincipal,
                        ),
                      )
                    : Text(
                        esVoluntario
                            ? 'Postular como voluntario'
                            : 'Inscribirme como asistente',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (!admite && motivo != null) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  motivo,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ),
            ],
          ] else ...[
            // Aviso cuando ya postuló
            Text(
              esVoluntario
                  ? 'Ya enviaste tu postulación a esta convocatoria.'
                  : 'Ya estás inscrito como asistente a esta edición.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textoSecundario,
              ),
            ),
          ],

          // Formulario externo si ya postuló y existe enlaceExterno
          if (haPostulado &&
              convocatoria.enlaceExterno != null &&
              convocatoria.enlaceExterno!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: AppColors.textoPrincipal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Abrir formulario externo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    convocatoria.enlaceExterno!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textoPrincipal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: convocatoria.enlaceExterno!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar enlace'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textoPrincipal,
                      side: const BorderSide(color: AppColors.textoPrincipal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tamano = Responsive.tamano(context);
    final esCompacto = tamano == TamanoPantalla.compacto;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textoPrincipal,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver',
        ),
        title: Text(
          'Detalle de convocatoria',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoPrincipal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarDatos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.textoPrincipal,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ContenidoCentrado(
                    child: esCompacto
                        ? _construirLayoutCompacto()
                        : _construirLayoutAmplio(),
                  ),
                ),
    );
  }

  // Layout para móvil compacto (< 600 px)
  Widget _construirLayoutCompacto() {
    final edicion = _edicion!;
    final evento = _evento;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta principal de información del evento
        _construirTarjetaPrincipal(edicion, evento),

        const SizedBox(height: 20),

        // Aviso suave de perfil incompleto
        if (_usuario != null && _usuario!.carrera.isEmpty)
          _construirAvisoPerfilIncompleto(),

        // Convocatoria de Voluntarios
        if (edicion.voluntarios.abierta) ...[
          _construirBloqueConvocatoria(
            rol: RolPostulacion.voluntario,
            convocatoria: edicion.voluntarios,
            postulacionPrevia: _postulacionVoluntario,
            edicion: edicion,
          ),
          const SizedBox(height: 16),
        ],

        // Convocatoria de Asistentes
        if (edicion.asistentes.abierta) ...[
          _construirBloqueConvocatoria(
            rol: RolPostulacion.asistente,
            convocatoria: edicion.asistentes,
            postulacionPrevia: _postulacionAsistente,
            edicion: edicion,
          ),
        ],
      ],
    );
  }

  // Layout para escritorio y tablet (>= 600 px): 8 columnas principal + 4 columnas lateral
  Widget _construirLayoutAmplio() {
    final edicion = _edicion!;
    final evento = _evento;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta principal (8 / 12)
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _construirTarjetaPrincipal(edicion, evento),
              if (_usuario != null && _usuario!.carrera.isEmpty) ...[
                const SizedBox(height: 20),
                _construirAvisoPerfilIncompleto(),
              ],
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Panel lateral con botones y bloques de postulación (4 / 12)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Convocatorias',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              const SizedBox(height: 12),

              // Voluntarios
              if (edicion.voluntarios.abierta) ...[
                _construirBloqueConvocatoria(
                  rol: RolPostulacion.voluntario,
                  convocatoria: edicion.voluntarios,
                  postulacionPrevia: _postulacionVoluntario,
                  edicion: edicion,
                ),
                const SizedBox(height: 16),
              ],

              // Asistentes
              if (edicion.asistentes.abierta) ...[
                _construirBloqueConvocatoria(
                  rol: RolPostulacion.asistente,
                  convocatoria: edicion.asistentes,
                  postulacionPrevia: _postulacionAsistente,
                  edicion: edicion,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Tarjeta principal con metadatos del evento y descripción
  Widget _construirTarjetaPrincipal(Edicion edicion, Evento? evento) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              edicion.tipo.etiqueta.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Título de la edición
          Text(
            edicion.nombre,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
              height: 1.25,
            ),
          ),

          // Evento padre y entidad organizadora
          const SizedBox(height: 6),
          Text(
            evento != null && evento.entidad.isNotEmpty
                ? '${evento.nombre} · ${evento.entidad}'
                : (edicion.eventoNombre.isNotEmpty ? edicion.eventoNombre : ''),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textoSecundario,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borde, height: 1),
          const SizedBox(height: 16),

          // Metadatos clave
          _construirFilaDato(
            Icons.calendar_today_rounded,
            'Fechas',
            rangoFechas(edicion.fechaInicio, edicion.fechaFin),
          ),
          _construirFilaDato(
            Icons.location_on_rounded,
            'Lugar',
            edicion.lugar.isNotEmpty ? edicion.lugar : edicion.modalidad.etiqueta,
          ),
          _construirFilaDato(
            Icons.devices_rounded,
            'Modalidad',
            edicion.modalidad.etiqueta,
          ),
          _construirFilaDato(
            Icons.school_rounded,
            'Universidad',
            edicion.universidad.isNotEmpty
                ? edicion.universidad
                : 'Abierto a todas las universidades',
          ),

          // Descripción completa
          if (evento != null && evento.descripcion.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.borde, height: 1),
            const SizedBox(height: 16),
            Text(
              'Descripción del evento',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              evento.descripcion,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textoPrincipal,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Aviso suave de perfil incompleto
  Widget _construirAvisoPerfilIncompleto() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textoPrincipal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Completa tu perfil para que el organizador te conozca mejor.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
