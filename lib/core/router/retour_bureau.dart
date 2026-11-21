import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'etat_routeur_sur.dart';
import 'fil_ariane.dart';
import 'historique_navigateur.dart';
import 'routes.dart';

/// Recule dans l'historique du navigateur ; `false` hors du web. Remplacable
/// dans un test, qui n'a pas de navigateur.
@visibleForTesting
bool Function() reculerHistorique = reculerDansLeNavigateur;

/// Le retour du bureau (fleche de la coquille, touche retour du systeme) :
/// la page empilee se retire ; sinon le parent logique ([retourLogiqueBureau]).
void retourBureau(BuildContext context) {
  final GoRouter? routeur = GoRouter.maybeOf(context);
  if (routeur == null) return;
  if (routeur.canPop()) {
    // Etape (f) : dans un navigateur, la fleche fait ce que fait son bouton
    // de retour (elle recule dans l'historique), sinon l'entree de la page
    // fermee reste et le retour du navigateur la rouvre.
    if (!reculerHistorique()) routeur.pop();
    return;
  }
  final Uri adresse =
      adresseRouteurSur(context) ??
      routeur.routerDelegate.currentConfiguration.uri;
  final String? cible = retourLogiqueBureau(
    adresse: adresse,
    plan: ContexteFilAriane.de(context),
  );
  if (cible != null) routeur.go(cible);
}

/// BUREAU-NAV (contrat de navigation du 20/11/2026, §4 et §5) : ou mene le
/// retour du bureau quand il n'y a **rien a depiler** (lien direct,
/// rechargement, page ouverte par la barre laterale).
///
/// Quand un ecran a ete empile (`push`), le retour le retire simplement : la
/// page d'en dessous revient avec son adresse, donc ses filtres. Cette
/// fonction ne sert qu'apres un rechargement ou un lien direct : la pile est
/// alors reconstruite par l'arbre (le parent logique), jamais dans le vide.
///
/// - Une page de detail (`/admin/personnes/candidatures/CAND-…`) : sa liste.
///   Quand l'adresse porte la file d'ou l'on vient (`depuis=liste`, BE-SUIVANT),
///   la liste rouvre avec ce filtre et ce tri.
/// - Une page plus profonde qu'un onglet : son parent nomme dans l'arbre.
/// - La racine d'une rubrique, ou un onglet de la barre laterale : l'Accueil.
/// - L'Accueil : `null`, il n'y a pas de retour.
String? retourLogiqueBureau({required Uri adresse, PlanFil? plan}) {
  final String page = _sansBarreFinale(adresse.path);
  if (page.isEmpty || page == Routes.admin) return null;

  const String candidatures = Routes.adminPersonnesCandidatures;
  if (page.startsWith('$candidatures/') &&
      page != Routes.adminPersonnesCreneauxEntretien) {
    final Map<String, String> file = <String, String>{
      if (adresse.queryParameters['depuis'] == 'liste')
        ...adresse.queryParameters,
    }..remove('depuis');
    return file.isEmpty
        ? candidatures
        : Uri(path: candidatures, queryParameters: file).toString();
  }

  if (plan == null) return Routes.admin;
  final List<SegmentFil> ancetres = ancetresFil(plan: plan, chemin: page);
  // Un seul ancetre : la page est un onglet de sa rubrique (ou la rubrique
  // elle-meme) ; la racine d'une rubrique mene a l'Accueil (§4, point 4).
  // Remonter a la rubrique rouvrirait souvent la meme page (`/admin/personnes`
  // redirige vers Candidatures).
  if (ancetres.length <= 1) return Routes.admin;
  return ancetres.last.chemin ?? Routes.admin;
}

String _sansBarreFinale(String chemin) =>
    chemin.length > 1 && chemin.endsWith('/')
    ? chemin.substring(0, chemin.length - 1)
    : chemin;
