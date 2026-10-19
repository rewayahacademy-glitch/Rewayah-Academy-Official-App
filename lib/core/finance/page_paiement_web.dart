import 'dart:js_interop';

@JS('location')
external _Adresse get _adresse;

/// `window.location`, reduit a l'appel utile.
extension type _Adresse._(JSObject _) implements JSObject {
  external void assign(String adresse);
}

/// Remplace l'application par la page du prestataire, dans le meme onglet.
void ouvrirPagePaiement(Uri page) => _adresse.assign(page.toString());

/// L'adresse complete de [route] dans l'application (routage par `#`).
String adresseApplication(String route) {
  final Uri base = Uri.base;
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.port,
    path: base.path,
    fragment: route,
  ).toString();
}
