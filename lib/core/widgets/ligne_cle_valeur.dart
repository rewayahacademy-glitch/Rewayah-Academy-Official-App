import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pastille_etat_seance.dart';

/// Une ligne « cle : valeur » de fiche de detail : « Horaire : 18:00 (heure
/// de Paris) », « Presence : En cours de verification » (detail de seance et
/// detail d'observation, manifeste visuel Tuteur V1 section 3.4).
///
/// La cle se lit en encre attenuee, la valeur en encre forte. Cote a cote
/// quand la place le permet, **empilees des que le texte est agrandi**
/// (`AppGabarit.seuilTexteColonne`) : a 200 %, deux colonnes coupent les
/// mots, une pile ne coupe rien.
///
/// Le lecteur d'ecran lit la cle puis la valeur, en un seul noeud
/// (`MergeSemantics`) : une valeur lue seule, « 18:00 », ne dit rien.
class LigneCleValeur extends StatelessWidget {
  /// Cree une ligne.
  const LigneCleValeur({
    required this.cle,
    required this.valeur,
    super.key,
    this.complement,
    this.chiffres = false,
    this.annulee = false,
    this.detailCle,
    this.meneur,
    this.valeurForte = false,
    this.valeurEnFin = false,
  });

  /// La marge au-dessus et au-dessous de la ligne : un bandeau de profil
  /// pose en [meneur] y remonte sans depasser la ligne (`BandeauProfil`,
  /// `remontee`).
  static const double margeVerticale = AppSpacing.sm;

  /// Ce que la valeur designe : « Horaire », « Duree », « Presence ».
  final String cle;

  /// La valeur, deja mise en mots par le service ou l'ecran.
  final String valeur;

  /// Un element pose apres la valeur : une pastille d'etat, par exemple.
  final Widget? complement;

  /// Vrai pour une valeur faite de chiffres (horaire, duree, code) : chiffres
  /// tabulaires, qui ne dansent pas d'une ligne a l'autre.
  final bool chiffres;

  /// Vrai quand la valeur est l'horaire d'une seance annulee : barree et
  /// attenuee, annoncee « Annulee : ... » (ANNUL-VIS-1).
  final bool annulee;

  /// Une precision sous la cle, en plus petit : la date d'un mouvement, la
  /// periode d'un profil (lignes d'argent, FI-3a).
  final String? detailCle;

  /// Ce qui se pose avant la cle : l'avatar d'un profil (lignes d'argent,
  /// FI-3a). Reste en tete quand la ligne s'empile.
  final Widget? meneur;

  /// Vrai pour une valeur qui conclut un bloc (un total) : au rang des noms
  /// et titres de carte (`titleMedium`) au lieu du corps.
  final bool valeurForte;

  /// Vrai pour une valeur posee au bord de fin de la ligne (droite en LTR,
  /// gauche en RTL) : les montants des lignes d'argent (revue FI-3-R, M1 ;
  /// guide Finance V4 §7, §11.3 « colonnes calmes et stables »). Les fins de
  /// montants d'une meme carte tombent alors sur un seul bord, et les
  /// chiffres tabulaires alignent les decimales. Le complement (une
  /// pastille) passe avant la valeur, pour que le montant reste au bord.
  /// Faux par defaut : les autres lignes gardent leur valeur au debut.
  final bool valeurEnFin;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base =
        (valeurForte ? textes.titleMedium : textes.bodyLarge) ??
        const TextStyle();
    final TextStyle styleValeur = palette.inkStrong.applyTo(
      chiffres ? AppTypography.tabulaire(base) : base,
    );
    // COUPE-MOTS-1 : la cle passe a la ligne entre les mots, a la taille du
    // theme ; un mot trop long pour sa colonne (« Reconnexions » a 320 px,
    // texte a 100 %) ne se reduit pas : la cle passe au-dessus de la valeur,
    // sur toute la largeur (voir [_cleTientEnColonne]).
    final TextStyle styleCle = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final Widget libelleCle = TexteSansCoupure(cle, style: styleCle);
    final String? detail = detailCle;
    final Widget texteCle = detail == null
        ? libelleCle
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              libelleCle,
              TexteSansCoupure(
                detail,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          );
    final Widget texteValeur = annulee
        ? TexteHeureSeance(heure: valeur, annulee: true, style: styleValeur)
        : TexteSansCoupure(
            valeur,
            style: styleValeur,
            textAlign: valeurEnFin ? TextAlign.end : null,
          );
    final Widget blocValeur = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      alignment: valeurEnFin ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (valeurEnFin) ?complement,
        texteValeur,
        if (!valeurEnFin) ?complement,
      ],
    );
    final bool grandTexte =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;

    // Le mot le plus long de la cle, mesure une fois : la disposition se
    // choisit a la mise en page, sans `LayoutBuilder` (une ligne posee sous
    // un `IntrinsicHeight`, Vue globale de la Finance, doit donner sa
    // hauteur intrinseque). Cote a cote : la cle sur deux cinquiemes, la
    // valeur sur trois ; empilee : la cle au-dessus, la valeur dessous, a
    // son bord (celui de fin pour un montant).
    final double motLong = largeurMotLePlusLong(
      context,
      cle,
      styleCle,
      MediaQuery.textScalerOf(context),
    );
    final Widget mesure = _Disposition(
      empilee: (double largeur) =>
          grandTexte || !_cleTientEnColonne(motLong, largeur),
      valeurEnFin: valeurEnFin,
      sens: Directionality.of(context),
      children: <Widget>[texteCle, blocValeur],
    );
    final Widget? tete = meneur;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: margeVerticale),
        child: tete == null
            ? mesure
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  tete,
                  Ecart.hMd,
                  Expanded(child: mesure),
                ],
              ),
      ),
    );
  }

  /// Vrai quand le mot le plus long de la cle ([motLong], a l'echelle de
  /// l'appareil) tient dans sa colonne (deux cinquiemes de la ligne, ecart
  /// retire).
  static bool _cleTientEnColonne(double motLong, double w) {
    if (!w.isFinite) return true;
    final double colonne = (w - AppSpacing.lg) * 2 / 5;
    return motLong <= colonne - 2;
  }
}

/// Pose la cle (premier enfant) et la valeur (second) cote a cote, la cle
/// sur deux cinquiemes et la valeur sur trois, separees de `AppSpacing.lg` ;
/// ou empilees quand [empilee] le dit pour la largeur recue : la cle, puis
/// `AppSpacing.xs`, puis la valeur, au bord de debut, ou de fin avec
/// [valeurEnFin]. Contrairement a un `LayoutBuilder`, il rend ses dimensions
/// intrinseques.
class _Disposition extends MultiChildRenderObjectWidget {
  const _Disposition({
    required this.empilee,
    required this.valeurEnFin,
    required this.sens,
    required super.children,
  });

  final bool Function(double largeur) empilee;
  final bool valeurEnFin;
  final TextDirection sens;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenduDisposition(empilee, valeurEnFin, sens);

  @override
  void updateRenderObject(BuildContext context, _RenduDisposition rendu) {
    rendu
      ..empilee = empilee
      ..valeurEnFin = valeurEnFin
      ..sens = sens;
  }
}

class _DonneesDisposition extends ContainerBoxParentData<RenderBox> {}

class _RenduDisposition extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesDisposition>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesDisposition> {
  _RenduDisposition(this._empilee, this._valeurEnFin, this._sens);

  static const double _ecartLigne = AppSpacing.lg;
  static const double _ecartPile = AppSpacing.xs;

  bool Function(double largeur) _empilee;
  set empilee(bool Function(double largeur) valeur) {
    _empilee = valeur;
    markNeedsLayout();
  }

  bool _valeurEnFin;
  set valeurEnFin(bool valeur) {
    if (valeur == _valeurEnFin) return;
    _valeurEnFin = valeur;
    markNeedsLayout();
  }

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur == _sens) return;
    _sens = valeur;
    markNeedsLayout();
  }

  RenderBox get _cle => firstChild!;
  RenderBox get _valeur => lastChild!;

  double _largeurCle(double w) => (w - _ecartLigne) * 2 / 5;
  double _largeurValeur(double w) => (w - _ecartLigne) * 3 / 5;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonneesDisposition) {
      child.parentData = _DonneesDisposition();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _cle.getMinIntrinsicWidth(double.infinity),
    _valeur.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _cle.getMaxIntrinsicWidth(double.infinity) +
      _ecartLigne +
      _valeur.getMaxIntrinsicWidth(double.infinity);

  double _hauteur(double w) => _empilee(w)
      ? _cle.getMaxIntrinsicHeight(w) +
            _ecartPile +
            _valeur.getMaxIntrinsicHeight(w)
      : math.max(
          _cle.getMaxIntrinsicHeight(_largeurCle(w)),
          _valeur.getMaxIntrinsicHeight(_largeurValeur(w)),
        );

  @override
  double computeMinIntrinsicHeight(double width) => _hauteur(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _hauteur(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final double w = constraints.maxWidth;
    if (_empilee(w)) {
      final BoxConstraints libre = BoxConstraints(maxWidth: w);
      final Size c = _cle.getDryLayout(libre);
      final Size v = _valeur.getDryLayout(libre);
      return constraints.constrain(Size(w, c.height + _ecartPile + v.height));
    }
    final Size c = _cle.getDryLayout(
      BoxConstraints.tightFor(width: _largeurCle(w)),
    );
    final Size v = _valeur.getDryLayout(
      BoxConstraints.tightFor(width: _largeurValeur(w)),
    );
    return constraints.constrain(Size(w, math.max(c.height, v.height)));
  }

  @override
  void performLayout() {
    final double w = constraints.maxWidth;
    final _DonneesDisposition dCle = _cle.parentData! as _DonneesDisposition;
    final _DonneesDisposition dValeur =
        _valeur.parentData! as _DonneesDisposition;
    final bool rtl = _sens == TextDirection.rtl;
    if (_empilee(w)) {
      final BoxConstraints libre = BoxConstraints(maxWidth: w);
      _cle.layout(libre, parentUsesSize: true);
      _valeur.layout(libre, parentUsesSize: true);
      final double xCle = rtl ? w - _cle.size.width : 0;
      final bool auBordDeFin = _valeurEnFin;
      final double xValeur = (rtl != auBordDeFin) ? w - _valeur.size.width : 0;
      dCle.offset = Offset(xCle, 0);
      dValeur.offset = Offset(xValeur, _cle.size.height + _ecartPile);
      size = constraints.constrain(
        Size(w, _cle.size.height + _ecartPile + _valeur.size.height),
      );
      return;
    }
    final double lc = _largeurCle(w);
    final double lv = _largeurValeur(w);
    _cle.layout(BoxConstraints.tightFor(width: lc), parentUsesSize: true);
    _valeur.layout(BoxConstraints.tightFor(width: lv), parentUsesSize: true);
    dCle.offset = Offset(rtl ? w - lc : 0, 0);
    dValeur.offset = Offset(rtl ? 0 : w - lv, 0);
    size = constraints.constrain(
      Size(w, math.max(_cle.size.height, _valeur.size.height)),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
