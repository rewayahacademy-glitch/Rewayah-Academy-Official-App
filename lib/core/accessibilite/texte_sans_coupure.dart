import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Un texte dont **aucun mot n'est coupe** au milieu, meme a 200 %.
///
/// La regle de tout libelle du produit (lecon 8, K-54, K-61) : il passe a la
/// ligne ENTRE les mots, jamais dans un mot ; un mot trop long pour sa place
/// se reduit (echelle bornee) ou son conteneur s'elargit.
///
/// Quand le mot le plus long ne tient pas dans la largeur offerte, l'echelle
/// du texte est bornee juste assez pour qu'il tienne, jamais sous
/// [echelleMinimaleLisible] (0,85) : le texte reste agrandi autant que la
/// place le permet, sans ellipse et sans « Accessibilit / e ». A 100 %, un
/// mot qui ne tient pas se reduit de meme (jusqu'a 0,85). Un mot qui ne tient
/// toujours pas a 0,85 serait coupe : c'est alors au conteneur de s'elargir.
/// Partout ailleurs, l'echelle de l'appareil est gardee telle quelle.
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
    this.voisins = const <String>[],
    this.plancher = 1,
  });

  /// Les libelles voisins de MEME largeur (segments d'un `ControleSegmente`) :
  /// l'echelle est bornee par le mot le plus long de tous, pour que les
  /// voisins gardent la meme taille (COUPE-MOTS-1 point 6).
  final List<String> voisins;

  /// Le texte.
  final String texte;

  /// Son style.
  final TextStyle? style;

  /// Son alignement.
  final TextAlign? textAlign;

  /// Le nombre de lignes vise (titre de la salle : deux a 200 %). L'echelle
  /// se reduit encore, jamais sous [plancher], pour que le texte y tienne ;
  /// s'il n'y tient toujours pas, il prend une ligne de plus plutot qu'une
  /// ellipse (COUPE-MOTS-1). Nul : autant de lignes qu'il faut.
  final int? maxLignes;

  /// L'echelle sous laquelle la reduction pour [maxLignes] ne descend pas :
  /// 1 par defaut (taille du theme). Le titre de la salle la place plus
  /// haut, pour rester plus grand que son sous-titre. Elle ne concerne pas
  /// le mot le plus long, borne par [echelleMinimaleLisible].
  final double plancher;

  @override
  Widget build(BuildContext context) {
    final TextStyle complet = DefaultTextStyle.of(context).style.merge(style);
    final TextDirection sens = Directionality.of(context);
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    // L'echelle retenue pour une largeur : la meme regle pour la mise en
    // page et pour les hauteurs intrinseques (un parent `IntrinsicHeight`
    // mesure le texte tel qu'il sera rendu, pas a l'echelle de l'appareil).
    TextScaler pour(double largeur) => _echelleBornee(
      echelle: echelle,
      complet: complet,
      sens: sens,
      texte: texte,
      largeur: largeur,
      maxLignes: maxLignes,
      voisins: voisins,
      plancher: plancher,
    );
    return _Intrinseques(
      peintre: TextPainter(
        text: TextSpan(text: texte, style: complet),
        textDirection: sens,
        textScaler: echelle,
      ),
      echellePour: pour,
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints c) {
          final TextScaler retenue = pour(c.maxWidth);
          // SUPERPOS-1 : un nom compose (« Al-Badr ») passait a la ligne
          // apres son trait d'union (« Classe Al- / Badr ») : il est lu
          // comme un mot, il reste entier. Le texte n'est retouche (un
          // gluon invisible apres le trait) que si la ligne s'y coupait
          // vraiment ; le lecteur d'ecran lit le texte d'origine.
          final String rendu = sansCoupureAuTrait(
            texte,
            complet,
            sens,
            retenue,
            c.maxWidth,
          );
          return Text(
            rendu,
            style: style,
            textAlign: textAlign,
            textScaler: retenue,
            semanticsLabel: identical(rendu, texte) ? null : texte,
          );
        },
      ),
    );
  }
}

/// Un trait d'union entre deux lettres : « Al-Badr », « Saint-Denis ».
final RegExp _traitEntreLettres = RegExp(
  r'(?<=\p{L})-(?=\p{L})',
  unicode: true,
);

/// Le gluon invisible (WORD JOINER, U+2060) : aucune coupure de ligne a cote.
const String _gluon = '\u2060';

/// [texte] tel qu'il se rend sans couper un nom compose : si, a [echelle] et
/// dans [largeur], une ligne se termine juste apres un trait d'union entre
/// deux lettres, un gluon invisible est pose apres chaque tel trait (le nom
/// passe alors entier a la ligne). Sinon, [texte] lui-meme (le meme objet).
String sansCoupureAuTrait(
  String texte,
  TextStyle complet,
  TextDirection sens,
  TextScaler echelle,
  double largeur,
) {
  if (!largeur.isFinite || !texte.contains('-')) return texte;
  final List<int> traits = <int>[
    for (final RegExpMatch m in _traitEntreLettres.allMatches(texte)) m.start,
  ];
  if (traits.isEmpty) return texte;
  final TextPainter p = TextPainter(
    text: TextSpan(text: texte, style: complet),
    textDirection: sens,
    textScaler: echelle,
  )..layout(maxWidth: largeur);
  final bool coupe = traits.any(
    (int i) => p.getLineBoundary(TextPosition(offset: i)).end == i + 1,
  );
  p.dispose();
  return coupe ? texte.replaceAll(_traitEntreLettres, '-$_gluon') : texte;
}

/// La largeur du mot le plus long de [texte], a l'echelle [echelle].
double largeurMotLePlusLong(
  BuildContext context,
  String texte,
  TextStyle? style,
  TextScaler echelle,
) => _motLePlusLong(
  DefaultTextStyle.of(context).style.merge(style),
  Directionality.of(context),
  texte,
  echelle,
);

double _motLePlusLong(
  TextStyle complet,
  TextDirection sens,
  String texte,
  TextScaler echelle,
) {
  double motLong = 0;
  for (final String mot in texte.split(_espacesSecables)) {
    if (mot.isEmpty) continue;
    final TextPainter p = TextPainter(
      text: TextSpan(text: mot, style: complet),
      textDirection: sens,
      textScaler: echelle,
      maxLines: 1,
    )..layout();
    if (p.width > motLong) motLong = p.width;
    p.dispose();
  }
  return motLong;
}

/// Les espaces ou une ligne peut se couper : tout blanc SAUF les espaces
/// insecables (U+00A0, U+2007, U+202F). Une duree « 3\u00A0h\u00A028 »
/// (DUREE-INSECABLE-1) est un seul mot pour la mesure, comme pour le moteur
/// de texte qui ne la coupe pas.
final RegExp _espacesSecables = RegExp(r'[^\S\u00A0\u2007\u202F]+');

/// L'echelle sous laquelle aucun libelle ne descend pour garder un mot
/// entier (85 % de la taille du theme). Au-dela, le conteneur s'elargit
/// (rail, ligne cle-valeur) ou defile (barre basse) : la reduction est
/// bornee, comme un `FittedBox` borne, jamais une troncature invisible.
const double echelleMinimaleLisible = 0.85;

/// Une petite marge : l'arrondi des glyphes ne doit pas renvoyer la derniere
/// lettre a la ligne.
const double _margeArrondi = 2;

/// L'echelle de [context], bornee pour que le mot le plus long de [texte]
/// tienne dans [largeur] (jamais sous [echelleMinimaleLisible]) et, si [maxLignes] est donne, pour
/// que le texte entier tienne si possible dans ce nombre de lignes. Les mots
/// de [voisins] comptent comme les siens (voir [TexteSansCoupure.voisins]).
TextScaler echelleSansCoupure(
  BuildContext context,
  String texte,
  TextStyle? style,
  double largeur, {
  int? maxLignes,
  List<String> voisins = const <String>[],
  double plancher = 1,
}) => _echelleBornee(
  echelle: MediaQuery.textScalerOf(context),
  complet: DefaultTextStyle.of(context).style.merge(style),
  sens: Directionality.of(context),
  texte: texte,
  largeur: largeur,
  maxLignes: maxLignes,
  voisins: voisins,
  plancher: plancher,
);

TextScaler _echelleBornee({
  required TextScaler echelle,
  required TextStyle complet,
  required TextDirection sens,
  required String texte,
  required double largeur,
  required int? maxLignes,
  required List<String> voisins,
  required double plancher,
}) {
  final double facteur = echelle.scale(1);
  if (!largeur.isFinite) return echelle;
  // 1. Le mot le plus long doit tenir : l'echelle se reduit juste assez,
  // jamais sous [echelleMinimaleLisible] (sauf si l'appareil est deja en
  // dessous). Cela vaut aussi a 100 % : un mot plus long que sa place a la
  // taille du theme se reduit au lieu d'etre coupe. Sous ce plancher, c'est
  // au conteneur de s'elargir (barre de navigation, rail, ligne cle-valeur).
  final double minimumMot = echelleMinimaleLisible < facteur
      ? echelleMinimaleLisible
      : facteur;
  final double motLong = _motLePlusLong(
    complet,
    sens,
    <String>[texte, ...voisins].join(' '),
    echelle,
  );
  double borne = motLong <= largeur
      ? facteur
      : facteur * (largeur - _margeArrondi) / motLong;
  if (borne < minimumMot) borne = minimumMot;
  if (maxLignes != null) {
    // 2. Le nombre de lignes vise : des pas de 5 %, jamais sous [plancher]
    // (ni sous l'echelle deja retenue pour le mot). Le texte garde la plus
    // grande echelle qui le fait tenir ; sinon il prend une ligne de plus.
    final double minimum = plancher < borne ? plancher : borne;
    for (int pas = 0; pas < 60 && borne > minimum; pas++) {
      final TextPainter p = TextPainter(
        text: TextSpan(text: texte, style: complet),
        textDirection: sens,
        textScaler: TextScaler.linear(borne),
        maxLines: maxLignes,
      )..layout(maxWidth: largeur);
      final bool depasse = p.didExceedMaxLines;
      p.dispose();
      if (!depasse) break;
      borne = borne * 0.95 < minimum ? minimum : borne * 0.95;
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
/// mot long au lieu de le couper (« Disponibilites »). Si meme au plancher
/// ils ne tiennent pas, les largeurs rendues depassent [largeur] (voir la
/// fin de la fonction).
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
    // Au plancher, si les mots ne tiennent toujours pas ensemble, chacun
    // garde sa largeur : leur somme depasse [largeur] et l'appelant fait
    // defiler la rangee (le conteneur s'elargit, aucun mot n'est coupe).
    largeurs: reste < 0
        ? besoins
        : <double>[for (final double b in besoins) b + reste / n],
  );
}

/// Repond aux questions de dimensions intrinseques avec le texte mesure,
/// la ou un `LayoutBuilder` ne sait pas le faire.
class _Intrinseques extends SingleChildRenderObjectWidget {
  const _Intrinseques({
    required this.peintre,
    required this.echellePour,
    super.child,
  });

  final TextPainter peintre;

  /// L'echelle retenue pour une largeur donnee.
  final TextScaler Function(double largeur) echellePour;

  @override
  _RenduIntrinseques createRenderObject(BuildContext context) =>
      _RenduIntrinseques(peintre, echellePour);

  @override
  void updateRenderObject(BuildContext context, _RenduIntrinseques rendu) {
    // Le rendu possede son peintre : l'ancien est libere.
    if (!identical(rendu.peintre, peintre)) rendu.peintre.dispose();
    rendu
      ..peintre = peintre
      ..echellePour = echellePour
      ..markNeedsLayout();
  }
}

class _RenduIntrinseques extends RenderProxyBox {
  _RenduIntrinseques(this.peintre, this.echellePour);

  TextPainter peintre;
  TextScaler Function(double largeur) echellePour;

  @override
  void dispose() {
    peintre.dispose();
    super.dispose();
  }

  /// Pose sur le peintre l'echelle que le texte aura a [largeur].
  void _echelle(double largeur) {
    peintre.textScaler = echellePour(largeur);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _echelle(double.infinity);
    peintre.layout();
    return peintre.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _echelle(double.infinity);
    peintre.layout();
    return peintre.maxIntrinsicWidth;
  }

  double _hauteur(double width) {
    _echelle(width);
    peintre.layout(maxWidth: width.isFinite ? width : double.infinity);
    return peintre.height;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _hauteur(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _hauteur(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _echelle(constraints.maxWidth);
    peintre.layout(maxWidth: constraints.maxWidth);
    return constraints.constrain(peintre.size);
  }
}
