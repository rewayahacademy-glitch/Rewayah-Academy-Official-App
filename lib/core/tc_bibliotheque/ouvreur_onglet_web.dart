import 'dart:js_interop';

/// La fenetre rendue par `window.open`, reduite a ce qui sert : couper le
/// lien avec la page d'origine (`opener`), comme `rel="noopener"`.
extension type _Fenetre._(JSObject _) implements JSObject {
  external set opener(JSAny? valeur);
}

@JS('open')
external _Fenetre? _ouvrir(String adresse, String cible);

/// Ouvre [lien] dans un nouvel onglet ; faux quand le navigateur bloque
/// l'ouverture (fenetre intruse). Le lien n'est ni garde ni journalise.
bool _ouvrirDansUnOnglet(Uri lien) {
  final _Fenetre? fenetre = _ouvrir(lien.toString(), '_blank');
  if (fenetre == null) return false;
  fenetre.opener = null;
  return true;
}

/// Dans un navigateur : l'ouvreur d'onglet.
bool Function(Uri)? ouvreurOngletNatif() => _ouvrirDansUnOnglet;
