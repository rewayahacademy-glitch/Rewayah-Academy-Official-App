// Lot O, sous-paquet 1 : l'entree dans l'observation depuis la VRAIE
// navigation de l'application (routeur reel, coquille du tuteur), en touchant
// les boutons. Definition de « fait » du registre (`03` section 1 ter bis) :
// un `routeur.go` seul ne prouve pas l'acces.
//
// **Entree actuelle de cette branche** : « Assister », sur la carte de
// l'enfant pendant une seance en cours (Accueil de la base `cefab7f`). Le lot C
// remplace cet Accueil et porte l'entree dans le bloc Observation de la classe
// (sous-paquet C2), qui appellera `ouvrirObservation` : a l'integration, ce
// test part de la classe (demande O-3 au coordinateur). Le geste de la classe
// est deja teste dans `entree_explication_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
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
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';

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

void main() {
  testWidgets('telephone : Assister, l\'explication, Pas maintenant, retour a '
      'l\'accueil', (WidgetTester tester) async {
    final FauxPortVisite visites = FauxPortVisite();
    final FauxPortPolitique politique = FauxPortPolitique();
    addTearDown(politique.fermer);
    final GoRouter routeur = await _monter(
      tester,
      visites: visites,
      politique: politique,
    );

    // La coquille du tuteur : quatre destinations, dont Historique.
    expect(find.text(t.nav.tuteur.historique), findsOneWidget);

    await _presser(tester, find.text(t.tuteur.accueil.assister));

    // La porte d'observation de CETTE seance, hors coquille (tache
    // focalisee) : l'explication de premiere utilisation, un disque retour.
    expect(lieu(routeur), startsWith(Routes.tcObservation('s1')));
    expect(find.text(t.tc.observation.explication.titre), findsOneWidget);
    expect(find.byType(DisqueRetour), findsOneWidget);
    expect(find.text(t.nav.tuteur.historique), findsNothing);
    expect(visites.rolesDemandes, isEmpty);

    // « Pas maintenant » : retour a l'accueil (aucune classe dans
    // l'adresse), sans rien consommer, la navigation de nouveau la.
    await _presser(
      tester,
      find.text(t.tc.observation.explication.pasMaintenant),
    );
    expect(lieu(routeur), Routes.tuteurAccueil);
    expect(find.text(t.nav.tuteur.historique), findsOneWidget);
    expect(visites.rolesDemandes, isEmpty);
  });

  testWidgets(
    'bureau : Assister, l\'explication, Observer maintenant, la visite',
    (WidgetTester tester) async {
      // La salle de la base deborde a 390 (refonte au sous-paquet 2) :
      // l'entree jusqu'a la salle se prouve sur la composition de bureau,
      // barre laterale depliee.
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
      await _presser(tester, find.text(t.tuteur.accueil.assister));
      expect(lieu(routeur), startsWith(Routes.tcObservation('s1')));
      expect(find.text(t.tc.observation.explication.titre), findsOneWidget);
      expect(visites.rolesDemandes, isEmpty);

      await _presser(tester, find.text(t.tc.observation.explication.observer));

      expect(visites.rolesDemandes, <RoleObservateur>[RoleObservateur.tuteur]);
      expect(find.byType(PanneauObservationTuteur), findsOneWidget);
    },
  );

  testWidgets('le disque retour de l\'explication ramene aussi a l\'accueil', (
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

    await _presser(tester, find.text(t.tuteur.accueil.assister));
    await _presser(tester, find.byType(DisqueRetour));

    expect(lieu(routeur), Routes.tuteurAccueil);
    expect(visites.rolesDemandes, isEmpty);
  });
}
