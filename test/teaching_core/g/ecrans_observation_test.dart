import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_observation/vue_budget_observation.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
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

/// La salle remplit la hauteur qu'on lui donne (support dominant) : l'hote de
/// test defile, il faut donc la borner.
const double _hauteurSalle = 560;

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
      expect(
        find.text(t.tc.observation.entree.visiteJournalisee),
        findsOneWidget,
      );
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
      expect(
        find.text(t.tc.observation.entree.visiteJournalisee),
        findsNothing,
      );
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

      expect(
        find.text(t.tc.observation.entree.roleSansObservation),
        findsOneWidget,
      );
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
        hoteTcG(
          SizedBox(
            height: _hauteurSalle,
            child: PanneauObservationTuteur(vue: vue, onQuitter: () {}),
          ),
        ),
      );

      expect(find.text('02:00'), findsOneWidget);
      expect(find.text('prof-1'), findsOneWidget);
      expect(find.text('enfant-1'), findsOneWidget);
      // Les camarades ne sont nulle part : aucun roster, aucune fiche.
      expect(find.text('enfant-2'), findsNothing);
      expect(find.text('enfant-3'), findsNothing);
      // Aucune commande de media : ni micro, ni camera (trois commandes).
      expect(find.text(t.tc.observation.visite.quitter), findsOneWidget);
      expect(find.text(t.tc.observation.visite.agrandir), findsOneWidget);
      expect(find.text(t.tc.observation.visite.sonRecu), findsOneWidget);
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
          SizedBox(
            height: _hauteurSalle,
            child: PanneauObservationTuteur(
              vue: vue,
              onQuitter: () {},
              budgetIncertain: true,
            ),
          ),
        ),
      );

      expect(
        find.text(t.tc.observation.visite.budgetIncertain),
        findsOneWidget,
      );
    });
  });

  group('L\'annonce cote enseignant et cote enfant', () {
    testWidgets('personne n\'observe : rien ne s\'affiche', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(const IndicateurObservation(annonces: <AnnonceObservation>[])),
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
      // Un seul observateur ne se replie pas : une ligne ne merite pas une
      // animation, et il n'y a rien a compter.
      expect(find.byKey(IndicateurObservation.cleBandePrenoms), findsNothing);
    });

    group('Plusieurs tuteurs : l\'oeil, les prenoms, et leur nombre', () {
      /// Deux observateurs de deux foyers differents, comme dans un groupe.
      List<AnnonceObservation> deuxTuteurs() => <AnnonceObservation>[
        AnnonceObservation(
          libelle: t.tc.observation.annonce.tuteurObserve(
            prenomEnfant: 'Amina',
          ),
          prenomEnfant: 'Amina',
          enfantConcerneId: 'enfant-1',
        ),
        AnnonceObservation(
          libelle: t.tc.observation.annonce.tuteurObserve(
            prenomEnfant: 'Youssef',
          ),
          prenomEnfant: 'Youssef',
          enfantConcerneId: 'enfant-2',
        ),
      ];

      /// Le facteur de largeur de la bande : 1 deployee, 0 repliee derriere
      /// l'oeil. MESURE plutot que devinee -- les prenoms restent dans l'arbre
      /// une fois replies, donc `find.text` les trouverait encore.
      double replisement(WidgetTester tester) => tester
          .widget<Align>(find.byKey(IndicateurObservation.cleBandePrenoms))
          .widthFactor!;

      testWidgets('les prenoms se montrent, puis glissent derriere l\'oeil', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTcG(IndicateurObservation(annonces: deuxTuteurs())),
        );
        await tester.pumpAndSettle();

        // A l'arrivee : les deux prenoms sont sortis, et leur nombre est la.
        expect(replisement(tester), 1);
        expect(find.text('Amina'), findsOneWidget);
        expect(find.text('Youssef'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        // Jamais deux phrases empilees : c'est ce que ce repli evite.
        expect(find.textContaining('observe'), findsNothing);

        // Quelques secondes plus tard, ils sont rentres.
        await tester.pump(AppMouvement.retourLocalMaintien);
        await tester.pumpAndSettle();
        expect(replisement(tester), 0);
        // Le nombre, lui, reste lisible : c'est tout ce qui subsiste.
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('une pression les fait ressortir, le relachement les rend', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTcG(IndicateurObservation(annonces: deuxTuteurs())),
        );
        await tester.pump(AppMouvement.retourLocalMaintien);
        await tester.pumpAndSettle();
        expect(replisement(tester), 0);

        final TestGesture doigt = await tester.startGesture(
          tester.getCenter(find.byType(IndicateurObservation)),
        );
        await tester.pumpAndSettle();
        expect(replisement(tester), 1);

        // Le relachement rouvre la fenetre d'affichage plutot que de replier
        // sur-le-champ : au doigt, un appui bref ne laisserait rien lire.
        await doigt.up();
        await tester.pumpAndSettle();
        expect(replisement(tester), 1);

        await tester.pump(AppMouvement.retourLocalMaintien);
        await tester.pumpAndSettle();
        expect(replisement(tester), 0);
      });

      testWidgets('un tuteur de plus rouvre la fenetre d\'affichage', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          hoteTcG(IndicateurObservation(annonces: deuxTuteurs())),
        );
        await tester.pump(AppMouvement.retourLocalMaintien);
        await tester.pumpAndSettle();
        expect(replisement(tester), 0);

        await tester.pumpWidget(
          hoteTcG(
            IndicateurObservation(
              annonces: <AnnonceObservation>[
                ...deuxTuteurs(),
                AnnonceObservation(
                  libelle: t.tc.observation.annonce.tuteurObserve(
                    prenomEnfant: 'Bilal',
                  ),
                  prenomEnfant: 'Bilal',
                  enfantConcerneId: 'enfant-3',
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Sans cela, le troisieme observateur arriverait deja replie et
        // l'enseignant ne saurait jamais qu'il est entre.
        expect(replisement(tester), 1);
        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('le lecteur d\'ecran atteint les PRENOMS, pas que le compte', (
        WidgetTester tester,
      ) async {
        // Liberee a la MAIN en fin de corps, jamais par `addTearDown` : la
        // verification de flutter_test s'execute avant les tear-downs et
        // echouerait sur une poignee encore active.
        final SemanticsHandle poignee = tester.ensureSemantics();

        await tester.pumpWidget(
          hoteTcG(IndicateurObservation(annonces: deuxTuteurs())),
        );
        // On se place dans l'etat de REPOS, celui ou les prenoms sont replies :
        // c'est la que le defaut se voit. Ni le survol de la souris ni le focus
        // clavier n'existent pour un lecteur d'ecran tactile, et un `Opacity` a
        // zero retire son sous-arbre de l'arbre semantique.
        await tester.pump(AppMouvement.retourLocalMaintien);
        await tester.pumpAndSettle();
        expect(replisement(tester), 0);

        expect(
          find.bySemanticsLabel(
            RegExp(
              RegExp.escape(
                t.tc.observation.annonce.tuteursObservent(nombre: 2),
              ),
            ),
          ),
          findsOneWidget,
        );
        // Savoir DE QUI le parent regarde est ce qui sert a l'enseignant : le
        // repli est une economie de place, jamais une reserve d'information.
        expect(find.bySemanticsLabel(RegExp('Amina')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Youssef')), findsOneWidget);

        poignee.dispose();
      });
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
        enfantConcerneParObservation(const <AnnonceObservation>[], 'enfant-1'),
        isFalse,
      );
    });

    testWidgets('l\'enfant non concerne ne voit rien', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteTcG(const IndicateurObservationEnfant(visible: false)),
      );

      expect(
        find.text(t.tc.observation.annonce.enfantIndicateur),
        findsNothing,
      );
    });

    testWidgets('l\'enfant concerne le lit, y compris en mode enfant', (
      WidgetTester tester,
    ) async {
      // Le mode enfant change les metriques et la palette, pas le texte : c'est
      // le seul des cinq axes que ce composant traverse, et il faut le
      // constater plutot que le supposer.
      await tester.pumpWidget(
        hoteTcG(
          const IndicateurObservationEnfant(visible: true),
          mode: InterfaceMode.enfant,
        ),
      );

      expect(
        find.text(t.tc.observation.annonce.enfantIndicateur),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
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
      expect(
        find.text(t.tc.observation.reglages.personnaliser),
        findsOneWidget,
      );
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

      await _presser(
        tester,
        find.text(t.tc.observation.reglages.personnaliser),
      );
      expect(find.text(t.tc.observation.reglages.maxVisites), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.tempsTotal), findsOneWidget);

      await _presser(
        tester,
        find.text(t.tc.observation.reglages.augmenter).first,
      );
      await _presser(tester, find.text(t.tc.observation.reglages.enregistrer));

      expect(recue?.source, SourcePolitique.groupe);
      // Ecrit RELATIVEMENT a ce dont le groupe herite, et non en dur : ce que
      // ce cas mesure est « augmenter ajoute une visite a la valeur heritee ».
      // Fige a 2, il redevenait faux le jour ou l'Academie est passee de 1 a 2
      // visites (migration `0036`), sans rien mesurer de plus.
      expect(recue?.maxVisitsPerSession, academie.maxVisitsPerSession + 1);
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
      // Le tuteur passe par le vestibule (lot O, sous-paquet 1) : premiere
      // utilisation, l'explication, puis « Observer maintenant ».
      await _presser(tester, find.text(t.tc.observation.explication.observer));
    }

    testWidgets(
      'l\'enseignant et son enfant, avec leur image, et personne d\'autre',
      (WidgetTester tester) async {
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
      },
    );

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
      expect(find.text(t.tc.observation.fin.quotaAtteint), findsOneWidget);
    });

    testWidgets(
      'le budget epuise PENDANT la connexion ne laisse pas la salle jointe',
      (WidgetTester tester) async {
        // **Le defaut que ce test tient fermee** : entre la demande de jeton et
        // l'entree effective, il y a deux attentes. Si le serveur epuise le
        // budget pendant ce temps, l'ecran affiche « visite terminee » alors que
        // la salle finit tout de meme par etre jointe -- le parent continue de
        // voir et d'entendre la classe apres la fin de son quota, sans que ni
        // l'enseignant ni les enfants ne le sachent.
        final Completer<void> connexion = Completer<void>();
        final FauxMoteurClasse moteur = FauxMoteurClasse()
          ..entreeSuspendue = connexion;
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
        // La connexion court encore : rien n'est joint a cet instant.
        expect(moteur.entrees, isEmpty);

        // Le serveur, et lui seul, epuise le budget -- pendant la connexion.
        politique.flux.add(unBudget(restant: Duration.zero, peutEntrer: false));
        await tester.pumpAndSettle();
        expect(find.text(t.tc.observation.fin.quotaAtteint), findsOneWidget);

        // La connexion aboutit APRES la fin de la visite.
        connexion.complete();
        await tester.pumpAndSettle();

        expect(moteur.entrees, hasLength(1));
        // La salle est refermee aussitot : la visite terminee a l'ecran est une
        // visite terminee dans la salle.
        expect(moteur.departs, 1);
      },
    );
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
      await tester.pumpAndSettle();

      expect(find.byType(EntreeObservationPage), findsOneWidget);
      // Le tuteur arrive sur le vestibule : l'explication de premiere
      // utilisation, pas l'ancienne phrase d'introduction.
      expect(find.text(t.tc.observation.explication.titre), findsOneWidget);
      expect(find.text(t.tc.observation.entree.tuteurIntro), findsNothing);
    });

    testWidgets(
      'interrupteur P3 ferme : le tuteur lit « pas encore disponible », sans appel',
      (WidgetTester tester) async {
        final FauxPortVisite visites = FauxPortVisite();
        await tester.pumpWidget(
          hoteRoutantTcG(
            depart: RoutesTcG.versObservation('s1'),
            routes: routesTcG(),
            surcharges: surchargesTcG(
              role: AppRole.guardian,
              visites: visites,
              observationReelle: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EntreeObservationPage), findsOneWidget);
        expect(
          find.text(t.tc.observation.disponibilite.fermeeTitre),
          findsOneWidget,
        );
        expect(find.text(t.tc.observation.entree.tuteurIntro), findsNothing);
        expect(find.text(t.tc.observation.entree.entrer), findsNothing);
        expect(find.text(t.tc.observation.explication.observer), findsNothing);
        expect(visites.rolesDemandes, isEmpty);
      },
    );

    testWidgets('interrupteur P3 ferme : l administration garde sa porte', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteRoutantTcG(
          depart: RoutesTcG.versObservation('s1'),
          routes: routesTcG(),
          surcharges: surchargesTcG(
            role: AppRole.admin,
            observationReelle: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.tc.observation.entree.adminIntro), findsOneWidget);
      expect(find.text(t.commun.etats.indisponible.titre), findsNothing);
    });
  });
}
