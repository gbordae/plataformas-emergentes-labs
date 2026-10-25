// Pantalla de gestión de postulantes para una edición concreta (RF09, RF10).
// Permite filtrar por estado y rol, revisar perfiles, aceptar/rechazar voluntarios
// y marcar asistencia a eventos ya iniciados.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/enums.dart';
import '../../../core/errores.dart';
import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/filtro_chip.dart';
import '../../../core/widgets/postulante_card.dart';
import '../../eventos/modelos/edicion.dart';
import '../modelos/postulacion.dart';

class PantallaGestionPostulantes extends StatefulWidget {
  final String edicionId;
  final Edicion edicion;
  final Future<List<Postulacion>>? futurePostulantes;

  const PantallaGestionPostulantes({
    super.key,
    required this.edicionId,
    required this.edicion,
    this.futurePostulantes,
  });

  @override
  State<PantallaGestionPostulantes> createState() =>
      _PantallaGestionPostulantesState();
}

class _PantallaGestionPostulantesState
    extends State<PantallaGestionPostulantes> {
  // Stream creado una sola vez (initState / reintento), no en build().
  late Stream<List<Postulacion>> _streamPostulantes;

  // Filtros aplicados en memoria en el cliente
  EstadoPostulacion? _filtroEstado; // null = Todos
  RolPostulacion? _filtroRol; // null = Todos

  String? _procesandoId;

  @override
  void initState() {
    super.initState();
    _suscribir();
  }

  /// Abre la consulta en vivo. En tests se reutiliza el Future inyectado.
  void _suscribir() {
    _streamPostulantes = widget.futurePostulantes != null
        ? widget.futurePostulantes!.asStream()
        : Servicios.postulaciones.escucharPostulantesDeEdicion(widget.edicionId);
  }

  void _cargar() {
    setState(_suscribir);
  }

  /// Responde una postulación de voluntario (aceptar o rechazar) en Firestore.
  Future<void> _responder(
    Postulacion postulacion,
    EstadoPostulacion nuevoEstado,
  ) async {
    setState(() => _procesandoId = postulacion.id);

    try {
      await Servicios.postulaciones.responder(postulacion.id, nuevoEstado);
      if (mounted) {
        final accion = nuevoEstado == EstadoPostulacion.aceptada
            ? 'aceptada'
            : 'rechazada';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Postulación $accion correctamente',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textoPrincipal,
              ),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // El Stream de snapshots actualiza la lista; no hace falta recargar a mano.
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
        setState(() => _procesandoId = null);
      }
    }
  }

  /// Marca o desmarca la asistencia de un postulante aceptado (RF10).
  Future<void> _marcarAsistio(Postulacion postulacion, bool valor) async {
    setState(() => _procesandoId = postulacion.id);

    try {
      await Servicios.postulaciones.marcarAsistio(postulacion.id, valor);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              valor ? 'Asistencia confirmada' : 'Asistencia desmarcada',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textoPrincipal,
              ),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
        setState(() => _procesandoId = null);
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
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        // Alto extra: título + subtítulo sin invadir la barra de estado.
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Postulantes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
            ),
            Text(
              widget.edicion.nombre,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textoSecundario,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: AppColors.superficie,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textoPrincipal),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.borde),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _cargar(),
        child: StreamBuilder<List<Postulacion>>(
          stream: _streamPostulantes,
          builder: (context, snapshot) {
            // Estado: cargando
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(64.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            // Estado: error
            if (snapshot.hasError) {
              final esPermiso = snapshot.error.toString().contains('permission-denied');
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
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
                          esPermiso
                              ? 'No tienes permiso para esta acción.'
                              : 'Ocurrió un error al cargar postulantes.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textoPrincipal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final todas = snapshot.data ?? [];

            // Estado: vacío general
            if (todas.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 56,
                          color: AppColors.textoSecundario,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no hay postulantes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textoPrincipal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cuando los estudiantes postulen a tu convocatoria, aparecerán aquí para que los revises.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.textoSecundario,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Filtrado en el cliente para respuesta instantánea
            var filtrados = todas;
            if (_filtroEstado != null) {
              filtrados = filtrados.where((p) => p.estado == _filtroEstado).toList();
            }
            if (_filtroRol != null) {
              filtrados = filtrados.where((p) => p.rol == _filtroRol).toList();
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ContenidoCentrado(
                anchoMaximo: 1200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filtros por Estado y Rol
                    _buildFilaFiltros(todas),
                    const SizedBox(height: 12),

                    // Conteo de resultados
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Mostrando ${filtrados.length} de ${todas.length} postulantes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista o vacío por filtros
                    if (filtrados.isEmpty)
                      _buildVacioFiltros()
                    else
                      _buildListaPostulantes(context, filtrados),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Fila horizontal de chips para filtrar por estado y rol.
  Widget _buildFilaFiltros(List<Postulacion> todas) {
    final cantEnEspera =
        todas.where((p) => p.estado == EstadoPostulacion.enviada).length;
    final cantAceptados =
        todas.where((p) => p.estado == EstadoPostulacion.aceptada).length;
    final cantRechazados =
        todas.where((p) => p.estado == EstadoPostulacion.rechazada).length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Estados
        FiltroChip(
          label: 'Todos (${todas.length})',
          seleccionado: _filtroEstado == null,
          onSelected: (_) => setState(() => _filtroEstado = null),
        ),
        FiltroChip(
          label: 'En espera ($cantEnEspera)',
          seleccionado: _filtroEstado == EstadoPostulacion.enviada,
          onSelected: (_) => setState(() => _filtroEstado = EstadoPostulacion.enviada),
        ),
        FiltroChip(
          label: 'Aceptados ($cantAceptados)',
          seleccionado: _filtroEstado == EstadoPostulacion.aceptada,
          onSelected: (_) => setState(() => _filtroEstado = EstadoPostulacion.aceptada),
        ),
        FiltroChip(
          label: 'Rechazados ($cantRechazados)',
          seleccionado: _filtroEstado == EstadoPostulacion.rechazada,
          onSelected: (_) => setState(() => _filtroEstado = EstadoPostulacion.rechazada),
        ),

        const SizedBox(width: 8),

        // Roles
        FiltroChip(
          label: 'Voluntarios',
          seleccionado: _filtroRol == RolPostulacion.voluntario,
          onSelected: (sel) => setState(() {
            _filtroRol = sel ? RolPostulacion.voluntario : null;
          }),
        ),
        FiltroChip(
          label: 'Asistentes',
          seleccionado: _filtroRol == RolPostulacion.asistente,
          onSelected: (sel) => setState(() {
            _filtroRol = sel ? RolPostulacion.asistente : null;
          }),
        ),
      ],
    );
  }

  /// Mensaje cuando los filtros no coinciden con ninguna postulación.
  Widget _buildVacioFiltros() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list_off_rounded,
              size: 48,
              color: AppColors.textoSecundario,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay postulantes con esos filtros',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textoPrincipal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _filtroEstado = null;
                  _filtroRol = null;
                });
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la lista de postulantes adaptable: 1 columna en móvil y 2 columnas flexibles en tablet/web.
  Widget _buildListaPostulantes(
    BuildContext context,
    List<Postulacion> lista,
  ) {
    final tamano = Responsive.tamano(context);
    final esCompacto = tamano == TamanoPantalla.compacto;

    // Móvil (<600 px): 1 columna directa
    if (esCompacto) {
      return Column(
        children: lista.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostulanteCard(
              postulacion: p,
              fechaInicioEdicion: widget.edicion.fechaInicio,
              enProceso: _procesandoId == p.id,
              onResponder: _responder,
              onMarcarAsistio: _marcarAsistio,
            ),
          );
        }).toList(),
      );
    }

    // Medio y Amplio (>=600 px): 2 columnas con altura flexible
    final col1 = <Postulacion>[];
    final col2 = <Postulacion>[];
    for (int i = 0; i < lista.length; i++) {
      if (i % 2 == 0) {
        col1.add(lista[i]);
      } else {
        col2.add(lista[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: col1.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostulanteCard(
                  postulacion: p,
                  fechaInicioEdicion: widget.edicion.fechaInicio,
                  enProceso: _procesandoId == p.id,
                  onResponder: _responder,
                  onMarcarAsistio: _marcarAsistio,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: col2.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PostulanteCard(
                  postulacion: p,
                  fechaInicioEdicion: widget.edicion.fechaInicio,
                  enProceso: _procesandoId == p.id,
                  onResponder: _responder,
                  onMarcarAsistio: _marcarAsistio,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
