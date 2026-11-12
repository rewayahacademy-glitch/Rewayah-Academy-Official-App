// SOMMAIRE-SOURATES (directeur, 11/11/2026) : la table standard, de
// 1 Al-Fatiha a 114 An-Nas, du haut vers le bas ; le nom ARABE de chaque
// sourate, son nom translittere, son numero, sa page de depart. Les noms
// viennent du corpus du depot (migration 0013), jamais d'une liste recopiee.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/pages_depart_sourates.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/coran/sommaire_sourates.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';

import '../../support/corpus_coran_depot.dart';
import '../../support/harnais.dart';

Override _sourates(Future<List<Sourate>?> Function() lecture) =>
    souratesProvider.overrideWith((Ref _) => lecture());

Widget _ecran({
  void Function(Sourate sourate, int page)? onChoisir,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: Scaffold(
    body: SingleChildScrollView(
      child: SommaireSourates(
        libelleSemantique: (Sourate s, int page) =>
            'Aller a ${s.nomTranslittere}, page $page',
        onChoisir: onChoisir ?? (Sourate _, int _) {},
      ),
    ),
  ),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final List<Sourate> corpus = souratesDuCorpus();

  test('le corpus du depot porte les 114 sourates', () {
    expect(corpus, hasLength(114));
    expect(corpus.first.numero, 1);
    expect(corpus.last.numero, 114);
  });

  testWidgets('la table entiere : 114 lignes, de 1 a 114, du haut vers le '
      'bas, chacune avec son nom arabe, son nom translittere, son numero et '
      'sa page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Lue dans le desordre : la table remet l'ordre du mushaf.
    final List<Sourate> melangees = corpus.reversed.toList();
    await tester.pumpWidget(
      hote(_ecran(), surcharges: <Override>[_sourates(() async => melangees)]),
    );
    await tester.pump();

    double precedente = double.negativeInfinity;
    for (final Sourate s in corpus) {
      final Finder ligne = find.byKey(
        SommaireSourates.cleLigne(s.numero),
        skipOffstage: false,
      );
      expect(ligne, findsOneWidget, reason: 'sourate ${s.numero} absente');
      final double haut = tester.getTopLeft(ligne).dy;
      expect(
        haut,
        greaterThan(precedente),
        reason: 'la sourate ${s.numero} n est pas sous la precedente',
      );
      precedente = haut;

      Finder dans(Finder f) =>
          find.descendant(of: ligne, matching: f, skipOffstage: false);
      // Le nom arabe : celui du corpus, en police arabe des documents, de
      // droite a gauche.
      final Text arabe = tester.widget<Text>(dans(find.text(s.nomArabe)));
      expect(arabe.textDirection, TextDirection.rtl);
      expect(arabe.style?.fontFamily, AppFontFamily.arabeDocument);
      expect(dans(find.text(s.nomTranslittere)), findsOneWidget);
      expect(dans(find.text('${s.numero}')), findsOneWidget);
      expect(
        dans(
          find.text(
            t.tc.coran.navigation.pageNumero(
              page: pagesDeDepartDesSourates[s.numero - 1],
            ),
          ),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('sommaire-sourate-'),
        skipOffstage: false,
      ),
      findsNWidgets(114),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la table ne defile pas elle-meme : une seule barre de '
      'defilement, celle de la surface qui la porte', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(_ecran(), surcharges: <Override>[_sourates(() async => corpus)]),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(SommaireSourates),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('toucher une sourate rend la sourate et sa page de depart', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    final List<(int, int)> choisies = <(int, int)>[];
    await tester.pumpWidget(
      hote(
        _ecran(
          onChoisir: (Sourate s, int page) => choisies.add((s.numero, page)),
        ),
        surcharges: <Override>[_sourates(() async => corpus)],
      ),
    );
    await tester.pump();
    final Finder kahf = find.byKey(SommaireSourates.cleLigne(18));
    await tester.scrollUntilVisible(kahf, 400);
    await tester.tap(kahf);
    expect(choisies, <(int, int)>[(18, 293)]);
    // Le lecteur d'ecran dit l'acte, pas quatre morceaux de texte.
    expect(
      find.bySemanticsLabel(
        RegExp(
          'Aller a ${RegExp.escape(corpus[17].nomTranslittere)}, page 293',
        ),
      ),
      findsOneWidget,
    );
    semantique.dispose();
  });

  testWidgets('en arabe, la ligne se retourne : le numero passe a droite', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        _ecran(direction: TextDirection.rtl),
        surcharges: <Override>[_sourates(() async => corpus)],
      ),
    );
    await tester.pump();
    final Finder ligne = find.byKey(SommaireSourates.cleLigne(1));
    final double numero = tester
        .getCenter(find.descendant(of: ligne, matching: find.text('1')))
        .dx;
    final double nom = tester
        .getCenter(
          find.descendant(
            of: ligne,
            matching: find.text(corpus.first.nomArabe),
          ),
        )
        .dx;
    expect(numero, greaterThan(nom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lecture impossible : on le dit, avec « Reessayer » ; aucune '
      'sourate inventee', (WidgetTester tester) async {
    int lectures = 0;
    await tester.pumpWidget(
      hote(
        _ecran(),
        surcharges: <Override>[
          _sourates(() async {
            lectures++;
            return null;
          }),
        ],
      ),
    );
    await tester.pump();
    expect(find.text(t.tc.coran.sommaire.indisponible), findsOneWidget);
    expect(find.text(t.tc.coran.sommaire.indisponibleDetail), findsOneWidget);
    expect(find.byKey(SommaireSourates.cleLigne(1)), findsNothing);
    await tester.tap(find.text(t.commun.reessayer));
    await tester.pump();
    expect(lectures, 2);
  });

  testWidgets('corpus vide : on le dit, sans bouton qui ne mene a rien', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        _ecran(),
        surcharges: <Override>[_sourates(() async => const <Sourate>[])],
      ),
    );
    await tester.pump();
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(t.tc.coran.sommaire.absent), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsNothing);
  });
}
