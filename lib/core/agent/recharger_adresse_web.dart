import 'dart:js_interop';

@JS('location')
external _Adresse get _adresse;

/// `window.location`, reduit au seul appel utile.
extension type _Adresse._(JSObject _) implements JSObject {
  external void reload();
}

/// Recharge la page a la meme adresse : le jeton reste dans l'URL, et
/// `main()` relance l'ouverture de la session d'agent.
void rechargerAdresse() => _adresse.reload();
