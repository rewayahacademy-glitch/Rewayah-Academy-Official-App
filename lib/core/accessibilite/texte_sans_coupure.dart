import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Un texte dont **aucun mot n'est coupe** au milieu, meme a 200 %.
///
/// La regle de tout libelle du produit (lecon 8, K-54, K-61) : il passe a la
/// ligne ENTRE les mots, jamais dans un mot ; un mot trop long pour sa place
/// se reduit (echelle bornee) ou son conteneur s'elargit.
///
/// Quand le mot le plus long ne tient pas dans la largeur offerte, l'echelle
/// du texte est bornee juste assez pour qu'il tienne (jamais sous 1) : le
/// texte reste agrandi autant que la place le permet, sans ellipse et sans
/// « Accessibilit / e ». Partout ailleurs, l'echelle de l'appareil est
/// gardee telle quelle.
///
/// Les dimensions intrinseques (un parent `IntrinsicWidth`) sont mesurees sur
/// le texte lui-meme, sans relancer la mise en page.
class TexteSansCoupure extends StatelessWidget {
  /// Cree le texte.
  const TexteSansCoupure(
    this.texte, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLignes,
  });

  /// Le texte.
  final String texte;

  /// Son style.
  final TextStyle? style;

  /// Son alignement.
  final TextAlign? textAlign;

  /// Le nombre de lignes vise (titre de la salle : deux a 200 %). L'echelle
  /// se reduit encore, jamais sous 1, pour que le texte y tienne ; s'il n'y
  /// tient toujours pas, il prend une ligne de plus plutot qu'une ellipse
  /// (COUPE-MOTS-1). Nul : autant de lignes qu'il faut.
  final int? maxLignes;

  @override
  Widget build(BuildContext context) => _Intrinseques(
    peintre: TextPainter(
      text: TextSpan(
        text: texte,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    ),
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) => Text(
        texte,
        style: style,
        textAlign: textAlign,
        textScaler: echelleSansCoupure(
          context,
          texte,
          style,
          c.maxWidth,
          maxLignes: maxLignes,
        ),
      ),
    ),
  );
}

/// La largeur du mot le plus long de [texte], a l'echelle [echelle].
double largeurMotLePlusLong(
  BuildContext context,
  String texte,
  TextStyle? style,
  TextScaler echelle,
) {
  final TextStyle complet = DefaultTextStyle.of(context).style.merge(style);
  double motLong = 0;
  for (final String mot in texte.split(RegExp(r'\s+'))) {
    if (mot.isEmpty) continue;
    final TextPainter p = TextPainter(
      text: TextSpan(text: mot, style: complet),
      textDirection: Directionality.of(context),
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    if (p.width > motLong) motLong = p.width;
    p.dispose();
  }
  return motLong;
}

/// Une petite marge : l'arrondi des glyphes ne doit pas renvoyer la derniere
/// lettre a la ligne.
const double _margeArrondi = 2;

/// L'echelle de [context], bornee pour que le mot le plus long de [texte]
/// tienne dans [largeur] (jamais sous 1) et, si [maxLignes] est donne, pour
/// que le texte entier tienne si possible dans ce nombre de lignes.
TextScaler echelleSansCoupure(
  BuildContext context,
  String texte,
  TextStyle? style,
  double largeur, {
  int? maxLignes,
}) {
  final TextScaler echelle = MediaQuery.textScalerOf(context);
  final double facteur = echelle.scale(1);
  if (!largeur.isFinite || facteur <= 1) return echelle;
  final double motLong = largeurMotLePlusLong(context, texte, style, echelle);
  double borne = motLong <= largeur
      ? facteur
      : facteur * (largeur - _margeArrondi) / motLong;
  if (borne < 1) borne = 1;
  if (maxLignes != null) {
    final TextStyle complet = DefaultTextStyle.of(context).style.merge(style);
    // Quelques pas de 5 % au plus : le titre garde la plus grande echelle
    // qui le fait tenir dans ses lignes.
    while (borne > 1) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: texte, style: complet),
        textDirection: Directionality.of(context),
        textScaler: TextScaler.linear(borne),
        maxLines: maxLignes,
      )..layout(maxWidth: largeur);
      final bool depasse = p.didExceedMaxLines;
      p.dispose();
      if (!depasse) break;
      borne = borne * 0.95 < 1 ? 1 : borne * 0.95;
    }
  }
  return borne == facteur ? echelle : TextScaler.linear(borne);
}

/// L'echelle **commune** a des libelles voisins (onglets, segments, rail) :
/// la plus grande, au plus celle de [context], ou le mot le plus long de
/// chaque libelle tient dans sa largeur ([largeurs], une par libelle, ou
/// une seule pour tous). Les voisins gardent ainsi la meme taille au lieu
/// d'etre reduits chacun a sa mesure (COUPE-MOTS-1 point 6).
///
/// [plancher] : l'echelle sous laquelle on ne descend pas. 1 par defaut,
/// comme [TexteSansCoupure] ; une barre de navigation de largeur fixe peut
/// passer plus bas (reduction bornee, comme un `FittedBox`) plutot que de
/// couper un mot.
TextScaler echelleCommuneSansCoupure(
  BuildContext context, {
  required List<String> textes,
  required List<double> largeurs,
  TextStyle? style,
  double plancher = 1,
}) {
  final TextScaler echelle = MediaQuery.textScalerOf(context);
  final double facteur = echelle.scale(1);
  double borne = facteur;
  for (int i = 0; i < textes.length; i++) {
    final double largeur = largeurs[largeurs.length == 1 ? 0 : i];
    if (!largeur.isFinite) continue;
    final double mot = largeurMotLePlusLong(
      context,
      textes[i],
      style,
      TextScaler.noScaling,
    );
    if (mot <= 0) continue;
    final double possible = (largeur - _margeArrondi) / mot;
    if (possible < borne) borne = possible;
  }
  if (borne < plancher) borne = plancher;
  return borne >= facteur ? echelle : TextScaler.linear(borne);
}

/// Repartit [largeur] entre des libelles voisins de largeur libre (onglets
/// d'une barre basse) : chacun recoit son mot le plus long a l'echelle
/// commune, plus [marge], puis une part egale du reste. L'echelle commune
/// est la plus grande, au plus celle de [context] et jamais sous [plancher],
/// qui laisse tenir tous ces mots ensemble : le conteneur s'elargit pour le
/// mot long au lieu de le couper (« Disponibilites »).
({TextScaler echelle, List<double> largeurs}) repartitionSansCoupure(
  BuildContext context, {
  required List<String> textes,
  required double largeur,
  TextStyle? style,
  double marge = 0,
  double plancher = 1,
}) {
  final TextScaler echelle = MediaQuery.textScalerOf(context);
  final double facteur = echelle.scale(1);
  final int n = textes.length;
  if (n == 0 || !largeur.isFinite) {
    return (echelle: echelle, largeurs: <double>[]);
  }
  final List<double> mots = <double>[
    for (final String texte in textes)
      largeurMotLePlusLong(context, texte, style, TextScaler.noScaling),
  ];
  final double somme = mots.fold<double>(0, (double a, double b) => a + b);
  final double fixe = n * (marge + _margeArrondi);
  double borne = facteur;
  if (somme > 0 && somme * borne + fixe > largeur) {
    borne = (largeur - fixe) / somme;
  }
  if (borne < plancher) borne = plancher;
  final List<double> besoins = <double>[
    for (final double m in mots) m * borne + marge + _margeArrondi,
  ];
  final double reste =
      largeur - besoins.fold<double>(0, (double a, double b) => a + b);
  return (
    echelle: borne >= facteur ? echelle : TextScaler.linear(borne),
    largeurs: reste < 0
        ? <double>[for (int i = 0; i < n; i++) largeur / n]
        : <double>[for (final double b in besoins) b + reste / n],
  );
}

/// Repond aux questions de dimensions intrinseques avec le texte mesure,
/// la ou un `LayoutBuilder` ne sait pas le faire.
class _Intrinseques extends SingleChildRenderObjectWidget {
  const _Intrinseques({required this.peintre, super.child});

  final TextPainter peintre;

  @override
  _RenduIntrinseques createRenderObject(BuildContext context) =>
      _RenduIntrinseques(peintre);

  @override
  void updateRenderObject(BuildContext context, _RenduIntrinseques rendu) {
    rendu.peintre = peintre;
  }
}

class _RenduIntrinseques extends RenderProxyBox {
  _RenduIntrinseques(this.peintre);

  TextPainter peintre;

  @override
  double computeMinIntrinsicWidth(double height) {
    peintre.layout();
    return peintre.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    peintre.layout();
    return peintre.maxIntrinsicWidth;
  }

  double _hauteur(double width) {
    peintre.layout(maxWidth: width.isFinite ? width : double.infinity);
    return peintre.height;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _hauteur(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _hauteur(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    peintre.layout(maxWidth: constraints.maxWidth);
    return constraints.constrain(peintre.size);
  }
}
