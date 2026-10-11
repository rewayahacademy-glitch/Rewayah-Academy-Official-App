import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/pressable.dart';

/// Une fleche de page du Mushaf, ronde, hors de la page.
///
/// Meme forme que celles de `BarrePrecedentSuivant` (disque `surfaceRaised`,
/// cible tactile du mode d'interface), mais posee **de chaque cote de la page**
/// et non sous elle. Le glyphe est celui des jetons ; il est retourne ici,
/// selon le cote, jamais selon la langue de l'interface : un Mushaf se feuillette
/// de la droite vers la gauche en francais comme en arabe.
class FlechePageMushaf extends StatelessWidget {
  /// Cree une fleche.
  const FlechePageMushaf({
    required this.libelle,
    required this.versLaGauche,
    required this.onPress,
    super.key,
  });

  /// Ce que le lecteur d'ecran annonce.
  final String libelle;

  /// Vrai : fleche du bord gauche, qui pointe vers la gauche.
  final bool versLaGauche;

  /// `null` : borne atteinte, la fleche n'est pas rendue (sa place reste).
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final double cible = AppMetriques.of(context).cibleTactile;
    final VoidCallback? action = onPress;
    if (action == null) {
      return SizedBox.square(dimension: cible);
    }
    final AppPalette palette = AppPalette.of(context);
    return Pressable(
      onPress: action,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiFull,
      child: SizedBox.square(
        dimension: cible,
        child: DecoratedBox(
          decoration: palette.surfaceRaised.decoration(
            borderRadius: AppRadius.arrondiFull,
            side: palette.borderResting.asBorderSide(),
          ),
          child: Center(
            child: IconTheme(
              data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
              child: Transform.flip(
                flipX: versLaGauche,
                child: Icon(AppIcons.suivant.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La page encadree de ses deux fleches (tablette et bureau).
///
/// Les fleches sont symetriques, centrees verticalement, dans deux colonnes
/// reservees : elles ne chevauchent jamais le texte. **La page suivante est a
/// gauche**, comme quand on feuillette un livre arabe : la fleche de gauche est
/// « page suivante », celle de droite « page precedente ». Les touches
/// gauche et droite font de meme.
class PageAvecFlechesMushaf extends StatelessWidget {
  /// Cree l'encadrement.
  const PageAvecFlechesMushaf({
    required this.libellePrecedente,
    required this.libelleSuivante,
    required this.onPrecedente,
    required this.onSuivante,
    required this.child,
    super.key,
  });

  /// Le libelle de la fleche de droite.
  final String libellePrecedente;

  /// Le libelle de la fleche de gauche.
  final String libelleSuivante;

  /// `null` a la premiere page.
  final VoidCallback? onPrecedente;

  /// `null` a la derniere page.
  final VoidCallback? onSuivante;

  /// La page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextDirection sens = Directionality.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): ?onSuivante,
        const SingleActivator(LogicalKeyboardKey.arrowRight): ?onPrecedente,
      },
      child: Focus(
        autofocus: true,
        // Les fleches du clavier appartiennent a la page, pas a un champ : le
        // focus reste sur elle tant qu'aucun autre controle ne le prend.
        child: Directionality(
          // Cote physique : gauche et droite ne suivent pas la langue.
          textDirection: TextDirection.ltr,
          child: Row(
            children: <Widget>[
              FlechePageMushaf(
                libelle: libelleSuivante,
                versLaGauche: true,
                onPress: onSuivante,
              ),
              Expanded(
                child: Directionality(textDirection: sens, child: child),
              ),
              FlechePageMushaf(
                libelle: libellePrecedente,
                versLaGauche: false,
                onPress: onPrecedente,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
