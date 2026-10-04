// CPT-F : le socle Comptable V1 sur le VRAI routeur. Chaque route ouvre sa
// page dans la bonne coquille (NavShell du Comptable, destination allumee,
// onglet actif) ; « Recevoir mes paiements » dans la coquille du role ;
// « Reserve et delegation » dans la coquille admin ; un admin n'ouvre pas
// `/comptable` ; la demonstration n'existe pas en production ; la bascule des
// montants est sur chaque page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/admin_domaine.dart';
import 'package:rewayah_academy/core/comptable/navigation_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/bascule_montants.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/sous_navigation_domaine.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/reserve_delegation_page.dart';
import 'package:rewayah_academy/features/comptable/aujourdhui/aujourdhui_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/beneficiaires_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/contractuels/contractuels_page.dart';
import 'package:rewayah_academy/features/comptable/contractuels/nouvelle_obligation_page.dart';
import 'package:rewayah_academy/features/comptable/contractuels/obligation_contractuel_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/detail_encaissement_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/encaissements_page.dart';
import 'package:rewayah_academy/features/comptable/encaissements/rapprochement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/detail_paiement_page.dart';
import 'package:rewayah_academy/features/comptable/paiements/paiements_page.dart';
import 'package:rewayah_academy/features/comptable/tresorerie/tresorerie_page.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';
import 'package:rewayah_academy/features/paiements_recus/recevoir_paiements_page.dart';

import '../../../router/support_routeur.dart';
import '../../../support/harnais.dart';

String _chemin(GoRouter r) => r.routerDelegate.currentConfiguration.uri.path;

Future<GoRouter> _comptable(
  WidgetTester tester,
  String depart, {
  Size taille = const Size(390, 844),
}) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(AppRole.accountant)),
  taille: taille,
);

NavShell _coquille(WidgetTester tester) =>
    tester.widget<NavShell>(find.byType(NavShell));

void main() {
  group('Routes : helpers', () {
    test('adresses filtrees sans parametre vide', () {
      expect(Routes.comptablePaiementsFiltres(), Routes.comptablePaiements);
      expect(
        Routes.comptablePaiementsFiltres(filtre: 'prets', type: 'enseignant'),
        '/comptable/paiements?filtre=prets&type=enseignant',
      );
      expect(
        Routes.comptableTresorerieAlimenter,
        '/comptable/tresorerie?action=alimenter',
      );
      expect(Routes.comptableAttention, '/comptable?vue=attention');
      expect(
        Routes.comptablePaiementObligationPour('o1'),
        '/comptable/paiements/obligation/o1',
      );
      expect(
        Routes.comptableContractuelObligationPour('o2'),
        '/comptable/paiements/contractuels/obligation/o2',
      );
      expect(
        Routes.comptableBeneficiairePour('b1'),
        '/comptable/paiements/beneficiaires/b1',
      );
      expect(
        Routes.comptableEncaissementPour('e1'),
        '/comptable/tresorerie/encaissements/e1',
      );
      expect(Routes.racinePour(AppRole.accountant), Routes.comptable);
      expect(Routes.prefixePour(AppRole.accountant), Routes.comptable);
      expect(
        Routes.estTacheFocaliseeComptable(Routes.comptableContractuelsNouvelle),
        isTrue,
      );
      expect(
        Routes.estTacheFocaliseeComptable(
          Routes.comptablePaiementObligationPour('o'),
        ),
        isFalse,
      );
      expect(
        Routes.estPaiementsComptable(Routes.comptableBeneficiairePour('b')),
        isTrue,
      );
      expect(
        Routes.estTresorerieComptable(Routes.comptableRapprochement),
        isTrue,
      );
    });

    test('onglets de second niveau et leur index actif', () {
      expect(ongletsPaiementsComptable().map((o) => o.chemin), <String>[
        Routes.comptablePaiements,
        Routes.comptableContractuels,
        Routes.comptableBeneficiaires,
      ]);
      expect(ongletsTresorerieComptable().map((o) => o.chemin), <String>[
        Routes.comptableTresorerie,
        Routes.comptableEncaissements,
        Routes.comptableRapprochement,
      ]);
      expect(indexOngletPaiements(Routes.comptableContractuelsNouvelle), 1);
      expect(indexOngletPaiements(Routes.comptableBeneficiairePour('b')), 2);
      expect(
        indexOngletPaiements(Routes.comptablePaiementObligationPour('o')),
        0,
      );
      expect(indexOngletTresorerie(Routes.comptableEncaissementPour('e')), 1);
      expect(indexOngletTresorerie(Routes.comptableRapprochement), 2);
    });

    test('la demonstration n existe pas en production', () {
      expect(routesDemoComptable('production'), isEmpty);
      expect(routesDemoComptable(''), isEmpty);
      expect(routesDemoComptable('staging'), hasLength(1));
      expect(
        adresseDemoComptable(
          EcranDemoComptable.paiements,
          montantsAffiches: true,
        ),
        '/demo/comptable?ecran=paiements&montants=affiches',
      );
    });
  });

  group('Coquille du Comptable (vrai routeur)', () {
    final List<(String, Type, int, int?)> cas = <(String, Type, int, int?)>[
      (Routes.comptable, AujourdhuiComptablePage, 0, null),
      (Routes.comptableAttention, AujourdhuiComptablePage, 0, null),
      (Routes.comptablePaiements, PaiementsAEffectuerPage, 1, 0),
      (
        Routes.comptablePaiementsFiltres(filtre: 'prets'),
        PaiementsAEffectuerPage,
        1,
        0,
      ),
      (
        Routes.comptablePaiementObligationPour('o1'),
        DetailPaiementPage,
        1,
        null,
      ),
      (Routes.comptableContractuels, ContractuelsPage, 1, 1),
      (Routes.comptableContractuelsNouvelle, NouvelleObligationPage, 1, null),
      (
        Routes.comptableContractuelObligationPour('o2'),
        ObligationContractuelPage,
        1,
        null,
      ),
      (Routes.comptableBeneficiaires, BeneficiairesPage, 1, 2),
      (Routes.comptableBeneficiairePour('b1'), ProfilPaiementPage, 1, null),
      (Routes.comptableTresorerie, TresoreriePage, 2, 0),
      (Routes.comptableTresorerieAlimenter, TresoreriePage, 2, 0),
      (Routes.comptableEncaissements, EncaissementsPage, 2, 1),
      (Routes.comptableEncaissementPour('e1'), DetailEncaissementPage, 2, null),
      (Routes.comptableRapprochement, RapprochementPage, 2, 2),
    ];
    for (final (String chemin, Type page, int destination, int? onglet)
        in cas) {
      testWidgets('$chemin ouvre $page, destination $destination', (
        WidgetTester tester,
      ) async {
        final GoRouter routeur = await _comptable(tester, chemin);
        expect(_chemin(routeur), Uri.parse(chemin).path);
        expect(find.byType(page), findsOneWidget);
        final NavShell coquille = _coquille(tester);
        expect(coquille.destinations, hasLength(4));
        expect(coquille.indexActif, destination);
        expect(
          coquille.masquerBarreBasse,
          chemin == Routes.comptableContractuelsNouvelle,
          reason: 'seule Nouvelle obligation efface la barre basse',
        );
        // « En preparation » : honnete, aucun chiffre.
        expect(find.byType(EmptyState), findsOneWidget);
        expect(
          find.text(t.comptable.commun.enPreparationTitre),
          findsOneWidget,
        );
        if (onglet != null) {
          final SousNavigationDomaine nav = tester
              .widget<SousNavigationDomaine>(
                find.byType(SousNavigationDomaine),
              );
          expect(nav.indexActif, onglet);
        }
        if (chemin != Routes.comptableContractuelsNouvelle) {
          expect(find.byType(BasculeMontants), findsOneWidget);
        }
      });
    }

    testWidgets('les parametres de l adresse arrivent bruts au constructeur', (
      WidgetTester tester,
    ) async {
      await _comptable(
        tester,
        Routes.comptablePaiementsFiltres(
          filtre: 'infos',
          type: 'contractuel',
          classe: 'Al-Fajr',
        ),
      );
      final PaiementsAEffectuerPage page = tester.widget(
        find.byType(PaiementsAEffectuerPage),
      );
      expect(page.filtre, 'infos');
      expect(page.type, 'contractuel');
      expect(page.classe, 'Al-Fajr');
    });

    testWidgets('la barre mene aux trois branches puis a Compte', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _comptable(tester, Routes.comptable);
      final NavShell coquille = _coquille(tester);
      coquille.onAller(Routes.comptablePaiements);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.comptablePaiements);
      _coquille(tester).onAller(Routes.comptableTresorerie);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.comptableTresorerie);
      _coquille(tester).onAller(Routes.compte);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.compte);
      // Compte garde la coquille du Comptable, Compte allume.
      expect(_coquille(tester).indexActif, 3);
    });

    testWidgets('le retour d un detail ramene a sa liste', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _comptable(
        tester,
        Routes.comptableEncaissementPour('e1'),
      );
      await tester.tap(find.bySemanticsLabel(t.commun.entete.retour).first);
      await stabiliser(tester);
      expect(_chemin(routeur), Routes.comptableEncaissements);
    });

    testWidgets('/compte/paiements-recus : dans la coquille du role, Compte '
        'allume', (WidgetTester tester) async {
      final GoRouter routeur = await _comptable(
        tester,
        Routes.comptePaiementsRecus,
      );
      expect(_chemin(routeur), Routes.comptePaiementsRecus);
      expect(find.byType(RecevoirPaiementsPage), findsOneWidget);
      expect(_coquille(tester).indexActif, 3);
    });

    testWidgets('un enseignant ouvre aussi /compte/paiements-recus, dans SA '
        'coquille', (WidgetTester tester) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.comptePaiementsRecus,
        source: FausseSourceSession(sessionActive(AppRole.teacher)),
      );
      expect(_chemin(routeur), Routes.comptePaiementsRecus);
      expect(find.byType(RecevoirPaiementsPage), findsOneWidget);
      expect(
        _coquille(tester).destinations.first.chemin,
        Routes.enseignantJournee,
      );
    });

    testWidgets('un admin n ouvre pas /comptable : renvoye a sa racine', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.comptablePaiements,
        source: FausseSourceSession(sessionActive(AppRole.admin)),
      );
      expect(_chemin(routeur), Routes.admin);
      expect(find.byType(PaiementsAEffectuerPage), findsNothing);
    });

    testWidgets('a 1440, la barre laterale depliee porte les quatre '
        'destinations', (WidgetTester tester) async {
      await _comptable(tester, Routes.comptable, taille: const Size(1440, 900));
      expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
      expect(find.text(t.comptable.nav.paiements), findsWidgets);
      expect(find.text(t.comptable.nav.tresorerie), findsWidgets);
    });
  });

  group('Delta Direction', () {
    testWidgets('/admin/finance/reserve-delegation : troisieme onglet, '
        'coquille admin', (WidgetTester tester) async {
      final GoRouter routeur = await monterRouteur(
        tester,
        Routes.adminFinanceReserveDelegation,
        source: FausseSourceSession(sessionActive(AppRole.admin)),
        taille: const Size(1440, 900),
      );
      expect(_chemin(routeur), Routes.adminFinanceReserveDelegation);
      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(FinancePage), findsOneWidget);
      expect(find.byType(ReserveDelegationPage), findsOneWidget);
      expect(ongletsFinance(), hasLength(3));
      expect(
        ongletsFinance().last.chemin,
        Routes.adminFinanceReserveDelegation,
      );
      expect(find.text(t.admin.finance.reserveDelegation), findsWidgets);
    });

    testWidgets('un Comptable n ouvre pas le delta Direction', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _comptable(
        tester,
        Routes.adminFinanceReserveDelegation,
      );
      expect(_chemin(routeur), Routes.comptable);
    });
  });

  group('Demonstration (hors production)', () {
    testWidgets('la coquille de demonstration rend la vraie page, montants '
        'masques puis affiches', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hote(const CoquilleComptableDemo(ecran: EcranDemoComptable.tresorerie)),
      );
      await stabiliser(tester);
      expect(find.byType(TresoreriePage), findsOneWidget);
      expect(_coquille(tester).indexActif, 2);
      // Le repere « Demonstration » fusionne la semantique sous lui : on lit
      // le libelle du bouton lui-meme.
      expect(
        tester
            .widget<BoutonIcone>(find.byKey(BasculeMontants.cleBouton))
            .libelle,
        t.comptable.commun.afficherMontants,
      );

      await tester.pumpWidget(
        hote(
          const CoquilleComptableDemo(
            ecran: EcranDemoComptable.aujourdhui,
            montantsAffiches: true,
          ),
        ),
      );
      await stabiliser(tester);
      expect(find.byType(AujourdhuiComptablePage), findsOneWidget);
      expect(find.text(t.comptable.commun.montantsAffiches), findsOneWidget);
    });

    testWidgets('la liste de la demonstration nomme chaque ecran', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(hote(const DemoComptablePage()));
      await stabiliser(tester);
      for (final EcranDemoComptable e in EcranDemoComptable.values) {
        expect(
          find.byKey(ValueKey<String>('lien-${e.name}-masques')),
          findsOneWidget,
        );
      }
    });
  });
}
