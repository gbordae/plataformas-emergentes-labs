// lib/pruebas/prueba_back.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/auth/servicios/auth_service.dart';
import '../features/perfil/servicios/usuario_service.dart';
import '../features/eventos/servicios/evento_service.dart';
import '../features/eventos/servicios/edicion_service.dart';
import '../features/eventos/modelos/evento.dart';
import '../features/eventos/modelos/edicion.dart';
import '../features/eventos/modelos/convocatoria.dart';
import '../core/enums.dart';
import '../core/errores.dart';

/// Pantalla de prueba que ejecuta los pasos 3 y 4 del backend.
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

  final List<String> _log = [];

  void _addLog(String msg) => setState(() => _log.add(msg));

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba Back')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(_log[i]),
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Paso 3 botones
                  ElevatedButton(onPressed: _registrarLogin, child: const Text('1. Registrar/Login')),
                  ElevatedButton(onPressed: _obtenerPerfil, child: const Text('2. Obtener perfil')),
                  ElevatedButton(onPressed: _actualizarPerfil, child: const Text('3. Actualizar perfil')),
                  ElevatedButton(onPressed: _registroDuplicado, child: const Text('4. Registro duplicado')),
                  ElevatedButton(onPressed: _cerrarSesion, child: const Text('5. Cerrar sesión')),
                  // Paso 4 botones
                  ElevatedButton(onPressed: _crearEventoYEdicion, child: const Text('6. Crear evento y edición')),
                  ElevatedButton(onPressed: _listarAbiertas, child: const Text('7. Listar abiertas')),
                  ElevatedButton(onPressed: _detalleEdicionCreada, child: const Text('8. Detalle edición')),
                  ElevatedButton(onPressed: _misEdicionesYEventos, child: const Text('9. Mis ediciones/eventos')),
                  ElevatedButton(onPressed: _editarLugarYVoluntarios, child: const Text('10. Editar lugar/voluntarios')),
                  ElevatedButton(onPressed: _cerrarReabrirEdicion, child: const Text('11. Cerrar/Reabrir')),
                  ElevatedButton(onPressed: _crearNuevaDesdeAnterior, child: const Text('12. Crear nueva desde anterior')),
                  ElevatedButton(onPressed: _registrarOtroLoginYEditar, child: const Text('13. Otro login editar')),
                  ElevatedButton(onPressed: _registrarOtroLoginYCrearDesde, child: const Text('14. Otro login crear desde')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
