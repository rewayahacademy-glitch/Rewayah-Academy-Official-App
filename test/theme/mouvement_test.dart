import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';

/// Rend un widget sous une preference de mouvement donnee et renvoie son
/// contexte, pour interroger les fonctions qui dependent du systeme.
Future<BuildContext> contexteAvec(
  WidgetTester tester, {
  required bool animationsDesactivees,
}) async {
  late BuildContext capture;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: animationsDesactivees),
      child: Builder(
        builder: (BuildContext context) {
          capture = context;
          return const SizedBox();
        },
      ),
    ),
  );
  return capture;
}

void main() {
  group('Le budget de duree', () {
    test('les valeurs sont celles du tableau', () {
      expect(AppMouvement.retourTactile.inMilliseconds, 120);
      expect(AppMouvement.micro.inMilliseconds, 160);
      expect(AppMouvement.apparition.inMilliseconds, 200);
      expect(AppMouvement.navigation.inMilliseconds, 240);
      expect(AppMouvement.feuilleOuverture.inMilliseconds, 280);
      expect(AppMouvement.feuilleFermeture.inMilliseconds, 200);
      expect(AppMouvement.plafond.inMilliseconds, 400);
    });

    test('aucune transition ne depasse le plafond de 400 ms', () {
      // Une animation plus longue que ca n'explique plus, elle fait attendre.
      for (final Duration d in <Duration>[
        AppMouvement.retourTactile,
        AppMouvement.micro,
        AppMouvement.apparition,
        AppMouvement.navigation,
        AppMouvement.feuilleOuverture,
        AppMouvement.feuilleFermeture,
        AppMouvement.disparitionOpacite,
      ]) {
        expect(d, lessThanOrEqualTo(AppMouvement.plafond));
      }
    });

    test('la sortie est plus courte que l entree, d environ un tiers', () {
      expect(
        AppMouvement.feuilleFermeture,
        lessThan(AppMouvement.feuilleOuverture),
      );
      final double rapport =
          AppMouvement.feuilleFermeture.inMilliseconds /
          AppMouvement.feuilleOuverture.inMilliseconds;
      expect(rapport, closeTo(0.71, 0.05));
    });

    test('la pulsation est hors budget, et c est le seul cas', () {
      // Le plafond borne ce qui EXPLIQUE un changement, pas ce qui signale une
      // imminence en continu : un battement de 400 ms serait une alarme.
      expect(AppMouvement.pulsation, greaterThan(AppMouvement.plafond));
      expect(AppMouvement.pulsation.inMilliseconds, 1200);
    });
  });

  group('Les courbes : trois, pas davantage', () {
    test('l entree et la sortie sont les deux cubiques', () {
      expect(AppMouvement.entree, Curves.easeOutCubic);
      expect(AppMouvement.sortie, Curves.easeInCubic);
    });

    test('linear est reserve aux progressions indeterminees', () {
      expect(AppMouvement.progressionIndeterminee, Curves.linear);
    });

    test('le ressort des feuilles n a aucun rebond visible', () {
      // Amortissement critique : une arrivee qui n'est pas mecanique, pas un
      // rebond. bounceOut et elasticOut n'existent pas dans ce produit.
      final SpringDescription r = AppMouvement.ressort;
      final double critique = 2 * math.sqrt(r.mass * r.stiffness);
      expect(r.damping, closeTo(critique, 0.001));
    });
  });

  group('Les amplitudes des motifs', () {
    test('elles appartiennent a l echelle d espacement', () {
      // Une translation est un espacement : elle ne s'invente pas non plus.
      expect(AppSpacing.echelle, contains(AppMouvement.translationAjout));
      expect(AppSpacing.echelle, contains(AppMouvement.translationRetourLocal));
      expect(AppSpacing.echelle, contains(AppMouvement.translationNavigation));
    });

    test('le voile d une feuille reste sous la moitie', () {
      expect(AppMouvement.opaciteVoile, 0.32);
      expect(AppMouvement.opaciteVoile, lessThan(0.5));
    });
  });

  group('Reduction du mouvement', () {
    testWidgets('sans la preference, les durees et translations sont pleines', (
      WidgetTester tester,
    ) async {
      final BuildContext c = await contexteAvec(
        tester,
        animationsDesactivees: false,
      );
      expect(AppMouvement.mouvementReduit(c), isFalse);
      expect(
        AppMouvement.duree(c, AppMouvement.navigation),
        AppMouvement.navigation,
      );
      expect(
        AppMouvement.translation(c, AppMouvement.translationNavigation),
        AppMouvement.translationNavigation,
      );
    });

    testWidgets('avec la preference, il ne reste qu un fondu', (
      WidgetTester tester,
    ) async {
      final BuildContext c = await contexteAvec(
        tester,
        animationsDesactivees: true,
      );
      expect(AppMouvement.mouvementReduit(c), isTrue);
      expect(
        AppMouvement.duree(c, AppMouvement.navigation),
        AppMouvement.disparitionOpacite,
      );
      expect(
        AppMouvement.translation(c, AppMouvement.translationNavigation),
        0,
      );
    });
  });

  group('Les rayons', () {
    test('l echelle a cinq crans et un seul est une forme', () {
      expect(AppRadius.echelle, <double>[8, 12, 16, 24]);
      expect(AppRadius.full, 999);
      expect(AppRadius.echelle, isNot(contains(AppRadius.full)));
    });

    test('le rayon d un enfant est plus petit que celui de son parent', () {
      // L'inverse produit l'effet de bulle qui date le produit.
      expect(AppRadius.enfantDe(AppRadius.lg), AppRadius.md);
      expect(AppRadius.enfantDe(AppRadius.md), AppRadius.sm);
      expect(AppRadius.enfantDe(AppRadius.sm), AppRadius.xs);
    });

    test('on ne descend jamais sous le cran le plus serre', () {
      expect(AppRadius.enfantDe(AppRadius.xs), AppRadius.xs);
    });

    test('une pilule contient une tuile, pas une pastille', () {
      expect(AppRadius.enfantDe(AppRadius.full), AppRadius.lg);
    });
  });
}
