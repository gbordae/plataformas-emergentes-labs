// lib/pruebas/prueba_back.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/servicios/auth_service.dart';
import '../features/perfil/servicios/usuario_service.dart';
import '../features/eventos/servicios/evento_service.dart';
import '../features/eventos/servicios/edicion_service.dart';
import '../features/postulaciones/servicios/postulacion_service.dart';
import '../features/eventos/modelos/evento.dart';
import '../features/eventos/modelos/edicion.dart';
import '../features/eventos/modelos/convocatoria.dart';
import '../core/enums.dart';
import '../core/errores.dart';

/// Pantalla de prueba que ejecuta los pasos 3, 4 y 5 del backend.
class PruebaBackScreen extends StatefulWidget {
  const PruebaBackScreen({super.key});

  @override
  State<PruebaBackScreen> createState() => _PruebaBackScreenState();
}

class _PruebaBackScreenState extends State<PruebaBackScreen> {
  final AuthService _authService = AuthService();
  final UsuarioService _usuarioService = UsuarioService();
  final EventoService _eventoService = EventoService();
  final EdicionService _edicionService = EdicionService();
  final PostulacionService _postService = PostulacionService();

  final List<String> _log = [];

  void _addLog(String msg) => setState(() => _log.add(msg));

  // ── Helper: registra o inicia sesión ────────────────────────────────────
  Future<void> _entrar(String correo, String nombre) async {
    try {
      await _authService.registrar(
          nombre: nombre, correo: correo, password: '123456');
      _addLog('  ✅ Registrado $correo');
    } on AuthError catch (e) {
      if (e.mensaje.contains('ya está en uso')) {
        await _authService.iniciarSesion(correo: correo, password: '123456');
        _addLog('  ⚠️ Login $correo (ya existía)');
      } else {
        _addLog('  ❌ Error: ${e.mensaje}');
      }
    }
  }

  // ---------- Paso 3 ----------
  Future<void> _registrarLogin() async {
    const correo = 'prueba@sumate.pe';
    const password = '123456';
    const nombre = 'Prueba';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('✅ Registro exitoso');
    } on AuthError catch (e) {
      if (e.mensaje.contains('ya está en uso')) {
        try {
          await _authService.iniciarSesion(correo: correo, password: password);
          _addLog('⚠️ Usuario ya registrado, login exitoso');
        } on AuthError catch (e2) {
          _addLog('❌ Error al login: ${e2.mensaje}');
        }
      } else {
        _addLog('❌ Error registro: ${e.mensaje}');
      }
    }
  }

  Future<void> _obtenerPerfil() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) return _addLog('❌ No hay usuario autenticado');
    final usuario = await _usuarioService.obtener(uid);
    if (usuario == null) {
      _addLog('⚠️ Perfil no encontrado');
    } else {
      _addLog('✅ Perfil: ${usuario.nombre}, ${usuario.universidad}, ${usuario.carrera}');
    }
  }

  Future<void> _actualizarPerfil() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) return _addLog('❌ No hay usuario autenticado');
    final actual = await _usuarioService.obtener(uid);
    if (actual == null) return _addLog('⚠️ Perfil no encontrado');
    final actualizado = actual.copyWith(
      universidad: 'UNSA',
      carrera: 'Ingeniería de Sistemas',
      ciclo: 5,
      habilidades: ['Flutter', 'Diseño'],
    );
    await _usuarioService.actualizar(actualizado);
    _addLog('✅ Perfil actualizado');
    final revisado = await _usuarioService.obtener(uid);
    _addLog('🔎 Revisado: ${revisado?.universidad}, ${revisado?.carrera}, ${revisado?.ciclo}');
  }

  Future<void> _registroDuplicado() async {
    const correo = 'prueba@sumate.pe';
    const password = '123456';
    const nombre = 'PruebaDup';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('❌ Registro duplicado inesperado');
    } on AuthError catch (e) {
      _addLog('✅ Registro duplicado detectado: ${e.mensaje}');
    }
  }

  Future<void> _cerrarSesion() async {
    await _authService.cerrarSesion();
    _addLog('✅ Sesión cerrada');
  }

  // ---------- Paso 4 ----------

  String? _edicionCreadaId;

  Future<void> _crearEventoYEdicion() async {
    final uid = _authService.usuarioActual?.uid ?? '';
    final evento = Evento(
      id: '',
      nombre: 'Hack4Edu',
      tipo: TipoEvento.hackathon,
      descripcion: '',
      entidad: '',
      administradores: [uid],
    );
    final edicion = Edicion(
      id: '',
      eventoId: '',
      eventoNombre: 'Hack4Edu',
      tipo: TipoEvento.hackathon,
      nombre: 'Hack4Edu 2026',
      fechaInicio: DateTime(2026, 12, 1),
      fechaFin: DateTime(2026, 12, 3),
      lugar: 'Campus UNSA',
      modalidad: Modalidad.hibrido,
      universidad: 'UNSA',
      organizadores: [uid],
      voluntarios: Convocatoria(abierta: true, cupos: 5, ocupados: 0),
      asistentes: Convocatoria(abierta: true, cupos: 50, ocupados: 0),
    );
    final edicionId = await _edicionService.crearEventoConPrimeraEdicion(evento: evento, edicion: edicion, uid: uid);
    _edicionCreadaId = edicionId;
    _addLog('✅ Evento y edición creados, edición id=$edicionId');
  }

  Future<void> _listarAbiertas() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) return _addLog('❌ No hay usuario');
    final abiertas = await _edicionService.misEdicionesAbiertas(uid);
    _addLog('✅ Ediciones abiertas tot=${abiertas.length}');
    final hackAbiertas = await _edicionService.misEdicionesAbiertasFiltros(uid, tipo: TipoEvento.hackathon);
    _addLog('✅ Hackathon abiertas=${hackAbiertas.length}');
  }

  Future<void> _detalleEdicionCreada() async {
    final id = _edicionCreadaId;
    if (id == null) return _addLog('❌ No hay edición creada');
    final detalle = await _edicionService.obtener(id);
    _addLog('✅ Detalle edición: ${detalle?.nombre}, lugar=${detalle?.lugar}, voluntarios=${detalle?.voluntarios.cupos}');
  }

  Future<void> _misEdicionesYEventos() async {
    final uid = _authService.usuarioActual?.uid;
    if (uid == null) return _addLog('❌ No hay usuario');
    final misEdiciones = await _edicionService.misEdiciones(uid);
    final misEventos = await _eventoService.misEventos(uid);
    _addLog('✅ Tengo ${misEdiciones.length} ediciones y ${misEventos.length} eventos');
  }

  Future<void> _editarLugarYVoluntarios() async {
    final id = _edicionCreadaId;
    if (id == null) return _addLog('❌ No hay edición');
    final edicion = await _edicionService.obtener(id);
    if (edicion == null) return _addLog('❌ Edición no encontrada');
    final actualizada = edicion.copyWith(
      lugar: 'Nuevo Campus',
      voluntarios: edicion.voluntarios.copyWith(cupos: 8, ocupados: 0),
    );
    await _edicionService.editar(actualizada);
    final revisada = await _edicionService.obtener(id);
    _addLog('✅ Editada: lugar=${revisada?.lugar}, voluntarios max=${revisada?.voluntarios.cupos}, ocupados=${revisada?.voluntarios.ocupados}');
  }

  Future<void> _cerrarReabrirEdicion() async {
    final id = _edicionCreadaId;
    if (id == null) return _addLog('❌ No hay edición');
    await _edicionService.cerrar(id);
    final trasCerrar = await _edicionService.obtener(id);
    _addLog('✅ Estado tras cerrar: ${trasCerrar?.estado}');
    final uid = _authService.usuarioActual?.uid;
    if (uid != null) {
      final abiertas = await _edicionService.misEdicionesAbiertas(uid);
      final contiene = abiertas.any((e) => e.id == id);
      _addLog('✅ Aparece en abiertas después de cerrar? $contiene');
    }
    await _edicionService.reabrir(id);
    final trasReabrir = await _edicionService.obtener(id);
    _addLog('✅ Estado tras reabrir: ${trasReabrir?.estado}');
  }

  Future<void> _crearNuevaDesdeAnterior() async {
    final id = _edicionCreadaId;
    if (id == null) return _addLog('❌ No hay edición fuente');
    final nuevaId = await _edicionService.crearNuevaEdicionDesde(id);
    _addLog('✅ Nueva edición creada desde $id con id=$nuevaId');
  }

  Future<void> _registrarOtroLoginYEditar() async {
    const correo = 'otro@sumate.pe';
    const password = '123456';
    const nombre = 'Otro';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('✅ Otro usuario registrado');
    } on AuthError catch (_) {
      await _authService.iniciarSesion(correo: correo, password: password);
      _addLog('✅ Otro usuario login');
    }
    try {
      final edicion = await _edicionService.obtener(_edicionCreadaId ?? '');
      if (edicion == null) throw ErrorNegocio('Edición no encontrada');
      final editada = edicion.copyWith(lugar: 'Otro Lugar');
      await _edicionService.editar(editada);
      _addLog('❌ Edición editada inesperadamente por otro usuario');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _addLog('✅ Permission denied al editar como otro usuario');
      } else {
        _addLog('❌ Firebase error: ${e.code}');
      }
    } on ErrorNegocio catch (e) {
      _addLog('✅ ErrorNegocio capturado: $e');
    }
  }

  Future<void> _registrarOtroLoginYCrearDesde() async {
    const correo = 'otro2@sumate.pe';
    const password = '123456';
    const nombre = 'Otro2';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('✅ Otro2 registrado');
    } on AuthError catch (_) {
      await _authService.iniciarSesion(correo: correo, password: password);
      _addLog('✅ Otro2 login');
    }
    try {
      final nuevaId = await _edicionService.crearNuevaEdicionDesde(_edicionCreadaId ?? '');
      _addLog('❌ Creó nueva edición desde otro usuario, id=$nuevaId');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _addLog('✅ Permission denied al crear nueva edición desde otro usuario');
      } else {
        _addLog('❌ Firebase error: ${e.code}');
      }
    } on ErrorNegocio catch (e) {
      _addLog('✅ ErrorNegocio al crear desde otro usuario: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ████  Paso 5: Postulaciones  █████████████████████████████████████████████
  // ══════════════════════════════════════════════════════════════════════════

  String? _paso5EdicionId;
  String? _paso5VolPostId;

  // 5.1 ─ Preparar: crear evento con edición en curso
  Future<void> _p5Preparar() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      final uid = _authService.usuarioActual!.uid;

      final ahora = DateTime.now();
      final evento = Evento(
        id: '',
        nombre: 'Paso5 Test',
        tipo: TipoEvento.conferencia,
        descripcion: 'Evento de prueba paso 5',
        entidad: 'UNSA',
        administradores: [uid],
      );
      final edicion = Edicion(
        id: '',
        eventoId: '',
        eventoNombre: 'Paso5 Test',
        tipo: TipoEvento.conferencia,
        nombre: 'Paso5 Test 2026',
        fechaInicio: ahora.subtract(const Duration(hours: 1)),
        fechaFin: ahora.add(const Duration(days: 1)),
        lugar: 'Campus UNSA',
        modalidad: Modalidad.presencial,
        universidad: 'UNSA',
        organizadores: [uid],
        voluntarios: Convocatoria(abierta: true, cupos: 1, ocupados: 0),
        asistentes: Convocatoria(abierta: true, cupos: 2, ocupados: 0),
      );
      final edId = await _edicionService.crearEventoConPrimeraEdicion(
          evento: evento, edicion: edicion, uid: uid);
      _paso5EdicionId = edId;
      _addLog('✅ 5.1 Preparado: edición=$edId');
    } catch (e) {
      _addLog('❌ 5.1 ERROR: $e');
    }
  }

  // 5.2 ─ vol@ postula como voluntario
  Future<void> _p5VolPostula() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      final uid = _authService.usuarioActual!.uid;
      // Actualizar perfil
      final perfil = await _usuarioService.obtener(uid);
      if (perfil != null) {
        await _usuarioService.actualizar(perfil.copyWith(
          habilidades: ['Flutter', 'Diseño'],
          carrera: 'Ingeniería de Sistemas',
        ));
      }
      final postId = await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.voluntario,
        uid: uid,
      );
      _paso5VolPostId = postId;
      final post = await _postService.obtener(postId);
      final ed = await _edicionService.obtener(_paso5EdicionId!);
      _addLog('✅ 5.2 Vol postuló: estado=${post?.estado.name}, '
          'vol.ocupados=${ed?.voluntarios.ocupados}');
    } catch (e) {
      _addLog('❌ 5.2 ERROR: $e');
    }
  }

  // 5.3 ─ vol@ repite postulación: debe fallar
  Future<void> _p5VolRepite() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      final uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.voluntario,
        uid: uid,
      );
      _addLog('❌ 5.3 Duplicado NO detectado');
    } on ErrorNegocio catch (e) {
      _addLog('✅ 5.3 Duplicado bloqueado: $e');
    } catch (e) {
      _addLog('❌ 5.3 ERROR inesperado: $e');
    }
  }

  // 5.4 ─ asi@ postula como asistente
  Future<void> _p5AsiPostula() async {
    try {
      await _entrar('asi@sumate.pe', 'Asi');
      final uid = _authService.usuarioActual!.uid;
      final postId = await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.asistente,
        uid: uid,
      );
      final post = await _postService.obtener(postId);
      final ed = await _edicionService.obtener(_paso5EdicionId!);
      _addLog('✅ 5.4 Asi postuló: estado=${post?.estado.name}, '
          'asi.ocupados=${ed?.asistentes.ocupados}');
    } catch (e) {
      _addLog('❌ 5.4 ERROR: $e');
    }
  }

  // 5.5 ─ asi@ repite: debe fallar
  Future<void> _p5AsiRepite() async {
    try {
      await _entrar('asi@sumate.pe', 'Asi');
      final uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.asistente,
        uid: uid,
      );
      _addLog('❌ 5.5 Duplicado NO detectado');
    } on ErrorNegocio catch (e) {
      _addLog('✅ 5.5 Duplicado bloqueado: $e');
    } catch (e) {
      _addLog('❌ 5.5 ERROR inesperado: $e');
    }
  }

  // 5.6 ─ prueba@ lista postulantes de la edición
  Future<void> _p5ListarPostulantes() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      final lista = await _postService.postulantesDeEdicion(_paso5EdicionId!);
      _addLog('✅ 5.6 Postulantes: ${lista.length}');
      for (final p in lista) {
        _addLog('   ${p.perfil.nombre}, rol=${p.rol.name}, '
            'estado=${p.estado.name}, hab=${p.perfil.habilidades}');
      }
    } catch (e) {
      _addLog('❌ 5.6 ERROR: $e');
    }
  }

  // 5.7 ─ prueba@ acepta al voluntario
  Future<void> _p5AceptarVol() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      await _postService.responder(
          _paso5VolPostId!, EstadoPostulacion.aceptada);
      final post = await _postService.obtener(_paso5VolPostId!);
      final ed = await _edicionService.obtener(_paso5EdicionId!);
      _addLog('✅ 5.7 Vol aceptado: estado=${post?.estado.name}, '
          'vol.ocupados=${ed?.voluntarios.ocupados}');
    } catch (e) {
      _addLog('❌ 5.7 ERROR: $e');
    }
  }

  // 5.8 ─ vol2@ intenta postular como voluntario: cupo lleno
  Future<void> _p5Vol2Cupo() async {
    try {
      await _entrar('vol2@sumate.pe', 'Vol2');
      final uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.voluntario,
        uid: uid,
      );
      _addLog('❌ 5.8 Cupo lleno NO detectado');
    } on ErrorNegocio catch (e) {
      _addLog('✅ 5.8 Cupo bloqueado: $e');
    } catch (e) {
      _addLog('❌ 5.8 ERROR inesperado: $e');
    }
  }

  // 5.9 ─ prueba@ marca asistio=true al voluntario
  Future<void> _p5MarcarAsistio() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      await _postService.marcarAsistio(_paso5VolPostId!, true);
      _addLog('✅ 5.9 Asistió marcado OK');
    } catch (e) {
      _addLog('❌ 5.9 ERROR: $e');
    }
  }

  // 5.10 ─ vol@: misPostulaciones e historial
  Future<void> _p5MisPostEHistorial() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      final uid = _authService.usuarioActual!.uid;
      final mis = await _postService.misPostulaciones(uid);
      final hist = await _postService.historial(uid);
      _addLog('✅ 5.10 misPostulaciones=${mis.length}, historial=${hist.length}');
    } catch (e) {
      _addLog('❌ 5.10 ERROR: $e');
    }
  }

  // 5.11 ─ Negativa: vol@ intenta update directo asistio=true
  Future<void> _p5NegAsistio() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      await FirebaseFirestore.instance
          .collection('postulaciones')
          .doc(_paso5VolPostId!)
          .update({'asistio': true});
      _addLog('❌ 5.11 Update directo asistio NO bloqueado');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _addLog('✅ 5.11 permission-denied al update asistio');
      } else {
        _addLog('❌ 5.11 Firebase error: ${e.code}');
      }
    } catch (e) {
      _addLog('❌ 5.11 ERROR inesperado: $e');
    }
  }

  // 5.12 ─ Negativa: vol@ intenta update directo estado=aceptada
  Future<void> _p5NegEstado() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      await FirebaseFirestore.instance
          .collection('postulaciones')
          .doc(_paso5VolPostId!)
          .update({'estado': 'aceptada'});
      _addLog('❌ 5.12 Update directo estado NO bloqueado');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _addLog('✅ 5.12 permission-denied al update estado');
      } else {
        _addLog('❌ 5.12 Firebase error: ${e.code}');
      }
    } catch (e) {
      _addLog('❌ 5.12 ERROR inesperado: $e');
    }
  }

  // 5.13 ─ Negativa: vol@ intenta leer postulantesDeEdicion
  Future<void> _p5NegLeerPostulantes() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      final lista = await FirebaseFirestore.instance
          .collection('postulaciones')
          .where('edicionId', isEqualTo: _paso5EdicionId!)
          .get();
      // Si llegamos aquí sin error, la query devolvió docs
      // pero las reglas podrían filtrar en el get individual
      _addLog('❌ 5.13 Lectura de postulantes NO bloqueada (${lista.docs.length} docs)');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _addLog('✅ 5.13 permission-denied al leer postulantes');
      } else {
        _addLog('❌ 5.13 Firebase error: ${e.code}');
      }
    } catch (e) {
      _addLog('❌ 5.13 ERROR inesperado: $e');
    }
  }

  // 5.14 ─ Negativa: asi@ intenta increment(5) en asistentes.ocupados
  Future<void> _p5NegIncrement() async {
    try {
      await _entrar('asi@sumate.pe', 'Asi');
      await FirebaseFirestore.instance
          .collection('ediciones')
          .doc(_paso5EdicionId!)
          .update({'asistentes.ocupados': FieldValue.increment(5)});
      _addLog('❌ 5.14 Increment(5) NO bloqueado');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _addLog('✅ 5.14 permission-denied al increment(5)');
      } else {
        _addLog('❌ 5.14 Firebase error: ${e.code}');
      }
    } catch (e) {
      _addLog('❌ 5.14 ERROR inesperado: $e');
    }
  }

  // 5.15 ─ Plazo vencido: nueva edición con fechaLimite de ayer
  Future<void> _p5PlazoVencido() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      final uid = _authService.usuarioActual!.uid;
      final ahora = DateTime.now();
      final evento = Evento(
        id: '',
        nombre: 'Paso5 Plazo',
        tipo: TipoEvento.conferencia,
        descripcion: '',
        entidad: 'UNSA',
        administradores: [uid],
      );
      final edicion = Edicion(
        id: '',
        eventoId: '',
        eventoNombre: 'Paso5 Plazo',
        tipo: TipoEvento.conferencia,
        nombre: 'Paso5 Plazo 2026',
        fechaInicio: ahora.add(const Duration(days: 7)),
        fechaFin: ahora.add(const Duration(days: 8)),
        lugar: 'Campus UNSA',
        modalidad: Modalidad.presencial,
        universidad: 'UNSA',
        organizadores: [uid],
        voluntarios: Convocatoria(
          abierta: true,
          cupos: 5,
          ocupados: 0,
          fechaLimite: ahora.subtract(const Duration(days: 1)),
        ),
        asistentes: Convocatoria(abierta: true, cupos: 10, ocupados: 0),
      );
      final edId = await _edicionService.crearEventoConPrimeraEdicion(
          evento: evento, edicion: edicion, uid: uid);

      // Ahora vol2@ intenta postular como voluntario
      await _entrar('vol2@sumate.pe', 'Vol2');
      final vol2Uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: edId,
        rol: RolPostulacion.voluntario,
        uid: vol2Uid,
      );
      _addLog('❌ 5.15 Plazo vencido NO detectado');
    } on ErrorNegocio catch (e) {
      _addLog('✅ 5.15 Plazo vencido bloqueado: $e');
    } catch (e) {
      _addLog('❌ 5.15 ERROR inesperado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba Back')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(_log[i], style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // ── Paso 3 ──
                  ElevatedButton(onPressed: _registrarLogin, child: const Text('3.1 Registrar/Login')),
                  ElevatedButton(onPressed: _obtenerPerfil, child: const Text('3.2 Obtener perfil')),
                  ElevatedButton(onPressed: _actualizarPerfil, child: const Text('3.3 Actualizar perfil')),
                  ElevatedButton(onPressed: _registroDuplicado, child: const Text('3.4 Registro duplicado')),
                  ElevatedButton(onPressed: _cerrarSesion, child: const Text('3.5 Cerrar sesión')),
                  // ── Paso 4 ──
                  ElevatedButton(onPressed: _crearEventoYEdicion, child: const Text('4.1 Crear evento+edición')),
                  ElevatedButton(onPressed: _listarAbiertas, child: const Text('4.2 Listar abiertas')),
                  ElevatedButton(onPressed: _detalleEdicionCreada, child: const Text('4.3 Detalle edición')),
                  ElevatedButton(onPressed: _misEdicionesYEventos, child: const Text('4.4 Mis ed/eventos')),
                  ElevatedButton(onPressed: _editarLugarYVoluntarios, child: const Text('4.5 Editar lugar/vol')),
                  ElevatedButton(onPressed: _cerrarReabrirEdicion, child: const Text('4.6 Cerrar/Reabrir')),
                  ElevatedButton(onPressed: _crearNuevaDesdeAnterior, child: const Text('4.7 Crear desde anterior')),
                  ElevatedButton(onPressed: _registrarOtroLoginYEditar, child: const Text('4.8 Otro login editar')),
                  ElevatedButton(onPressed: _registrarOtroLoginYCrearDesde, child: const Text('4.9 Otro login crear')),
                  const Divider(),
                  // ── Paso 5: Postulaciones ──
                  ElevatedButton(
                    onPressed: _p5Preparar,
                    child: const Text('5.1 Preparar'),
                  ),
                  ElevatedButton(
                    onPressed: _p5VolPostula,
                    child: const Text('5.2 Vol postula'),
                  ),
                  ElevatedButton(
                    onPressed: _p5VolRepite,
                    child: const Text('5.3 Vol repite (dup)'),
                  ),
                  ElevatedButton(
                    onPressed: _p5AsiPostula,
                    child: const Text('5.4 Asi postula'),
                  ),
                  ElevatedButton(
                    onPressed: _p5AsiRepite,
                    child: const Text('5.5 Asi repite (dup)'),
                  ),
                  ElevatedButton(
                    onPressed: _p5ListarPostulantes,
                    child: const Text('5.6 Listar postulantes'),
                  ),
                  ElevatedButton(
                    onPressed: _p5AceptarVol,
                    child: const Text('5.7 Aceptar vol'),
                  ),
                  ElevatedButton(
                    onPressed: _p5Vol2Cupo,
                    child: const Text('5.8 Vol2 cupo lleno'),
                  ),
                  ElevatedButton(
                    onPressed: _p5MarcarAsistio,
                    child: const Text('5.9 Marcar asistió'),
                  ),
                  ElevatedButton(
                    onPressed: _p5MisPostEHistorial,
                    child: const Text('5.10 MisPost/Historial'),
                  ),
                  ElevatedButton(
                    onPressed: _p5NegAsistio,
                    child: const Text('5.11 Neg: asistio'),
                  ),
                  ElevatedButton(
                    onPressed: _p5NegEstado,
                    child: const Text('5.12 Neg: estado'),
                  ),
                  ElevatedButton(
                    onPressed: _p5NegLeerPostulantes,
                    child: const Text('5.13 Neg: leer post'),
                  ),
                  ElevatedButton(
                    onPressed: _p5NegIncrement,
                    child: const Text('5.14 Neg: incr(5)'),
                  ),
                  ElevatedButton(
                    onPressed: _p5PlazoVencido,
                    child: const Text('5.15 Plazo vencido'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
