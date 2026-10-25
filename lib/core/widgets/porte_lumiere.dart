import 'package:flutter/widgets.dart';

import '../marque/logo_traces.g.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'brand_logo.dart';

/// La porte et la lumiere : l'illustration des etats « il faut attendre » ou
/// « rien ici » (page introuvable).
///
/// Le symbole est celui du logo, pose par [BrandLogo] (aucun dessin refait,
/// couleur et zone de protection du composant). Seule la lumiere est peinte
/// ici : un faisceau qui sort du seuil et se pose sur le sol, des pas en
/// pointilles qui s'arretent avant la porte. Teintes lues dans la palette
/// (accent de marque en transparence), jamais une couleur litterale. Meme
/// scene que la page introuvable du site public (`site-public/scene_porte.py`).
///
/// Deux poses :
/// - [PorteLumiere.new], sur la page de l'application (page introuvable) :
///   symbole violet de marque, lumiere seule peinte ;
/// - [PorteLumiere.surMarque], sur la surface de marque (connexion,
///   25/10/2026) : **la scene du site, telle quelle** (etat « attente », celui
///   que la page de desinscription montre a l'ouverture), dans le meme
///   `viewBox` de 640 x 520 et aux memes coordonnees : ombre au sol, faisceau,
///   vide de la porte en degrade, symbole blanc ([FondLogo.violet]), pas en
///   pointilles, lanterne et son halo. Teintes : [AppCouleursPorte].
///
/// Decorative : exclue de l'arbre semantique. La page introuvable est sans
/// mouvement ; la scene du site joue une fois a l'arrivee puis reste
/// immobile, jamais en boucle (decision du directeur du 25/10/2026, le site
/// faisait respirer la lumiere sans fin).
class PorteLumiere extends StatelessWidget {
  /// Cree l'illustration de la page de l'application.
  const PorteLumiere({super.key}) : surMarque = false, largeurMax = largeur;

  /// Cree la scene du site, posee sur [AppPalette.surfaceMarque], a la
  /// largeur disponible et au plus [largeurMax].
  const PorteLumiere.surMarque({super.key, this.largeurMax = largeurScene})
    : surMarque = true;

  /// Vrai pour la scene du site, sur la surface de marque.
  final bool surMarque;

  /// La largeur maximale de la scene du site.
  final double largeurMax;

  /// La largeur du `viewBox` de la scene du site.
  static const double largeurViewBox = 640;

  /// La hauteur du `viewBox` de la scene du site.
  static const double hauteurViewBox = 520;

  /// La largeur par defaut de la scene du site (340 sur le telephone du site,
  /// ramene a l'echelle d'espacement).
  static const double largeurScene = AppSpacing.respiration * 5;

  /// Hauteur du dessin du symbole.
  static const double hauteurSymbole = AppSpacing.titreEcran * 2;

  /// Zone de protection du logo, au-dessus et au-dessous du dessin.
  static const double zone = hauteurSymbole * BrandLogo.zoneProtection;

  /// Le sol : la ou le seuil de la porte touche le dessin.
  static const double sol = hauteurSymbole + zone;

  /// Hauteur du faisceau sous le seuil.
  static const double hauteurFaisceau = AppSpacing.titreEcran;

  /// Largeur de la scene.
  static const double largeur = AppSpacing.respiration * 3;

  /// Hauteur de la scene.
  static const double hauteur = sol + hauteurFaisceau;

  @override
  Widget build(BuildContext context) {
    if (surMarque) {
      return ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) {
            final double l = contraintes.maxWidth < largeurMax
                ? contraintes.maxWidth
                : largeurMax;
            return _SceneSite(largeur: l);
          },
        ),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: largeur,
        height: hauteur,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _PeintreLumiere(
                  lumiere: palette.surfacePrimary.background,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.topCenter,
              child: BrandLogo(
                variante: VarianteLogo.symbole,
                hauteur: hauteurSymbole,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeintreLumiere extends CustomPainter {
  const _PeintreLumiere({required this.lumiere});

  final Color lumiere;

  @override
  void paint(Canvas canvas, Size size) {
    final double centre = size.width / 2;
    const double sol = PorteLumiere.sol;
    // Le seuil fait un peu plus de 40 % de la largeur du symbole.
    const double seuil = PorteLumiere.hauteurSymbole * 0.4;
    const double bas = seuil * 3;
    final double fond = size.height;
    final Rect zoneFaisceau = Rect.fromLTRB(0, sol, size.width, fond);
    final Path faisceau = Path()
      ..moveTo(centre - seuil / 2, sol)
      ..lineTo(centre + seuil / 2, sol)
      ..lineTo(centre + bas / 2, fond)
      ..lineTo(centre - bas / 2, fond)
      ..close();
    canvas.drawPath(
      faisceau,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lumiere.withValues(alpha: 0.4),
            lumiere.withValues(alpha: 0),
          ],
        ).createShader(zoneFaisceau),
    );
    // Les pas s'arretent avant le seuil : on attend.
    final Paint pas = Paint()..color = lumiere.withValues(alpha: 0.55);
    final double hauteurFaisceau = fond - sol;
    for (int i = 0; i < 3; i++) {
      final double echelle = 1 - i * 0.25;
      final double y = sol + hauteurFaisceau * (0.7 - i * 0.25);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centre, y),
          width: seuil * 0.3 * echelle,
          height: seuil * 0.09 * echelle,
        ),
        pas,
      );
    }
  }

  @override
  bool shouldRepaint(_PeintreLumiere ancien) => ancien.lumiere != lumiere;
}

/// Le vide de la porte (l'arche interieure, vantail compris), dans le repere
/// du symbole : `VIDE_PORTE` de `site-public/scene_porte.py`, mot pour mot.
const String _videPorte =
    'M358 224.9C439.7 224.9 505.9 291.1 505.9 372.9V677.3L210.1 681.3V372.9'
    'C210.1 291.1 276.3 224.9 358 224.9Z';

/// La pose du symbole dans la scene du site : `translate(127 58) scale(.54)`.
const double _symboleX = 127;
const double _symboleY = 58;
const double _symboleEchelle = 0.54;

/// Les temps de l'entree, en fraction de [AppMouvement.entreeIllustration] :
/// le symbole se dessine, la porte s'ouvre, la lumiere sort et s'etire au sol
/// comme une route, les pas puis la lanterne apparaissent.
abstract final class _Temps {
  static const Interval symbole = Interval(0, 0.4, curve: AppMouvement.entree);
  static const Interval ombre = Interval(0.1, 0.5, curve: AppMouvement.entree);
  static const Interval porte = Interval(0.3, 0.6, curve: AppMouvement.entree);
  static const Interval lumiere = Interval(
    0.45,
    0.8,
    curve: AppMouvement.entree,
  );
  static const Interval lanterne = Interval(
    0.75,
    1,
    curve: AppMouvement.entree,
  );

  /// Le pas [i] (0 : le plus bas, le plus loin de la porte).
  static Interval pas(int i) => Interval(
    0.65 + i * 0.07,
    0.65 + i * 0.07 + 0.14,
    curve: AppMouvement.entree,
  );
}

/// La scene du site a une largeur donnee : la peinture dessous, le symbole
/// par [BrandLogo] dessus, a sa place exacte (sa zone de protection deborde
/// autour de son dessin, sans rien peindre).
///
/// **Elle joue une fois a l'arrivee** ([AppMouvement.entreeIllustration]),
/// puis reste immobile : jamais de boucle. En mouvement reduit, les memes
/// temps en fondus seuls (le symbole ne se dessine pas, la lumiere ne s'etire
/// pas) ; l'image finale est la meme.
class _SceneSite extends StatefulWidget {
  const _SceneSite({required this.largeur});

  final double largeur;

  @override
  State<_SceneSite> createState() => _SceneSiteState();
}

class _SceneSiteState extends State<_SceneSite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entree = AnimationController(
    vsync: this,
    duration: AppMouvement.entreeIllustration,
  )..forward();

  @override
  void dispose() {
    _entree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduit = AppMouvement.mouvementReduit(context);
    final double e = widget.largeur / PorteLumiere.largeurViewBox;
    final double hauteurSymbole = logoSymbole.hauteur * _symboleEchelle * e;
    final double zone = hauteurSymbole * BrandLogo.zoneProtection;
    final Widget symbole = BrandLogo(
      variante: VarianteLogo.symbole,
      hauteur: hauteurSymbole,
      fond: FondLogo.violet,
    );
    return SizedBox(
      width: widget.largeur,
      height: PorteLumiere.hauteurViewBox * e,
      // Une image ne se retourne pas en arabe : le symbole et sa lumiere
      // gardent leurs coordonnees, comme le logo (README du logo).
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _PeintreSceneSite(entree: _entree, reduit: reduit),
              ),
            ),
            // Sous la direction forcee de gauche a droite ci-dessus, le debut
            // est la gauche du viewBox, en arabe comme en francais.
            PositionedDirectional(
              start: _symboleX * e - zone,
              top: _symboleY * e - zone,
              child: AnimatedBuilder(
                animation: _entree,
                child: symbole,
                builder: (BuildContext context, Widget? enfant) {
                  final double p = _Temps.symbole.transform(_entree.value);
                  if (reduit) {
                    return Opacity(opacity: p, child: enfant);
                  }
                  // Le symbole se dessine du seuil vers le haut de l'arche.
                  return ClipRect(clipper: _Revele(p), child: enfant);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La part visible du symbole pendant qu'il se dessine : du bas vers le haut.
class _Revele extends CustomClipper<Rect> {
  const _Revele(this.part);

  final double part;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * (1 - part), size.width, size.height);

  @override
  bool shouldReclip(_Revele ancien) => ancien.part != part;
}

/// La peinture de la scene du site, dans son `viewBox` de 640 x 520 :
/// `porte_lumiere("attente")` de `site-public/scene_porte.py`, forme par
/// forme, aux memes coordonnees et aux memes opacites une fois l'entree
/// jouee.
class _PeintreSceneSite extends CustomPainter {
  _PeintreSceneSite({required this.entree, required this.reduit})
    : super(repaint: entree);

  final Animation<double> entree;
  final bool reduit;

  static Color _c(AppInkColor encre) => encre.asBorderSide().color;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = entree.value;
    final Color blanc = _c(AppCouleursPorte.blanc);
    final Color lavande = _c(AppCouleursPorte.lavande);
    final Color ombre = _c(AppCouleursPorte.ombre);
    canvas
      ..save()
      ..scale(size.width / PorteLumiere.largeurViewBox);

    // L'ombre au sol : ellipse (320, 446), 300 x 30, degrade radial.
    final double pOmbre = _Temps.ombre.transform(t);
    canvas
      ..save()
      ..translate(320, 446)
      ..scale(1, 30 / 300);
    const Rect disque = Rect.fromLTRB(-300, -300, 300, 300);
    canvas
      ..drawOval(
        disque,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              ombre.withValues(alpha: 0.45 * pOmbre),
              ombre.withValues(alpha: 0),
            ],
          ).createShader(disque),
      )
      ..restore();

    // Le faisceau : sort du seuil et s'ouvre sur le sol, vers qui attend. A
    // l'entree, il s'etire depuis le seuil (y = 430) comme une route.
    final double pLumiere = _Temps.lumiere.transform(t);
    if (pLumiere > 0) {
      final Path faisceau = Path()
        ..moveTo(240, 430)
        ..lineTo(400, 430)
        ..lineTo(480, 518)
        ..lineTo(160, 518)
        ..close();
      final Rect boite = faisceau.getBounds();
      canvas.save();
      if (!reduit) {
        canvas
          ..translate(0, 430)
          ..scale(1, pLumiere)
          ..translate(0, -430);
      }
      canvas
        ..drawPath(
          faisceau,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                blanc.withValues(alpha: 0.8 * (reduit ? pLumiere : 1)),
                lavande.withValues(alpha: 0),
              ],
            ).createShader(boite),
        )
        ..restore();
    }

    // Le vide de la porte, sous le symbole : la piece derriere elle. Il
    // s'eclaire quand la porte s'ouvre.
    final double pPorte = _Temps.porte.transform(t);
    final Path vide = cheminDepuisTrace(_videPorte);
    canvas
      ..save()
      ..translate(_symboleX, _symboleY)
      ..scale(_symboleEchelle)
      ..drawPath(
        vide,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              _c(AppCouleursPorte.profond).withValues(alpha: pPorte),
              _c(AppCouleursPorte.accent).withValues(alpha: pPorte),
              lavande.withValues(alpha: pPorte),
            ],
            stops: const <double>[0, 0.55, 1],
          ).createShader(vide.getBounds()),
      )
      ..restore();

    // Les pas en pointilles, de bas en haut ; en attente, ils s'arretent
    // avant le seuil.
    final List<(double, double, double)> pas = <(double, double, double)>[
      (506, 14, 4.2),
      (486, 11.5, 3.5),
      (470, 9.5, 2.9),
      (457, 7.5, 2.3),
    ];
    for (int i = 0; i < pas.length; i++) {
      final (double y, double rx, double ry) = pas[i];
      canvas.drawOval(
        Rect.fromCenter(center: Offset(320, y), width: rx * 2, height: ry * 2),
        Paint()
          ..color = blanc.withValues(alpha: 0.8 * _Temps.pas(i).transform(t)),
      );
    }

    // La lanterne attend a cote : halo, corps, flamme, anse.
    final double pLanterne = _Temps.lanterne.transform(t);
    const Rect halo = Rect.fromLTRB(84 - 62, 420 - 62, 84 + 62, 420 + 62);
    canvas
      ..drawOval(
        halo,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              lavande.withValues(alpha: 0.55 * pLanterne),
              lavande.withValues(alpha: 0),
            ],
          ).createShader(halo),
      )
      ..drawPath(
        _arche(66, 452, 414, 18),
        Paint()..color = lavande.withValues(alpha: pLanterne),
      )
      ..drawPath(
        _arche(76, 452, 416, 8),
        Paint()..color = blanc.withValues(alpha: pLanterne),
      )
      ..drawLine(
        const Offset(84, 388),
        const Offset(84, 376),
        Paint()
          ..color = lavande.withValues(alpha: pLanterne)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
  }

  /// `M{x} {bas}V{haut}a{r} {r} 0 0 1 {2r} 0V{bas}Z` : un rectangle coiffe
  /// d'un demi-cercle (le trace SVG des arcs n'est pas lu par
  /// `cheminDepuisTrace`).
  static Path _arche(double x, double bas, double haut, double r) => Path()
    ..moveTo(x, bas)
    ..lineTo(x, haut)
    ..arcToPoint(Offset(x + 2 * r, haut), radius: Radius.circular(r))
    ..lineTo(x + 2 * r, bas)
    ..close();

  @override
  bool shouldRepaint(_PeintreSceneSite ancien) =>
      ancien.entree != entree || ancien.reduit != reduit;
}
