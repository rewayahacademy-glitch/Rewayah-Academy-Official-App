// Lot O, sous-paquet 1 : l'entree dans l'observation depuis la VRAIE
// navigation de l'application (routeur reel, coquille du tuteur), en touchant
// les boutons. Definition de « fait » du registre (`03` section 1 ter bis) :
// un `routeur.go` seul ne prouve pas l'acces.
//
// **Entree integree (demandes O-3, O-INT-1)** : l'Accueil du lot C ne porte
// plus « Assister ». Le parcours touche part de l'Accueil reel, ouvre la
// classe (« Voir la classe »), puis « Observer la seance » du bloc
// Observation de la classe (`BlocObservationClasse`). L'entree recoit alors
// `?classe=` et `?eleve=` : « Pas maintenant », le disque retour et le retour
// de fin de visite ramenent a la classe, jamais dans une impasse.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
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
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_horloge/port_horloge_seance.dart';
import 'package:rewayah_academy/core/tc_observation/activation_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/moteur_visite_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/tc_observation_ui/compteur_visite.dart';
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../fixtures/tuteur/faux_seances_famille.dart';
import '../../parcours/faux_service_offres.dart';
import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import '../a/faux/faux_groupes.dart';
import '../e/faux/faux_classe.dart';
import 'faux/faux_observation.dart';

/// Une seance en cours pour l'enfant `e1`, calee sur l'horloge reelle : le
/// vrai Accueil lit `DateTime.now()`.
Seance _seanceEnCours() {
  final DateTime debut = DateTime.now().subtract(const Duration(minutes: 10));
  return Seance(
    id: 's1',
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: StatutSeance.enCours,
    eleveId: 'e1',
    elevePrenom: 'Mariam',
    eleveIdentifiant: 'STUD-TC-000001',
    enseignantId: 't1',
    enseignantPrenom: 'Amina',
    enseignantIdentifiant: 'TEACH-TC-000001',
  );
}

/// Les faux de tous les services lus au montage (ceux de
/// `surchargesRouteur`), et ceux de l'observation.
List<Override> _surcharges({
  required FauxPortVisite visites,
  required FauxPortPolitique politique,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.guardian)),
  ),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  servicePlanningProvider.overrideWithValue(
    FauxServicePlanning()
      ..seancesRendues = <Seance>[_seanceEnCours()]
      ..affectationsRendues = <Affectation>[
        Affectation(
          id: 'a1',
          enseignantId: 't1',
          enseignantPrenom: 'Amina',
          enseignantIdentifiant: 'TEACH-TC-000001',
          eleveId: 'e1',
          elevePrenom: 'Mariam',
          creneau: const Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
          depuis: DateTime(2026, 9, 1),
        ),
      ],
  ),
  serviceAppairageProvider.overrideWithValue(
    FauxServiceAppairage()
      ..elevesRendus = const <EleveDuFoyer>[
        EleveDuFoyer(
          id: 'e1',
          prenom: 'Mariam',
          identifiantImmuable: 'STUD-TC-000001',
          mode: InterfaceMode.standard,
          camera: CameraPolicy.forbidden,
        ),
      ],
  ),
  serviceAvatarProvider.overrideWithValue(FauxServiceAvatar()),
  serviceSuiviProvider.overrideWithValue(FauxServiceSuivi()),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
  servicePriereProvider.overrideWithValue(FauxServicePriere()),
  serviceEnseignantProvider.overrideWithValue(FauxServiceEnseignant()),
  serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
  // La presence de l'enfant, confirmee : l'observation est proposee.
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(
      lignes: const <PresenceParticipant>[
        PresenceParticipant(
          profilId: 'e1',
          role: 'student',
          prenom: 'Mariam',
          identifiantImmuable: 'STUD-TC-000001',
          etat: EtatPresence.presente,
          consolide: false,
        ),
      ],
    ),
  ),
  // La classe de l'enfant (contrat K6) et sa seance en direct (contrat K2) :
  // l'Accueil montre la classe, la classe porte l'entree d'observation.
  portClassesFoyerProvider.overrideWithValue(
    FauxClassesFoyer(
      classes: <ClasseFoyer>[
        ClasseFoyer(eleveId: 'e1', classe: classeFictive()),
      ],
    ),
  ),
  portSeancesFamilleProvider.overrideWithValue(
    FauxSeancesFamille(
      seances: <SeanceFamille>[
        seanceFictive(
          eleveId: 'e1',
          debutUtc: instantServeurFige.subtract(const Duration(minutes: 10)),
          statut: StatutSeance.enCours,
          heureFoyer: heureRendue('Europe/Paris', 'Paris', '17:50'),
        ),
      ],
    ),
  ),
  serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
  serviceOffresProvider.overrideWithValue(FauxServiceOffres()),
  portGroupesProvider.overrideWithValue(
    const FauxPortGroupes(groupes: <Never>[]),
  ),
  portHorlogeSeanceProvider.overrideWithValue(const PortHorlogeMuet()),
  stockagePreferencesProvider.overrideWithValue(StockagePreferencesMemoire()),
  // L'observation : interrupteur P3 ouvert (le parcours tel qu'il sera
  // ouvert), ports et salle remplaces, battement coupe.
  observationTuteurReelleProvider.overrideWithValue(true),
  portVisiteObservationProvider.overrideWithValue(visites),
  portPolitiqueObservationProvider.overrideWithValue(politique),
  moteurVisiteObservationProvider.overrideWith((Ref ref, String sessionId) {
    final MoteurVisiteObservation moteur = MoteurVisiteObservation(
      ref.watch(portVisiteObservationProvider),
      ref.watch(portPolitiqueObservationProvider),
      battement: const Stream<void>.empty(),
    );
    ref.onDispose(() => unawaited(moteur.dispose()));
    return moteur;
  }),
  moteurSalleProvider.overrideWithValue(FauxMoteurClasse()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideoClasse(acces0: accesDe('guardian_observer')),
  ),
];

Future<GoRouter> _monter(
  WidgetTester tester, {
  required FauxPortVisite visites,
  required FauxPortPolitique politique,
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(visites: visites, politique: politique),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurAccueil);
  await stabiliser(tester);
  return routeur;
}

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

/// L'adresse de la classe de l'enfant, ou ramenent les retours de l'entree.
final String _classe = Routes.classePour('classe-a', eleveId: 'e1');

/// « Historique » dans la barre basse de la coquille (telephone) : la
/// navigation est la. Le titre de l'Historique et le lien de la classe
/// portent le meme mot, d'ou la barre comme repere.
final Finder _navHistorique = find.descendant(
  of: find.byKey(NavShell.barreBasseKey),
  matching: find.text(t.nav.tuteur.historique),
);

/// De l'Accueil reel a la classe (« Voir la classe »), puis « Observer la
/// seance » : l'entree d'observation, touchee comme un parent la touche.
Future<void> _ouvrirObservation(WidgetTester tester) async {
  await _presser(tester, find.text(t.tuteur.accueil.voirLaClasse));
  await _presser(tester, find.text(t.classe.observer));
}

void main() {
  testWidgets('telephone : la classe, l\'explication, Pas maintenant, retour '
      'a la classe', (WidgetTester tester) async {
    final FauxPortVisite visites = FauxPortVisite();
    final FauxPortPolitique politique = FauxPortPolitique();
    addTearDown(politique.fermer);
    final GoRouter routeur = await _monter(
      tester,
      visites: visites,
      politique: politique,
    );

    // La coquille du tuteur : quatre destinations, dont Historique.
    expect(_navHistorique, findsOneWidget);

    await _ouvrirObservation(tester);

    // La porte d'observation de CETTE seance, hors coquille (tache
    // focalisee) : l'explication de premiere utilisation, un disque retour.
    expect(lieu(routeur), startsWith(Routes.tcObservation('s1')));
    expect(find.text(t.tc.observation.explication.titre), findsOneWidget);
    expect(find.byType(DisqueRetour), findsOneWidget);
    expect(_navHistorique, findsNothing);
    expect(visites.rolesDemandes, isEmpty);

    // « Pas maintenant » : retour a la classe (donnee par l'adresse),
    // sans rien consommer, la navigation de nouveau la.
    await _presser(
      tester,
      find.text(t.tc.observation.explication.pasMaintenant),
    );
    expect(lieu(routeur), _classe);
    expect(_navHistorique, findsOneWidget);
    expect(visites.rolesDemandes, isEmpty);
  });

  testWidgets('telephone : la classe, Observer maintenant, la salle, Agrandir, '
      'Quitter et sa confirmation', (WidgetTester tester) async {
    // Lot O, sous-paquet 2 : la salle refondue, atteinte en touchant depuis
    // la vraie coquille du tuteur, au format telephone.
    final FauxPortVisite visites = FauxPortVisite();
    final FauxPortPolitique politique = FauxPortPolitique();
    addTearDown(politique.fermer);
    final GoRouter routeur = await _monter(
      tester,
      visites: visites,
      politique: politique,
    );

    await _ouvrirObservation(tester);
    await _presser(tester, find.text(t.tc.observation.explication.observer));

    final v = t.tc.observation.visite;
    expect(find.byType(PanneauObservationTuteur), findsOneWidget);
    expect(find.byType(BandeauDecompteVisite), findsOneWidget);
    expect(_navHistorique, findsNothing);
    expect(tester.takeException(), isNull);

    await _presser(tester, find.text(v.agrandir));
    expect(find.text(v.reduire), findsOneWidget);

    await _presser(tester, find.text(v.quitter));
    expect(find.text(v.quitterQuestion), findsOneWidget);
    await _presser(tester, find.text(v.quitterConfirmer));
    // Le moteur attend l'annulation de ses abonnements (futur de la zone
    // racine) avant d'appeler le serveur : un tour de la vraie boucle.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await stabiliser(tester);

    expect(visites.sorties, <String>['s1']);
    expect(find.byType(PanneauObservationTuteur), findsNothing);
    expect(lieu(routeur), startsWith(Routes.tcObservation('s1')));

    // Lot O, sous-paquet 3 : la fin de visite (M5), puis le retour, touche.
    // Le faux serveur rend une politique d'une seule visite : c'etait la
    // derniere.
    expect(
      find.text(t.tc.observation.resultat.derniereTerminee),
      findsOneWidget,
    );
    await _presser(tester, find.text(t.tc.observation.entree.retourClasse));
    expect(lieu(routeur), _classe);
    expect(_navHistorique, findsOneWidget);
  });

  testWidgets('telephone : fin de visite, « Voir mes observations » ouvre '
      'l\'Historique, segment Observations', (WidgetTester tester) async {
    final FauxPortVisite visites = FauxPortVisite();
    final FauxPortPolitique politique = FauxPortPolitique();
    addTearDown(politique.fermer);
    final GoRouter routeur = await _monter(
      tester,
      visites: visites,
      politique: politique,
    );

    await _ouvrirObservation(tester);
    await _presser(tester, find.text(t.tc.observation.explication.observer));
    await _presser(tester, find.text(t.tc.observation.visite.quitter));
    await _presser(
      tester,
      find.text(t.tc.observation.visite.quitterConfirmer),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await stabiliser(tester);

    await _presser(
      tester,
      find.text(t.tc.observation.resultat.voirObservations),
    );
    expect(lieu(routeur), startsWith(Routes.tuteurSuiviObservations));
    // L'Historique est une destination de la coquille : la navigation revient.
    expect(_navHistorique, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bureau : la classe, l\'explication, Observer maintenant, la visite',
    (WidgetTester tester) async {
      final FauxPortVisite visites = FauxPortVisite();
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);
      final GoRouter routeur = await _monter(
        tester,
        visites: visites,
        politique: politique,
        taille: const Size(1440, 900),
      );

      expect(find.text(t.nav.tuteur.historique), findsOneWidget);
      await _ouvrirObservation(tester);
      expect(lieu(routeur), startsWith(Routes.tcObservation('s1')));
      expect(find.text(t.tc.observation.explication.titre), findsOneWidget);
      expect(visites.rolesDemandes, isEmpty);

      await _presser(tester, find.text(t.tc.observation.explication.observer));

      expect(visites.rolesDemandes, <RoleObservateur>[RoleObservateur.tuteur]);
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
    },
  );

  testWidgets('le disque retour de l\'explication ramene aussi a la classe', (
    WidgetTester tester,
  ) async {
    final FauxPortVisite visites = FauxPortVisite();
    final FauxPortPolitique politique = FauxPortPolitique();
    addTearDown(politique.fermer);
    final GoRouter routeur = await _monter(
      tester,
      visites: visites,
      politique: politique,
    );

    await _ouvrirObservation(tester);
    await _presser(tester, find.byType(DisqueRetour));

    expect(lieu(routeur), _classe);
    expect(visites.rolesDemandes, isEmpty);
  });
}
