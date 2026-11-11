// RUBAN-ORDINATEUR (directeur, 11/11/2026, capture de la vraie application :
// « les en-tetes des deux panneaux ne se ressemblent pas ») : LA tete d'un
// panneau de cote de la salle. Le titre au debut, sur une pastille ; la croix
// qui referme le panneau a la fin ; meme hauteur, meme style pour les Eleves
// et la Bibliotheque.
//
// La Bibliotheque garde la couleur de la marque et l'ornement (journal D-016 :
// « le titre du panneau porte la couleur de la marque », a la place d'une
// languette au bord de l'ecran) ; les autres panneaux prennent la meme
// pastille dans une surface neutre, avec leur icone.

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'bouton_icone.dart';
import 'brand_logo.dart' show FondLogo;
import 'ornement_marque.dart';

/// La tete d'un panneau de cote : [titre] sur une pastille au debut, la
/// croix « Fermer » ([onFermer]) a la fin.
class TetePanneau extends StatelessWidget {
  /// Cree la tete.
  const TetePanneau({
    required this.titre,
    required this.onFermer,
    super.key,
    this.icone,
    this.marque = false,
    this.clePastille,
    this.cleFermer,
  });

  /// Le titre du panneau (« Bibliotheque », « Eleves 2/3 »).
  final String titre;

  /// Referme le panneau.
  final VoidCallback onFermer;

  /// L'icone posee avant le titre (panneau neutre) ; ignoree quand
  /// [marque] est vrai (l'ornement de la marque la remplace).
  final AppIcon? icone;

  /// Vrai : la pastille aux couleurs de la marque, avec l'ornement (la
  /// Bibliotheque, D-016).
  final bool marque;

  /// Les cles de la pastille et de la croix (tests).
  final Key? clePastille;
  final Key? cleFermer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair surface = marque
        ? palette.surfacePrimary
        : palette.surfaceSunken;
    final AppIcon? icone = this.icone;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(
                header: true,
                child: DecoratedBox(
                  key: clePastille,
                  decoration: surface.decoration(
                    borderRadius: AppRadius.arrondiFull,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (marque)
                          const OrnementMarque(fond: FondLogo.violet)
                        else if (icone != null)
                          ExcludeSemantics(
                            child: IconTheme(
                              data: IconThemeData(
                                color: surface.onBackground,
                                size: AppSpacing.lg,
                              ),
                              child: Icon(icone.repos),
                            ),
                          ),
                        if (marque || icone != null) Ecart.hSm,
                        Flexible(
                          child: Text(
                            titre,
                            style: surface.applyTo(
                              textes.titleMedium ?? const TextStyle(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          BoutonIcone(
            key: cleFermer,
            icone: AppIcons.fermer,
            libelle: t.commun.fermer,
            infobulle: t.commun.fermer,
            forme: FormeBoutonIcone.nue,
            onPress: onFermer,
          ),
        ],
      ),
    );
  }
}
