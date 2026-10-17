// CPT-PAY-2 : la confirmation d'un payout (`PayoutConfirmationSheet`).
// Montant exact meme masque (R-FIN-04), preflight obligatoire, seuls les
// prets partent et les exclus sont dits (R-FIN-22, 23), paiement sensible :
// « Demander validation » (R-FIN-14), auto-payout sans « Payer » (R-FIN-15),
// idempotence (double appui, reponse perdue), recalcul pendant la
// confirmation (R-FIN-18, DR-13), jamais « Reussi » sur simple appui (§5.3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_capacite_payout.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/capacites/port_payout.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/pastilles_comptable.dart';
import 'package:rewayah_academy/features/comptable/paiements/barre_selection.dart';
import 'package:rewayah_academy/features/comptable/paiements/confirmation/confirmation_payout.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/ligne_obligation.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/validations_demo.dart';

import 'support_paiements.dart';

/// Un payout dont la premiere reponse se perd apres l'envoi : la source a
/// accepte, l'app ne le sait pas.
class PayoutReponsePerdue extends PayoutDemo {
  PayoutReponsePerdue(super.etat);

  int appels = 0;
  final Set<String> cles = <String>{};

  @override
  Future<List<SuiviPayout>> soumettre({
    required String preflightId,
    required String cleIdempotence,
  }) async {
    appels++;
    cles.add(cleIdempotence);
    final List<SuiviPayout> r = await super.soumettre(
      preflightId: preflightId,
      cleIdempotence: cleIdempotence,
    );
    if (appels == 1) throw StateError('reponse perdue');
    return r;
  }
}

void main() {
  // Le registre unique des validations de la demonstration (CPT-VAL-1)
  // repart de l'etat de depart a chaque test.
  setUp(RegistreValidationsDemo.instance.reinitialiser);

  final p = t.comptable.paiements;
  final c = p.confirmation;
  const Size telephone = Size(390, 1600);

  Future<void> ouvrirDetail(
    WidgetTester tester,
    EtatDemoPaiements etat,
    String id, {
    bool horsLigne = false,
    PortPayout? payout,
  }) async {
    await monterPaiements(
      tester,
      DetailPaiementPage(obligationId: id),
      surcharges: payout == null
          ? surchargesDemo(etat, horsLigne: horsLigne)
          : <Override>[
              portObligationsPayablesProvider.overrideWithValue(
                ObligationsPayablesDemo(etat),
              ),
              portPayoutProvider.overrideWithValue(payout),
              ...surchargesCommunes(horsLigne: horsLigne),
            ],
      taille: telephone,
    );
  }

  Future<void> appuyer(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  group('un paiement seul (§7.5, §40)', () {
    testWidgets('R-FIN-04 : montants masques partout, la feuille montre le '
        'montant exact et le bouton le dit', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await ouvrirDetail(tester, etat, SocleComptableDemo.obligationDiallo);
      final String exact = formaterMontant(
        etat.obligations[SocleComptableDemo.obligationDiallo]!.montant,
      );
      // Le detail masque le montant.
      expect(find.text(exact), findsNothing);
      expect(find.text(MontantSensible.masquePour('USD')), findsWidgets);
      await appuyer(tester, find.text(c.payerMaintenant));
      final Finder feuille = find.byType(PayoutConfirmationSheet);
      expect(feuille, findsOneWidget);
      expect(
        find.descendant(of: feuille, matching: find.text(exact)),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: feuille,
          matching: find.text(MontantSensible.masquePour('USD')),
        ),
        findsNothing,
      );
      expect(find.text(c.confirmerUn(montant: exact)), findsOneWidget);
      // Beneficiaire, destination masquee, prestataire, frais connus.
      expect(
        find.descendant(of: feuille, matching: find.text(c.beneficiaire)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: feuille, matching: find.text(c.prestataire)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: feuille, matching: find.text(c.frais)),
        findsOneWidget,
      );
      expect(etat.envoisAcceptes, 0, reason: 'rien ne part sans confirmer');
    });

    testWidgets('un double appui n\'envoie qu\'une fois ; le suivi vient du '
        'prestataire, jamais « Reussi » sur simple appui (§5.3)', (
      WidgetTester tester,
    ) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await ouvrirDetail(tester, etat, SocleComptableDemo.obligationDiallo);
      await appuyer(tester, find.text(c.payerMaintenant));
      final Finder confirmer = find.byKey(PayoutConfirmationSheet.cleConfirmer);
      await tester.ensureVisible(confirmer);
      await tester.pumpAndSettle();
      await tester.tap(confirmer);
      await tester.tap(confirmer, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(etat.envoisAcceptes, 1);
      expect(find.text(c.soumisTitre), findsOneWidget);
      expect(
        find.text(libellePaiementSortant(EtatPaiementSortant.soumis)),
        findsWidgets,
      );
      final Finder feuille = find.byType(PayoutConfirmationSheet);
      expect(
        find.descendant(
          of: feuille,
          matching: find.text(
            libellePaiementSortant(EtatPaiementSortant.reussi),
          ),
        ),
        findsNothing,
      );
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleActualiser));
      expect(
        find.descendant(
          of: feuille,
          matching: find.text(
            libellePaiementSortant(EtatPaiementSortant.enTransit),
          ),
        ),
        findsOneWidget,
      );
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleActualiser));
      expect(
        find.descendant(
          of: feuille,
          matching: find.text(
            libellePaiementSortant(EtatPaiementSortant.reussi),
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(PayoutConfirmationSheet.cleActualiser), findsNothing);
      expect(etat.envoisAcceptes, 1);
    });

    testWidgets('reponse perdue : « Issue inconnue », Reessayer rejoue la '
        'meme cle et rien ne part deux fois', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      final PayoutReponsePerdue payout = PayoutReponsePerdue(etat);
      await ouvrirDetail(
        tester,
        etat,
        SocleComptableDemo.obligationDiallo,
        payout: payout,
      );
      await appuyer(tester, find.text(c.payerMaintenant));
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleConfirmer));
      expect(find.text(c.inconnuTitre), findsOneWidget);
      expect(find.text(c.soumisTitre), findsNothing);
      expect(etat.envoisAcceptes, 1);
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleReessayer));
      expect(payout.appels, 2);
      expect(payout.cles, hasLength(1), reason: 'la meme cle est rejouee');
      expect(etat.envoisAcceptes, 1, reason: 'aucun second envoi');
      expect(find.text(c.soumisTitre), findsOneWidget);
    });

    testWidgets('R-FIN-18 / DR-13 : recalcul pendant la confirmation, rien '
        'ne part, le nouveau montant est montre puis confirme', (
      WidgetTester tester,
    ) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      const String id = PaiementsDemo.obligationRecalculee;
      final String ancien = formaterMontant(etat.obligations[id]!.montant);
      await ouvrirDetail(tester, etat, id);
      await appuyer(tester, find.text(c.payerMaintenant));
      expect(find.text(c.confirmerUn(montant: ancien)), findsOneWidget);
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleConfirmer));
      expect(find.text(c.recalculeTitre), findsOneWidget);
      expect(etat.envoisAcceptes, 0);
      final String nouveau = formaterMontant(etat.obligations[id]!.montant);
      expect(nouveau, isNot(ancien));
      expect(find.text(nouveau), findsWidgets);
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleRelancer));
      expect(find.text(c.confirmerUn(montant: nouveau)), findsOneWidget);
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleConfirmer));
      expect(etat.envoisAcceptes, 1);
      expect(etat.suivis.values.single.montant, etat.obligations[id]!.montant);
    });

    testWidgets('R-FIN-14 : methode modifiee recemment, « Demander '
        'validation » et jamais « Confirmer »', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await ouvrirDetail(tester, etat, PaiementsDemo.obligationMethodeRecente);
      expect(find.text(c.payerMaintenant), findsNothing);
      await appuyer(tester, find.text(c.demanderValidation));
      expect(find.byKey(PayoutConfirmationSheet.cleConfirmer), findsNothing);
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleDemander));
      expect(find.text(c.validationDemandeeTitre), findsOneWidget);
      expect(etat.validations, hasLength(1));
      expect(etat.envoisAcceptes, 0);
    });

    testWidgets('R-FIN-15 : son propre paiement, ni « Payer maintenant » ni '
        'feuille, la raison rendue', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await ouvrirDetail(tester, etat, PaiementsDemo.obligationComptable);
      expect(find.text(c.payerMaintenant), findsNothing);
      expect(find.text(c.demanderValidation), findsNothing);
      expect(
        find.text(libelleRaisonBlocage(RaisonBlocage.autoPaiement)),
        findsWidgets,
      );
    });

    testWidgets('hors ligne : aucun bouton d\'envoi', (
      WidgetTester tester,
    ) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await ouvrirDetail(
        tester,
        etat,
        SocleComptableDemo.obligationDiallo,
        horsLigne: true,
      );
      expect(find.text(c.payerMaintenant), findsNothing);
      expect(find.text(p.horsLigneCourt), findsWidgets);
    });
  });

  group('le lot (§41)', () {
    testWidgets(
      'R-FIN-22 et R-FIN-23 : 11 prets / 2 exclus, l\'exclusion dite, '
      'seuls les prets partent',
      (WidgetTester tester) async {
        final EtatDemoPaiements etat = EtatDemoPaiements();
        await monterPaiements(
          tester,
          const PaiementsAEffectuerPage(),
          surcharges: surchargesDemo(etat),
          taille: telephone,
        );
        await appuyer(
          tester,
          find.byKey(PaiementsAEffectuerPage.cleSelectionnerPrets),
        );
        // Une ligne non prete retenue en plus : le preflight l'exclura.
        final Finder caseInfos = find.byKey(
          CaseObligation.cleDe(PaiementsDemo.obligationInfosManquantes),
        );
        await appuyer(tester, caseInfos);
        expect(find.text(p.selection(n: 13)), findsOneWidget);
        await appuyer(tester, find.byKey(BarreSelection.clePayer));
        final Finder feuille = find.byType(PayoutConfirmationSheet);
        expect(feuille, findsOneWidget);
        expect(
          find.text('${c.prets(n: 11)} / ${c.exclus(n: 2)}'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('payout-exclus')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: feuille,
            matching: find.text(
              libelleRaisonBlocage(RaisonBlocage.fournisseurIndisponible),
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: feuille,
            matching: find.text(
              libelleRaisonBlocage(RaisonBlocage.infosManquantes),
            ),
          ),
          findsOneWidget,
        );
        // Le bouton dit le total rendu par la source, en clair.
        expect(
          find.descendant(
            of: feuille,
            matching: find.text(MontantSensible.masquePour('USD')),
          ),
          findsNothing,
        );
        await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleConfirmer));
        // Un des prets est recalcule a la source pendant la confirmation :
        // tout le lot est refuse, rien ne part (DR-13).
        expect(find.text(c.recalculeTitre), findsOneWidget);
        expect(etat.envoisAcceptes, 0);
        await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleRelancer));
        expect(
          find.text('${c.prets(n: 11)} / ${c.exclus(n: 2)}'),
          findsOneWidget,
        );
        await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleConfirmer));
        expect(find.text(c.soumisTitre), findsOneWidget);
        expect(etat.envoisAcceptes, 11);
        expect(
          etat
              .obligations[PaiementsDemo.obligationFournisseurIndisponible]!
              .etat,
          EtatPaiementSortant.pretAPayer,
          reason: 'un exclu ne part jamais avec le lot',
        );
        expect(
          etat.obligations[PaiementsDemo.obligationInfosManquantes]!.etat,
          EtatPaiementSortant.infosManquantes,
        );
      },
    );

    testWidgets('un paiement sensible retenu dans un lot en est exclu '
        '(pas de contournement en le noyant, §47)', (
      WidgetTester tester,
    ) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      final PayoutDemo payout = PayoutDemo(etat);
      final PreflightLot lot = await payout.preflight(<ObligationChoisie>[
        for (final String id in <String>[
          SocleComptableDemo.obligationDiallo,
          PaiementsDemo.obligationMethodeRecente,
        ])
          ObligationChoisie(
            obligationId: id,
            version: etat.obligations[id]!.version,
          ),
      ]);
      expect(lot.sensible, isFalse);
      expect(lot.prets, hasLength(1));
      expect(
        lot.exclus.single.obligationId,
        PaiementsDemo.obligationMethodeRecente,
      );
    });

    testWidgets('« Payer » sur une ligne ouvre la confirmation de ce seul '
        'paiement', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(etat),
        taille: telephone,
      );
      await appuyer(
        tester,
        find.byKey(ActionObligation.cleDe(SocleComptableDemo.obligationDiallo)),
      );
      expect(find.byType(PayoutConfirmationSheet), findsOneWidget);
      expect(find.text(c.titreUn), findsOneWidget);
    });
  });

  test('le port neutre reste indisponible (CPT-BR-02, 10)', () {
    expect(
      const PayoutIndisponible().preflight(const <ObligationChoisie>[]),
      throwsA(anything),
    );
    expect(
      const CapacitePayoutIndisponible().prestataires(),
      throwsA(anything),
    );
    expect(
      const ObligationsPayablesIndisponibles().liste(FiltreObligations.tout),
      throwsA(anything),
    );
  });
}
