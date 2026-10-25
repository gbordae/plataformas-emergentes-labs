// Pantalla de exploración de convocatorias abiertas (RF05).
// Permite filtrar por tipo, modalidad, universidad y fecha desde.
// Se adapta responsivamente a móvil (compacto con modal bottom sheet)
// y desktop/tablet (medio y amplio con chips visibles).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/enums.dart';
import '../../../core/formato.dart';
import '../../../core/responsive.dart';
import '../../../core/servicios.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cabecera_pantalla.dart';
import '../../../core/widgets/evento_card.dart';
import '../../../core/widgets/filtro_chip.dart';
import '../modelos/edicion.dart';
import 'pantalla_detalle_convocatoria.dart';

class PantallaExplorar extends StatefulWidget {
  const PantallaExplorar({super.key});

  @override
  State<PantallaExplorar> createState() => _PantallaExplorarState();
}

class _PantallaExplorarState extends State<PantallaExplorar> {
  // Filtros de búsqueda
  TipoEvento? _tipoSeleccionado;
  Modalidad? _modalidadSeleccionada;
  String? _universidadSeleccionada;
  DateTime? _fechaDesde;

  late Future<List<Edicion>> _futureEdiciones;

  // Universidades disponibles según especificación
  static const List<String> _universidades = ['UNSA', 'UCSM', 'UCSP'];

  @override
  void initState() {
    super.initState();
    _cargarEdiciones();
  }

  void _cargarEdiciones() {
    _futureEdiciones = Servicios.edicion.listarAbiertas(
      tipo: _tipoSeleccionado,
      universidad: _universidadSeleccionada,
      modalidad: _modalidadSeleccionada,
      fechaDesde: _fechaDesde,
    );
  }

  void _recargar() {
    setState(() {
      _cargarEdiciones();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _tipoSeleccionado = null;
      _modalidadSeleccionada = null;
      _universidadSeleccionada = null;
      _fechaDesde = null;
      _cargarEdiciones();
    });
  }

  bool get _hayFiltrosActivos =>
      _tipoSeleccionado != null ||
      _modalidadSeleccionada != null ||
      _universidadSeleccionada != null ||
      _fechaDesde != null;

  int get _cantidadFiltrosActivos {
    var c = 0;
    if (_tipoSeleccionado != null) c++;
    if (_modalidadSeleccionada != null) c++;
    if (_universidadSeleccionada != null) c++;
    if (_fechaDesde != null) c++;
    return c;
  }

  Future<void> _seleccionarFechaDesde(BuildContext context) async {
    final inicial = _fechaDesde ?? DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: 'Selecciona fecha desde',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );

    if (seleccionada != null) {
      setState(() {
        _fechaDesde = seleccionada;
        _cargarEdiciones();
      });
    }
  }

  // Abre el modal bottom sheet para pantallas compactas
  void _mostrarModalFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera del modal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtros de búsqueda',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                          if (_hayFiltrosActivos)
                            TextButton(
                              onPressed: () {
                                _limpiarFiltros();
                                setModalState(() {});
                                Navigator.of(ctx).pop();
                              },
                              child: Text(
                                'Limpiar todo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filtro Tipo de evento
                      Text(
                        'Tipo de evento',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FiltroChip(
                            label: 'Todos',
                            seleccionado: _tipoSeleccionado == null,
                            onSelected: (_) {
                              setModalState(() => _tipoSeleccionado = null);
                              _recargar();
                            },
                          ),
                          ...TipoEvento.values.map((t) {
                            return FiltroChip(
                              label: t.etiqueta,
                              seleccionado: _tipoSeleccionado == t,
                              onSelected: (val) {
                                setModalState(() => _tipoSeleccionado = val ? t : null);
                                _recargar();
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Filtro Modalidad
                      Text(
                        'Modalidad',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FiltroChip(
                            label: 'Todas',
                            seleccionado: _modalidadSeleccionada == null,
                            onSelected: (_) {
                              setModalState(() => _modalidadSeleccionada = null);
                              _recargar();
                            },
                          ),
                          ...Modalidad.values.map((m) {
                            return FiltroChip(
                              label: m.etiqueta,
                              seleccionado: _modalidadSeleccionada == m,
                              onSelected: (val) {
                                setModalState(() => _modalidadSeleccionada = val ? m : null);
                                _recargar();
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Filtro Universidad
                      Text(
                        'Universidad',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FiltroChip(
                            label: 'Todas',
                            seleccionado: _universidadSeleccionada == null,
                            onSelected: (_) {
                              setModalState(() => _universidadSeleccionada = null);
                              _recargar();
                            },
                          ),
                          ..._universidades.map((u) {
                            return FiltroChip(
                              label: u,
                              seleccionado: _universidadSeleccionada == u,
                              onSelected: (val) {
                                setModalState(() => _universidadSeleccionada = val ? u : null);
                                _recargar();
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Filtro Fecha Desde
                      Text(
                        'Fecha de inicio',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final inicial = _fechaDesde ?? DateTime.now();
                              final s = await showDatePicker(
                                context: modalContext,
                                initialDate: inicial,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (s != null) {
                                setModalState(() => _fechaDesde = s);
                                _recargar();
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text(
                              _fechaDesde == null
                                  ? 'Desde: Cualquier fecha'
                                  : 'Desde: ${fechaCorta(_fechaDesde!)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textoPrincipal,
                              side: const BorderSide(color: AppColors.borde),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_fechaDesde != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setModalState(() => _fechaDesde = null);
                                _recargar();
                              },
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              tooltip: 'Limpiar fecha',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botón Listo
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.textoPrincipal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Ver resultados',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget para el pie de cada tarjeta de evento
  Widget _construirPieTarjeta(Edicion edicion) {
    final admiteVol = edicion.admitePostulaciones(RolPostulacion.voluntario);
    final admiteAsi = edicion.admitePostulaciones(RolPostulacion.asistente);

    // Si ninguna convocatoria admite postulaciones
    if (!admiteVol && !admiteAsi) {
      final volAgotado = edicion.voluntarios.abierta && !edicion.voluntarios.hayCupo;
      final asiAgotado = edicion.asistentes.abierta && !edicion.asistentes.hayCupo;
      final textoEstado = (volAgotado || asiAgotado) ? 'Cupos agotados' : 'Cerrada';

      return Text(
        textoEstado,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.error,
        ),
      );
    }

    // Calcular cupos restantes acumulados
    var cuposDisponibles = 0;
    if (admiteVol) {
      cuposDisponibles += (edicion.voluntarios.cupos - edicion.voluntarios.ocupados);
    }
    if (admiteAsi) {
      cuposDisponibles += (edicion.asistentes.cupos - edicion.asistentes.ocupados);
    }

    final textoCupo = cuposDisponibles == 1
        ? '1 cupo disponible'
        : '$cuposDisponibles cupos disponibles';

    // Fecha límite más próxima de las convocatorias abiertas
    DateTime? fechaLimiteProxima;
    if (admiteVol && edicion.voluntarios.fechaLimite != null) {
      fechaLimiteProxima = edicion.voluntarios.fechaLimite;
    }
    if (admiteAsi && edicion.asistentes.fechaLimite != null) {
      if (fechaLimiteProxima == null ||
          edicion.asistentes.fechaLimite!.isBefore(fechaLimiteProxima)) {
        fechaLimiteProxima = edicion.asistentes.fechaLimite;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            textoCupo,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textoSecundario,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (fechaLimiteProxima != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              textoFechaLimite(fechaLimiteProxima),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textoSecundario,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }

  // Fila de filtros para pantallas medianas y amplias
  Widget _construirFiltrosMedioYAmplio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Tipos de evento
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FiltroChip(
              label: 'Todos',
              seleccionado: _tipoSeleccionado == null,
              onSelected: (_) {
                setState(() {
                  _tipoSeleccionado = null;
                  _cargarEdiciones();
                });
              },
            ),
            ...TipoEvento.values.map((t) {
              return FiltroChip(
                label: t.etiqueta,
                seleccionado: _tipoSeleccionado == t,
                onSelected: (val) {
                  setState(() {
                    _tipoSeleccionado = val ? t : null;
                    _cargarEdiciones();
                  });
                },
              );
            }),
          ],
        ),
        const SizedBox(height: 12),

        // Fila 2: Modalidad, Universidad y Fecha
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Modalidades
            FiltroChip(
              label: 'Todas las modalidades',
              seleccionado: _modalidadSeleccionada == null,
              onSelected: (_) {
                setState(() {
                  _modalidadSeleccionada = null;
                  _cargarEdiciones();
                });
              },
            ),
            ...Modalidad.values.map((m) {
              return FiltroChip(
                label: m.etiqueta,
                seleccionado: _modalidadSeleccionada == m,
                onSelected: (val) {
                  setState(() {
                    _modalidadSeleccionada = val ? m : null;
                    _cargarEdiciones();
                  });
                },
              );
            }),

            const SizedBox(width: 8),

            // Universidades
            FiltroChip(
              label: 'Todas las universidades',
              seleccionado: _universidadSeleccionada == null,
              onSelected: (_) {
                setState(() {
                  _universidadSeleccionada = null;
                  _cargarEdiciones();
                });
              },
            ),
            ..._universidades.map((u) {
              return FiltroChip(
                label: u,
                seleccionado: _universidadSeleccionada == u,
                onSelected: (val) {
                  setState(() {
                    _universidadSeleccionada = val ? u : null;
                    _cargarEdiciones();
                  });
                },
              );
            }),

            const SizedBox(width: 8),

            // Selector Fecha Desde
            ActionChip(
              avatar: const Icon(Icons.calendar_today_rounded, size: 14),
              label: Text(
                _fechaDesde == null
                    ? 'Desde'
                    : 'Desde: ${fechaCorta(_fechaDesde!)}',
              ),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: _fechaDesde != null ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textoPrincipal,
              ),
              backgroundColor: _fechaDesde != null
                  ? AppColors.primaryContainer
                  : AppColors.superficie,
              shape: StadiumBorder(
                side: BorderSide(
                  color: _fechaDesde != null ? AppColors.primary : AppColors.borde,
                ),
              ),
              onPressed: () => _seleccionarFechaDesde(context),
            ),

            if (_fechaDesde != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.clear_rounded, size: 18),
                tooltip: 'Limpiar fecha',
                onPressed: () {
                  setState(() {
                    _fechaDesde = null;
                    _cargarEdiciones();
                  });
                },
              ),

            // Botón Limpiar filtros cuando hay filtros aplicados
            if (_hayFiltrosActivos)
              TextButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textoSecundario,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tamano = Responsive.tamano(context);
    final esCompacto = tamano == TamanoPantalla.compacto;
    final columnas = Responsive.columnasGrilla(context);
    final gutter = Responsive.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _recargar();
          await _futureEdiciones;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera principal
              const CabeceraPantalla(
                titulo: 'Explorar',
                subtitulo: 'Encuentra oportunidades de voluntariado y asistencia en Arequipa',
              ),

              const SizedBox(height: 16),

              // Contenedor centrado para controles y contenido
              ContenidoCentrado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros según tamaño de pantalla
                    if (esCompacto) ...[
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _mostrarModalFiltros(context),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: Text(
                              _hayFiltrosActivos
                                  ? 'Filtros ($_cantidadFiltrosActivos)'
                                  : 'Filtros',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              backgroundColor: _hayFiltrosActivos
                                  ? AppColors.primaryContainer
                                  : AppColors.superficie,
                              foregroundColor: AppColors.textoPrincipal,
                              side: BorderSide(
                                color: _hayFiltrosActivos
                                    ? AppColors.primary
                                    : AppColors.borde,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_hayFiltrosActivos) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _limpiarFiltros,
                              child: Text(
                                'Limpiar',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      _construirFiltrosMedioYAmplio(),
                    ],

                    const SizedBox(height: 24),

                    // Lista de convocatorias con FutureBuilder
                    FutureBuilder<List<Edicion>>(
                      future: _futureEdiciones,
                      builder: (context, snapshot) {
                        // Estado: Cargando
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 64),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }

                        // Estado: Error
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 48,
                                horizontal: 24,
                              ),
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
                                    'Ocurrió un error al cargar las convocatorias.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textoPrincipal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _recargar,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Reintentar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: AppColors.textoPrincipal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Filtrar finalizadas efectivas y ordenar por fechaInicio ascendente
                        final ediciones = (snapshot.data ?? [])
                            .where((e) => !e.finalizadaEfectiva)
                            .toList();
                        ediciones.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

                        // Estado: Vacío
                        if (ediciones.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 48,
                                horizontal: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.textoSecundario,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay convocatorias con esos filtros',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textoPrincipal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _limpiarFiltros,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: AppColors.textoPrincipal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Limpiar filtros'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Compacto: lista de altura natural (sin hueco por mainAxisExtent).
                        // Medio/amplio: grilla con altura fija.
                        Widget tarjeta(Edicion edicion) {
                          return EventoCard(
                            categoria: edicion.tipo.etiqueta,
                            titulo: edicion.nombre,
                            fecha: fechaCorta(edicion.fechaInicio),
                            lugar: edicion.lugar.isNotEmpty
                                ? edicion.lugar
                                : edicion.modalidad.etiqueta,
                            organizador: edicion.eventoNombre,
                            pie: _construirPieTarjeta(edicion),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PantallaDetalleConvocatoria(
                                    edicionId: edicion.id,
                                  ),
                                ),
                              );
                              _recargar();
                            },
                          );
                        }

                        if (esCompacto) {
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ediciones.length,
                            separatorBuilder: (_, _) => SizedBox(height: gutter),
                            itemBuilder: (context, index) =>
                                tarjeta(ediciones[index]),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ediciones.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnas,
                            crossAxisSpacing: gutter,
                            mainAxisSpacing: gutter,
                            mainAxisExtent: 260,
                          ),
                          itemBuilder: (context, index) =>
                              tarjeta(ediciones[index]),
                        );
                      },
                    ),

                    // Espacio final para que la última tarjeta no quede pegada a la barra.
                    SizedBox(height: 32 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
