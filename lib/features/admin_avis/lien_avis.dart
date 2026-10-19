// L'adresse complete d'un lien d'avis, a remettre aux familles
// (DECISION-AVIS-2026-10-19, choix 3 : `/avis/<jeton>` dans l'application).
//
// L'application ne porte pas d'adresse publique en configuration : sur le Web,
// elle prend celle de la page ouverte par la direction ; ailleurs (mobile,
// bureau, tests), l'adresse de production de l'application. Flutter Web range
// l'itineraire apres un « # » tant qu'aucune strategie d'adresse n'est
// choisie : on suit ce que la page ouverte montre (fragment commencant par
// « / »).

import '../../core/router/routes.dart';

/// L'adresse publique de l'application quand la page n'en fournit pas
/// (`docs/current/CONFIGURATION_BASELINE_2026-09-23.md`, alias Vercel).
const String origineParDefaut = 'https://rewayah-academy.vercel.app';

/// L'adresse complete du formulaire d'avis pour [jeton], d'apres l'adresse de
/// la page ouverte [base] (par defaut `Uri.base`). Pure, testee.
String lienAvisPour(String jeton, {Uri? base}) {
  final Uri b = base ?? Uri.base;
  final bool web =
      (b.scheme == 'http' || b.scheme == 'https') && b.host.isNotEmpty;
  final String origine = web ? b.origin : origineParDefaut;
  final String chemin = Routes.avisPour(jeton);
  // Hors du Web, ou quand la page ouverte range son itineraire apres « # » :
  // meme forme. Seule une page sans fragment d'itineraire (strategie par
  // chemin) recoit l'adresse sans « # ».
  final bool parChemin =
      web && b.fragment.isEmpty && b.path != '/' && b.path.isNotEmpty;
  return parChemin ? '$origine$chemin' : '$origine/#$chemin';
}
