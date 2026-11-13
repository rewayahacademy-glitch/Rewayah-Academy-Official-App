/// ESPACE-APPRENDRE (lot 5) : la vignette d'un document de la planche.
///
/// Trois cas, dans cet ordre : la vignette deposee ([DocumentPlanche.vignette]),
/// sinon la couverture de livre de l'academie (`CouvertureSupport`, le Coran
/// garde la sienne) pour un document, sinon une vignette par defaut **selon le
/// type** (audio, video, lien externe : une surface douce et l'icone du type).
///
/// Dans l'application, la vignette COMPLETE vient de la couche des ecrans :
/// la couverture de la Bibliotheque une (`VignetteRessource`, lot 3, vignette
/// deposee par-dessus) est posee dans [DocumentPlanche.vignette] ; un composant
/// du core ne depend pas d'un ecran. La vignette par defaut de ce fichier ne
/// sert qu'a un document que cette couche n'a pas habille (demonstration, test).
library;

import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/couverture_support.dart';
import 'document_planche.dart';

/// La vignette de [document], au rapport d'un livre (3 sur 4).
class VignetteDocument extends StatelessWidget {
  /// Cree la vignette.
  const VignetteDocument({required this.document, super.key});

  /// Le document.
  final DocumentPlanche document;

  /// L'icone d'un type.
  static AppIcon iconeDe(TypeDocumentPlanche type) => switch (type) {
    TypeDocumentPlanche.document => AppIcons.document,
    TypeDocumentPlanche.audio => AppIcons.audio,
    TypeDocumentPlanche.video => AppIcons.video,
    TypeDocumentPlanche.lienExterne => AppIcons.lienExterne,
  };

  @override
  Widget build(BuildContext context) {
    final Widget? deposee = document.vignette;
    if (deposee != null) {
      return AspectRatio(
        aspectRatio: CouvertureSupport.rapport,
        child: ClipRRect(borderRadius: AppRadius.arrondiMd, child: deposee),
      );
    }
    if (document.type == TypeDocumentPlanche.document &&
        document.couverture != null) {
      return CouvertureSupport(
        titre: document.titre,
        couverture: document.couverture!,
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair paire = switch (document.type) {
      TypeDocumentPlanche.audio => palette.washAccent,
      TypeDocumentPlanche.video => palette.surfaceInverse,
      TypeDocumentPlanche.document ||
      TypeDocumentPlanche.lienExterne => palette.surfaceSunken,
    };
    return AspectRatio(
      aspectRatio: CouvertureSupport.rapport,
      child: DecoratedBox(
        decoration: paire.decoration(borderRadius: AppRadius.arrondiMd),
        child: Center(
          child: IconTheme(
            data: IconThemeData(
              color: paire.onBackground,
              size: AppSpacing.respiration,
            ),
            child: Icon(iconeDe(document.type).repos),
          ),
        ),
      ),
    );
  }
}
