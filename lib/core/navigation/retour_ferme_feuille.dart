import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// RETOUR-FERME-FEUILLE (garde-cap, 12/11/2026) : le retour du NAVIGATEUR
/// ferme d'abord la feuille du bas ouverte, au lieu de changer d'onglet.
///
/// Le retour Android le fait deja : `GoRouterDelegate.popRoute` appelle
/// `maybePop` sur le navigateur de l'onglet, ou vit la feuille. Le retour du
/// navigateur web, lui, arrive comme une nouvelle adresse
/// (`pushRouteInformation`) : le routeur changeait d'onglet et la feuille
/// restait montee, hors scene, dans l'onglet quitte.
///
/// [RetourFermeFeuille] est un observateur du binding inscrit AVANT le
/// routeur (`lib/main.dart`, avant `runApp`) : il voit la nouvelle adresse
/// le premier. Seuls les retours et avances du navigateur passent par la ;
/// un `go` ou un `push` de l'application ne passe jamais par le binding, les
/// liens d'une feuille ne sont donc pas touches.
///
/// - Une feuille est A L'ECRAN : elle se ferme (`maybePop`, qui respecte une
///   `PopScope` qui l'interdit), l'onglet ne change pas, et l'adresse
///   courante est republiee dans le navigateur (`replace: false`) : le
///   retour suivant mene a l'onglet precedent.
/// - Aucune feuille a l'ecran : rien n'est intercepte.
class RetourFermeFeuille with WidgetsBindingObserver {
  RetourFermeFeuille._();

  /// L'observateur unique.
  static final RetourFermeFeuille instance = RetourFermeFeuille._();

  bool _inscrit = false;

  /// Inscrit l'observateur (sans effet au second appel). A appeler avant
  /// `runApp`, pour passer avant l'observateur du routeur.
  static void installer() {
    if (instance._inscrit) return;
    instance._inscrit = true;
    WidgetsBinding.instance.addObserver(instance);
  }

  /// Retire l'observateur (tests).
  static void desinstaller() {
    if (!instance._inscrit) return;
    instance._inscrit = false;
    WidgetsBinding.instance.removeObserver(instance);
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      FeuillesOuvertes.fermerFeuilleVisible();
}

/// Le registre des feuilles du bas ouvertes, chacune avec son contexte et
/// sa presence a l'ecran. Une feuille y entre a son premier cadre et en sort
/// a son demontage, quel que soit le chemin de fermeture (bouton, voile,
/// glissement, navigateur retire) : le registre ne fuit pas.
abstract final class FeuillesOuvertes {
  static final List<FeuilleInscrite> _pile = <FeuilleInscrite>[];

  /// Le nombre de feuilles inscrites (tests).
  static int get nombre => _pile.length;

  /// Inscrit une feuille ; la retirer par [FeuilleInscrite.retirer].
  static FeuilleInscrite inscrire({
    required BuildContext Function() contexte,
    required bool Function() enScene,
  }) {
    final FeuilleInscrite f = FeuilleInscrite._(contexte, enScene);
    _pile.add(f);
    return f;
  }

  /// Ferme la feuille du dessus si elle est a l'ecran. Vrai quand une
  /// feuille etait a l'ecran : le retour est alors consomme, meme si la
  /// feuille interdit sa fermeture (comme un retour Android).
  static Future<bool> fermerFeuilleVisible() async {
    FeuilleInscrite? visible;
    for (final FeuilleInscrite f in _pile.reversed) {
      if (f._enScene()) {
        visible = f;
        break;
      }
    }
    if (visible == null) return false;
    final BuildContext contexte = visible._contexte();
    if (!contexte.mounted) return false;
    final NavigatorState navigateur = Navigator.of(contexte);
    final Uri? adresse = GoRouter.maybeOf(contexte)
        ?.routerDelegate
        .currentConfiguration
        .uri;
    await navigateur.maybePop();
    // La barre d'adresse a deja recule : on y remet l'adresse courante, en
    // nouvelle entree, pour que le retour suivant mene a l'onglet precedent.
    if (adresse != null) {
      unawaited(
        SystemNavigator.routeInformationUpdated(uri: adresse, replace: false),
      );
    }
    return true;
  }
}

/// Une feuille inscrite dans [FeuillesOuvertes].
class FeuilleInscrite {
  FeuilleInscrite._(this._contexte, this._enScene);

  final BuildContext Function() _contexte;
  final bool Function() _enScene;

  /// Retire la feuille du registre (sans effet au second appel).
  void retirer() => FeuillesOuvertes._pile.remove(this);
}
