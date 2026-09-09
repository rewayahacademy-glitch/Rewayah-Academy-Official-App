import 'package:flutter/material.dart';

import '../theme/app_elevation.dart';
import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// La feuille de bas d'ecran du produit.
///
/// **Seul point d'entree d'une surface modale.** Le produit n'ouvre pas de
/// boite de dialogue Material : une feuille se prend au pouce sur un telephone,
/// une boite de dialogue non.
///
/// Le motif de mouvement est celui de `docs/design/04-systeme-mouvement.md`
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
  });

  /// Le titre de la feuille, en une phrase.
  final String titre;

  /// Le corps de la feuille.
  final Widget child;

  /// La zone d'action, collee en bas de la feuille.
  final Widget? actions;

  /// Largeur de la poignee de glissement.
  static const double largeurPoignee = AppSpacing.section;

  /// Hauteur de la poignee de glissement.
  static const double hauteurPoignee = AppSpacing.xs;

  /// Ouvre une feuille modale et rend ce que sa fermeture renvoie.
  ///
  /// `Echap` la ferme, comme le veut la regle du clavier
  /// (`05-regles-responsive.md` section 5) : c'est le comportement par defaut
  /// d'une route modale, il n'y a rien a cabler.
  static Future<T?> ouvrir<T>(
    BuildContext context, {
    required String titre,
    required Widget Function(BuildContext context) constructeur,
    Widget Function(BuildContext context)? actions,
  }) {
    final AppPalette palette = AppPalette.of(context);

    // Les durees du budget de mouvement, et non celles de Material : 280 ms a
    // l'ouverture, 200 ms a la fermeture, la sortie plus courte que l'entree
    // d'environ un tiers. Le controleur se dispose a la fermeture, sinon
    // chaque feuille ouverte laisserait un ticker derriere elle.
    final AnimationController animation =
        BottomSheet.createAnimationController(Navigator.of(context))
          ..duration = AppMouvement.feuilleOuverture
          ..reverseDuration = AppMouvement.feuilleFermeture;

    return showModalBottomSheet<T>(
      context: context,
      // La feuille peut depasser la moitie de l'ecran : une confirmation
      // destructive qui explique sa consequence prend la place qu'il faut.
      isScrollControlled: true,
      useSafeArea: true,
      transitionAnimationController: animation,
      // Les courbes viennent du budget de mouvement, jamais de Material : ce
      // qui entre s'installe doucement, ce qui sort part plus vite
      // (`04-systeme-mouvement.md` section 2).
      sheetAnimationStyle: const AnimationStyle(
        curve: AppMouvement.entree,
        reverseCurve: AppMouvement.sortie,
      ),
      backgroundColor: palette.surfaceRaised.background,
      // Le voile derive du noir de la charte, jamais d'un gris invente.
      barrierColor: palette.surfaceInverse.background.withValues(
        alpha: AppMouvement.opaciteVoile,
      ),
      // L'ombre et le filet viennent d'AppElevation, sur la surface elle-meme
      // (voir `build`) : le `Material` de la feuille ne fait que clipper les
      // coins.
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.arrondiFeuille,
      ),
      builder: (BuildContext contexte) => AppBottomSheet(
        titre: titre,
        actions: actions?.call(contexte),
        child: constructeur(contexte),
      ),
    ).whenComplete(animation.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return DecoratedBox(
      // Un filet ET une ombre, composes en une fois : une feuille est une
      // surface elevee, et une surface elevee ne porte jamais l'un sans
      // l'autre (`01-systeme-visuel.md` section 2).
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.borderHairline,
        arrondi: AppRadius.arrondiFeuille,
        ombres: AppElevation.niveau3,
      ),
      child: Padding(
        padding: EdgeInsets.all(metriques.marge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // La poignee dit que la feuille se glisse. Elle est decorative :
            // le glissement double toujours un bouton ou la touche Echap,
            // aucun geste n'est le seul chemin (`06-accessibilite.md` section 2).
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
            Text(
              titre,
              style: palette.surfaceRaised.applyTo(
                textes.headlineSmall ?? const TextStyle(),
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
