// CPT-VAL-1 (decision Q-8 = (a) du 05/10) : l'onglet « A valider » de la
// Finance de la direction et le suivi cote Comptable.
//
// - cinq etats (chargement, contenu, vide « Rien a valider », erreur, hors
//   ligne) et la production honnete (port non branche : « Pas encore
//   disponible », aucun bouton) ;
// - le demandeur ne valide jamais lui-meme : capacite rendue par la source
//   (pas de bouton) ET refus de la source si on essaie ;
// - motif obligatoire pour refuser (puces + Autre), rien ne part sans lui ;
// - aucune promesse de succes non confirmee (envoi en cours, issue
//   inconnue) ;
// - cote Comptable : « Demander validation » envoie la demande, qui arrive
//   dans l'onglet de la direction, puis « Validee » ou « Refusee (motif) ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_validations_finance.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_finance/a_valider/a_valider_page.dart';
import 'package:rewayah_academy/features/admin_finance/a_valider/decision_validation.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/confirmation/confirmation_payout.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/validation/suivi_validation.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/validations_demo.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';

import '../../comptable/paiements/support_paiements.dart';
import '../reserve_delegation/support_direction.dart';

/// Un port pilote par le test : chargement sans fin, erreur, liste donnee,
/// decision qui attend, echoue ou est refusee ; il compte les decisions.
class ValidationsPilotees implements PortValidationsFinance {
  ValidationsPilotees({
    this.rendues = const <DemandeValidation>[],
    this.erreur,
    this.attente,
    this.decision,
    this.erreurDecision,
  });

  List<DemandeValidation> rendues;
  Object? erreur;
  Completer<List<DemandeValidation>>? attente;
  Completer<DemandeValidation>? decision;
  Object? erreurDecision;
  final List<(DecisionValidation, String?, String)> decisions =
      <(DecisionValidation, String?, String)>[];

  @override
  Future<List<DemandeValidation>> demandes(
    FiltreDemandesValidation filtre,
  ) async {
    final Completer<List<DemandeValidation>>? a = attente;
    if (a != null) return a.future;
    final Object? e = erreur;
    if (e != null) return Future<List<DemandeValidation>>.error(e);
    return rendues;
  }

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
    String? motif,
  }) async {
    decisions.add((decision, motif, cleIdempotence));
    final Object? e = erreurDecision;
    if (e != null) return Future<DemandeValidation>.error(e);
    final Completer<DemandeValidation>? c = this.decision;
    if (c != null) return c.future;
    throw StateError('aucune decision prevue');
  }

  @override
  Future<List<EntreeJournal>> journal(String demandeId) async =>
      const <EntreeJournal>[];
}

DemandeValidation _demande({
  String id = 'd-1',
  EtatDemandeValidation etat = EtatDemandeValidation.enAttente,
  PermissionsFinance permissions = const PermissionsFinance(
    actions: <ActionFinance>{ActionFinance.approuver},
  ),
}) => DemandeValidation(
  id: id,
  nature: NatureDemandeValidation.payoutSensible,
  date: SocleComptableDemo.aujourdhui,
  demandeur: SocleComptableDemo.leComptable.nom,
  objet: 'Octobre 2026 · test',
  montant: SocleComptableDemo.usd(120),
  raison: RaisonBlocage.validationRequise,
  etat: etat,
  permissions: permissions,
  decideur: etat == EtatDemandeValidation.enAttente ? null : 'Direction',
  dateDecision: etat == EtatDemandeValidation.enAttente
      ? null
      : SocleComptableDemo.aujourdhui,
);

void main() {
  final v = t.comptable.validation;
  const Size telephone = Size(390, 2400);

  setUp(RegistreValidationsDemo.instance.reinitialiser);

  Future<void> monter(
    WidgetTester tester,
    PortValidationsFinance port, {
    bool horsLigne = false,
    bool attendre = true,
  }) async {
    taille(tester, telephone);
    await tester.pumpWidget(
      hoteDirection(
        const AValiderBloc(),
        horsLigne: horsLigne,
        surcharges: <Override>[
          portValidationsFinanceProvider.overrideWithValue(port),
        ],
      ),
    );
    if (attendre) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> appuyer(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> ouvrir(WidgetTester tester, String id) =>
      appuyer(tester, find.byKey(AValiderBloc.cleDemande(id)));

  group('cinq etats', () {
    testWidgets('production : port non branche, « Pas encore disponible », '
        'aucune demande ni bouton', (WidgetTester tester) async {
      await monter(tester, const ValidationsFinanceIndisponibles());
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.indisponible,
        ),
        findsOneWidget,
      );
      expect(find.text(v.valider), findsNothing);
      expect(find.text(v.aDecider), findsNothing);
      expect(find.byType(CarteDemandeValidation), findsNothing);
    });

    testWidgets('chargement : un squelette, aucun contenu', (
      WidgetTester tester,
    ) async {
      final ValidationsPilotees port = ValidationsPilotees(
        attente: Completer<List<DemandeValidation>>(),
      );
      await monter(tester, port, attendre: false);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(CarteDemandeValidation), findsNothing);
    });

    testWidgets('vide : « Rien a valider », les decidees restent lisibles', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        ValidationsPilotees(
          rendues: <DemandeValidation>[
            _demande(etat: EtatDemandeValidation.validee),
          ],
        ),
      );
      expect(find.byKey(AValiderBloc.cleVide), findsOneWidget);
      expect(find.text(v.videTitre), findsOneWidget);
      expect(find.text(v.decidees), findsOneWidget);
    });

    testWidgets(
      'erreur : un echec n\'est jamais une liste vide, « Reessayer »',
      (WidgetTester tester) async {
        await monter(tester, ValidationsPilotees(erreur: StateError('x')));
        expect(find.byKey(AValiderBloc.cleVide), findsNothing);
        expect(find.text(t.commun.reessayer), findsWidgets);
      },
    );

    testWidgets('hors ligne : l\'echec sans reseau le dit', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        ValidationsPilotees(erreur: StateError('x')),
        horsLigne: true,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.horsLigne,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne avec la liste chargee : aucune decision ne part, '
        'une phrase au lieu des boutons', (WidgetTester tester) async {
      await monter(tester, const ValidationsFinanceDemo(), horsLigne: true);
      await ouvrir(tester, ValidationsDemo.demandeLieeOperateur);
      expect(find.text(v.horsLigne), findsOneWidget);
      expect(find.byKey(FeuilleDecisionValidation.cleValider), findsNothing);
      expect(find.byKey(FeuilleDecisionValidation.cleRefuser), findsNothing);
    });

    testWidgets('contenu : les quatre demandes du Comptable, la demande de la '
        'direction, puis les decidees ; montants masques', (
      WidgetTester tester,
    ) async {
      await monter(tester, const ValidationsFinanceDemo());
      expect(find.text(v.aDecider), findsOneWidget);
      for (final String id in <String>[
        ValidationsDemo.demandeLieeOperateur,
        ValidationsDemo.demandePaieComptable,
        ValidationsDemo.demandeRetraitReserve,
        ValidationsDemo.demandeObligationPonctuelle,
        ValidationsDemo.demandeDeLaDirection,
        ValidationsDemo.demandeValidee,
        ValidationsDemo.demandeRefusee,
      ]) {
        expect(find.byKey(AValiderBloc.cleDemande(id)), findsOneWidget);
      }
      expect(find.text(v.natures.retraitReserve), findsOneWidget);
      expect(find.text(v.natures.payoutDuComptable), findsOneWidget);
      expect(find.text(v.natures.obligationAApprouver), findsNWidgets(2));
      expect(find.text(v.votreDemandeTitre), findsOneWidget);
      expect(
        find.text(v.motif(motif: 'Coordonnées du bénéficiaire à vérifier')),
        findsOneWidget,
      );
      // Masques par defaut dans la liste.
      expect(
        find.text(formaterMontant(SocleComptableDemo.usd(500))),
        findsNothing,
      );
    });
  });

  group('decider', () {
    testWidgets('valider : le montant exact, puis « Validee » seulement avec '
        'la reponse de la source', (WidgetTester tester) async {
      await monter(tester, const ValidationsFinanceDemo());
      await ouvrir(tester, ValidationsDemo.demandeRetraitReserve);
      expect(
        find.text(formaterMontant(SocleComptableDemo.usd(500))),
        findsOneWidget,
      );
      await appuyer(tester, find.byKey(FeuilleDecisionValidation.cleValider));
      expect(find.text(v.decisionValidee), findsOneWidget);
      final DemandeValidation d = RegistreValidationsDemo.instance
          .demandes(ValidationsDemo.directionId, FiltreDemandesValidation.tout)
          .firstWhere(
            (DemandeValidation x) =>
                x.id == ValidationsDemo.demandeRetraitReserve,
          );
      expect(d.etat, EtatDemandeValidation.validee);
      expect(d.decideur, ValidationsDemo.directionNom);
      await appuyer(tester, find.text(v.fermer));
      // Relue : elle a quitte « A decider ».
      expect(find.text(v.natures.retraitReserve), findsOneWidget);
      expect(find.byType(FeuilleDecisionValidation), findsNothing);
    });

    testWidgets('refuser : motif obligatoire ; sans motif rien ne part, '
        '« Autre » vide non plus', (WidgetTester tester) async {
      final ValidationsPilotees port = ValidationsPilotees(
        rendues: <DemandeValidation>[_demande()],
      );
      await monter(tester, port);
      await ouvrir(tester, 'd-1');
      await appuyer(tester, find.byKey(FeuilleDecisionValidation.cleRefuser));
      expect(find.text(v.motifTitre), findsWidgets);
      await appuyer(
        tester,
        find.byKey(FeuilleDecisionValidation.cleConfirmerRefus),
      );
      expect(find.text(v.erreurMotif), findsOneWidget);
      expect(port.decisions, isEmpty);
      await appuyer(
        tester,
        find.byKey(
          FeuilleDecisionValidation.cleMotif(MotifRefusValidation.autre),
        ),
      );
      await tester.enterText(
        find.byKey(FeuilleDecisionValidation.cleMotifAutre),
        '   ',
      );
      await appuyer(
        tester,
        find.byKey(FeuilleDecisionValidation.cleConfirmerRefus),
      );
      expect(find.text(v.erreurMotifAutre), findsOneWidget);
      expect(port.decisions, isEmpty);
    });

    testWidgets('refuser avec une puce : le motif part et revient au '
        'Comptable', (WidgetTester tester) async {
      await monter(tester, const ValidationsFinanceDemo());
      await ouvrir(tester, ValidationsDemo.demandeLieeOperateur);
      await appuyer(tester, find.byKey(FeuilleDecisionValidation.cleRefuser));
      await appuyer(
        tester,
        find.byKey(
          FeuilleDecisionValidation.cleMotif(MotifRefusValidation.justificatif),
        ),
      );
      await appuyer(
        tester,
        find.byKey(FeuilleDecisionValidation.cleConfirmerRefus),
      );
      expect(find.text(v.decisionRefusee), findsOneWidget);
      final DemandeValidation? d = RegistreValidationsDemo.instance.derniere(
        PaiementsDemo.obligationLieeOperateur,
      );
      expect(d!.etat, EtatDemandeValidation.refusee);
      expect(d.motifDecision, v.motifs.justificatif);
    });

    testWidgets('refuser avec « Autre » : le texte saisi est le motif', (
      WidgetTester tester,
    ) async {
      await monter(tester, const ValidationsFinanceDemo());
      await ouvrir(tester, ValidationsDemo.demandeObligationPonctuelle);
      await appuyer(tester, find.byKey(FeuilleDecisionValidation.cleRefuser));
      await appuyer(
        tester,
        find.byKey(
          FeuilleDecisionValidation.cleMotif(MotifRefusValidation.autre),
        ),
      );
      await tester.enterText(
        find.byKey(FeuilleDecisionValidation.cleMotifAutre),
        'Devis à refaire avec la TVA',
      );
      await appuyer(
        tester,
        find.byKey(FeuilleDecisionValidation.cleConfirmerRefus),
      );
      expect(
        RegistreValidationsDemo.instance.derniere('obl-ctr-025')!.motifDecision,
        'Devis à refaire avec la TVA',
      );
    });
  });

  group('jamais le demandeur', () {
    testWidgets('sa propre demande : aucun bouton de decision, la phrase le '
        'dit (capacite rendue, aucun role lu)', (WidgetTester tester) async {
      await monter(tester, const ValidationsFinanceDemo());
      await ouvrir(tester, ValidationsDemo.demandeDeLaDirection);
      expect(find.text(v.votreDemandePhrase), findsOneWidget);
      expect(find.byKey(FeuilleDecisionValidation.cleValider), findsNothing);
      expect(find.byKey(FeuilleDecisionValidation.cleRefuser), findsNothing);
    });

    test('la source refuse la decision du demandeur lui-meme, quel que soit '
        'son ecran', () async {
      const ValidationsFinanceDemo direction = ValidationsFinanceDemo();
      expect(
        () => direction.decider(
          demandeId: ValidationsDemo.demandeDeLaDirection,
          decision: DecisionValidation.valider,
          cleIdempotence: 'k1',
        ),
        throwsA(
          isA<RefusDecision>().having(
            (RefusDecision r) => r.motif,
            'motif',
            MotifRefusDecision.demandeurNePeutPasValider,
          ),
        ),
      );
      // Le Comptable ne valide pas non plus ce qu'il a demande.
      final ValidationsFinanceDemo comptable = ValidationsFinanceDemo(
        lecteurId: SocleComptableDemo.comptableId,
        lecteurNom: SocleComptableDemo.leComptable.nom,
      );
      final List<DemandeValidation> siennes = await comptable.demandes(
        const FiltreDemandesValidation(etat: EtatDemandeValidation.enAttente),
      );
      final DemandeValidation paie = siennes.firstWhere(
        (DemandeValidation d) => d.id == ValidationsDemo.demandePaieComptable,
      );
      expect(paie.permissions.permet(ActionFinance.approuver), isFalse);
      expect(
        paie.permissions.raisonDe(ActionFinance.approuver),
        RaisonBlocage.autoPaiement,
      );
      expect(
        () => comptable.decider(
          demandeId: ValidationsDemo.demandePaieComptable,
          decision: DecisionValidation.valider,
          cleIdempotence: 'k2',
        ),
        throwsA(isA<RefusDecision>()),
      );
      expect(
        RegistreValidationsDemo.instance
            .derniere(PaiementsDemo.obligationComptable)!
            .etat,
        EtatDemandeValidation.enAttente,
      );
    });

    testWidgets('si la source refuse quand meme (demandeur), « Decision non '
        'enregistree », jamais « Validee »', (WidgetTester tester) async {
      final ValidationsPilotees port = ValidationsPilotees(
        rendues: <DemandeValidation>[_demande()],
        erreurDecision: const RefusDecision(
          MotifRefusDecision.demandeurNePeutPasValider,
        ),
      );
      await monter(tester, port);
      await ouvrir(tester, 'd-1');
      await appuyer(tester, find.byKey(FeuilleDecisionValidation.cleValider));
      expect(find.text(v.refusTitre), findsOneWidget);
      expect(find.text(v.refusDemandeur), findsOneWidget);
      expect(find.text(v.decisionValidee), findsNothing);
    });

    test('la source refuse un refus sans motif et une demande deja '
        'decidee', () {
      const ValidationsFinanceDemo direction = ValidationsFinanceDemo();
      expect(
        () => direction.decider(
          demandeId: ValidationsDemo.demandeLieeOperateur,
          decision: DecisionValidation.refuser,
          cleIdempotence: 'k3',
          motif: '  ',
        ),
        throwsA(
          isA<RefusDecision>().having(
            (RefusDecision r) => r.motif,
            'motif',
            MotifRefusDecision.motifObligatoire,
          ),
        ),
      );
      expect(
        () => direction.decider(
          demandeId: ValidationsDemo.demandeValidee,
          decision: DecisionValidation.valider,
          cleIdempotence: 'k4',
        ),
        throwsA(isA<RefusDecision>()),
      );
    });
  });

  group('aucune promesse non confirmee', () {
    testWidgets('pendant l\'envoi : rien n\'est annonce ; une seule decision '
        'meme sur double appui', (WidgetTester tester) async {
      final ValidationsPilotees port = ValidationsPilotees(
        rendues: <DemandeValidation>[_demande()],
        decision: Completer<DemandeValidation>(),
      );
      await monter(tester, port);
      await ouvrir(tester, 'd-1');
      final Finder valider = find.byKey(FeuilleDecisionValidation.cleValider);
      await tester.tap(valider);
      await tester.pump();
      await tester.tap(valider, warnIfMissed: false);
      await tester.pump();
      expect(port.decisions, hasLength(1));
      expect(find.text(v.decisionValidee), findsNothing);
      expect(
        find.text(libelleDemandeValidationTest(EtatDemandeValidation.validee)),
        findsNothing,
      );
      port.decision!.complete(_demande(etat: EtatDemandeValidation.validee));
      await tester.pumpAndSettle();
      expect(find.text(v.decisionValidee), findsOneWidget);
    });

    testWidgets('reponse perdue : « Decision non confirmee », relire la liste, '
        'jamais « Validee »', (WidgetTester tester) async {
      final ValidationsPilotees port = ValidationsPilotees(
        rendues: <DemandeValidation>[_demande()],
        erreurDecision: StateError('coupure'),
      );
      await monter(tester, port);
      await ouvrir(tester, 'd-1');
      await appuyer(tester, find.byKey(FeuilleDecisionValidation.cleValider));
      expect(find.text(v.inconnuTitre), findsOneWidget);
      expect(find.text(v.decisionValidee), findsNothing);
      expect(find.text(v.relireListe), findsOneWidget);
      expect(find.byKey(FeuilleDecisionValidation.cleValider), findsNothing);
    });

    test('la meme cle rejouee rend la meme decision, sans seconde', () async {
      const ValidationsFinanceDemo direction = ValidationsFinanceDemo();
      final DemandeValidation a = await direction.decider(
        demandeId: ValidationsDemo.demandeLieeOperateur,
        decision: DecisionValidation.valider,
        cleIdempotence: 'meme',
      );
      final DemandeValidation b = await direction.decider(
        demandeId: ValidationsDemo.demandeLieeOperateur,
        decision: DecisionValidation.valider,
        cleIdempotence: 'meme',
      );
      expect(identical(a, b), isTrue);
    });
  });

  group('cote Comptable', () {
    List<Override> surchargesComptable(EtatDemoPaiements etat) => <Override>[
      ...surchargesDemo(etat),
      portValidationsFinanceProvider.overrideWithValue(
        ValidationsFinanceDemo(
          lecteurId: SocleComptableDemo.comptableId,
          lecteurNom: SocleComptableDemo.leComptable.nom,
        ),
      ),
    ];

    testWidgets('« Demander validation » envoie la demande : « Validation '
        'demandee », puis elle arrive dans l\'onglet de la direction', (
      WidgetTester tester,
    ) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await monterPaiements(
        tester,
        const DetailPaiementPage(
          obligationId: PaiementsDemo.obligationMethodeRecente,
        ),
        surcharges: surchargesComptable(etat),
        taille: telephone,
      );
      expect(find.byKey(SuiviValidation.cle), findsNothing);
      await appuyer(
        tester,
        find.text(t.comptable.paiements.actions.demanderValidation),
      );
      await appuyer(tester, find.byKey(PayoutConfirmationSheet.cleDemander));
      expect(
        find.text(t.comptable.paiements.confirmation.validationDemandeeTitre),
        findsWidgets,
      );
      await appuyer(
        tester,
        find.text(t.comptable.paiements.confirmation.fermer),
      );
      // Le detail relu : le suivi « Validation demandee », plus de bouton.
      expect(find.byKey(SuiviValidation.cle), findsOneWidget);
      expect(find.text(t.comptable.statuts.validation.enAttente), findsWidgets);
      expect(find.byKey(DetailPaiementPage.clePayer), findsNothing);
      // La demande est dans l'onglet de la direction, decidable par elle.
      final List<DemandeValidation> recues =
          await const ValidationsFinanceDemo().demandes(
            const FiltreDemandesValidation(
              objetId: PaiementsDemo.obligationMethodeRecente,
            ),
          );
      expect(recues, hasLength(1));
      expect(recues.single.etat, EtatDemandeValidation.enAttente);
      expect(recues.single.permissions.permet(ActionFinance.approuver), isTrue);
      expect(recues.single.precision, contains('2 octobre 2026'));
    });

    testWidgets(
      'refusee par la direction : « Refusee », par qui, et le motif',
      (WidgetTester tester) async {
        final EtatDemoPaiements etat = EtatDemoPaiements();
        final DemandeValidation d = RegistreValidationsDemo.instance.deposer(
          nature: NatureDemandeValidation.payoutSensible,
          demandeurId: SocleComptableDemo.comptableId,
          demandeurNom: SocleComptableDemo.leComptable.nom,
          objet: 'x',
          montant: SocleComptableDemo.usd(100),
          raison: RaisonBlocage.validationRequise,
          cleIdempotence: 'dep',
          objetId: PaiementsDemo.obligationMethodeRecente,
        );
        await const ValidationsFinanceDemo().decider(
          demandeId: d.id,
          decision: DecisionValidation.refuser,
          cleIdempotence: 'dec',
          motif: v.motifs.coordonnees,
        );
        await monterPaiements(
          tester,
          const DetailPaiementPage(
            obligationId: PaiementsDemo.obligationMethodeRecente,
          ),
          surcharges: surchargesComptable(etat),
          taille: telephone,
        );
        expect(find.text(t.comptable.statuts.validation.refusee), findsWidgets);
        expect(find.textContaining(v.motifs.coordonnees), findsOneWidget);
        expect(
          find.textContaining(ValidationsDemo.directionNom),
          findsOneWidget,
        );
        // Refusee : la demande peut etre refaite apres correction.
        expect(find.byKey(DetailPaiementPage.clePayer), findsOneWidget);
      },
    );

    testWidgets('validee par la direction : « Validee », le paiement devient '
        'payable par le Comptable', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await const ValidationsFinanceDemo().decider(
        demandeId: ValidationsDemo.demandeLieeOperateur,
        decision: DecisionValidation.valider,
        cleIdempotence: 'v',
      );
      await monterPaiements(
        tester,
        const DetailPaiementPage(
          obligationId: PaiementsDemo.obligationLieeOperateur,
        ),
        surcharges: surchargesComptable(etat),
        taille: telephone,
      );
      expect(find.text(t.comptable.statuts.validation.validee), findsWidgets);
      expect(
        find.text(t.comptable.paiements.confirmation.payerMaintenant),
        findsOneWidget,
      );
    });

    testWidgets('production : la page ne dit rien d\'une validation qu\'elle '
        'ne connait pas', (WidgetTester tester) async {
      final EtatDemoPaiements etat = EtatDemoPaiements();
      await monterPaiements(
        tester,
        const DetailPaiementPage(
          obligationId: PaiementsDemo.obligationComptable,
        ),
        surcharges: <Override>[
          ...surchargesDemo(etat),
          portValidationsFinanceProvider.overrideWithValue(
            const ValidationsFinanceIndisponibles(),
          ),
        ],
        taille: telephone,
      );
      expect(find.byKey(SuiviValidation.cle), findsNothing);
    });
  });

  testWidgets('/demo/finance?ecran=aValider : le quatrieme onglet, dans la '
      'vraie coquille admin', (WidgetTester tester) async {
    taille(tester, const Size(1440, 1200));
    final GoRouter routeur = GoRouter(
      initialLocation: adresseDemoFinance(OngletFinance.aValider),
      routes: routesDemoFinance('staging'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: sessionDirection(),
        child: TranslationProvider(
          child: MaterialApp.router(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: routeur,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AValiderBloc), findsOneWidget);
    expect(find.text(t.admin.finance.aValider), findsWidgets);
    expect(
      find.byKey(AValiderBloc.cleDemande(ValidationsDemo.demandeLieeOperateur)),
      findsOneWidget,
    );
    expect(find.byType(AdminShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Le libelle d'etat, lu comme l'ecran le lit.
String libelleDemandeValidationTest(EtatDemandeValidation e) => switch (e) {
  EtatDemandeValidation.enAttente => t.comptable.statuts.validation.enAttente,
  EtatDemandeValidation.validee => t.comptable.statuts.validation.validee,
  EtatDemandeValidation.refusee => t.comptable.statuts.validation.refusee,
};
