// lib/pruebas/prueba_back.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

/// Pantalla de prueba que ejecuta los pasos 3, 4, 5 y 8 (regresión completa) del backend.
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
    final actual = FirebaseAuth.instance.currentUser;
    if (actual != null && actual.email?.toLowerCase() == correo.toLowerCase()) {
      return;
    }
    if (actual != null) {
      await _authService.cerrarSesion();
    }
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
        rethrow;
      }
    }
  }

  // ── Helper: verifica si un error es de permisos denegados de Firestore ────
  bool _esPermisoDenegado(Object e) {
    if (e is FirebaseException &&
        (e.code == 'permission-denied' || e.code.toLowerCase() == 'permission-denied')) {
      return true;
    }
    return e.toString().toLowerCase().contains('permission-denied');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ████  Paso 3: Auth y Perfil  █████████████████████████████████████████████
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> _registrarLogin() async {
    const correo = 'prueba@sumate.pe';
    const password = '123456';
    const nombre = 'Prueba';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('✅ Registro exitoso');
      return true;
    } on AuthError catch (e) {
      if (e.mensaje.contains('ya está en uso')) {
        try {
          await _authService.iniciarSesion(correo: correo, password: password);
          _addLog('⚠️ Usuario ya registrado, login exitoso');
          return true;
        } on AuthError catch (e2) {
          _addLog('❌ Error al login: ${e2.mensaje}');
          return false;
        }
      } else {
        _addLog('❌ Error registro: ${e.mensaje}');
        return false;
      }
    } catch (e) {
      _addLog('❌ Error inesperado: $e');
      return false;
    }
  }

  Future<bool> _obtenerPerfil() async {
    try {
      final uid = _authService.usuarioActual?.uid;
      if (uid == null) {
        _addLog('❌ No hay usuario autenticado');
        return false;
      }
      final usuario = await _usuarioService.obtener(uid);
      if (usuario == null) {
        _addLog('❌ Perfil no encontrado');
        return false;
      } else {
        _addLog('✅ Perfil: ${usuario.nombre}, ${usuario.universidad}, ${usuario.carrera}');
        return true;
      }
    } catch (e) {
      _addLog('❌ Error inesperado: $e');
      return false;
    }
  }

  Future<bool> _actualizarPerfil() async {
    try {
      final uid = _authService.usuarioActual?.uid;
      if (uid == null) {
        _addLog('❌ No hay usuario autenticado');
        return false;
      }
      final actual = await _usuarioService.obtener(uid);
      if (actual == null) {
        _addLog('❌ Perfil no encontrado');
        return false;
      }
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
      return revisado?.universidad == 'UNSA' &&
          revisado?.carrera == 'Ingeniería de Sistemas' &&
          revisado?.ciclo == 5;
    } catch (e) {
      _addLog('❌ Error inesperado: $e');
      return false;
    }
  }

  Future<bool> _registroDuplicado() async {
    const correo = 'prueba@sumate.pe';
    const password = '123456';
    const nombre = 'PruebaDup';
    try {
      await _authService.registrar(nombre: nombre, correo: correo, password: password);
      _addLog('❌ Registro duplicado inesperado');
      return false;
    } on AuthError catch (e) {
      _addLog('✅ Registro duplicado detectado: ${e.mensaje}');
      return true;
    } catch (e) {
      _addLog('❌ Error inesperado: $e');
      return false;
    }
  }

  Future<bool> _cerrarSesion() async {
    try {
      await _authService.cerrarSesion();
      _addLog('✅ Sesión cerrada');
      return true;
    } catch (e) {
      _addLog('❌ Error al cerrar sesión: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ████  Paso 4: Eventos y Ediciones  ███████████████████████████████████████
  // ══════════════════════════════════════════════════════════════════════════

  String? _edicionCreadaId;

  Future<bool> _crearEventoYEdicion() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
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
      final edicionId = await _edicionService.crearEventoConPrimeraEdicion(
          evento: evento, edicion: edicion, uid: uid);
      _edicionCreadaId = edicionId;
      _addLog('✅ Evento y edición creados, edición id=$edicionId');
      return edicionId.isNotEmpty;
    } catch (e) {
      _addLog('❌ Error al crear evento y edición: $e');
      return false;
    }
  }

  Future<bool> _listarAbiertas() async {
    try {
      if (_authService.usuarioActual == null) {
        await _entrar('prueba@sumate.pe', 'Prueba');
      }
      final uid = _authService.usuarioActual?.uid;
      if (uid == null) {
        _addLog('❌ No hay usuario');
        return false;
      }
      final abiertas = await _edicionService.misEdicionesAbiertas(uid);
      _addLog('✅ Ediciones abiertas tot=${abiertas.length}');
      final hackAbiertas = await _edicionService.misEdicionesAbiertasFiltros(uid, tipo: TipoEvento.hackathon);
      _addLog('✅ Hackathon abiertas=${hackAbiertas.length}');
      final contiene = _edicionCreadaId == null || abiertas.any((e) => e.id == _edicionCreadaId);
      return abiertas.isNotEmpty && contiene;
    } catch (e) {
      _addLog('❌ Error al listar abiertas: $e');
      return false;
    }
  }

  Future<bool> _detalleEdicionCreada() async {
    try {
      final id = _edicionCreadaId;
      if (id == null) {
        _addLog('❌ No hay edición creada');
        return false;
      }
      final detalle = await _edicionService.obtener(id);
      if (detalle == null) {
        _addLog('❌ Edición no encontrada');
        return false;
      }
      _addLog('✅ Detalle edición: ${detalle.nombre}, lugar=${detalle.lugar}, voluntarios=${detalle.voluntarios.cupos}');
      return true;
    } catch (e) {
      _addLog('❌ Error al obtener detalle: $e');
      return false;
    }
  }

  Future<bool> _misEdicionesYEventos() async {
    try {
      if (_authService.usuarioActual == null) {
        await _entrar('prueba@sumate.pe', 'Prueba');
      }
      final uid = _authService.usuarioActual?.uid;
      if (uid == null) {
        _addLog('❌ No hay usuario');
        return false;
      }
      final misEdiciones = await _edicionService.misEdiciones(uid);
      final misEventos = await _eventoService.misEventos(uid);
      _addLog('✅ Tengo ${misEdiciones.length} ediciones y ${misEventos.length} eventos');
      return misEdiciones.isNotEmpty && misEventos.isNotEmpty;
    } catch (e) {
      _addLog('❌ Error en misEdicionesYEventos: $e');
      return false;
    }
  }

  Future<bool> _editarLugarYVoluntarios() async {
    try {
      if (_authService.usuarioActual == null) {
        await _entrar('prueba@sumate.pe', 'Prueba');
      }
      final id = _edicionCreadaId;
      if (id == null) {
        _addLog('❌ No hay edición');
        return false;
      }
      final edicion = await _edicionService.obtener(id);
      if (edicion == null) {
        _addLog('❌ Edición no encontrada');
        return false;
      }
      final actualizada = edicion.copyWith(
        lugar: 'Nuevo Campus',
        voluntarios: edicion.voluntarios.copyWith(cupos: 8, ocupados: 0),
      );
      await _edicionService.editar(actualizada);
      final revisada = await _edicionService.obtener(id);
      _addLog('✅ Editada: lugar=${revisada?.lugar}, voluntarios max=${revisada?.voluntarios.cupos}, ocupados=${revisada?.voluntarios.ocupados}');
      return revisada?.lugar == 'Nuevo Campus' && revisada?.voluntarios.cupos == 8;
    } catch (e) {
      _addLog('❌ Error al editar edición: $e');
      return false;
    }
  }

  Future<bool> _cerrarReabrirEdicion() async {
    try {
      if (_authService.usuarioActual == null) {
        await _entrar('prueba@sumate.pe', 'Prueba');
      }
      final id = _edicionCreadaId;
      if (id == null) {
        _addLog('❌ No hay edición');
        return false;
      }
      await _edicionService.cerrar(id);
      final trasCerrar = await _edicionService.obtener(id);
      _addLog('✅ Estado tras cerrar: ${trasCerrar?.estado}');
      final uid = _authService.usuarioActual?.uid;
      bool cerradaNoAparece = true;
      if (uid != null) {
        final abiertas = await _edicionService.misEdicionesAbiertas(uid);
        final contiene = abiertas.any((e) => e.id == id);
        _addLog('✅ Aparece en abiertas después de cerrar? $contiene');
        if (contiene) cerradaNoAparece = false;
      }
      await _edicionService.reabrir(id);
      final trasReabrir = await _edicionService.obtener(id);
      _addLog('✅ Estado tras reabrir: ${trasReabrir?.estado}');
      return trasCerrar?.estado == EstadoEdicion.cerrada &&
          trasReabrir?.estado == EstadoEdicion.abierta &&
          cerradaNoAparece;
    } catch (e) {
      _addLog('❌ Error al cerrar/reabrir: $e');
      return false;
    }
  }

  Future<bool> _crearNuevaDesdeAnterior() async {
    try {
      if (_authService.usuarioActual == null) {
        await _entrar('prueba@sumate.pe', 'Prueba');
      }
      final id = _edicionCreadaId;
      if (id == null) {
        _addLog('❌ No hay edición fuente');
        return false;
      }
      final nuevaId = await _edicionService.crearNuevaEdicionDesde(id);
      _addLog('✅ Nueva edición creada desde $id con id=$nuevaId');
      return nuevaId.isNotEmpty;
    } catch (e) {
      _addLog('❌ Error al crear nueva edición desde anterior: $e');
      return false;
    }
  }

  Future<bool> _registrarOtroLoginYEditar() async {
    try {
      if (_edicionCreadaId == null) {
        await _crearEventoYEdicion();
      }
      await _entrar('otro@sumate.pe', 'Otro');
      final user = FirebaseAuth.instance.currentUser;
      _addLog('  👤 4.8 Auth actual: uid=${user?.uid}, email=${user?.email}');
      await user?.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));

      final edicion = await _edicionService.obtener(_edicionCreadaId ?? '');
      if (edicion == null) throw ErrorNegocio('Edición no encontrada');
      final editada = edicion.copyWith(lugar: 'Otro Lugar');
      await _edicionService.editar(editada);
      _addLog('❌ Edición editada inesperadamente por otro usuario');
      return false;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      _addLog('❌ 4.8 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  Future<bool> _registrarOtroLoginYCrearDesde() async {
    try {
      if (_edicionCreadaId == null) {
        await _crearEventoYEdicion();
      }
      await _entrar('otro2@sumate.pe', 'Otro2');
      final user = FirebaseAuth.instance.currentUser;
      _addLog('  👤 4.9 Auth actual: uid=${user?.uid}, email=${user?.email}');
      await user?.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));

      final nuevaId = await _edicionService.crearNuevaEdicionDesde(_edicionCreadaId ?? '');
      _addLog('❌ Creó nueva edición desde otro usuario, id=$nuevaId');
      return false;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      if (e is ErrorNegocio || e.toString().contains('Dart exception:')) {
        final limpio = e.toString().replaceFirst('Error: Dart exception: ', '').replaceFirst('Dart exception: ', '');
        _addLog('OK: bloqueado: $limpio');
        return true;
      }
      _addLog('❌ 4.9 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ████  Paso 5: Postulaciones  █████████████████████████████████████████████
  // ══════════════════════════════════════════════════════════════════════════

  String? _paso5EdicionId;
  String? _paso5VolPostId;

  // 5.1 ─ Preparar: crear evento con edición en curso
  Future<bool> _p5Preparar() async {
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
      return edId.isNotEmpty;
    } catch (e) {
      _addLog('❌ 5.1 ERROR: $e');
      return false;
    }
  }

  // 5.2 ─ vol@ postula como voluntario
  Future<bool> _p5VolPostula() async {
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
      return post != null && post.estado == EstadoPostulacion.enviada;
    } catch (e) {
      _addLog('❌ 5.2 ERROR: $e');
      return false;
    }
  }

  // 5.3 ─ vol@ repite postulación: debe fallar
  Future<bool> _p5VolRepite() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      final uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.voluntario,
        uid: uid,
      );
      _addLog('❌ 5.3 Duplicado NO detectado');
      return false;
    } on ErrorNegocio catch (e) {
      _addLog('OK: bloqueado: $e');
      return true;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      final msg = e.toString();
      if (msg.contains('Dart exception:')) {
        final limpio = msg.replaceFirst('Error: Dart exception: ', '').replaceFirst('Dart exception: ', '');
        _addLog('OK: bloqueado: $limpio');
        return true;
      }
      _addLog('❌ 5.3 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.4 ─ asi@ postula como asistente
  Future<bool> _p5AsiPostula() async {
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
      return post != null &&
          post.estado == EstadoPostulacion.aceptada &&
          ed?.asistentes.ocupados == 1;
    } catch (e) {
      _addLog('❌ 5.4 ERROR: $e');
      return false;
    }
  }

  // 5.5 ─ asi@ repite: debe fallar
  Future<bool> _p5AsiRepite() async {
    try {
      await _entrar('asi@sumate.pe', 'Asi');
      final uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.asistente,
        uid: uid,
      );
      _addLog('❌ 5.5 Duplicado NO detectado');
      return false;
    } on ErrorNegocio catch (e) {
      _addLog('OK: bloqueado: $e');
      return true;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      final msg = e.toString();
      if (msg.contains('Dart exception:')) {
        final limpio = msg.replaceFirst('Error: Dart exception: ', '').replaceFirst('Dart exception: ', '');
        _addLog('OK: bloqueado: $limpio');
        return true;
      }
      _addLog('❌ 5.5 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.6 ─ prueba@ lista postulantes de la edición
  Future<bool> _p5ListarPostulantes() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      final lista = await _postService.postulantesDeEdicion(_paso5EdicionId!);
      _addLog('✅ 5.6 Postulantes: ${lista.length}');
      for (final p in lista) {
        _addLog('   ${p.perfil.nombre}, rol=${p.rol.name}, '
            'estado=${p.estado.name}, hab=${p.perfil.habilidades}');
      }
      return lista.any((p) => p.rol == RolPostulacion.voluntario) &&
          lista.any((p) => p.rol == RolPostulacion.asistente);
    } catch (e) {
      _addLog('❌ 5.6 ERROR: $e');
      return false;
    }
  }

  // 5.7 ─ prueba@ acepta al voluntario
  Future<bool> _p5AceptarVol() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      await _postService.responder(
          _paso5VolPostId!, EstadoPostulacion.aceptada);
      final post = await _postService.obtener(_paso5VolPostId!);
      final ed = await _edicionService.obtener(_paso5EdicionId!);
      _addLog('✅ 5.7 Vol aceptado: estado=${post?.estado.name}, '
          'vol.ocupados=${ed?.voluntarios.ocupados}');
      return post?.estado == EstadoPostulacion.aceptada &&
          ed?.voluntarios.ocupados == 1;
    } catch (e) {
      _addLog('❌ 5.7 ERROR: $e');
      return false;
    }
  }

  // 5.8 ─ vol2@ intenta postular como voluntario: cupo lleno
  Future<bool> _p5Vol2Cupo() async {
    try {
      // Asegurar que el voluntario previo esté aceptado para que el cupo esté lleno (1 de 1)
      if (_paso5VolPostId != null) {
        final ed = await _edicionService.obtener(_paso5EdicionId!);
        if (ed != null && ed.voluntarios.ocupados == 0) {
          await _entrar('prueba@sumate.pe', 'Prueba');
          await _postService.responder(_paso5VolPostId!, EstadoPostulacion.aceptada);
        }
      }
      await _entrar('vol2@sumate.pe', 'Vol2');
      final uid = _authService.usuarioActual!.uid;
      await _postService.postular(
        edicionId: _paso5EdicionId!,
        rol: RolPostulacion.voluntario,
        uid: uid,
      );
      _addLog('❌ 5.8 Cupo lleno NO detectado');
      return false;
    } on ErrorNegocio catch (e) {
      _addLog('OK: bloqueado: $e');
      return true;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      final msg = e.toString();
      if (msg.contains('Dart exception:')) {
        final limpio = msg.replaceFirst('Error: Dart exception: ', '').replaceFirst('Dart exception: ', '');
        _addLog('OK: bloqueado: $limpio');
        return true;
      }
      _addLog('❌ 5.8 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.9 ─ prueba@ marca asistio=true al voluntario
  Future<bool> _p5MarcarAsistio() async {
    try {
      await _entrar('prueba@sumate.pe', 'Prueba');
      await _postService.marcarAsistio(_paso5VolPostId!, true);
      final post = await _postService.obtener(_paso5VolPostId!);
      _addLog('✅ 5.9 Asistió marcado OK');
      return post?.asistio == true;
    } catch (e) {
      _addLog('❌ 5.9 ERROR: $e');
      return false;
    }
  }

  // 5.10 ─ vol@: misPostulaciones e historial
  Future<bool> _p5MisPostEHistorial() async {
    try {
      await _entrar('vol@sumate.pe', 'Vol');
      final uid = _authService.usuarioActual!.uid;
      final mis = await _postService.misPostulaciones(uid);
      final hist = await _postService.historial(uid);
      _addLog('✅ 5.10 misPostulaciones=${mis.length}, historial=${hist.length}');
      final contienePost = mis.any((p) => p.id == _paso5VolPostId);
      final contieneHist = hist.any((p) => p.id == _paso5VolPostId);
      return contienePost && contieneHist;
    } catch (e) {
      _addLog('❌ 5.10 ERROR: $e');
      return false;
    }
  }

  // 5.11 ─ Negativa: vol@ intenta update directo asistio=true
  Future<bool> _p5NegAsistio() async {
    try {
      if (_paso5VolPostId == null || _paso5EdicionId == null) {
        await _p5Preparar();
        await _p5VolPostula();
      }
      await _entrar('vol@sumate.pe', 'Vol');
      final user = FirebaseAuth.instance.currentUser;
      _addLog('  👤 5.11 Auth actual: uid=${user?.uid}, email=${user?.email}');
      await user?.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));

      await FirebaseFirestore.instance
          .collection('postulaciones')
          .doc(_paso5VolPostId!)
          .update({'asistio': true});
      _addLog('❌ 5.11 Update directo asistio NO bloqueado');
      return false;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      _addLog('❌ 5.11 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.12 ─ Negativa: vol@ intenta update directo estado=aceptada
  Future<bool> _p5NegEstado() async {
    try {
      if (_paso5VolPostId == null || _paso5EdicionId == null) {
        await _p5Preparar();
        await _p5VolPostula();
      }
      await _entrar('vol@sumate.pe', 'Vol');
      final user = FirebaseAuth.instance.currentUser;
      _addLog('  👤 5.12 Auth actual: uid=${user?.uid}, email=${user?.email}');
      await user?.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));

      await FirebaseFirestore.instance
          .collection('postulaciones')
          .doc(_paso5VolPostId!)
          .update({'estado': 'aceptada'});
      _addLog('❌ 5.12 Update directo estado NO bloqueado');
      return false;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      _addLog('❌ 5.12 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.13 ─ Negativa: vol@ intenta leer postulantesDeEdicion
  Future<bool> _p5NegLeerPostulantes() async {
    try {
      if (_paso5EdicionId == null) {
        await _p5Preparar();
      }
      await _entrar('vol@sumate.pe', 'Vol');
      final user = FirebaseAuth.instance.currentUser;
      _addLog('  👤 5.13 Auth actual: uid=${user?.uid}, email=${user?.email}');
      await user?.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));

      final lista = await FirebaseFirestore.instance
          .collection('postulaciones')
          .where('edicionId', isEqualTo: _paso5EdicionId!)
          .get();
      _addLog('❌ 5.13 Lectura de postulantes NO bloqueada (${lista.docs.length} docs)');
      return false;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      _addLog('❌ 5.13 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.14 ─ Negativa: asi@ intenta increment(5) en asistentes.ocupados
  Future<bool> _p5NegIncrement() async {
    try {
      if (_paso5EdicionId == null) {
        await _p5Preparar();
      }
      await _entrar('asi@sumate.pe', 'Asi');
      final user = FirebaseAuth.instance.currentUser;
      _addLog('  👤 5.14 Auth actual: uid=${user?.uid}, email=${user?.email}');
      await user?.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));

      await FirebaseFirestore.instance
          .collection('ediciones')
          .doc(_paso5EdicionId!)
          .update({'asistentes.ocupados': FieldValue.increment(5)});
      _addLog('❌ 5.14 Increment(5) NO bloqueado');
      return false;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      _addLog('❌ 5.14 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // 5.15 ─ Plazo vencido: nueva edición con fechaLimite de ayer
  Future<bool> _p5PlazoVencido() async {
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
      return false;
    } on ErrorNegocio catch (e) {
      _addLog('OK: bloqueado: $e');
      return true;
    } catch (e) {
      if (_esPermisoDenegado(e)) {
        _addLog('OK: bloqueado por reglas');
        return true;
      }
      final msg = e.toString();
      if (msg.contains('Dart exception:')) {
        final limpio = msg.replaceFirst('Error: Dart exception: ', '').replaceFirst('Dart exception: ', '');
        _addLog('OK: bloqueado: $limpio');
        return true;
      }
      _addLog('❌ 5.15 Error no reconocido (${e.runtimeType}): $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ████  Paso 8: regresión completa  ████████████████████████████████████████
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _ejecutarTodasLasPruebas() async {
    _addLog('══════════════════════════════════════════════');
    _addLog('🚀 INICIANDO REGRESIÓN COMPLETA (PASO 8)');
    _addLog('══════════════════════════════════════════════');

    _edicionCreadaId = null;
    _paso5EdicionId = null;
    _paso5VolPostId = null;

    final pruebas = <String, Future<bool> Function()>{
      // Paso 3: Auth y Perfil
      '3.1 Registrar/Login': _registrarLogin,
      '3.2 Obtener perfil': _obtenerPerfil,
      '3.3 Actualizar perfil': _actualizarPerfil,
      '3.4 Registro duplicado': _registroDuplicado,
      '3.5 Cerrar sesión': _cerrarSesion,

      // Paso 4: Eventos y Ediciones
      '4.1 Crear evento+edición': _crearEventoYEdicion,
      '4.2 Listar abiertas': _listarAbiertas,
      '4.3 Detalle edición': _detalleEdicionCreada,
      '4.4 Mis ed/eventos': _misEdicionesYEventos,
      '4.5 Editar lugar/vol': _editarLugarYVoluntarios,
      '4.6 Cerrar/Reabrir': _cerrarReabrirEdicion,
      '4.7 Crear desde anterior': _crearNuevaDesdeAnterior,
      '4.8 Otro login editar': _registrarOtroLoginYEditar,
      '4.9 Otro login crear': _registrarOtroLoginYCrearDesde,

      // Paso 5: Postulaciones
      '5.1 Preparar': _p5Preparar,
      '5.2 Vol postula': _p5VolPostula,
      '5.3 Vol repite (dup)': _p5VolRepite,
      '5.4 Asi postula': _p5AsiPostula,
      '5.5 Asi repite (dup)': _p5AsiRepite,
      '5.6 Listar postulantes': _p5ListarPostulantes,
      '5.7 Aceptar vol': _p5AceptarVol,
      '5.8 Vol2 cupo lleno': _p5Vol2Cupo,
      '5.9 Marcar asistió': _p5MarcarAsistio,
      '5.10 MisPost/Historial': _p5MisPostEHistorial,
      '5.11 Neg: asistio': _p5NegAsistio,
      '5.12 Neg: estado': _p5NegEstado,
      '5.13 Neg: leer post': _p5NegLeerPostulantes,
      '5.14 Neg: incr(5)': _p5NegIncrement,
      '5.15 Plazo vencido': _p5PlazoVencido,
    };

    int pasadas = 0;
    final List<String> falladas = [];

    for (final entry in pruebas.entries) {
      final nombre = entry.key;
      final fn = entry.value;
      _addLog('▶️ Ejecutando: $nombre...');
      bool ok = false;
      try {
        ok = await fn();
      } catch (e) {
        _addLog('❌ Excepción inesperada en $nombre: $e');
        ok = false;
      }
      if (ok) {
        pasadas++;
        _addLog('  👉 $nombre: OK');
      } else {
        falladas.add(nombre);
        _addLog('  👉 $nombre: FALLÓ');
      }
    }

    _addLog('══════════════════════════════════════════════');
    _addLog('Resultado: $pasadas de ${pruebas.length} pruebas OK');
    if (falladas.isEmpty) {
      _addLog('🎉 ¡Todas las pruebas pasaron exitosamente!');
    } else {
      _addLog('Pruebas que fallaron:');
      for (final f in falladas) {
        _addLog('  - $f');
      }
    }
    _addLog('══════════════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba Back'),
        actions: [
          IconButton(
            tooltip: 'Limpiar log',
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () => setState(() => _log.clear()),
          ),
        ],
      ),
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
                  // ── Paso 8: regresión completa ──
                  const SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Paso 8: regresión completa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF473C33),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _ejecutarTodasLasPruebas,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFABC270),
                      foregroundColor: const Color(0xFF473C33),
                    ),
                    child: const Text(
                      'Ejecutar todas las pruebas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  // ── Paso 3 ──
                  ElevatedButton(onPressed: _registrarLogin, child: const Text('3.1 Registrar/Login')),
                  ElevatedButton(onPressed: _obtenerPerfil, child: const Text('3.2 Obtener perfil')),
                  ElevatedButton(onPressed: _actualizarPerfil, child: const Text('3.3 Actualizar perfil')),
                  ElevatedButton(onPressed: _registroDuplicado, child: const Text('3.4 Registro duplicado')),
                  ElevatedButton(onPressed: _cerrarSesion, child: const Text('3.5 Cerrar sesión')),
                  const Divider(),
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
