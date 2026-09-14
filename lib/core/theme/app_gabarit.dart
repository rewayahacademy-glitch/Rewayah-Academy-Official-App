import 'package:flutter/widgets.dart';

import 'app_spacing.dart';

/// La forme du chrome de navigation, selon la largeur disponible.
///
/// Trois formes, une seule liste de destinations : c'est `NavShell` qui les
/// rend, et il ne connait qu'une source
/// (`docs/design/03-architecture-information.md` section 5).
enum ChromeNavigation {
  /// Barre basse, sous le contenu.
  barreBasse,

  /// Rail lateral replie : icone plus libelle court.
  rail,

  /// Barre laterale permanente, libelles complets.
  barreLaterale,
}

/// Les trois gabarits de l'application.
///
/// **Trois presentations, pas trois applications** : les memes composants, la
/// meme arborescence de routes, les memes donnees
/// (`docs/design/05-regles-responsive.md` section 1).
enum Gabarit {
  /// Moins de 600.
  mobile(AppPage.gouttiereMobile, ChromeNavigation.barreBasse),

  /// De 600 a 1199.
  tablette(AppPage.gouttiereTablette, ChromeNavigation.rail),

  /// A partir de 1200.
  desktop(AppPage.gouttiereDesktop, ChromeNavigation.barreLaterale);

  const Gabarit(this.gouttiere, this.chrome);

  /// La gouttiere laterale de la page dans ce gabarit.
  final double gouttiere;

  /// La forme que prend la navigation dans ce gabarit.
  final ChromeNavigation chrome;

  /// Vrai des la tablette : le survol et le clavier existent, l'ecran a de la
  /// place pour un detail a cote plutot qu'une page de plus.
  bool get estLarge => this != mobile;
}

/// Les seuils de largeur, en un seul endroit.
///
/// **C'est le seul fichier du depot autorise a comparer une largeur d'ecran a
/// un nombre.** Un `MediaQuery.of(context).size.width > 700` pose au fil d'un
/// ecran est exactement la maniere dont un produit finit avec quatre seuils
/// differents, dont trois faux (`docs/design/05-regles-responsive.md` section 1).
/// R1 content classes. Legacy navigation mapping below is retained for R2.
enum ClasseLargeur { compacte, moyenne, etendue, large }

abstract final class AppGabarit {
  /// A partir de cette largeur, le rail remplace la barre basse.
  static const double seuilTablette = 600;

  /// Seuil de contenu : la densite peut evoluer, sans changer de chrome.
  static const double seuilEtendu = 840;

  /// A partir de cette largeur, le tiroir permanent remplace le rail.
  static const double seuilDesktop = 1200;

  /// Alias semantique pour les consommateurs de classes de largeur R1.
  static const double seuilLarge = seuilDesktop;
  static const double seuilChoixDouble = 560;
  static const double seuilTexteColonne = 1.5;
  static ClasseLargeur classe(double largeur) {
    if (largeur < seuilTablette) return ClasseLargeur.compacte;
    if (largeur < seuilEtendu) return ClasseLargeur.moyenne;
    if (largeur < seuilLarge) return ClasseLargeur.etendue;
    return ClasseLargeur.large;
  }

  static double margePour(double largeur) => largeur < seuilTablette
      ? AppSpacing.lg
      : largeur < seuilLarge
      ? AppSpacing.xxl
      : AppSpacing.xxxl;
  static bool choixEnColonnes(double largeur, TextScaler texte) =>
      largeur >= seuilChoixDouble && texte.scale(16) / 16 < seuilTexteColonne;

  /// Le gabarit correspondant a une largeur.
  ///
  /// Les bornes suivent le shell R2 : mobile **sous** 600, rail de 600 a
  /// 1199 inclus, tiroir permanent a partir de 1200.
  static Gabarit pour(double largeur) {
    if (largeur < seuilTablette) {
      return Gabarit.mobile;
    }
    if (largeur < seuilDesktop) {
      return Gabarit.tablette;
    }
    return Gabarit.desktop;
  }

  /// Le gabarit de la fenetre courante.
  ///
  /// Passe par `MediaQuery.sizeOf` et non par `MediaQuery.of` : seule la taille
  /// est ecoutee, un changement de police ou de luminosite ne reconstruit donc
  /// pas toute la page.
  static Gabarit de(BuildContext context) =>
      pour(MediaQuery.sizeOf(context).width);

  /// Largeur du rail replie : la cible tactile du mode enfant, plus une marge.
  ///
  /// C'est la plus etroite qui tienne une icone et un libelle court sous elle
  /// sans que la cible tactile deborde.
  static const double largeurRail = 80;

  /// Largeur de la barre laterale permanente.
  ///
  /// **Posee, et non derivee de l'echelle** : c'est une largeur de chrome, pas
  /// un espacement. Elle vaut ce qu'il faut pour ecrire le plus long libelle de
  /// navigation du produit, « Tableau de bord », sur une ligne a l'echelle du
  /// mode enfant, icone et gouttieres comprises.
  static const double largeurBarreLaterale = 256;
}
