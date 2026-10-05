// La mention d'enregistrement et la notice de visite de la salle (I-1, I-2).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/permanent_notice.dart';
import '../../core/widgets/pressable.dart';
import 'cible_debordante.dart';
import 'information_controle.dart';
import 'vue_seance.dart';

/// Au repos : la mention permanente ([PermanentNotice], sans parametre).
/// Pendant une visite annoncee a ce role : le point (clignotant, sauf en
/// guidee), l'oeil en guidee, puis la notice a la place du texte, meme
/// taille, sans fond. Le libelle d'accessibilite garde la mention ET la
/// notice. Enregistrement non confirme ou seance finie : rien.
///
/// Aucun role ne voit jamais un controleur : la vue ne porte que la visite
/// d'un tuteur.
///
/// Apres la mention, pour l'eleve, un lien discret « En savoir plus » ouvre le
/// texte d'information valide le 02/10/2026 (E-1 en guidee, E-2 pour l'eleve
/// quand son contact est fourni ; [InformationControle]). Il est le meme au
/// repos et pendant une visite annoncee : rien ne change a l'arrivee d'un
/// controleur.
///
/// Le lien ne change pas la mise en page de la salle : il suit la mention sur
/// sa ligne quand elle a la place (390 et plus), centre sur le point et le
/// texte ; sinon il passe dessous, aligne sur le debut du texte, avec la
/// seule hauteur de son texte. Sa cible tactile (48, 72 en guidee) deborde
/// sans prendre de hauteur ([CibleDebordante]). Il est souligne, dans l'encre
/// de la mention : reconnaissable comme lien sans couleur ajoutee.
class MentionSeance extends StatelessWidget {
  const MentionSeance({
    required this.vue,
    super.key,
    this.lienAccepte = InformationControle.lienAccepte,
    this.contact = InformationControle.contactConfidentialite,
  });

  final VueSeance vue;

  /// Le lien « En savoir plus » est accepte (refusable, [InformationControle]).
  final bool lienAccepte;

  /// Le contact confidentialite du texte E-2.
  final String? contact;

  @override
  Widget build(BuildContext context) {
    final String? mention = vue.texteMention;
    if (mention == null) return const SizedBox.shrink();
    final Widget ligne = _ligne(context, mention);
    if (!lienAccepte ||
        !InformationControle.texteDisponible(vue.role, contact: contact)) {
      return ligne;
    }
    return _LigneEtLien(
      ligne: ligne,
      lien: _LienDiscret(
        onPress: () => unawaited(
          ouvrirInformationControle(context, vue.role, contact: contact),
        ),
      ),
    );
  }

  Widget _ligne(BuildContext context, String mention) {
    final String? notice = vue.texteNotice;
    if (notice == null) return const PermanentNotice();

    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Semantics(
      label: t.salle.seance.mentionEtNotice(mention: mention, notice: notice),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PointEnregistrement(clignote: vue.pointClignote),
          Ecart.hSm,
          if (vue.voitOeilNotice) ...<Widget>[
            IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
              child: Icon(AppIcons.observationEnCours.repos),
            ),
            Ecart.hXs,
          ],
          Flexible(child: Text(notice, style: style)),
        ],
      ),
    );
  }
}

/// Le lien « En savoir plus » : le texte souligne, dans l'encre et la taille
/// de la mention, sans surface ni fleche. Sa cible tactile est portee par
/// [CibleDebordante], sans hauteur dans la mise en page.
class _LienDiscret extends StatelessWidget {
  const _LienDiscret({required this.onPress});

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final String libelle = t.salle.informationControle.lien;
    final TextStyle style = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle())
        .copyWith(decoration: TextDecoration.underline);
    return CibleDebordante(
      child: Pressable(
        onPress: onPress,
        libelleSemantique: libelle,
        lien: true,
        respecterCibleTactile: false,
        arrondiFocus: AppRadius.arrondiSm,
        child: ExcludeSemantics(
          child: Text(libelle, style: style, softWrap: false),
        ),
      ),
    );
  }
}

/// La mention et son lien : sur la meme ligne quand la mention, a sa largeur
/// naturelle, laisse la place du lien ; sinon le lien passe dessous, au
/// retrait du texte (apres le point). Jamais de hauteur au-dela de celle du
/// texte du lien.
class _LigneEtLien extends MultiChildRenderObjectWidget {
  _LigneEtLien({required Widget ligne, required Widget lien})
    : super(children: <Widget>[ligne, lien]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLigneEtLien(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLigneEtLien renderObject,
  ) {
    renderObject.sens = Directionality.of(context);
  }
}

class _ParentLigneEtLien extends ContainerBoxParentData<RenderBox> {}

class _RenderLigneEtLien extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentLigneEtLien>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentLigneEtLien> {
  _RenderLigneEtLien(this._sens);

  /// L'ecart entre la fin de la mention et le lien, sur une meme ligne.
  static const double ecart = AppSpacing.xs;

  /// Le retrait du lien quand il passe dessous : le debut du texte.
  static const double retrait = PointEnregistrement.diametre + AppSpacing.sm;

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) return;
    _sens = valeur;
    markNeedsLayout();
  }

  RenderBox get _ligne => firstChild!;
  RenderBox get _lien => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParentLigneEtLien) {
      child.parentData = _ParentLigneEtLien();
    }
  }

  bool _surUneLigne(double largeurLien, double largeurMax) =>
      _ligne.getMaxIntrinsicWidth(double.infinity) + ecart + largeurLien <=
      largeurMax;

  ({Size taille, Offset ligne, Offset lien}) _placer(
    BoxConstraints contraintes,
    Size Function(RenderBox enfant, BoxConstraints c) mesurer,
  ) {
    final double largeurMax = contraintes.maxWidth;
    final Size lien = mesurer(_lien, BoxConstraints(maxWidth: largeurMax));
    if (_surUneLigne(lien.width, largeurMax)) {
      final Size ligne = mesurer(
        _ligne,
        BoxConstraints(maxWidth: largeurMax - ecart - lien.width),
      );
      final double hauteur = ligne.height > lien.height
          ? ligne.height
          : lien.height;
      final Size taille = contraintes.constrain(
        Size(ligne.width + ecart + lien.width, hauteur),
      );
      return (
        taille: taille,
        ligne: _miroir(taille, 0, (hauteur - ligne.height) / 2, ligne),
        lien: _miroir(
          taille,
          ligne.width + ecart,
          (hauteur - lien.height) / 2,
          lien,
        ),
      );
    }
    final Size ligne = mesurer(_ligne, BoxConstraints(maxWidth: largeurMax));
    final double largeur = ligne.width > retrait + lien.width
        ? ligne.width
        : retrait + lien.width;
    final Size taille = contraintes.constrain(
      Size(largeur, ligne.height + lien.height),
    );
    return (
      taille: taille,
      ligne: _miroir(taille, 0, 0, ligne),
      lien: _miroir(taille, retrait, ligne.height, lien),
    );
  }

  Offset _miroir(Size taille, double x, double y, Size enfant) =>
      _sens == TextDirection.ltr
      ? Offset(x, y)
      : Offset(taille.width - x - enfant.width, y);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => _placer(
    constraints,
    (RenderBox enfant, BoxConstraints c) => enfant.getDryLayout(c),
  ).taille;

  @override
  void performLayout() {
    final ({Size taille, Offset ligne, Offset lien}) p = _placer(constraints, (
      RenderBox enfant,
      BoxConstraints c,
    ) {
      enfant.layout(c, parentUsesSize: true);
      return enfant.size;
    });
    size = p.taille;
    (_ligne.parentData! as _ParentLigneEtLien).offset = p.ligne;
    (_lien.parentData! as _ParentLigneEtLien).offset = p.lien;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double a = _ligne.getMinIntrinsicWidth(height);
    final double b = retrait + _lien.getMinIntrinsicWidth(height);
    return a > b ? a : b;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _ligne.getMaxIntrinsicWidth(height) +
      ecart +
      _lien.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _placer(
    BoxConstraints(maxWidth: width),
    (RenderBox enfant, BoxConstraints c) => enfant.getDryLayout(c),
  ).taille.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
