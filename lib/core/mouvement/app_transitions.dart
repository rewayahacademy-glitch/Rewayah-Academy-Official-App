// TRANSITIONS (directeur, 11/11/2026 ; conseil de Fable et arbitrages du
// garde-cap) : le catalogue UNIQUE des transitions de l'application.
//
// Grammaire (docs/current/DECISION-MOUVEMENT-2026-11-11.md) :
//   - horizontal = avancer ou reculer dans une hierarchie (axe partage), en
//     miroir en arabe ;
//   - vertical = une surface temporaire qui monte du bas (feuille) ;
//   - profondeur (zoom leger et fondu) = une fenetre au-dessus (dialogue) ;
//   - meme niveau (onglets) = fondu enchaine, sans glissement.
// Jamais deux axes pour la meme relation. Sortie environ 2/3 de l'entree.
// Mouvement reduit : rien (duree nulle). Aucune transition n'est definie hors
// de ce fichier (test-garde `test/mouvement/catalogue_transitions_test.dart`).
//
// Il est applique a TROIS endroits, jamais ecran par ecran :
//   1. le theme (`AppTheme.pour`, `pageTransitionsTheme`) : toutes les pages
//      Material, donc toutes les routes `builder` du routeur ;
//   2. `pageGlissee` (`transitions.dart`) : les routes `pageBuilder` ;
//   3. `AppBottomSheet` : feuilles du bas et dialogues.
// La salle (`/salle`) appartient a Fable : ses transitions d'entree et de
// sortie ne sont pas ici.

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_gabarit.dart';
import '../theme/app_mouvement.dart';

/// Les types de transition du catalogue, par relation entre deux surfaces.
enum TypeTransition {
  /// Deux destinations de meme niveau (onglets) : fondu enchaine.
  onglet,

  /// Descente vers un detail, et retour : axe partage horizontal.
  descente,

  /// Une fenetre au-dessus (dialogue, confirmation) : zoom leger et fondu.
  fenetre,

  /// Une surface temporaire du bas : montee, fermeture en tirant.
  feuille,
}

/// Le catalogue : durees, distances et constructeurs de chaque type.
abstract final class AppTransitions {
  /// Part de la transition pendant laquelle la surface quittee s'efface,
  /// avant que la nouvelle n'apparaisse (fondu en passage, LG-FLASH) : jamais
  /// deux contenus superposes.
  static const double partEffacement = 0.3;

  /// Echelle de depart d'une fenetre (zoom leger).
  static const double echelleFenetre = 0.94;

  /// Vrai sur un ecran large (classe etendue ou plus) : la descente y est
  /// plus courte et plus breve.
  static bool large(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppGabarit.seuilEtendu;

  /// Duree d'entree d'une descente : telephone [AppMouvement.descente],
  /// ordinateur [AppMouvement.navigation].
  static Duration dureeDescente(BuildContext context) =>
      large(context) ? AppMouvement.navigation : AppMouvement.descente;

  /// La sortie dure environ les deux tiers de l'entree.
  static Duration sortieDe(Duration entree) =>
      Duration(microseconds: (entree.inMicroseconds * 2) ~/ 3);

  /// La course de l'axe partage : courte sur ordinateur.
  static double course(BuildContext context) => large(context)
      ? AppMouvement.courseAxePartageLarge
      : AppMouvement.courseAxePartage;

  /// Axe partage horizontal. La page qui entre glisse depuis le bord de
  /// lecture et apparait ; la page recouverte glisse en sens inverse et
  /// s'efface d'abord. Le retour joue l'inverse. En arabe, le sens s'inverse.
  static Widget descente(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaire,
    Widget enfant,
  ) {
    final double sens = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    final double dx = course(context) * sens;
    final Animation<double> entree = CurvedAnimation(
      parent: animation,
      curve: AppMouvement.entree,
      reverseCurve: AppMouvement.sortie,
    );
    final Animation<double> apparition = CurvedAnimation(
      parent: animation,
      curve: const Interval(partEffacement, 1, curve: AppMouvement.selection),
      reverseCurve: const Interval(
        partEffacement,
        1,
        curve: AppMouvement.selection,
      ),
    );
    final Animation<double> recouvrement = CurvedAnimation(
      parent: secondaire,
      curve: AppMouvement.entree,
      reverseCurve: AppMouvement.sortie,
    );
    final Animation<double> effacement = ReverseAnimation(
      CurvedAnimation(
        parent: secondaire,
        curve: const Interval(0, partEffacement, curve: AppMouvement.selection),
      ),
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[entree, recouvrement]),
        builder: (BuildContext _, Widget? enfantFige) => Transform.translate(
          offset: Offset(dx * (1 - entree.value) - dx * recouvrement.value, 0),
          child: enfantFige,
        ),
        child: FadeTransition(
          opacity: effacement,
          child: FadeTransition(opacity: apparition, child: enfant),
        ),
      ),
    );
  }

  /// Fondu enchaine : la surface quittee s'efface d'abord, puis la nouvelle
  /// apparait, sans glissement.
  static Widget fonduEnchaine(
    Animation<double> animation,
    Animation<double> secondaire,
    Widget enfant,
  ) => FadeTransition(
    opacity: ReverseAnimation(
      CurvedAnimation(
        parent: secondaire,
        curve: const Interval(0, partEffacement, curve: AppMouvement.selection),
      ),
    ),
    child: FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(partEffacement, 1, curve: AppMouvement.selection),
      ),
      child: enfant,
    ),
  );

  /// Fenetre au-dessus : zoom leger et fondu.
  static Widget zoomFondu(Animation<double> animation, Widget enfant) {
    final Animation<double> courbe = CurvedAnimation(
      parent: animation,
      curve: AppMouvement.entree,
      reverseCurve: AppMouvement.sortie,
    );
    return FadeTransition(
      opacity: courbe,
      child: ScaleTransition(
        scale: Tween<double>(begin: echelleFenetre, end: 1).animate(courbe),
        child: enfant,
      ),
    );
  }

  /// Le zoom leger d'une fenetre deja portee par une route de dialogue, qui
  /// fournit elle-meme le fondu (`showDialog`) : le zoom seul, sur
  /// l'animation de la route. Hors d'une route animee, rien ne change.
  static Widget zoomDeFenetre(BuildContext context, Widget enfant) {
    final Animation<double>? animation = ModalRoute.of(context)?.animation;
    if (animation == null || AppMouvement.mouvementReduit(context)) {
      return enfant;
    }
    return ScaleTransition(
      scale: Tween<double>(begin: echelleFenetre, end: 1).animate(
        CurvedAnimation(
          parent: animation,
          curve: AppMouvement.entree,
          reverseCurve: AppMouvement.sortie,
        ),
      ),
      child: enfant,
    );
  }

  /// Fondu court, sans deplacement : le retour venu du navigateur (bouton ou
  /// geste du navigateur, qui anime deja) ne joue pas une seconde animation.
  static Widget fonduCourt(Animation<double> animation, Widget enfant) =>
      FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMouvement.selection,
        ),
        child: enfant,
      );

  /// Le theme des transitions de page : sur le web et sur ordinateur, l'axe
  /// partage du catalogue ; sur iOS et macOS natifs, la transition du systeme
  /// (geste de retour par glissement conserve) ; sur Android natif, le retour
  /// predictif du systeme.
  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: kIsWeb
        ? <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: DescenteTransitionsBuilder(),
            TargetPlatform.iOS: DescenteTransitionsBuilder(),
            TargetPlatform.macOS: DescenteTransitionsBuilder(),
            TargetPlatform.windows: DescenteTransitionsBuilder(),
            TargetPlatform.linux: DescenteTransitionsBuilder(),
            TargetPlatform.fuchsia: DescenteTransitionsBuilder(),
          }
        : <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: DescenteTransitionsBuilder(),
            TargetPlatform.linux: DescenteTransitionsBuilder(),
            TargetPlatform.fuchsia: DescenteTransitionsBuilder(),
          },
  );
}

/// L'axe partage du catalogue comme transition de page Material : toutes les
/// routes `builder` du routeur, et toute page Material poussee.
class DescenteTransitionsBuilder extends PageTransitionsBuilder {
  /// Cree le constructeur.
  const DescenteTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMouvement.descente;

  @override
  Duration get reverseTransitionDuration =>
      AppTransitions.sortieDe(AppMouvement.descente);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMouvement.mouvementReduit(context)) {
      return child;
    }
    // Sur le web, un retour (bouton du navigateur, geste de Safari, ou
    // fleche de l'application) est un fondu court : le navigateur anime
    // deja son propre retour, jamais deux animations a la fois.
    if (kIsWeb && animation.status == AnimationStatus.reverse) {
      return AppTransitions.fonduCourt(animation, child);
    }
    return AppTransitions.descente(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
