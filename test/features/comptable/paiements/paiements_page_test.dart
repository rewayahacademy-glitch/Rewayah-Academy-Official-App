// CPT-PAY-1 : la liste W02 « Paiements a effectuer ». Tableau au bureau,
// cartes sur telephone, filtres de l'adresse et de la page, selection et
// « Selectionner tous les paiements prets », montant en lecture seule
// (R-FIN-16), auto-payout sans case ni bouton (R-FIN-15), cinq etats.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_obligations_payables.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/data_collection.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/comptable/paiements/barre_selection.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/ligne_obligation.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/demo/comptable/paiements_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/validations_demo.dart';

import 'support_paiements.dart';

void main() {
  // Le registre unique des validations de la demonstration (CPT-VAL-1)
  // repart de l'etat de depart a chaque test.
  setUp(RegistreValidationsDemo.instance.reinitialiser);

  final p = t.comptable.paiements;
  final String masqueUsd = MontantSensible.masquePour('USD');

  // Assez haut pour que les 21 lignes du tableau (paresseux) soient bâties.
  const Size bureauHaut = Size(1440, 2400);

  group('W02 au bureau (1440)', () {
    testWidgets('le tableau de §30 : 21 lignes, montants masques, '
        'aucun champ de saisie (R-FIN-16)', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      expect(find.byType(DataCollection<ObligationPayable>), findsOneWidget);
      for (final String colonne in <String>[
        p.colonnes.beneficiaire,
        p.colonnes.type,
        p.colonnes.periode,
        p.colonnes.montant,
        p.colonnes.destination,
        p.colonnes.echeance,
        p.colonnes.statut,
        p.colonnes.action,
      ]) {
        expect(find.text(colonne), findsWidgets, reason: colonne);
      }
      expect(find.text(p.compteur(n: 21)), findsOneWidget);
      expect(find.text(masqueUsd), findsWidgets);
      expect(
        find.text(formaterMontant(SocleComptableDemo.usd(212))),
        findsNothing,
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('le Comptable beneficiaire : ni case ni Payer, la raison '
        'rendue (R-FIN-15)', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
        taille: bureauHaut,
      );
      expect(
        find.byKey(CaseObligation.cleDe(PaiementsDemo.obligationComptable)),
        findsNothing,
      );
      expect(
        find.byKey(ActionObligation.cleDe(PaiementsDemo.obligationComptable)),
        findsNothing,
      );
      expect(
        find.text(t.comptable.statuts.raison.autoPaiement),
        findsOneWidget,
      );
      // Une ligne en transit se suit, elle ne se choisit plus.
      expect(
        find.byKey(CaseObligation.cleDe(PaiementsDemo.obligationEnTransit)),
        findsNothing,
      );
    });

    testWidgets('Selectionner tous les paiements prets retient les 12 prets, '
        'la barre ne montre aucun total', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
        taille: bureauHaut,
      );
      expect(find.byKey(BarreSelection.cleBarre), findsNothing);
      await tester.tap(
        find.byKey(PaiementsAEffectuerPage.cleSelectionnerPrets),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BarreSelection.cleBarre), findsOneWidget);
      expect(find.text(p.selection(n: 12)), findsOneWidget);
      expect(find.text(p.selectionPhrase), findsOneWidget);
      // Les infos manquantes ne sont pas retenues par « tous les prets ».
      final Checkbox infos = tester.widget(
        find.byKey(
          CaseObligation.cleDe(PaiementsDemo.obligationInfosManquantes),
        ),
      );
      expect(infos.value, isFalse);
      await tester.tap(find.text(p.actions.viderSelection));
      await tester.pumpAndSettle();
      expect(find.byKey(BarreSelection.cleBarre), findsNothing);
    });

    testWidgets('une case retient une ligne non prete : le preflight dira '
        'pourquoi (§41)', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
        taille: bureauHaut,
      );
      await tester.tap(
        find.byKey(
          CaseObligation.cleDe(PaiementsDemo.obligationInfosManquantes),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(p.selection(n: 1)), findsOneWidget);
    });

    testWidgets('un clic sur une ligne ouvre le detail W03', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      await tester.tap(find.text('Sayyid Youssouf Diallo'));
      await tester.pumpAndSettle();
      expect(find.byType(DetailPaiementPage), findsOneWidget);
    });

    testWidgets('Relancer ouvre le profil de paiement du beneficiaire (W07), '
        'aucune messagerie Finance (R-FIN-21)', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
        taille: bureauHaut,
      );
      await tester.tap(
        find.byKey(
          ActionObligation.cleDe(PaiementsDemo.obligationInfosManquantes),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('profil ens-11'), findsOneWidget);
    });
  });

  group('Filtres', () {
    testWidgets('?filtre=infos ouvre la liste deja filtree (§5.1)', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(filtre: 'infos'),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      expect(find.text(p.compteur(n: 2)), findsOneWidget);
      expect(find.text(p.filtres.effacer), findsOneWidget);
    });

    testWidgets('?type=contractuel&classe= inconnue : le type filtre, une '
        'valeur inconnue ne vide pas la liste', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(type: 'contractuel', filtre: 'nimporte'),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      // Cinq contractuels et le Comptable (contractuel de Rewayah).
      expect(find.text(p.compteur(n: 6)), findsOneWidget);
    });

    testWidgets('la Classe reste un filtre (§14.5)', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(classe: 'Al-Fajr'),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      expect(find.text(p.compteur(n: 4)), findsOneWidget);
    });

    testWidgets('les pilules de type filtrent, Effacer les filtres revient '
        'a tout', (WidgetTester tester) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      await tester.tap(find.text(p.filtres.enseignants));
      await tester.pumpAndSettle();
      expect(find.text(p.compteur(n: 15)), findsOneWidget);
      // FILTRES-1 : une seule RangeeFiltres qui defile ; « Effacer les
      // filtres » est en bout de rangee, amene a l'ecran avant le toucher.
      await tester.ensureVisible(find.text(p.filtres.effacer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(p.filtres.effacer));
      await tester.pumpAndSettle();
      expect(find.text(p.compteur(n: 21)), findsOneWidget);
    });

    testWidgets('un filtre sans resultat : vide actionnable', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(
          filtre: 'verification',
          type: 'contractuel',
        ),
        surcharges: surchargesDemo(EtatDemoPaiements()),
      );
      expect(find.text(p.vide.filtreMessage), findsOneWidget);
      await tester.tap(find.text(p.filtres.effacer).last);
      await tester.pumpAndSettle();
      expect(find.text(p.compteur(n: 21)), findsOneWidget);
    });
  });

  group('W02 sur telephone (390, M01 ecran 2)', () {
    testWidgets('des cartes, pas un tableau ; montants masques', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
        taille: const Size(390, 844),
      );
      expect(find.byType(DataCollection<ObligationPayable>), findsNothing);
      expect(find.byType(CarteObligation), findsWidgets);
      expect(find.text(masqueUsd), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 de large, texte double : rien ne deborde', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements()),
        taille: const Size(320, 640),
        texte: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CarteObligation), findsWidgets);
    });

    testWidgets('montants affiches : le chiffre exact apparait', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: surchargesDemo(EtatDemoPaiements(), montantsAffiches: true),
        taille: const Size(390, 844),
      );
      expect(find.text('212 \$'), findsOneWidget);
    });
  });

  group('Les cinq etats', () {
    testWidgets('chargement : squelette', (WidgetTester tester) async {
      final ObligationsPilotees port = ObligationsPilotees(
        attente: Completer<List<ObligationPayable>>(),
      );
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: <Override>[
          portObligationsPayablesProvider.overrideWithValue(port),
          ...surchargesCommunes(),
        ],
        taille: const Size(390, 844),
        attendre: false,
      );
      expect(find.byType(Skeleton), findsWidgets);
      port.attente!.complete(const <ObligationPayable>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('vide : bonne nouvelle, sans bouton', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: <Override>[
          portObligationsPayablesProvider.overrideWithValue(
            ObligationsPilotees(),
          ),
          ...surchargesCommunes(),
        ],
      );
      expect(find.text(p.vide.message), findsOneWidget);
    });

    testWidgets('erreur : echec de bloc avec Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final ObligationsPilotees port = ObligationsPilotees(
        erreur: StateError('panne'),
      );
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: <Override>[
          portObligationsPayablesProvider.overrideWithValue(port),
          ...surchargesCommunes(),
        ],
      );
      final Finder etat = find.byWidgetPredicate(
        (Widget w) => w is EtatSysteme && w.nature == NatureEtat.echecServeur,
      );
      expect(etat, findsOneWidget);
      final int avant = port.lectures;
      port.erreur = null;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await tester.pumpAndSettle();
      expect(port.lectures, greaterThan(avant));
      expect(find.text(p.vide.message), findsOneWidget);
    });

    testWidgets('hors ligne : etat hors ligne, aucun paiement possible', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: <Override>[
          portObligationsPayablesProvider.overrideWithValue(
            ObligationsPilotees(erreur: StateError('reseau')),
          ),
          ...surchargesCommunes(horsLigne: true),
        ],
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is EtatSysteme && w.nature == NatureEtat.horsLigne,
        ),
        findsOneWidget,
      );
    });

    testWidgets('sans source serveur : « en preparation », aucun chiffre', (
      WidgetTester tester,
    ) async {
      await monterPaiements(
        tester,
        const PaiementsAEffectuerPage(),
        surcharges: <Override>[
          portObligationsPayablesProvider.overrideWithValue(
            ObligationsPilotees(
              erreur: const CapaciteIndisponible('CPT-BR-01'),
            ),
          ),
          ...surchargesCommunes(),
        ],
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(t.comptable.commun.enPreparationTitre), findsOneWidget);
    });
  });

  test('la demonstration tient la spec §44', () async {
    final EtatDemoPaiements etat = EtatDemoPaiements();
    final List<ObligationPayable> toutes = etat.obligations.values.toList();
    expect(
      toutes.where(
        (ObligationPayable o) => o.beneficiaire.id.startsWith('ens'),
      ),
      hasLength(SocleComptableDemo.enseignants.length),
    );
    expect(
      toutes.where(
        (ObligationPayable o) => o.beneficiaire.id.startsWith('ctr'),
      ),
      hasLength(5),
    );
    final ObligationsPayablesDemo port = ObligationsPayablesDemo(etat);
    Future<int> nombre(FiltreObligations f) async =>
        (await port.liste(f)).length;
    expect(
      await nombre(const FiltreObligations(filtre: FiltrePaiements.infos)),
      2,
    );
  });
}
