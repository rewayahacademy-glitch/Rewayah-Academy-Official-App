import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../tc_catalogue/class_library_picker.dart';
import '../tc_catalogue/surface_bibliotheque.dart';

/// La Bibliotheque ouverte pendant un cours : le Coran d'abord, le catalogue
/// ensuite.
///
/// **Le Coran est immediatement reconnaissable** (lot 2 section 8), et il l'est
/// meme quand le catalogue est vide -- ce qui est le cas en production tant
/// que `portCatalogueProvider` est `CatalogueLocal()` : le corpus, lui, existe
/// (ADR-024), et c'est le seul support que le moteur de classe sait rendre.
/// La carte n'est pas une entree de catalogue inventee : elle mene a la meme
/// ressource (`identifiantRessourceCoran`) que le picker rendrait si la
/// ressource y figurait.
///
/// Elle ne connait pas LiveKit et ne navigue nulle part : choisir un support
/// est une decision de la Classe Live, qui recoit les deux rappels.
class BibliothequeEnClasse extends StatelessWidget {
  /// Cree la surface.
  const BibliothequeEnClasse({
    required this.onPresenterCoran,
    required this.onChoisir,
    required this.enPanneau,
    super.key,
    this.groupeId,
  });

  /// Le groupe, pour la section « Ce groupe ». `null` sans groupe connu.
  final String? groupeId;

  /// Presente le Coran au groupe.
  final VoidCallback onPresenterCoran;

  /// Un support du catalogue a ete choisi.
  final ChoixRessource onChoisir;

  /// Vrai dans le panneau lateral (hauteur bornee par le parent), faux dans une
  /// feuille (le picker borne sa propre hauteur).
  final bool enPanneau;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final Widget coran = AppCard(
      onPress: onPresenterCoran,
      libelleSemantique: t.tc.classe.support.presenterCoran,
      child: Row(
        children: <Widget>[
          Icon(AppIcons.coran.repos, size: AppSpacing.xxxl),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.tc.classe.support.presenterCoran,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                Text(
                  t.tc.classe.support.presenterCoranDetail,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Widget picker = ClassLibraryPicker(
      groupeId: groupeId,
      onChoisir: onChoisir,
      // Dans le panneau, le parent borne : la surface prend ce qui reste.
      hauteurMaximale: enPanneau ? double.infinity : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        coran,
        Ecart.vMd,
        if (enPanneau) Expanded(child: picker) else picker,
      ],
    );
  }
}
