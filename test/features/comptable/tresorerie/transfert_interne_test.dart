// CPT-TRES-2 : mouvements entre coffres (`TreasuryInternalTransfer`, spec
// §9.5, §10 ; DR-15). Confirmation explicite avant tout envoi, montant
// propose et modifiable (K-57), retrait de la Reserve = demande de
// validation jamais execution directe, retrait sans capacite bloque
// (R-FIN-10), interdits §10.4 jamais proposes, etat du port seulement (aucun
// faux succes, §5.3), meme cle d'idempotence pour la nouvelle tentative.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_tresorerie.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/pastilles_comptable.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/transfert/transfert_interne.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/tresorerie_page.dart';

import 'faux_tresorerie.dart';

Future<void> _stable(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pump();
  await tester.tap(cible);
  await _stable(tester);
}

void main() {
  final tr = t.comptable.tresorerie;
  final tt = tr.transfert;

  testWidgets('Alimenter : choisir, verifier le montant exact, puis envoyer '
      'une fois ; resultat rendu par le port', (WidgetTester tester) async {
    final FausseTresorerie port = FausseTresorerie();
    await monterTresorerie(tester, tresorerie: port);
    await _toucher(tester, find.byKey(TresoreriePage.cleAlimenter));

    // Un seul couple vers la Reserve : deja choisi. Montants masques : le
    // champ reste vide, la proposition se reprend d'un geste.
    expect(find.text(tt.montantPropose), findsOneWidget);
    final Finder champ = find.byKey(TransfertInterne.cleMontant);
    expect(tester.widget<TextField>(champ).controller!.text, isEmpty);
    await _toucher(tester, find.text(tt.utiliserPropose));
    expect(tester.widget<TextField>(champ).controller!.text, '600');

    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    // Confirmation explicite : le montant exact, rien n'est encore parti.
    expect(port.appels, isEmpty);
    expect(find.text(tt.recapPhrase), findsOneWidget);
    expect(find.text(formaterMontant(usd(600))), findsOneWidget);
    expect(find.text(tt.delegable), findsOneWidget);
    expect(find.text(tt.confirmer), findsOneWidget);

    await _toucher(tester, find.byKey(TransfertInterne.cleEnvoyer));
    expect(port.appels, hasLength(1));
    expect(port.appels.single.origine, Coffre.tresorerieLibre);
    expect(port.appels.single.destination, Coffre.reserveStrategique);
    expect(port.appels.single.montant, usd(600));
    expect(port.appels.single.cle, isNotEmpty);
    expect(find.text(tt.executeTitre), findsOneWidget);
    expect(find.text(tt.reference(reference: 'MVT-42')), findsOneWidget);
    expect(find.textContaining('Réussi'), findsNothing);
  });

  testWidgets('montants affiches : le montant propose est prerempli, '
      'modifiable', (WidgetTester tester) async {
    final FausseTresorerie port = FausseTresorerie();
    await monterTresorerie(tester, tresorerie: port, montantsAffiches: true);
    await _toucher(tester, find.byKey(TresoreriePage.cleAlimenter));
    final Finder champ = find.byKey(TransfertInterne.cleMontant);
    expect(tester.widget<TextField>(champ).controller!.text, '600');
    await tester.enterText(champ, '750');
    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    await _toucher(tester, find.byKey(TransfertInterne.cleEnvoyer));
    expect(port.appels.single.montant, usd(750));
  });

  testWidgets('montant vide ou nul : erreur, aucune verification', (
    WidgetTester tester,
  ) async {
    final FausseTresorerie port = FausseTresorerie();
    await monterTresorerie(tester, tresorerie: port);
    await _toucher(tester, find.byKey(TresoreriePage.cleAlimenter));
    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    expect(find.text(tt.erreurMontant), findsOneWidget);
    await tester.enterText(find.byKey(TransfertInterne.cleMontant), '0');
    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    expect(find.text(tt.erreurMontant), findsOneWidget);
    expect(find.text(tt.recapPhrase), findsNothing);
    expect(port.appels, isEmpty);
  });

  testWidgets('retrait de la Reserve permis : toujours une demande de '
      'validation, meme si la source le dit delegable', (
    WidgetTester tester,
  ) async {
    final FausseTresorerie port = FausseTresorerie()
      ..bloques = const <MouvementBloque>[]
      ..permis = const <MouvementPermis>[
        MouvementPermis(
          origine: Coffre.reserveStrategique,
          destination: Coffre.tresorerieLibre,
          sensible: false,
        ),
      ]
      ..reponse = (AppelTransfert a) => const ResultatMouvement(
        mouvementId: 'm-2',
        execute: false,
        validation: EtatDemandeValidation.enAttente,
      );
    await monterTresorerie(tester, tresorerie: port);
    await _toucher(tester, find.byKey(TresoreriePage.cleRetirer));
    expect(find.text(tt.sensible), findsWidgets);
    await tester.enterText(find.byKey(TransfertInterne.cleMontant), '200');
    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    expect(find.text(tt.demanderValidation), findsOneWidget);
    expect(find.text(tt.confirmer), findsNothing);
    await _toucher(tester, find.byKey(TransfertInterne.cleEnvoyer));
    expect(port.appels, hasLength(1));
    expect(find.text(tt.validationTitre), findsWidgets);
    expect(find.text(tt.validationPhrase), findsOneWidget);
    expect(find.text(tt.executeTitre), findsNothing);
  });

  testWidgets('interdits §10.4 : Fonds clients et Taxes vers Libre ne sont '
      'jamais proposes ; le retrait refuse apparait avec sa raison', (
    WidgetTester tester,
  ) async {
    final FausseTresorerie port = FausseTresorerie()
      ..permis = const <MouvementPermis>[
        MouvementPermis(
          origine: Coffre.fondsClientsEngages,
          destination: Coffre.tresorerieLibre,
          sensible: true,
        ),
        MouvementPermis(
          origine: Coffre.taxesObligations,
          destination: Coffre.tresorerieLibre,
          sensible: true,
        ),
        MouvementPermis(
          origine: Coffre.tresorerieLibre,
          destination: Coffre.chargesEssentielles,
          sensible: false,
        ),
      ];
    await monterTresorerie(tester, tresorerie: port);
    await _toucher(tester, find.byKey(TresoreriePage.clePreparer));
    expect(
      find.byKey(
        TransfertInterne.cleCouple(
          Coffre.fondsClientsEngages,
          Coffre.tresorerieLibre,
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        TransfertInterne.cleCouple(
          Coffre.taxesObligations,
          Coffre.tresorerieLibre,
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        TransfertInterne.cleCouple(
          Coffre.tresorerieLibre,
          Coffre.chargesEssentielles,
        ),
      ),
      findsOneWidget,
    );
    // R-FIN-10 dans la feuille : visible, raison ecrite, jamais pressable.
    final Finder retrait = find.byKey(
      TransfertInterne.cleCouple(
        Coffre.reserveStrategique,
        Coffre.tresorerieLibre,
      ),
    );
    expect(retrait, findsOneWidget);
    expect(
      find.text(libelleRaisonBlocage(RaisonBlocage.capaciteAbsente)),
      findsOneWidget,
    );
    await _toucher(tester, retrait);
    expect(port.appels, isEmpty);
  });

  testWidgets('refus de la source : raison ecrite, aucun succes', (
    WidgetTester tester,
  ) async {
    final FausseTresorerie port = FausseTresorerie()
      ..reponse = (AppelTransfert a) => const ResultatMouvement(
        mouvementId: 'm-3',
        execute: false,
        refus: RaisonBlocage.fondsInsuffisants,
      );
    await monterTresorerie(tester, tresorerie: port);
    await _toucher(tester, find.byKey(TresoreriePage.cleAlimenter));
    await tester.enterText(find.byKey(TransfertInterne.cleMontant), '50');
    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    await _toucher(tester, find.byKey(TransfertInterne.cleEnvoyer));
    expect(find.text(tt.refusTitre), findsOneWidget);
    expect(
      find.text(
        tt.refusPhrase(
          raison: libelleRaisonBlocage(RaisonBlocage.fondsInsuffisants),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(tt.executeTitre), findsNothing);
  });

  testWidgets('reponse perdue : Reessayer renvoie la meme cle '
      'd idempotence', (WidgetTester tester) async {
    final FausseTresorerie port = FausseTresorerie();
    final reussite = port.reponse;
    port.reponse = (AppelTransfert a) => throw StateError('coupure');
    await monterTresorerie(tester, tresorerie: port);
    await _toucher(tester, find.byKey(TresoreriePage.cleAlimenter));
    await tester.enterText(find.byKey(TransfertInterne.cleMontant), '80');
    await _toucher(tester, find.byKey(TransfertInterne.cleVerifier));
    await _toucher(tester, find.byKey(TransfertInterne.cleEnvoyer));
    expect(find.text(tt.erreurEnvoiTitre), findsOneWidget);
    expect(find.text(tt.executeTitre), findsNothing);
    port.reponse = reussite;
    await _toucher(tester, find.text(t.commun.reessayer));
    expect(port.appels, hasLength(2));
    expect(port.appels[1].cle, port.appels[0].cle);
    expect(find.text(tt.executeTitre), findsOneWidget);
  });

  testWidgets('?action=alimenter ouvre « Alimenter » a l arrivee', (
    WidgetTester tester,
  ) async {
    await monterTresorerie(
      tester,
      tresorerie: FausseTresorerie(),
      action: Routes.actionAlimenterReserve,
    );
    await _stable(tester);
    expect(find.byType(TransfertInterne), findsOneWidget);
    expect(find.text(tt.montantPropose), findsOneWidget);
  });

  testWidgets('bureau : la feuille devient une boite de dialogue', (
    WidgetTester tester,
  ) async {
    await monterTresorerie(
      tester,
      tresorerie: FausseTresorerie(),
      taille: const Size(1440, 1600),
    );
    await _toucher(tester, find.byKey(TresoreriePage.cleAlimenter));
    expect(
      tester.widget<AppBottomSheet>(find.byType(AppBottomSheet)).forme,
      FormeModale.dialogue,
    );
    expect(find.byType(TransfertInterne), findsOneWidget);
  });
}
