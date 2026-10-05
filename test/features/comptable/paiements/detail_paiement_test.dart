// CPT-PAY-1 : le detail W03. Lignes de calcul avec leur source (§13.3),
// montant en lecture seule (R-FIN-16), « Signaler un ecart » sans champ de
// correction (R-FIN-17) et idempotent, encart permanent §31, alertes,
// auto-payout (R-FIN-15), telephone a 320 et texte double.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/signaler_ecart.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';

import 'support_paiements.dart';

void main() {
  final p = t.comptable.paiements;
  const Size bureau = Size(1440, 1600);

  testWidgets('Diallo : les quatre lignes de §13.3, chacune avec sa source, '
      'le total, aucun champ (R-FIN-16)', (WidgetTester tester) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(
        obligationId: SocleComptableDemo.obligationDiallo,
      ),
      surcharges: surchargesDemo(EtatDemoPaiements()),
      taille: bureau,
    );
    for (final String libelle in <String>[
      'Classe Al-Fajr',
      'Classe An-Nour',
      'Remplacement',
      'Bonus approuvé',
    ]) {
      expect(find.text(libelle), findsOneWidget, reason: libelle);
    }
    expect(
      find.text(p.detail.source(source: 'Bonus Internet de septembre')),
      findsOneWidget,
    );
    expect(
      find.text(p.detail.auteur(auteur: 'Direction pédagogique')),
      findsOneWidget,
    );
    expect(find.text(p.detail.ligneTotal), findsOneWidget);
    // Total, total de la carte et quatre lignes : tout est masque.
    expect(find.text(MontantSensible.masquePour('USD')), findsNWidgets(6));
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(DetailPaiementPage.cleEncart), findsOneWidget);
    expect(find.text(p.detail.encart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signaler un ecart : ligne et motif choisis, aucune saisie '
      '(R-FIN-17), un seul signalement par feuille', (
    WidgetTester tester,
  ) async {
    final EtatDemoPaiements etat = EtatDemoPaiements();
    await monterPaiements(
      tester,
      const DetailPaiementPage(
        obligationId: SocleComptableDemo.obligationDiallo,
      ),
      surcharges: surchargesDemo(etat),
      taille: bureau,
    );
    await tester.tap(find.byKey(DetailPaiementPage.cleSignaler));
    await tester.pumpAndSettle();
    expect(find.byType(FeuilleSignalerEcart), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsNothing);
    await tester.tap(find.text(p.ecart.motifs.ligneManquante));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FeuilleSignalerEcart.cleEnvoyer));
    await tester.pumpAndSettle();
    expect(find.byType(FeuilleSignalerEcart), findsNothing);
    expect(etat.signalements, hasLength(1));
    expect(
      find.text(p.ecart.envoye(date: '4 ${t.commun.dates.mois[9]} 2026')),
      findsOneWidget,
    );
    // Le montant n'a pas bouge : il reste celui de la source.
    expect(
      etat.obligations[SocleComptableDemo.obligationDiallo]!.montant,
      SocleComptableDemo.usd(212),
    );
  });

  testWidgets('un signalement refuse : la feuille reste ouverte et dit quoi '
      'faire', (WidgetTester tester) async {
    final EtatDemoPaiements etat = EtatDemoPaiements();
    final ObligationsPilotees port = ObligationsPilotees(
      rendues: etat.obligations.values.toList(),
    );
    await monterPaiements(
      tester,
      const DetailPaiementPage(
        obligationId: SocleComptableDemo.obligationDiallo,
      ),
      surcharges: <Override>[
        portObligationsPayablesProvider.overrideWithValue(port),
        ...surchargesCommunes(),
      ],
      taille: bureau,
    );
    await tester.tap(find.byKey(DetailPaiementPage.cleSignaler));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FeuilleSignalerEcart.cleEnvoyer));
    await tester.pumpAndSettle();
    expect(find.byType(FeuilleSignalerEcart), findsOneWidget);
    expect(find.text(p.ecart.erreurEnvoi), findsOneWidget);
  });

  testWidgets('le Comptable beneficiaire : la raison rendue, aucun Payer '
      '(R-FIN-15)', (WidgetTester tester) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(obligationId: PaiementsDemo.obligationComptable),
      surcharges: surchargesDemo(EtatDemoPaiements()),
      taille: bureau,
    );
    expect(find.text(t.comptable.statuts.raison.autoPaiement), findsOneWidget);
    expect(find.text(p.detail.autoPaiementPhrase), findsOneWidget);
    expect(find.text(p.actions.payer), findsNothing);
    // L'auto-payout ne se signale pas non plus : la source ne le permet pas.
    expect(find.byKey(DetailPaiementPage.cleSignaler), findsNothing);
  });

  testWidgets('methode modifiee recemment : validation supplementaire, la '
      'date rendue (R-FIN-14)', (WidgetTester tester) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(
        obligationId: PaiementsDemo.obligationMethodeRecente,
      ),
      surcharges: surchargesDemo(EtatDemoPaiements()),
      taille: bureau,
    );
    expect(
      find.text(
        p.detail.alerteMethodeRecente(date: '2 ${t.commun.dates.mois[9]} 2026'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('payout echoue : alerte et historique du prestataire', (
    WidgetTester tester,
  ) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(obligationId: PaiementsDemo.obligationEchouee),
      surcharges: surchargesDemo(EtatDemoPaiements()),
      taille: bureau,
    );
    expect(find.text(p.detail.alerteEchec), findsOneWidget);
    expect(find.text('Payout de septembre'), findsOneWidget);
  });

  testWidgets('infos manquantes : alerte et lien vers le profil (W07)', (
    WidgetTester tester,
  ) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(
        obligationId: PaiementsDemo.obligationInfosManquantes,
      ),
      surcharges: surchargesDemo(EtatDemoPaiements()),
      taille: bureau,
    );
    expect(find.text(p.detail.alerteInfos), findsOneWidget);
    expect(find.text(t.comptable.commun.destinationAucune), findsOneWidget);
    await tester.tap(find.text(p.actions.voirProfil));
    await tester.pumpAndSettle();
    expect(find.text('profil ens-11'), findsOneWidget);
  });

  testWidgets('telephone 320, texte double : une colonne, rien ne deborde', (
    WidgetTester tester,
  ) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(
        obligationId: SocleComptableDemo.obligationDiallo,
      ),
      surcharges: surchargesDemo(EtatDemoPaiements()),
      taille: const Size(320, 640),
      texte: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Sayyid Youssouf Diallo'), findsOneWidget);
  });

  testWidgets('sans source : « en preparation »', (WidgetTester tester) async {
    await monterPaiements(
      tester,
      const DetailPaiementPage(obligationId: 'o1'),
      surcharges: <Override>[
        portObligationsPayablesProvider.overrideWithValue(
          ObligationsPilotees(erreur: const CapaciteIndisponible('CPT-BR-01')),
        ),
        ...surchargesCommunes(),
      ],
    );
    expect(find.byType(EmptyState), findsOneWidget);
  });
}
