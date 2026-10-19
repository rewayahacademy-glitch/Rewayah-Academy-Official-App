// FAC-D-01 : captures de la validation des paiements saisis par la
// comptabilite (page « Paiements des familles », fiche « Validation
// demandee », onglet « A valider » de la direction et sa decision).
// Sautees sans `CAPTURE_DIR` (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_saisis.dart';
import 'package:rewayah_academy/core/capacites/port_validations_finance.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/admin_finance/a_valider/a_valider_page.dart';
import 'package:rewayah_academy/features/admin_finance/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/comptable/paiements_familles/paiements_familles_page.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

const EdgeInsets _zoneSure = EdgeInsets.only(top: 47, bottom: 34);

class _Paiements implements PortPaiementsSaisis {
  @override
  Future<List<ElevePourPaiement>> eleves() =>
      Future<List<ElevePourPaiement>>.value(const <ElevePourPaiement>[
        ElevePourPaiement(
          profilId: 'e2',
          prenom: 'Bilal',
          nom: 'Diallo',
          matricule: 'RA-26-4817',
          resteAPayer: Montant(5000, 'USD'),
        ),
        ElevePourPaiement(
          profilId: 'e3',
          prenom: 'Maryam',
          nom: 'Sow',
          matricule: 'RA-26-2290',
          resteAPayer: Montant(4750, 'USD'),
        ),
        ElevePourPaiement(
          profilId: 'e1',
          prenom: 'Yasmine',
          nom: 'Diallo',
          matricule: 'RA-26-1203',
          resteAPayer: Montant(0, 'USD'),
        ),
      ]);

  @override
  Future<PaiementEnregistre> enregistrer({
    required String profilId,
    required Montant montant,
    required String cle,
    String? reference,
  }) => Future<PaiementEnregistre>.value(
    const PaiementEnregistre(
      issue: IssuePaiement.validationDemandee,
      nouveau: true,
    ),
  );

  @override
  Future<FacturesEmises> emettreFactures(DateTime mois) =>
      Future<FacturesEmises>.value(
        const FacturesEmises(emises: 0, financees: 0),
      );
}

class _Validations implements PortValidationsFinance {
  _Validations({required this.direction});

  final bool direction;

  @override
  Future<List<DemandeValidation>> demandes(FiltreDemandesValidation filtre) =>
      Future<List<DemandeValidation>>.value(<DemandeValidation>[
        _demande(
          'v1',
          'Maryam Sow (RA-26-2290)',
          4750,
          EtatDemandeValidation.enAttente,
          reference: 'VIR-2026-1018',
        ),
        _demande(
          'v2',
          'Bilal Diallo (RA-26-4817)',
          5000,
          EtatDemandeValidation.refusee,
        ),
      ]);

  DemandeValidation _demande(
    String id,
    String objet,
    int mineur,
    EtatDemandeValidation etat, {
    String? reference,
  }) => DemandeValidation(
    id: id,
    nature: NatureDemandeValidation.paiementRecu,
    date: DateTime(2026, 10, 18, 9, 12),
    demandeur: 'Ibrahima Bah',
    objet: objet,
    objetId: id,
    montant: Montant(mineur, 'USD'),
    raison: RaisonBlocage.paiementHorsApplication,
    precision: reference == null
        ? null
        : t.comptable.validation.reference(reference: reference),
    etat: etat,
    decideur: etat == EtatDemandeValidation.enAttente ? null : 'Direction',
    dateDecision: etat == EtatDemandeValidation.enAttente
        ? null
        : DateTime(2026, 10, 18, 10, 40),
    motifDecision: etat == EtatDemandeValidation.refusee
        ? t.comptable.validation.motifs.montant
        : null,
    permissions: etat != EtatDemandeValidation.enAttente
        ? PermissionsFinance.lectureSeule
        : direction
        ? const PermissionsFinance(
            actions: <ActionFinance>{ActionFinance.approuver},
          )
        : const PermissionsFinance(
            blocages: <ActionFinance, RaisonBlocage>{
              ActionFinance.approuver: RaisonBlocage.autoPaiement,
            },
          ),
  );

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
    String? motif,
  }) => throw UnimplementedError();

  @override
  Future<List<EntreeJournal>> journal(String demandeId) =>
      Future<List<EntreeJournal>>.value(<EntreeJournal>[
        EntreeJournal(
          id: '$demandeId:demande',
          date: DateTime(2026, 10, 18, 9, 12),
          initiateur: 'Ibrahima Bah',
          objet: t.comptable.validation.journal.demandee,
          montant: const Montant(4750, 'USD'),
          reference: 'VIR-2026-1018',
        ),
      ]);
}

List<Override> _surcharges({required bool direction}) => <Override>[
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  sansPersonneConnectee(),
  portPaiementsSaisisProvider.overrideWithValue(_Paiements()),
  portValidationsFinanceProvider.overrideWithValue(
    _Validations(direction: direction),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  Widget ecran, {
  required bool direction,
  ThemeMode mode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      ecran,
      surcharges: _surcharges(direction: direction),
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Capture : validation des paiements', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      neutraliserStockageAppareil();
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('comptable, paiements des familles, ${mode.name}', (
        WidgetTester tester,
      ) async {
        fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
        await _monter(
          tester,
          const PaiementsFamillesPage(),
          direction: false,
          mode: mode,
        );
        final Finder attente = find.text(t.admin.finance.pai.enAttente);
        await tester.ensureVisible(attente);
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, '1_comptable_paiements_familles_${mode.name}')}',
        );
      });
    }

    testWidgets('comptable, fiche : validation demandee', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(tester, const PaiementsFamillesPage(), direction: false);
      await _toucher(tester, find.byKey(PaiementsBloc.cleEleve('e2')));
      debugPrint('PNG ${await capturer(tester, '2_comptable_fiche_saisie')}');
      await _toucher(tester, find.byKey(FeuillePaiement.cleEnregistrer));
      debugPrint(
        'PNG ${await capturer(tester, '3_comptable_validation_demandee')}',
      );
    });

    testWidgets('direction, a valider', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3, zoneSure: _zoneSure);
      await _monter(
        tester,
        PageShell(titre: t.admin.finance.aValider, child: const AValiderBloc()),
        direction: true,
      );
      debugPrint('PNG ${await capturer(tester, '4_direction_a_valider')}');
      await _toucher(tester, find.byKey(AValiderBloc.cleDemande('v1')));
      debugPrint('PNG ${await capturer(tester, '5_direction_decision')}');
    });

    testWidgets('direction, a valider, bureau', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(1440, 900), 1);
      await _monter(
        tester,
        PageShell(titre: t.admin.finance.aValider, child: const AValiderBloc()),
        direction: true,
      );
      await _toucher(tester, find.byKey(AValiderBloc.cleDemande('v1')));
      debugPrint(
        'PNG ${await capturer(tester, '6_direction_decision_bureau')}',
      );
    });
  });
}
