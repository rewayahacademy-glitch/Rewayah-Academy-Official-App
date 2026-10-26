import 'dart:js_interop';

@JS('document')
external _Document get _document;

/// `document`, reduit au seul champ utile.
extension type _Document._(JSObject _) implements JSObject {
  external String get baseURI;
}

/// `version.json` relatif a la base de la page (`<base href>`), et non a la
/// route courante : `/salle/abc` ne doit pas lire `/salle/version.json`.
Uri? adresseVersion() => Uri.parse(_document.baseURI).resolve('version.json');
