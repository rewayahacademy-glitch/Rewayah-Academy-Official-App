import 'dart:js_interop';

/// `Intl.DateTimeFormat`, reduit au seul appel utile.
@JS('Intl.DateTimeFormat')
extension type _Formateur._(JSObject _) implements JSObject {
  external factory _Formateur();

  external _Options resolvedOptions();
}

/// Les options resolues du formateur : le fuseau de l'appareil.
extension type _Options._(JSObject _) implements JSObject {
  external JSString? get timeZone;
}

/// Le fuseau IANA de l'appareil (« Europe/Paris »), ou `null` quand le
/// navigateur ne le donne pas.
String? fuseauIanaAppareil() {
  try {
    final String? zone = _Formateur().resolvedOptions().timeZone?.toDart;
    return zone == null || zone.isEmpty ? null : zone;
  } on Object {
    return null;
  }
}
