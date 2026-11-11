import 'dart:js_interop';

@JS('window.addEventListener')
external void _ecouter(String type, JSFunction rappel);

@JS('window.removeEventListener')
external void _oublier(String type, JSFunction rappel);

extension type _EvenementFermeture._(JSObject _) implements JSObject {
  external void preventDefault();
  external set returnValue(String valeur);
}

/// Le rappel `beforeunload`, garde pour pouvoir le retirer.
JSFunction? _rappel;

/// Arme ou retire la question native du navigateur avant de fermer ou de
/// recharger l'onglet. `preventDefault` et `returnValue` : les deux formes
/// que les navigateurs reconnaissent ; le texte affiche est le leur.
void poserGardeFermeture({required bool armee}) {
  final JSFunction? actuel = _rappel;
  if (armee) {
    if (actuel != null) return;
    final JSFunction rappel = ((_EvenementFermeture evenement) {
      evenement.preventDefault();
      evenement.returnValue = '';
    }).toJS;
    _rappel = rappel;
    _ecouter('beforeunload', rappel);
    return;
  }
  if (actuel == null) return;
  _oublier('beforeunload', actuel);
  _rappel = null;
}
