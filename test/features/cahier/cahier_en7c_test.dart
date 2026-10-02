// EN-7c : l'evaluation par eleve du cahier (N1 du directeur, 27/09), tapee
// depuis la vraie coquille enseignant : echelle de performance a choix
// unique, faiblesses a choix multiple, preremplies depuis la seance
// precedente ; « Ajustez la suggestion » absente quand le devoir est vide ;
// l'identifiant de l'eleve une seule fois dans la feuille.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester) async {
  fixerVueCapture(tester, const Size(390, 2400), 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Set<String> _retenues(WidgetTester tester, String cle) => tester
    .widget<ChoiceCardGroup>(
      find.descendant(of: _cle(cle), matching: find.byType(ChoiceCardGroup)),
    )
    .valeurInitiale!
    .valeurs;

void main() {
  testWidgets('niveau et faiblesse choisis, prerempli, puis valide', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _toucher(tester, find.text('Nour'));

    // Les mots du directeur, tels quels.
    for (final String mot in <String>[
      'À revoir',
      'En progrès',
      'Acquis',
      'Maîtrisé',
      'Makharij',
      'Madd',
      'Ghunna',
      'Waqf',
      'Fluidité',
      'Mémorisation',
    ]) {
      expect(find.text(mot), findsOneWidget, reason: mot);
    }

    // Prerempli depuis la seance precedente.
    expect(_retenues(tester, 'cahier-emplacement-performance'), <String>{
      'enProgres',
    });
    expect(_retenues(tester, 'cahier-emplacement-faiblesses'), <String>{
      'madd',
    });

    // Le devoir est vide : pas de « suggestion » a ajuster.
    expect(find.text(t.enseignant.cahier.travailMaisonDetail), findsNothing);
    expect(_cle('cahier-devoir-suggestion'), findsNothing);

    // L'identifiant de l'eleve, une seule fois.
    expect(find.text('RA-NOUR'), findsOneWidget);

    await _toucher(tester, _cle('cahier-performance-acquis'));
    await _toucher(tester, _cle('cahier-faiblesse-waqf'));
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));

    // Le niveau retenu se relit sur la ligne avant de valider.
    expect(find.text(t.enseignant.cahier.niveauAcquis), findsOneWidget);

    // Rouverte, la feuille garde le choix.
    await _toucher(tester, find.text('Nour'));
    expect(_retenues(tester, 'cahier-emplacement-performance'), <String>{
      'acquis',
    });
    expect(_retenues(tester, 'cahier-emplacement-faiblesses'), <String>{
      'madd',
      'waqf',
    });
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));

    await _toucher(tester, _cle('cahier-valider'));
    expect(find.text(t.enseignant.cahier.depose), findsOneWidget);
  });

  test('l echec reseau ne dit jamais « n a pas ete envoye » (D5)', () {
    expect(
      t.enseignant.cahier.echecEnvoi,
      "L'envoi n'a pas été confirmé. Vérifiez avant de réessayer.",
    );
  });

  test('la decision preremplie part avec performance et faiblesses', () {
    final ParticipantBrouillon nour =
        DonneesEnseignantDemo.brouillonCahier().participants.first;
    final Map<String, dynamic> json = DecisionEleve.preremplie(nour).versJson();
    expect(json['performance'], 'enProgres');
    expect(json['faiblesses'], <String>['madd']);
  });
}
