// CAHIER-C3 (06/11/2026) : le cahier de confirmation. Les points a renforcer
// se choisissent parmi les objectifs de l'etape, « pret pour le petit bilan »
// se touche, et le cahier les envoie ; la page presentee dans la salle part
// avec la position.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/cahier/selecteur_reprise.dart';
import 'package:rewayah_academy/features/salle/position_reprise.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/demo_enseignant_page.dart';
import '../../support/demo/enseignant_demo.dart';
import '../../support/harnais.dart';

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('le cahier envoie objectifs a renforcer, pret pour le bilan, page', () {
    final Map<String, dynamic> json = const CahierARendre(
      seanceId: 's1',
      positionReprise: 'Page 14 du Mushaf',
      pageReprise: 14,
      decisions: <DecisionEleve>[
        DecisionEleve(
          studentId: 'e1',
          objectifsARenforcer: <String>['Lit le tanwin'],
          pretBilan: true,
        ),
        DecisionEleve(studentId: 'e2'),
      ],
    ).versJson();
    expect(json['page_reprise'], 14);
    final List<Map<String, dynamic>> eleves =
        json['eleves'] as List<Map<String, dynamic>>;
    expect(eleves.first['objectifs_a_renforcer'], <String>['Lit le tanwin']);
    expect(eleves.first['pret_bilan'], isTrue);
    // « Comme prevu » : rien de plus ne part pour l'eleve sans exception.
    expect(eleves.last.containsKey('objectifs_a_renforcer'), isFalse);
    expect(eleves.last.containsKey('pret_bilan'), isFalse);
    // Sans page confirmee, aucune cle.
    expect(
      const CahierARendre(
        seanceId: 's1',
        decisions: <DecisionEleve>[],
      ).versJson().containsKey('page_reprise'),
      isFalse,
    );
  });

  for (final bool avecObjectifs in <bool>[true, false]) {
    testWidgets('la feuille de l eleve : objectifs de l etape '
        '${avecObjectifs ? 'proposes et rendus' : 'absents, aucun bloc'}', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 3200), 1);
      final BrouillonCahier brouillon = DonneesEnseignantDemo.brouillonCahier();
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
                        objectifsEtape: avecObjectifs
                            ? const <String>['Lit le tanwin', 'Lit la chadda']
                            : const <String>[],
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
      if (!avecObjectifs) {
        expect(find.text(t.cahierC3.renforcerTitre), findsNothing);
        expect(find.text(t.cahierC3.pretBilan), findsNothing);
        return;
      }
      expect(find.text(t.cahierC3.renforcerTitre), findsOneWidget);
      await _toucher(tester, find.text('Lit la chadda'));
      await _toucher(tester, find.text(t.cahierC3.pretBilan));
      await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));
      expect(rendue, isNotNull);
      expect(rendue!.objectifsARenforcer, <String>['Lit la chadda']);
      expect(rendue!.pretBilan, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la page presentee dans la salle est proposee ; corriger rouvre '
      'le choix par sourate', (WidgetTester tester) async {
    fixerVueCapture(tester, const Size(390, 2400), 1);
    await tester.pumpWidget(
      hoteCapture(
        const CoquilleEnseignantDemo(
          ecran: EcranDemoEnseignant.cahier,
          etat: EtatDemoEnseignant.nominal,
        ),
        surcharges: <Override>[
          depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
          pageRepriseSeanceProvider.overrideWith((Ref _, String _) async => 14),
        ],
      ),
    );
    await stabiliser(tester);
    final String phrase = LibellesGroupe.insecable(
      t.cahierC3.arretPage(page: '14'),
    );
    expect(find.text(phrase), findsOneWidget);
    expect(find.byType(ChampReprise), findsNothing);
    await _toucher(tester, find.text(t.cahierC3.corriger));
    expect(find.text(phrase), findsNothing);
    // La correction rouvre le choix de la reprise : par sourate, ou au
    // clavier quand la liste des sourates est illisible (FORM-L9).
    expect(
      find.byType(ChampReprise).evaluate().length +
          find.byKey(ChampReprise.champKey).evaluate().length,
      greaterThan(0),
    );
  });
}
