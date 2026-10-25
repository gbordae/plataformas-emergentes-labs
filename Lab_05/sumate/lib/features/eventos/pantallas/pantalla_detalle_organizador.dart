// Pantalla de detalle de organizador para una edición concreta (RF09, RF10, RF14).
// Muestra datos de la edición, métricas de postulantes en tiempo real,
// acciones para gestionar postulantes y cerrar o reabrir la convocatoria.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/enums.dart';
import '../../../core/errores.dart';
import '../../../core/formato.dart';
import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../postulaciones/modelos/postulacion.dart';
import '../../postulaciones/pantallas/pantalla_gestion_postulantes.dart';
import '../modelos/edicion.dart';

class PantallaDetalleOrganizador extends StatefulWidget {
  final String edicionId;
  final Future<Edicion?>? futureEdicion;
  final Future<List<Postulacion>>? futurePostulantes;

  const PantallaDetalleOrganizador({
    super.key,
    required this.edicionId,
    this.futureEdicion,
    this.futurePostulantes,
  });

  @override
  State<PantallaDetalleOrganizador> createState() =>
      _PantallaDetalleOrganizadorState();
}

class _PantallaDetalleOrganizadorState
    extends State<PantallaDetalleOrganizador> {
  Edicion? _edicion;
  List<Postulacion> _postulantes = [];
  bool _cargando = true;
  String? _error;
  bool _procesandoAccion = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga la edición y sus postulantes para calcular métricas en el cliente.
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final futEdicion = widget.futureEdicion ??
          Servicios.edicion.obtener(widget.edicionId);
      final futPostulantes = widget.futurePostulantes ??
          Servicios.postulaciones.postulantesDeEdicion(widget.edicionId);

      final resultados = await Future.wait([futEdicion, futPostulantes]);
      final edicion = resultados[0] as Edicion?;
      final postulantes = (resultados[1] as List<Postulacion>?) ?? [];

      if (!mounted) return;

      if (edicion == null) {
        setState(() {
          _error = 'Edición no encontrada.';
          _cargando = false;
        });
        return;
      }

      setState(() {
        _edicion = edicion;
        _postulantes = postulantes;
        _cargando = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (e.code == 'permission-denied' ||
            e.toString().contains('permission-denied')) {
          _error = 'No tienes permiso para ver esta edición.';
        } else {
          _error = 'Ocurrió un error al cargar la información.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        if (e.toString().contains('permission-denied')) {
          _error = 'No tienes permiso para ver esta edición.';
        } else {
          _error = 'Ocurrió un error al cargar la información.';
        }
      });
    }
  }

  /// Diálogo de confirmación para cerrar o reabrir la convocatoria (RF14).
  Future<void> _confirmarCerrarOReabrir(Edicion edicion) async {
    final esCerrar = edicion.estado == EstadoEdicion.abierta;
    final accion = esCerrar ? 'Cerrar' : 'Reabrir';
    final mensaje = esCerrar
        ? '¿Estás seguro de que deseas cerrar la convocatoria? Los estudiantes ya no podrán postularse.'
        : '¿Estás seguro de que deseas reabrir la convocatoria? Los estudiantes podrán volver a postularse.';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '$accion convocatoria',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
        content: Text(
          mensaje,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textoSecundario,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: esCerrar ? AppColors.error : AppColors.secondary,
              foregroundColor:
                  esCerrar ? AppColors.superficie : AppColors.textoPrincipal,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(accion),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesandoAccion = true);
    try {
      if (esCerrar) {
        await Servicios.edicion.cerrar(edicion.id);
      } else {
        await Servicios.edicion.reabrir(edicion.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esCerrar ? 'Convocatoria cerrada' : 'Convocatoria reabierta',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.textoPrincipal,
            ),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cargar();
    } on ErrorNegocio catch (e) {
      _mostrarMensajeError(e.mensaje);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' ||
          e.toString().contains('permission-denied')) {
        _mostrarMensajeError('No tienes permiso para esta acción.');
      } else {
        _mostrarMensajeError('Ocurrió un error. Intenta de nuevo.');
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        _mostrarMensajeError('No tienes permiso para esta acción.');
      } else {
        _mostrarMensajeError('Ocurrió un error. Intenta de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() => _procesandoAccion = false);
      }
    }
  }

  void _mostrarMensajeError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tamano = Responsive.tamano(context);
    final esAmplio = tamano == TamanoPantalla.amplio;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: Text(
          'Detalle de la edición',
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
                        ElevatedButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _cargar(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ContenidoCentrado(
                      anchoMaximo: 1200,
                      child: esAmplio
                          ? _buildLayoutAmplio(_edicion!)
                          : _buildLayoutCompacto(_edicion!),
                    ),
                  ),
                ),
    );
  }

  // ── Layout Compacto / Medio (<1024 px) ──────────────────────────────────
  Widget _buildLayoutCompacto(Edicion edicion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTarjetasMetricas(),
        const SizedBox(height: 16),
        _buildTarjetaAcciones(edicion),
        const SizedBox(height: 16),
        _buildTarjetaDatosEdicion(edicion),
      ],
    );
  }

  // ── Layout Amplio (>=1024 px: 8/12 y 4/12) ──────────────────────────────
  Widget _buildLayoutAmplio(Edicion edicion) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna principal (8 / 12)
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTarjetaDatosEdicion(edicion),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Panel lateral de métricas y gestión (4 / 12)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTarjetaAcciones(edicion),
              const SizedBox(height: 16),
              _buildTarjetasMetricas(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Métricas calculadas en el cliente ────────────────────────────────────
  Widget _buildTarjetasMetricas() {
    final total = _postulantes.length;
    final enEspera = _postulantes
        .where((p) => p.estado == EstadoPostulacion.enviada)
        .length;
    final aceptados = _postulantes
        .where((p) => p.estado == EstadoPostulacion.aceptada)
        .length;
    final asistieron = _postulantes.where((p) => p.asistio).length;

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
          Text(
            'Métricas de la convocatoria',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildItemMetrica(
                  titulo: 'Postulantes',
                  valor: '$total',
                  icono: Icons.people_outline_rounded,
                  colorFondo: AppColors.primaryContainer.withValues(alpha: 0.5),
                  colorTexto: AppColors.textoPrincipal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildItemMetrica(
                  titulo: 'En espera',
                  valor: '$enEspera',
                  icono: Icons.schedule_rounded,
                  colorFondo: enEspera > 0
                      ? AppColors.tertiary
                      : AppColors.secondaryContainer,
                  colorTexto: AppColors.textoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildItemMetrica(
                  titulo: 'Aceptados',
                  valor: '$aceptados',
                  icono: Icons.check_circle_outline_rounded,
                  colorFondo: AppColors.estadoAceptadaFondo,
                  colorTexto: AppColors.estadoAceptadaTexto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildItemMetrica(
                  titulo: 'Asistieron',
                  valor: '$asistieron',
                  icono: Icons.how_to_reg_rounded,
                  colorFondo: AppColors.primaryContainer,
                  colorTexto: AppColors.textoPrincipal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemMetrica({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color colorFondo,
    required Color colorTexto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  valor,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorTexto,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icono, size: 20, color: colorTexto),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel de acciones para el organizador ────────────────────────────────
  Widget _buildTarjetaAcciones(Edicion edicion) {
    final enEspera = _postulantes
        .where((p) => p.estado == EstadoPostulacion.enviada)
        .length;
    final esFinalizada = edicion.finalizadaEfectiva;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gestión de la edición',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),

          // Botón primario: Gestionar postulantes
          ElevatedButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PantallaGestionPostulantes(
                    edicionId: edicion.id,
                    edicion: edicion,
                  ),
                ),
              );
              _cargar();
            },
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Icon(Icons.people_alt_rounded, size: 18),
                const Text('Gestionar postulantes'),
                if (enEspera > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '$enEspera',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botón de contorno: Cerrar o Reabrir convocatoria (o aviso si finalizó)
          if (esFinalizada)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: AppColors.textoSecundario, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta edición finalizó',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (edicion.estado == EstadoEdicion.abierta)
            OutlinedButton.icon(
              onPressed: _procesandoAccion
                  ? null
                  : () => _confirmarCerrarOReabrir(edicion),
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text('Cerrar convocatoria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textoPrincipal,
                side: const BorderSide(color: AppColors.borde),
              ),
            )
          else if (edicion.estado == EstadoEdicion.cerrada)
            OutlinedButton.icon(
              onPressed: _procesandoAccion
                  ? null
                  : () => _confirmarCerrarOReabrir(edicion),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text('Reabrir convocatoria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textoPrincipal,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tarjeta principal con datos de la edición ────────────────────────────
  Widget _buildTarjetaDatosEdicion(Edicion edicion) {
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
          // Cabecera con categoría y estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'Tu evento',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBadgeEstado(edicion),
            ],
          ),
          const SizedBox(height: 14),

          // Título de la edición
          Text(
            edicion.nombre,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),

          // Nombre del evento padre
          Text(
            edicion.eventoNombre,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: AppColors.borde),
          const SizedBox(height: 16),

          // Metadatos
          _buildFilaMetadato(
            icono: Icons.calendar_today_rounded,
            titulo: 'Fecha y horario',
            valor: rangoFechas(edicion.fechaInicio, edicion.fechaFin),
          ),
          const SizedBox(height: 10),
          _buildFilaMetadato(
            icono: Icons.location_on_rounded,
            titulo: 'Lugar',
            valor: edicion.lugar.isNotEmpty ? edicion.lugar : 'Por definir',
          ),
          const SizedBox(height: 10),
          _buildFilaMetadato(
            icono: Icons.devices_rounded,
            titulo: 'Modalidad',
            valor: edicion.modalidad.etiqueta,
          ),
          if (edicion.universidad.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildFilaMetadato(
              icono: Icons.school_rounded,
              titulo: 'Universidad sede',
              valor: edicion.universidad,
            ),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: AppColors.borde),
          const SizedBox(height: 20),

          // Convocatorias y cupos
          Text(
            'Cupos y convocatorias',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 12),

          // Voluntarios
          if (edicion.voluntarios.abierta) ...[
            _buildBloqueCupo(
              rol: 'Voluntarios',
              ocupados: edicion.voluntarios.ocupados,
              cupos: edicion.voluntarios.cupos,
              fechaLimite: edicion.voluntarios.fechaLimite,
              beneficios: edicion.voluntarios.beneficios,
              enlaceExterno: edicion.voluntarios.enlaceExterno,
            ),
            const SizedBox(height: 12),
          ],

          // Asistentes
          if (edicion.asistentes.abierta) ...[
            _buildBloqueCupo(
              rol: 'Asistentes',
              ocupados: edicion.asistentes.ocupados,
              cupos: edicion.asistentes.cupos,
              fechaLimite: edicion.asistentes.fechaLimite,
              enlaceExterno: edicion.asistentes.enlaceExterno,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilaMetadato({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Row(
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
    );
  }

  Widget _buildBloqueCupo({
    required String rol,
    required int ocupados,
    required int cupos,
    DateTime? fechaLimite,
    String? beneficios,
    String? enlaceExterno,
  }) {
    final progreso = cupos > 0 ? (ocupados / cupos).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rol,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                ),
              ),
              Flexible(
                child: Text(
                  '$ocupados de $cupos cubiertos',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textoSecundario,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: AppColors.borde,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (fechaLimite != null) ...[
            const SizedBox(height: 8),
            Text(
              'Fecha límite: ${fechaCorta(fechaLimite)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textoSecundario,
              ),
            ),
          ],
          if (beneficios != null && beneficios.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Beneficios: $beneficios',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textoSecundario,
              ),
            ),
          ],
          if (enlaceExterno != null && enlaceExterno.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Enlace externo: $enlaceExterno',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeEstado(Edicion edicion) {
    final Color colorFondo;
    final Color colorTexto;
    final IconData icono;
    final String etiqueta;

    if (edicion.finalizadaEfectiva) {
      colorFondo = AppColors.tertiaryContainer;
      colorTexto = AppColors.textoSecundario;
      icono = Icons.flag_rounded;
      etiqueta = 'Finalizada';
    } else if (edicion.estado == EstadoEdicion.cerrada) {
      colorFondo = AppColors.secondaryContainer;
      colorTexto = AppColors.estadoEnviadaTexto;
      icono = Icons.lock_outline_rounded;
      etiqueta = 'Cerrada';
    } else {
      colorFondo = AppColors.estadoAceptadaFondo;
      colorTexto = AppColors.estadoAceptadaTexto;
      icono = Icons.check_circle_outline_rounded;
      etiqueta = 'Abierta';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: colorTexto),
          const SizedBox(width: 5),
          Text(
            etiqueta,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }
}
