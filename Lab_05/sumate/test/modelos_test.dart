import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sumate/core/enums.dart';
import 'package:sumate/features/eventos/modelos/convocatoria.dart';
import 'package:sumate/features/eventos/modelos/edicion.dart';
import 'package:sumate/features/postulaciones/modelos/postulacion.dart';

/// Tests de los modelos de datos (sin Firebase real).
///
/// Verifican que la serialización/deserialización funciona correctamente
/// y que la lógica de negocio (cupos, fechas, ids) se comporta como se espera.
void main() {
  // ── (a) Edicion toMap → fromMap conserva datos ──────────────────────────
  group('Edicion toMap → fromMap', () {
    test('conserva todos los campos y usa Timestamp para fechas', () {
      final edicion = Edicion(
        id: 'ed1',
        eventoId: 'ev1',
        eventoNombre: 'Hack4Edu',
        tipo: TipoEvento.hackathon,
        nombre: 'Hack4Edu 2026',
        fechaInicio: DateTime(2026, 11, 15, 9, 0),
        fechaFin: DateTime(2026, 11, 16, 18, 0),
        lugar: 'UNSA Campus',
        modalidad: Modalidad.hibrido,
        universidad: 'UNSA',
        estado: EstadoEdicion.abierta,
        organizadores: ['org1', 'org2'],
        voluntarios: const Convocatoria(
          abierta: true,
          cupos: 10,
          ocupados: 3,
          beneficios: 'Certificado y almuerzo',
        ),
        asistentes: const Convocatoria(
          abierta: true,
          cupos: 50,
        ),
      );

      final map = edicion.toMap();

      // La modalidad se guarda como 'hibrido' (sin tilde, name del enum)
      expect(map['modalidad'], 'hibrido');

      // Las fechas se guardan como Timestamp de Firestore
      expect(map['fechaInicio'], isA<Timestamp>());
      expect(map['fechaFin'], isA<Timestamp>());

      // Asistentes no tiene beneficios (es null por defecto)
      final asistentesMap = map['asistentes'] as Map<String, dynamic>;
      expect(asistentesMap.containsKey('beneficios'), false);

      // Reconstruir desde el Map y verificar que se conservan los datos
      final reconstruida = Edicion.fromMap(map, id: 'ed1');
      expect(reconstruida.id, 'ed1');
      expect(reconstruida.eventoNombre, 'Hack4Edu');
      expect(reconstruida.modalidad, Modalidad.hibrido);
      expect(reconstruida.fechaInicio, DateTime(2026, 11, 15, 9, 0));
      expect(reconstruida.voluntarios.beneficios, 'Certificado y almuerzo');
      expect(reconstruida.asistentes.beneficios, isNull);
      expect(reconstruida.organizadores, ['org1', 'org2']);
    });
  });

  // ── (b) Convocatoria sin cupo ───────────────────────────────────────────
  group('Convocatoria sin cupo', () {
    test('cupos == ocupados → hayCupo false y admitePostulaciones false', () {
      const conv = Convocatoria(abierta: true, cupos: 2, ocupados: 2);
      expect(conv.hayCupo, false);
      expect(conv.admitePostulaciones, false);
    });
  });

  // ── (c) Convocatoria vencida ────────────────────────────────────────────
  group('Convocatoria vencida', () {
    test('fechaLimite en el pasado → vencida true', () {
      final conv = Convocatoria(
        abierta: true,
        cupos: 10,
        fechaLimite: DateTime(2020, 1, 1), // fecha pasada
      );
      expect(conv.vencida, true);
      expect(conv.admitePostulaciones, false);
    });
  });

  // ── (d) Postulacion.construirId ─────────────────────────────────────────
  group('Postulacion.construirId', () {
    test('genera el id determinista correcto', () {
      final id = Postulacion.construirId(
          'e1', 'u1', RolPostulacion.voluntario);
      expect(id, 'e1_u1_voluntario');
    });
  });

  // ── (e) TipoEvento.desde con valor desconocido ─────────────────────────
  group('TipoEvento.desde', () {
    test('valor desconocido devuelve TipoEvento.otro', () {
      expect(TipoEvento.desde('algo raro'), TipoEvento.otro);
    });

    test('null devuelve TipoEvento.otro', () {
      expect(TipoEvento.desde(null), TipoEvento.otro);
    });

    test('valor válido devuelve el enum correcto', () {
      expect(TipoEvento.desde('campana'), TipoEvento.campana);
      expect(TipoEvento.campana.etiqueta, 'Campaña');
    });
  });
}
