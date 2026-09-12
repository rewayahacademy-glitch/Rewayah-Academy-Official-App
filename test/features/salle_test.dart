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
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../support/harnais.dart';

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
}
