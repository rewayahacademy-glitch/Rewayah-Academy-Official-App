import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Un texte dont **aucun mot n'est coupe** au milieu, meme a 200 %.
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
  const TexteSansCoupure(this.texte, {super.key, this.style, this.textAlign});

  /// Le texte.
  final String texte;

  /// Son style.
  final TextStyle? style;

  /// Son alignement.
  final TextAlign? textAlign;

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
        textScaler: echelleSansCoupure(context, texte, style, c.maxWidth),
      ),
    ),
  );
}

/// L'echelle de [context], bornee pour que le mot le plus long de [texte]
/// tienne dans [largeur].
TextScaler echelleSansCoupure(
  BuildContext context,
  String texte,
  TextStyle? style,
  double largeur,
) {
  final TextScaler echelle = MediaQuery.textScalerOf(context);
  final double facteur = echelle.scale(1);
  if (!largeur.isFinite || facteur <= 1) return echelle;
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
  if (motLong <= largeur) return echelle;
  // Une petite marge : l'arrondi des glyphes ne doit pas renvoyer la
  // derniere lettre a la ligne.
  final double borne = facteur * (largeur - 2) / motLong;
  return TextScaler.linear(borne < 1 ? 1 : borne);
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
