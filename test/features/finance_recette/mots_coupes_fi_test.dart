// R8-03 (revue FI-VAGUE-R) : la regle « aucun mot coupe a 320 px et 200 % »
// (lecon 8, K-54, K-61) mesuree sur CHAQUE ecran Finance, dans sa
// composition reelle : la coquille comprise (vrai routeur, coquilles de
// demonstration de l'adulte, de l'enseignant et de la direction), avec les
// VRAIES polices du depot. Les tests a 320 px de chaque ecran ne verifiaient
// que l'absence d'exception : une coupure en plein mot n'en leve pas
// (« Politiques / commerci / ales », R8-02).
//
// Exception ecrite : la barre basse de la coquille (`nav_shell.dart`) est
// hors de cette vague (R5-07 / R8-01, lot navigation et accessibilite). Ses
// libelles sont exclus de la mesure, et SEULEMENT eux.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_finance_direction.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart'
    show OngletFinance;
import 'package:rewayah_academy/features/demo/adulte_demo.dart'
    show EtatDemoAdulte;
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';
import 'package:rewayah_academy/features/revenus_enseignant/revenus_enseignant_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show stabiliser;
import '../../support/harnais.dart'
    show FauxServiceReseau, sansPersonneConnectee;
import '../../support/mots_coupes.dart';
import 'support_recette_fi.dart';

const String _ibrahim = DonneesFinanceDemo.ibrahimId;
const String _aicha = DonneesFinanceDemo.aichaId;
const JeuFoyerFinance _reg = JeuFoyerFinance.unARegulariser;

/// La vue de mesure : 320 de large, haute pour que tout le contenu soit
/// pose (une liste paresseuse ne construit que ce qui est visible).
const Size _vue = Size(320, 6000);

/// Les ports de production (neutres) du tuteur : l'etat honnete
/// « pas encore disponible » de chaque ecran.
final List<Override> _productionTuteur = <Override>[
  portPaiementsFoyerProvider.overrideWithValue(
    const PaiementsFoyerIndisponible(),
  ),
  portRechargeFoyerProvider.overrideWithValue(
    const RechargeFoyerIndisponible(),
  ),
  portAccesFoyerProvider.overrideWithValue(const AccesFoyerIndisponible()),
];

/// Les libelles de la barre basse de la coquille, hors vague (R8-01).
final Finder _barreBasse = find.byWidgetPredicate(
  (Widget w) => w.runtimeType.toString() == '_BarreFlottante',
);

/// Le cours en direct de l'enfant (accueil de l'eleve).
Seance _coursEnDirect(String eleveId) {
  final DateTime maintenant = DateTime.now();
  return Seance(
    id: 'r8-03-direct',
    debut: maintenant.subtract(const Duration(minutes: 10)),
    fin: maintenant.add(const Duration(minutes: 50)),
    statut: StatutSeance.enCours,
    eleveId: eleveId,
    elevePrenom: 'Ibrahim',
    eleveIdentifiant: 'STUD-FI-$eleveId',
    enseignantId: 't1',
    enseignantPrenom: 'Aminata',
    enseignantIdentifiant: 'TEACH-FI-000001',
  );
}

/// Monte la coquille de demonstration de la direction (`/demo/finance`) sur
/// l'onglet [onglet] : le `PageShell` sans en-tete riche de R8-02.
Future<void> _monterDemoFinance(
  WidgetTester tester,
  OngletFinance onglet,
) async {
  tester.view.physicalSize = _vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoFinance(onglet),
    routes: routesDemoFinance('staging'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
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
}

/// Monte l'ecran [page] seul, sur ses ports de PRODUCTION (aucune
/// surcharge de port) : l'etat honnete « pas encore disponible » que la
/// personne verra tant que la source manque. Les demonstrations surchargent
/// ces ports a l'interieur de leur coquille ; leur etat de production ne se
/// mesure donc que l'ecran monte seul.
Future<void> _monterProduction(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = _vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sansPersonneConnectee(),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: page,
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

typedef _Cas = ({String nom, Future<void> Function(WidgetTester) monter});

_Cas _tuteur(
  String nom,
  String depart, {
  JeuFoyerFinance jeu = _reg,
  List<Override> surcharges = const <Override>[],
}) => (
  nom: nom,
  monter: (WidgetTester tester) => monterTuteurFi(
    tester,
    jeu: jeu,
    depart: depart,
    surcharges: surcharges,
    taille: _vue,
  ),
);

_Cas _adulte(String nom, EcranDemoAdulte ecran, {bool aRegulariser = false}) =>
    (
      nom: nom,
      monter: (WidgetTester tester) => monterAdulteFi(
        tester,
        adresseDemoAdulte(
          ecran,
          etat: EtatDemoAdulte.adulteSeul,
          financeARegulariser: aRegulariser,
        ),
        taille: _vue,
      ),
    );

_Cas _admin(String nom, String depart, {List<Override>? surcharges}) => (
  nom: nom,
  monter: (WidgetTester tester) => monterAdminFi(
    tester,
    depart: depart,
    surcharges: surcharges ?? const <Override>[],
    taille: _vue,
  ),
);

final List<_Cas> _cas = <_Cas>[
  // Foyer (FI-4, FI-5).
  _tuteur('Foyer, a regulariser', Routes.tuteurFoyer),
  _tuteur(
    'Foyer, cinq profils',
    Routes.tuteurFoyer,
    jeu: JeuFoyerFinance.cinqProfils,
  ),
  _tuteur(
    'Foyer, production',
    Routes.tuteurFoyer,
    surcharges: _productionTuteur,
  ),
  // Fiche > Finances (FI-6a).
  _tuteur(
    'Finances, a regulariser',
    Routes.ficheEleveSousPage(_ibrahim, 'finances'),
  ),
  _tuteur(
    'Finances, essai',
    Routes.ficheEleveSousPage(_aicha, 'finances'),
    jeu: JeuFoyerFinance.unEnEssai,
  ),
  _tuteur(
    'Finances, production',
    Routes.ficheEleveSousPage(_ibrahim, 'finances'),
    surcharges: _productionTuteur,
  ),
  // Fiche > Mouvements (FI-6b).
  _tuteur(
    'Mouvements, a regulariser',
    Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
  ),
  _tuteur(
    'Mouvements, production',
    Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
    surcharges: _productionTuteur,
  ),
  // Recharge (FI-7).
  _tuteur('Recharge, etape 1', Routes.rechargePour(<String>[_ibrahim])),
  _tuteur(
    'Recharge, production',
    Routes.tuteurFoyerRecharge,
    surcharges: _productionTuteur,
  ),
  // Resultat (FI-8).
  for (final EtatPaiement e in <EtatPaiement>[
    EtatPaiement.termine,
    EtatPaiement.attenteConfirmation,
    EtatPaiement.echec,
    EtatPaiement.perime,
  ])
    _tuteur(
      'Resultat, ${e.name}',
      Routes.resultatRechargePour(DonneesFinanceDemo.commandeDemo(e)),
    ),
  _tuteur(
    'Resultat, production',
    Routes.resultatRechargePour(
      DonneesFinanceDemo.commandeDemo(EtatPaiement.termine),
    ),
    surcharges: _productionTuteur,
  ),
  // Acces (FI-9a) : fiche, Compte, enfant.
  _tuteur(
    'Acces fiche, a regulariser',
    Routes.ficheEleveSousPage(_ibrahim, 'acces'),
  ),
  _tuteur(
    'Acces fiche, essai',
    Routes.ficheEleveSousPage(_aicha, 'acces'),
    jeu: JeuFoyerFinance.unEnEssai,
  ),
  _tuteur('Acces Compte, a regulariser', Routes.compteTuteurSousPage('acces')),
  _tuteur(
    'Acces Compte, production',
    Routes.compteTuteurSousPage('acces'),
    surcharges: _productionTuteur,
  ),
  (
    nom: 'Acces enfant, ferme',
    monter: (WidgetTester tester) => monterEleveFi(
      tester,
      Routes.eleve,
      profilId: _ibrahim,
      seances: <Seance>[_coursEnDirect(_ibrahim)],
      surcharges: <Override>[
        portMonAccesProvider.overrideWithValue(
          const MonAccesFinanceDemo(_reg, _ibrahim),
        ),
      ],
      taille: _vue,
    ),
  ),
  // Mes finances de l'adulte autonome (FI-9b).
  _adulte('Adulte, Mon espace', EcranDemoAdulte.monEspace),
  _adulte('Adulte, paiements', EcranDemoAdulte.paiements),
  _adulte(
    'Adulte, paiements a regulariser',
    EcranDemoAdulte.paiements,
    aRegulariser: true,
  ),
  _adulte('Adulte, mouvements', EcranDemoAdulte.mesMouvements),
  _adulte('Adulte, recharge', EcranDemoAdulte.maRecharge),
  (
    nom: 'Adulte, Mes finances, production',
    monter: (WidgetTester tester) => _monterProduction(
      tester,
      MesFinancesPage(
        onRetour: () {},
        onRecharger: (String _) {},
        onMouvements: () {},
      ),
    ),
  ),
  (
    nom: 'Adulte, Mes mouvements, production',
    monter: (WidgetTester tester) =>
        _monterProduction(tester, MesMouvementsPage(onRetour: () {})),
  ),
  // Revenus de l'enseignant (FI-10).
  (
    nom: 'Revenus enseignant',
    monter: (WidgetTester tester) => monterEnseignantFi(tester, taille: _vue),
  ),
  (
    nom: 'Revenus enseignant, production',
    monter: (WidgetTester tester) =>
        _monterProduction(tester, const RevenusEnseignantPage()),
  ),
  // Vue globale et Politiques (FI-11) : coquille admin, puis la
  // demonstration `/demo/finance` (R8-02).
  _admin('Vue globale', Routes.adminFinance),
  _admin(
    'Vue globale, production',
    Routes.adminFinance,
    surcharges: <Override>[
      portFinanceDirectionProvider.overrideWithValue(
        const FinanceDirectionIndisponible(),
      ),
    ],
  ),
  _admin('Politiques', Routes.adminFinancePolitiques),
  _admin(
    'Politiques, production',
    Routes.adminFinancePolitiques,
    surcharges: <Override>[
      portPolitiquesCommercialesProvider.overrideWithValue(
        const PolitiquesCommercialesIndisponibles(),
      ),
    ],
  ),
  for (final OngletFinance o in OngletFinance.values)
    (
      nom: 'Demonstration Finance, ${o.name}',
      monter: (WidgetTester tester) => _monterDemoFinance(tester, o),
    ),
];

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('R8-03 : aucun mot coupe a 320 px et 200 %, coquille comprise', () {
    for (final _Cas cas in _cas) {
      testWidgets(cas.nom, (WidgetTester tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await cas.monter(tester);
        expect(tester.takeException(), isNull);
        expect(
          motsCoupes(tester, find.byType(MaterialApp), sauf: _barreBasse),
          isEmpty,
        );
        // Demonte avant la fin : aucune minuterie ne reste en suspens.
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}
