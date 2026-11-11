// La scene d'attente (directeur, 11/11/2026, salle) : « l'ecran blanc qui
// s'affiche avant la rentree des membres de la classe est moche, il faut la
// brander avec le logo des pages de chargement, mais la page ne doit pas se
// transformer en violet. Trouve un combo pour qu'on sache qu'on est en
// attente sans que ca soit moche, et ajoute des effets et animations
// hypnotisants pour faciliter l'attente. »
//
// Le symbole de la marque, pose par [BrandLogo] (aucun dessin refait), au
// centre d'ondes lentes qui partent de lui et s'effacent en s'eloignant,
// comme une goutte tombee dans l'eau. La surface reste celle de l'ecran
// (claire ou sombre) : seules les ondes portent la teinte de la marque, en
// transparence.
//
// - Le mouvement dit « on attend » : il dure tant que l'attente dure
//   ([AppMouvement.ondeAttente], boucle d'attente comme le reflet des
//   squelettes), lent, sans a-coup, sans clignotement (WCAG 2.3.1).
// - « Reduire les animations » : les memes ondes, immobiles. L'information
//   (on attend) reste portee par le texte de l'ecran, jamais par le mouvement.
// - Decorative : exclue de l'arbre semantique, ne recoit aucun geste.
// - Rien ne se reconstruit a chaque image : la peinture seule suit l'horloge.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'brand_logo.dart';

/// Le symbole de la marque au centre d'ondes lentes : l'illustration d'une
/// attente (la salle avant l'arrivee des autres).
class SceneAttente extends StatefulWidget {
  /// Cree la scene, dans un carre de [cote] au plus.
  const SceneAttente({this.cote = coteStandard, super.key});

  /// Le cote du carre ou vivent les ondes.
  final double cote;

  /// Le cote par defaut : quatre respirations de la grille.
  static const double coteStandard = AppSpacing.respiration * 4;

  /// Le plus petit cote ou la scene reste lisible.
  static const double coteMinimal = AppSpacing.respiration * 2;

  /// Le nombre d'ondes visibles a la fois.
  static const int ondes = 4;

  /// La cle de la peinture des ondes (tests).
  static const Key cleOndes = ValueKey<String>('scene-attente-ondes');

  /// Faux : les ondes ne tournent pas (elles restent posees).
  ///
  /// **Reserve aux tests** : une boucle sans fin empeche `pumpAndSettle` de
  /// rendre la main. `test/flutter_test_config.dart` la coupe pour toute la
  /// suite ; le test du composant la rallume. Jamais touche par l'application.
  @visibleForTesting
  static bool boucle = true;

  @override
  State<SceneAttente> createState() => _EtatSceneAttente();
}

class _EtatSceneAttente extends State<SceneAttente>
    with SingleTickerProviderStateMixin {
  late final AnimationController _horloge = AnimationController(
    vsync: this,
    duration: AppMouvement.ondeAttente,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mouvement reduit : aucune boucle, les ondes restent posees.
    if (AppMouvement.mouvementReduit(context) || !SceneAttente.boucle) {
      _horloge.stop();
    } else if (!_horloge.isAnimating) {
      _horloge.repeat();
    }
  }

  @override
  void dispose() {
    _horloge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool reduit = AppMouvement.mouvementReduit(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final double cote = math.max(
              SceneAttente.coteMinimal,
              math.min(
                widget.cote,
                math.min(
                  c.hasBoundedWidth ? c.maxWidth : widget.cote,
                  c.hasBoundedHeight ? c.maxHeight : widget.cote,
                ),
              ),
            );
            // Le symbole : un quart du cote, jamais sous sa taille minimale.
            final double symbole = math.max(BrandLogo.minimumSymbole, cote / 4);
            // Dans un cadre impose, la scene garde son cote et se centre.
            return Center(
              child: SizedBox.square(
                dimension: cote,
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: SceneAttente.cleOndes,
                    painter: _Ondes(
                      horloge: _horloge,
                      teinte: palette.surfacePrimary.background,
                      coeur: symbole * 0.75,
                      immobile: reduit,
                    ),
                    child: Center(
                      child: BrandLogo(
                        variante: VarianteLogo.symbole,
                        hauteur: symbole,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Les ondes : des anneaux qui naissent au bord du symbole, grandissent
/// jusqu'au bord de la scene et s'effacent ; un halo doux respire dessous.
class _Ondes extends CustomPainter {
  _Ondes({
    required this.horloge,
    required this.teinte,
    required this.coeur,
    required this.immobile,
  }) : super(repaint: horloge);

  final Animation<double> horloge;
  final Color teinte;

  /// Le rayon d'ou partent les ondes (le bord du symbole).
  final double coeur;

  /// Mouvement reduit : les ondes posees, sans horloge.
  final bool immobile;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final double bord = size.shortestSide / 2;
    final double t = immobile ? 0.5 : horloge.value;

    // Le halo : une lueur douce sous le symbole, qui respire une fois par
    // tour (un sinus : ni depart ni arrivee visibles).
    final double souffle = immobile
        ? 0.5
        : 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    canvas.drawCircle(
      centre,
      bord,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            teinte.withValues(alpha: 0.10 + 0.06 * souffle),
            teinte.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: bord)),
    );

    // Les ondes : decalees d'une part de tour, elles se suivent sans fin.
    // Chacune ralentit en s'eloignant et s'efface avant le bord : aucune
    // n'apparait ni ne disparait d'un coup.
    for (int i = 0; i < SceneAttente.ondes; i++) {
      final double phase = (t + i / SceneAttente.ondes) % 1;
      final double avance = 1 - (1 - phase) * (1 - phase);
      final double rayon = coeur + (bord - coeur) * avance;
      // Fondu d'entree sur le premier dixieme, puis effacement regulier.
      final double entree = math.min(1, phase / 0.1);
      final double alpha = 0.42 * entree * (1 - phase) * (1 - phase);
      if (alpha <= 0.004) continue;
      canvas.drawCircle(
        centre,
        rayon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + 1.5 * (1 - phase)
          ..color = teinte.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_Ondes ancien) =>
      ancien.teinte != teinte ||
      ancien.coeur != coeur ||
      ancien.immobile != immobile;
}
