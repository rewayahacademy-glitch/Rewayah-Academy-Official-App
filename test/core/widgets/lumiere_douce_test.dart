// LUMIERE-DOUCE (directeur, 11/11/2026, vu en production sur la carte rouge
// « Aucun appareil pret » de l'Accueil du tuteur) : la lumiere d'une carte
// pleine largeur n'est coupee ni par les bords de l'ecran ni par un parent,
// elle tourne plus lentement et moins fort que le cercle Compte, puis reste
// en lueur fixe tres legere. Le cercle Compte ne change pas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/halo_lumiere.dart';
import 'package:rewayah_academy/core/widgets/lumiere_autour.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_lumiere.dart';

/// Une page reelle (`PageShell`, gouttiere de la page, defilement) et trois
/// cartes pleine largeur allumees : rouge, orange, bleu.
Widget _page() => PageShell(
  titre: 'Accueil',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: <Widget>[
      for (final NatureHalo nature in <NatureHalo>[
        NatureHalo.urgent,
        NatureHalo.aPreparer,
        NatureHalo.nouveau,
      ])
        LumiereAutour(
          nature: nature,
          child: AppCard(
            child: Text(
              'Carte ${nature.name} : une ligne de texte qui occupe toute la '
              'largeur de la carte.',
            ),
          ),
        ),
    ],
  ),
);

Future<void> _monter(
  WidgetTester tester, {
  required double largeur,
  double echelle = 1,
  ThemeMode mode = ThemeMode.light,
  double densite = 1,
}) async {
  fixerVueCapture(tester, Size(largeur, 900), densite);
  await tester.pumpWidget(
    hoteCapture(_page(), themeMode: mode, echelleTexte: echelle),
  );
}

void main() {
  group('LUMIERE-DOUCE : jamais coupee', () {
    for (final double largeur in <double>[320, 390]) {
      for (final double echelle in <double>[1, 2]) {
        testWidgets('$largeur px, texte x$echelle : pendant et apres la '
            'rotation', (WidgetTester tester) async {
          await _monter(tester, largeur: largeur, echelle: echelle);
          await tester.pump(const Duration(milliseconds: 600));
          expect(find.byKey(HaloLumiere.lumiereKey), findsWidgets);
          verifierLumieresEntieres(tester, auMoins: 3);
          await tester.pumpAndSettle();
          expect(find.byKey(HaloLumiere.lueurKey), findsNWidgets(3));
          verifierLumieresEntieres(tester, auMoins: 3);
        });
      }
    }

    testWidgets('la garde echoue si un parent coupe la lumiere', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 600), 1);
      await tester.pumpWidget(
        hoteCapture(
          const Center(
            child: ClipRect(
              child: SizedBox(
                width: 300,
                height: 80,
                child: LumiereAutour(
                  nature: NatureHalo.urgent,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        () => verifierLumieresEntieres(tester),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('la garde echoue si la lumiere depasse le bord de l ecran', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(320, 600), 1);
      await tester.pumpWidget(
        hoteCapture(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              height: 80,
              child: LumiereAutour(
                nature: NatureHalo.urgent,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        () => verifierLumieresEntieres(tester),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('LUMIERE-DOUCE : plus lente et plus douce que le cercle Compte', () {
    test('portee totale au plus 12, dans la gouttiere de 16', () {
      expect(
        HaloLumiere.porteeCarte + 3 * HaloLumiere.flouCarte,
        lessThanOrEqualTo(HaloLumiere.debordementCarte),
      );
      expect(HaloLumiere.debordementCarte, lessThanOrEqualTo(12));
    });

    test('rotation deux fois plus lente, moins de tours, opacite basse', () {
      expect(AppMouvement.tourHaloCarte, AppMouvement.tourHaloUrgent * 2);
      expect(
        AppMouvement.toursHaloCarte,
        lessThan(AppMouvement.toursHaloUrgent),
      );
      expect(
        AppMouvement.tourHaloCarte * AppMouvement.toursHaloCarte,
        lessThan(const Duration(seconds: 5)),
      );
      expect(CouleursHalo.intensiteCarte, lessThanOrEqualTo(0.5));
    });

    testWidgets('une carte reste en rotation 4,8 s, puis lueur fixe', (
      WidgetTester tester,
    ) async {
      await _monter(tester, largeur: 390);
      await tester.pump(const Duration(milliseconds: 4700));
      expect(find.byKey(HaloLumiere.lumiereKey), findsWidgets);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(HaloLumiere.lumiereKey), findsNothing);
      expect(find.byKey(HaloLumiere.lueurKey), findsNWidgets(3));
    });
  });

  group('Capture : LUMIERE-DOUCE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final double largeur in <double>[320, 390]) {
      for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
        ('clair', ThemeMode.light),
        ('sombre', ThemeMode.dark),
      ]) {
        for (final double echelle in <double>[1, 2]) {
          final String nom = '${largeur.toInt()}_${m}_x${echelle.toInt()}';
          testWidgets('lumiere_douce_$nom', (WidgetTester tester) async {
            await _monter(
              tester,
              largeur: largeur,
              echelle: echelle,
              mode: mode,
              densite: 2,
            );
            await tester.pump(const Duration(milliseconds: 1200));
            debugPrint(
              'PNG ${await capturer(tester, 'lumiere_douce_rotation_$nom')}',
            );
            await tester.pumpAndSettle();
            debugPrint(
              'PNG ${await capturer(tester, 'lumiere_douce_fixe_$nom')}',
            );
          });
        }
      }
    }
  });
}
