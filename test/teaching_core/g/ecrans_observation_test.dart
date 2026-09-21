import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_observation/vue_budget_observation.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/tc_observation_ui/choix_entree_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/entree_observation_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/indicateur_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/module_reglages_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/options_entree_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/panneau_observation_tuteur.dart';
import 'package:rewayah_academy/features/tc_observation_ui/routes_tc_g.dart';
import 'package:rewayah_academy/features/tc_observation_ui/vue_observation_tuteur.dart';

import '../e/faux/faux_classe.dart';
import 'faux/faux_observation.dart';
import 'support/hote_tc_g.dart';

final DateTime _instant = DateTime.utc(2026, 9, 20, 10);

/// Amene la cible dans le cadre avant de la presser.
///
/// Le module de reglages depasse les six cents points du cadre de test des que
/// les quotas s'ouvrent : `tap` echouerait sur un point hors ecran, ce qui
/// dirait « le bouton ne marche pas » la ou il faut lire « il faut defiler ».
Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

ParticipantSalle _personne({
  required String identite,
  required String role,
  bool camera = false,
}) => ParticipantSalle(
  identite: identite,
  nom: identite,
  role: role,
  estLocal: false,
  micro: false,
  camera: camera,
  parle: false,
  qualite: QualiteLien.bonne,
);

void main() {
  group('Le choix d\'entree, par role', () {
    testWidgets('le controleur n\'a AUCUNE option de mode a l\'ecran', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(
          ChoixEntreeObservation(
            options: OptionsEntreeObservation.pour(AppRole.controller),
            onMode: (_) {},
            onEntrer: () {},
          ),
        ),
      );

      expect(find.text(t.tc.observation.entree.modeDiscret), findsNothing);
      expect(find.text(t.tc.observation.entree.modeVisible), findsNothing);
      // Ce qu'il voit en revanche, et en permanence : sa visite est
      // journalisee.
      expect(find.text(t.tc.observation.entree.visiteJournalisee), findsOneWidget);
      expect(find.text(t.tc.observation.entree.entrer), findsOneWidget);
    });

    testWidgets('l\'administration voit ses deux modes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(
          ChoixEntreeObservation(
            options: OptionsEntreeObservation.pour(AppRole.admin),
            onMode: (_) {},
            onEntrer: () {},
          ),
        ),
      );

      expect(find.text(t.tc.observation.entree.modeDiscret), findsOneWidget);
      expect(find.text(t.tc.observation.entree.modeVisible), findsOneWidget);
    });

    testWidgets('le tuteur n\'a ni mode ni bandeau d\'incognito', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(
          ChoixEntreeObservation(
            options: OptionsEntreeObservation.pour(AppRole.guardian),
            onMode: (_) {},
            onEntrer: () {},
          ),
        ),
      );

      expect(find.text(t.tc.observation.entree.modeDiscret), findsNothing);
      expect(find.text(t.tc.observation.entree.tuteurIntro), findsOneWidget);
      // Le tuteur est visible : l'enseignant doit savoir qu'un parent regarde.
      expect(find.text(t.tc.observation.entree.visiteJournalisee), findsNothing);
    });

    testWidgets('un compte qui n\'observe pas n\'a pas d\'action active', (
      WidgetTester tester,
    ) async {
      bool entre = false;
      await tester.pumpWidget(
        hoteTcG(
          ChoixEntreeObservation(
            options: OptionsEntreeObservation.pour(AppRole.student),
            onMode: (_) {},
            onEntrer: () => entre = true,
          ),
        ),
      );

      expect(find.text(t.tc.observation.entree.roleSansObservation), findsOneWidget);
      await tester.tap(find.text(t.tc.observation.entree.entrer));
      await tester.pump();
      expect(entre, isFalse);
    });
  });

  group('Le panneau du tuteur pendant sa visite', () {
    testWidgets('le compte a rebours et deux personnes, pas une de plus', (
      WidgetTester tester,
    ) async {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: <ParticipantSalle>[
          _personne(identite: 'prof-1', role: 'teacher', camera: true),
          _personne(identite: 'enfant-1', role: 'student', camera: true),
          _personne(identite: 'enfant-2', role: 'student'),
          _personne(identite: 'enfant-3', role: 'student'),
        ],
        enfantProfilId: 'enfant-1',
        budget: VueBudgetObservation.depuis(
          budget: unBudget(),
          recuA: _instant,
          maintenant: _instant,
        ),
      );

      await tester.pumpWidget(
        hoteTcG(PanneauObservationTuteur(vue: vue, onQuitter: () {})),
      );

      expect(
        find.text(t.tc.observation.visite.restant(secondes: 120)),
        findsOneWidget,
      );
      expect(find.text('prof-1'), findsOneWidget);
      expect(find.text('enfant-1'), findsOneWidget);
      // Les camarades ne sont nulle part : aucun roster, aucune fiche.
      expect(find.text('enfant-2'), findsNothing);
      expect(find.text('enfant-3'), findsNothing);
      // Le rappel des interdictions est permanent.
      expect(find.text(t.tc.observation.visite.mediaFerme), findsOneWidget);
    });

    testWidgets('un temps restant non confirme se dit', (
      WidgetTester tester,
    ) async {
      final VueObservationTuteur vue = VueObservationTuteur.depuis(
        participants: const <ParticipantSalle>[],
        enfantProfilId: 'enfant-1',
        budget: VueBudgetObservation.depuis(
          budget: unBudget(),
          recuA: _instant,
          maintenant: _instant,
        ),
      );

      await tester.pumpWidget(
        hoteTcG(
          PanneauObservationTuteur(
            vue: vue,
            onQuitter: () {},
            budgetIncertain: true,
          ),
        ),
      );

      expect(find.text(t.tc.observation.visite.budgetIncertain), findsOneWidget);
    });
  });

  group('L\'annonce cote enseignant et cote enfant', () {
    testWidgets('personne n\'observe : rien ne s\'affiche', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(
          const IndicateurObservation(annonces: <AnnonceObservation>[]),
        ),
      );

      expect(find.byType(IndicateurObservation), findsOneWidget);
      expect(find.textContaining('Tuteur'), findsNothing);
    });

    testWidgets('l\'enseignant lit le prenom de l\'enfant, jamais du tuteur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(
          IndicateurObservation(
            annonces: <AnnonceObservation>[
              AnnonceObservation(
                libelle: t.tc.observation.annonce.tuteurObserve(
                  prenomEnfant: 'Amina',
                ),
                tempsRestant: const Duration(seconds: 80),
                enfantConcerneId: 'enfant-1',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tuteur de Amina observe'), findsOneWidget);
      expect(
        find.text(t.tc.observation.annonce.restant(secondes: 80)),
        findsOneWidget,
      );
    });

    test('seul l\'enfant concerne recoit l\'indicateur discret', () {
      const List<AnnonceObservation> annonces = <AnnonceObservation>[
        AnnonceObservation(libelle: 'x', enfantConcerneId: 'enfant-1'),
      ];

      expect(enfantConcerneParObservation(annonces, 'enfant-1'), isTrue);
      // Les autres eleves ne sont pas interrompus.
      expect(enfantConcerneParObservation(annonces, 'enfant-2'), isFalse);
      expect(enfantConcerneParObservation(annonces, null), isFalse);
      expect(
        enfantConcerneParObservation(
          const <AnnonceObservation>[],
          'enfant-1',
        ),
        isFalse,
      );
    });

    testWidgets('l\'enfant non concerne ne voit rien', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(const IndicateurObservationEnfant(visible: false)),
      );

      expect(find.text(t.tc.observation.annonce.enfantIndicateur), findsNothing);
    });
  });

  group('Le module de reglages, isole et non route', () {
    const GuardianObservationPolicy academie =
        GuardianObservationPolicy.defautsNormatifs(policyVersion: 'a1');

    testWidgets('les trois choix, et les quotas caches quand on herite', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(
          ModuleReglagesObservation(
            politiqueAcademie: academie,
            politiqueGroupe: academie,
            onEnregistrer: (_) {},
          ),
        ),
      );

      expect(find.text(t.tc.observation.reglages.heriter), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.personnaliser), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.desactiver), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.maxVisites), findsNothing);
    });

    testWidgets('personnaliser ouvre les quotas et produit la politique', (
      WidgetTester tester,
    ) async {
      GuardianObservationPolicy? recue;
      await tester.pumpWidget(
        hoteTcG(
          ModuleReglagesObservation(
            politiqueAcademie: academie,
            politiqueGroupe: academie,
            onEnregistrer: (GuardianObservationPolicy p) => recue = p,
          ),
        ),
      );

      await _presser(tester, find.text(t.tc.observation.reglages.personnaliser));
      expect(find.text(t.tc.observation.reglages.maxVisites), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.tempsTotal), findsOneWidget);

      await _presser(tester, find.text(t.tc.observation.reglages.augmenter).first);
      await _presser(tester, find.text(t.tc.observation.reglages.enregistrer));

      expect(recue?.source, SourcePolitique.groupe);
      expect(recue?.maxVisitsPerSession, 2);
      expect(recue?.observationActivee, isTrue);
    });

    testWidgets('desactiver ferme la porte sans toucher aux quotas', (
      WidgetTester tester,
    ) async {
      GuardianObservationPolicy? recue;
      await tester.pumpWidget(
        hoteTcG(
          ModuleReglagesObservation(
            politiqueAcademie: academie,
            politiqueGroupe: academie,
            onEnregistrer: (GuardianObservationPolicy p) => recue = p,
          ),
        ),
      );

      await _presser(tester, find.text(t.tc.observation.reglages.desactiver));
      await _presser(tester, find.text(t.tc.observation.reglages.enregistrer));

      expect(recue?.source, SourcePolitique.desactivee);
      expect(recue?.observationActivee, isFalse);
      expect(find.text(t.tc.observation.reglages.maxVisites), findsNothing);
    });
  });

  group('La visite du tuteur est branchee sur la salle reelle', () {
    /// Monte la porte d'observation, presse « Entrer », et rend les faux.
    ///
    /// Le deroule reproduit celui de la production : le serveur ouvre
    /// l'intervalle, PUIS l'ecran demande le jeton video. L'ordre est ce qui
    /// permet a `autoriser_jeton_video()` de lire un role -- l'inverse recevrait
    /// « non inscrit a cette seance ».
    Future<void> entrerEnVisite(
      WidgetTester tester, {
      required FauxMoteurClasse moteur,
      required FauxServiceVideoClasse video,
      FauxPortPolitique? politique,
    }) async {
      await tester.pumpWidget(
        hoteRoutantTcG(
          depart: RoutesTcG.versObservation('s1'),
          routes: routesTcG(),
          surcharges: surchargesTcG(
            role: AppRole.guardian,
            politique: politique,
            moteur: moteur,
            video: video,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _presser(tester, find.text(t.tc.observation.entree.entrer));
    }

    testWidgets('l\'enseignant et son enfant, avec leur image, et personne d\'autre', (
      WidgetTester tester,
    ) async {
      final FauxMoteurClasse moteur = FauxMoteurClasse();
      moteur.videos['enfant-1'] = const Text('image de l\'enfant');
      moteur.videos['enfant-2'] = const Text('image d\'un camarade');
      final FauxServiceVideoClasse video = FauxServiceVideoClasse(
        acces0: accesDe('guardian_observer'),
      );

      await entrerEnVisite(tester, moteur: moteur, video: video);

      // La salle est rejointe avec le jeton du role d'observation, et une
      // seule fois.
      expect(video.demandes, <String>['s1']);
      expect(moteur.entrees.single.role, 'guardian_observer');
      // Aucune capacite de publication n'est ouverte : ni micro, ni camera.
      expect(moteur.microDemande, isEmpty);
      expect(moteur.cameraDemandee, isEmpty);

      moteur.publier(<ParticipantSalle>[
        participantDe(identite: 'prof-1', role: 'teacher', camera: true),
        participantDe(identite: 'enfant-1', role: 'student', camera: true),
        participantDe(identite: 'enfant-2', role: 'student', camera: true),
        participantDe(identite: 'enfant-3', role: 'student'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('prof-1'), findsOneWidget);
      expect(find.text('enfant-1'), findsOneWidget);
      expect(find.text('image de l\'enfant'), findsOneWidget);
      // Les camarades ne sortent pas de `VueObservationTuteur` : ni leur nom,
      // ni -- surtout -- leur image.
      expect(find.text('enfant-2'), findsNothing);
      expect(find.text('image d\'un camarade'), findsNothing);
      expect(find.text('enfant-3'), findsNothing);
    });

    testWidgets('un jeton d\'un autre role n\'ouvre aucune salle', (
      WidgetTester tester,
    ) async {
      final FauxMoteurClasse moteur = FauxMoteurClasse();
      final FauxServiceVideoClasse video = FauxServiceVideoClasse(
        // Le backend rend un jeton d'eleve : capacites de publication ouvertes.
        acces0: accesDe('student', camera: true),
      );

      await entrerEnVisite(tester, moteur: moteur, video: video);

      expect(moteur.entrees, isEmpty);
      expect(
        find.text(t.tc.observation.visite.videoIndisponible),
        findsOneWidget,
      );
      // Le panneau reste entier : le compte a rebours court cote serveur, et
      // le tuteur doit pouvoir refermer sa visite.
      expect(find.text(t.tc.observation.visite.quitter), findsOneWidget);
    });

    testWidgets('un jeton refuse se dit, sans inventer une salle', (
      WidgetTester tester,
    ) async {
      final FauxMoteurClasse moteur = FauxMoteurClasse();
      final FauxServiceVideoClasse video = FauxServiceVideoClasse(
        motifARefuser: MotifRefusSalle.acces,
      );

      await entrerEnVisite(tester, moteur: moteur, video: video);

      expect(moteur.entrees, isEmpty);
      expect(
        find.text(t.tc.observation.visite.videoIndisponible),
        findsOneWidget,
      );
    });

    testWidgets('le SERVEUR ferme la salle quand le budget tombe a zero', (
      WidgetTester tester,
    ) async {
      final FauxMoteurClasse moteur = FauxMoteurClasse();
      final FauxServiceVideoClasse video = FauxServiceVideoClasse(
        acces0: accesDe('guardian_observer'),
      );
      final FauxPortPolitique politique = FauxPortPolitique();
      addTearDown(politique.fermer);

      await entrerEnVisite(
        tester,
        moteur: moteur,
        video: video,
        politique: politique,
      );
      expect(moteur.entrees, hasLength(1));
      expect(moteur.departs, 0);

      // Aucune minuterie locale n'est avancee ici : c'est le flux serveur, et
      // lui seul, qui annonce le budget epuise.
      politique.flux.add(unBudget(restant: Duration.zero, peutEntrer: false));
      await tester.pumpAndSettle();

      expect(moteur.departs, 1);
      expect(
        find.text(t.tc.observation.fin.quotaAtteint),
        findsOneWidget,
      );
    });
  });

  group('La route se monte sans toucher au routeur global', () {
    testWidgets('routesTcG ouvre la porte d\'observation d\'une seance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteRoutantTcG(
          depart: RoutesTcG.versObservation('s1'),
          routes: routesTcG(),
          surcharges: surchargesTcG(role: AppRole.guardian),
        ),
      );
      await tester.pump();

      expect(find.byType(EntreeObservationPage), findsOneWidget);
      expect(find.text(t.tc.observation.entree.tuteurIntro), findsOneWidget);
    });
  });
}
