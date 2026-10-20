// Enums del dominio de Súmate.
//
// En Firestore se guarda siempre `enum.name` (String ASCII, sin tildes).
// La propiedad `etiqueta` devuelve el texto legible para la UI.
// El método estático `desde` convierte un String de Firestore al enum,
// retornando un valor por defecto si el String no coincide con ningún valor.


// ── Tipo de evento ──────────────────────────────────────────────────────────
/// Categoría del evento (hackathon, ponencia, etc.).
enum TipoEvento {
  hackathon('Hackathon'),
  ponencia('Ponencia'),
  lanzamiento('Lanzamiento'),
  campana('Campaña'), // sin tilde en el name para Firestore
  conferencia('Conferencia'),
  otro('Otro');

  final String etiqueta;
  const TipoEvento(this.etiqueta);

  /// Convierte un String de Firestore al enum; devuelve [otro] si no coincide.
  static TipoEvento desde(String? valor) =>
      TipoEvento.values.firstWhere((e) => e.name == valor, orElse: () => otro);
}

// ── Modalidad ───────────────────────────────────────────────────────────────
/// Modalidad de la edición (presencial, remoto o híbrido).
enum Modalidad {
  presencial('Presencial'),
  remoto('Remoto'),
  hibrido('Híbrido'); // name = 'hibrido', sin tilde

  final String etiqueta;
  const Modalidad(this.etiqueta);

  static Modalidad desde(String? valor) =>
      Modalidad.values.firstWhere((e) => e.name == valor, orElse: () => presencial);
}

// ── Estado de edición ───────────────────────────────────────────────────────
/// Estado del ciclo de vida de una edición.
enum EstadoEdicion {
  abierta('Abierta'),
  cerrada('Cerrada'),
  finalizada('Finalizada');

  final String etiqueta;
  const EstadoEdicion(this.etiqueta);

  static EstadoEdicion desde(String? valor) =>
      EstadoEdicion.values.firstWhere((e) => e.name == valor, orElse: () => abierta);
}

// ── Rol de postulación ──────────────────────────────────────────────────────
/// Rol con el que un usuario postula a una edición.
enum RolPostulacion {
  voluntario('Voluntario'),
  asistente('Asistente');

  final String etiqueta;
  const RolPostulacion(this.etiqueta);

  static RolPostulacion desde(String? valor) =>
      RolPostulacion.values.firstWhere((e) => e.name == valor, orElse: () => asistente);
}

// ── Estado de postulación ───────────────────────────────────────────────────
/// Estado de revisión de una postulación.
enum EstadoPostulacion {
  enviada('En espera'), // la UI muestra "En espera", no "enviada"
  aceptada('Aceptada'),
  rechazada('Rechazada');

  final String etiqueta;
  const EstadoPostulacion(this.etiqueta);

  static EstadoPostulacion desde(String? valor) =>
      EstadoPostulacion.values.firstWhere((e) => e.name == valor, orElse: () => enviada);
}
