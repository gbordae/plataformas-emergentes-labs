// Pantalla de Mis Postulaciones (RF08) y Historial (RF11).
// Usa DefaultTabController con dos pestañas: "Activas" e "Historial".
// Layout responsive igual a PantallaExplorar (1/2/3 columnas según breakpoint).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cabecera_pantalla.dart';
import '../../../core/widgets/postulacion_card.dart';
import '../../eventos/pantallas/pantalla_detalle_convocatoria.dart';
import '../modelos/postulacion.dart';
import 'dialogo_constancia.dart';

class PantallaMisPostulaciones extends StatefulWidget {
  const PantallaMisPostulaciones({super.key});

  @override
  State<PantallaMisPostulaciones> createState() =>
      _PantallaMisPostulacionesState();
}

class _PantallaMisPostulacionesState extends State<PantallaMisPostulaciones>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Streams creados en initState (no en build) para no reabrir la consulta.
  late Stream<List<Postulacion>> _streamActivas;
  late Stream<List<Postulacion>> _streamHistorial;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _suscribir();
  }

  /// Abre las consultas en vivo. Solo se llama al iniciar o al reintentar un error.
  void _suscribir() {
    final uid = Servicios.auth.usuarioActual?.uid ?? '';
    _streamActivas = Servicios.postulaciones.escucharMisPostulaciones(uid);
    _streamHistorial = Servicios.postulaciones.escucharHistorial(uid);
  }

  void _reintentar() {
    setState(_suscribir);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Navega al detalle de la convocatoria y recarga al volver.
  Future<void> _irADetalle(String edicionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaDetalleConvocatoria(edicionId: edicionId),
      ),
    );
    // El Stream actualiza solo; no hace falta recargar a mano.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera con el título de la pantalla
          const CabeceraPantalla(titulo: 'Postulaciones'),

          // TabBar debajo de la cabecera
          _buildTabBar(),

          // Contenido expandido para que el TabBarView ocupe el espacio restante
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 0: Activas
                _PestaniaLista(
                  stream: _streamActivas,
                  esHistorial: false,
                  mensajeVacio: 'Aún no te has postulado',
                  iconoVacio: Icons.assignment_outlined,
                  onReintentar: _reintentar,
                  onTapTarjeta: _irADetalle,
                  onVerConstancia: (p) => mostrarConstancia(context, p),
                ),
                // Pestaña 1: Historial
                _PestaniaLista(
                  stream: _streamHistorial,
                  esHistorial: true,
                  mensajeVacio: 'Aquí aparecerán los eventos a los que asististe',
                  iconoVacio: Icons.history_rounded,
                  onReintentar: _reintentar,
                  onTapTarjeta: _irADetalle,
                  onVerConstancia: (p) => mostrarConstancia(context, p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el TabBar con indicador de píldora usando primaryContainer (#EEF3DC).
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
        // Indicador tipo píldora: verde solo como relleno estructural, nunca como texto
        indicator: BoxDecoration(
          color: AppColors.primaryContainer, // #EEF3DC
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
          Tab(text: 'Historial'),
        ],
      ),
    );
  }
}

// ─── Pestaña genérica para Activas e Historial ─────────────────────────────

/// Widget de pestaña que maneja el ciclo loading/vacío/error/datos.
class _PestaniaLista extends StatelessWidget {
  final Stream<List<Postulacion>> stream;
  final bool esHistorial;
  final String mensajeVacio;
  final IconData iconoVacio;
  final VoidCallback onReintentar;
  final Future<void> Function(String edicionId) onTapTarjeta;
  final void Function(Postulacion) onVerConstancia;

  const _PestaniaLista({
    required this.stream,
    required this.esHistorial,
    required this.mensajeVacio,
    required this.iconoVacio,
    required this.onReintentar,
    required this.onTapTarjeta,
    required this.onVerConstancia,
  });

  @override
  Widget build(BuildContext context) {
    final columnas = Responsive.columnasGrilla(context);
    final gutter = Responsive.gutter(context);
    final margen = Responsive.margenHorizontal(context);

    return RefreshIndicator(
      color: AppColors.primary,
      // El listado llega por snapshots(); el indicador solo espera el frame actual.
      onRefresh: () async {},
      child: StreamBuilder<List<Postulacion>>(
        stream: stream,
        builder: (context, snapshot) {
          // Estado: cargando
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(64),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          // Estado: error (visualmente distinto del vacío)
          if (snapshot.hasError) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícono de error en color rojo, distinto al ícono vacío en gris
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ocurrió un error al cargar.',
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
                        onPressed: onReintentar,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final lista = snapshot.data ?? [];

          // Estado: vacío
          if (lista.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconoVacio, size: 48, color: AppColors.textoSecundario),
                      const SizedBox(height: 16),
                      Text(
                        mensajeVacio,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

          // Espacio extra al final para que la última tarjeta no quede pegada a la barra.
          final paddingInferior = 32.0 + MediaQuery.paddingOf(context).bottom;
          final esCompacto = Responsive.tamano(context) == TamanoPantalla.compacto;

          Widget tarjeta(int index) {
            final p = lista[index];
            return PostulacionCard(
              postulacion: p,
              esHistorial: esHistorial,
              onTap: () => onTapTarjeta(p.edicionId),
              onVerConstancia: esHistorial ? () => onVerConstancia(p) : null,
            );
          }

          // Compacto: lista de altura natural. Medio/amplio: grilla con altura fija.
          final listado = esCompacto
              ? ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => SizedBox(height: gutter),
                  itemBuilder: (context, index) => tarjeta(index),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lista.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnas,
                    crossAxisSpacing: gutter,
                    mainAxisSpacing: gutter,
                    mainAxisExtent: esHistorial ? 240 : 220,
                  ),
                  itemBuilder: (context, index) => tarjeta(index),
                );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(margen, 16, margen, paddingInferior),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: listado,
              ),
            ),
          );
        },
      ),
    );
  }
}
