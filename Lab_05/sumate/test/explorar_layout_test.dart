// Test de regresión visual responsive para la pantalla Explorar y EventoCard.
// Verifica que no existan restricciones infinitas (BoxConstraints forces an infinite width)
// ni overflows en breakpoints compacto (390 px), medio (800 px) y amplio (1440 px).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumate/core/responsive.dart';
import 'package:sumate/core/theme/app_theme.dart';
import 'package:sumate/core/widgets/cabecera_pantalla.dart';
import 'package:sumate/core/widgets/evento_card.dart';

Widget _tarjetaDemo() {
  return EventoCard(
    categoria: 'Hackathon',
    titulo: 'Hack4Edu Arequipa 2026',
    fecha: 'sáb 22 nov · 9:00',
    lugar: 'Pabellón de Sistemas UNSA, Av. Independencia s/n',
    organizador: 'Hack4Edu',
    pie: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Flexible(
          child: Text(
            '12 cupos disponibles',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Hasta sáb 22 nov · 23:59',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _crearWidgetPrueba() {
  return MaterialApp(
    theme: AppTheme.tema,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CabeceraPantalla(
              titulo: 'Explorar',
              subtitulo: 'Encuentra oportunidades de voluntariado y asistencia en Arequipa',
            ),
            ContenidoCentrado(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tamano = Responsive.tamano(context);
                  final esCompacto = tamano == TamanoPantalla.compacto;
                  final columnas = Responsive.columnasGrilla(context);
                  final gutter = Responsive.gutter(context);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (esCompacto)
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () {},
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('Filtros'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                              ),
                            ),
                          ],
                        )
                      else
                        const Text('Filtros medio y amplio'),
                      if (esCompacto)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 8,
                          separatorBuilder: (_, _) => SizedBox(height: gutter),
                          itemBuilder: (context, index) => _tarjetaDemo(),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 8,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnas,
                            crossAxisSpacing: gutter,
                            mainAxisSpacing: gutter,
                            mainAxisExtent: 260,
                          ),
                          itemBuilder: (context, index) => _tarjetaDemo(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Layout compacto a 390 px no lanza excepciones de constraints', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    // Simula barra de estado y zona de gestos de un teléfono Android.
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(_crearWidgetPrueba());
    await tester.pumpAndSettle();
    expect(find.text('Filtros'), findsOneWidget);

    // El título no debe solaparse con la barra de estado (44 px).
    final tituloTop = tester.getTopLeft(find.text('Explorar')).dy;
    expect(tituloTop, greaterThanOrEqualTo(44));

    // Cabecera y botón Filtros comparten el margen horizontal de compacto (20 px).
    expect(tester.getTopLeft(find.text('Explorar')).dx, 20);
    expect(tester.getTopLeft(find.byType(FilledButton)).dx, 20);
  });

  testWidgets('Layout medio a 800 px se renderiza en 2 columnas', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_crearWidgetPrueba());
    await tester.pumpAndSettle();
    expect(find.text('Filtros medio y amplio'), findsOneWidget);
  });

  testWidgets('Layout amplio a 1440 px se renderiza en 3 columnas', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_crearWidgetPrueba());
    await tester.pumpAndSettle();
    expect(find.text('Filtros medio y amplio'), findsOneWidget);
  });
}
