import 'package:flutter/widgets.dart';

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
/// Decorative : exclue de l'arbre semantique, sans mouvement.
class PorteLumiere extends StatelessWidget {
  /// Cree l'illustration.
  const PorteLumiere({super.key});

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
