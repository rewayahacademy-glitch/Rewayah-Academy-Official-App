import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'preferences_locales.dart';

/// Sur le web : le `localStorage` du navigateur (valeurs non sensibles
/// seulement, comme tout [StockagePreferences]).
StockagePreferences stockageNavigateur() => const _StockageLocalStorage();

class _StockageLocalStorage implements StockagePreferences {
  const _StockageLocalStorage();

  /// Prefixe des clefs, pour ne pas croiser d'autres valeurs de l'origine.
  static const String _prefixe = 'rewayah.';

  JSObject get _stockage => globalContext['localStorage']! as JSObject;

  @override
  Future<String?> lire(String clef) async => _stockage
      .callMethod<JSString?>('getItem'.toJS, '$_prefixe$clef'.toJS)
      ?.toDart;

  @override
  Future<void> ecrire(String clef, String valeur) async {
    _stockage.callMethod<JSAny?>(
      'setItem'.toJS,
      '$_prefixe$clef'.toJS,
      valeur.toJS,
    );
  }
}
