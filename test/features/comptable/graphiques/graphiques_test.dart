// COMPTA-GRAPH-1 : les graphiques du Comptable (decision du directeur du
// 11/10, qui leve DR-09), sur port de demonstration.
//
// Ce que le test prouve :
// - montants masques, aucun graphique n'est dessine (la forme dirait le
//   montant) et la variation en pourcentage est masquee avec eux (Q-9) ;
//   affiches, le dessin, sa legende ecrite et le tableau des valeurs
//   (l'alternative accessible) sont la ;
// - les cinq etats de chaque bloc : chargement, contenu, vide, erreur, hors
//   ligne, plus la source absente (« en preparation ») ;
// - les exports passent par un port : la reference rendue, l'echec dit en une
//   phrase, et sans capacite une phrase a la place de l'action ;
// - l'onglet « Rapports » est le quatrieme de Tresorerie ;
// - 320 px, texte a 200 %, LTR et RTL.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_export_rapports.dart';
import 'package:rewayah_academy/core/capacites/port_series_tresorerie.dart';
import 'package:rewayah_academy/core/comptable/navigation_comptable.dart';
import 'package:rewayah_academy/core/comptable/visibilite_montants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/comptable/graphiques/graphiques_comptable.dart';
import 'package:rewayah_academy/core/widgets/comptable/pourcentage_sensible.dart';
import 'package:rewayah_academy/features/comptable/graphiques/blocs_graphiques.dart';
import 'package:rewayah_academy/features/comptable/graphiques/rapports_page.dart';
import 'package:rewayah_academy/features/demo/comptable/series_demo.dart';

import '../../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../../support/aucun_mot_coupe.dart';
import '../../../support/harnais.dart';

final DateTime _jour = DateTime(2026, 10, 4);

class _Visibilite extends VisibiliteMontants {
  _Visibilite(this.depart);
  final bool depart;
  @override
  bool build() => depart;
}

class _SeriesFictives implements PortSeriesTresorerie {
  _SeriesFictives({this.echec = false, this.attente, this.vide = false});
  final bool echec;
  final bool vide;
  final Completer<void>? attente;

  @override
  Future<SeriesTresorerie> series() async {
    if (attente != null) await attente!.future;
    if (echec) throw StateError('hors portee');
    return SeriesTresorerieDemo(aujourdhui: _jour, vide: vide).series();
  }
}

class _ExportEchec implements PortExportRapports {
  @override
  Future<ResultatExport> exporterRapport({required String cleIdempotence}) =>
      Future<ResultatExport>.error(StateError('perdu'));

  @override
  Future<ResultatExport> exporterSelection({
    required List<String> identifiants,
    required String cleIdempotence,
  }) => Future<ResultatExport>.error(StateError('perdu'));
}

List<Override> _surcharges({
  PortSeriesTresorerie? series,
  PortExportRapports? export,
  bool affiches = false,
  bool horsLigne = false,
}) => <Override>[
  if (series != null) portSeriesTresorerieProvider.overrideWithValue(series),
  if (export != null) portExportRapportsProvider.overrideWithValue(export),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  visibiliteMontantsProvider.overrideWith(() => _Visibilite(affiches)),
];

Future<void> _monter(
  WidgetTester tester,
  Widget page,
  List<Override> surcharges, {
  Size taille = const Size(1440, 4000),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hote(
      MediaQuery(
        data: MediaQueryData(
          size: taille,
          textScaler: TextScaler.linear(echelle),
        ),
        child: Directionality(textDirection: direction, child: page),
      ),
      surcharges: surcharges,
    ),
  );
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

void main() {
  final g = t.comptable.graphiques;
  const Widget rapports = RapportsPage();
  final PortSeriesTresorerie demo = SeriesTresorerieDemo(aujourdhui: _jour);

  group('Montants masques', () {
    testWidgets('aucun graphique dessine, une phrase le dit', (
      WidgetTester tester,
    ) async {
      await _monter(tester, rapports, _surcharges(series: demo));
      expect(_cle('graphique-masque'), findsNWidgets(2));
      expect(_cle('graphique-dessin'), findsNothing);
      expect(find.text(g.masque), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('affiches : dessin, legende ecrite et tableau des valeurs', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        rapports,
        _surcharges(series: demo, affiches: true),
      );
      expect(_cle('graphique-dessin'), findsNWidgets(2));
      expect(_cle('graphique-masque'), findsNothing);
      // La couleur n'est jamais seule : chaque serie a son mot.
      Finder legende(String mot) => find.descendant(
        of: find.byType(LegendeGraphique),
        matching: find.text(mot),
      );
      expect(legende(g.legendeEntrees), findsOneWidget);
      expect(legende(g.legendeSorties), findsOneWidget);
      expect(legende(g.legendeEncaissements), findsOneWidget);
      // L'alternative accessible s'ouvre.
      expect(_cle('graphique-tableau'), findsNothing);
      await tester.tap(_cle('graphique-valeurs-lien').first);
      await tester.pump();
      expect(_cle('graphique-tableau'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('le tableau des valeurs masque ses montants', (
      WidgetTester tester,
    ) async {
      await _monter(tester, rapports, _surcharges(series: demo));
      await tester.tap(_cle('graphique-valeurs-lien').first);
      await tester.pump();
      expect(_cle('graphique-tableau'), findsOneWidget);
      expect(find.textContaining('4 200'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('la variation en % se masque avec les montants', (
      WidgetTester tester,
    ) async {
      const Widget kpi = Scaffold(body: CarteIndicateursFlux());
      await _monter(tester, kpi, _surcharges(series: demo));
      expect(
        find.text(g.variation(pourcent: PourcentageSensible.masque)),
        findsNWidgets(2),
      );
      expect(find.text(g.variation(pourcent: '+12')), findsNothing);
      await _monter(tester, kpi, _surcharges(series: demo, affiches: true));
      expect(find.text(g.variation(pourcent: '+12')), findsOneWidget);
      expect(find.text(g.variation(pourcent: '-4')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Les cinq etats', () {
    testWidgets('contenu : entrees et sorties, flux', (
      WidgetTester tester,
    ) async {
      await _monter(tester, rapports, _surcharges(series: demo));
      expect(_cle('bloc-mensuel'), findsOneWidget);
      expect(_cle('bloc-flux'), findsOneWidget);
      expect(find.text(g.mensuelTitre), findsOneWidget);
      expect(find.text(g.fluxTitre), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : un squelette, pas de graphique', (
      WidgetTester tester,
    ) async {
      final Completer<void> attente = Completer<void>();
      await _monter(
        tester,
        rapports,
        _surcharges(series: _SeriesFictives(attente: attente), affiches: true),
      );
      expect(_cle('graphique-dessin'), findsNothing);
      expect(find.text(g.vide), findsNothing);
      attente.complete();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_cle('graphique-dessin'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide : rien a dessiner', (WidgetTester tester) async {
      await _monter(
        tester,
        rapports,
        _surcharges(series: _SeriesFictives(vide: true)),
      );
      expect(_cle('bloc-mensuel-vide'), findsOneWidget);
      expect(find.text(g.vide), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : un message et « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        rapports,
        _surcharges(series: _SeriesFictives(echec: true)),
      );
      expect(_cle('bloc-mensuel-erreur'), findsOneWidget);
      expect(find.text(g.erreur), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hors ligne, sans donnees : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        rapports,
        _surcharges(series: _SeriesFictives(echec: true), horsLigne: true),
      );
      expect(_cle('bloc-mensuel-sans-donnees'), findsOneWidget);
      expect(find.text(g.sansDonnees), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('source absente : « en preparation », aucun chiffre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, rapports, _surcharges());
      expect(_cle('bloc-mensuel-indisponible'), findsOneWidget);
      expect(_cle('graphique-dessin'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Exports', () {
    testWidgets('sans capacite : une phrase a la place de l action', (
      WidgetTester tester,
    ) async {
      await _monter(tester, rapports, _surcharges(series: demo));
      expect(_cle('export-indisponible'), findsOneWidget);
      expect(find.text(g.exportIndisponible), findsOneWidget);
      expect(_cle('export-rapport'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('avec capacite : la reference rendue par la source', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        rapports,
        _surcharges(series: demo, export: const ExportRapportsDemo()),
      );
      await tester.tap(_cle('export-rapport'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_cle('export-resultat'), findsOneWidget);
      expect(
        find.text(g.exportPret(reference: 'EXP-DEMO-0001', lignes: 36)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('echec : une phrase qui dit quoi faire', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        rapports,
        _surcharges(series: demo, export: _ExportEchec()),
      );
      await tester.tap(_cle('export-rapport'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_cle('export-echec'), findsOneWidget);
      expect(find.text(g.exportEchec), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Navigation', () {
    test('« Rapports » est le quatrieme onglet de Tresorerie', () {
      final onglets = ongletsTresorerieComptable();
      expect(onglets, hasLength(4));
      expect(onglets.last.chemin, Routes.comptableRapports);
      expect(indexOngletTresorerie(Routes.comptableRapports), 3);
    });
  });

  group('Blocs de la tresorerie et des indicateurs', () {
    testWidgets('anneau et evolution', (WidgetTester tester) async {
      const Widget blocs = Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[BlocRepartitionCoffres(), BlocEvolution6Mois()],
          ),
        ),
      );
      await _monter(tester, blocs, _surcharges(series: demo, affiches: true));
      expect(_cle('bloc-repartition'), findsOneWidget);
      expect(_cle('bloc-evolution'), findsOneWidget);
      expect(find.byType(AnneauRepartition), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('indicateurs : mini-courbes seulement montants affiches', (
      WidgetTester tester,
    ) async {
      const Widget kpi = Scaffold(body: CarteIndicateursFlux());
      await _monter(tester, kpi, _surcharges(series: demo));
      expect(find.byType(MiniCourbe), findsNothing);
      await _monter(tester, kpi, _surcharges(series: demo, affiches: true));
      expect(find.byType(MiniCourbe), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      for (final bool affiches in <bool>[false, true]) {
        testWidgets('rapports, aucun debordement (${direction.name}, '
            '${affiches ? 'affiches' : 'masques'})', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            rapports,
            _surcharges(
              series: demo,
              export: const ExportRapportsDemo(),
              affiches: affiches,
            ),
            taille: const Size(320, 4000),
            echelle: 2,
            direction: direction,
          );
          await tester.tap(_cle('graphique-valeurs-lien').first);
          await tester.pump();
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
