import 'dart:js_interop';

@JS('navigator.userAgent')
external String? get _agent;

/// L'agent utilisateur du navigateur ; vide s'il est illisible.
String agentUtilisateur() {
  try {
    return _agent ?? '';
  } catch (_) {
    return '';
  }
}

/// Dans un navigateur, le systeme se lit dans l'agent.
String systemeNatif() => '';
