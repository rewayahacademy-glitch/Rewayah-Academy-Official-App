// ONBOARDING-TUTEUR (09/11/2026, decision du directeur : on garde la question
// « Suivez-vous aussi des cours ? », donc on la branche).
//
// Une seule carte, partagee par l'Accueil famille (entree vers l'espace
// d'eleve du tuteur qui suit aussi des cours) et par l'Accueil adulte (retour
// vers l'Accueil famille) : un titre, une phrase, un chevron. Toute la carte se
// touche et s'annonce comme lien (K-58). Aucun contenu qui defile, aucune
// lecture : la carte ne decide rien, ses appelants lisent la capacite.

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

/// La carte qui mene d'un accueil a l'autre.
class CarteEntreeEspace extends StatelessWidget {
  /// Cree la carte.
  const CarteEntreeEspace({
    required this.icone,
    required this.titre,
    required this.phrase,
    required this.onPress,
    super.key,
  });

  /// L'icone de l'endroit d'arrivee.
  final AppIcon icone;

  /// Le nom de l'endroit d'arrivee.
  final String titre;

  /// Ce que la personne y retrouve, en une phrase.
  final String phrase;

  /// Ouvre l'endroit d'arrivee.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      onPress: onPress,
      lien: true,
      libelleSemantique: '$titre. $phrase',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            IconTheme(
              data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
              child: Icon(icone.repos),
            ),
            Ecart.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TexteSansCoupure(
                    titre,
                    style: textes.titleMedium ?? const TextStyle(),
                  ),
                  Ecart.vSm,
                  TexteSansCoupure(
                    phrase,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
            Ecart.hSm,
            IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
              child: Icon(AppIcons.chevron.repos),
            ),
          ],
        ),
      ),
    );
  }
}
