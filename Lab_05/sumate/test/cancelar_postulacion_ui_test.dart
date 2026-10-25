import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumate/core/enums.dart';
import 'package:sumate/core/theme/app_theme.dart';
import 'package:sumate/core/widgets/postulacion_card.dart';
import 'package:sumate/features/postulaciones/modelos/postulacion.dart';

void main() {
  Widget envolver(Widget child) {
    return MaterialApp(
      theme: AppTheme.tema,
      home: Scaffold(body: child),
    );
  }

  final ahora = DateTime.now();

  final postulacionVoluntarioEnEspera = Postulacion(
    id: 'ed1_u1_voluntario',
    edicionId: 'ed1',
    usuarioId: 'u1',
    rol: RolPostulacion.voluntario,
    estado: EstadoPostulacion.enviada,
    asistio: false,
    fecha: ahora.subtract(const Duration(days: 1)),
    perfil: const PerfilPostulante(
      nombre: 'Juan Pérez',
      correo: 'juan@unsa.edu.pe',
    ),
    eventoNombre: 'Hack4Edu',
    edicionNombre: 'Hack4Edu 2026',
    fechaInicio: ahora.add(const Duration(days: 5)),
    lugar: 'UNSA Pabellón de Sistemas',
  );

  final postulacionVoluntarioAceptado = Postulacion(
    id: 'ed1_u2_voluntario',
    edicionId: 'ed1',
    usuarioId: 'u2',
    rol: RolPostulacion.voluntario,
    estado: EstadoPostulacion.aceptada,
    asistio: false,
    fecha: ahora.subtract(const Duration(days: 2)),
    perfil: const PerfilPostulante(
      nombre: 'María Gómez',
      correo: 'maria@unsa.edu.pe',
    ),
    eventoNombre: 'Hack4Edu',
    edicionNombre: 'Hack4Edu 2026',
    fechaInicio: ahora.add(const Duration(days: 5)),
    lugar: 'UNSA Pabellón de Sistemas',
  );

  final postulacionAsistenteFuturo = Postulacion(
    id: 'ed1_u3_asistente',
    edicionId: 'ed1',
    usuarioId: 'u3',
    rol: RolPostulacion.asistente,
    estado: EstadoPostulacion.aceptada,
    asistio: false,
    fecha: ahora.subtract(const Duration(days: 1)),
    perfil: const PerfilPostulante(
      nombre: 'Carlos Ruiz',
      correo: 'carlos@unsa.edu.pe',
    ),
    eventoNombre: 'Hack4Edu',
    edicionNombre: 'Hack4Edu 2026',
    fechaInicio: ahora.add(const Duration(days: 5)),
    lugar: 'UNSA Pabellón de Sistemas',
  );

  group('PostulacionCard (Pantalla Mis Postulaciones)', () {
    testWidgets('Quitar botón Cancelar postulación de PostulacionCard en Activas', (tester) async {
      await tester.pumpWidget(
        envolver(
          PostulacionCard(
            postulacion: postulacionVoluntarioEnEspera,
            esHistorial: false,
            onTap: () {},
          ),
        ),
      );

      // Debe mostrar el estado, rol, fecha y lugar
      expect(find.text('En espera'), findsOneWidget);
      expect(find.text('Voluntario'), findsOneWidget);
      expect(find.text('Hack4Edu 2026'), findsOneWidget);
      expect(find.text('UNSA Pabellón de Sistemas'), findsOneWidget);

      // NO debe tener el botón "Cancelar postulación"
      expect(find.text('Cancelar postulación'), findsNothing);
    });

    testWidgets('PostulacionCard para voluntario aceptado tampoco tiene botón cancelar', (tester) async {
      await tester.pumpWidget(
        envolver(
          PostulacionCard(
            postulacion: postulacionVoluntarioAceptado,
            esHistorial: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Aceptada'), findsOneWidget);
      expect(find.text('Cancelar postulación'), findsNothing);
    });

    testWidgets('PostulacionCard para asistente no muestra botón cancelar en Mis Postulaciones', (tester) async {
      await tester.pumpWidget(
        envolver(
          PostulacionCard(
            postulacion: postulacionAsistenteFuturo,
            esHistorial: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Aceptada'), findsOneWidget);
      expect(find.text('Asistente'), findsOneWidget);
      expect(find.text('Cancelar postulación'), findsNothing);
    });
  });

  group('Reglas de visibilidad de Cancelar postulación en Detalle', () {
    // Función auxiliar que replica la lógica de _puedeCancelar de PantallaDetalleConvocatoria
    bool puedeCancelar(Postulacion postulacion, DateTime fechaInicioEdicion) {
      if (postulacion.asistio) return false;
      if (postulacion.rol == RolPostulacion.voluntario) {
        return postulacion.estado == EstadoPostulacion.enviada;
      }
      return DateTime.now().isBefore(fechaInicioEdicion);
    }

    test('(a) voluntario En espera ve el botón en detalle', () {
      final fechaInicio = ahora.add(const Duration(days: 3));
      expect(puedeCancelar(postulacionVoluntarioEnEspera, fechaInicio), isTrue);
    });

    test('(b) voluntario aceptado NO ve el botón en detalle', () {
      final fechaInicio = ahora.add(const Duration(days: 3));
      expect(puedeCancelar(postulacionVoluntarioAceptado, fechaInicio), isFalse);

      final voluntarioRechazado = Postulacion(
        id: 'ed1_u1_vol_rechazado',
        edicionId: 'ed1',
        usuarioId: 'u1',
        rol: RolPostulacion.voluntario,
        estado: EstadoPostulacion.rechazada,
        asistio: false,
        fecha: ahora.subtract(const Duration(days: 1)),
        perfil: const PerfilPostulante(
          nombre: 'Juan Pérez',
          correo: 'juan@unsa.edu.pe',
        ),
        eventoNombre: 'Hack4Edu',
        edicionNombre: 'Hack4Edu 2026',
        fechaInicio: ahora.add(const Duration(days: 5)),
        lugar: 'UNSA Pabellón de Sistemas',
      );
      expect(puedeCancelar(voluntarioRechazado, fechaInicio), isFalse);
    });

    test('(c) asistente inscrito antes de fechaInicio ve el botón en detalle', () {
      final fechaInicioFutura = ahora.add(const Duration(days: 2));
      expect(puedeCancelar(postulacionAsistenteFuturo, fechaInicioFutura), isTrue);
    });

    test('(d) asistente en edición ya iniciada NO ve el botón en detalle', () {
      final fechaInicioPasada = ahora.subtract(const Duration(hours: 1));
      expect(puedeCancelar(postulacionAsistenteFuturo, fechaInicioPasada), isFalse);
    });
  });
}
