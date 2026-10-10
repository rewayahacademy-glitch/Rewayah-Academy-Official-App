import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/page_immersive.dart';
import 'classe_live_page.dart';
import 'encre_salle.dart';

/// Les chemins d'Agent E, sous le prefixe reserve `/tc/`.
///
/// **Aucun `GoRouter` n'est construit ici** (decision D-04) :
/// `tool/verifier_jetons.dart` fait echouer la CI si un second fichier de `lib/`
/// en construit un, et `app_router.dart` reste le seul. [routesTcE] **retourne**
/// des routes ; c'est Agent Z qui les appelle, promeut les constantes dans
/// `routes.dart` et ajuste `redirection.dart`.
///
/// Piege nomme, que cette classe ne peut pas resoudre seule : `redirection.dart`
/// renvoie toute route hors prefixe de role vers la racine du role. **Un ecran
/// pose sans cet ajustement sera inatteignable.** Et une route sans entree de
/// navigation n'existe pas -- or `nav_shell.dart` est plafonne a quatre
/// destinations par assertion, et l'enseignant en a deja quatre. Le point
/// d'entree de la Classe Live n'est donc pas une destination de barre : c'est le
/// bouton « Rejoindre » du Groupe, et la barre compacte « Cours en cours ».
abstract final class RoutesTcE {
  /// La Classe Live.
  ///
  /// **Elle n'est ni memorisable ni partageable** (ADR-005) : le contexte de
  /// seance voyage par `extra`, qui n'est pas serialise dans l'URL et ne survit
  /// pas a un rechargement. Une adresse copiee arrive donc sans contexte, et
  /// repart.
  static const String classe = '/tc/classe';
}

/// Les routes d'Agent E. **Retourne des routes, ne construit pas de routeur.**
List<RouteBase> routesTcE() => <RouteBase>[
  GoRoute(
    path: RoutesTcE.classe,
    builder: (BuildContext _, GoRouterState etat) {
      final Object? contexte = etat.extra;
      if (contexte is ContexteClasseLive) {
        return ClasseLivePage(contexte: contexte);
      }
      // Arriver ici sans contexte est le cas NORMAL d'une adresse collee : on
      // ne devine pas une seance, on le dit. Agent Z branchera la redirection
      // vers la racine du role, comme `redirection.dart` le fait deja pour
      // `/salle` sans billet.
      return const _ClasseSansContexte();
    },
  ),
];

/// La Classe Live ouverte sans contexte de seance.
class _ClasseSansContexte extends StatelessWidget {
  const _ClasseSansContexte();

  @override
  Widget build(BuildContext context) => PageImmersive(
    registre: RegistreImmersif.salle,
    child: Center(
      child: Text(
        t.tc.classe.attente.refus,
        textAlign: TextAlign.center,
        style: styleDuFond(context, Theme.of(context).textTheme.titleMedium),
      ),
    ),
  );
}
