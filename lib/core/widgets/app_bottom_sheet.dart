import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// La forme d'une surface modale, selon le gabarit.
enum FormeModale {
  /// Telephone : la feuille de bas d'ecran, pleine largeur, au pouce.
  feuille,

  /// Tablette : la meme feuille, bornee a [AppPage.largeurDialogue] et
  /// centree. Jamais une feuille de telephone etiree sur 800 points.
  feuilleBornee,

  /// Bureau : une boite de dialogue centree, meme contenu, meme largeur
  /// bornee, sans poignee de glissement (il n'y a pas de doigt).
  dialogue,
}

/// La feuille de bas d'ecran du produit.
///
/// **Seul point d'entree d'une surface modale.** Sur telephone, une feuille se
/// prend au pouce ; sur tablette, la meme feuille est bornee en largeur ; sur
/// bureau, elle devient une boite de dialogue centree (contrat K5 du chantier
/// Tuteur V1 : pas de feuille mobile etiree). Le contenu, les actions et leur
/// ordre ne changent pas d'une forme a l'autre : seul le gabarit decide
/// ([formePour]).
///
/// Le motif de mouvement est celui de `docs/archive/2026-09-pre-remise-a-plat/design/04-systeme-mouvement.md`
/// section 3 : 280 ms a l'ouverture, 200 ms a la fermeture, voile a 0,32
/// d'opacite, et **la feuille suit le doigt pendant le glissement**. Elle ne se
/// referme que si la vitesse ou la distance depasse le seuil : une feuille qui
/// se referme sur un effleurement est une feuille qu'on n'ose plus toucher.
class AppBottomSheet extends StatelessWidget {
  /// Cree le contenu d'une feuille.
  ///
  /// Rendu directement plutot que par [ouvrir] dans la galerie : c'est le seul
  /// moyen de montrer ses etats sans ouvrir une vraie modale.
  const AppBottomSheet({
    required this.titre,
    required this.child,
    super.key,
    this.actions,
    this.forme = FormeModale.feuille,
  });

  /// Le titre de la feuille, en une phrase.
  final String titre;

  /// Le corps de la feuille.
  final Widget child;

  /// La zone d'action, collee en bas de la feuille.
  final Widget? actions;

  /// La forme rendue. [ouvrir] la choisit d'apres le gabarit ; la galerie la
  /// fixe pour montrer les trois.
  final FormeModale forme;

  /// La forme qui convient a un gabarit.
  static FormeModale formePour(Gabarit gabarit) => switch (gabarit) {
    Gabarit.mobile => FormeModale.feuille,
    Gabarit.tablette => FormeModale.feuilleBornee,
    Gabarit.desktop => FormeModale.dialogue,
  };

  /// Largeur de la poignee de glissement.
  static const double largeurPoignee = AppSpacing.section;

  /// Hauteur de la poignee de glissement.
  static const double hauteurPoignee = AppSpacing.xs;

  /// Ouvre une feuille modale et rend ce que sa fermeture renvoie.
  ///
  /// `Echap` la ferme, comme le veut la regle du clavier
  /// (`05-regles-responsive.md` section 5). C'est bien le comportement par
  /// defaut d'une route modale -- `ModalRoute` associe `DismissIntent` a
  /// `Navigator.maybePop()` (framework, `widgets/routes.dart`) -- mais il a
  /// fallu le lot de remise au vert pour que ce soit vrai ici, et la cause
  /// merite d'etre ecrite parce qu'elle ne se devine pas.
  ///
  /// **La feuille se depopait sans jamais se retirer de l'ecran.** Cette
  /// methode fournissait son propre `transitionAnimationController`. Or
  /// `ModalBottomSheetRoute` pose alors `willDisposeAnimationController =
  /// false` : le controleur appartient a l'appelant. Et l'appelant, ici, le
  /// detruisait par `.whenComplete(animation.dispose)`, c'est-a-dire quand la
  /// future de la feuille se complete -- **au pop, pas au retrait**. Le
  /// controleur mourait donc au milieu de l'animation de sortie, la route
  /// n'atteignait jamais l'etat qui la fait retirer de l'overlay, et la
  /// feuille restait affichee sur une route deja depopee. `Echap` faisait
  /// exactement ce qu'il fallait, et rien ne bougeait.
  ///
  /// Le remede supprime le controleur au lieu d'en ajouter : `AnimationStyle`
  /// porte aussi bien les durees que les courbes, et `showModalBottomSheet`
  /// construit alors le controleur lui-meme -- et le detruit lui-meme, au bon
  /// moment. **Ne jamais repasser de `transitionAnimationController` ici** :
  /// ce serait reprendre la propriete du controleur, donc le bug.
  ///
  /// **Sur bureau, une boite de dialogue** (voir [FormeModale]) : meme titre,
  /// meme corps, memes actions dans le meme ordre, fermee par `Echap`, par le
  /// voile ou par ses actions, et rendant la meme valeur. Sur tablette, la
  /// feuille est bornee a [AppPage.largeurDialogue].
  ///
  /// Le voile est `palette.voile` (noir a 32 % en clair, 56 % en sombre) : il
  /// derivait de `surfaceInverse`, qui est **clair** dans le theme sombre et
  /// voilait donc l'ecran de blanc (defaut releve par l'audit C02 et la phase
  /// 0b du chantier Tuteur V1).
  static Future<T?> ouvrir<T>(
    BuildContext context, {
    required String titre,
    required Widget Function(BuildContext context) constructeur,
    Widget Function(BuildContext context)? actions,
  }) {
    final AppPalette palette = AppPalette.of(context);
    final FormeModale forme = formePour(AppGabarit.de(context));

    if (forme == FormeModale.dialogue) {
      return showDialog<T>(
        context: context,
        barrierColor: palette.voile,
        animationStyle: const AnimationStyle(
          curve: AppMouvement.entree,
          duration: AppMouvement.feuilleOuverture,
          reverseCurve: AppMouvement.sortie,
          reverseDuration: AppMouvement.feuilleFermeture,
        ),
        builder: (BuildContext contexte) => _CadreDialogue(
          child: AppBottomSheet(
            titre: titre,
            forme: FormeModale.dialogue,
            actions: actions?.call(contexte),
            child: constructeur(contexte),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      // La feuille peut depasser la moitie de l'ecran : une confirmation
      // destructive qui explique sa consequence prend la place qu'il faut.
      isScrollControlled: true,
      useSafeArea: true,
      // Les durees et les courbes du budget de mouvement, jamais celles de
      // Material : 280 ms a l'ouverture, 200 ms a la fermeture -- la sortie
      // plus courte que l'entree d'environ un tiers -- et ce qui entre
      // s'installe doucement quand ce qui sort part plus vite
      // (`04-systeme-mouvement.md` section 2).
      sheetAnimationStyle: const AnimationStyle(
        curve: AppMouvement.entree,
        duration: AppMouvement.feuilleOuverture,
        reverseCurve: AppMouvement.sortie,
        reverseDuration: AppMouvement.feuilleFermeture,
      ),
      backgroundColor: palette.surfaceRaised.background,
      // Le voile du theme, sombre dans les deux themes (voir plus haut).
      barrierColor: palette.voile,
      // Tablette : la feuille garde sa forme mais ne s'etire plus.
      constraints: forme == FormeModale.feuilleBornee
          ? const BoxConstraints(maxWidth: AppPage.largeurDialogue)
          : null,
      // L'ombre et le filet viennent d'AppElevation, sur la surface elle-meme
      // (voir `build`) : le `Material` de la feuille ne fait que clipper les
      // coins.
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.arrondiFeuille,
      ),
      builder: (BuildContext contexte) => AppBottomSheet(
        titre: titre,
        forme: forme,
        actions: actions?.call(contexte),
        child: constructeur(contexte),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool dialogue = forme == FormeModale.dialogue;
    // La boite de dialogue prend la surface des superpositions (plus claire
    // que la carte en sombre) et arrondit ses quatre coins : elle n'est
    // ancree a aucun bord.
    final AppColorPair surface = dialogue
        ? palette.surfaceOverlay
        : palette.surfaceRaised;

    return DecoratedBox(
      // Un filet ET une ombre, composes en une fois : une feuille est une
      // surface elevee, et une surface elevee ne porte jamais l'un sans
      // l'autre (`01-systeme-visuel.md` section 2). Niveau 3 pour les deux
      // formes : c'est le niveau de « ce qui recouvre » (`app_elevation.dart`).
      decoration: AppElevation.avecFilet(
        surface: surface,
        filet: palette.borderHairline,
        ombre: palette.ombre,
        arrondi: dialogue ? AppRadius.arrondiLg : AppRadius.arrondiFeuille,
        ombres: AppElevation.niveau3(palette.ombre),
      ),
      child: Padding(
        padding: EdgeInsets.all(dialogue ? AppSpacing.xxl : metriques.marge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // La poignee dit que la feuille se glisse. Elle est decorative :
            // le glissement double toujours un bouton ou la touche Echap,
            // aucun geste n'est le seul chemin (`06-accessibilite.md` section 2).
            // Une boite de dialogue ne se glisse pas : pas de poignee.
            if (!dialogue) ...<Widget>[
              Center(
                child: ExcludeSemantics(
                  child: SizedBox(
                    width: largeurPoignee,
                    height: hauteurPoignee,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.borderResting.asBorderSide().color,
                        borderRadius: AppRadius.arrondiFull,
                      ),
                    ),
                  ),
                ),
              ),
              Ecart.vLg,
            ],
            Semantics(
              header: true,
              child: Text(
                titre,
                style: surface.applyTo(
                  textes.headlineSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vLg,
            Flexible(child: SingleChildScrollView(child: child)),
            if (actions != null) ...<Widget>[Ecart.vXxl, actions!],
          ],
        ),
      ),
    );
  }
}

/// Le cadre de la boite de dialogue de bureau : centree, bornee a
/// [AppPage.largeurDialogue], tenue a distance des bords, jamais plus haute que
/// la fenetre (le corps defile dans [AppBottomSheet]).
class _CadreDialogue extends StatelessWidget {
  const _CadreDialogue({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppPage.largeurDialogue,
            ),
            // Un `Material` transparent : le texte et les controles du corps
            // trouvent leur ancetre Material sans qu'aucune couleur ni ombre
            // Material ne s'ajoute a celles d'AppElevation.
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}
