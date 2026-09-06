import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// L'action principale d'un ecran.
///
/// **Dixieme composant partage, ajoute a l'etape 3.** L'etape 2 n'avait aucun
/// formulaire : le seul bouton du produit vivait a l'interieur d'`EmptyState`,
/// qui le redessinait pour son propre compte. L'etape 3 en a besoin sur chaque
/// page d'inscription, de contrat et de depot. Ce fichier n'ajoute donc pas un
/// composant a cote d'un autre, il sort celui qui existait deja pour que les
/// deux usages ne divergent pas.
///
/// Regle d'ecran heritee des parcours : **un ecran, une action principale.** Si
/// deux `ActionPrincipale` se disputent un ecran, l'ecran est a revoir, pas le
/// composant.
class ActionPrincipale extends StatelessWidget {
  /// Cree l'action principale.
  const ActionPrincipale({
    required this.libelle,
    required this.onPress,
    super.key,
    this.surface,
    this.enCours = false,
    this.pleineLargeur = true,
  });

  /// Le libelle du bouton.
  final String libelle;

  /// L'action. `null` rend le bouton inerte, et le dit visuellement.
  final VoidCallback? onPress;

  /// La paire de couleurs. Par defaut, l'accent principal.
  final AppColorPair? surface;

  /// Remplace le libelle par un indicateur d'activite, et bloque la pression.
  final bool enCours;

  /// Faux pour que le bouton ne prenne que la largeur de son libelle.
  final bool pleineLargeur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final bool actif = onPress != null && !enCours;

    // Un bouton inerte ne se signale pas par de la transparence : baisser
    // l'opacite ferait tomber tout le sous-arbre sous le seuil de contraste.
    // Il change de PAIRE, donc son texte reste lisible et suit son fond.
    final AppColorPair paire = actif
        ? (surface ?? palette.surfacePrimary)
        : palette.surfaceBase;

    final Widget contenu = Container(
      width: pleineLargeur ? double.infinity : null,
      constraints: BoxConstraints(minHeight: metriques.cibleTactile),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      decoration: paire.decoration(
        borderRadius: BorderRadius.circular(metriques.rayon),
        side: actif ? null : palette.borderDefault.asBorderSide(width: 2),
      ),
      child: enCours
          ? SizedBox.square(
              dimension: AppSpacing.xl,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: paire.onBackground,
              ),
            )
          : Text(
              libelle,
              textAlign: TextAlign.center,
              style: paire.applyTo(
                Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
              ),
            ),
    );

    return Pressable(
      onPress: actif ? onPress : null,
      libelleSemantique: libelle,
      respecterCibleTactile: false,
      child: contenu,
    );
  }
}
