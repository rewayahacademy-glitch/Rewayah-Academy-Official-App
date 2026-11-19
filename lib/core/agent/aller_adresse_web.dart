import 'dart:js_interop';

@JS('location')
external _Adresse get _adresse;

/// `window.location`, reduit au seul appel utile.
extension type _Adresse._(JSObject _) implements JSObject {
  external void assign(String adresse);
}

/// Envoie le navigateur a [adresse] (la page courante reste dans l'historique).
void allerAdresse(String adresse) => _adresse.assign(adresse);
