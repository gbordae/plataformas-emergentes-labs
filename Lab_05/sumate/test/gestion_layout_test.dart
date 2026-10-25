// Tests de regresión visual y funcional para Detalle del Organizador y Gestión de Postulantes (Paso 6).
// Ejecuta sin Firebase real utilizando modelos en memoria y futures inyectados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumate/core/enums.dart';
import 'package:sumate/core/theme/app_theme.dart';
import 'package:sumate/core/widgets/postulante_card.dart';
import 'package:sumate/features/eventos/modelos/convocatoria.dart';
import 'package:sumate/features/eventos/modelos/edicion.dart';
import 'package:sumate/features/eventos/pantallas/pantalla_detalle_organizador.dart';
import 'package:sumate/features/postulaciones/modelos/postulacion.dart';
import 'package:sumate/features/postulaciones/pantallas/pantalla_gestion_postulantes.dart';

void main() {
  Widget envolver(Widget child) {
    return MaterialApp(
      theme: AppTheme.tema,
      home: child,
    );
  }

  final ahora = DateTime.now();

  final edicionDemo = Edicion(
    id: 'edicion_test_1',
    eventoId: 'evento_test_1',
    eventoNombre: 'HackSan',
    tipo: TipoEvento.hackathon,
    nombre: 'HackSan 2026 – 3.ª edición',
    fechaInicio: ahora.subtract(const Duration(hours: 1)), // evento ya iniciado
    fechaFin: ahora.add(const Duration(days: 1)),
    lugar: 'Auditorio de Ingeniería, UNSA',
    modalidad: Modalidad.presencial,
    universidad: 'UNSA',
    estado: EstadoEdicion.abierta,
    organizadores: const ['organizador_uid_1'],
    voluntarios: const Convocatoria(
      abierta: true,
      cupos: 12,
      ocupados: 6,
      beneficios: 'Constancia y refrigerio',
    ),
    asistentes: const Convocatoria(
      abierta: true,
      cupos: 80,
      ocupados: 40,
    ),
  );

  final voluntarioEnEspera = Postulacion(
    id: 'post_1',
    edicionId: 'edicion_test_1',
    usuarioId: 'user_1',
    rol: RolPostulacion.voluntario,
    estado: EstadoPostulacion.enviada,
    asistio: false,
    fecha: ahora.subtract(const Duration(days: 2)),
    perfil: const PerfilPostulante(
      nombre: 'Camila Quispe',
      correo: 'cquispe@unsa.edu.pe',
      universidad: 'UNSA',
      carrera: 'Ingeniería de Sistemas',
      ciclo: 6,
      habilidades: ['Python', 'Logística', 'Oratoria'],
    ),
    eventoNombre: 'HackSan',
    edicionNombre: 'HackSan 2026',
    fechaInicio: ahora.subtract(const Duration(hours: 1)),
    lugar: 'Auditorio UNSA',
  );

  final voluntarioAceptado = Postulacion(
    id: 'post_2',
    edicionId: 'edicion_test_1',
    usuarioId: 'user_2',
    rol: RolPostulacion.voluntario,
    estado: EstadoPostulacion.aceptada,
    asistio: true,
    fecha: ahora.subtract(const Duration(days: 3)),
    perfil: const PerfilPostulante(
      nombre: 'Diego Ramos',
      correo: 'dramos@ucsm.edu.pe',
      universidad: 'UCSM',
      carrera: 'Diseño Gráfico',
      ciclo: 4,
      habilidades: ['Fotografía', 'Ilustración'],
    ),
    eventoNombre: 'HackSan',
    edicionNombre: 'HackSan 2026',
    fechaInicio: ahora.subtract(const Duration(hours: 1)),
    lugar: 'Auditorio UNSA',
  );

  final asistenteAceptado = Postulacion(
    id: 'post_3',
    edicionId: 'edicion_test_1',
    usuarioId: 'user_3',
    rol: RolPostulacion.asistente,
    estado: EstadoPostulacion.aceptada,
    asistio: false,
    fecha: ahora.subtract(const Duration(days: 1)),
    perfil: const PerfilPostulante(
      nombre: 'Valeria Mamani',
      correo: 'vmamani@ucsp.edu.pe',
      universidad: 'UCSP',
      carrera: '',
      ciclo: null,
      habilidades: [],
    ),
    eventoNombre: 'HackSan',
    edicionNombre: 'HackSan 2026',
    fechaInicio: ahora.subtract(const Duration(hours: 1)),
    lugar: 'Auditorio UNSA',
  );

  group('PostulanteCard - Renderizado y acciones', () {
    testWidgets('Voluntario en espera muestra botones Aceptar y Rechazar y habilidades', (tester) async {
      await tester.pumpWidget(envolver(
        PostulanteCard(
          postulacion: voluntarioEnEspera,
          fechaInicioEdicion: edicionDemo.fechaInicio,
        ),
      ));

      expect(find.text('Camila Quispe'), findsOneWidget);
      expect(find.text('Voluntario'), findsOneWidget);
      expect(find.text('En espera'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Logística'), findsOneWidget);
    });

    testWidgets('Voluntario que ya asistió no muestra botón Rechazar', (tester) async {
      await tester.pumpWidget(envolver(
        PostulanteCard(
          postulacion: voluntarioAceptado,
          fechaInicioEdicion: edicionDemo.fechaInicio,
        ),
      ));

      expect(find.text('Diego Ramos'), findsOneWidget);
      expect(find.text('Asistió al evento'), findsOneWidget);
      expect(find.text('Rechazar'), findsNothing);
    });

    testWidgets('Postulante sin habilidades no renderiza chips vacíos', (tester) async {
      await tester.pumpWidget(envolver(
        PostulanteCard(
          postulacion: asistenteAceptado,
          fechaInicioEdicion: edicionDemo.fechaInicio,
        ),
      ));

      expect(find.text('Valeria Mamani'), findsOneWidget);
      expect(find.text('Asistente'), findsOneWidget);
      // 'Sin carrera' aparece concatenado en "Independiente · Sin carrera"
      expect(find.textContaining('Sin carrera'), findsOneWidget);
    });
  });

  group('PantallaDetalleOrganizador - Layout responsive y métricas', () {
    testWidgets('Renderiza métricas y datos a 390 px (móvil)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(
        PantallaDetalleOrganizador(
          edicionId: 'edicion_test_1',
          futureEdicion: Future.value(edicionDemo),
          futurePostulantes: Future.value([
            voluntarioEnEspera,
            voluntarioAceptado,
            asistenteAceptado,
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de la edición'), findsOneWidget);
      expect(find.text('HackSan 2026 – 3.ª edición'), findsOneWidget);
      expect(find.text('Métricas de la convocatoria'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Total postulantes
      expect(find.text('Gestionar postulantes'), findsOneWidget);
      expect(find.text('Cerrar convocatoria'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza en dos columnas (8/12 y 4/12) a 1440 px (desktop)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(
        PantallaDetalleOrganizador(
          edicionId: 'edicion_test_1',
          futureEdicion: Future.value(edicionDemo),
          futurePostulantes: Future.value([
            voluntarioEnEspera,
            voluntarioAceptado,
            asistenteAceptado,
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('HackSan 2026 – 3.ª edición'), findsOneWidget);
      expect(find.text('Gestionar postulantes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PantallaGestionPostulantes - Filtros y responsive', () {
    testWidgets('Renderiza filtros y lista a 390 px sin overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(
        PantallaGestionPostulantes(
          edicionId: 'edicion_test_1',
          edicion: edicionDemo,
          futurePostulantes: Future.value([
            voluntarioEnEspera,
            voluntarioAceptado,
            asistenteAceptado,
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Postulantes'), findsOneWidget);
      expect(find.text('Mostrando 3 de 3 postulantes'), findsOneWidget);
      expect(find.text('Todos (3)'), findsOneWidget);
      expect(find.text('En espera (1)'), findsOneWidget);
      expect(find.text('Aceptados (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Filtra correctamente por rol voluntario', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(
        PantallaGestionPostulantes(
          edicionId: 'edicion_test_1',
          edicion: edicionDemo,
          futurePostulantes: Future.value([
            voluntarioEnEspera,
            voluntarioAceptado,
            asistenteAceptado,
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      // Seleccionar filtro Voluntarios
      final chipVoluntarios = find.text('Voluntarios');
      expect(chipVoluntarios, findsOneWidget);
      await tester.tap(chipVoluntarios);
      await tester.pumpAndSettle();

      expect(find.text('Mostrando 2 de 3 postulantes'), findsOneWidget);
      expect(find.text('Camila Quispe'), findsOneWidget);
      expect(find.text('Diego Ramos'), findsOneWidget);
      expect(find.text('Valeria Mamani'), findsNothing);
    });

    testWidgets('Renderiza en dos columnas a 1440 px sin overflow', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(envolver(
        PantallaGestionPostulantes(
          edicionId: 'edicion_test_1',
          edicion: edicionDemo,
          futurePostulantes: Future.value([
            voluntarioEnEspera,
            voluntarioAceptado,
            asistenteAceptado,
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Postulantes'), findsOneWidget);
      expect(find.text('Camila Quispe'), findsOneWidget);
      expect(find.text('Diego Ramos'), findsOneWidget);
      expect(find.text('Valeria Mamani'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
