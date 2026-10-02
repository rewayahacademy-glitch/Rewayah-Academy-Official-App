import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'action_principale.dart';

/// Le titre d'une section, son compteur et son action tertiaire.
///
/// Trois raisons d'en faire un composant plutot qu'une `Row` recopiee :
///
/// 1. le compteur porte les **chiffres tabulaires** ; sans eux, un compteur qui
///    passe de 17 a 18 deplace le titre a cote ;
/// 2. **le zero s'affiche comme les autres valeurs**, jamais masque : un
///    compteur qui disparait a zero fait douter s'il a ete charge ou s'il est
///    reellement nul (`02-regles-ux.md` section 2) ;
/// 3. l'action de droite est **tertiaire**, jamais un second bouton plein a
///    cote de l'action principale de l'ecran.
class SectionHeader extends StatelessWidget {
  /// Cree un en-tete de section.
  const SectionHeader({
    required this.titre,
    super.key,
    this.compteur,
    this.libelleAction,
    this.onAction,
  });

  /// Le titre de la section.
  final String titre;

  /// Le nombre d'elements, quand il y en a un. **Zero s'affiche.**
  final int? compteur;

  /// Le libelle de l'action tertiaire.
  final String? libelleAction;

  /// L'action tertiaire. Sans elle, aucun bouton n'est rendu.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Un titre de SECTION : `titleLarge`, un cran sous le titre d'ecran
    // (`headline*`). Avant, `headlineSmall` valait le titre d'`EntetePage` sur
    // telephone : titre d'ecran et titre de section a la meme taille (HIER-1).
    final TextStyle styleTitre = textes.titleLarge ?? const TextStyle();

    final bool actionSousTitre =
        MediaQuery.textScalerOf(context).scale(16) > 16 ||
        MediaQuery.sizeOf(context).width < 600;
    final Widget titreEtCompteur = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Text(titre, style: palette.surfaceCanvas.applyTo(styleTitre)),
        ),
        if (compteur != null) ...<Widget>[
          Ecart.hSm,
          Text(
            '$compteur',
            style: AppTypography.tabulaire(
              palette.inkMuted.applyTo(textes.titleMedium ?? const TextStyle()),
            ),
          ),
        ],
      ],
    );
    final Widget? action = libelleAction != null && onAction != null
        ? ActionPrincipale(
            libelle: libelleAction!,
            onPress: onAction,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          )
        : null;

    if (action == null) {
      return titreEtCompteur;
    }
    if (actionSousTitre) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[titreEtCompteur, Ecart.vSm, action],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: titreEtCompteur),
        Ecart.hLg,
        action,
      ],
    );
  }
}
