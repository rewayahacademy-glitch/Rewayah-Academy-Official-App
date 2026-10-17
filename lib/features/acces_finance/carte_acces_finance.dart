// L'acces a ses finances depuis un accueil (lot F1, demande du directeur du
// 17/10/2026 : la finance de chacun visible ailleurs que chez
// l'administration).
//
// Une seule carte, partagee par l'Accueil de l'eleve adulte et l'Accueil
// famille : un titre, une phrase qui dit ce que la page d'arrivee montre, et
// un chevron. **Toute la carte se touche** (K-58) et s'annonce comme lien :
// elle mene a un endroit, elle n'engage rien.
//
// **Aucun chiffre ici** : la carte ne lit aucun port. Ce que la page d'arrivee
// montre (ou l'etat « pas encore publie » tant que le serveur ne rend rien)
// reste a la page d'arrivee, seule lecture des finances (FI-4, lecon 15).

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';

/// La carte qui mene aux finances de la personne, ou d'un profil du foyer.
class CarteAccesFinance extends StatelessWidget {
  /// Cree la carte.
  const CarteAccesFinance({
    required this.titre,
    required this.phrase,
    required this.onPress,
    super.key,
  });

  /// Le nom de la page d'arrivee.
  final String titre;

  /// Ce que la page d'arrivee montre, en une phrase.
  final String phrase;

  /// Ouvre la page d'arrivee.
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
              child: Icon(AppIcons.finance.repos),
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
