import 'dart:js_interop';

@JS('window.history')
external _Historique get _historique;

/// `window.history`, reduit au seul appel utile.
extension type _Historique._(JSObject _) implements JSObject {
  external void back();
}

/// Recule d'une entree dans l'historique du navigateur, comme son bouton de
/// retour : le routeur retire alors la page empilee. `false` si le navigateur
/// le refuse : l'appelant retire la page lui-meme.
bool reculerDansLeNavigateur() {
  try {
    _historique.back();
    return true;
  } on Object {
    return false;
  }
}
