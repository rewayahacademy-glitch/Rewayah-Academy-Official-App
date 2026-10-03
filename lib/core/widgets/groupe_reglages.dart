import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_elevation.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Une rubrique d'un [GroupeReglages] : icone (ou meneur), libelle, legende
/// ou valeur, chevron quand elle mene ailleurs.
@immutable
class LigneRubrique {
  /// Cree une rubrique. Il faut une [icone] ou un [meneur].
  const LigneRubrique({
    required this.libelle,
    this.icone,
    this.meneur,
    this.legende,
    this.valeur,
    this.onPress,
    this.controle,
    this.marque,
    this.pastille,
    this.pastilleSousLibelle,
    this.selectionnee,
    this.libelleSemantique,
    this.autofocus = false,
    this.cochee,
    this.focusNode,
  });

  /// Case d'une liste de verifications : annoncee (`Semantics.checked`). Non
  /// nulle, la ligne se presse (bascule) sans chevron. Nul : pas une case.
  final bool? cochee;

  /// Le noeud de focus de la ligne pressable, pour qu'un ecran y pose le
  /// focus ou l'y rende (fermeture du panneau de la fiche eleve, EN-12).
  final FocusNode? focusNode;

  /// L'icone de la rubrique, en encre d'accent.
  final AppIcon? icone;

  /// Ce qui tient la tete de ligne a la place de l'icone : l'avatar ou
  /// l'initiale d'un membre du Foyer (demande B-1). Largeur libre ; le filet
  /// commence apres lui, au meme retrait qu'apres une icone. Il n'a pas de
  /// semantique propre a porter : la ligne est lue par son libelle.
  final Widget? meneur;

  /// Le nom de la rubrique : « Informations personnelles ».
  final String libelle;

  /// Une ligne de resume sous le libelle : « Nom, courriel, fuseau ».
  final String? legende;

  /// Une valeur courte en fin de ligne : « Systeme », « Francais ».
  final String? valeur;

  /// La destination. Avec elle, la ligne porte un chevron et se presse.
  final VoidCallback? onPress;

  /// Un controle natif en fin de ligne (interrupteur). Il garde son propre
  /// geste et sa propre semantique : la ligne ne se presse alors pas.
  final Widget? controle;

  /// Une marque d'etat en fin de ligne, sans geste propre : une `StatusPill`,
  /// un `PointRappel` (EN-3). Elle est lue avec la ligne et, contrairement a
  /// [controle], elle n'empeche pas la ligne de se presser.
  final Widget? marque;

  /// Une pastille d'etat dans le flux du libelle : a cote du nom quand la
  /// place suffit, dessous sinon (AD-5).
  final Widget? pastille;

  /// Place de la [pastille] imposee par la liste, pour que toutes ses lignes
  /// la posent au meme endroit : vrai, sous le libelle ; faux, a cote. Nul :
  /// chaque ligne decide selon sa place (Wrap).
  final bool? pastilleSousLibelle;

  /// Selection d'une file maitre-detail : annoncee (`Semantics.selected`) et
  /// marquee autrement que par la couleur (barre de debut, graisse). Nul :
  /// la ligne n'est pas selectionnable.
  final bool? selectionnee;

  /// Ce que la ligne pressable dit de son action au lecteur d'ecran, quand
  /// le libelle seul ne la nomme pas : « Ajuster · Aya » (W-243).
  final String? libelleSemantique;

  /// Prend le focus a l'apparition (retour d'un detail vers sa ligne).
  final bool autofocus;
}

/// Un groupe de rubriques a filets en retrait : le hub du Compte, la fiche
/// d'un eleve, les Preferences (maquettes V3, V4 ; manifeste visuel Tuteur V1
/// section 3.4).
///
/// **Une seule surface pour tout le groupe**, jamais une carte par ligne :
/// « Hub Reglages : un seul groupe a filets, pas quatre cartes » (V4). Les
/// filets separent les lignes et commencent apres l'icone, comme les listes
/// groupees des deux plateformes.
///
/// Chaque ligne fait au moins 48 de haut (cible tactile) et grandit avec le
/// texte ; a 200 %, la valeur passe sous le libelle au lieu de le couper.
class GroupeReglages extends StatelessWidget {
  /// Cree un groupe.
  const GroupeReglages({required this.lignes, super.key, this.titre});

  /// Le titre du groupe, au-dessus de la surface. Facultatif.
  final String? titre;

  /// Les rubriques, dans l'ordre d'affichage.
  final List<LigneRubrique> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (titre != null) ...<Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(
              titre!,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
        ],
        DecoratedBox(
          decoration: AppElevation.avecFilet(
            surface: palette.surfaceRaised,
            filet: palette.contourCarte,
            ombre: palette.ombre,
            arrondi: AppRadius.arrondiMd,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.arrondiMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < lignes.length; i++)
                  _Ligne(ligne: lignes[i], filet: i < lignes.length - 1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({required this.ligne, required this.filet});

  final LigneRubrique ligne;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    // Une ligne a controle ne se presse pas : l'interrupteur garde son geste.
    if (ligne.controle != null || ligne.onPress == null) {
      return MergeSemantics(
        child: Semantics(
          checked: ligne.cochee,
          child: _contenu(context, const EtatPression()),
        ),
      );
    }
    return Pressable.selon(
      onPress: ligne.onPress,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      libelleSemantique: ligne.libelleSemantique,
      selectionne: ligne.selectionnee,
      coche: ligne.cochee,
      focusNode: ligne.focusNode,
      autofocus: ligne.autofocus,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool choisie = ligne.selectionnee ?? false;
    final Color fond = etat.survole || etat.presse || choisie
        ? Color.alphaBlend(
            palette.calqueInteraction(presse: etat.presse),
            palette.surfaceRaised.background,
          )
        : palette.surfaceRaised.background;
    final Widget? tete =
        ligne.meneur ??
        (ligne.icone == null
            ? null
            : IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                child: Icon(ligne.icone!.repos),
              ));

    return DecoratedBox(
      // La selection ne tient pas a la seule teinte : une barre de 4 au bord
      // de debut, en encre d'accent (jeton existant).
      decoration: BoxDecoration(
        color: fond,
        border: choisie
            ? BorderDirectional(
                start: palette.inkAccent.asBorderSide(width: AppSpacing.xs),
              )
            : null,
      ),
      // Le filet d'une decoration ne prend aucune place : le retrait reste le
      // meme, selectionnee ou non (le contenu ne saute pas de 4).
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            if (tete != null) ...<Widget>[tete, Ecart.hMd],
            Expanded(
              // Le filet en retrait : il court sous le texte, pas sous
              // l'icone, et s'arrete a la derniere ligne du groupe.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: filet
                      ? Border(bottom: palette.contourCarte.asBorderSide())
                      : null,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppTouchTarget.standard,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.md,
                      end: AppSpacing.lg,
                    ),
                    child: ligne.controle != null
                        ? _RangeeMesuree(
                            sens: Directionality.of(context),
                            children: <Widget>[
                              _textes(palette, textes),
                              ligne.controle!,
                            ],
                          )
                        // Sans marque, aucune mesure : la ligne reste compatible
                        // avec les parents qui demandent des dimensions
                        // intrinseques.
                        : ligne.marque == null
                        ? _rangee(palette, textes, double.infinity, context)
                        : LayoutBuilder(
                            builder: (BuildContext _, BoxConstraints c) =>
                                _rangee(palette, textes, c.maxWidth, context),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// La marque reste en fin de ligne tant qu'elle laisse de la place au
  /// texte ; a grande taille de texte ou sur une ligne etroite, elle passe
  /// sous la legende, au bord de debut, au lieu de deborder.
  Widget _rangee(
    AppPalette palette,
    TextTheme textes,
    double largeur,
    BuildContext context,
  ) {
    final Widget? marque = ligne.marque;
    final bool marqueDessous =
        marque != null &&
        (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
            largeur < _largeurMarqueEnFin);
    return Row(
      children: <Widget>[
        Expanded(
          child: marqueDessous
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _textes(palette, textes),
                    Ecart.vSm,
                    marque,
                  ],
                )
              : _textes(palette, textes),
        ),
        // CORR-SUITE-2 : en fin de ligne, la marque est bornee par la ligne
        // elle-meme (deux tiers de sa largeur, le reste au libelle), plus par
        // une largeur fixe posee par l'ecran : une marque longue (« Cahier de
        // transmission a valider ») tient sur une ligne des que la place le
        // permet, et passe a la ligne entre ses mots sinon.
        if (marque != null && !marqueDessous) ...<Widget>[
          Ecart.hSm,
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: largeur * _partMarqueEnFin),
            child: marque,
          ),
        ],
        if (ligne.controle != null) ...<Widget>[Ecart.hSm, ligne.controle!],
        if (ligne.onPress != null &&
            ligne.controle == null &&
            ligne.cochee == null) ...<Widget>[
          Ecart.hSm,
          ExcludeSemantics(
            child: IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
              child: Icon(AppIcons.chevron.repos),
            ),
          ),
        ],
      ],
    );
  }

  /// En dessous de cette largeur de texte, la marque passe sous la legende.
  static const double _largeurMarqueEnFin = 320;

  /// La part de la ligne que peut prendre une marque en fin de ligne.
  static const double _partMarqueEnFin = 2 / 3;

  Widget _textes(AppPalette palette, TextTheme textes) {
    final TextStyle styleSecondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    // Libelle et valeur partagent la ligne tant qu'ils tiennent ; sinon la
    // valeur passe dessous (Wrap), sans jamais couper un mot. Le Wrap prend
    // toute la largeur (MA-GR-1) : sur une seule ligne, spaceBetween pousse
    // la valeur au bord de fin ; seule sur sa ligne, elle reste au debut.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              // COUPE-MOTS-1 : libelle, valeur et legende passent a la ligne
              // entre les mots, jamais dans un mot (« Assurer ce
              // remplacem / ent ? » a 200 %, 320 px).
              TexteSansCoupure(
                ligne.libelle,
                key: const ValueKey<String>('groupe-reglages-libelle'),
                style: palette.inkStrong
                    .applyTo(textes.bodyLarge ?? const TextStyle())
                    .copyWith(
                      fontWeight: (ligne.selectionnee ?? false)
                          ? FontWeight.w600
                          : null,
                    ),
              ),
              if (ligne.pastille != null && ligne.pastilleSousLibelle != true)
                ligne.pastille!,
              if (ligne.valeur != null)
                TexteSansCoupure(
                  ligne.valeur!,
                  key: const ValueKey<String>('groupe-reglages-valeur'),
                  style: styleSecondaire,
                ),
            ],
          ),
        ),
        if (ligne.pastille != null &&
            ligne.pastilleSousLibelle == true) ...<Widget>[
          Ecart.vXs,
          ligne.pastille!,
        ],
        if (ligne.legende != null) ...<Widget>[
          Ecart.vXs,
          TexteSansCoupure(ligne.legende!, style: styleSecondaire),
        ],
      ],
    );
  }
}

/// Le libelle et le controle de fin de ligne, places par une MESURE (HL-A-3) :
/// cote a cote tant que le mot le plus long du libelle, l'ecart de 8 et la
/// largeur naturelle du controle tiennent dans la largeur disponible ; sinon
/// le controle passe sous le libelle, aligne en fin, a 4. Aucun seuil fixe
/// d'echelle ni de largeur d'ecran.
class _RangeeMesuree extends MultiChildRenderObjectWidget {
  const _RangeeMesuree({required this.sens, required super.children});

  final TextDirection sens;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduRangeeMesuree(sens);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduRangeeMesuree renderObject,
  ) {
    renderObject.sens = sens;
  }
}

class _DonneesRangee extends ContainerBoxParentData<RenderBox> {}

class _RenduRangeeMesuree extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesRangee>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesRangee> {
  _RenduRangeeMesuree(this._sens);

  static const double _ecartCote = AppSpacing.sm;
  static const double _ecartDessous = AppSpacing.xs;

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) {
      return;
    }
    _sens = valeur;
    markNeedsLayout();
  }

  RenderBox get _textes => firstChild!;
  RenderBox get _controle => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonneesRangee) {
      child.parentData = _DonneesRangee();
    }
  }

  /// Vrai : le controle tient a cote du libelle dans [largeur].
  bool _cote(double largeur) =>
      !largeur.isFinite ||
      _textes.getMinIntrinsicWidth(double.infinity) +
              _ecartCote +
              _controle.getMaxIntrinsicWidth(double.infinity) <=
          largeur;

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _textes.getMinIntrinsicWidth(height),
    _controle.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _textes.getMaxIntrinsicWidth(height) +
      _ecartCote +
      _controle.getMaxIntrinsicWidth(height);

  double _hauteur(double largeur, bool max) {
    double h(RenderBox b, double w) =>
        max ? b.getMaxIntrinsicHeight(w) : b.getMinIntrinsicHeight(w);
    if (_cote(largeur)) {
      final double c = _controle.getMaxIntrinsicWidth(double.infinity);
      return math.max(
        h(_textes, largeur.isFinite ? largeur - c - _ecartCote : largeur),
        h(_controle, c),
      );
    }
    return h(_textes, largeur) + _ecartDessous + h(_controle, largeur);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _hauteur(width, false);

  @override
  double computeMaxIntrinsicHeight(double width) => _hauteur(width, true);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _placer(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    size = _placer(constraints, ChildLayoutHelper.layoutChild, placer: true);
  }

  Size _placer(
    BoxConstraints contraintes,
    ChildLayouter disposer, {
    bool placer = false,
  }) {
    final double largeur = contraintes.maxWidth;
    final bool finSurDroite = _sens == TextDirection.ltr;
    if (_cote(largeur)) {
      final Size c = disposer(
        _controle,
        BoxConstraints(maxHeight: contraintes.maxHeight),
      );
      final double wTextes = largeur.isFinite
          ? math.max(0, largeur - c.width - _ecartCote)
          : _textes.getMaxIntrinsicWidth(double.infinity);
      final Size t = disposer(
        _textes,
        BoxConstraints.tightFor(width: wTextes)
            .copyWith(maxHeight: contraintes.maxHeight),
      );
      final double w = wTextes + _ecartCote + c.width;
      final double h = math.max(t.height, c.height);
      if (placer) {
        (_textes.parentData! as _DonneesRangee).offset = Offset(
          finSurDroite ? 0 : w - t.width,
          (h - t.height) / 2,
        );
        (_controle.parentData! as _DonneesRangee).offset = Offset(
          finSurDroite ? w - c.width : 0,
          (h - c.height) / 2,
        );
      }
      return contraintes.constrain(Size(w, h));
    }
    final Size t = disposer(_textes, BoxConstraints.tightFor(width: largeur));
    final Size c = disposer(_controle, BoxConstraints(maxWidth: largeur));
    final double h = t.height + _ecartDessous + c.height;
    if (placer) {
      (_textes.parentData! as _DonneesRangee).offset = Offset.zero;
      (_controle.parentData! as _DonneesRangee).offset = Offset(
        finSurDroite ? largeur - c.width : 0,
        t.height + _ecartDessous,
      );
    }
    return contraintes.constrain(Size(largeur, h));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
