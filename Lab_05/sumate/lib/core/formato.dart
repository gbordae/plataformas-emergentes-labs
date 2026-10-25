// Helpers de formateo en español para Súmate sin dependencias externas.
// Maneja fechas en hora local, rangos y textos de estado/cupos.

import '../features/eventos/modelos/convocatoria.dart';

const List<String> _diasSemana = [
  'lun',
  'mar',
  'mié',
  'jue',
  'vie',
  'sáb',
  'dom',
];

const List<String> _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'set',
  'oct',
  'nov',
  'dic',
];

/// Formatea una fecha en formato corto: "sáb 22 nov · 9:00" (hora local).
String fechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = _diasSemana[local.weekday - 1];
  final mes = _meses[local.month - 1];
  final minutos = local.minute.toString().padLeft(2, '0');
  return '$dia ${local.day} $mes · ${local.hour}:$minutos';
}

/// Formatea un rango de fechas. Si es el mismo día, muestra "sáb 22 nov · 9:00 - 18:00".
/// Si son días diferentes, muestra "sáb 22 nov · 9:00 al dom 23 nov · 18:00".
String rangoFechas(DateTime inicio, DateTime fin) {
  final iniLocal = inicio.toLocal();
  final finLocal = fin.toLocal();
  final inicioStr = fechaCorta(iniLocal);

  final mismoDia = iniLocal.year == finLocal.year &&
      iniLocal.month == finLocal.month &&
      iniLocal.day == finLocal.day;

  if (mismoDia) {
    final minutosFin = finLocal.minute.toString().padLeft(2, '0');
    return '$inicioStr - ${finLocal.hour}:$minutosFin';
  }

  return '$inicioStr al ${fechaCorta(finLocal)}';
}

/// Devuelve texto descriptivo de cupos disponibles:
/// "12 cupos disponibles", "1 cupo disponible" o "Cupos agotados".
String textoCupos(Convocatoria convocatoria) {
  if (!convocatoria.abierta) return 'Cerrada';
  final disponibles = convocatoria.cupos - convocatoria.ocupados;
  if (disponibles <= 0) return 'Cupos agotados';
  if (disponibles == 1) return '1 cupo disponible';
  return '$disponibles cupos disponibles';
}

/// Devuelve la fecha límite formateada o texto informativo si no tiene.
String textoFechaLimite(DateTime? fecha) {
  if (fecha == null) return 'Sin fecha límite';
  return 'Hasta ${fechaCorta(fecha)}';
}
