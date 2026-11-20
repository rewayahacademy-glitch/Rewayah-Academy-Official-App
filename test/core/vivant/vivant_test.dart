// VIVANT : les briques de mouvement de `lib/core/vivant/`.
//
// La regle commune : tout part du toucher, depasse un peu, se pose, puis se
// tait. « Se tait » se prouve : au repos, plus aucun rappel d'image n'est en
// attente (`transientCallbackCount == 0`), donc aucun ticker actif.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/vivant/niveau_eau.dart';
import 'package:rewayah_academy/core/vivant/nombre_rouleaux.dart';
import 'package:rewayah_academy/core/vivant/praxis_vivant.dart';
import 'package:rewayah_academy/core/vivant/ressort.dart';
import 'package:rewayah_academy/core/vivant/surface_penchee.dart';
import 'package:rewayah_academy/core/vivant/toucher_vivant.dart';

import '../../support/harnais.dart';

int _rappels() => SchedulerBinding.instance.transientCallbackCount;

Future<void> _laisserVivre(WidgetTester tester, {int images = 240}) async {
  for (int i = 0; i < images; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Widget _reduit(Widget enfant) => EffetsReduits(actifs: true, child: enfant);

void main() {
  group('Ressort', () {
    test('depasse sa cible puis se pose', () {
      final Ressort r = Ressort(0, raideur: 420, frein: 14)..cible = 1;
      double sommet = 0;
      for (int i = 0; i < 600 && !r.repos; i++) {
        r.pas(1 / 120);
        if (r.x > sommet) sommet = r.x;
      }
      expect(sommet, greaterThan(1), reason: 'il depasse un peu');
      expect(r.repos, isTrue);
      expect(r.x, closeTo(1, 0.002));
    });

    test('poser : sur la cible, sans vitesse', () {
      final Ressort r = Ressort(0)
        ..cible = 3
        ..v = 9
        ..poser();
      expect(r.x, 3);
      expect(r.v, 0);
      expect(r.repos, isTrue);
    });
  });

  group('AppRadius.interieur', () {
    test('rayon exterieur moins la marge, jamais sous le plus petit cran', () {
      expect(AppRadius.interieur(24, 12), 12);
      expect(AppRadius.interieur(24, 8), 16);
      expect(AppRadius.interieur(24, 24), AppRadius.xs);
      expect(AppRadius.interieur(16, 16), AppRadius.xs);
    });

    test('coinContinu rend une superellipse du rayon demande', () {
      final ShapeBorder forme = AppRadius.coinContinu(AppRadius.lg);
      expect(forme, isA<RoundedSuperellipseBorder>());
      expect(
        (forme as RoundedSuperellipseBorder).borderRadius,
        const BorderRadius.all(Radius.circular(AppRadius.lg)),
      );
    });
  });

  group('ToucherVivant', () {
    testWidgets('s enfonce a l appui, appelle le geste, puis se tait', (
      WidgetTester tester,
    ) async {
      int touches = 0;
      await tester.pumpWidget(
        hote(
          Center(
            child: ToucherVivant(
              onPress: () => touches++,
              child: const SizedBox(width: 120, height: 80),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_rappels(), 0, reason: 'au repos avant tout toucher');

      final TestGesture geste = await tester.startGesture(
        tester.getCenter(find.byType(ToucherVivant)),
      );
      await _laisserVivre(tester, images: 12);
      final Iterable<Transform> transformations = tester.widgetList<Transform>(
        find.descendant(
          of: find.byType(ToucherVivant),
          matching: find.byType(Transform),
        ),
      );
      expect(
        transformations
            .map((Transform x) => x.transform.storage[0])
            .reduce((double a, double b) => a < b ? a : b),
        lessThan(1),
        reason: 'la surface s enfonce sous le doigt',
      );
      await geste.up();
      await _laisserVivre(tester);
      expect(touches, 1);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
    });
  });

  group('SurfacePenchee', () {
    testWidgets('penche au survol, se redresse, puis se tait', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const Center(
            child: SurfacePenchee(child: SizedBox(width: 200, height: 120)),
          ),
        ),
      );
      final TestGesture souris = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await souris.addPointer(location: Offset.zero);
      addTearDown(souris.removePointer);
      final Offset centre = tester.getCenter(find.byType(SurfacePenchee));
      await souris.moveTo(centre + const Offset(60, 30));
      await _laisserVivre(tester, images: 10);
      expect(_rappels(), greaterThan(0), reason: 'elle bouge au survol');
      await souris.moveTo(Offset.zero);
      await _laisserVivre(tester);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
    });
  });

  group('NombreRouleaux', () {
    testWidgets('roule quand le nombre change, puis se tait', (
      WidgetTester tester,
    ) async {
      Widget monter(int n) =>
          hote(Center(child: NombreRouleaux(n, style: const TextStyle())));
      await tester.pumpWidget(monter(12));
      expect(find.text('12'), findsOneWidget);
      expect(_rappels(), 0);

      await tester.pumpWidget(monter(13));
      await _laisserVivre(tester, images: 4);
      expect(find.text('12'), findsOneWidget, reason: 'l ancienne sort');
      expect(find.text('13'), findsOneWidget, reason: 'la nouvelle monte');
      await _laisserVivre(tester);
      expect(find.text('12'), findsNothing);
      expect(find.text('13'), findsOneWidget);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
    });

    testWidgets('effets reduits : la nouvelle valeur, sans animation', (
      WidgetTester tester,
    ) async {
      Widget monter(int n) => hote(
        _reduit(Center(child: NombreRouleaux(n, style: const TextStyle()))),
      );
      await tester.pumpWidget(monter(1));
      await tester.pumpWidget(monter(2));
      await tester.pump();
      // Des la premiere image : la nouvelle valeur seule, rien ne roule.
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
      // Le fondu du theme de `MaterialApp` (nouvelle instance) passe, puis
      // plus rien ne tourne.
      await _laisserVivre(tester, images: 30);
      expect(_rappels(), 0);
    });
  });

  group('NiveauEau', () {
    testWidgets('l eau respire : le seul mouvement qui dure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          const Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: NiveauEau(niveau: 0.5, couleur: Color(0xFF8652E6)),
            ),
          ),
        ),
      );
      await _laisserVivre(tester);
      expect(_rappels(), greaterThan(0));
    });

    testWidgets('effets reduits : l eau est posee, immobile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          _reduit(
            const Center(
              child: SizedBox(
                width: 200,
                height: 120,
                child: NiveauEau(niveau: 0.5, couleur: Color(0xFF8652E6)),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_rappels(), 0, reason: 'aucune image animee en mode reduit');
    });
  });

  group('PraxisVivant', () {
    testWidgets('tombe, rebondit, se pose, puis se tait', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(const Center(child: PraxisVivant(humeur: HumeurPraxis.heureux))),
      );
      await tester.pump();
      await tester.pump();
      expect(_rappels(), greaterThan(0), reason: 'il arrive en tombant');
      await _laisserVivre(tester, images: 600);
      expect(_rappels(), 0, reason: 'au repos, aucun ticker actif');
      expect(tester.takeException(), isNull);
    });

    testWidgets('chaque humeur, le « non » et les larmes finissent', (
      WidgetTester tester,
    ) async {
      final GlobalKey<EtatPraxisVivant> cle = GlobalKey<EtatPraxisVivant>();
      for (final HumeurPraxis h in HumeurPraxis.values) {
        await tester.pumpWidget(
          hote(
            Center(
              child: PraxisVivant(key: cle, humeur: h, tombe: false),
            ),
          ),
        );
        await _laisserVivre(tester, images: 600);
        expect(_rappels(), 0, reason: 'humeur $h : au repos, il se tait');
      }
      cle.currentState!.non();
      await tester.pump();
      await tester.pump();
      expect(_rappels(), greaterThan(0));
      await _laisserVivre(tester, images: 400);
      expect(_rappels(), 0, reason: 'apres le « non », il se tait');
      cle.currentState!.cligner();
      await _laisserVivre(tester, images: 200);
      expect(_rappels(), 0, reason: 'apres le clin, il se tait');
      expect(tester.takeException(), isNull);
    });

    testWidgets('effets reduits : pose d emblee, aucune image animee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(
          _reduit(
            const Center(child: PraxisVivant(humeur: HumeurPraxis.pleure)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_rappels(), 0);
    });

    testWidgets('il est decoratif : rien pour le lecteur d ecran', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hote(const Center(child: PraxisVivant(tombe: false))),
      );
      expect(
        find.ancestor(
          of: find.byType(CustomPaint),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });
}
