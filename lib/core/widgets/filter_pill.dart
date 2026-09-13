import 'package:flutter/material.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Une valeur de filtre, retenue ou non, avec son compteur facultatif.
///
/// **Un filtre n'est pas une action**, et c'est pour cela qu'il ne passe pas
/// par `ActionPrincipale` : une rangee de huit boutons tertiaires alignes est
/// exactement ce que `02-regles-ux.md` section 4 interdit (« autant que
/// necessaire, mais jamais alignees comme des boutons »). Ce n'est pas non plus
/// un `ChoiceCardGroup` : celui-la ajoute d'office une carte « Autre » en
/// saisie libre, qui n'a aucun sens quand les valeurs viennent de la base.
///
/// Le compteur porte les **chiffres tabulaires**, pour la meme raison que celui
/// de `SectionHeader` : sans eux, une pilule qui passe de 9 a 10 deplace ses
/// voisines.
///
/// **Le compteur n'est pas decoratif.** Il dit a l'avance si un filtre mene
/// quelque part : sans lui, l'administration decouvre l'impasse apres le tap.
class FilterPill extends StatelessWidget {
  /// Cree une pilule de filtre.
  const FilterPill({
    required this.libelle,
    required this.onPress,
    super.key,
    this.retenue = false,
    this.compteur,
  });

  /// Ce qui s'affiche.
  final String libelle;

  /// L'action au tap. Une pilule deja retenue reste pressable : c'est ainsi
  /// qu'on la relache.
  final VoidCallback? onPress;

  /// Vrai quand ce filtre est actif.
  final bool retenue;

  /// Le nombre d'elements derriere cette valeur. **Zero s'affiche comme les
  /// autres valeurs** (`02-regles-ux.md` section 2).
  final int? compteur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Semantics(
      selected: retenue,
      button: true,
      child: Pressable.selon(
        onPress: onPress,
        libelleSemantique: compteur == null ? libelle : '$libelle, $compteur',
        arrondiFocus: AppRadius.arrondiFull,
        constructeur: (BuildContext contexte, EtatPression etat) {
          // La paire douce d'accent quand le filtre porte, la surface elevee
          // sinon : jamais un aplat sature, une pilule n'est pas l'action
          // principale de l'ecran (`01-systeme-visuel.md` section 3).
          final AppColorPair fond = retenue
              ? palette.washAccent
              : palette.surfaceRaised;
          // Le filet porteur de sens des que la pilule dit quelque chose :
          // retenue, survolee ou pressee. Meme regle que `AppCard`.
          final BorderSide filet =
              (retenue || etat.survole || etat.presse
                      ? palette.borderStrong
                      : palette.borderHairline)
                  .asBorderSide();

          return DecoratedBox(
            decoration: fond.decoration(
              borderRadius: AppRadius.arrondiFull,
              side: filet,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    libelle,
                    style: fond.applyTo(textes.labelLarge ?? const TextStyle()),
                  ),
                  if (compteur != null) ...<Widget>[
                    Text(
                      '$compteur',
                      style: AppTypography.tabulaire(
                        palette.inkMuted.applyTo(
                          textes.labelMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
