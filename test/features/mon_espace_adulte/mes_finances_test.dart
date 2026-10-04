// FI-9b (guide Finance V4 §4 « Eleve adulte », FI-BR-17, K-53.8) : les
// finances de l'eleve adulte autonome, atteintes depuis la VRAIE coquille
// adulte (Mon espace > Paiements) ; solde, periode, prochain debit,
// mensualite et mouvements de son SEUL profil ; « Recharger » ouvre LE
// moteur du foyer, son seul profil coche ; aucune donnee d'un autre membre
// lue ni affichee ; etats chargement, contenu, vide, erreur, hors ligne et
// production ; 320 px texte x2 et 1440 px, clair et sombre, LTR et RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_mes_finances.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/badge_periode_financee.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/ligne_finance.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/core/widgets/montant_argent.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/fiche/mouvements_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart'
    show dateEcheance;
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mon_espace_adulte_page.dart';

import '../../router/support_routeur.dart' show stabiliser;
import '../../support/garde_interface.dart';

/// La finance de Mamadou, adulte seul, telle que la demonstration la rend.
final FinancesProfil _mamadou = DonneesFinanceDemo.financesAdulte(
  profilId: DonneesAdulteDemo.mamadouId,
  prenom: 'Mamadou',
  classe: DonneesAdulteDemo.classeTitulaire,
);

/// Les prenoms des autres membres : ceux du foyer de demonstration de la
/// Finance (rendus par l'espion) et ceux du foyer Diallo.
const List<String> _autres = <String>[
  'Mariam',
  'Ibrahim',
  'Aïcha',
  'Mariama',
  'Oumar',
];

/// Le port des paiements du FOYER, espion : il rend le foyer entier, et
/// compte chaque lecture. L'ecran de l'adulte ne doit jamais l'appeler.
class _PaiementsFoyerEspion implements PortPaiementsFoyer {
  final List<String> appels = <String>[];

  @override
  Future<FinancesFoyer> finances() async {
    appels.add('finances');
    return DonneesFinanceDemo.finances(JeuFoyerFinance.tousFinances);
  }

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) async {
    appels.add('mouvements $profilId');
    return DonneesFinanceDemo.mouvements(
      JeuFoyerFinance.tousFinances,
      profilId,
    );
  }

  @override
  Future<List<PaiementFoyer>> historique() async {
    appels.add('historique');
    return <PaiementFoyer>[];
  }

  @override
  Future<PaiementFoyer?> detail(String id) async => null;

  @override
  Future<SoldesFoyer> soldes() async {
    appels.add('soldes');
    return const SoldesFoyer(beneficiaires: <SoldeBeneficiaire>[]);
  }
}

/// Un port de mes finances qui rend [lecture] et [mouvements].
class _PortMesFinances implements PortMesFinances {
  _PortMesFinances(this.lecture, {this.lectureMouvements});

  final Future<FinancesProfil?> Function() lecture;
  final Future<List<MouvementProfil>> Function()? lectureMouvements;

  @override
  Future<FinancesProfil?> finances() => lecture();

  @override
  Future<List<MouvementProfil>> mouvements() =>
      lectureMouvements?.call() ??
      Future<List<MouvementProfil>>.value(
        DonneesFinanceDemo.mouvementsAdulte(_mamadou),
      );
}

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

void _aucunAutreMembre() {
  for (final String prenom in _autres) {
    expect(find.textContaining(prenom), findsNothing, reason: prenom);
  }
}

void main() {
  void taille(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// La VRAIE coquille adulte de la demonstration, a l'adresse [depart]. Le
  /// conteneur racine porte l'espion du foyer et la recharge du FOYER de
  /// demonstration : si l'ecran de l'adulte les lisait, il les trouverait.
  Future<GoRouter> monterCoquille(
    WidgetTester tester,
    String depart, {
    _PaiementsFoyerEspion? espion,
  }) async {
    final GoRouter routeur = GoRouter(
      initialLocation: depart,
      routes: routesDemoAdulte('dev'),
    );
    addTearDown(routeur.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            espion ?? _PaiementsFoyerEspion(),
          ),
          portRechargeFoyerProvider.overrideWithValue(
            const RechargeFoyerFinanceDemo(),
          ),
        ],
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
    await stabiliser(tester);
    return routeur;
  }

  Future<void> toucher(WidgetTester tester, Finder cible) async {
    await tester.ensureVisible(cible);
    await stabiliser(tester);
    await tester.tap(cible);
    await stabiliser(tester);
  }

  group('Chemin depuis la coquille adulte', () {
    testWidgets('Mon espace > Paiements : solde, periode, prochain debit et '
        'mensualite du seul adulte ; rien d\'un autre membre lu', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 2400));
      final _PaiementsFoyerEspion espion = _PaiementsFoyerEspion();
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.monEspace,
          etat: EtatDemoAdulte.adulteSeul,
        ),
        espion: espion,
      );
      expect(find.byType(MonEspaceAdultePage), findsOneWidget);
      // La rubrique suit la source de la page d'arrivee : rendue, donc
      // jamais « Non disponible ».
      expect(
        find.descendant(
          of: find
              .ancestor(
                of: find.text(t.adulte.monEspace.paiements),
                matching: find.byType(Pressable),
              )
              .first,
          matching: find.text(t.compte.nonDisponible),
        ),
        findsNothing,
      );

      await toucher(tester, find.text(t.adulte.monEspace.paiements));
      expect(find.byType(MesFinancesPage), findsOneWidget);
      expect(find.byType(PaiementsComptePage), findsNothing);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 3);

      // Le seul profil de l'adulte, ses valeurs rendues.
      expect(find.text('Mamadou'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is MontantArgent && w.montant == _mamadou.solde,
        ),
        findsOneWidget,
      );
      expect(find.byType(BadgePeriodeFinancee), findsOneWidget);
      expect(
        find.text(
          t.foyer.finances.prochainDebitValeur(
            date: dateEcheance(_mamadou.prochainDebit!.date),
            montant: formaterMontant(_mamadou.prochainDebit!.montant),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.ficheEleve.finances.mensualiteValeur(
            montant: formaterMontant(_mamadou.mensualite),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is LigneFinance &&
              w.libelle == t.ficheEleve.finances.tarifAdulte,
        ),
        findsOneWidget,
      );
      expect(find.text(t.ficheEleve.finances.remiseRang), findsNothing);
      verifierUnSeulBoutonPlein(tester);

      _aucunAutreMembre();
      expect(espion.appels, isEmpty);

      // Retour vers Mon espace.
      await toucher(tester, find.byType(DisqueRetour));
      expect(find.byType(MonEspaceAdultePage), findsOneWidget);
    });

    testWidgets('Mouvements : l\'historique du seul adulte, sans filtre par '
        'personne, puis retour aux Paiements', (WidgetTester tester) async {
      taille(tester, const Size(390, 2400));
      final _PaiementsFoyerEspion espion = _PaiementsFoyerEspion();
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.paiements,
          etat: EtatDemoAdulte.adulteSeul,
        ),
        espion: espion,
      );
      await toucher(tester, find.byKey(FinancesElevePage.mouvementsKey));
      expect(find.byType(MesMouvementsPage), findsOneWidget);
      expect(find.text(t.adulte.finances.mouvementsContexte), findsOneWidget);
      expect(find.byKey(MouvementsElevePage.filtreKey), findsNothing);
      final List<MouvementProfil> attendus =
          DonneesFinanceDemo.mouvementsAdulte(_mamadou);
      expect(attendus, isNotEmpty);
      expect(find.byType(LigneTransaction), findsNWidgets(attendus.length));
      // Le recu ne repartit le paiement que sur lui.
      final MouvementProfil recharge = attendus.firstWhere(
        (MouvementProfil m) => m.recu != null,
      );
      expect(
        recharge.recu!.allocations.map((AllocationProfil a) => a.profilId),
        <String>[DonneesAdulteDemo.mamadouId],
      );
      await toucher(
        tester,
        find.byKey(MouvementsElevePage.voirRecuKey(recharge.id)),
      );
      expect(find.byKey(MouvementsElevePage.recuKey), findsOneWidget);
      _aucunAutreMembre();
      expect(espion.appels, isEmpty);
      Navigator.of(tester.element(find.byKey(MouvementsElevePage.recuKey)))
          .pop();
      await stabiliser(tester);

      await toucher(tester, find.byType(DisqueRetour).first);
      expect(find.byType(MesFinancesPage), findsOneWidget);
    });

    testWidgets('« Recharger » ouvre LE moteur du foyer, son seul profil '
        'coche, et aucun autre beneficiaire', (WidgetTester tester) async {
      taille(tester, const Size(390, 2400));
      final _PaiementsFoyerEspion espion = _PaiementsFoyerEspion();
      final GoRouter routeur = await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.paiements,
          etat: EtatDemoAdulte.adulteSeul,
        ),
        espion: espion,
      );
      await toucher(tester, find.byKey(FinancesElevePage.rechargerKey));
      final RechargeFoyerPage page = tester.widget<RechargeFoyerPage>(
        find.byType(RechargeFoyerPage),
      );
      expect(page.preselection, <String>{DonneesAdulteDemo.mamadouId});
      expect(
        routeur
            .routerDelegate
            .currentConfiguration
            .uri
            .queryParameters['ecran'],
        EcranDemoAdulte.maRecharge.name,
      );
      expect(
        find.byKey(RechargeFoyerPage.profilDe(DonneesAdulteDemo.mamadouId)),
        findsOneWidget,
      );
      for (final String id in <String>[
        DonneesFinanceDemo.mariamId,
        DonneesFinanceDemo.ibrahimId,
        DonneesFinanceDemo.aichaId,
      ]) {
        expect(find.byKey(RechargeFoyerPage.profilDe(id)), findsNothing);
      }
      _aucunAutreMembre();
      expect(espion.appels, isEmpty);

      // Le moteur verifie le recapitulatif de ce seul profil.
      await toucher(
        tester,
        find.byKey(RechargeFoyerPage.plusDe(DonneesAdulteDemo.mamadouId)),
      );
      await toucher(tester, find.byKey(RechargeFoyerPage.verifierKey));
      expect(
        find.byKey(RechargeFoyerPage.ligneDe(DonneesAdulteDemo.mamadouId)),
        findsOneWidget,
      );
      expect(find.byKey(RechargeFoyerPage.totalKey), findsOneWidget);
      _aucunAutreMembre();
    });

    testWidgets('second adulte qui n\'est plus rattache : un adulte autonome, '
        'ses propres finances', (WidgetTester tester) async {
      taille(tester, const Size(390, 2400));
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.paiements,
          etat: EtatDemoAdulte.conjointQuitte,
          vue: VueDemoAdulte.secondAdulte,
        ),
      );
      expect(find.byType(MesFinancesPage), findsOneWidget);
      expect(find.text('Mariama'), findsWidgets);
      expect(find.textContaining('Mamadou'), findsNothing);
      await toucher(tester, find.byKey(FinancesElevePage.rechargerKey));
      expect(
        tester
            .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
            .preselection,
        <String>{DonneesAdulteDemo.mariamaId},
      );
    });

    testWidgets('titulaire d\'une famille : Paiements reste la page des '
        'paiements ; mes mouvements et ma recharge lui sont fermes', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 2400));
      await monterCoquille(
        tester,
        adresseDemoAdulte(EcranDemoAdulte.paiements),
      );
      expect(find.byType(PaiementsComptePage), findsOneWidget);
      expect(find.byType(MesFinancesPage), findsNothing);
      for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
        EcranDemoAdulte.mesMouvements,
        EcranDemoAdulte.maRecharge,
      ]) {
        expect(
          ecranPermisDemoAdulte(
            ecran,
            EtatDemoAdulte.conjointActif,
            VueDemoAdulte.titulaire,
          ),
          EcranDemoAdulte.monEspace,
        );
        expect(
          ecranPermisDemoAdulte(
            ecran,
            EtatDemoAdulte.conjointActif,
            VueDemoAdulte.secondAdulte,
          ),
          EcranDemoAdulte.monEspace,
        );
        expect(
          ecranPermisDemoAdulte(
            ecran,
            EtatDemoAdulte.adulteSeul,
            VueDemoAdulte.titulaire,
          ),
          ecran,
        );
      }
    });

    testWidgets('reseau coupe : Paiements dit hors ligne', (
      WidgetTester tester,
    ) async {
      taille(tester, const Size(390, 2400));
      await monterCoquille(
        tester,
        adresseDemoAdulte(
          EcranDemoAdulte.paiements,
          etat: EtatDemoAdulte.adulteSeul,
          reseauCoupe: true,
        ),
      );
      expect(find.byType(MesFinancesPage), findsOneWidget);
      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
    });
  });

  /// Une page seule, avec son port de mes finances.
  Future<void> monterPage(
    WidgetTester tester,
    Widget page, {
    PortMesFinances? port,
    bool horsLigne = false,
    Size dimension = const Size(390, 2400),
    double echelle = 1,
    Brightness luminosite = Brightness.light,
    TextDirection sens = TextDirection.ltr,
  }) async {
    taille(tester, dimension);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          horsLigneProvider.overrideWith(
            (Ref _) => Stream<bool>.value(horsLigne),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            const PolitiquesCommercialesDemo(),
          ),
          portPaiementsFoyerProvider.overrideWithValue(_PaiementsFoyerEspion()),
          if (port != null) portMesFinancesProvider.overrideWithValue(port),
        ],
        child: TranslationProvider(
          child: MediaQuery(
            data: MediaQueryData(
              size: dimension,
              textScaler: TextScaler.linear(echelle),
            ),
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, luminosite),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext _, Widget? enfant) =>
                  Directionality(textDirection: sens, child: enfant!),
              home: page,
            ),
          ),
        ),
      ),
    );
    await stabiliser(tester);
  }

  final Widget finances = MesFinancesPage(
    onRetour: () {},
    onRecharger: (String _) {},
    onMouvements: () {},
  );
  final Widget mouvements = MesMouvementsPage(onRetour: () {});

  group('Etats de Mes finances', () {
    testWidgets('chargement : squelette, puis contenu', (
      WidgetTester tester,
    ) async {
      final Completer<FinancesProfil?> attente = Completer<FinancesProfil?>();
      await monterPage(
        tester,
        finances,
        port: _PortMesFinances(() => attente.future),
      );
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byKey(FinancesElevePage.vueKey), findsNothing);
      attente.complete(_mamadou);
      await stabiliser(tester);
      expect(find.byKey(FinancesElevePage.vueKey), findsOneWidget);
    });

    testWidgets('erreur : titre a la deuxieme personne, « Reessayer » relit', (
      WidgetTester tester,
    ) async {
      bool echoue = true;
      await monterPage(
        tester,
        finances,
        port: _PortMesFinances(() async {
          if (echoue) throw Exception('lecture refusee');
          return _mamadou;
        }),
      );
      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      expect(find.text(t.adulte.finances.erreurTitre), findsOneWidget);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      echoue = false;
      await stabiliser(tester);
      expect(find.byKey(FinancesElevePage.vueKey), findsOneWidget);
    });

    testWidgets('hors ligne : dit hors ligne, pas echec du serveur', (
      WidgetTester tester,
    ) async {
      await monterPage(
        tester,
        finances,
        port: _PortMesFinances(() async => throw Exception('reseau')),
        horsLigne: true,
      );
      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
    });

    testWidgets('production : « pas encore disponible », aucun montant ni '
        'bouton, et le port du foyer jamais lu', (WidgetTester tester) async {
      await monterPage(tester, finances);
      expect(_etat(NatureEtat.indisponible), findsOneWidget);
      expect(find.text(t.adulte.finances.indisponibleTitre), findsOneWidget);
      expect(find.byType(LigneFinance), findsNothing);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
    });

    testWidgets('vide : aucune finance rendue pour son profil', (
      WidgetTester tester,
    ) async {
      await monterPage(
        tester,
        finances,
        port: _PortMesFinances(() async => null),
      );
      expect(_etat(NatureEtat.aucunResultat), findsOneWidget);
      expect(find.text(t.adulte.finances.videTitre), findsOneWidget);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
    });
  });

  group('Etats de Mes mouvements', () {
    testWidgets('chargement puis contenu', (WidgetTester tester) async {
      final Completer<List<MouvementProfil>> attente =
          Completer<List<MouvementProfil>>();
      await monterPage(
        tester,
        mouvements,
        port: _PortMesFinances(
          () async => _mamadou,
          lectureMouvements: () => attente.future,
        ),
      );
      expect(find.byType(Skeleton), findsWidgets);
      attente.complete(DonneesFinanceDemo.mouvementsAdulte(_mamadou));
      await stabiliser(tester);
      expect(find.byKey(MouvementsElevePage.listeKey), findsOneWidget);
    });

    testWidgets('erreur : titre a la deuxieme personne', (
      WidgetTester tester,
    ) async {
      await monterPage(
        tester,
        mouvements,
        port: _PortMesFinances(
          () async => _mamadou,
          lectureMouvements: () async => throw Exception('refus'),
        ),
      );
      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      expect(
        find.text(t.adulte.finances.mouvementsErreurTitre),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne', (WidgetTester tester) async {
      await monterPage(
        tester,
        mouvements,
        horsLigne: true,
        port: _PortMesFinances(
          () async => _mamadou,
          lectureMouvements: () async => throw Exception('reseau'),
        ),
      );
      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
    });

    testWidgets('production : « pas encore disponible »', (
      WidgetTester tester,
    ) async {
      await monterPage(tester, mouvements);
      expect(_etat(NatureEtat.indisponible), findsOneWidget);
      expect(
        find.text(t.adulte.finances.mouvementsIndisponiblePhrase),
        findsOneWidget,
      );
    });

    testWidgets('vide', (WidgetTester tester) async {
      await monterPage(
        tester,
        mouvements,
        port: _PortMesFinances(
          () async => _mamadou,
          lectureMouvements: () async => <MouvementProfil>[],
        ),
      );
      expect(_etat(NatureEtat.aucunResultat), findsOneWidget);
      expect(find.text(t.adulte.finances.mouvementsVidePhrase), findsOneWidget);
    });
  });

  group('Gabarits', () {
    for (final (double, double) cas in const <(double, double)>[
      (320, 2),
      (1440, 1),
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        for (final TextDirection sens in TextDirection.values) {
          final String nom =
              '${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
              '${luminosite.name}, ${sens.name}';
          testWidgets('Mes finances, $nom : aucun debordement', (
            WidgetTester tester,
          ) async {
            await monterPage(
              tester,
              finances,
              port: _PortMesFinances(() async => _mamadou),
              dimension: Size(cas.$1, 3000),
              echelle: cas.$2,
              luminosite: luminosite,
              sens: sens,
            );
            expect(tester.takeException(), isNull);
            expect(find.byKey(FinancesElevePage.vueKey), findsOneWidget);
            verifierUnSeulBoutonPlein(tester);
          });
          testWidgets('Mes mouvements, $nom : aucun debordement', (
            WidgetTester tester,
          ) async {
            await monterPage(
              tester,
              mouvements,
              port: _PortMesFinances(() async => _mamadou),
              dimension: Size(cas.$1, 3000),
              echelle: cas.$2,
              luminosite: luminosite,
              sens: sens,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(
                cas.$1 >= 1440
                    ? MouvementsElevePage.tableauKey
                    : MouvementsElevePage.listeKey,
              ),
              findsOneWidget,
            );
            verifierUnSeulBoutonPlein(tester, maximum: 0);
          });
        }
      }
    }
  });
}
