// FI-12 : outils partages des tests de recette Finance (recette_fi_test.dart,
// recette_fi_roles_test.dart). Chaque montage part de la VRAIE coquille :
// le vrai routeur (`routeurProvider`, `RewayahApp`) branche sur les
// demonstrations, ou la coquille de demonstration de l'eleve adulte et de
// l'enseignant, qui posent les vraies pages.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/tc_coran/corpus_service_coran.dart';
import 'package:rewayah_academy/core/tc_coran/layout_lignes_indisponible.dart';
import 'package:rewayah_academy/core/tc_coran/navigation_coran.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/demonstration_horloge.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/demo_adulte_page.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart'
    show EcranDemoEnseignant;
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart'
    show horlogeFoyerProvider;

import '../../parcours/faux_service_offres.dart';
import '../../router/support_routeur.dart' show stabiliser;
import '../../support/harnais.dart';
import '../../teaching_core/c/faux/faux_corpus_coran.dart';
import '../../teaching_core/c/goldens/corpus_reference.dart';

/// Le corpus de reference du Coran, lu une fois.
final CorpusReference _corpusReference = CorpusReference.charger();

/// Le 4 octobre 2026 a midi, le mois de reference de la demonstration.
final DateTime maintenantFi = DateTime(2026, 10, 4, 12);

/// Monte l'application du tuteur de la demonstration Finance sur le VRAI
/// routeur, puis va a [depart]. [surcharges] ne touche que des lectures que
/// la demonstration ne surcharge pas (pannes, politique injectee, espions).
/// [sansRetentative] coupe les nouvelles tentatives silencieuses de
/// Riverpod 3 : seul « Reessayer » peut alors relire.
Future<GoRouter> monterTuteurFi(
  WidgetTester tester, {
  JeuFoyerFinance jeu = JeuFoyerFinance.unARegulariser,
  String depart = Routes.tuteurFoyer,
  List<EleveDuFoyer>? eleves,
  List<Override> surcharges = const <Override>[],
  bool sansRetentative = false,
  Size taille = const Size(390, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Un nouveau conteneur a chaque montage : un ProviderScope reconstruit au
  // meme endroit garderait les surcharges du montage precedent.
  await tester.pumpWidget(const SizedBox.shrink());
  final Set<Object> remplaces = <Object>{
    for (final Override o in surcharges) o.origin,
  };
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      retry: sansRetentative ? (int _, Object _) => null : null,
      overrides: <Override>[
        // Une surcharge du test remplace celle de la demonstration du meme
        // fournisseur (un port espion a la place du double) : un conteneur
        // refuse deux surcharges d'un fournisseur.
        ...surchargesDemoTuteur(
          environnement: 'staging',
          finances: jeu,
          eleves: eleves,
        ).where((Override o) => !remplaces.contains(o.origin)),
        horlogeFoyerProvider.overrideWithValue(() => maintenantFi),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Monte la VRAIE application de la direction en demonstration
/// (`?demo=admin`), puis va a [depart].
Future<GoRouter> monterAdminFi(
  WidgetTester tester, {
  String depart = Routes.adminFinancePolitiques,
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(1440, 3200),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging').where(
          (Override o) =>
              !<Object>{for (final Override s in surcharges) s.origin}
                  .contains(o.origin),
        ),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Monte la VRAIE coquille de l'eleve adulte de la demonstration
/// (`/demo/adulte`) a l'adresse [adresse]. [surcharges] va au conteneur
/// racine : un espion y voit toute lecture que la coquille ne surcharge pas.
Future<GoRouter> monterAdulteFi(
  WidgetTester tester,
  String adresse, {
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(390, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  final GoRouter routeur = GoRouter(
    initialLocation: adresse,
    routes: routesDemoAdulte('staging'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      // La source de session, comme l'application la pose toujours
      // (`main.dart`) : les lectures d'argent suivent la personne connectee
      // (R7-04).
      overrides: <Override>[sansPersonneConnectee(), ...surcharges],
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

/// Monte la VRAIE coquille de l'enseignant de la demonstration, sur
/// [ecran].
Future<GoRouter> monterEnseignantFi(
  WidgetTester tester, {
  EcranDemoEnseignant ecran = EcranDemoEnseignant.revenus,
  Size taille = const Size(390, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoEnseignant(ecran),
    routes: routesDemoEnseignant('staging'),
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
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
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return routeur;
}

/// Monte l'application de l'eleve ENFANT [profilId] sur le VRAI routeur
/// (coquille de l'eleve, garde de role comprise), avec les groupes de la
/// demonstration, puis va a [depart]. [surcharges] porte l'acces rendu et
/// les espions.
Future<GoRouter> monterEleveFi(
  WidgetTester tester,
  String depart, {
  required String profilId,
  List<Override> surcharges = const <Override>[],
  List<Seance> seances = const <Seance>[],
  Size taille = const Size(390, 1400),
}) async {
  // L'horloge des groupes de la demonstration, comme `hoteTcA` : une seance
  // en cours, sans cadence.
  final HorlogeSeanceDemonstration horloges = HorlogeSeanceDemonstration(
    cadence: Duration.zero,
  );
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox.shrink());
  final SessionState session = SessionState(
    resolue: true,
    role: AppRole.student,
    profileId: profilId,
    householdId: 'h1',
    accountStatus: AccountStatus.active,
    interfaceMode: InterfaceMode.enfant,
    lectureProfil: LectureProfil.presente,
  );
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        // Les faux de `surchargesRouteur`, sauf les groupes et leur horloge :
        // ceux de la demonstration, pour que « Mes groupes » ait des cartes.
        sourceSessionProvider.overrideWithValue(FausseSourceSession(session)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        servicePlanningProvider.overrideWithValue(
          FauxServicePlanning()..seancesRendues = seances,
        ),
        serviceAppairageProvider.overrideWithValue(FauxServiceAppairage()),
        serviceAvatarProvider.overrideWithValue(FauxServiceAvatar()),
        serviceSuiviProvider.overrideWithValue(FauxServiceSuivi()),
        serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
        serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
        servicePriereProvider.overrideWithValue(FauxServicePriere()),
        serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
        serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
        servicePresenceProvider.overrideWithValue(FauxServicePresence()),
        serviceVideoProvider.overrideWithValue(FauxServiceVideo()),
        serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
        serviceOffresProvider.overrideWithValue(FauxServiceOffres()),
        portGroupesProvider.overrideWithValue(
          GroupesDemonstrationLocale(horloges: horloges),
        ),
        portHorlogeSeanceProvider.overrideWithValue(horloges),
        stockagePreferencesProvider.overrideWithValue(
          StockagePreferencesMemoire(),
        ),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        // Le Coran de l'eleve sur le corpus de reference des tests : son
        // service reel lit Supabase.
        portCorpusCoranProvider.overrideWithValue(
          FauxCorpusCoran(_corpusReference),
        ),
        portLayoutMushafProvider.overrideWithValue(
          const LayoutLignesIndisponible(),
        ),
        portNavigationCoranProvider.overrideWithValue(FauxNavigationCoran()),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Rend [cible] visible, la touche, puis laisse l'ecran se poser.
Future<void> toucherFi(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await stabiliser(tester);
}

/// Le chemin courant du routeur.
String cheminFi(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

/// L'adresse courante du routeur, requete comprise.
Uri adresseFi(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri;

/// [cible] sous [parent].
Finder dansFi(Finder parent, Finder cible) =>
    find.descendant(of: parent, matching: cible);

/// L'etat systeme de nature [nature].
Finder etatFi(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

/// La navigation rendue : barre basse, rail, barre laterale, ou aucune
/// (le tiroir de la direction, ferme, sur telephone).
enum NavigationFi { basse, rail, laterale, aucune }

/// La composition mesuree d'un ecran : combien de blocs se tiennent cote a
/// cote, la largeur du plus large, la largeur de la vue, la navigation.
@immutable
class CompositionFi {
  const CompositionFi({
    required this.colonnes,
    required this.largeurMax,
    required this.largeurVue,
    required this.navigation,
    required this.blocs,
  });

  /// Le plus grand nombre de blocs cote a cote (meme bande verticale,
  /// aucun recouvrement horizontal).
  final int colonnes;

  /// La largeur du plus large bloc.
  final double largeurMax;

  /// La largeur de la vue.
  final double largeurVue;

  /// La navigation rendue.
  final NavigationFi navigation;

  /// Le nombre de blocs mesures.
  final int blocs;

  @override
  String toString() =>
      'colonnes $colonnes, bloc le plus large ${largeurMax.round()} sur '
      '${largeurVue.round()}, navigation ${navigation.name}, $blocs blocs';
}

/// Mesure la composition des [blocs] rendus a l'ecran.
CompositionFi mesurerFi(WidgetTester tester, List<Finder> blocs) {
  final List<Rect> rects = <Rect>[
    for (final Finder f in blocs)
      for (final Element e in f.evaluate())
        if (e.renderObject case final RenderBox b when b.hasSize)
          b.localToGlobal(Offset.zero) & b.size,
  ];
  int colonnes = 0;
  for (final Rect r in rects) {
    // Les blocs de la meme bande que [r], ranges par bord droit : le plus
    // grand ensemble sans recouvrement horizontal (choix glouton).
    final List<Rect> bande =
        rects
            .where((Rect a) => a.top < r.bottom - 1 && r.top < a.bottom - 1)
            .toList()
          ..sort((Rect a, Rect b) => a.right.compareTo(b.right));
    int n = 0;
    double bord = double.negativeInfinity;
    for (final Rect a in bande) {
      if (a.left >= bord - 0.5) {
        n++;
        bord = a.right;
      }
    }
    if (n > colonnes) colonnes = n;
  }
  bool rendu(Key k) => find.byKey(k).evaluate().isNotEmpty;
  final NavigationFi navigation =
      rendu(NavShell.barreLateraleKey) || rendu(AdminShell.barreLateraleKey)
      ? NavigationFi.laterale
      : rendu(NavShell.railKey) || rendu(AdminShell.railKey)
      ? NavigationFi.rail
      : rendu(NavShell.barreBasseKey)
      ? NavigationFi.basse
      : NavigationFi.aucune;
  return CompositionFi(
    colonnes: colonnes,
    largeurMax: rects.fold<double>(
      0,
      (double m, Rect r) => r.width > m ? r.width : m,
    ),
    largeurVue: tester.view.physicalSize.width / tester.view.devicePixelRatio,
    navigation: navigation,
    blocs: rects.length,
  );
}

/// Le port des paiements du foyer de la demonstration, espion : il note
/// chaque lecture (`finances`, `soldes`, `mouvements`, `derniersMouvements`,
/// `historique`, `detail`) avant de rendre le jeu [jeu].
class PaiementsEspionFi extends PaiementsFoyerFinanceDemo {
  /// Cree l'espion.
  PaiementsEspionFi(super.jeu);

  /// Les lectures, dans l'ordre.
  final List<String> lectures = <String>[];

  /// Les lectures qui portent un solde, un montant ou une cause : celles
  /// qu'un second adulte ou un enfant ne doit jamais faire (lecon 15).
  Iterable<String> get lecturesFinancieres => lectures.where(
    (String l) => l != 'historique' && !l.startsWith('detail'),
  );

  @override
  Future<FinancesFoyer> finances() {
    lectures.add('finances');
    return super.finances();
  }

  @override
  Future<SoldesFoyer> soldes() {
    lectures.add('soldes');
    return super.soldes();
  }

  @override
  Future<List<MouvementProfil>> mouvements(String profilId) {
    lectures.add('mouvements $profilId');
    return super.mouvements(profilId);
  }

  @override
  Future<List<MouvementFoyer>> derniersMouvements({int limite = 3}) {
    lectures.add('derniersMouvements');
    return super.derniersMouvements(limite: limite);
  }

  @override
  Future<List<PaiementFoyer>> historique() {
    lectures.add('historique');
    return super.historique();
  }

  @override
  Future<PaiementFoyer?> detail(String id) {
    lectures.add('detail $id');
    return super.detail(id);
  }
}

/// Le port de recharge de la demonstration, espion : il note chaque
/// lecture des beneficiaires.
class RechargeEspionneFi extends RechargeFoyerFinanceDemo {
  /// Cree l'espion.
  RechargeEspionneFi(super.jeu);

  /// Le nombre de lectures des beneficiaires.
  int lecturesBeneficiaires = 0;

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() {
    lecturesBeneficiaires++;
    return super.beneficiaires();
  }
}
