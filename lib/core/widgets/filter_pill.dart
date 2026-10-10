import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../accessibilite/texte_sans_coupure.dart';
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
/// pilule est plus large de la place de la coche (24 px). Seul cas ou la
/// pilule change de forme : quand le libelle occupe deja toute la largeur
/// (320 px, texte x2, mot long), la coche passe au-dessus du libelle plutot
/// que de lui couper un mot ; la largeur reste la meme, la hauteur grandit
/// de [hauteurCocheEmpilee].
class FilterPill extends StatelessWidget {
  /// Cree une pilule de filtre.
  const FilterPill({
    required this.libelle,
    required this.onPress,
    super.key,
    this.retenue = false,
    this.compteur,
    this.apercu,
    this.focusNode,
  });

  /// TB-7b : un apercu peint avant le libelle (la pastille d'une couleur
  /// d'encre). Il ne remplace jamais le libelle ; muet au lecteur d'ecran.
  final Widget? apercu;

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

  /// La place de la coche sur la ligne du libelle.
  static const double _reserve = tailleCoche + ecartCoche;

  /// Ce qu'une pilule retenue gagne en hauteur quand la place manque et que
  /// la coche passe au-dessus du libelle (`RangeePuces` le prevoit).
  static const double hauteurCocheEmpilee = tailleCoche + AppSpacing.xs;

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

        final Widget libelleEtCompteur = Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            // Aucun mot coupe (COUPE-MOTS-4 sur les puces de motifs de
            // FORM-L1, reuni par JONCTION-LIGNES-1) : un mot plus long que la
            // puce reduit juste assez l'echelle au lieu de se couper.
            if (apercu case final Widget a) a,
            TexteSansCoupure(
              libelle,
              textAlign: TextAlign.center,
              style: fond.applyTo(textes.labelLarge ?? const TextStyle()),
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
        );

        return ExcludeSemantics(
          child: DecoratedBox(
            decoration: fond.decoration(
              borderRadius: AppRadius.arrondiFull,
              side: filet,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              // K-54 : le contenu est centre dans la pilule, en largeur comme
              // en hauteur (la cible tactile de 48 est plus haute que le
              // texte), y compris quand le parent etire la pilule.
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                // La place de la coche est reservee dans les deux etats
                // (`_PlaceCoche`) : meme largeur retenue ou non. Quand elle
                // manque (320 px, texte x2, mot long), le libelle garde toute
                // la largeur et la coche passe au-dessus de lui : jamais un
                // mot coupe pour la coche.
                child: _PlaceCoche(
                  children: <Widget>[
                    libelleEtCompteur,
                    // La forme qui double la couleur.
                    if (retenue)
                      IconTheme(
                        data: IconThemeData(
                          color: fond.onBackground,
                          size: tailleCoche,
                        ),
                        child: Icon(AppIcons.succes.actif),
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

/// Le contenu d'une pilule : le libelle (et son compteur), et la coche quand
/// la pilule est retenue.
///
/// La largeur vaut `min(largeur offerte, libelle + place de la coche)` dans
/// les deux etats : au repos, la place est de l'air a parts egales des deux
/// cotes du libelle centre ; retenue, la coche l'occupe, devant le libelle
/// dans le sens de lecture. Quand la place manque, le libelle garde toute la
/// largeur offerte et la coche passe au-dessus de lui, centree, a
/// `AppSpacing.xs` (la pilule grandit alors de
/// [FilterPill.hauteurCocheEmpilee], jamais en largeur).
class _PlaceCoche extends MultiChildRenderObjectWidget {
  const _PlaceCoche({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduPlaceCoche(Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenduPlaceCoche rendu) {
    rendu.sens = Directionality.of(context);
  }
}

class _DonneesPlaceCoche extends ContainerBoxParentData<RenderBox> {}

class _RenduPlaceCoche extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesPlaceCoche>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesPlaceCoche> {
  _RenduPlaceCoche(this._sens);

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) return;
    _sens = valeur;
    markNeedsLayout();
  }

  static const double _reserve = FilterPill._reserve;

  RenderBox get _libelle => firstChild!;
  RenderBox? get _coche => childAfter(firstChild!);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonneesPlaceCoche) {
      child.parentData = _DonneesPlaceCoche();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _libelle.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _libelle.getMaxIntrinsicWidth(height) + _reserve;

  /// Vrai quand la coche ne tient pas sur la ligne du libelle.
  bool _empilee(double largeurLibelle, double largeurMax) =>
      _coche != null && largeurLibelle + _reserve > largeurMax;

  double _hauteur(double largeur) {
    final double libelle = _libelle.getMaxIntrinsicHeight(largeur);
    final RenderBox? coche = _coche;
    if (coche == null) return libelle;
    final double hCoche = coche.getMaxIntrinsicHeight(double.infinity);
    return _empilee(_libelle.getMaxIntrinsicWidth(double.infinity), largeur)
        ? libelle + AppSpacing.xs + hCoche
        : math.max(libelle, hCoche);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _hauteur(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _hauteur(width);

  Size _mesurer(BoxConstraints contraintes, {required bool poser}) {
    final BoxConstraints libres = BoxConstraints(
      maxWidth: contraintes.maxWidth,
    );
    final Size libelle = poser
        ? (_libelle..layout(libres, parentUsesSize: true)).size
        : _libelle.getDryLayout(libres);
    final RenderBox? coche = _coche;
    final Size taCoche = coche == null
        ? Size.zero
        : poser
        ? (coche..layout(const BoxConstraints(), parentUsesSize: true)).size
        : coche.getDryLayout(const BoxConstraints());
    final double largeur = math.min(
      contraintes.maxWidth,
      libelle.width + _reserve,
    );
    final bool empilee = _empilee(libelle.width, contraintes.maxWidth);
    final double hauteur = coche == null
        ? libelle.height
        : empilee
        ? libelle.height + AppSpacing.xs + taCoche.height
        : math.max(libelle.height, taCoche.height);
    final Size taille = contraintes.constrain(Size(largeur, hauteur));
    if (poser) {
      // Le groupe (coche, ecart, libelle) ou le libelle seul, centre.
      if (coche == null || empilee) {
        double y = (taille.height - hauteur) / 2;
        if (coche != null) {
          (coche.parentData! as _DonneesPlaceCoche).offset = Offset(
            (taille.width - taCoche.width) / 2,
            y,
          );
          y += taCoche.height + AppSpacing.xs;
        }
        (_libelle.parentData! as _DonneesPlaceCoche).offset = Offset(
          (taille.width - libelle.width) / 2,
          y,
        );
      } else {
        final double groupe =
            taCoche.width + FilterPill.ecartCoche + libelle.width;
        final double debut = (taille.width - groupe) / 2;
        final double xCoche = _sens == TextDirection.ltr
            ? debut
            : debut + groupe - taCoche.width;
        final double xLibelle = _sens == TextDirection.ltr
            ? debut + taCoche.width + FilterPill.ecartCoche
            : debut;
        (coche.parentData! as _DonneesPlaceCoche).offset = Offset(
          xCoche,
          (taille.height - taCoche.height) / 2,
        );
        (_libelle.parentData! as _DonneesPlaceCoche).offset = Offset(
          xLibelle,
          (taille.height - libelle.height) / 2,
        );
      }
    }
    return taille;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _mesurer(constraints, poser: false);

  @override
  void performLayout() {
    size = _mesurer(constraints, poser: true);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
