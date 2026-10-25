// Pantalla de Mis Eventos para organizadores (RF03, RF14).
// Lista las ediciones que el usuario organiza divididas en "Activas" y "Pasadas".
// Muestra badges de estado y badge coral "N por revisar" cuando hay postulaciones pendientes.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/enums.dart';
import '../../../core/formato.dart';
import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cabecera_pantalla.dart';
import '../../../core/widgets/evento_card.dart';
import '../modelos/edicion.dart';
import 'pantalla_detalle_organizador.dart';
import 'pantalla_publicar_evento.dart';

class PantallaMisEventos extends StatefulWidget {
  const PantallaMisEventos({super.key});

  @override
  State<PantallaMisEventos> createState() => _PantallaMisEventosState();
}

class _PantallaMisEventosState extends State<PantallaMisEventos>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Edicion>> _futureEdiciones;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// UID del usuario actualmente autenticado.
  String get _uid => Servicios.auth.usuarioActual?.uid ?? '';

  /// Asigna un nuevo Future dentro de setState para recargar datos con FutureBuilder.
  void _cargar() {
    setState(() {
      _futureEdiciones = Servicios.edicion.misEdiciones(_uid);
    });
  }

  /// Navega al detalle del organizador (placeholder temporal) y recarga al volver.
  Future<void> _irADetalle(String edicionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaDetalleOrganizador(edicionId: edicionId),
      ),
    );
    _cargar();
  }

  /// Abre la pantalla para publicar un nuevo evento y recarga si el resultado fue exitoso.
  Future<void> _abrirPublicarEvento() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PantallaPublicarEvento(),
      ),
    );

    if (resultado == true) {
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Evento publicado',
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera superior institucional
          const CabeceraPantalla(
            titulo: 'Mis eventos',
            subtitulo: 'Gestiona las convocatorias que publicaste',
          ),

          // Pestañas Activas / Pasadas
          _buildTabBar(),

          // Contenido principal de las pestañas
          Expanded(
            child: FutureBuilder<List<Edicion>>(
              future: _futureEdiciones,
              builder: (context, snapshot) {
                // Estado: cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                // Estado: error
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => _cargar(),
                    child: SingleChildScrollView(
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
                                'Ocurrió un error al cargar tus eventos.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textoPrincipal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                snapshot.error.toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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
                    ),
                  );
                }

                final todas = snapshot.data ?? [];

                // Filtro en cliente: Activas = abierta y !finalizadaEfectiva
                final activas = todas
                    .where((e) => e.estado == EstadoEdicion.abierta && !e.finalizadaEfectiva)
                    .toList()
                  ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio)); // ascendente

                // Pasadas = el resto
                final pasadas = todas
                    .where((e) => !(e.estado == EstadoEdicion.abierta && !e.finalizadaEfectiva))
                    .toList()
                  ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio)); // descendente

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Pestaña Activas
                    _PestaniaEdiciones(
                      ediciones: activas,
                      esActivas: true,
                      mensajeVacioTitulo: 'Aún no organizas eventos',
                      mensajeVacioSubtitulo:
                          'Publica un evento para comenzar a gestionar convocatorias y recibir postulantes.',
                      iconoVacio: Icons.event_available_outlined,
                      onRefresh: () async => _cargar(),
                      onTapTarjeta: _irADetalle,
                      onPublicar: _abrirPublicarEvento,
                    ),

                    // Pestaña Pasadas
                    _PestaniaEdiciones(
                      ediciones: pasadas,
                      esActivas: false,
                      mensajeVacioTitulo: 'Aquí aparecerán tus eventos pasados',
                      mensajeVacioSubtitulo:
                          'Los eventos finalizados o cerrados se mostrarán en esta sección.',
                      iconoVacio: Icons.history_rounded,
                      onRefresh: () async => _cargar(),
                      onTapTarjeta: _irADetalle,
                      onPublicar: _abrirPublicarEvento,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // FAB mostaza para publicar evento
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _abrirPublicarEvento,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textoPrincipal,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Publicar evento',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textoPrincipal,
          ),
        ),
      ),
    );
  }

  /// Construye el TabBar con diseño de píldora institucional.
  Widget _buildTabBar() {
    return Container(
      color: AppColors.fondo,
      padding: EdgeInsets.fromLTRB(
        Responsive.margenHorizontal(context),
        8,
        Responsive.margenHorizontal(context),
        0,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(9999),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textoPrincipal,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textoSecundario,
        ),
        labelColor: AppColors.textoPrincipal,
        unselectedLabelColor: AppColors.textoSecundario,
        tabs: const [
          Tab(text: 'Activas'),
          Tab(text: 'Pasadas'),
        ],
      ),
    );
  }
}

/// Vista de contenido para una de las pestañas (Activas o Pasadas).
class _PestaniaEdiciones extends StatelessWidget {
  final List<Edicion> ediciones;
  final bool esActivas;
  final String mensajeVacioTitulo;
  final String mensajeVacioSubtitulo;
  final IconData iconoVacio;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String edicionId) onTapTarjeta;
  final VoidCallback onPublicar;

  const _PestaniaEdiciones({
    required this.ediciones,
    required this.esActivas,
    required this.mensajeVacioTitulo,
    required this.mensajeVacioSubtitulo,
    required this.iconoVacio,
    required this.onRefresh,
    required this.onTapTarjeta,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    final columnas = Responsive.columnasGrilla(context);
    final gutter = Responsive.gutter(context);
    final margen = Responsive.margenHorizontal(context);

    // Estado vacío
    if (ediciones.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(margen, 40, margen, 88),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconoVacio, size: 52, color: AppColors.textoSecundario),
                  const SizedBox(height: 16),
                  Text(
                    mensajeVacioTitulo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mensajeVacioSubtitulo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textoSecundario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (esActivas) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: onPublicar,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Crear mi primer evento'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final esCompacto = Responsive.tamano(context) == TamanoPantalla.compacto;
    // 88 px deja hueco para el FAB; se suma el inset de gestos si aún aplica.
    final paddingInferior = 88.0 + MediaQuery.paddingOf(context).bottom;

    Widget tarjeta(Edicion edicion) {
      return EventoCard(
        categoria: edicion.tipo.etiqueta,
        titulo: edicion.nombre,
        fecha: fechaCorta(edicion.fechaInicio),
        lugar: edicion.lugar.isNotEmpty ? edicion.lugar : edicion.modalidad.etiqueta,
        organizador: edicion.eventoNombre,
        pie: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _BadgeEstadoEdicion(edicion: edicion),
            ),
            if (esActivas) ...[
              const SizedBox(width: 8),
              _BadgePendientes(
                key: ValueKey(edicion.id),
                edicionId: edicion.id,
              ),
            ],
          ],
        ),
        onTap: () => onTapTarjeta(edicion.id),
      );
    }

    final listado = esCompacto
        ? ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ediciones.length,
            separatorBuilder: (_, _) => SizedBox(height: gutter),
            itemBuilder: (context, index) => tarjeta(ediciones[index]),
          )
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ediciones.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnas,
              crossAxisSpacing: gutter,
              mainAxisSpacing: gutter,
              mainAxisExtent: 260,
            ),
            itemBuilder: (context, index) => tarjeta(ediciones[index]),
          );

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(margen, 16, margen, paddingInferior),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: listado,
          ),
        ),
      ),
    );
  }
}

/// Etiqueta visual para el estado de una edición (Abierta, Cerrada o Finalizada).
/// Siempre incluye ícono + texto + contenedor acorde al sistema de diseño.
class _BadgeEstadoEdicion extends StatelessWidget {
  final Edicion edicion;

  const _BadgeEstadoEdicion({required this.edicion});

  @override
  Widget build(BuildContext context) {
    final Color colorFondo;
    final Color colorContenido;
    final IconData icono;
    final String etiqueta;

    if (edicion.finalizadaEfectiva) {
      colorFondo = AppColors.tertiaryContainer;
      colorContenido = AppColors.textoSecundario;
      icono = Icons.flag_rounded;
      etiqueta = 'Finalizada';
    } else if (edicion.estado == EstadoEdicion.cerrada) {
      colorFondo = AppColors.secondaryContainer;
      colorContenido = AppColors.estadoEnviadaTexto;
      icono = Icons.lock_outline_rounded;
      etiqueta = 'Cerrada';
    } else {
      colorFondo = AppColors.estadoAceptadaFondo;
      colorContenido = AppColors.estadoAceptadaTexto;
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
          Icon(icono, size: 15, color: colorContenido),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              etiqueta,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorContenido,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge coral (#FDA769) con texto e ícono #473C33 "N por revisar".
/// Escucha postulaciones en espera con snapshots(); si falla o es 0 no muestra nada.
class _BadgePendientes extends StatefulWidget {
  final String edicionId;

  const _BadgePendientes({super.key, required this.edicionId});

  @override
  State<_BadgePendientes> createState() => _BadgePendientesState();
}

class _BadgePendientesState extends State<_BadgePendientes> {
  late Stream<int> _stream;

  @override
  void initState() {
    super.initState();
    _stream =
        Servicios.postulaciones.escucharCantidadPendientes(widget.edicionId);
  }

  @override
  void didUpdateWidget(covariant _BadgePendientes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.edicionId != widget.edicionId) {
      _stream =
          Servicios.postulaciones.escucharCantidadPendientes(widget.edicionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final pendientes = snapshot.data!;
        if (pendientes <= 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tertiary, // Coral #FDA769
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_rounded,
                size: 15,
                color: AppColors.textoPrincipal,
              ),
              const SizedBox(width: 5),
              Text(
                '$pendientes por revisar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal, // #473C33
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
