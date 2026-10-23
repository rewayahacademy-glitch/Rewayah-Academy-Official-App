// BOUTONS-GRISES-1 : « Enregistrer le resultat » n'est jamais grise. Sans
// resultat choisi, l'appui le dit, l'annonce au lecteur d'ecran et rend le
// focus a la premiere valeur du resultat.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';

import '../../support/annonces.dart';
import '../../support/harnais.dart';
import '../support_form_l2.dart';

class _AvecUneEvaluation extends FauxEvaluationsFormL2 {
  final List<ResultatEvaluation> resultats = <ResultatEvaluation>[];

  @override
  Future<List<EvaluationAdmin>> toutes() async => <EvaluationAdmin>[
    EvaluationAdmin(
      id: 'ev1',
      studentId: 'e-mariam',
      identifiant: 'ELV-001',
      prenom: 'Mariam',
      nom: null,
      niveauId: 'n1',
      niveauNomHumain: 'Fondations de lecture',
      type: TypeEvaluation.initiale,
      statut: StatutEvaluation.planifiee,
      datePrevue: DateTime(2026, 10, 12),
      dateRealisee: null,
      resultat: null,
      notes: null,
    ),
  ];

  @override
  Future<void> enregistrerResultat({
    required String evaluationId,
    required ResultatEvaluation resultat,
    String? notes,
  }) async => resultats.add(resultat);
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans resultat : actif, dit ce qui manque, annonce, focus', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final List<String> annonces = ecouterAnnonces(tester);
    final _AvecUneEvaluation evaluations = _AvecUneEvaluation();
    await tester.pumpWidget(
      hote(
        const EvaluationsPage(),
        surcharges: surchargesFormL2(
          comptes: FauxComptesFormL2(comptesFormL2),
          evaluations: evaluations,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _presser(
      tester,
      find.byWidgetPredicate(
        (Widget w) => w is MenuActions && w.objet == 'Mariam',
      ),
    );
    await _presser(
      tester,
      find.text(t.admin.evaluations.actionEnregistrerResultat).last,
    );

    final Finder envoyer = find.widgetWithText(
      ActionPrincipale,
      t.admin.evaluations.resultatEnvoyer,
    );
    expect(tester.widget<ActionPrincipale>(envoyer).onPress, isNotNull);
    await _presser(tester, envoyer);

    expect(evaluations.resultats, isEmpty);
    expect(find.text(t.admin.evaluations.manqueResultat), findsOneWidget);
    expect(annonces, <String>[t.admin.evaluations.manqueResultat]);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'resultat');

    await _presser(tester, find.text(t.admin.evaluations.resultatReussi).last);
    expect(find.text(t.admin.evaluations.manqueResultat), findsNothing);
    await _presser(tester, envoyer);
    expect(evaluations.resultats, <ResultatEvaluation>[
      ResultatEvaluation.reussi,
    ]);
  });
}
