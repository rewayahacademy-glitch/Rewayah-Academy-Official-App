// SOMMAIRE-SOURATES (directeur, 11/11/2026) : la meme table des sourates dans
// les deux lecteurs. Le lecteur de l'eleve : la feuille « Aller a », ouverte
// par le bouton du lecteur. La salle : la bibliotheque de l'enseignant
// (« Choisir une sourate »). Deux gestes : ouvrir, toucher la sourate.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/coran/sommaire_sourates.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/features/salle_enseignant/panneau_enseignant.dart';
import 'package:rewayah_academy/features/tc_mushaf/navigation_coran_feuille.dart';

import '../capture/outil_capture.dart';
import '../support/corpus_coran_depot.dart';
import '../teaching_core/c/faux/faux_corpus_coran.dart';

const Key _ouvrir = Key('ouvrir');

final List<Sourate> _corpus = souratesDuCorpus();

List<Override> get _surcharges => <Override>[
  souratesProvider.overrideWith((Ref _) async => _corpus),
  portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
];

/// Un ecran avec un seul bouton, qui ouvre la surface sous test.
Widget _hote(Future<void> Function(BuildContext context) ouvrir) => Scaffold(
  body: Builder(
    builder: (BuildContext context) => Center(
      child: TextButton(
        key: _ouvrir,
        onPressed: () => ouvrir(context),
        child: const Text('Ouvrir'),
      ),
    ),
  ),
);

Finder _ligne(int numero) => find.byKey(SommaireSourates.cleLigne(numero));

const List<(String, Size, ThemeMode)> _vues = <(String, Size, ThemeMode)>[
  ('390_clair', Size(390, 844), ThemeMode.light),
  ('390_sombre', Size(390, 844), ThemeMode.dark),
  ('1440_clair', Size(1440, 900), ThemeMode.light),
  ('1440_sombre', Size(1440, 900), ThemeMode.dark),
];

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Le lecteur de l eleve : la feuille « Aller a »', () {
    for (final (String nom, Size vue, ThemeMode theme) in _vues) {
      testWidgets('$nom : la table des 114 sourates est la des l ouverture ; '
          'toucher Al-Baqara mene a sa page, la feuille se ferme', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, vue, 1);
        final List<int> pages = <int>[];
        await tester.pumpWidget(
          hoteCapture(
            _hote(
              (BuildContext c) =>
                  FeuilleNavigationCoran.ouvrir(c, onAller: pages.add),
            ),
            surcharges: _surcharges,
            themeMode: theme,
          ),
        );
        await tester.tap(find.byKey(_ouvrir));
        await stabiliser(tester);

        expect(find.text(t.tc.coran.sommaire.titre), findsOneWidget);
        expect(find.byType(SommaireSourates), findsOneWidget);
        // La premiere sourate est a l'ecran sans defiler, avec son nom arabe.
        expect(_ligne(1).hitTestable(), findsOneWidget);
        expect(find.text(_corpus.first.nomArabe), findsOneWidget);
        // Les 114 sont dans la feuille, la derniere au bout du defilement.
        expect(_ligne(114), findsOneWidget);
        // Une seule barre de defilement : celle de la feuille. La table n'en
        // porte aucune.
        expect(
          find.descendant(
            of: find.byType(SommaireSourates),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        if (dossierCapture != null) {
          await capturer(tester, 'sommaire_lecteur_eleve_$nom');
        }

        await tester.tap(_ligne(2));
        await stabiliser(tester);
        expect(pages, <int>[2]);
        expect(find.byType(FeuilleNavigationCoran), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('la derniere sourate s atteint en defilant la feuille, et '
        'mene a la page 604', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      final List<int> pages = <int>[];
      await tester.pumpWidget(
        hoteCapture(
          _hote(
            (BuildContext c) =>
                FeuilleNavigationCoran.ouvrir(c, onAller: pages.add),
          ),
          surcharges: _surcharges,
        ),
      );
      await tester.tap(find.byKey(_ouvrir));
      await stabiliser(tester);
      await tester.scrollUntilVisible(
        _ligne(114),
        600,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(_ligne(114));
      await stabiliser(tester);
      expect(pages, <int>[604]);
    });

    testWidgets('des qu on cherche, la table laisse la place aux resultats', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 1);
      await tester.pumpWidget(
        hoteCapture(
          _hote(
            (BuildContext c) =>
                FeuilleNavigationCoran.ouvrir(c, onAller: (int _) {}),
          ),
          surcharges: _surcharges,
        ),
      );
      await tester.tap(find.byKey(_ouvrir));
      await stabiliser(tester);
      expect(find.byType(SommaireSourates), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'kahf');
      await stabiliser(tester);
      expect(find.byType(SommaireSourates), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await stabiliser(tester);
      expect(find.byType(SommaireSourates), findsOneWidget);
    });
  });

  group('La salle : « Choisir une sourate »', () {
    for (final (String nom, Size vue, ThemeMode theme) in _vues) {
      testWidgets('$nom : la meme table ; toucher Yaseen rend le debut de la '
          'sourate 36', (WidgetTester tester) async {
        fixerVueCapture(tester, vue, 1);
        final SemanticsHandle semantique = tester.ensureSemantics();
        ({int sourate, int verset})? choix;
        await tester.pumpWidget(
          hoteCapture(
            _hote((BuildContext c) async {
              choix = await choisirVersetCoran(c);
            }),
            surcharges: _surcharges,
            themeMode: theme,
          ),
        );
        await tester.tap(find.byKey(_ouvrir));
        await stabiliser(tester);

        expect(find.text(t.enseignant.salle.bibliotheque), findsOneWidget);
        expect(find.byType(SommaireSourates), findsOneWidget);
        expect(_ligne(1).hitTestable(), findsOneWidget);
        expect(find.text(_corpus.first.nomArabe), findsOneWidget);
        expect(_ligne(114), findsOneWidget);
        if (dossierCapture != null) {
          await capturer(tester, 'sommaire_salle_$nom');
        }

        final Sourate yaseen = _corpus[35];
        await tester.scrollUntilVisible(
          _ligne(36),
          600,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(yaseen.nomArabe), findsOneWidget);
        // Le lecteur d'ecran dit l'acte de la salle : presenter a la classe.
        expect(
          find.bySemanticsLabel(
            RegExp(
              RegExp.escape(
                t.enseignant.salle.presenterSourate(
                  deSourate: deDevant(yaseen.nomTranslittere),
                ),
              ),
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(_ligne(36));
        await stabiliser(tester);
        expect(choix, (sourate: 36, verset: 1));
        semantique.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
