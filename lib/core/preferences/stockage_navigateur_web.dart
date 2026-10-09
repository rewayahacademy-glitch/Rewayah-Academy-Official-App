import 'dart:js_interop';

import 'stockage_cle_valeur.dart';

@JS('localStorage')
external _StockageWeb? get _stockageWeb;

/// Le `localStorage` du navigateur, reduit aux deux appels utiles.
extension type _StockageWeb._(JSObject _) implements JSObject {
  external String? getItem(String clef);
  external void setItem(String clef, String valeur);
}

/// Le `localStorage` vu comme un [AccesCleValeur]. L'acces a
/// `window.localStorage` lui-meme peut lever une exception (donnees de site
/// bloquees) : il est donc relu a chaque appel, dans la garde de
/// [StockagePreferencesCleValeur].
final class _AccesLocalStorage implements AccesCleValeur {
  const _AccesLocalStorage();

  @override
  String? lire(String clef) => _stockageWeb?.getItem(clef);

  @override
  void ecrire(String clef, String valeur) =>
      _stockageWeb?.setItem(clef, valeur);
}

/// Le `localStorage` du navigateur : durable pour cet appareil et ce site,
/// **non sensible**. La logique (secours en memoire, pannes absorbees) est
/// celle de [StockagePreferencesCleValeur], testee hors navigateur.
class StockagePreferencesNavigateur extends StockagePreferencesCleValeur {
  /// Cree le stockage.
  StockagePreferencesNavigateur() : super(const _AccesLocalStorage());
}
