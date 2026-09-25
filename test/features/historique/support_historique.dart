// Outils des tests de l'Historique du tuteur (lot E, sous-paquet 2).
//
// L'application se monte sur son VRAI routeur, avec la coquille du tuteur et
// le foyer fictif A ; les parcours se TOUCHENT depuis la barre de navigation
// (definition de « fait », registre section 5 bis). Donnees : fixtures de
// test isolees, aucun appel reseau, aucun Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/suivi_foyer/donnees_historique.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_observation.dart';
import '../../fixtures/tuteur/foyers.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// L'instant de reference, calcule une fois : l'ecran lit l'horloge reelle,
/// les seances fictives sont donc datees par rapport a maintenant.
final DateTime maintenantHistorique = DateTime.now();

/// Une seance passee de [eleve], commencee il y a [ilYAJours] jours a 18 h.
Seance seanceFictive({
  required String id,
  required int ilYAJours,
  EleveDuFoyer eleve = FoyersFictifs.a1,
  StatutSeance? statut = StatutSeance.terminee,
  String enseignantId = 'enseignant-x',
  String enseignantPrenom = 'Enseignant X',
  int minutes = 60,
  int interruption = 0,
}) {
  final DateTime jour = maintenantHistorique.subtract(
    Duration(days: ilYAJours),
  );
  final DateTime debut = DateTime(jour.year, jour.month, jour.day, 18);
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(Duration(minutes: minutes)),
    statut: statut,
    eleveId: eleve.id,
    elevePrenom: eleve.prenom,
    eleveIdentifiant: eleve.identifiantImmuable,
    enseignantId: enseignantId,
    enseignantPrenom: enseignantPrenom,
    enseignantIdentifiant: 'TEACH-FX-000001',
    minutesInterruption: interruption,
  );
}

/// La presence de [eleve] a [seance].
PresenceParticipant presenceFictive(
  Seance seance,
  EtatPresence etat, {
  EleveDuFoyer eleve = FoyersFictifs.a1,
  Duration? arriveeApres,
  bool consolide = false,
}) => PresenceParticipant(
  seanceId: seance.id,
  profilId: eleve.id,
  role: 'student',
  prenom: eleve.prenom,
  identifiantImmuable: eleve.identifiantImmuable,
  etat: etat,
  consolide: consolide,
  entreLe: arriveeApres == null ? null : seance.debut.add(arriveeApres),
  debutSeance: seance.debut,
);

/// Le jeu de seances du foyer A : cinq seances de A1 (tous les sorts), une
/// de A2, une seance a venir (jamais dans l'Historique) et une ligne du foyer
/// B que la base ne rendrait jamais (preuve que l'ecran filtre par eleve).
final List<Seance> seancesFoyerA = <Seance>[
  seanceFictive(id: 's-presente', ilYAJours: 2),
  seanceFictive(id: 's-retard', ilYAJours: 4),
  seanceFictive(id: 's-coupure', ilYAJours: 6),
  seanceFictive(id: 's-annulee', ilYAJours: 9, statut: StatutSeance.annulee),
  seanceFictive(
    id: 's-non-tenue',
    ilYAJours: 40,
    statut: StatutSeance.enseignantAbsent,
  ),
  seanceFictive(id: 's-a2', ilYAJours: 3, eleve: FoyersFictifs.a2),
  seanceFictive(id: 's-futur', ilYAJours: -3),
];

/// Les presences du jeu [seancesFoyerA].
final List<PresenceParticipant> presencesFoyerA = <PresenceParticipant>[
  presenceFictive(
    seancesFoyerA[0],
    EtatPresence.presente,
    arriveeApres: const Duration(minutes: 1),
  ),
  presenceFictive(
    seancesFoyerA[1],
    EtatPresence.enRetard,
    arriveeApres: const Duration(minutes: 8),
  ),
  presenceFictive(
    seancesFoyerA[2],
    EtatPresence.deconnectee,
    arriveeApres: const Duration(minutes: 2),
  ),
  presenceFictive(
    seancesFoyerA[5],
    EtatPresence.presente,
    eleve: FoyersFictifs.a2,
    arriveeApres: Duration.zero,
  ),
];

/// La classe courante de A1 (fixture du coordinateur).
final GroupSummaryVM classeA = classeFictive();

/// Les visites de l'observateur : deux sur `s-presente` (A1, dont une
/// ouverte), une fermee sur `s-a2` (A2).
List<Map<String, dynamic>> visitesFoyerA() {
  final Seance s = seancesFoyerA[0];
  final Seance s2 = seancesFoyerA[5];
  String iso(DateTime d) => d.toUtc().toIso8601String();
  return <Map<String, dynamic>>[
    ligneVisite(
      seanceId: s.id,
      groupeId: classeA.groupeId,
      entree: iso(s.debut.add(const Duration(minutes: 12))),
      sortie: iso(s.debut.add(const Duration(minutes: 14))),
    ),
    ligneVisite(
      id: 'v2',
      seanceId: s.id,
      groupeId: classeA.groupeId,
      entree: iso(s.debut.add(const Duration(minutes: 35))),
      sortie: null,
      duree: null,
      rang: 2,
    ),
    ligneVisite(
      id: 'v3',
      seanceId: s2.id,
      groupeId: 'classe-inconnue',
      enfantId: FoyersFictifs.a2.id,
      entree: iso(s2.debut.add(const Duration(minutes: 5))),
      sortie: iso(s2.debut.add(const Duration(minutes: 5, seconds: 48))),
      duree: 48,
    ),
  ];
}

/// Le conteneur Riverpod de l'application montee.
ProviderContainer conteneurDe(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

/// Le faux service de suivi que [surchargesRouteur] a pose.
FauxServiceSuivi suiviDe(WidgetTester tester) =>
    conteneurDe(tester).read(serviceSuiviProvider) as FauxServiceSuivi;

/// Les surcharges de l'Historique : classe courante et classes des seances
/// (derives du lot), et, si donne, le port d'historique des observations.
List<Override> surchargesHistorique({
  PortHistoriqueObservations? observations,
  bool avecClasses = true,
}) => <Override>[
  classesCourantesProvider.overrideWithValue(
    avecClasses
        ? <String, GroupSummaryVM>{classeA.groupeId: classeA}
        : const <String, GroupSummaryVM>{},
  ),
  classeDesSeancesProvider.overrideWithValue(<String, String>{
    for (final Seance s in seancesFoyerA)
      if (s.eleveId == FoyersFictifs.a1.id) s.id: classeA.groupeId,
  }),
  if (observations != null)
    portHistoriqueObservationsProvider.overrideWithValue(observations),
];

/// Monte l'application sur son vrai routeur (foyer A), remplit le faux suivi
/// puis va a [depart].
Future<GoRouter> monterHistorique(
  WidgetTester tester, {
  String depart = Routes.tuteurAccueil,
  Size? taille = const Size(390, 844),
  List<Seance>? seances,
  List<PresenceParticipant>? presences,
  bool presencesIllisibles = false,
  Duration? delai,
  Object? erreur,
  PortHistoriqueObservations? observations,
  bool avecClasses = true,
  List<EleveDuFoyer> eleves = FoyersFictifs.foyerA,
  bool horsLigne = false,
  ThemeMode mode = ThemeMode.light,
  Key? cadre,
  List<Override> autres = const <Override>[],
}) async {
  // Sans taille, la vue est deja fixee par l'appelant (outil de capture).
  if (taille != null) {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final FauxServiceAppairage appairage = FauxServiceAppairage()
    ..elevesRendus = eleves;
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: appairage,
        ),
        ...surchargesHistorique(
          observations: observations,
          avecClasses: avecClasses,
        ),
        ...autres,
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadre,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final FauxServiceSuivi suivi = suiviDe(tester)
    ..seancesRendues = seances ?? seancesFoyerA
    ..presencesRendues = presencesIllisibles
        ? null
        : presences ?? presencesFoyerA
    ..delai = delai
    ..erreurAJeter = erreur;
  final ProviderContainer conteneur = conteneurDe(tester);
  if (horsLigne) {
    (conteneur.read(
      serviceReseauProvider,
    ) as FauxServiceReseau).horsLigneRendu = true;
  }
  conteneur
    ..invalidate(horsLigneProvider)
    ..invalidate(seancesDuSuiviProvider)
    ..invalidate(presenceDuSuiviProvider);
  expect(suivi.seancesRendues, isNotNull);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Touche la destination [libelle] de la barre basse (ou du rail).
Future<void> toucherDestination(WidgetTester tester, String libelle) async {
  final Finder barre = find.byKey(NavShell.barreBasseKey);
  await tester.tap(
    barre.evaluate().isEmpty
        ? find.text(libelle).first
        : find.descendant(of: barre, matching: find.text(libelle)),
  );
  await stabiliser(tester);
}

/// Fait defiler jusqu'a [cible] puis la touche.
Future<void> toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// Choisit [entree] dans le menu de filtre [axe].
Future<void> choisirFiltre(
  WidgetTester tester,
  String axe,
  String entree,
) async {
  await toucher(tester, find.bySemanticsLabel(RegExp('^$axe')).first);
  await tester.tap(find.text(entree).last);
  await stabiliser(tester);
}

/// Le libelle d'etat des lignes de l'Historique, pour les verifications.
String get libelleVerification => t.historique.etat.verification;
