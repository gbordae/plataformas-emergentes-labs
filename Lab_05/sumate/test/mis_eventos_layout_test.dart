// Tests de layout y validaciones para Mis Eventos y Publicar Evento (Paso 5).
// Verifica ausencia de overflows en 390, 800 y 1440 px, y valida reglas de publicación.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumate/core/theme/app_theme.dart';
import 'package:sumate/features/eventos/pantallas/pantalla_detalle_organizador.dart';
import 'package:sumate/features/eventos/pantallas/pantalla_publicar_evento.dart';

void main() {
  Widget envolver(Widget child) {
    return MaterialApp(
      theme: AppTheme.tema,
      home: child,
    );
  }

  group('Layout tests para PantallaPublicarEvento en distintos breakpoints', () {
    testWidgets('Publicar evento a 390 px (móvil compacto) no desborda', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(const PantallaPublicarEvento()));
      await tester.pump();

      expect(find.text('Publicar evento'), findsWidgets);
      expect(find.text('Datos generales del evento'), findsOneWidget);
      expect(find.text('Primera edición'), findsOneWidget);
      expect(find.text('Buscar voluntarios'), findsOneWidget);
      expect(find.text('Recibir asistentes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Publicar evento a 800 px (tablet / medio) se renderiza correctamente', (tester) async {
      tester.view.physicalSize = const Size(800, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(const PantallaPublicarEvento()));
      await tester.pump();

      expect(find.text('Publicar evento'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Publicar evento a 1440 px (desktop amplio) se renderiza centrado', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(const PantallaPublicarEvento()));
      await tester.pump();

      expect(find.text('Publicar evento'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Validaciones de formulario en PantallaPublicarEvento', () {
    testWidgets('Intento de publicar con campos vacíos activa mensajes de validación', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(const PantallaPublicarEvento()));
      await tester.pump();

      // Tocar botón Publicar evento
      final botonPublicar = find.widgetWithText(ElevatedButton, 'Publicar evento');
      expect(botonPublicar, findsOneWidget);
      await tester.ensureVisible(botonPublicar);
      await tester.tap(botonPublicar);
      await tester.pumpAndSettle();

      // Debe mostrar errores de campos obligatorios
      expect(find.text('Ingresa el nombre del evento'), findsOneWidget);
      expect(find.text('Ingresa una descripción del evento'), findsOneWidget);
      expect(find.text('Ingresa la entidad u organización responsable'), findsOneWidget);
    });

    testWidgets('Cupos en 0 muestran error de validación', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(const PantallaPublicarEvento()));
      await tester.pump();

      // Llenar cupos con 0
      final campoCuposVoluntarios = find.widgetWithText(TextFormField, 'Cupos para voluntarios *');
      if (campoCuposVoluntarios.evaluate().isNotEmpty) {
        await tester.enterText(campoCuposVoluntarios, '0');
      }

      final botonPublicar = find.widgetWithText(ElevatedButton, 'Publicar evento');
      await tester.ensureVisible(botonPublicar);
      await tester.tap(botonPublicar);
      await tester.pumpAndSettle();

      expect(find.text('Los cupos deben ser un número mayor a 0'), findsWidgets);
    });

    testWidgets('Desactivar ambas convocatorias muestra error de validación', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(const PantallaPublicarEvento()));
      await tester.pump();

      // Llenar campos requeridos para que pase la validación básica de campos
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del evento *'), 'Evento Test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Descripción del evento *'), 'Desc test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Entidad organizadora *'), 'Club');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre de la edición *'), 'Edicion Test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Lugar físico o enlace *'), 'Auditorio');

      // Desactivar ambos switches
      final switchVoluntarios = find.widgetWithText(SwitchListTile, 'Buscar voluntarios');
      final switchAsistentes = find.widgetWithText(SwitchListTile, 'Recibir asistentes');

      await tester.ensureVisible(switchVoluntarios);
      await tester.tap(switchVoluntarios);
      await tester.pumpAndSettle();

      await tester.ensureVisible(switchAsistentes);
      await tester.tap(switchAsistentes);
      await tester.pumpAndSettle();

      // Tocar publicar
      final botonPublicar = find.widgetWithText(ElevatedButton, 'Publicar evento');
      await tester.ensureVisible(botonPublicar);
      await tester.tap(botonPublicar);
      await tester.pumpAndSettle();

      expect(
        find.text('Debes activar al menos una convocatoria (voluntarios o asistentes).'),
        findsOneWidget,
      );
    });
  });

  group('Detalle Organizador Placeholder', () {
    testWidgets('Muestra estado de error cuando la edición no existe', (tester) async {
      await tester.pumpWidget(envolver(
        PantallaDetalleOrganizador(
          edicionId: 'edicion_inexistente',
          futureEdicion: Future.value(null),
          futurePostulantes: Future.value([]),
        ),
      ));
      await tester.pumpAndSettle();

      // Con edición null, muestra "Edición no encontrada." con botón Reintentar
      expect(find.text('Edición no encontrada.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
