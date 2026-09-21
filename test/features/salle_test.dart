import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/tc_observation_ui/indicateur_observation.dart';

import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';

const String _seance = 's1';

/// L'acces tel que `create-room-token` le rend pour chacun des quatre roles.
AccesSalle _acces(String role, {bool camera = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher' || (role == 'student' && camera),
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

ParticipantSalle _personne({
  required String identite,
  required String role,
  String? nom,
  bool local = false,
  bool micro = false,
  bool camera = false,
}) => ParticipantSalle(
  identite: identite,
  nom: nom ?? identite,
  role: role,
  estLocal: local,
  micro: micro,
  camera: camera,
  parle: false,
  qualite: QualiteLien.bonne,
);

SessionState _session(AppRole role) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
);

List<Override> _surcharges({
  required FauxServiceVideo video,
  required FauxMoteurSalle moteur,
  required FauxServicePreVol preVol,
  AppRole role = AppRole.student,
  FauxServicePresence? presence,
  bool monTuteurObserve = false,
  List<AnnonceObservation> annonces = const <AnnonceObservation>[],
}) => <Override>[
  sourceSessionProvider.overrideWithValue(FausseSourceSession(_session(role))),
  servicePreVolProvider.overrideWithValue(preVol),
  serviceVideoProvider.overrideWithValue(video),
  moteurSalleProvider.overrideWithValue(moteur),
  // **Indisponible par defaut, et c'est le bon defaut** : un test qui ne parle
  // pas de presence doit exercer le repli de l'invariant J3, pas un tableau
  // rempli par commodite.
  servicePresenceProvider.overrideWithValue(
    presence ?? FauxServicePresence(),
  ),
  // **Personne n'observe par defaut**, et surtout : sans cette surcharge, les
  // quinze cas de ce fichier qui montent la salle en role eleve iraient
  // chercher le VRAI port, c'est-a-dire `Supabase.instance.client`.
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(observe: monTuteurObserve),
  ),
  // Meme raison : sans surcharge, un enseignant monte ici irait chercher le
  // vrai port, donc Supabase.
  portAnnonceObservationProvider.overrideWithValue(
    FauxAnnonceObservation(lignes: annonces),
  ),
];

/// Une ligne de presence telle que `presence_seance_v` la rend.
PresenceParticipant _presence(
  EtatPresence etat, {
  required String profilId,
  required String prenom,
  String role = 'student',
  bool consolide = false,
  DateTime? entreLe,
}) => PresenceParticipant(
  profilId: profilId,
  role: role,
  prenom: prenom,
  identifiantImmuable: 'ID-$profilId',
  etat: etat,
  consolide: consolide,
  entreLe: entreLe,
  debutSeance: DateTime.now().subtract(const Duration(minutes: 15)),
);

/// Le pointeur qu'un enseignant pousse a sa classe : l'ayat al-Kursi.
ContenuPresente _contenu() => ContenuPresente(
  page: 42,
  sourate: 2,
  verset: 255,
  presentePar: 'p1',
  emisLe: DateTime.now(),
);

/// Une commande de la salle, retrouvee par le libelle de son ACTE.
///
/// Par une expression et non par une egalite : le libelle parle du bouton
/// (« Ouvrir le micro ») se fond dans le noeud semantique avec le mot court
/// affiche dessous (« Micro »), et une comparaison exacte ne trouverait donc
/// rien. C'est bien l'acte que l'on cherche, et c'est lui qu'un lecteur d'ecran
/// annoncera.
Finder _commande(String acte) => find.bySemanticsLabel(RegExp(acte));

/// Monte la salle dans un routeur minimal, pour que la sortie ait une
/// destination reelle.
Future<void> _monterSalle(
  WidgetTester tester, {
  required List<Override> surcharges,
  InterfaceMode mode = InterfaceMode.standard,
}) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.salle,
      surcharges: surcharges,
      mode: mode,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState _) =>
              const SallePage(seanceId: _seance),
        ),
        GoRoute(
          path: Routes.eleve,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('accueil eleve'),
        ),
        GoRoute(
          path: Routes.enseignantJournee,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('journee enseignant'),
        ),
        GoRoute(
          path: Routes.controleur,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('planning controleur'),
        ),
        // L'ecran de sortie de seance de l'enseignant, pose comme un talon
        // nomme et non avec la vraie `CahierPage` : ce qui se mesure ici est
        // **ou mene la sortie**, pas ce que le cahier montre --
        // `test/features/cahier_test.dart` s'en charge, et le brancher pour de
        // vrai obligerait ce fichier a surcharger les lectures du cahier.
        GoRoute(
          path: '${Routes.enseignantSeance}/:seanceId/cahier',
          builder: (BuildContext _, GoRouterState etat) =>
              Text('cahier de ${etat.pathParameters['seanceId']}'),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('L entree en salle, dans ses trois temps', () {
    testWidgets('le pre-vol precede la demande de jeton', (
      WidgetTester tester,
    ) async {
      // Une salle qui echoue APRES etre entree laisse deux personnes dedans
      // dont l'une est muette sans savoir pourquoi. L'ordre est donc une
      // exigence, pas un detail d'implementation.
      final FauxServicePreVol preVol = FauxServicePreVol(
        microDisponible: false,
      );
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student'),
      );

      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: video,
          moteur: FauxMoteurSalle(),
          preVol: preVol,
        ),
      );

      expect(preVol.verifications, 1);
      expect(video.demandes, isEmpty);
      expect(find.text(t.salle.refusMateriel), findsOneWidget);
    });

    testWidgets('rien ne publie a l entree, pour aucun role', (
      WidgetTester tester,
    ) async {
      // **L'invariant du catalogue**, et un defaut corrige du lot N2 : « micro
      // et camera fermes a l'entree, un tap les ouvre. Vrai pour tous les
      // roles. » Le moteur ne doit donc recevoir aucun reglage tant que
      // personne n'a touche l'ecran.
      for (final String role in <String>[
        'teacher',
        'student',
        'guardian_observer',
        'masked_controller',
      ]) {
        final FauxMoteurSalle moteur = FauxMoteurSalle();
        await _monterSalle(
          tester,
          surcharges: _surcharges(
            video: FauxServiceVideo(acces0: _acces(role, camera: true)),
            moteur: moteur,
            preVol: FauxServicePreVol(),
          ),
        );

        expect(moteur.entrees.length, 1, reason: role);
        expect(moteur.microDemande, isEmpty, reason: role);
        expect(moteur.cameraDemandee, isEmpty, reason: role);
      }
    });

    testWidgets('le bandeau permanent est la pour les quatre roles', (
      WidgetTester tester,
    ) async {
      // ADR-011 : la meme ligne, inchangee, quel que soit le role et que la
      // visite de controle ait lieu ou non.
      for (final String role in <String>[
        'teacher',
        'student',
        'guardian_observer',
        'masked_controller',
      ]) {
        await _monterSalle(
          tester,
          surcharges: _surcharges(
            video: FauxServiceVideo(acces0: _acces(role)),
            moteur: FauxMoteurSalle(),
            preVol: FauxServicePreVol(),
          ),
        );
        expect(
          find.text(t.salle.bandeauPermanent),
          findsOneWidget,
          reason: role,
        );
      }
    });
  });

  group('Les commandes suivent le jeton, jamais le mode d interface', () {
    testWidgets('un eleve dont la camera est interdite n a pas le bouton', (
      WidgetTester tester,
    ) async {
      // Il n'est pas grise : il n'existe pas. Un bouton visible mais inactif
      // invite a appuyer dessus, son absence ne pose pas la question.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
        mode: InterfaceMode.enfant,
      );

      expect(_commande(t.salle.ouvrirMicro), findsOneWidget);
      expect(_commande(t.salle.ouvrirCamera), findsNothing);
      expect(_commande(t.salle.quitterLeCours), findsOneWidget);
    });

    testWidgets('un eleve autorise a sa camera, meme en mode enfant', (
      WidgetTester tester,
    ) async {
      // Le nombre de commandes decoule du JETON. Coder « deux commandes en mode
      // enfant » priverait de sa camera l'enfant dont le tuteur l'a justement
      // autorisee dans `TUT-05`.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student', camera: true)),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
        mode: InterfaceMode.enfant,
      );

      expect(_commande(t.salle.ouvrirCamera), findsOneWidget);
    });

    testWidgets('un observateur et un controleur n ont que la sortie', (
      WidgetTester tester,
    ) async {
      for (final String role in <String>[
        'guardian_observer',
        'masked_controller',
      ]) {
        await _monterSalle(
          tester,
          surcharges: _surcharges(
            video: FauxServiceVideo(acces0: _acces(role)),
            moteur: FauxMoteurSalle(),
            preVol: FauxServicePreVol(),
          ),
        );
        expect(
          _commande(t.salle.ouvrirMicro),
          findsNothing,
          reason: role,
        );
        expect(
          _commande(t.salle.ouvrirCamera),
          findsNothing,
          reason: role,
        );
        expect(
          _commande(t.salle.quitterLeCours),
          findsOneWidget,
          reason: role,
        );
      }
    });

    testWidgets('un tap sur le micro demande son ouverture au moteur', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      moteur.publier(<ParticipantSalle>[
        _personne(identite: 'p1', role: 'student', local: true),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(_commande(t.salle.ouvrirMicro));
      await tester.pumpAndSettle();

      expect(moteur.microDemande, <bool>[true]);
    });
  });

  group('L invisibilite du controleur se voit a l ecran', () {
    testWidgets('son rappel est present, et ce n est pas le bandeau', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('masked_controller')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          role: AppRole.controller,
        ),
      );

      // Deux bandeaux distincts : celui de l'ADR-011, identique pour tous, et
      // le rappel d'invisibilite, qui ne vit que sur cet ecran-la.
      expect(find.text(t.salle.bandeauControle), findsOneWidget);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    });

    testWidgets('il lit deux personnes, et ne s y trouve pas', (
      WidgetTester tester,
    ) async {
      // Le test visuel de la fonction (fiche produit `CTR-02`). La fenetre par
      // defaut de flutter_test fait 800 points de large, donc un gabarit
      // tablette : la colonne des participants y est rendue.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('masked_controller')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.controller,
        ),
      );

      moteur.publier(<ParticipantSalle>[
        _personne(
          identite: 'c1',
          role: 'masked_controller',
          nom: 'Le controleur',
          local: true,
        ),
        _personne(identite: 't1', role: 'teacher', nom: 'Omar'),
        _personne(identite: 'e1', role: 'student', nom: 'Khadija'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(t.presence.titre), findsOneWidget);
      expect(find.text('Omar'), findsWidgets);
      expect(find.text('Khadija'), findsWidgets);
      expect(find.text('Le controleur'), findsNothing);
      expect(find.text(t.salle.vousMeme), findsNothing);
    });

    testWidgets('l enseignant, lui, figure dans sa propre liste', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      moteur.publier(<ParticipantSalle>[
        _personne(identite: 't1', role: 'teacher', nom: 'Omar', local: true),
        _personne(identite: 'e1', role: 'student', nom: 'Khadija'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(t.salle.vousMeme), findsWidgets);
      expect(find.text('Khadija'), findsWidgets);
    });
  });

  group('Ce que la salle dit quand on y est seul', () {
    testWidgets('l eleve attend son professeur, nomme comme tel', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
      );

      expect(find.text(t.salle.seulEnseignant), findsOneWidget);
      expect(find.text(t.salle.seulEleve), findsNothing);
    });

    testWidgets('l enseignant attend son eleve', (WidgetTester tester) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      expect(find.text(t.salle.seulEleve), findsOneWidget);
    });

    testWidgets('un lien degrade se dit en mots, jamais en couleur seule', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      moteur.publierQualite(QualiteLien.mediocre);
      await tester.pumpAndSettle();

      expect(find.text(t.salle.lienMediocre), findsOneWidget);
    });

    testWidgets('une reconnexion n est pas une absence', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      moteur.poser(EtatSalle.reconnexion);
      await tester.pumpAndSettle();

      // La salle reste montee, le bandeau reste la, et l'ecran le dit.
      expect(find.text(t.salle.reconnexionCourt), findsOneWidget);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(find.text(t.salle.refusReseau), findsNothing);
    });

    testWidgets('un lien instable porte son mot, et garde les commandes', (
      WidgetTester tester,
    ) async {
      // Le quatrieme des cinq etats du protocole. **Un etat ne se dit jamais
      // par la couleur seule** (invariant J7) : la pastille porte un libelle, et
      // la seance continue -- le micro reste utilisable.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      moteur
        ..publier(<ParticipantSalle>[
          _personne(identite: 'p1', role: 'student', local: true),
        ])
        ..poser(EtatSalle.instable);
      await tester.pumpAndSettle();

      expect(find.text(t.salle.lienMediocre), findsOneWidget);
      await tester.tap(_commande(t.salle.ouvrirMicro));
      await tester.pumpAndSettle();
      expect(moteur.microDemande, <bool>[true]);
    });

    testWidgets('un retablissement se dit, plutot que de se taire', (
      WidgetTester tester,
    ) async {
      // Le cinquieme etat. Quelqu'un qui a vu « Reconnexion » a besoin de lire
      // qu'elle a abouti : sans mot de fin, il reste a se demander si le cours
      // l'entend.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      moteur.poser(EtatSalle.reconnexion);
      await tester.pumpAndSettle();
      expect(find.text(t.salle.reconnexionCourt), findsOneWidget);

      moteur.poser(EtatSalle.retabli);
      await tester.pumpAndSettle();

      expect(find.text(t.reseau.retabli), findsOneWidget);
      expect(find.text(t.salle.reconnexionCourt), findsNothing);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    });
  });

  group('La scene tient un groupe, pas seulement un duo', () {
    testWidgets('six participants tiennent sur un telephone, sans rognage', (
      WidgetTester tester,
    ) async {
      // **Le pivot du 19 septembre 2026 mesure a l'ecran.** La version
      // precedente posait les vignettes dans une `Row` non defilante de 96
      // points chacune : six participants demandaient 624 points contre 390 de
      // large. Le debordement etait certain, et il n'etait pas theorique -- il
      // faisait deja echouer un test a deux personnes.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      moteur.publier(<ParticipantSalle>[
        _personne(
          identite: 't1',
          role: 'teacher',
          nom: 'Omar',
          local: true,
          camera: true,
        ),
        for (int i = 1; i <= 5; i++)
          _personne(identite: 'e$i', role: 'student', nom: 'Eleve $i'),
      ]);
      await tester.pumpAndSettle();

      // Aucune exception de rendu : `pumpAndSettle` les leve, un debordement
      // compris. Et les cinq eleves sont tous a l'ecran, aucun rogne.
      for (int i = 1; i <= 5; i++) {
        expect(find.text('Eleve $i'), findsWidgets, reason: 'Eleve $i');
      }
      final Size ecran = tester.view.physicalSize;
      for (final Element cadre in find.byType(AvatarTile).evaluate()) {
        final RenderBox boite = cadre.renderObject! as RenderBox;
        final Offset coin = boite.localToGlobal(Offset.zero);
        expect(coin.dx, greaterThanOrEqualTo(0));
        expect(coin.dx + boite.size.width, lessThanOrEqualTo(ecran.width));
      }
    });

    testWidgets('a deux, l autre occupe toujours le cadre entier', (
      WidgetTester tester,
    ) async {
      // La raison pedagogique de l'ADR-001 tient toujours a deux : les makharij
      // se lisent sur une bouche, pas sur une mosaique. La galerie ne s'ouvre
      // qu'a partir de deux distants.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      moteur.publier(<ParticipantSalle>[
        _personne(identite: 't1', role: 'teacher', nom: 'Omar', local: true),
        _personne(identite: 'e1', role: 'student', nom: 'Khadija'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
      expect(find.text('Khadija'), findsWidgets);
    });
  });

  group('Le contenu presente : un pointeur, jamais du contenu', () {
    testWidgets('l enseignant publie, et son propre ecran le recoit', (
      WidgetTester tester,
    ) async {
      // Le presentateur lit son contenu par le MEME flux que la classe : un seul
      // chemin de rendu, donc aucune divergence entre ce qu'il croit montrer et
      // ce qui est montre.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      await moteur.presenterContenu(_contenu());
      await tester.pumpAndSettle();

      expect(moteur.contenusPresentesDemandes.length, 1);
      // Le flux rejoue le dernier contenu a tout abonne : c'est donc bien par
      // lui que le presentateur lit ce qu'il vient de publier.
      final ContenuPresente vu = await moteur.contenusPresentes.first;
      expect(vu.reference, '2:255');
      expect(vu.page, 42);
    });

    testWidgets('un eleve qui tenterait de presenter est refuse en silence', (
      WidgetTester tester,
    ) async {
      // La barriere reelle est le jeton : `can_publish_data` vaut faux pour un
      // eleve, et le serveur LiveKit rejetterait le paquet. Le client refuse
      // d'abord, sans lever -- une exception n'apprendrait rien de plus que ses
      // capacites.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      await moteur.presenterContenu(_contenu());
      await tester.pumpAndSettle();

      // L'appel a bien eu lieu, et rien n'est parti : les deux faits se
      // mesurent separement, sinon un refus se confondrait avec un ecran muet.
      expect(moteur.contenusPresentesDemandes.length, 1);
      expect(moteur.dernierContenuPresente, isNull);
    });

    testWidgets('un abonne tardif retrouve la page ouverte', (
      WidgetTester tester,
    ) async {
      // **L'exigence de reconnexion sans perte d'etat pedagogique.** Un ecran
      // remonte au milieu d'une seance -- rotation, retour de veille -- doit
      // retrouver la page, et pas attendre que l'enseignant la tourne a nouveau.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      // L'abonnement arrive APRES la publication, et il recoit quand meme.
      final ContenuPresente vu = await moteur.contenusPresentes.first;

      expect(vu.reference, '2:255');
      expect(vu.page, 42);
    });
  });

  group('Les impasses, une par cause', () {
    testWidgets('la video non branchee ne se reessaye pas', (
      WidgetTester tester,
    ) async {
      // C'est l'etat de la production tant qu'aucun trousseau LiveKit n'est
      // pose : `create-room-token` repond 503, et l'ecran doit le dire sans
      // envoyer l'usager chercher la faute sur son appareil.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(
            motifARefuser: MotifRefusSalle.videoNonConfiguree,
          ),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
      );

      expect(find.text(t.salle.refusConfiguration), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
      expect(find.text(t.salle.retourAccueil), findsOneWidget);
      // Une impasse n'est pas une salle : rien n'y est enregistre, donc le
      // bandeau n'a rien a y annoncer.
      expect(find.text(t.salle.bandeauPermanent), findsNothing);
    });

    testWidgets('un refus d acces ne dit pas pourquoi, et c est voulu', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(motifARefuser: MotifRefusSalle.acces),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
      );

      expect(find.text(t.salle.refusAcces), findsOneWidget);
      expect(find.text(t.commun.reessayer), findsNothing);
    });

    testWidgets('un echec de connexion se reessaye, et relance le pre-vol', (
      WidgetTester tester,
    ) async {
      final FauxServicePreVol preVol = FauxServicePreVol();
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreurEntree = StateError('lien coupe');

      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: preVol,
        ),
      );

      expect(find.text(t.salle.refusReseau), findsOneWidget);
      expect(preVol.verifications, 1);

      moteur.erreurEntree = null;
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();

      // Reessayer reprend depuis le debut : le materiel a pu changer entre
      // temps, et un casque branche apres coup ne servirait a rien sinon.
      expect(preVol.verifications, 2);
      expect(find.text(t.salle.refusReseau), findsNothing);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    });

    testWidgets('rentrer mene a la racine de son role', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(motifARefuser: MotifRefusSalle.acces),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
      );

      await tester.tap(find.text(t.salle.retourAccueil));
      await tester.pumpAndSettle();

      expect(find.text('accueil eleve'), findsOneWidget);
    });
  });

  group('La sortie volontaire', () {
    testWidgets('elle se confirme, et s annonce AVANT de se deconnecter', (
      WidgetTester tester,
    ) async {
      // LiveKit envoie le meme evenement `left` dans les deux cas : seule cette
      // ecriture distingue une sortie volontaire d'une perte de reseau. Annoncer
      // apres la deconnexion laisserait le webhook arriver le premier.
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student'),
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();

      await _monterSalle(
        tester,
        surcharges: _surcharges(video: video, moteur: moteur, preVol: FauxServicePreVol()),
      );

      await tester.tap(_commande(t.salle.quitterLeCours));
      await tester.pumpAndSettle();

      // Trois temps : la question, la consequence en langage humain, et deux
      // actions asymetriques.
      expect(find.text(t.salle.confirmerSortie), findsWidgets);
      expect(find.text(t.salle.consequenceSortie), findsOneWidget);

      await tester.tap(find.text(t.salle.quitterLeCours).last);
      await tester.pumpAndSettle();

      expect(video.sorties, <String>[_seance]);
      expect(moteur.departs, greaterThanOrEqualTo(1));
      expect(find.text('accueil eleve'), findsOneWidget);
    });

    testWidgets('renoncer laisse dans la salle', (WidgetTester tester) async {
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student'),
      );

      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: video,
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
      );

      await tester.tap(_commande(t.salle.quitterLeCours));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.commun.annuler));
      await tester.pumpAndSettle();

      expect(video.sorties, isEmpty);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    });

    testWidgets('l enseignant qui a fait cours sort vers SON cahier', (
      WidgetTester tester,
    ) async {
      // **L'invariant du catalogue, enfin tenu.** La sortie de `ENS-03` mene a
      // `ENS-04` et a rien d'autre : le cahier de transmission est un ecran de
      // SORTIE de seance, pas un onglet, et c'est ce qui fait qu'un compte rendu
      // ne s'oublie pas. L'ecart inscrit ici depuis le lot N3 -- « `ENS-04` n'a
      // pas de route, on renvoie donc chez soi » -- est leve.
      //
      // Le cahier recoit l'identifiant de LA seance qu'on vient de quitter, et
      // non un cahier generique : c'est la cle d'idempotence qui en depend.
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('teacher'),
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();

      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: video,
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      await tester.tap(_commande(t.salle.quitterLeCours));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.quitterLeCours).last);
      await tester.pumpAndSettle();

      expect(video.sorties, <String>[_seance]);
      expect(find.text('cahier de $_seance'), findsOneWidget);
      expect(find.text('journee enseignant'), findsNothing);
    });

    testWidgets('celui qui n est jamais entre rentre chez lui, sans cahier', (
      WidgetTester tester,
    ) async {
      // Un cours qui n'a pas eu lieu n'a pas de compte rendu. Demander son
      // cahier a un enseignant qui a abandonne pendant la connexion serait lui
      // demander le recit d'un cours qui n'existe pas -- et le deposer
      // consommerait la cle d'idempotence de la vraie seance.
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('teacher'),
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();

      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: video,
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      // Le moteur retombe en `connexion` : la phase n'est plus `enSalle`, donc
      // `dansLaSalle` est faux, mais on n'est pas en impasse -- les commandes
      // sont la, et « quitter » est encore offert. C'est exactement l'etat d'un
      // enseignant qui renonce pendant que la salle s'ouvre.
      moteur.poser(EtatSalle.connexion);
      await tester.pumpAndSettle();

      await tester.tap(_commande(t.salle.quitterLeCours));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.quitterLeCours).last);
      await tester.pumpAndSettle();

      expect(find.text('journee enseignant'), findsOneWidget);
      expect(find.text('cahier de $_seance'), findsNothing);
    });
  });

  group('La presence, telle que la salle la montre', () {
    testWidgets('l eleve lit SON etat, et aucun autre', (
      WidgetTester tester,
    ) async {
      // Section 6.6 : « son propre etat ; aucun detail administratif, pas les
      // etats des autres ». La vue en base ne lui rend qu'une ligne ; l'ecran
      // ne doit donc pas aller en chercher une seconde ailleurs.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          presence: FauxServicePresence(
            lignes: <PresenceParticipant>[
              _presence(
                EtatPresence.enRetard,
                profilId: 'p1',
                prenom: 'Maryam',
                entreLe: DateTime.now().subtract(const Duration(minutes: 3)),
              ),
            ],
          ),
        ),
      );

      expect(find.text(t.presence.mienne), findsOneWidget);
      expect(find.text(t.presence.enRetard), findsOneWidget);
      // Aucune liste : l'eleve n'y a pas droit, et le bouton qui l'ouvrirait
      // n'existe pas non plus.
      expect(find.text(t.presence.titre), findsNothing);
    });

    testWidgets('l enseignant lit les inscrits, celui qui manque compris', (
      WidgetTester tester,
    ) async {
      // **Le coeur du lot.** Celui qui n'est jamais arrive n'a aucune piste
      // LiveKit, donc aucune ligne cote moteur. Une liste batie sur les
      // connectes ne montrerait que ceux dont il n'y a rien a dire.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
          presence: FauxServicePresence(
            lignes: <PresenceParticipant>[
              _presence(
                EtatPresence.presente,
                profilId: 'p1',
                prenom: 'Omar',
                role: 'teacher',
                entreLe: DateTime.now().subtract(const Duration(minutes: 14)),
              ),
              _presence(
                EtatPresence.enAttente,
                profilId: 'e1',
                prenom: 'Khadija',
              ),
            ],
          ),
        ),
      );

      // Seul l'enseignant est connecte : Khadija n'existe que par sa ligne.
      moteur.publier(<ParticipantSalle>[
        _personne(identite: 'p1', role: 'teacher', nom: 'Omar', local: true),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Khadija'), findsOneWidget);
      expect(find.text(t.presence.enAttente), findsOneWidget);
      expect(find.text(t.presence.presente), findsOneWidget);
      // Lui-meme se nomme « Vous », pas par son prenom : c'est deja la regle
      // de la liste de N3.
      expect(find.text(t.salle.vousMeme), findsWidgets);
    });

    testWidgets('une presence illisible se dit inconnue, jamais absente', (
      WidgetTester tester,
    ) async {
      // **Invariant J3, mesure a l'ecran et pas seulement dans la fonction
      // pure.** Le faux rend `null` : reseau coupe, lecture refusee, ou simple
      // premiere seconde avant la reponse. Les trois se disent pareil.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
        ),
      );

      moteur.publier(<ParticipantSalle>[
        _personne(identite: 'p1', role: 'teacher', nom: 'Omar', local: true),
        _personne(identite: 'e1', role: 'student', nom: 'Khadija'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(t.presence.inconnu), findsWidgets);
      expect(find.text(t.presence.absente), findsNothing);
      // La salle ne perd pas sa liste parce qu'une requete a echoue : elle
      // retombe sur ce que le moteur sait, et dit qu'elle ne sait pas le reste.
      expect(find.text('Khadija'), findsWidgets);
    });

    testWidgets('le controleur voit la meme liste que l enseignant', (
      WidgetTester tester,
    ) async {
      // ADR-011 jusque dans la presence : la vue en base ne lui rend aucune
      // ligne de `masked_controller`, pas meme la sienne. Son ecran affiche
      // donc exactement les memes personnes que celui de l'enseignant.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('masked_controller')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
          role: AppRole.controller,
          presence: FauxServicePresence(
            lignes: <PresenceParticipant>[
              _presence(
                EtatPresence.presente,
                profilId: 't1',
                prenom: 'Omar',
                role: 'teacher',
              ),
              _presence(
                EtatPresence.presente,
                profilId: 'e1',
                prenom: 'Khadija',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Omar'), findsWidgets);
      expect(find.text('Khadija'), findsWidgets);
      expect(find.text(t.salle.vousMeme), findsNothing);
      // Et il ne lit pas son propre etat non plus : il assiste, il n'est pas
      // note.
      expect(find.text(t.presence.mienne), findsNothing);
    });

    testWidgets('un etat consolide se distingue d un etat calcule', (
      WidgetTester tester,
    ) async {
      // Section 6.6 : l'enseignant distingue le provisoire du finalise. Le
      // motif, lui, ne traverse pas la vue -- il vit au journal d'audit.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
          presence: FauxServicePresence(
            lignes: <PresenceParticipant>[
              _presence(
                EtatPresence.excusee,
                profilId: 'e1',
                prenom: 'Khadija',
                consolide: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(t.presence.excusee), findsOneWidget);
      expect(
        find.textContaining(t.presence.consolide),
        findsOneWidget,
      );
    });
  });

  group('L enfant apprend que son tuteur regarde', () {
    testWidgets('l eleve observe lit la mention discrete, sans action', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          monTuteurObserve: true,
        ),
      );

      expect(
        find.text(t.tc.observation.annonce.enfantIndicateur),
        findsOneWidget,
      );
      // Sans bouton : un enfant de sept ans n'a rien a decider ici.
      expect(
        find.descendant(
          of: find.byType(IndicateurObservationEnfant),
          matching: find.byType(ActionPrincipale),
        ),
        findsNothing,
      );
    });

    testWidgets('l eleve non observe ne lit rien du tout', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
        ),
      );

      // C'est le cas des quatre autres enfants du groupe : le serveur leur
      // rend `observe: false`, et ils n'apprennent rien d'un autre foyer.
      expect(
        find.text(t.tc.observation.annonce.enfantIndicateur),
        findsNothing,
      );
    });

    testWidgets('le controleur masque ne lit jamais la mention de l enfant', (
      WidgetTester tester,
    ) async {
      // Le jeton dit `masked_controller` : la mention appartient a l'eleve, et
      // elle parle de SON foyer. Meme surcharge « observe » que le premier cas,
      // pour que le test mesure la condition de role et pas la donnee.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('masked_controller')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          role: AppRole.controller,
          monTuteurObserve: true,
        ),
      );

      expect(
        find.text(t.tc.observation.annonce.enfantIndicateur),
        findsNothing,
      );
    });

    testWidgets('l enseignant lance son cours ICI et apprend qu un parent regarde', (
      WidgetTester tester,
    ) async {
      // **Le chemin reel de l'enseignant.** Le bouton « Lancer » de sa journee
      // (`ENS-02`) mene a cette salle, pas a `/tc/classe`. L'annonce n'etait
      // montee que sur l'autre : il enseignait deux minutes devant un parent
      // sans le savoir.
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('teacher')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          role: AppRole.teacher,
          annonces: <AnnonceObservation>[
            AnnonceObservation(
              libelle: t.tc.observation.annonce.tuteurObserve(
                prenomEnfant: 'Amina',
              ),
              prenomEnfant: 'Amina',
              enfantConcerneId: 'enfant-1',
            ),
          ],
        ),
      );

      expect(find.byType(IndicateurObservation), findsOneWidget);
      expect(find.text('Tuteur de Amina observe'), findsOneWidget);
    });

    testWidgets('l eleve de cette meme salle ne lit pas l annonce enseignante', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle(),
          preVol: FauxServicePreVol(),
          annonces: <AnnonceObservation>[
            AnnonceObservation(
              libelle: t.tc.observation.annonce.tuteurObserve(
                prenomEnfant: 'Amina',
              ),
              prenomEnfant: 'Amina',
              enfantConcerneId: 'enfant-1',
            ),
          ],
        ),
      );

      // Elle porte le prenom d'un enfant qui n'est pas forcement le sien.
      expect(find.byType(IndicateurObservation), findsNothing);
      expect(find.text('Tuteur de Amina observe'), findsNothing);
    });
  });
}
