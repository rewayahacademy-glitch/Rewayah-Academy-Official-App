// SOURATES (directeur, 11/11/2026, option A) : l'enseignant coche la sourate
// au cahier. Les 17 sourates et leur ordre viennent du serveur ; seules celles
// pas encore validees se proposent ; le cahier envoie les numeros cochees ; le
// suivi lit le compte rendu par le serveur, jamais un 0 invente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/suivi/port_suivi_pedagogique.dart';
import 'package:rewayah_academy/core/suivi/suivi_pedagogique_supabase.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/fiche_groupe/sourates_classe.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/demo/enseignant_demo.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Trois des 17 sourates, comme le serveur les rend : Al-Fatiha deja
/// validee, An-Nas et Al-Falaq a valider.
const List<SourateBases> _sourates = <SourateBases>[
  SourateBases(ordre: 1, numero: 1, nom: 'Al-Fatiha', validee: true),
  SourateBases(ordre: 2, numero: 114, nom: 'An-Nas', validee: false),
  SourateBases(ordre: 3, numero: 113, nom: 'Al-Falaq', validee: false),
];

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('lecture', () {
    test('sourates de la classe : par eleve, dans l ordre d etude', () {
      final Map<String, List<SourateBases>> lu = souratesDepuisReponse(
        <Object?>[
          <String, Object?>{
            'student_id': 'e1',
            'ordre': 2,
            'numero': 114,
            'nom': 'An-Nas',
            'validee': false,
          },
          <String, Object?>{
            'student_id': 'e1',
            'ordre': 1,
            'numero': 1,
            'nom': 'Al-Fatiha',
            'validee': true,
          },
          <String, Object?>{'student_id': 'e2', 'ordre': 'x'},
          'illisible',
        ],
      );
      expect(lu.keys, <String>['e1']);
      expect(lu['e1']!.map((SourateBases s) => s.numero), <int>[1, 114]);
      expect(lu['e1']!.first.validee, isTrue);
      expect(souratesDepuisReponse(null), isEmpty);
    });

    test('suivi : le compte du serveur, nul s il manque ou s il est '
        'incoherent', () {
      final SuiviPedagogique? avec = SuiviPedagogique.depuisJson(
        <String, Object?>{
          'etape_nom': 'Les sourates courtes',
          'sourates_validees': 3,
          'sourates_total': 17,
        },
      );
      expect(avec!.sourates!.validees, 3);
      expect(avec.sourates!.total, 17);
      expect(avec.sourates!.toutes, isFalse);
      final SuiviPedagogique? sans = SuiviPedagogique.depuisJson(
        <String, Object?>{'etape_nom': 'Lire avec les voyelles'},
      );
      expect(sans!.sourates, isNull);
      expect(SouratesValidees.depuis(18, 17), isNull);
      expect(SouratesValidees.depuis(1, 0), isNull);
      expect(SouratesValidees.depuis(17, 17)!.toutes, isTrue);
    });
  });

  test('suivi : sourates_eleve complete la ligne ; sans elle, le suivi '
      'reste lisible sans sourates', () {
    final Object? fusion = avecSourates(
      <Object?>[
        <String, Object?>{'etape_nom': 'Les sourates courtes'},
      ],
      <String, Object?>{'sourates_validees': 4, 'sourates_total': 17},
    );
    final SuiviPedagogique? lu = SuiviPedagogique.depuisJson(fusion);
    expect(lu!.sourates!.validees, 4);
    final SuiviPedagogique? sans = SuiviPedagogique.depuisJson(
      avecSourates(<String, Object?>{'etape_nom': 'Lire'}, null),
    );
    expect(sans!.etapeNom, 'Lire');
    expect(sans.sourates, isNull);
  });

  test('le cahier envoie les sourates cochees, triees ; rien sans '
      'sourate', () {
    final Map<String, dynamic> json = const CahierARendre(
      seanceId: 's1',
      decisions: <DecisionEleve>[
        DecisionEleve(studentId: 'e1', souratesValidees: <int>{114, 1}),
        DecisionEleve(studentId: 'e2'),
      ],
    ).versJson();
    final List<Map<String, dynamic>> eleves =
        json['eleves'] as List<Map<String, dynamic>>;
    expect(eleves.first['sourates_validees'], <int>[1, 114]);
    expect(eleves.last.containsKey('sourates_validees'), isFalse);
  });

  for (final bool avecSourates in <bool>[true, false]) {
    testWidgets(
      'la feuille de l eleve : sourates '
      '${avecSourates ? 'a valider proposees et rendues' : 'absentes, aucun bloc'}',
      (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(390, 3600), 1);
        final BrouillonCahier brouillon =
            DonneesEnseignantDemo.brouillonCahier();
        final ParticipantBrouillon nour = brouillon.participants.first;
        DecisionEleve? rendue;
        await tester.pumpWidget(
          hoteCapture(
            Builder(
              builder: (BuildContext context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      rendue = await AppBottomSheet.ouvrir<DecisionEleve>(
                        context,
                        titre: t.enseignant.cahier.ajusterPour(eleve: 'Nour'),
                        constructeur: (BuildContext _) => FeuilleAjusterCahier(
                          participant: nour,
                          brouillon: brouillon,
                          decision: DecisionEleve(
                            studentId: nour.membre.studentId,
                          ),
                          sourates: avecSourates
                              ? _sourates
                              : const <SourateBases>[],
                        ),
                      );
                    },
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await _toucher(tester, find.text('ouvrir'));
        if (!avecSourates) {
          expect(find.text(t.cahierSourates.titre), findsNothing);
          return;
        }
        expect(find.text(t.cahierSourates.titre), findsOneWidget);
        expect(
          find.text(t.cahierSourates.dejaValidees(n: '1', total: '3')),
          findsOneWidget,
        );
        // Une sourate deja validee ne se propose plus.
        expect(find.text('Al-Fatiha'), findsNothing);
        // Les noms restent entiers, a cote de leur case (aucun mot coupe).
        expect(
          motsCoupes(
            tester,
            find.byKey(const ValueKey<String>('cahier-sourates-0')),
          ),
          isEmpty,
        );
        await _toucher(
          tester,
          find.byKey(const ValueKey<String>('cahier-sourate-113')),
        );
        await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));
        expect(rendue, isNotNull);
        expect(rendue!.souratesValidees, <int>{113});
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('toutes validees : la phrase le dit, aucune case', (
    WidgetTester tester,
  ) async {
    fixerVueCapture(tester, const Size(390, 3600), 1);
    final BrouillonCahier brouillon = DonneesEnseignantDemo.brouillonCahier();
    final ParticipantBrouillon nour = brouillon.participants.first;
    await tester.pumpWidget(
      hoteCapture(
        Scaffold(
          body: SingleChildScrollView(
            child: FeuilleAjusterCahier(
              participant: nour,
              brouillon: brouillon,
              decision: DecisionEleve(studentId: nour.membre.studentId),
              sourates: const <SourateBases>[
                SourateBases(
                  ordre: 1,
                  numero: 1,
                  nom: 'Al-Fatiha',
                  validee: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.cahierSourates.toutes), findsOneWidget);
    expect(find.text(t.cahierSourates.aide), findsNothing);
  });
}
