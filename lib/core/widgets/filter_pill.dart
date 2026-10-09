import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
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
///
/// **L'etat retenu ne se lit jamais a la seule couleur** (`lib/CLAUDE.md`,
/// FILTERPILL-ETAT-1, decide par delegation le 09/10) : en plus du fond doux
/// et du filet fort, une pilule retenue porte une **coche** devant son
/// libelle, la meme que celle de `ChoiceCardGroup` et de `MenuFiltre`
/// (`AppIcons.succes`, graisse pleine). Le lecteur d'ecran garde
/// `selected`.
///
/// **La largeur ne saute pas a la selection.** La place de la coche est
/// reservee dans les deux etats : au repos, elle est rendue en air, a parts
/// egales des deux cotes du libelle (qui reste centre, K-54) ; retenue, elle
/// est occupee par la coche. Une pilule qu'on touche ne grandit donc pas et ne
/// pousse pas ses voisines a la ligne suivante dans un `Wrap` (jours de la
/// feuille « Ajouter une plage », filtres d'administration) : le doigt reste
/// sur la meme pilule et la rangee ne se recompose pas sous lui. Prix : chaque
/// pilule est plus large de [retraitLargeur] moins `2 x AppSpacing.lg`.
class FilterPill extends StatelessWidget {
  /// Cree une pilule de filtre.
  const FilterPill({
    required this.libelle,
    required this.onPress,
    super.key,
    this.retenue = false,
    this.compteur,
    this.focusNode,
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

  /// Le noeud de focus de la pilule, facultatif.
  final FocusNode? focusNode;

  /// La taille de la coche d'une pilule retenue (celle de `MenuFiltre`).
  static const double tailleCoche = AppSpacing.lg;

  /// L'ecart entre la coche et le libelle (celui du compteur).
  static const double ecartCoche = AppSpacing.sm;

  /// Le retrait interieur horizontal total de la pilule, identique dans les
  /// deux etats : ce qu'un parent qui mesure les pilules a l'avance
  /// (`RangeePuces`) ajoute a la largeur du libelle.
  static const double retraitLargeur =
      AppSpacing.lg * 2 + tailleCoche + ecartCoche;

  /// Le retrait de chaque cote d'une pilule au repos : la place de la coche,
  /// partagee en deux pour que le libelle reste centre.
  static const double _retraitRepos = retraitLargeur / 2;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Un seul noeud pour le lecteur d'ecran : bouton, `selected`, et le
    // libelle (compteur compris) dit une fois. Avant FILTERPILL-ETAT-1,
    // `selected` vivait sur un noeud sans libelle, au-dessus d'un noeud qui
    // disait le libelle deux fois (« Lundi Lundi ») : celui de `Pressable` et
    // celui du texte peint, fusionnes.
    return Pressable.selon(
      onPress: onPress,
      focusNode: focusNode,
      selectionne: retenue,
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

        return ExcludeSemantics(
          child: DecoratedBox(
            decoration: fond.decoration(
              borderRadius: AppRadius.arrondiFull,
              side: filet,
            ),
            child: Padding(
              padding: retenue
                  ? const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    )
                  : const EdgeInsetsDirectional.symmetric(
                      horizontal: _retraitRepos,
                      vertical: AppSpacing.sm,
                    ),
              // K-54 : le contenu est centre dans la pilule, en largeur comme
              // en hauteur (la cible tactile de 48 est plus haute que le
              // texte), y compris quand le parent etire la pilule.
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // La forme qui double la couleur : une coche, jamais
                    // annoncee a part (la pilule dit deja `selected`).
                    if (retenue) ...<Widget>[
                      ExcludeSemantics(
                        child: IconTheme(
                          data: IconThemeData(
                            color: fond.onBackground,
                            size: tailleCoche,
                          ),
                          child: Icon(AppIcons.succes.actif),
                        ),
                      ),
                      const SizedBox(width: ecartCoche),
                    ],
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            libelle,
                            textAlign: TextAlign.center,
                            style: fond.applyTo(
                              textes.labelLarge ?? const TextStyle(),
                            ),
                          ),
                          if (compteur != null)
                            Text(
                              '$compteur',
                              style: AppTypography.tabulaire(
                                palette.inkMuted.applyTo(
                                  textes.labelMedium ?? const TextStyle(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
