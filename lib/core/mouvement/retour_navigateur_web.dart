import 'dart:js_interop';

@JS('addEventListener')
external void _ecouter(String type, JSFunction rappel);

/// Dans un navigateur : [surRetour] est appele a chaque `popstate`, c'est-a-
/// dire a chaque retour (ou avance) demande par le navigateur : bouton, geste
/// de Safari, raccourci clavier. Un retour par la fleche de l'application
/// n'en declenche aucun : le routeur ecrit l'adresse sans remonter
/// l'historique.
void ecouterRetourNavigateur(void Function() surRetour) {
  _ecouter('popstate', surRetour.toJS);
}
