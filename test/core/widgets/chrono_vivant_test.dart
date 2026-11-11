// CHRONO-ETAT (directeur, 10 et 11/11/2026) : la capsule du chrono de la
// salle. Elle montre ce qui reste, puis le depassement ; elle change d'etat a
// cinq minutes de la fin et a la fin prevue ; elle reste sobre chez qui ne
// conduit pas la seance ; sans mouvement, elle dit la meme chose.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 18);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
  depassementMax: const Duration(minutes: 15),
);

ChronoSeance _a(Duration depuisT0) =>
    ChronoSeance.a(_bornes, _t0.add(depuisT0));

Future<void> _poser(
  WidgetTester tester,
  ChronoSeance chrono, {
  bool sobre = false,
  bool mouvementReduit = false,
  ValueChanged<EtatChronoVivant>? onEtat,
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  double largeur = 390,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(largeur, 400),
        textScaler: TextScaler.linear(echelle),
        disableAnimations: mouvementReduit,
      ),
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, luminosite),
        home: Directionality(
          textDirection: sens,
          child: Material(
            child: Align(
              alignment: Alignment.topLeft,
              child: ChronoVivant(
                chrono: chrono,
                annonce: 'annonce',
                libelleFini: 'Temps prévu écoulé',
                sobre: sobre,
                onEtat: onEtat,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Les chiffres rendus, lus case par case une fois les roulements finis.
String _rendu(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(ChronoVivant.cleChiffres),
        matching: find.byType(Text),
      ),
    )
    .map((Text t) => t.data!)
    .join();

Color _fond(WidgetTester tester) {
  final AnimatedContainer capsule = tester.widget<AnimatedContainer>(
    find.byKey(ChronoVivant.cleCapsule),
  );
  return (capsule.decoration! as BoxDecoration).color!;
}

void main() {
  test('chiffres : le reste, puis le depassement precede d un plus', () {
    expect(
      ChronoVivant.chiffresDe(_a(const Duration(minutes: 3, seconds: 16))),
      '56:44',
    );
    expect(ChronoVivant.chiffresDe(_a(const Duration(minutes: 60))), '+00:00');
    expect(
      ChronoVivant.chiffresDe(_a(const Duration(minutes: 63, seconds: 12))),
      '+03:12',
    );
  });

  test('etat : calme, bientot a cinq minutes, depassement, fini', () {
    const Duration seuil = Duration(minutes: 5);
    expect(
      ChronoVivant.etatDe(_a(const Duration(minutes: 10)), seuil),
      EtatChronoVivant.calme,
    );
    expect(
      ChronoVivant.etatDe(_a(const Duration(minutes: 54, seconds: 59)), seuil),
      EtatChronoVivant.calme,
    );
    expect(
      ChronoVivant.etatDe(_a(const Duration(minutes: 55)), seuil),
      EtatChronoVivant.bientot,
    );
    expect(
      ChronoVivant.etatDe(_a(const Duration(minutes: 60)), seuil),
      EtatChronoVivant.depassement,
    );
    expect(
      ChronoVivant.etatDe(_a(const Duration(minutes: 75)), seuil),
      EtatChronoVivant.fini,
    );
  });

  testWidgets('la capsule rend les chiffres du temps restant', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _a(const Duration(minutes: 3, seconds: 16)));
    await tester.pumpAndSettle();
    expect(_rendu(tester), '56:44');
    expect(tester.takeException(), isNull);
  });

  testWidgets('un chiffre qui change roule, puis se pose', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _a(const Duration(minutes: 3, seconds: 16)));
    await tester.pumpAndSettle();
    await _poser(tester, _a(const Duration(minutes: 3, seconds: 17)));
    // Pendant le roulement, l'ancien et le nouveau chiffre coexistent.
    await tester.pump(const Duration(milliseconds: 60));
    expect(_rendu(tester).length, greaterThan('56:43'.length));
    await tester.pumpAndSettle();
    expect(_rendu(tester), '56:43');
  });

  testWidgets(
    'mouvement reduit : aucun roulement, le chiffre change d un coup',
    (WidgetTester tester) async {
      await _poser(
        tester,
        _a(const Duration(minutes: 3, seconds: 16)),
        mouvementReduit: true,
      );
      await tester.pump();
      await _poser(
        tester,
        _a(const Duration(minutes: 3, seconds: 17)),
        mouvementReduit: true,
      );
      await tester.pump();
      expect(_rendu(tester), '56:43');
      // La capsule est a sa taille : aucun ressort n'a ete lance.
      final ScaleTransition echelle = tester.widget<ScaleTransition>(
        find.descendant(
          of: find.byType(ChronoVivant),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(echelle.scale.value, 1);
    },
  );

  testWidgets('teintes : attention a cinq minutes, alerte au depassement', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _a(const Duration(minutes: 10)));
    await tester.pumpAndSettle();
    final AppPalette palette = AppPalette.of(
      tester.element(find.byType(ChronoVivant)),
    );
    expect(_fond(tester), palette.surfaceRaised.background);
    await _poser(tester, _a(const Duration(minutes: 56)));
    await tester.pumpAndSettle();
    expect(_fond(tester), palette.washWarning.background);
    await _poser(tester, _a(const Duration(minutes: 61)));
    await tester.pumpAndSettle();
    expect(_fond(tester), palette.washAlert.background);
    expect(_rendu(tester), '+01:00');
  });

  testWidgets(
    'sobre (qui ne conduit pas la seance) : jamais de teinte d urgence',
    (WidgetTester tester) async {
      await _poser(tester, _a(const Duration(minutes: 61)), sobre: true);
      await tester.pumpAndSettle();
      final AppPalette palette = AppPalette.of(
        tester.element(find.byType(ChronoVivant)),
      );
      expect(_fond(tester), palette.surfaceRaised.background);
      // Les chiffres, eux, disent la meme chose a tous.
      expect(_rendu(tester), '+01:00');
    },
  );

  testWidgets('onEtat : appele aux changements, jamais a l ouverture', (
    WidgetTester tester,
  ) async {
    final List<EtatChronoVivant> vus = <EtatChronoVivant>[];
    await _poser(tester, _a(const Duration(minutes: 56)), onEtat: vus.add);
    await tester.pumpAndSettle();
    expect(
      vus,
      isEmpty,
      reason: 'entrer a cinq minutes de la fin ne sonne pas',
    );
    await _poser(tester, _a(const Duration(minutes: 57)), onEtat: vus.add);
    await tester.pumpAndSettle();
    expect(vus, isEmpty);
    await _poser(tester, _a(const Duration(minutes: 60)), onEtat: vus.add);
    await tester.pumpAndSettle();
    await _poser(tester, _a(const Duration(minutes: 75)), onEtat: vus.add);
    await tester.pumpAndSettle();
    expect(vus, <EtatChronoVivant>[
      EtatChronoVivant.depassement,
      EtatChronoVivant.fini,
    ]);
  });

  testWidgets('depassement epuise : la phrase de fin, plus de chiffres', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _a(const Duration(minutes: 80)));
    await tester.pumpAndSettle();
    expect(find.text('Temps prévu écoulé'), findsOneWidget);
    expect(find.byKey(ChronoVivant.cleChiffres), findsNothing);
  });

  testWidgets('arabe : les chiffres restent de gauche a droite', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      _a(const Duration(minutes: 3, seconds: 16)),
      sens: TextDirection.rtl,
    );
    await tester.pumpAndSettle();
    expect(_rendu(tester), '56:44');
    final List<double> gauches = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(ChronoVivant.cleChiffres),
            matching: find.byType(Text),
          ),
        )
        .map((Text t) => tester.getTopLeft(find.byWidget(t)).dx)
        .toList();
    expect(gauches, orderedEquals(<double>[...gauches]..sort()));
  });

  for (final Brightness luminosite in Brightness.values) {
    for (final double echelle in <double>[1, 2]) {
      testWidgets('320 px, texte x${echelle.toInt()}, ${luminosite.name} : '
          'la capsule tient, lisible', (WidgetTester tester) async {
        await _poser(
          tester,
          _a(const Duration(minutes: 63, seconds: 12)),
          luminosite: luminosite,
          echelle: echelle,
          largeur: 320,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Rect r = tester.getRect(find.byKey(ChronoVivant.cleCapsule));
        expect(r.right, lessThanOrEqualTo(320.5));
      });
    }
  }

  testWidgets('lecteur d ecran : un seul noeud, l annonce, pas les chiffres', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    await _poser(tester, _a(const Duration(minutes: 3, seconds: 16)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('annonce'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'\d\d:\d\d')), findsNothing);
    poignee.dispose();
  });
}
