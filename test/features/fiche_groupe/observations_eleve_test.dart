// NON-BRANCHE-LIVRAISON 1 (08/11/2026) : les observations du cahier
// (points a renforcer, pret pour le petit bilan), lues par
// `observations_classe` et montrees dans la fiche de l'eleve. Avant ce lot,
// aucun ecran ne les lisait : chaque test ci-dessous est ROUGE sans le
// branchement.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/fiche_groupe/observations_eleve.dart';

import '../../support/harnais.dart';

class _Port implements PortObservationsClasse {
  _Port(this.reponse);

  final Future<Map<String, ObservationsEleve>> Function() reponse;
  final List<String> lues = <String>[];

  @override
  Future<Map<String, ObservationsEleve>> observationsDeLaClasse(
    String groupeId,
  ) {
    lues.add(groupeId);
    return reponse();
  }
}

Future<void> _fiche(WidgetTester tester, _Port port) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      Scaffold(
        body: SingleChildScrollView(
          child: FicheEleveEnseignant(
            eleve: const EleveFiche(
              membre: MembreSeance(
                studentId: 'e1',
                identifiantImmuable: 'RA-26-0001',
                prenom: 'Mariam',
              ),
              classe: 'An-Nour',
              groupeId: 'c1',
            ),
            onSignaler: () {},
          ),
        ),
      ),
      surcharges: <Override>[
        portObservationsClasseProvider.overrideWithValue(port),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('lecture : seule la derniere seance de chaque eleve est gardee', () {
    final Map<String, ObservationsEleve> o = observationsDepuisReponse(
      <Object?>[
        <String, Object?>{
          'session_id': 's2',
          'student_id': 'e1',
          'nature': 'a_renforcer',
          'objectif': 'Lit le tanwin',
          'observe_le': '2026-11-06T17:00:00Z',
        },
        <String, Object?>{
          'session_id': 's2',
          'student_id': 'e1',
          'nature': 'pret_bilan',
          'objectif': null,
          'observe_le': '2026-11-06T17:00:00Z',
        },
        <String, Object?>{
          'session_id': 's1',
          'student_id': 'e1',
          'nature': 'a_renforcer',
          'objectif': 'Ancien objectif',
          'observe_le': '2026-11-01T17:00:00Z',
        },
        <String, Object?>{
          'session_id': 's1',
          'student_id': 'e2',
          'nature': 'a_renforcer',
          'objectif': 'Lit la chadda',
          'observe_le': '2026-11-01T17:00:00Z',
        },
        <String, Object?>{'student_id': 'e3', 'nature': 'pret_bilan'},
        'pas une ligne',
      ],
    );
    expect(o.keys.toSet(), <String>{'e1', 'e2'});
    expect(o['e1']!.aRenforcer, <String>['Lit le tanwin']);
    expect(o['e1']!.pretBilan, isTrue);
    expect(o['e1']!.notees, DateTime.parse('2026-11-06T17:00:00Z').toLocal());
    expect(o['e2']!.aRenforcer, <String>['Lit la chadda']);
    expect(o['e2']!.pretBilan, isFalse);
    expect(observationsDepuisReponse(null), isEmpty);
  });

  testWidgets('la fiche montre les points a renforcer, la date et le petit '
      'bilan', (WidgetTester tester) async {
    final DateTime le = DateTime(2026, 11, 6, 18);
    final _Port port = _Port(
      () async => <String, ObservationsEleve>{
        'e1': ObservationsEleve(
          studentId: 'e1',
          notees: le,
          aRenforcer: const <String>['Lit le tanwin', 'Lit la chadda'],
          pretBilan: true,
        ),
      },
    );
    await _fiche(tester, port);
    expect(port.lues, <String>['c1']);
    expect(find.byKey(BlocObservationsEleve.contenuKey), findsOneWidget);
    expect(find.text(t.cahierC3.renforcerTitre), findsOneWidget);
    final String date = LibellesGroupe.insecable(
      t.enseignant.eleve.renforcerNotees(
        numero: '6',
        mois: t.commun.dates.mois[10],
        annee: '2026',
      ),
    );
    expect(find.text('Lit le tanwin\nLit la chadda\n$date'), findsOneWidget);
    expect(find.text(t.cahierC3.pretBilan), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rien de note pour cet eleve : une ligne le dit', (
    WidgetTester tester,
  ) async {
    await _fiche(tester, _Port(() async => <String, ObservationsEleve>{}));
    expect(find.byKey(BlocObservationsEleve.videKey), findsOneWidget);
    expect(find.text(t.enseignant.eleve.renforcerAucun), findsOneWidget);
    expect(find.text(t.cahierC3.pretBilan), findsNothing);
  });

  testWidgets('echec de lecture : dit comme une panne, jamais comme vide ; '
      'la ligne relit au toucher', (WidgetTester tester) async {
    int appels = 0;
    final _Port port = _Port(() async {
      appels++;
      if (appels == 1) throw StateError('panne');
      return <String, ObservationsEleve>{};
    });
    await _fiche(tester, port);
    expect(find.byKey(BlocObservationsEleve.echecKey), findsOneWidget);
    expect(find.text(t.enseignant.eleve.renforcerIllisible), findsOneWidget);
    expect(find.text(t.enseignant.eleve.renforcerAucun), findsNothing);
    await tester.tap(find.text(t.enseignant.eleve.renforcerIllisible));
    await tester.pumpAndSettle();
    expect(appels, 2);
    expect(find.byKey(BlocObservationsEleve.videKey), findsOneWidget);
  });

  testWidgets('pendant la lecture : rien, pas de ligne vide supposee', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: BlocObservationsEleve(groupeId: 'c1', studentId: 'e1'),
        ),
        surcharges: <Override>[
          portObservationsClasseProvider.overrideWithValue(
            _Port(
              () => Future<Map<String, ObservationsEleve>>.delayed(
                const Duration(seconds: 1),
                () => <String, ObservationsEleve>{},
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    expect(find.byKey(BlocObservationsEleve.videKey), findsNothing);
    expect(find.byKey(BlocObservationsEleve.echecKey), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(BlocObservationsEleve.videKey), findsOneWidget);
  });

  test("l'application reelle lit le serveur, jamais le port absent", () {
    final String main = File('lib/main.dart').readAsStringSync();
    expect(
      main,
      contains(
        'portObservationsClasseProvider.overrideWithValue(\n'
        '    ObservationsClasseSupabase(Supabase.instance.client),',
      ),
    );
  });
}
