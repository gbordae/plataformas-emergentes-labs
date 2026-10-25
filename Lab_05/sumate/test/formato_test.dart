import 'package:flutter_test/flutter_test.dart';
import 'package:sumate/core/formato.dart';
import 'package:sumate/features/eventos/modelos/convocatoria.dart';

void main() {
  group('formato.dart', () {
    test('fechaCorta formatea correctamente día, mes y hora local', () {
      // 2026-11-21 es sábado
      final fecha = DateTime(2026, 11, 21, 9, 5);
      final resultado = fechaCorta(fecha);
      expect(resultado, equals('sáb 21 nov · 9:05'));
    });

    test('rangoFechas en el mismo día muestra horas de inicio y fin', () {
      final inicio = DateTime(2026, 11, 21, 9, 0);
      final fin = DateTime(2026, 11, 21, 18, 30);
      expect(rangoFechas(inicio, fin), equals('sáb 21 nov · 9:00 - 18:30'));
    });

    test('rangoFechas en diferentes días muestra ambas fechas completas', () {
      final inicio = DateTime(2026, 11, 21, 9, 0);
      final fin = DateTime(2026, 11, 22, 18, 0);
      expect(rangoFechas(inicio, fin), equals('sáb 21 nov · 9:00 al dom 22 nov · 18:00'));
    });

    test('textoCupos devuelve la cantidad disponible o agotado', () {
      const abiertaCon12 = Convocatoria(abierta: true, cupos: 20, ocupados: 8);
      expect(textoCupos(abiertaCon12), equals('12 cupos disponibles'));

      const abiertaCon1 = Convocatoria(abierta: true, cupos: 10, ocupados: 9);
      expect(textoCupos(abiertaCon1), equals('1 cupo disponible'));

      const agotada = Convocatoria(abierta: true, cupos: 10, ocupados: 10);
      expect(textoCupos(agotada), equals('Cupos agotados'));

      const cerrada = Convocatoria.cerrada();
      expect(textoCupos(cerrada), equals('Cerrada'));
    });

    test('textoFechaLimite maneja fechas y nulos adecuadamente', () {
      expect(textoFechaLimite(null), equals('Sin fecha límite'));

      final fecha = DateTime(2026, 11, 21, 23, 59);
      expect(textoFechaLimite(fecha), equals('Hasta sáb 21 nov · 23:59'));
    });
  });
}
