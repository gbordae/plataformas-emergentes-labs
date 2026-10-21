// lib/pruebas/seed_demo.dart
import 'package:flutter/material.dart';

import '../core/enums.dart';
import '../features/auth/servicios/auth_service.dart';
import '../features/eventos/modelos/convocatoria.dart';
import '../features/eventos/modelos/edicion.dart';
import '../features/eventos/modelos/evento.dart';
import '../features/eventos/servicios/edicion_service.dart';
import '../features/eventos/servicios/evento_service.dart';

/// Pantalla temporal para sembrar datos de ejemplo (seed) de la demo.
///
/// Crea 8 eventos con sus respectivas primeras ediciones si no existen previamente,
/// garantizando idempotencia mediante la consulta por nombre de evento.
class SeedDemoScreen extends StatefulWidget {
  const SeedDemoScreen({super.key});

  @override
  State<SeedDemoScreen> createState() => _SeedDemoScreenState();
}

class _SeedDemoScreenState extends State<SeedDemoScreen> {
  final AuthService _authService = AuthService();
  final EventoService _eventoService = EventoService();
  final EdicionService _edicionService = EdicionService();

  final List<String> _log = [];
  bool _cargando = false;

  void _addLog(String msg) {
    setState(() => _log.add(msg));
  }

  /// Consulta las convocatorias abiertas del organizador de demo.
  Future<List<Edicion>> listarConvocatoriasAbiertas() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) return [];
    return await _edicionService.misEdicionesAbiertas(uid);
  }

  /// Autentica como organizador de demo (registra si es la primera vez).
  Future<String> _iniciarSesionDemo() async {
    const correo = 'demo@sumate.pe';
    const password = '123456';
    const nombre = 'Organización Demo';

    try {
      await _authService.iniciarSesion(correo: correo, password: password);
      _addLog('🔑 Sesión iniciada como $correo');
    } on AuthError catch (_) {
      try {
        await _authService.registrar(
          nombre: nombre,
          correo: correo,
          password: password,
        );
        _addLog('👤 Usuario demo registrado e identificado');
      } on AuthError catch (e) {
        // En caso de concurrencia o reintento, volver a intentar login
        await _authService.iniciarSesion(correo: correo, password: password);
        _addLog('🔑 Sesión iniciada tras advertencia: ${e.mensaje}');
      }
    }

    final uid = _authService.usuarioActual?.uid;
    if (uid == null) {
      throw Exception('No se pudo obtener el UID del usuario de demo');
    }
    return uid;
  }

  /// Siembra los 8 eventos de demo de forma idempotente.
  Future<void> _sembrarDatos() async {
    setState(() {
      _cargando = true;
      _log.clear();
    });

    try {
      _addLog('🌱 Iniciando siembra de datos de demo...');
      final uid = await _iniciarSesionDemo();

      // Consultar eventos existentes para asegurar idempotencia
      final existentes = await _eventoService.misEventos(uid);
      final nombresExistentes = existentes.map((e) => e.nombre).toSet();

      final hoy = DateTime.now();
      int creados = 0;
      int yaExistian = 0;

      // Definición de los 8 eventos con sus ediciones
      final semillas = [
        // 1. Hack4Edu
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Hack4Edu',
            tipo: TipoEvento.hackathon,
            descripcion:
                'Hackathon universitaria para desarrollar soluciones tecnológicas que transformen la educación en Arequipa.',
            entidad: 'UNSA - Escuela de Sistemas',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 10));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Hack4Edu 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 2)),
              lugar: 'Campus UNSA, Arequipa',
              modalidad: Modalidad.hibrido,
              universidad: 'UNSA',
              organizadores: [uid],
              voluntarios: const Convocatoria(
                abierta: true,
                cupos: 10,
                ocupados: 0,
                beneficios: 'Certificado y networking',
              ),
              asistentes: const Convocatoria(
                abierta: true,
                cupos: 60,
                ocupados: 0,
              ),
            );
          },
        ),

        // 2. Ciclo de Ponencias en IA
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Ciclo de Ponencias en IA',
            tipo: TipoEvento.ponencia,
            descripcion:
                'Serie de conferencias magistrales con expertos en inteligencia artificial y aprendizaje automático aplicados a la industria.',
            entidad: 'UCSM',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 15));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Ciclo de Ponencias en IA 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 1)),
              lugar: 'Auditorio UCSM',
              modalidad: Modalidad.presencial,
              universidad: 'UCSM',
              organizadores: [uid],
              voluntarios: const Convocatoria.cerrada(),
              asistentes: const Convocatoria(
                abierta: true,
                cupos: 120,
                ocupados: 0,
              ),
            );
          },
        ),

        // 3. Lanzamiento Startup Arequipa
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Lanzamiento Startup Arequipa',
            tipo: TipoEvento.lanzamiento,
            descripcion:
                'Presentación oficial de emprendimientos tecnológicos emergentes de la región Arequipa ante inversionistas y comunidad.',
            entidad: 'Cámara de Comercio de Arequipa',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 20));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Lanzamiento Startup Arequipa 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 1)),
              lugar: 'Centro de Convenciones, Arequipa',
              modalidad: Modalidad.presencial,
              universidad: '',
              organizadores: [uid],
              voluntarios: const Convocatoria(
                abierta: true,
                cupos: 6,
                ocupados: 0,
                beneficios: 'Constancia y acceso a mentores',
              ),
              asistentes: const Convocatoria(
                abierta: true,
                cupos: 80,
                ocupados: 0,
              ),
            );
          },
        ),

        // 4. Campaña de Reforestación Chilina
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Campaña de Reforestación Chilina',
            tipo: TipoEvento.campana,
            descripcion:
                'Jornada de arborización y preservación ambiental en el Valle de Chilina con participación de la comunidad universitaria.',
            entidad: 'UCSP - Proyección Social',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 12));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Campaña de Reforestación Chilina 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 1)),
              lugar: 'Valle de Chilina',
              modalidad: Modalidad.presencial,
              universidad: 'UCSP',
              organizadores: [uid],
              voluntarios: const Convocatoria(
                abierta: true,
                cupos: 25,
                ocupados: 0,
                beneficios: 'Constancia de proyección social',
              ),
              asistentes: const Convocatoria.cerrada(),
            );
          },
        ),

        // 5. Conferencia de Ciberseguridad
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Conferencia de Ciberseguridad',
            tipo: TipoEvento.conferencia,
            descripcion:
                'Conferencia internacional sobre seguridad de la información, buenas prácticas defensivas y análisis de vulnerabilidades.',
            entidad: 'UNSA',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 25));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Conferencia de Ciberseguridad 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 1)),
              lugar: 'Zoom (enlace al inscribirse)',
              modalidad: Modalidad.remoto,
              universidad: 'UNSA',
              organizadores: [uid],
              voluntarios: const Convocatoria.cerrada(),
              asistentes: const Convocatoria(
                abierta: true,
                cupos: 200,
                ocupados: 0,
                enlaceExterno: 'https://forms.gle/ejemplo-ciberseguridad',
              ),
            );
          },
        ),

        // 6. Feria de Proyectos Tecnológicos
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Feria de Proyectos Tecnológicos',
            tipo: TipoEvento.otro,
            descripcion:
                'Exhibición abierta al público general de prototipos e innovaciones tecnológicas desarrolladas por talentos locales.',
            entidad: 'Colectivo Tech Arequipa',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 35));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Feria de Proyectos Tecnológicos 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 2)),
              lugar: 'Plaza de Armas, Arequipa',
              modalidad: Modalidad.presencial,
              universidad: '',
              organizadores: [uid],
              voluntarios: const Convocatoria(
                abierta: true,
                cupos: 8,
                ocupados: 0,
                beneficios: 'Certificado y almuerzo',
              ),
              asistentes: Convocatoria(
                abierta: true,
                cupos: 100,
                ocupados: 0,
                fechaLimite: hoy.add(const Duration(days: 30)),
              ),
            );
          },
        ),

        // 7. Taller de Diseño UX
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Taller de Diseño UX',
            tipo: TipoEvento.ponencia,
            descripcion:
                'Taller práctico e intensivo sobre investigación de usuarios, wireframing y diseño de interfaces centradas en las personas.',
            entidad: 'UCSM - Diseño',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 8));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Taller de Diseño UX 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 1)),
              lugar: 'Laboratorio de Diseño UCSM',
              modalidad: Modalidad.hibrido,
              universidad: 'UCSM',
              organizadores: [uid],
              voluntarios: const Convocatoria(
                abierta: true,
                cupos: 4,
                ocupados: 0,
                beneficios: 'Certificado',
              ),
              asistentes: const Convocatoria(
                abierta: true,
                cupos: 30,
                ocupados: 0,
              ),
            );
          },
        ),

        // 8. Voluntariado Banco de Alimentos
        _SemillaEvento(
          evento: Evento(
            id: '',
            nombre: 'Voluntariado Banco de Alimentos',
            tipo: TipoEvento.campana,
            descripcion:
                'Actividad solidaria de clasificación y distribución de alimentos de primera necesidad para familias vulnerables.',
            entidad: 'Voluntarios Arequipa',
            administradores: [uid],
          ),
          construirEdicion: (ev) {
            final inicio = hoy.add(const Duration(days: 18));
            return Edicion(
              id: '',
              eventoId: '',
              eventoNombre: ev.nombre,
              tipo: ev.tipo,
              nombre: 'Voluntariado Banco de Alimentos 2026',
              fechaInicio: inicio,
              fechaFin: inicio.add(const Duration(days: 1)),
              lugar: 'Banco de Alimentos, Cerro Colorado',
              modalidad: Modalidad.presencial,
              universidad: '',
              organizadores: [uid],
              voluntarios: Convocatoria(
                abierta: true,
                cupos: 15,
                ocupados: 0,
                fechaLimite: hoy.add(const Duration(days: 14)),
              ),
              asistentes: const Convocatoria.cerrada(),
            );
          },
        ),
      ];

      // Procesar cada evento con try/catch individual
      for (int i = 0; i < semillas.length; i++) {
        final sem = semillas[i];
        final num = i + 1;
        if (nombresExistentes.contains(sem.evento.nombre)) {
          _addLog('⚠️ [$num/8] "${sem.evento.nombre}" ya existía');
          yaExistian++;
        } else {
          try {
            final edicion = sem.construirEdicion(sem.evento);
            await _edicionService.crearEventoConPrimeraEdicion(
              evento: sem.evento,
              edicion: edicion,
              uid: uid,
            );
            _addLog('✅ [$num/8] "${sem.evento.nombre}" creado exitosamente');
            creados++;
          } catch (e) {
            _addLog('❌ [$num/8] Error al crear "${sem.evento.nombre}": $e');
          }
        }
      }

      // Verificación final del total de convocatorias abiertas
      final abiertas = await listarConvocatoriasAbiertas();
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('📊 Resumen de siembra:');
      _addLog('   • Creados: $creados');
      _addLog('   • Ya existían: $yaExistian');
      _addLog('   • Total listarConvocatoriasAbiertas(): ${abiertas.length} (esperado: 8)');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      _addLog('❌ ERROR general en la siembra: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Súmate: Siembra de Datos de Demo'),
        backgroundColor: const Color(0xFFABC270),
        foregroundColor: const Color(0xFF473C33),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _cargando ? null : _sembrarDatos,
              icon: _cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                _cargando ? 'Sembrando datos...' : 'Sembrar datos de demo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEC868),
                foregroundColor: const Color(0xFF473C33),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registro de operaciones:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF473C33),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E0D3)),
                ),
                child: _log.isEmpty
                    ? const Center(
                        child: Text(
                          'Presiona "Sembrar datos de demo" para iniciar.',
                          style: TextStyle(color: Color(0xFF6B5F54)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _log.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _log[i],
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemillaEvento {
  final Evento evento;
  final Edicion Function(Evento) construirEdicion;

  const _SemillaEvento({
    required this.evento,
    required this.construirEdicion,
  });
}
