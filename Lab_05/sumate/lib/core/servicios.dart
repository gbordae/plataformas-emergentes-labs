// Localizador central de servicios de Súmate.
// Expone instancias únicas (static final) con constructores sin argumentos.
// No modifica ninguna firma de backend.

import '../features/auth/servicios/auth_service.dart';
import '../features/eventos/servicios/edicion_service.dart';
import '../features/eventos/servicios/evento_service.dart';
import '../features/perfil/servicios/usuario_service.dart';
import '../features/postulaciones/servicios/postulacion_service.dart';

class Servicios {
  Servicios._();

  static final AuthService auth = AuthService();
  static final UsuarioService usuario = UsuarioService();
  static UsuarioService get usuarios => usuario;
  static final EventoService evento = EventoService();
  static final EdicionService edicion = EdicionService();
  static final PostulacionService postulacion = PostulacionService();
  static PostulacionService get postulaciones => postulacion;
}
