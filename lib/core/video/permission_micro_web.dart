import 'dart:js_interop';

/// `navigator.permissions`, absent des navigateurs qui ne connaissent pas
/// l'API.
@JS('navigator.permissions')
external _Permissions? get _permissions;

extension type _Permissions._(JSObject _) implements JSObject {
  external JSPromise<_Etat> query(JSObject descripteur);
}

extension type _Etat._(JSObject _) implements JSObject {
  external String get state;
}

/// SITUATIONS-GRAVES (11/11/2026) : l'etat de la permission du micro, sans
/// rien demander ni ouvrir (`navigator.permissions.query`) : `granted`,
/// `denied`, `prompt`, ou `null` quand le navigateur ne sait pas le dire
/// (Firefox ancien, API absente).
Future<String?> lirePermissionMicro() async {
  final _Permissions? permissions = _permissions;
  if (permissions == null) return null;
  try {
    final JSObject descripteur =
        <String, String>{'name': 'microphone'}.jsify()! as JSObject;
    final _Etat etat = await permissions.query(descripteur).toDart;
    return etat.state;
  } catch (_) {
    return null;
  }
}
