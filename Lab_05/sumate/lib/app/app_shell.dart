// Shell principal de navegación responsive para Súmate.
// Implementa los 4 destinos definidos una sola vez y se adapta según el ancho:
// - Compacto (<600 px): NavigationBar inferior de 72 px.
// - Medio (600 a 1023 px): NavigationRail compacto (solo íconos).
// - Amplio (>=1024 px): NavigationRail extendido de 240 px con Wordmark superior y borde derecho.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/responsive.dart';
import '../core/servicios.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/wordmark_sumate.dart';
import '../features/eventos/pantallas/pantalla_explorar.dart';
import '../features/eventos/pantallas/pantalla_mis_eventos.dart';
import '../features/perfil/modelos/usuario.dart';
import '../features/perfil/pantallas/pantalla_perfil.dart';
import '../features/postulaciones/pantallas/pantalla_mis_postulaciones.dart';

/// Definición de un destino de navegación del AppShell.
class DestinoNavegacion {
  final String etiqueta;
  final IconData icono;
  final IconData iconoSeleccionado;

  const DestinoNavegacion({
    required this.etiqueta,
    required this.icono,
    required this.iconoSeleccionado,
  });
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indiceSeleccionado = 0;

  // ── Los 4 destinos de la app definidos UNA sola vez ─────────────────────────
  static const List<DestinoNavegacion> _destinos = [
    DestinoNavegacion(
      etiqueta: 'Explorar',
      icono: Icons.explore_outlined,
      iconoSeleccionado: Icons.explore_rounded,
    ),
    DestinoNavegacion(
      etiqueta: 'Postulaciones',
      icono: Icons.assignment_turned_in_outlined,
      iconoSeleccionado: Icons.assignment_turned_in_rounded,
    ),
    DestinoNavegacion(
      etiqueta: 'Mis eventos',
      icono: Icons.event_outlined,
      iconoSeleccionado: Icons.event_rounded,
    ),
    DestinoNavegacion(
      etiqueta: 'Perfil',
      icono: Icons.person_outlined,
      iconoSeleccionado: Icons.person_rounded,
    ),
  ];

  // Pantallas correspondientes a cada índice
  final List<Widget> _pantallas = const [
    PantallaExplorar(),
    PantallaMisPostulaciones(), // RF08 + RF11: Mis Postulaciones e Historial
    PantallaMisEventos(), // RF03 + RF04: Mis Eventos y Publicar Evento
    PantallaPerfil(),
  ];

  void _onCambiarDestino(int index) {
    if (_indiceSeleccionado != index) {
      setState(() => _indiceSeleccionado = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tamano = Responsive.tamanoPorAncho(constraints.maxWidth);

        // ── Vista compacta (< 600 px): Barra inferior ───────────────────────
        if (tamano == TamanoPantalla.compacto) {
          return Scaffold(
            backgroundColor: AppColors.fondo,
            body: IndexedStack(
              index: _indiceSeleccionado,
              children: _pantallas,
            ),
            // SafeArea inferior: la barra no queda bajo la zona de gestos del sistema.
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borde, width: 1.0),
                ),
              ),
              child: SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: _indiceSeleccionado,
                  onDestinationSelected: _onCambiarDestino,
                  destinations: _destinos.map((d) {
                    return NavigationDestination(
                      icon: Icon(d.icono),
                      selectedIcon: Icon(d.iconoSeleccionado),
                      label: d.etiqueta,
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }

        // ── Vista media (600 a 1023 px): Riel compacto (solo íconos) ──────────
        if (tamano == TamanoPantalla.medio) {
          return Scaffold(
            backgroundColor: AppColors.fondo,
            body: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.borde, width: 1.0),
                    ),
                  ),
                  child: NavigationRail(
                    selectedIndex: _indiceSeleccionado,
                    onDestinationSelected: _onCambiarDestino,
                    labelType: NavigationRailLabelType.none,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: WordmarkSumate(fontSize: 20),
                    ),
                    destinations: _destinos.map((d) {
                      return NavigationRailDestination(
                        icon: Icon(d.icono),
                        selectedIcon: Icon(d.iconoSeleccionado),
                        label: Text(d.etiqueta),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _indiceSeleccionado,
                    children: _pantallas,
                  ),
                ),
              ],
            ),
          );
        }

        // ── Vista amplia (>= 1024 px): Riel extendido de 240 px ──────────────
        return Scaffold(
          backgroundColor: AppColors.fondo,
          body: Row(
            children: [
              Container(
                width: 240,
                decoration: const BoxDecoration(
                  color: AppColors.superficie,
                  border: Border(
                    right: BorderSide(color: AppColors.borde, width: 1.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera del riel con el Wordmark "Súmate" y píldora "Arequipa"
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        children: [
                          const WordmarkSumate(fontSize: 24),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              'Arequipa',
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

                    const Divider(height: 1, color: AppColors.borde),
                    const SizedBox(height: 12),

                    // Lista de ítems de navegación vertical
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _destinos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final destino = _destinos[index];
                          final activo = index == _indiceSeleccionado;

                          return Material(
                            color: activo
                                ? AppColors.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onCambiarDestino(index),
                              hoverColor:
                                  AppColors.primaryContainer.withValues(alpha: 0.5),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      activo
                                          ? destino.iconoSeleccionado
                                          : destino.icono,
                                      size: 22,
                                      color: activo
                                          ? AppColors.textoPrincipal
                                          : AppColors.textoSecundario,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        destino.etiqueta,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: activo
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: activo
                                              ? AppColors.textoPrincipal
                                              : AppColors.textoSecundario,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Pie del riel de navegación con información del usuario autenticado
                    StreamBuilder<Usuario?>(
                      stream: Servicios.usuarios.escuchar(Servicios.auth.usuarioActual?.uid ?? ''),
                      builder: (context, snap) {
                        final u = snap.data;
                        final nombre = u?.nombre.isNotEmpty == true ? u!.nombre : 'Usuario';
                        final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : 'U';
                        final subtitulo = u != null && u.carrera.isNotEmpty
                            ? u.carrera
                            : (u?.universidad.isNotEmpty == true ? u!.universidad : 'Estudiante');

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.borde, width: 1.0),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.tertiary,
                                child: Text(
                                  inicial,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textoPrincipal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      nombre,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textoPrincipal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      subtitulo,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.textoSecundario,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Área de contenido principal sobre fondo crema
              Expanded(
                child: IndexedStack(
                  index: _indiceSeleccionado,
                  children: _pantallas,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
