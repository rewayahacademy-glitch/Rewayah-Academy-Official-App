// TRANSITIONS-SALLE (directeur, 11/11/2026) : entrer dans la salle, le
// moment de l'arche. « L'ecran s'assombrit et s'ouvre comme une porte » :
// l'arche, la porte « Bab » que le logo porte en lui.
//
// Regle arbitree (avis du pilote, retenu par le garde-cap) :
// - ce moment habille le delai REEL d'entree (verification du materiel,
//   demande du jeton, connexion), a la place de l'attente nue, **jamais en
//   plus** : l'ecran qui le pose le retire des que la salle est prete, meme
//   inacheve (`PassageSalle` passe alors la main par un voile qui s'efface) ;
// - il se joue une fois ([AppMouvement.entreeArche], 700 ms), puis la scene
//   reste immobile : aucune boucle, rien ne bouge pendant qu'on attend ;
// - il ne se joue ni au retour dans une salle reduite, ni a une reconnexion,
//   ni apres un rechargement : c'est l'ecran qui le decide ;
// - « reduire les animations » : l'image finale, en un fondu.
//
// Le logo : le symbole passe par [BrandLogo] (aucun dessin refait, aucune
// deformation, aucune couleur changee), violet sur la lumiere claire de la
// porte (README : fond clair, logo violet). Il n'est pas anime : la porte,
// peinte ici, s'ouvre devant lui. L'arche est une forme simple (un
// rectangle coiffe d'un demi-cercle), pas une copie du logo.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'brand_logo.dart';

/// Le moment de l'arche : l'attente reelle de l'entree dans la salle,
/// habillee d'une porte qui s'ouvre sur la lumiere.
class EntreeArche extends StatefulWidget {
  /// Cree le moment de l'arche. Il remplit la place donnee.
  const EntreeArche({super.key});

  /// La cle de la scene (tests et captures).
  static const Key cle = ValueKey<String>('entree-arche');

  /// La plus grande largeur de l'arche.
  static const double largeurMax = AppSpacing.respiration * 3;

  @override
  State<EntreeArche> createState() => _EtatEntreeArche();
}

class _EtatEntreeArche extends State<EntreeArche>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMouvement.entreeArche,
  );
  bool _parti = false;
  bool _reduit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parti) return;
    _parti = true;
    _reduit = AppMouvement.mouvementReduit(context);
    // Mouvement reduit : l'image finale, en un fondu court.
    if (_reduit) _c.duration = AppMouvement.fonduEntree;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Sombre dans les deux themes : « l'ecran s'assombrit ».
    final AppColorPair couche = palette.coucheSalle;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: LayoutBuilder(
          key: EntreeArche.cle,
          builder: (BuildContext context, BoxConstraints c) {
            final double cote = math.min(
              c.hasBoundedWidth ? c.maxWidth : EntreeArche.largeurMax * 2,
              c.hasBoundedHeight ? c.maxHeight : EntreeArche.largeurMax * 2,
            );
            final double largeur = math.max(
              AppSpacing.respiration,
              math.min(EntreeArche.largeurMax, cote * 0.42),
            );
            final double hauteur = largeur * 1.4;
            final double symbole = math.max(
              BrandLogo.minimumSymbole,
              largeur * 0.4,
            );
            final Widget porte = SizedBox(
              width: largeur,
              height: hauteur,
              child: AnimatedBuilder(
                animation: _c,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: _Lumiere(
                        clair: couche.onBackground,
                        teinte: palette.surfacePrimary.background,
                      ),
                    ),
                    // Le symbole, au seuil de la porte, au tiers bas.
                    Align(
                      alignment: const Alignment(0, 0.2),
                      child: BrandLogo(
                        variante: VarianteLogo.symbole,
                        hauteur: symbole,
                      ),
                    ),
                  ],
                ),
                builder: (BuildContext context, Widget? interieur) => ClipPath(
                  clipper: _Ouverture(ouverture: _ouverture),
                  child: interieur,
                ),
              ),
            );
            return AnimatedBuilder(
              animation: _c,
              child: porte,
              builder: (BuildContext context, Widget? porte) => Opacity(
                opacity: _reduit ? _c.value : 1,
                child: CustomPaint(
                  painter: _Seuil(
                    fond: couche.background,
                    clair: couche.onBackground,
                    teinte: palette.surfacePrimary.background,
                    assombri: _reduit ? 1 : _temps(0, 0.3),
                    ouverture: _ouverture,
                    sol: _reduit ? 1 : _temps(0.4, 1),
                    porte: Size(largeur, hauteur),
                  ),
                  child: Center(child: porte),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// La part du temps [debut]-[fin], sur la courbe du fondu.
  double _temps(double debut, double fin) => AppMouvement.courbeFondu.transform(
    ((_c.value - debut) / (fin - debut)).clamp(0.0, 1.0),
  );

  /// L'ouverture de la porte, de 0 (fermee) a 1 (grande ouverte), sur le
  /// ressort sans rebond : elle part vite et se pose.
  double get _ouverture => _reduit
      ? 1
      : AppMouvement.ressortDeplacement.transform(
          ((_c.value - 0.15) / 0.85).clamp(0.0, 1.0),
        );
}

/// Le contour d'une arche dans [taille] : un rectangle coiffe d'un
/// demi-cercle.
Path _arche(Size taille, {Offset decalage = Offset.zero}) {
  final double r = taille.width / 2;
  final Rect boite = decalage & taille;
  return Path()
    ..moveTo(boite.left, boite.bottom)
    ..lineTo(boite.left, boite.top + r)
    ..arcToPoint(Offset(boite.right, boite.top + r), radius: Radius.circular(r))
    ..lineTo(boite.right, boite.bottom)
    ..close();
}

/// La porte ouverte de [ouverture] : l'arche, vue par la fente centrale qui
/// s'elargit (les deux battants s'ecartent).
class _Ouverture extends CustomClipper<Path> {
  const _Ouverture({required this.ouverture});

  final double ouverture;

  @override
  Path getClip(Size size) {
    final double demi = size.width / 2 * ouverture;
    final Path fente = Path()
      ..addRect(
        Rect.fromLTRB(
          size.width / 2 - demi,
          0,
          size.width / 2 + demi,
          size.height,
        ),
      );
    return Path.combine(PathOperation.intersect, _arche(size), fente);
  }

  @override
  bool shouldReclip(_Ouverture ancien) => ancien.ouverture != ouverture;
}

/// La lumiere dans l'arche : claire en bas (le seuil), un voile de la
/// teinte de la marque en haut.
class _Lumiere extends CustomPainter {
  const _Lumiere({required this.clair, required this.teinte});

  final Color clair;
  final Color teinte;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect boite = Offset.zero & size;
    canvas.drawPath(
      _arche(size),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color.lerp(clair, teinte, 0.18)!, clair],
        ).createShader(boite),
    );
  }

  @override
  bool shouldRepaint(_Lumiere ancien) =>
      ancien.clair != clair || ancien.teinte != teinte;
}

/// Le fond qui s'assombrit, le contour de l'arche fermee et la lumiere qui
/// s'etire au sol quand la porte s'ouvre.
class _Seuil extends CustomPainter {
  const _Seuil({
    required this.fond,
    required this.clair,
    required this.teinte,
    required this.assombri,
    required this.ouverture,
    required this.sol,
    required this.porte,
  });

  final Color fond;
  final Color clair;
  final Color teinte;
  final double assombri;
  final double ouverture;
  final double sol;
  final Size porte;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect tout = Offset.zero & size;
    // L'ecran s'assombrit, dans la forme d'une carte de la salle.
    canvas.drawRRect(
      AppRadius.arrondiLg.toRRect(tout),
      Paint()..color = fond.withValues(alpha: fond.a * assombri),
    );
    final Offset coin = Offset(
      (size.width - porte.width) / 2,
      (size.height - porte.height) / 2,
    );
    final Rect cadre = coin & porte;
    // Un halo doux de la teinte de la marque autour de la porte qui s'ouvre.
    canvas.drawCircle(
      cadre.center,
      porte.height * 0.75,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                teinte.withValues(alpha: 0.22 * ouverture),
                teinte.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: cadre.center,
                radius: porte.height * 0.75,
              ),
            ),
    );
    // La lumiere au sol : elle sort de la porte et s'etire vers la personne.
    if (sol > 0) {
      final double bas = math.min(size.height, cadre.bottom + porte.height / 2);
      final double demi = porte.width / 2 * ouverture;
      final Path rayon = Path()
        ..moveTo(cadre.center.dx - demi, cadre.bottom)
        ..lineTo(cadre.center.dx + demi, cadre.bottom)
        ..lineTo(cadre.center.dx + demi * 1.8, bas)
        ..lineTo(cadre.center.dx - demi * 1.8, bas)
        ..close();
      canvas.drawPath(
        rayon,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              clair.withValues(alpha: 0.35 * sol),
              clair.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(0, cadre.bottom, size.width, bas)),
      );
    }
    // Le contour de l'arche, visible des que l'ecran s'assombrit : on voit
    // la porte avant qu'elle s'ouvre.
    canvas.drawPath(
      _arche(porte, decalage: coin),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = clair.withValues(alpha: 0.35 * assombri),
    );
  }

  @override
  bool shouldRepaint(_Seuil ancien) =>
      ancien.fond != fond ||
      ancien.clair != clair ||
      ancien.teinte != teinte ||
      ancien.assombri != assombri ||
      ancien.ouverture != ouverture ||
      ancien.sol != sol ||
      ancien.porte != porte;
}
