import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';
import '../marque/dessin_logo.dart';
import '../marque/logo_traces.g.dart';
import '../marque/trace_svg.dart';
import '../theme/app_palette.dart';
import 'pressable.dart';

/// La variante du logo Rewayah Academy (`assets/brand/logo/README.md`).
enum VarianteLogo {
  /// Logo principal : en-tete de la barre laterale large.
  horizontal,

  /// Connexion, zones carrees ou etroites, dans un espace degage.
  vertical,

  /// Petit format : rail replie, barre etroite.
  symbole,
}

/// Le fond sur lequel le logo se pose : il decide de sa couleur, jamais
/// l'ecran (README, « Quelle couleur selon le fond »).
enum FondLogo {
  /// Le fond de l'application, clair ou sombre : logo violet de marque.
  page,

  /// Une bande violette de marque : logo blanc.
  violet,

  /// Impression noir et blanc, tampon : logo encre.
  impression,
}

/// Le logo Rewayah Academy, **seul point d'entree** du logo dans l'application.
///
/// Le dessin est celui des SVG du directeur, recopies octet pour octet dans
/// `logo_traces.g.dart` par `tool/generer_logo.dart` et peints ici par un
/// rendu sur mesure ([RenduLogo]) : aucun asset charge a l'execution, aucune
/// dependance SVG.
///
/// Regles du README appliquees ici, une fois pour toutes :
/// - **proportions verrouillees** : la largeur se deduit de la hauteur par le
///   `viewBox` ; si la place manque en largeur, tout le logo reduit ;
/// - **tailles minimales** (horizontal 28, vertical 56, symbole 24) : en
///   dessous, le vertical passe a l'horizontal puis au symbole, l'horizontal
///   passe au symbole, le symbole ne descend jamais sous 24 ;
/// - **zone de protection** : 25 % de la hauteur du logo libres de chaque
///   cote, comprise dans la taille du composant ;
/// - **couleur** lue dans les jetons d'apres [fond], jamais dans l'ecran ;
/// - **jamais retourne** en arabe : le dessin ne suit pas `Directionality`
///   (c'est l'appelant qui le pose au debut de ligne, `start`).
///
/// Semantique : avec [onAccueil], c'est le logo d'en-tete, seul cliquable, un
/// lien lu « Rewayah Academy, accueil » ; avec [libelle], une image nommee
/// (le nom de marque n'est pas ecrit ailleurs) ; sans l'un ni l'autre, il est
/// decoratif et retire de l'arbre semantique.
class BrandLogo extends StatelessWidget {
  /// Cree le logo.
  const BrandLogo({
    required this.variante,
    required this.hauteur,
    this.fond = FondLogo.page,
    this.onAccueil,
    this.libelle,
    super.key,
  });

  /// La variante souhaitee ; celle rendue peut etre plus petite
  /// ([varianteRendue]).
  final VarianteLogo variante;

  /// La hauteur souhaitee du dessin, hors zone de protection.
  final double hauteur;

  /// Le fond qui porte le logo, d'ou sa couleur.
  final FondLogo fond;

  /// Ramene a l'accueil du role : fait du logo le lien d'en-tete.
  final VoidCallback? onAccueil;

  /// Le nom lu par le lecteur d'ecran quand le logo n'est pas un lien et que
  /// le nom de marque n'est pas ecrit a cote. Nul : decoratif.
  final String? libelle;

  /// Hauteur minimale du logo horizontal a l'ecran.
  static const double minimumHorizontal = 28;

  /// Hauteur minimale du logo vertical a l'ecran.
  static const double minimumVertical = 56;

  /// Hauteur minimale du symbole a l'ecran.
  static const double minimumSymbole = 24;

  /// La zone de protection, en part de la hauteur du dessin, de chaque cote.
  static const double zoneProtection = 0.25;

  /// Le dessin de chaque variante.
  static DessinLogo dessin(VarianteLogo variante) => switch (variante) {
    VarianteLogo.horizontal => logoHorizontal,
    VarianteLogo.vertical => logoVertical,
    VarianteLogo.symbole => logoSymbole,
  };

  /// La hauteur minimale de chaque variante.
  static double minimum(VarianteLogo variante) => switch (variante) {
    VarianteLogo.horizontal => minimumHorizontal,
    VarianteLogo.vertical => minimumVertical,
    VarianteLogo.symbole => minimumSymbole,
  };

  /// La variante rendue et la hauteur de son dessin, pour une [hauteur]
  /// souhaitee et une [largeurMax] disponible (zone de protection comprise).
  static (VarianteLogo, double) varianteRendue(
    VarianteLogo demandee,
    double hauteur, {
    double largeurMax = double.infinity,
  }) {
    double tenue(VarianteLogo v) {
      // Largeur totale = h x (proportion + 2 x zone de protection).
      final double parLargeur =
          largeurMax / (dessin(v).proportion + 2 * zoneProtection);
      return hauteur < parLargeur ? hauteur : parLargeur;
    }

    final List<VarianteLogo> repli = switch (demandee) {
      VarianteLogo.vertical => <VarianteLogo>[
        VarianteLogo.vertical,
        VarianteLogo.horizontal,
      ],
      VarianteLogo.horizontal => <VarianteLogo>[VarianteLogo.horizontal],
      VarianteLogo.symbole => <VarianteLogo>[],
    };
    for (final VarianteLogo v in repli) {
      final double h = tenue(v);
      if (h >= minimum(v)) return (v, h);
    }
    final double h = tenue(VarianteLogo.symbole);
    return (VarianteLogo.symbole, h < minimumSymbole ? minimumSymbole : h);
  }

  /// La couleur du logo sur [fond].
  ///
  /// Le violet de marque est le fond de `surfacePrimary` de la palette claire
  /// (#8652E6, valeur exacte du README) : **il ne suit pas le glissement
  /// tonal du theme sombre** (#BA98FB), parce que le README impose une seule
  /// teinte de violet, aussi sur le fond sombre (3,58:1 sur `surfaceCanvas`
  /// sombre, au-dessus du 3:1 d'un element graphique). Le blanc est l'encre
  /// de cette meme surface ; l'encre d'impression est l'encre de texte de la
  /// carte claire (#110E20, le plus proche jeton de l'encre #17141F livree).
  static Color couleur(FondLogo fond) {
    final AppPalette marque = AppPalette.claire();
    return switch (fond) {
      FondLogo.page => marque.surfacePrimary.background,
      FondLogo.violet => marque.surfacePrimary.onBackground,
      FondLogo.impression => marque.surfaceRaised.onBackground,
    };
  }

  @override
  Widget build(BuildContext context) {
    // La variante rendue se decide a la mise en page ([RenduLogo]), d'apres la
    // largeur offerte : pas de `LayoutBuilder`, qui ne sait pas repondre aux
    // dimensions intrinseques (la colonne de navigation en demande).
    final Widget logo = ExcludeSemantics(
      child: LogoPeint(
        variante: variante,
        hauteur: hauteur,
        couleur: couleur(fond),
      ),
    );
    final VoidCallback? accueil = onAccueil;
    if (accueil != null) {
      return Pressable(
        onPress: accueil,
        lien: true,
        libelleSemantique: t.nav.logoAccueil,
        child: logo,
      );
    }
    final String? nom = libelle;
    if (nom != null) {
      return Semantics(image: true, label: nom, child: logo);
    }
    return logo;
  }
}

/// Le dessin du logo et sa zone de protection, sans semantique ni geste.
///
/// Public pour les tests seulement ; un ecran pose toujours [BrandLogo].
class LogoPeint extends LeafRenderObjectWidget {
  /// Cree le dessin.
  const LogoPeint({
    required this.variante,
    required this.hauteur,
    required this.couleur,
    super.key,
  });

  /// La variante souhaitee.
  final VarianteLogo variante;

  /// La hauteur souhaitee du dessin.
  final double hauteur;

  /// L'unique couleur de remplissage.
  final Color couleur;

  @override
  RenduLogo createRenderObject(BuildContext context) =>
      RenduLogo(variante, hauteur, couleur);

  @override
  void updateRenderObject(BuildContext context, RenduLogo renderObject) {
    renderObject
      ..variante = variante
      ..hauteur = hauteur
      ..couleur = couleur;
  }
}

/// Le rendu du logo : choisit la variante d'apres la largeur offerte
/// ([BrandLogo.varianteRendue]), prend la taille du dessin plus sa zone de
/// protection, et peint les traces a l'echelle homogene.
class RenduLogo extends RenderBox {
  /// Cree le rendu.
  RenduLogo(this._variante, this._hauteur, this._couleur);

  VarianteLogo _variante;
  double _hauteur;
  Color _couleur;

  /// La variante souhaitee.
  set variante(VarianteLogo valeur) {
    if (valeur == _variante) return;
    _variante = valeur;
    markNeedsLayout();
  }

  /// La hauteur souhaitee du dessin.
  set hauteur(double valeur) {
    if (valeur == _hauteur) return;
    _hauteur = valeur;
    markNeedsLayout();
  }

  /// La couleur de remplissage.
  Color get couleur => _couleur;
  set couleur(Color valeur) {
    if (valeur == _couleur) return;
    _couleur = valeur;
    markNeedsPaint();
  }

  /// La variante reellement rendue a la derniere mise en page.
  VarianteLogo get varianteRendue => _rendu.$1;

  /// La hauteur du dessin, hors zone de protection, a la derniere mise en
  /// page.
  double get hauteurDessin => _rendu.$2;

  (VarianteLogo, double) _rendu = (VarianteLogo.symbole, 0);

  (VarianteLogo, double) _pour(double largeurMax) =>
      BrandLogo.varianteRendue(_variante, _hauteur, largeurMax: largeurMax);

  static Size _taille((VarianteLogo, double) rendu) {
    final double h = rendu.$2;
    final double marge = 2 * h * BrandLogo.zoneProtection;
    return Size(h * BrandLogo.dessin(rendu.$1).proportion + marge, h + marge);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _taille(_pour(double.infinity)).width;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _taille(_pour(double.infinity)).width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _taille(_pour(width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _taille(_pour(width)).height;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(_taille(_pour(constraints.maxWidth)));

  @override
  void performLayout() {
    _rendu = _pour(constraints.maxWidth);
    size = constraints.constrain(_taille(_rendu));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final DessinLogo d = BrandLogo.dessin(_rendu.$1);
    final double h = _rendu.$2;
    final double marge = h * BrandLogo.zoneProtection;
    // Echelle homogene : la hauteur du dessin sur celle du viewBox ; la
    // largeur suit par la proportion. Jamais etire, jamais retourne.
    final double echelle = h / d.hauteur;
    final Paint peinture = Paint()
      ..color = _couleur
      ..isAntiAlias = true;
    final Canvas canvas = context.canvas
      ..save()
      ..translate(offset.dx + marge, offset.dy + marge)
      ..scale(echelle);
    for (final String trace in d.traces) {
      canvas.drawPath(
        _chemins.putIfAbsent(
          trace,
          () => cheminDepuisTrace(trace, pairImpair: d.pairImpair),
        ),
        peinture,
      );
    }
    canvas.restore();
  }
}

/// Le chemin d'un trace, construit une seule fois par chaine.
final Map<String, Path> _chemins = <String, Path>{};

/// Construit le [Path] des donnees `d` d'un trace SVG.
Path cheminDepuisTrace(String donnees, {bool pairImpair = false}) {
  final Path chemin = Path()
    ..fillType = pairImpair ? PathFillType.evenOdd : PathFillType.nonZero;
  for (final CommandeTrace c in lireTraceSvg(donnees)) {
    final List<double> p = c.coordonnees;
    switch (c.nature) {
      case NatureCommande.deplacer:
        chemin.moveTo(p[0], p[1]);
      case NatureCommande.ligne:
        chemin.lineTo(p[0], p[1]);
      case NatureCommande.cubique:
        chemin.cubicTo(p[0], p[1], p[2], p[3], p[4], p[5]);
      case NatureCommande.quadratique:
        chemin.quadraticBezierTo(p[0], p[1], p[2], p[3]);
      case NatureCommande.fermer:
        chemin.close();
    }
  }
  return chemin;
}
