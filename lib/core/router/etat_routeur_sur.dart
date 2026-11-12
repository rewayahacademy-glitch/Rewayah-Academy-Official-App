// GOROUTERSTATE-SUR (garde-cap, 12/11/2026) : la seule lecture de l'etat du
// routeur (adresse, parametres, `extra`) permise dans lib/, sans risque de
// boucle infinie.
//
// `GoRouterState.of` (go_router 18.0.1, state.dart:132) remonte de navigateur
// en navigateur dans une boucle `while (true)`. Quand la route du widget n'est
// pas une page du routeur (une feuille du bas, un dialogue, une
// `MaterialPageRoute` poussee par `Navigator.push`), il remonte au navigateur
// de la coquille ; si la page de ce navigateur n'a pas d'etat associe,
// `Navigator.maybeOf(contexte du navigateur)` lui rend le MEME navigateur et
// la boucle ne finit jamais : rien n'est leve, aucun gestionnaire ne le voit,
// l'onglet gele puis le navigateur le tue (CRASH-MON-ESPACE, cause trouvee
// par E le 12/11). Un `try` autour n'y change rien.
//
// [etatRouteurSur] n'appelle `GoRouterState.of` que pour une route qui est
// une page du routeur : la page est alors trouvee au premier tour, sans
// remontee. Sinon, il rend l'etat de la page du dessus du routeur
// (`GoRouter.state`), lu directement, sans remontee non plus : c'est la page
// sous la feuille ou sous la page poussee.
//
// Un test de garde (test/core/router/etat_routeur_sur_test.dart) interdit
// tout autre appel de `GoRouterState.of` dans lib/.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// L'etat du routeur pour [context], ou `null` hors du routeur. Jamais de
/// boucle : voir l'en-tete du fichier.
GoRouterState? etatRouteurSur(BuildContext context) {
  final GoRouter? routeur = GoRouter.maybeOf(context);
  if (routeur == null) return null;
  if (ModalRoute.of(context)?.settings is Page<Object?>) {
    try {
      return GoRouterState.of(context);
    } on GoError {
      return null;
    }
  }
  // Feuille du bas, dialogue, page poussee hors du routeur : l'etat de la
  // page du dessus, sans remontee.
  return routeur.state;
}

/// L'adresse de [context] ([etatRouteurSur]), ou `null` hors du routeur.
Uri? adresseRouteurSur(BuildContext context) => etatRouteurSur(context)?.uri;

/// Un parametre de requete de l'adresse de [context], ou `null`.
String? parametreRouteurSur(BuildContext context, String cle) =>
    adresseRouteurSur(context)?.queryParameters[cle];
