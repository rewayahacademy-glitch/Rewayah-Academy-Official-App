import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, ProviderScope, Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_avatar.dart'
    show photoEnseignantUrlProvider;
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart'
    show ProfilEnseignant, profilEnseignantParIdProvider;
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_classe/port_rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/rappel_discret.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_coran/moteur_mushaf.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart'
    show PointNormalise;
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/ligne_presence.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle_enseignant/page_coran_salle.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart'
    show DeclencheurCommandes;
import 'package:rewayah_academy/features/salle_seance/ecriture_seance.dart'
    show diffusionEcritureProvider;
import 'package:rewayah_academy/features/salle_seance/media_salle.dart';
import 'package:rewayah_academy/features/salle_seance/palette_tableau.dart';
import 'package:rewayah_academy/features/salle_seance/panneau_bibliotheque_salle.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/salle_seance/salle_ordinateur.dart';
import 'package:rewayah_academy/features/salle_seance/salle_seance.dart';
import 'package:rewayah_academy/features/salle_seance/telephone_plein_ecran.dart';
import 'package:rewayah_academy/features/tc_mushaf/page_madina_15.dart'
    show cleLigneMadina15;
import 'package:rewayah_academy/features/tc_mushaf/police_mushaf.dart';
import 'package:rewayah_academy/features/tc_observation_ui/indicateur_observation.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';
import '../support/hors_ligne_une_fois.dart';
import '../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';
import '../teaching_core/fixtures/fixtures_groupes.dart' show groupe;
import '../theme/support/contraste.dart';

const String _seance = 's1';

/// L'acces tel que `create-room-token` le rend pour chacun des quatre roles.
AccesSalle _acces(String role, {bool camera = false, bool? voix}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: voix ?? (role == 'teacher' || role == 'student'),
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
  servicePresenceProvider.overrideWithValue(presence ?? FauxServicePresence()),
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
  ThemeMode themeMode = ThemeMode.light,
  TextDirection? direction,
  double echelle = 1,
  // Une visite annoncee fait battre le point de la mention sans fin
  // (`PointEnregistrement`) : on ne peut pas attendre le repos.
  bool auRepos = true,
  String? groupeId,
}) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.salle,
      surcharges: surcharges,
      mode: mode,
      themeMode: themeMode,
      direction: direction,
      echelle: echelle,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState _) =>
              SallePage(seanceId: _seance, groupeId: groupeId),
        ),
        GoRoute(
          path: Routes.eleve,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('accueil eleve'),
        ),
        GoRoute(
          path: Routes.tcGroupes,
          builder: (BuildContext _, GoRouterState _) =>
              const Text('classes eleve'),
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
  if (auRepos) {
    await tester.pumpAndSettle();
    return;
  }
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// S0 : dans la salle de seance, la liste de presence de l'enseignant
/// s'ouvre par le lien « Presence » sous l'en-tete (feuille).
Future<void> _ouvrirPresence(WidgetTester tester) async {
  // S0.2 : la presence (J3) et le roster vivent dans le panneau Eleves de la
  // salle de seance : colonne deja ouverte, ou bouton « Eleves » a toucher.
  if (find.byType(LignePresence).evaluate().isNotEmpty) return;
  // K4 (25/10/2026) : dans `/salle`, a toutes les largeurs, le bouton rond
  // « Eleves » de la ligne d'etat ; ailleurs, celui de l'en-tete.
  final Finder rond = find.byKey(const ValueKey<String>('salle-eleves'));
  await tester.tap(
    rond.evaluate().isNotEmpty
        ? rond.first
        : find.byKey(const ValueKey<String>('bouton-eleves')).first,
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

    // CTRL-PREVOL-1 (releve VERIF-CT-1 ; P-CTR-03 point 4, R8, R13) : le micro
    // n'est exige que de qui parle.
    testWidgets('un controleur sans micro entre, et lit sa zone de controle', (
      WidgetTester tester,
    ) async {
      final FauxServicePreVol preVol = FauxServicePreVol(
        microDisponible: false,
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('masked_controller')),
          moteur: moteur,
          preVol: preVol,
          role: AppRole.controller,
        ),
      );

      expect(find.text(t.salle.refusMateriel), findsNothing);
      expect(moteur.entrees.length, 1);
      // Aucune demande de permission injustifiee : il n'ouvrira aucun micro.
      expect(preVol.verifications, 0);
      expect(find.text(t.salle.bandeauControle), findsOneWidget);
      expect(find.text(t.salle.quitter), findsOneWidget);
    });

    testWidgets(
      'tuteur temoin et administration en observation entrent muets',
      (WidgetTester tester) async {
        for (final (AppRole compte, String jeton) in <(AppRole, String)>[
          (AppRole.guardian, 'guardian_observer'),
          (AppRole.admin, 'admin_masked'),
        ]) {
          final FauxMoteurSalle moteur = FauxMoteurSalle();
          await _monterSalle(
            tester,
            surcharges: _surcharges(
              video: FauxServiceVideo(acces0: _acces(jeton)),
              moteur: moteur,
              preVol: FauxServicePreVol(microDisponible: false),
              role: compte,
            ),
          );
          expect(find.text(t.salle.refusMateriel), findsNothing, reason: jeton);
          expect(moteur.entrees.length, 1, reason: jeton);
        }
      },
    );

    testWidgets(
      'enseignant, eleve et administration qui parle restent bloques',
      (WidgetTester tester) async {
        for (final (AppRole compte, AccesSalle acces)
            in <(AppRole, AccesSalle)>[
              (AppRole.teacher, _acces('teacher')),
              (AppRole.student, _acces('student')),
              (AppRole.admin, _acces('admin_visible', voix: true)),
            ]) {
          final FauxMoteurSalle moteur = FauxMoteurSalle();
          await _monterSalle(
            tester,
            surcharges: _surcharges(
              video: FauxServiceVideo(acces0: acces),
              moteur: moteur,
              preVol: FauxServicePreVol(microDisponible: false),
              role: compte,
            ),
          );
          expect(
            find.text(t.salle.refusMateriel),
            findsOneWidget,
            reason: acces.role,
          );
          expect(moteur.entrees, isEmpty, reason: acces.role);
        }
      },
    );

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

    testWidgets(
      'le bandeau permanent est la pour les trois roles participants',
      (WidgetTester tester) async {
        // ADR-011 : la meme ligne, inchangee, quel que soit le role et que la
        // visite de controle ait lieu ou non. CTRL-SALLE-1 : elle s'adresse aux
        // participants ; le controleur, qui EST la visite, ne la voit pas
        // (teste dans le groupe de l'invisibilite du controleur).
        for (final String role in <String>[
          'teacher',
          'student',
          'guardian_observer',
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
      },
    );
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
      // S0 : le dock de la salle de seance (« Sortir de la seance »).
      expect(_commande(t.salle.seance.sortir), findsOneWidget);
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

    testWidgets('D14 : un refus de camera dit la phrase du navigateur', (
      WidgetTester tester,
    ) async {
      // Le directeur a touche « Camera » cinquante fois sans que rien ne se
      // passe : l'echec ne doit plus etre silencieux (K-59).
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreurCamera = StateError(
          'NotReadableError: Could not start video source',
        );
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student', camera: true)),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      await tester.tap(_commande(t.salle.ouvrirCamera));
      await tester.pumpAndSettle();

      expect(moteur.cameraDemandee, <bool>[true]);
      expect(find.text(t.salle.cameraEchec), findsOneWidget);
      expect(find.text(t.salle.cameraEchecOccupee), findsOneWidget);
      expect(
        find.textContaining('NotReadableError: Could not start video source'),
        findsOneWidget,
      );

      // Un essai qui aboutit efface le message.
      moteur.erreurCamera = null;
      await tester.tap(_commande(t.salle.ouvrirCamera));
      await tester.pumpAndSettle();
      expect(find.text(t.salle.cameraEchec), findsNothing);
    });

    testWidgets('Lot salle 3 : le message de la camera se ferme, et revient '
        'si un nouvel essai echoue', (WidgetTester tester) async {
      // Directeur, 25/10/2026 : « La camera ne s'allume pas » ne se fermait
      // pas. Une croix « Fermer », cible de 48, le ferme.
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreurCamera = StateError(
          'NotFoundError: Requested device not found',
        );
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student', camera: true)),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );
      await tester.tap(_commande(t.salle.ouvrirCamera));
      await tester.pumpAndSettle();
      expect(find.text(t.salle.cameraEchecAbsente), findsOneWidget);

      const Key croix = ValueKey<String>('salle-erreur-camera-fermer');
      final SemanticsHandle semantique = tester.ensureSemantics();
      expect(find.bySemanticsLabel(t.commun.fermer), findsOneWidget);
      semantique.dispose();
      final Size cible = tester.getSize(find.byKey(croix));
      expect(cible.width, greaterThanOrEqualTo(48));
      expect(cible.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byKey(croix));
      await tester.pumpAndSettle();
      expect(find.text(t.salle.cameraEchec), findsNothing);

      // Un nouvel essai qui echoue encore : le message revient.
      await tester.tap(_commande(t.salle.ouvrirCamera));
      await tester.pumpAndSettle();
      expect(find.text(t.salle.cameraEchec), findsOneWidget);
    });

    testWidgets('Lot salle 3 : sans camera, l appui dit la phrase existante '
        'sans rien demander au navigateur', (WidgetTester tester) async {
      // Audit reseau du pilote (25/10/2026) : sur un poste sans camera, la
      // salle demandait quand meme la camera au navigateur.
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student', camera: true)),
          moteur: moteur,
          preVol: FauxServicePreVol(cameraDisponible: false),
        ),
      );
      // A l'entree, rien n'est tente.
      expect(moteur.cameraDemandee, isEmpty);
      expect(find.text(t.salle.cameraEchec), findsNothing);

      await tester.tap(_commande(t.salle.ouvrirCamera));
      await tester.pumpAndSettle();
      expect(moteur.cameraDemandee, isEmpty);
      expect(find.text(t.salle.cameraEchecAbsente), findsOneWidget);
      expect(find.textContaining('Message du navigateur'), findsNothing);
    });

    testWidgets('Lot salle 3 (reseau) : salle ouverte puis deconnexion : '
        '« connexion perdue », et Reessayer redemande un jeton', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student'),
      );
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: video,
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );
      expect(video.demandes, hasLength(1));
      moteur.poser(EtatSalle.connecte);
      await tester.pumpAndSettle();
      // Deconnexion definitive (reseau, serveur) : le moteur passe en echec.
      moteur.poser(EtatSalle.echec);
      await tester.pumpAndSettle();
      expect(find.text(t.salle.perdue), findsOneWidget);
      expect(find.text(t.salle.secours.echec), findsOneWidget);
      // Jamais « La salle n'a pas pu s'ouvrir » : elle etait ouverte.
      expect(find.text(t.salle.refusReseau), findsNothing);
      await tester.tap(find.text(t.commun.reessayer));
      await tester.pumpAndSettle();
      expect(video.demandes, hasLength(2), reason: 'un nouveau jeton');
      expect(find.text(t.salle.perdue), findsNothing);
    });

    testWidgets('Lot salle 3 (reseau) : un echec avant toute ouverture reste '
        '« La salle n a pas pu s ouvrir »', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreurEntree = StateError('lien coupe');
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );
      expect(find.text(t.salle.refusReseau), findsOneWidget);
      expect(find.text(t.salle.perdue), findsNothing);
    });

    testWidgets('D14 : un allumage d entree refuse se dit sans geste', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle()
        ..erreurEntreeCamera = 'NotAllowedError: Permission denied';
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student', camera: true)),
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      expect(moteur.cameraDemandee, isEmpty);
      expect(find.text(t.salle.cameraEchec), findsOneWidget);
      expect(find.text(t.salle.cameraEchecRefus), findsOneWidget);
    });

    test('D14 : la cause probable se lit dans la phrase du navigateur', () {
      expect(
        causeEchecCamera('NotAllowedError: Permission denied'),
        t.salle.cameraEchecRefus,
      );
      expect(
        causeEchecCamera('NotFoundError: Requested device not found'),
        t.salle.cameraEchecAbsente,
      );
      expect(
        causeEchecCamera('OverconstrainedError: width'),
        t.salle.cameraEchecAutre,
      );
    });

    testWidgets('observateur et controleur : ni micro ni camera', (
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
        expect(_commande(t.salle.ouvrirMicro), findsNothing, reason: role);
        expect(_commande(t.salle.ouvrirCamera), findsNothing, reason: role);
        // CTR-02 (CT-3) : le controleur sort par « Quitter » de sa zone haute.
        expect(
          role == 'masked_controller'
              ? find.text(t.salle.quitter)
              : _commande(t.salle.quitterLeCours),
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

      // CTRL-SALLE-1 : le rappel d'invisibilite, qui ne vit que sur cet
      // ecran-la ; la mention de l'ADR-011 s'adresse aux participants, jamais
      // au controleur lui-meme.
      expect(find.text(t.salle.bandeauControle), findsOneWidget);
      expect(find.text(t.salle.bandeauPermanent), findsNothing);
      expect(find.byType(PermanentNotice), findsNothing);
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
        _personne(identite: 't1', role: 'teacher', nom: 'Omar', camera: true),
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
      await _ouvrirPresence(tester);

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

      // S0 : le bandeau de la salle de seance le dit en mots.
      expect(find.text(t.salle.secours.reseauFaible), findsOneWidget);
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

      expect(find.text(t.salle.secours.reseauFaible), findsOneWidget);
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

      expect(find.text(t.salle.secours.retablie), findsOneWidget);
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
          _personne(identite: 'e$i', role: 'student', nom: 'Élève $i'),
      ]);
      await tester.pumpAndSettle();

      // Aucune exception de rendu : `pumpAndSettle` les leve, un debordement
      // compris. Et les cinq eleves sont tous a l'ecran, aucun rogne.
      for (int i = 1; i <= 5; i++) {
        expect(find.text('Élève $i'), findsWidgets, reason: 'Élève $i');
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

    testWidgets('D9 : l eleve voit la page du Coran que l enseignant '
        'presente, et rien sans presentation', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces('student')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
          ),
          // Aucune source reelle du mushaf : la page dit qu'elle ne peut pas
          // s'afficher, et c'est le composant qui compte ici.
          policeMushafDisponibleProvider.overrideWith((Ref _) async => false),
          pageMushafProvider.overrideWith(
            (Ref _, int _) async => throw StateError('aucune source'),
          ),
        ],
      );
      expect(find.byKey(SallePage.pageEleveKey), findsNothing);

      // Une RECEPTION, comme si l'enseignant avait tourne la page.
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      final Finder page = find.byKey(SallePage.pageEleveKey);
      expect(page, findsOneWidget);
      expect(tester.widget<PageCoranSalle>(page).numero, 42);
    });

    testWidgets('S0 : sans page, la scene en grand ; la page la remplace, '
        'la vignette la rappelle', (WidgetTester tester) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces('student')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
          ),
          policeMushafDisponibleProvider.overrideWith((Ref _) async => false),
          pageMushafProvider.overrideWith(
            (Ref _, int _) async => throw StateError('aucune source'),
          ),
        ],
      );
      moteur.publier(<ParticipantSalle>[
        _personne(identite: 'p1', role: 'student', local: true),
        _personne(identite: 't1', role: 'teacher', nom: 'Omar', camera: true),
      ]);
      await tester.pumpAndSettle();

      // Rien de presente : les visages en grand, et rien a « revenir ».
      final Finder scene = find.byKey(
        const ValueKey<String>('scene-premier-plan'),
      );
      expect(scene, findsOneWidget);
      expect(find.byKey(const ValueKey<String>('revenir-page')), findsNothing);

      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();
      expect(scene, findsNothing);
      expect(find.byKey(SallePage.pageEleveKey), findsOneWidget);

      // Toucher la vignette remet la video en grand ; « Revenir a la page ».
      await tester.tap(find.byKey(const ValueKey<String>('vignette-en-grand')));
      await tester.pumpAndSettle();
      expect(scene, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('revenir-page')));
      await tester.pumpAndSettle();
      expect(find.byKey(SallePage.pageEleveKey), findsOneWidget);
    });

    testWidgets('S0 : un seul affichage, et le zoom par paliers', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces('student')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
          ),
          policeMushafDisponibleProvider.overrideWith((Ref _) async => false),
          pageMushafProvider.overrideWith(
            (Ref _, int _) async => throw StateError('aucune source'),
          ),
        ],
      );
      moteur.publierContenu(_contenu());
      await tester.pumpAndSettle();

      // B' : aucun bouton d'affichage (Support, Tableau) n'est propose.
      expect(
        find.text(t.salle.seance.commandes.affichageTableau),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('surface-feuille')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('surface-page')),
        findsOneWidget,
      );
    });

    testWidgets('S0.2 : les grandes fleches tournent la page pour la classe', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces('teacher')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
            role: AppRole.teacher,
          ),
          ...surchargesMadina15(page: 43),
          pageCoranProvider.overrideWith(
            (Ref _, int n) async => PageCoran(
              numero: n,
              versets: <VersetCoran>[
                VersetCoran(
                  sourateNumero: 2,
                  numero: 1,
                  texte: 'verset',
                  pageNumero: n,
                ),
              ],
            ),
          ),
        ],
      );
      await moteur.presenterContenu(_contenu());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fleches-page-salle')),
        findsOneWidget,
      );
      await tester.tap(
        find.bySemanticsLabel(RegExp(t.salle.seance.pageSuivante)).first,
      );
      await tester.pumpAndSettle();
      expect(moteur.contenusPresentesDemandes.last.page, 43);
    });

    for (final (String role, AppRole appRole, bool diffuse)
        in <(String, AppRole, bool)>[
          ('teacher', AppRole.teacher, true),
          ('student', AppRole.student, false),
        ]) {
      testWidgets('S1 : /salle branche la synchronisation de l ecriture '
          '($role)', (WidgetTester tester) async {
        final FauxMoteurSalle moteur = FauxMoteurSalle();
        await _monterSalle(
          tester,
          surcharges: <Override>[
            ..._surcharges(
              video: FauxServiceVideo(acces0: _acces(role)),
              moteur: moteur,
              preVol: FauxServicePreVol(),
              role: appRole,
            ),
            policeMushafDisponibleProvider.overrideWith((Ref _) async => false),
            pageMushafProvider.overrideWith(
              (Ref _, int _) async => throw StateError('aucune source'),
            ),
          ],
        );
        moteur.publierContenu(_contenu());
        await tester.pumpAndSettle();

        final ProviderContainer salle = ProviderScope.containerOf(
          tester.element(find.byType(SalleSeance)),
        );
        // Le depot de la seance est en memoire ; l'enseignant diffuse, pas
        // l'eleve (jeton sans `can_publish_data`).
        expect(salle.read(portAnnotationsProvider), isA<AnnotationsMemoire>());
        expect(
          salle.read(diffusionEcritureProvider) != null,
          diffuse,
          reason: role,
        );
      });
    }

    testWidgets('S0.3 : le bouton Tableau ouvre la feuille pour la classe, '
        'puis rend la page', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces('teacher')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
            role: AppRole.teacher,
          ),
          policeMushafDisponibleProvider.overrideWith((Ref _) async => false),
          pageMushafProvider.overrideWith(
            (Ref _, int _) async => throw StateError('aucune source'),
          ),
        ],
      );
      await moteur.presenterContenu(_contenu());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('surface-page')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('bouton-tableau')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('surface-feuille')),
        findsOneWidget,
      );
      expect(find.byTooltip(t.salle.seance.tableauOuvert), findsOneWidget);
      // L'ouverture part a la classe, sur le canal fiable.
      expect(moteur.donneesPubliees.last.fiable, isTrue);

      await tester.tap(find.byKey(const ValueKey<String>('bouton-tableau')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('surface-page')),
        findsOneWidget,
      );
    });

    test('S0 : les paliers du zoom, 100 a 200 %', () {
      expect(palierSuivant(1), 1.25);
      expect(palierSuivant(1.5), 2);
      expect(palierSuivant(2), isNull);
      expect(palierPrecedent(1), isNull);
      expect(palierPrecedent(1.25), 1);
      expect(zoomBorne(3), 2);
      expect(zoomBorne(0.5), 1);
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
      // EA-HL-DOUBLE-1f (K-59) : « La salle n'a pas repondu » affirmait une
      // cause ; la cause probable est dite sans l'affirmer.
      expect(causesAffirmees(), findsNothing);
      expect(find.textContaining(formulationCauseProbable), findsOneWidget);

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
        surcharges: _surcharges(
          video: video,
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );

      await tester.tap(_commande(t.salle.seance.sortir));
      await tester.pumpAndSettle();

      // Trois temps : la question, la consequence en langage humain, et deux
      // actions asymetriques (S0 : la question du dock de la salle de seance,
      // posee une seule fois).
      expect(find.text(t.salle.seance.quitterQuestion), findsWidgets);
      expect(find.text(t.salle.seance.quitterConsequence), findsOneWidget);

      await tester.tap(find.text(t.salle.quitter).last);
      await tester.pumpAndSettle();

      expect(video.sorties, <String>[_seance]);
      expect(moteur.departs, greaterThanOrEqualTo(1));
      // CLV-09 d'abord : la sortie se dit, sans recapitulatif ni presence.
      expect(find.text(t.salle.fin.quitteTitre), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('fin-recapitulatif')),
        findsNothing,
      );
      expect(find.text(t.salle.bandeauPermanent), findsNothing);
      // Lot salle 2 (pilote, 25/10/2026, standard Meet « You left the
      // meeting / Rejoin ») : « Retourner dans la salle » d'abord, puis
      // « Retour a l'accueil » ; libelle et destination concordent.
      expect(find.byKey(ResultatSeance.revenirKey), findsOneWidget);
      await tester.tap(find.text(t.salle.fin.retourAccueil));
      await tester.pumpAndSettle();
      expect(find.text('accueil eleve'), findsOneWidget);
    });

    testWidgets('Lot salle 2 : apres Quitter, un toucher ramene dans la '
        'salle, sans passer par la carte', (WidgetTester tester) async {
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student'),
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: video,
          moteur: moteur,
          preVol: FauxServicePreVol(),
        ),
      );
      await tester.tap(_commande(t.salle.seance.sortir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.quitter).last);
      await tester.pumpAndSettle();
      expect(find.text(t.salle.fin.quitteTitre), findsOneWidget);
      final int demandes = video.demandes.length;

      await tester.tap(find.byKey(ResultatSeance.revenirKey));
      await tester.pumpAndSettle();
      // Le meme chemin que l'entree : un nouveau jeton, la salle de seance.
      expect(video.demandes.length, demandes + 1);
      expect(find.text(t.salle.fin.quitteTitre), findsNothing);
      expect(find.byType(SalleSeance), findsOneWidget);
      expect(find.text('accueil eleve'), findsNothing);
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

      await tester.tap(_commande(t.salle.seance.sortir));
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

      await tester.tap(_commande(t.salle.seance.sortir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.seance.quitterCahier).last);
      await tester.pumpAndSettle();

      expect(video.sorties, <String>[_seance]);
      // CLV-10 d'abord : « Seance terminee », le recapitulatif, aucune mention
      // d'enregistrement ; puis « Ouvrir le cahier » mene a SON cahier.
      expect(find.text(t.salle.fin.enseignant.phrase), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('fin-recapitulatif')),
        findsOneWidget,
      );
      expect(find.text(t.salle.bandeauPermanent), findsNothing);
      expect(find.text('cahier de $_seance'), findsNothing);
      await tester.ensureVisible(
        find.text(t.salle.fin.enseignant.ouvrirCahier),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.fin.enseignant.ouvrirCahier));
      await tester.pumpAndSettle();
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

      // S0.2 : sa pastille dans l'en-tete, lue « Votre presence ».
      expect(find.bySemanticsLabel(RegExp(t.presence.mienne)), findsOneWidget);
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
      await _ouvrirPresence(tester);

      // S0.2 : dans la feuille, et dans la colonne Eleves de la salle.
      expect(find.text('Khadija'), findsWidgets);
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
      await _ouvrirPresence(tester);

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
      await _ouvrirPresence(tester);

      expect(find.text(t.presence.excusee), findsOneWidget);
      expect(find.textContaining(t.presence.consolide), findsOneWidget);
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
        auRepos: false,
      );

      // S0 : la notice de la salle de seance (« Votre parent observe le
      // cours », mots-rewayah), a l'enfant concerne seulement.
      expect(find.text(t.salle.seance.votreParentObserve), findsOneWidget);
      // Sans bouton : un enfant de sept ans n'a rien a decider ici.
      expect(find.byType(ActionPrincipale), findsNothing);
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
      expect(find.text(t.salle.seance.votreParentObserve), findsNothing);
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

    testWidgets(
      'l enseignant lance son cours ICI et apprend qu un parent regarde',
      (WidgetTester tester) async {
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
                  dePrenomEnfant: deDevant('Amina'),
                ),
                prenomEnfant: 'Amina',
                enfantConcerneId: 'enfant-1',
              ),
            ],
          ),
          auRepos: false,
        );

        // S0 : la notice de la salle de seance, sans prenom (EN-9).
        expect(find.text(t.salle.seance.unParentObserve), findsOneWidget);
      },
    );

    testWidgets(
      'l eleve de cette meme salle ne lit pas l annonce enseignante',
      (WidgetTester tester) async {
        await _monterSalle(
          tester,
          surcharges: _surcharges(
            video: FauxServiceVideo(acces0: _acces('student')),
            moteur: FauxMoteurSalle(),
            preVol: FauxServicePreVol(),
            annonces: <AnnonceObservation>[
              AnnonceObservation(
                libelle: t.tc.observation.annonce.tuteurObserve(
                  dePrenomEnfant: deDevant('Amina'),
                ),
                prenomEnfant: 'Amina',
                enfantConcerneId: 'enfant-1',
              ),
            ],
          ),
        );

        // Elle porte le prenom d'un enfant qui n'est pas forcement le sien.
        expect(find.byType(IndicateurObservation), findsNothing);
        expect(find.text(t.salle.seance.unParentObserve), findsNothing);
        expect(find.text("Tuteur d'Amina observe"), findsNothing);
      },
    );
  });

  // EA-HL-DOUBLE-1f : le titre et le detail de l'impasse prenaient l'encre
  // du fond creme (style du theme), illisible sur le fond de la salle.
  for (final ThemeMode theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('l impasse ecrit avec l encre du fond de la salle, $theme', (
      WidgetTester tester,
    ) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle()..erreurEntree = StateError('lien coupe'),
          preVol: FauxServicePreVol(),
        ),
        themeMode: theme,
      );
      for (final String texte in <String>[
        t.salle.refusReseau,
        t.salle.refusReseauDetail,
      ]) {
        final Finder f = find.text(texte);
        expect(f, findsOneWidget);
        final Color? encreFond = DefaultTextStyle.of(tester.element(f))
            .style
            .color;
        expect(encreFond, isNotNull);
        expect(tester.widget<Text>(f).style?.color, encreFond, reason: texte);
      }
    });
  }

  // EA-HL-DOUBLE-1f (reprise) : « Votre presence », pose sur le fond de la
  // salle, prenait l'encre du fond creme (captures 1440 : sombre sur sombre
  // en clair, clair sur clair en sombre).
  for (final ThemeMode theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('votre presence ecrit avec l encre du fond de la salle, '
        '$theme', (WidgetTester tester) async {
      await _monterSalle(
        tester,
        surcharges: _surcharges(
          video: FauxServiceVideo(acces0: _acces('student')),
          moteur: FauxMoteurSalle()..erreurEntree = StateError('lien coupe'),
          preVol: FauxServicePreVol(),
        ),
        themeMode: theme,
      );
      final Finder f = find.text(t.presence.mienne);
      expect(f, findsOneWidget);
      // JONCTION-LIGNES-1 : la ligne ccr (SALLE-ENCRE-1, SALLE-CORR-4) pose
      // « Votre presence » sur la surface des vignettes (`surfaceSunken`)
      // pour tous les roles, au lieu de l'ecrire sur le fond de la salle.
      // Ce qui compte reste le defaut de 1f : jamais sombre sur sombre ni
      // clair sur clair. Le texte se lit sur la surface qui le porte.
      final Color? encre = tester.widget<Text>(f).style?.color;
      expect(encre, isNotNull);
      final BoxDecoration surface =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(of: f, matching: find.byType(DecoratedBox))
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      final double l1 = encre!.computeLuminance();
      final double l2 = surface.color!.computeLuminance();
      final double contraste =
          (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
      expect(contraste, greaterThanOrEqualTo(4.5));
    });
  }

  // EA-HL-DOUBLE-1f : captures de preuve de l'impasse « reseau » de la salle
  // (sans bandeau, `PageImmersive`), 390 clair et sombre, 320 texte x2 en
  // LTR et RTL. Sautees sans CAPTURE_DIR.
  group('Capture EA-HL-DOUBLE-1f', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final (String, Size, ThemeMode, double, TextDirection) cas
        in <(String, Size, ThemeMode, double, TextDirection)>[
          (
            '390_clair',
            const Size(390, 844),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
          (
            '390_sombre',
            const Size(390, 844),
            ThemeMode.dark,
            1,
            TextDirection.ltr,
          ),
          (
            '320x2_clair',
            const Size(320, 1000),
            ThemeMode.light,
            2,
            TextDirection.ltr,
          ),
          (
            '320x2_rtl_clair',
            const Size(320, 1000),
            ThemeMode.light,
            2,
            TextDirection.rtl,
          ),
          (
            '320x2_rtl_sombre',
            const Size(320, 1000),
            ThemeMode.dark,
            2,
            TextDirection.rtl,
          ),
          (
            '1440_clair',
            const Size(1440, 900),
            ThemeMode.light,
            1,
            TextDirection.ltr,
          ),
        ]) {
      testWidgets(cas.$1, (WidgetTester tester) async {
        fixerVueCapture(tester, cas.$2, 1);
        await _monterSalle(
          tester,
          surcharges: _surcharges(
            video: FauxServiceVideo(acces0: _acces('student')),
            moteur: FauxMoteurSalle()..erreurEntree = StateError('lien coupe'),
            preVol: FauxServicePreVol(),
          ),
          themeMode: cas.$3,
          direction: cas.$5,
          echelle: cas.$4,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(t.salle.refusReseau), findsOneWidget);
        expect(causesAffirmees(), findsNothing);
        verifierAucunMotCoupe(tester, find.byType(MaterialApp));
        debugPrint(
          'PNG ${await capturerVue(tester, 'ea_hl_double1f_salle_refus_reseau_${cas.$1}')}',
        );
      });
    }
  });

  // Point 7 de la passation du 17/10 (spec section 10) : la fiche
  // pedagogique de seance, portee de l'ancienne classe dans `/salle`.
  group('La fiche de seance de l enseignant', () {
    Future<FauxRappelDiscret> monter(
      WidgetTester tester, {
      AppRole role = AppRole.teacher,
      String acces = 'teacher',
      EchecRappel? echec,
    }) async {
      final FauxRappelDiscret rappel = FauxRappelDiscret(echec: echec);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces(acces)),
            moteur: moteur,
            preVol: FauxServicePreVol(),
            role: role,
            presence: FauxServicePresence(
              lignes: <PresenceParticipant>[
                _presence(
                  EtatPresence.presente,
                  profilId: 'e1',
                  prenom: 'Amina',
                ),
                _presence(
                  EtatPresence.enAttente,
                  profilId: 'e2',
                  prenom: 'Ilyas',
                ),
                _presence(
                  EtatPresence.presente,
                  profilId: 'p1',
                  prenom: 'Omar',
                  role: 'teacher',
                ),
              ],
            ),
          ),
          portRosterEnseignantProvider.overrideWithValue(
            FauxRosterEnseignant(
              fiches: const <TeacherStudentProjection>[
                TeacherStudentProjection(
                  firstName: 'Amina',
                  academyId: 'ID-e1',
                  level: 'Decodage consolide',
                  liveStatus: EtatPresenceProjete.inconnu,
                  interfaceGuidee: false,
                ),
              ],
            ),
          ),
          portRappelDiscretProvider.overrideWithValue(rappel),
        ],
      );
      moteur.publier(<ParticipantSalle>[
        _personne(identite: 'p1', role: 'teacher', nom: 'Omar', local: true),
        _personne(identite: 'e1', role: 'student', nom: 'Amina'),
      ]);
      await tester.pumpAndSettle();
      return rappel;
    }

    testWidgets('le compteur des eleves ouvre la liste, puis la fiche ; '
        'un rappel qui part ne dit rien', (WidgetTester tester) async {
      final FauxRappelDiscret rappel = await monter(tester);
      // S0.2 : le roster reel vit dans le panneau Eleves de la salle de
      // seance (colonne ouverte, ou bouton « Eleves »).
      await _ouvrirPresence(tester);

      await tester.tap(find.text('Amina').last);
      await tester.pumpAndSettle();
      expect(find.text('Decodage consolide'), findsOneWidget);
      await tester.ensureVisible(find.text(t.tc.classe.action.rappel));
      await tester.tap(find.text(t.tc.classe.action.rappel));
      await tester.pump();
      await tester.pump();
      expect(rappel.appels, <(String, String)>[(_seance, 'ID-e1')]);
      expect(find.text(t.tc.classe.rappel.echec), findsNothing);
    });

    testWidgets('un rappel qui echoue est le seul a dire quelque chose', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        echec: const EchecRappel(MotifEchecRappel.transport),
      );
      await _ouvrirPresence(tester);
      await tester.tap(find.text('Amina').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(t.tc.classe.action.rappel));
      await tester.tap(find.text(t.tc.classe.action.rappel));
      await tester.pump();
      await tester.pump();
      expect(find.text(t.tc.classe.rappel.echec), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('l eleve n a ni compteur ni fiche de ses camarades', (
      WidgetTester tester,
    ) async {
      await monter(tester, role: AppRole.student, acces: 'student');
      expect(find.byKey(const ValueKey<String>('salle-eleves')), findsNothing);
    });
  });

  // D9 (24/10/2026) : captures de la page du Coran en salle, enseignant et
  // eleve, avec les VRAIES polices (UthmanicHafs comprise) et les vraies
  // lignes de l'edition de Medine. Sautees sans CAPTURE_DIR.
  group('D9 : captures de la page du Coran en salle', () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });

    const Map<String, Size> tailles = <String, Size>{
      '390-portrait': Size(390, 844),
      '390-paysage': Size(844, 390),
      '1366': Size(1366, 768),
    };
    for (final MapEntry<String, Size> taille in tailles.entries) {
      for (final String role in <String>['enseignant', 'eleve']) {
        testWidgets('page du Coran, $role, ${taille.key}', (
          WidgetTester tester,
        ) async {
          masquerRubanDebug();
          tester.view.physicalSize = taille.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final bool enseignant = role == 'enseignant';
          final FauxMoteurSalle moteur = FauxMoteurSalle();
          await _monterSalle(
            tester,
            surcharges: <Override>[
              ..._surcharges(
                video: FauxServiceVideo(
                  acces0: _acces(enseignant ? 'teacher' : 'student'),
                ),
                moteur: moteur,
                preVol: FauxServicePreVol(),
                role: enseignant ? AppRole.teacher : AppRole.student,
              ),
              ...surchargesMadina15(page: 293),
              // Le panneau de l'enseignant lit d'abord la page par le service
              // du Coran (etats de lecture) : une page 293 en memoire.
              pageCoranProvider.overrideWith(
                (Ref _, int n) async => PageCoran(
                  numero: n,
                  versets: <VersetCoran>[
                    VersetCoran(
                      sourateNumero: 18,
                      numero: 1,
                      texte: 'verset',
                      pageNumero: n,
                    ),
                  ],
                ),
              ),
              souratesProvider.overrideWith(
                (Ref _) async => const <Sourate>[
                  Sourate(
                    numero: 18,
                    nomArabe: 'الكهف',
                    nomTranslittere: 'Al-Kahf',
                    lieuRevelation: 'mecque',
                    nombreVersets: 110,
                  ),
                ],
              ),
            ],
          );
          // La page 293 (Al-Kahf) : celle des captures de Madina-15.
          final ContenuPresente contenu = ContenuPresente(
            page: 293,
            sourate: 18,
            verset: 1,
            presentePar: 'p1',
            emisLe: DateTime.now(),
          );
          if (enseignant) {
            await moteur.presenterContenu(contenu);
          } else {
            moteur.publierContenu(contenu);
          }
          await tester.pumpAndSettle();
          expect(find.byType(PageCoranSalle), findsOneWidget);
          expect(find.byKey(PageCoranSalle.cle), findsOneWidget);
          await capturerVue(tester, 'd9-coran-salle-$role-${taille.key}');
        });
      }
    }
  }, skip: sautSansCapture);

  // S0 (arbitrage du pilote, 24/10/2026) : la salle de seance montee dans
  // `/salle`, aux trois largeurs, des deux cotes, en clair et en sombre.
  group('S0 : captures de la salle de seance', () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });

    const Map<String, Size> tailles = <String, Size>{
      '390-portrait': Size(390, 844),
      '390-paysage': Size(844, 390),
      '1366': Size(1366, 768),
    };
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final MapEntry<String, Size> taille in tailles.entries) {
        for (final String role in <String>['enseignant', 'eleve']) {
          final String nom =
              's0-2d-salle-$role-${taille.key}-${theme == ThemeMode.light ? 'clair' : 'sombre'}';
          testWidgets(nom, (WidgetTester tester) async {
            masquerRubanDebug();
            tester.view.physicalSize = taille.value;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final bool enseignant = role == 'enseignant';
            final FauxMoteurSalle moteur = FauxMoteurSalle();
            await _monterSalle(
              tester,
              themeMode: theme,
              surcharges: <Override>[
                ..._surcharges(
                  video: FauxServiceVideo(
                    acces0: _acces(
                      enseignant ? 'teacher' : 'student',
                      camera: true,
                    ),
                  ),
                  moteur: moteur,
                  preVol: FauxServicePreVol(),
                  role: enseignant ? AppRole.teacher : AppRole.student,
                  presence: FauxServicePresence(
                    lignes: <PresenceParticipant>[
                      _presence(
                        EtatPresence.presente,
                        profilId: enseignant ? 'p1' : 't1',
                        prenom: 'Omar',
                        role: 'teacher',
                      ),
                      _presence(
                        EtatPresence.presente,
                        profilId: enseignant ? 'e1' : 'p1',
                        prenom: 'Hakim',
                      ),
                    ],
                  ),
                ),
                ...surchargesMadina15(page: 293),
                pageCoranProvider.overrideWith(
                  (Ref _, int n) async => PageCoran(
                    numero: n,
                    versets: <VersetCoran>[
                      VersetCoran(
                        sourateNumero: 18,
                        numero: 1,
                        texte: 'verset',
                        pageNumero: n,
                      ),
                    ],
                  ),
                ),
              ],
            );
            moteur.publier(<ParticipantSalle>[
              _personne(
                identite: enseignant ? 'p1' : 't1',
                role: 'teacher',
                nom: 'Omar',
                local: enseignant,
                micro: true,
                camera: true,
              ),
              _personne(
                identite: enseignant ? 'e1' : 'p1',
                role: 'student',
                nom: 'Hakim',
                local: !enseignant,
                micro: true,
              ),
            ]);
            final ContenuPresente contenu = ContenuPresente(
              page: 293,
              sourate: 18,
              verset: 1,
              presentePar: 'p1',
              emisLe: DateTime.now(),
            );
            if (enseignant) {
              await moteur.presenterContenu(contenu);
            } else {
              moteur.publierContenu(contenu);
            }
            await tester.pumpAndSettle();
            expect(find.byKey(PageCoranSalle.cle), findsOneWidget);
            await capturerVue(tester, nom);
          });
        }
      }
    }
  }, skip: sautSansCapture);

  // S0.3 : le tableau blanc ouvert par l'enseignant, a 1366 et au telephone.
  group('S0.3 : captures du tableau', () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });
    for (final MapEntry<String, Size> taille in <String, Size>{
      '390-portrait': const Size(390, 844),
      '1366': const Size(1366, 768),
    }.entries) {
      testWidgets('s0-3-tableau-enseignant-${taille.key}', (
        WidgetTester tester,
      ) async {
        masquerRubanDebug();
        tester.view.physicalSize = taille.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
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
        await tester.tap(find.byKey(const ValueKey<String>('bouton-tableau')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('surface-feuille')),
          findsOneWidget,
        );
        await capturerVue(tester, 's0-3-tableau-enseignant-${taille.key}');
      });
    }
  }, skip: sautSansCapture);

  // Standard des commandes d'appel (directeur, 24/10/2026) : Google Meet
  // (Material 3). Captures std-* : 390 portrait (eleve, enseignant, tableau
  // ouvert) et 1366 (enseignant, tableau ouvert), clair et sombre. Verifie
  // sur le rendu : aucun texte sous un bouton de la pilule, une seule rangee.
  group('Standard des commandes d appel : captures std', () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      for (final (String cas, Size taille, bool enseignant, bool tableau)
          in <(String, Size, bool, bool)>[
            ('eleve-390', const Size(390, 844), false, false),
            ('enseignant-390', const Size(390, 844), true, false),
            ('enseignant-tableau-390', const Size(390, 844), true, true),
            ('enseignant-1366', const Size(1366, 768), true, false),
            ('enseignant-tableau-1366', const Size(1366, 768), true, true),
          ]) {
        final String nom =
            'std-$cas-${theme == ThemeMode.light ? 'clair' : 'sombre'}';
        testWidgets(nom, (WidgetTester tester) async {
          masquerRubanDebug();
          tester.view.physicalSize = taille;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final FauxMoteurSalle moteur = FauxMoteurSalle();
          await _monterSalle(
            tester,
            themeMode: theme,
            surcharges: <Override>[
              ..._surcharges(
                video: FauxServiceVideo(
                  acces0: _acces(
                    enseignant ? 'teacher' : 'student',
                    camera: true,
                  ),
                ),
                moteur: moteur,
                preVol: FauxServicePreVol(),
                role: enseignant ? AppRole.teacher : AppRole.student,
                presence: FauxServicePresence(
                  lignes: <PresenceParticipant>[
                    _presence(
                      EtatPresence.presente,
                      profilId: enseignant ? 'p1' : 't1',
                      prenom: 'Omar',
                      role: 'teacher',
                    ),
                    _presence(
                      EtatPresence.presente,
                      profilId: enseignant ? 'e1' : 'p1',
                      prenom: 'Hakim',
                    ),
                  ],
                ),
              ),
              ...surchargesMadina15(page: 293),
              pageCoranProvider.overrideWith(
                (Ref _, int n) async => PageCoran(
                  numero: n,
                  versets: <VersetCoran>[
                    VersetCoran(
                      sourateNumero: 18,
                      numero: 1,
                      texte: 'verset',
                      pageNumero: n,
                    ),
                  ],
                ),
              ),
            ],
          );
          moteur.publier(<ParticipantSalle>[
            _personne(
              identite: enseignant ? 'p1' : 't1',
              role: 'teacher',
              nom: 'Omar',
              local: enseignant,
              micro: true,
              camera: true,
            ),
            _personne(
              identite: enseignant ? 'e1' : 'p1',
              role: 'student',
              nom: 'Hakim',
              local: !enseignant,
              micro: true,
            ),
          ]);
          final ContenuPresente contenu = ContenuPresente(
            page: 293,
            sourate: 18,
            verset: 1,
            presentePar: 'p1',
            emisLe: DateTime.now(),
          );
          if (enseignant) {
            await moteur.presenterContenu(contenu);
          } else {
            moteur.publierContenu(contenu);
          }
          await tester.pumpAndSettle();
          if (tableau) {
            await tester.tap(
              find.byKey(const ValueKey<String>('bouton-tableau')),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(PaletteTableau.cle), findsOneWidget);
            expect(
              find.text(t.salle.seance.surface.aucunSupport),
              findsNothing,
            );
          }
          // Aucun texte sous un bouton : la pilule ne porte que des icones.
          final Finder pilule = find.byKey(
            const ValueKey<String>('dock-seance'),
          );
          expect(pilule, findsOneWidget);
          expect(
            find.descendant(of: pilule, matching: find.byType(Text)),
            findsNothing,
          );
          // Une seule rangee : tous les boutons ont le meme centre vertical.
          final List<double> centres = <double>[
            for (final Element e
                in find
                    .descendant(
                      of: pilule,
                      matching: find.byKey(
                        const ValueKey<String>('disque-appel'),
                      ),
                    )
                    .evaluate())
              tester
                  .getCenter(find.byElementPredicate((Element x) => x == e))
                  .dy,
          ];
          expect(centres, isNotEmpty);
          expect(centres.toSet().length, 1);
          // Aucun declencheur hors de la pilule.
          expect(find.byKey(DeclencheurCommandes.cle), findsNothing);
          await capturerVue(tester, nom);
          if (tableau && taille.width >= 1200) {
            // Point 7 : la palette du tableau disparait a 3 s avec la barre
            // de l'appel, et revient au toucher.
            double opacite() => tester
                .widget<AnimatedOpacity>(
                  find
                      .ancestor(
                        of: find.byKey(PaletteTableau.cle),
                        matching: find.byType(AnimatedOpacity),
                      )
                      .first,
                )
                .opacity;
            expect(opacite(), 1);
            await tester.pump(const Duration(seconds: 4));
            await tester.pumpAndSettle();
            expect(opacite(), 0);
            await tester.tapAt(const Offset(800, 400));
            await tester.pumpAndSettle();
            expect(opacite(), 1);
          }
        });
      }
    }
  }, skip: sautSansCapture);

  // K4 (directeur, 25/10/2026, essai en production sur ordinateur) : « full
  // screen, full body, no bezels ; tout ce qui reste est superpose au-dessus
  // et disparait ». Sur ordinateur, la page du Coran occupe toute la hauteur
  // de la fenetre, aucun widget opaque ne reduit sa boite, les Commandes sont
  // repliees ; le tableau occupe la fenetre (feuille 16:9 ajustee).
  group('K4 : plein ecran sur ordinateur', () {
    // Les vraies polices seulement pour les captures : apres les autres
    // groupes du fichier, leur chargement par `rootBundle` restait en attente
    // jusqu'au delai de la suite (la geometrie testee n'en depend pas : la
    // page se compose sur la hauteur donnee).
    setUpAll(() async {
      if (dossierCapture == null) return;
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });

    Future<FauxMoteurSalle> monterAvecPage(
      WidgetTester tester,
      Size taille,
    ) async {
      masquerRubanDebug();
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces('teacher')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
            role: AppRole.teacher,
          ),
          ...surchargesMadina15(page: 293),
          pageCoranProvider.overrideWith(
            (Ref _, int n) async => PageCoran(
              numero: n,
              versets: <VersetCoran>[
                VersetCoran(
                  sourateNumero: 18,
                  numero: 1,
                  texte: 'verset',
                  pageNumero: n,
                ),
              ],
            ),
          ),
        ],
      );
      await moteur.presenterContenu(
        ContenuPresente(
          page: 293,
          sourate: 18,
          verset: 1,
          presentePar: 'p1',
          emisLe: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      return moteur;
    }

    for (final Size taille in <Size>[
      const Size(1366, 768),
      const Size(1920, 1080),
    ]) {
      final String nom = '${taille.width.toInt()}x${taille.height.toInt()}';
      // Plan de composition du 26/10/2026 (remplace K4 sur ordinateur) :
      // la page occupe toute la hauteur du centre, entre les deux panneaux,
      // et rien ne la recouvre.
      testWidgets('enseignant, $nom : la page prend toute la hauteur du '
          'centre, rien ne reduit sa boite, Commandes repliees', (
        WidgetTester tester,
      ) async {
        await monterAvecPage(tester, taille);
        expect(tester.takeException(), isNull);
        final Rect boite = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        final Rect centre = tester.getRect(
          find.byKey(SalleOrdinateur.cleCentre),
        );
        // De bas en haut de sa zone, centree dans le centre.
        expect(boite.bottom, closeTo(centre.bottom, 0.5));
        expect(boite.center.dx, closeTo(centre.center.dx, 0.5));
        expect(boite.left, greaterThanOrEqualTo(centre.left - 0.5));
        expect(boite.right, lessThanOrEqualTo(centre.right + 0.5));
        for (final Key cote in <Key>[
          SalleOrdinateur.cleGauche,
          SalleOrdinateur.cleDroite,
          SalleOrdinateur.cleBas,
        ]) {
          expect(
            boite.overlaps(tester.getRect(find.byKey(cote))),
            isFalse,
            reason: '$cote recouvre la page',
          );
        }
        // Sa largeur suit la composition du mushaf, plafonnee a 1,4 fois.
        final Size attendue = boitePagePleinEcran(
          Size(centre.width, boite.height),
          telephone: false,
        );
        expect(boite.width, closeTo(attendue.width, 0.5));
        // La page composee remplit la hauteur de sa boite.
        final Rect page = tester.getRect(find.byKey(PageCoranSalle.cle));
        expect(page.height, closeTo(boite.height, 0.5));
        // Les quinze lignes se partagent la hauteur de la boite.
        final double ligne = tester
            .getRect(find.byKey(cleLigneMadina15(3)))
            .height;
        expect(ligne, greaterThan(boite.height / 15 * 0.85));
        if (dossierCapture != null) {
          await capturerVue(tester, 'k4-page-enseignant-$nom');
        }
        // Commandes repliees par defaut ; aucune carte opaque a cote.
        expect(
          find.byKey(const ValueKey<String>('telephone-commandes')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('panneau-seance-colonne')),
          findsNothing,
        );
      });
    }

    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(1366, 768),
    ]) {
      final String nom = '${taille.width.toInt()}x${taille.height.toInt()}';
      testWidgets('tableau, $nom : le canevas est la fenetre, la feuille '
          '16:9 ajustee sans etirement', (WidgetTester tester) async {
        await monterAvecPage(tester, taille);
        await tester.tap(find.byKey(const ValueKey<String>('bouton-tableau')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Rect canevas = tester.getRect(
          find.byKey(TelephonePleinEcran.clePage),
        );
        // Telephone : la fenetre. Ordinateur (plan du 26/10/2026) : tout le
        // centre, sous la ligne du titre.
        if (taille.width < 840) {
          expect(canevas, Offset.zero & taille);
        } else {
          final Rect centre = tester.getRect(
            find.byKey(SalleOrdinateur.cleCentre),
          );
          expect(canevas.left, closeTo(centre.left, 0.5));
          expect(canevas.right, closeTo(centre.right, 0.5));
          expect(canevas.bottom, closeTo(centre.bottom, 0.5));
        }
        final Rect feuille = tester.getRect(
          find.byKey(const ValueKey<String>('surface-feuille')),
        );
        // La forme de la classe, 16:9, ajustee a echelle uniforme, centree,
        // dans le canevas (bandes vides ailleurs).
        expect(feuille.width / feuille.height, closeTo(16 / 9, 0.01));
        expect(feuille.width, lessThanOrEqualTo(canevas.width + 0.5));
        expect(feuille.height, lessThanOrEqualTo(canevas.height + 0.5));
        expect(feuille.center.dx, closeTo(canevas.center.dx, 0.5));
        expect(feuille.center.dy, closeTo(canevas.center.dy, 0.5));
        expect(
          math.max(
            feuille.width / canevas.width,
            feuille.height / canevas.height,
          ),
          closeTo(1, 0.01),
        );
        if (dossierCapture != null) {
          await capturerVue(tester, 'k4-tableau-enseignant-$nom');
        }

        // Retour du directeur (25/10) : le tableau « devient bizarre » quand
        // les commandes se masquent. La boite ne bouge plus au masquage, et
        // meme si la fenetre change, un trait garde son rapport x / y.
        PointNormalise a = const PointNormalise(0.1, 0.2);
        PointNormalise b = const PointNormalise(0.6, 0.5);
        double rapport(Rect f) =>
            ((b.x - a.x) * f.width) / ((b.y - a.y) * f.height);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        final Rect masquee = tester.getRect(
          find.byKey(const ValueKey<String>('surface-feuille')),
        );
        expect(masquee, feuille);
        tester.view.physicalSize = Size(taille.width * 0.8, taille.height);
        await tester.pumpAndSettle();
        final Rect autre = tester.getRect(
          find.byKey(const ValueKey<String>('surface-feuille')),
        );
        expect(rapport(autre), closeTo(rapport(feuille), 0.02));
        a = const PointNormalise(0, 0);
        b = const PointNormalise(1, 1);
        expect(rapport(autre), closeTo(16 / 9, 0.02));
      });
    }

    for (final Size taille in <Size>[
      const Size(1366, 768),
      const Size(390, 844),
    ]) {
      final String nom = '${taille.width.toInt()}x${taille.height.toInt()}';
      testWidgets('zoom, $nom : + et - visibles, la page passe de 100 a '
          '200 %', (WidgetTester tester) async {
        await monterAvecPage(tester, taille);
        final Finder plus = find.byKey(
          const ValueKey<String>('salle-zoom-plus'),
        );
        expect(plus, findsOneWidget);
        // Au premier palier, « moins » n'est pas rendu (jamais grise).
        expect(
          find.byKey(const ValueKey<String>('salle-zoom-moins')),
          findsNothing,
        );
        final double avant = tester
            .getRect(find.byKey(PageCoranSalle.cle))
            .height;
        while (plus.evaluate().isNotEmpty) {
          await tester.tap(plus);
          await tester.pumpAndSettle();
        }
        final double apres = tester
            .getRect(find.byKey(PageCoranSalle.cle))
            .height;
        expect(apres / avant, closeTo(2, 0.01));
        expect(
          find.byKey(const ValueKey<String>('salle-zoom-moins')),
          findsOneWidget,
        );
      });
    }

    // EN-KB (25/10/2026) : la bascule K4 avait perdu M, V, R, B avec
    // `_FocusPanneaux` ; ils reviennent a l'enseignant sur ordinateur, une
    // touche par test.
    Future<FauxMoteurSalle> monterAvecMoi(
      WidgetTester tester, {
      Size taille = const Size(1366, 768),
      bool camera = false,
    }) async {
      final FauxMoteurSalle moteur = await monterAvecPage(tester, taille);
      moteur.publier(<ParticipantSalle>[
        _personne(identite: 't1', role: 'teacher', local: true, camera: camera),
      ]);
      await tester.pumpAndSettle();
      return moteur;
    }

    Future<void> touche(WidgetTester tester, LogicalKeyboardKey cle) async {
      await tester.sendKeyEvent(cle);
      await tester.pumpAndSettle();
    }

    testWidgets('EN-KB, ordinateur : M ouvre le micro', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = await monterAvecMoi(tester);
      await touche(tester, LogicalKeyboardKey.keyM);
      expect(moteur.microDemande, <bool>[true]);
    });

    testWidgets('EN-KB, ordinateur : V coupe la camera, ne l allume jamais', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle allumee = await monterAvecMoi(tester, camera: true);
      await touche(tester, LogicalKeyboardKey.keyV);
      expect(allumee.cameraDemandee, <bool>[false]);
    });

    testWidgets('EN-KB, ordinateur : V n allume pas une camera eteinte', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle eteinte = await monterAvecMoi(tester);
      await touche(tester, LogicalKeyboardKey.keyV);
      expect(eteinte.cameraDemandee, isEmpty);
    });

    // Plan de composition du 26/10/2026 : sur ordinateur, R et B ouvrent
    // et ferment les panneaux (Eleves a gauche, Bibliotheque a droite) ;
    // rien ne s'ouvre au milieu.
    const Key panneauEleves = ValueKey<String>('salle-ordinateur-eleves');

    testWidgets('EN-KB, ordinateur : R ferme puis rouvre les Eleves', (
      WidgetTester tester,
    ) async {
      await monterAvecMoi(tester);
      expect(find.byKey(panneauEleves), findsOneWidget);
      await touche(tester, LogicalKeyboardKey.keyR);
      expect(find.byKey(panneauEleves), findsNothing);
      await touche(tester, LogicalKeyboardKey.keyR);
      expect(find.byKey(panneauEleves), findsOneWidget);
    });

    testWidgets('EN-KB, ordinateur : B ouvre la Bibliotheque', (
      WidgetTester tester,
    ) async {
      // 1366 : la Bibliotheque est ouverte d'office ; B la ferme et la
      // rouvre.
      await monterAvecMoi(tester);
      expect(find.byKey(PanneauBibliothequeSalle.cle), findsOneWidget);
      await touche(tester, LogicalKeyboardKey.keyB);
      expect(find.byKey(PanneauBibliothequeSalle.cle), findsNothing);
      await touche(tester, LogicalKeyboardKey.keyB);
      expect(find.byKey(PanneauBibliothequeSalle.cle), findsOneWidget);
    });

    testWidgets('F : focus, puis retour des panneaux', (
      WidgetTester tester,
    ) async {
      await monterAvecMoi(tester);
      expect(find.byKey(SalleOrdinateur.cleGauche), findsOneWidget);
      await touche(tester, LogicalKeyboardKey.keyF);
      expect(find.byKey(SalleOrdinateur.cleGauche), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleHaut), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleDroite), findsNothing);
      expect(find.byKey(SalleOrdinateur.cleBas), findsOneWidget);
      await touche(tester, LogicalKeyboardKey.keyF);
      expect(find.byKey(SalleOrdinateur.cleGauche), findsOneWidget);
      expect(find.byKey(SalleOrdinateur.cleDroite), findsOneWidget);
    });

    testWidgets('EN-KB, telephone : aucune lettre n agit', (
      WidgetTester tester,
    ) async {
      final FauxMoteurSalle moteur = await monterAvecMoi(
        tester,
        taille: const Size(390, 844),
      );
      await touche(tester, LogicalKeyboardKey.keyM);
      await touche(tester, LogicalKeyboardKey.keyB);
      expect(moteur.microDemande, isEmpty);
      expect(find.text(t.tc.bibliotheque.titre), findsNothing);
    });
  });

  // Lot salle 2 (directeur, 25/10/2026, capture du telephone de l'eleve) :
  // l'attente etait un texte blanc sur gris clair. Surface teintee (jamais
  // du blanc pur), ornement, titre qui nomme l'enseignant attendu, une
  // phrase ; contraste >= 4,5:1, en clair et en sombre.
  group('Lot salle 2 : l attente de l eleve se lit', () {
    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('390 x 844, ${theme.name}', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final FauxMoteurSalle moteur = FauxMoteurSalle();
        await _monterSalle(
          tester,
          themeMode: theme,
          surcharges: _surcharges(
            video: FauxServiceVideo(acces0: _acces('student')),
            moteur: moteur,
            preVol: FauxServicePreVol(),
            presence: FauxServicePresence(
              lignes: <PresenceParticipant>[
                _presence(
                  EtatPresence.enAttente,
                  profilId: 't1',
                  prenom: 'Omar',
                  role: 'teacher',
                ),
                _presence(EtatPresence.presente, profilId: 'p1', prenom: 'Aya'),
              ],
            ),
          ),
        );
        moteur.publier(<ParticipantSalle>[
          _personne(identite: 'p1', role: 'student', nom: 'Aya', local: true),
        ]);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final Finder attente = find.byKey(
          const ValueKey<String>('salle-attente'),
        );
        expect(attente, findsOneWidget);
        final Color fond =
            (tester.widget<DecoratedBox>(attente).decoration as BoxDecoration)
                .color!;
        expect(fond, isNot(const Color(0xFFFFFFFF)));
        for (final String texte in <String>[
          t.salle.attenteDe(deNom: "d'Omar"),
          t.salle.seulEnseignantDetail,
        ]) {
          final Finder f = find.descendant(
            of: attente,
            matching: find.text(texte),
          );
          expect(f, findsOneWidget, reason: texte);
          final Color encre = tester
              .widget<RichText>(
                find.descendant(of: f, matching: find.byType(RichText)),
              )
              .text
              .style!
              .color!;
          expect(
            contraste(encre, fond),
            greaterThanOrEqualTo(4.5),
            reason: texte,
          );
        }
      });
    }
  });

  // Lot salle 2 : la vignette se deplace au doigt et a la souris, aimantee
  // aux quatre coins (standard Meet, FaceTime).
  group('Lot salle 2 : vignette deplacable', () {
    for (final Size taille in <Size>[
      const Size(1366, 768),
      const Size(390, 844),
    ]) {
      testWidgets('${taille.width.toInt()} px : un glisser l emmene au coin '
          'oppose', (WidgetTester tester) async {
        tester.view.physicalSize = taille;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final FauxMoteurSalle moteur = FauxMoteurSalle();
        await _monterSalle(
          tester,
          surcharges: <Override>[
            ..._surcharges(
              video: FauxServiceVideo(acces0: _acces('student')),
              moteur: moteur,
              preVol: FauxServicePreVol(),
            ),
            ...surchargesMadina15(page: 293),
          ],
        );
        moteur
          ..publier(<ParticipantSalle>[
            _personne(
              identite: 't1',
              role: 'teacher',
              nom: 'Omar',
              camera: true,
            ),
            _personne(identite: 'p1', role: 'student', nom: 'Aya', local: true),
          ])
          ..publierContenu(
            ContenuPresente(
              page: 293,
              sourate: 18,
              verset: 1,
              presentePar: 't1',
              emisLe: DateTime.now(),
            ),
          );
        await tester.pumpAndSettle();
        final Finder vignette = find.byKey(VignetteAimantee.cle);
        expect(vignette, findsOneWidget);
        final Rect avant = tester.getRect(vignette);
        // Par defaut, en haut a droite (sens de lecture francais).
        expect(avant.center.dx, greaterThan(taille.width / 2));
        expect(avant.center.dy, lessThan(taille.height / 2));
        await tester.drag(
          vignette,
          Offset(-taille.width * 0.7, taille.height * 0.7),
        );
        await tester.pumpAndSettle();
        final Rect apres = tester.getRect(vignette);
        expect(apres.center.dx, lessThan(taille.width / 2));
        expect(apres.center.dy, greaterThan(taille.height / 2));
        // Aimantee au coin : a 16 du bord.
        expect(apres.left, closeTo(16, 0.5));
      });
    }
  });

  // Lot salle 2 (directeur, 25/10/2026) : la Bibliotheque montre le choix des
  // supports ; la salle reprend a la derniere page presentee dans la classe.
  group('Lot salle 2 : choix du support et reprise de la page', () {
    List<Override> surcharges(FauxMoteurSalle moteur) => <Override>[
      ..._surcharges(
        video: FauxServiceVideo(acces0: _acces('teacher')),
        moteur: moteur,
        preVol: FauxServicePreVol(),
        role: AppRole.teacher,
      ),
      ...surchargesMadina15(page: 604),
      pageCoranProvider.overrideWith(
        (Ref _, int n) async => PageCoran(
          numero: n,
          versets: <VersetCoran>[
            VersetCoran(
              sourateNumero: 114,
              numero: 1,
              texte: 'verset',
              pageNumero: n,
            ),
          ],
        ),
      ),
    ];

    testWidgets('la Bibliotheque montre le Coran, sans promesse, et reprend '
        'la page de la classe', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: surcharges(moteur),
        groupeId: 'g1',
      );
      await moteur.presenterContenu(
        ContenuPresente(
          page: 604,
          sourate: 114,
          verset: 1,
          presentePar: 'p1',
          emisLe: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      // Plan de composition du 26/10/2026 : sur ordinateur, la
      // Bibliotheque est le panneau de droite ; le Coran y est seul.
      expect(find.byKey(PanneauBibliothequeSalle.cle), findsOneWidget);
      expect(find.text(t.salle.supports.coran), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
      );
      await tester.pumpAndSettle();
      final int avant = moteur.contenusPresentesDemandes.length;
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('bibliotheque-reprendre-coran')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('bibliotheque-reprendre-coran')),
      );
      await tester.pumpAndSettle();
      // « Reprendre page 604 » ouvre la page retenue, sans autre question.
      expect(moteur.contenusPresentesDemandes.length, avant + 1);
      expect(moteur.contenusPresentesDemandes.last.page, 604);
    });

    // Lot salle 3 (directeur, 25/10/2026) : la page ne se rouvre plus seule
    // a l'entree ; la Bibliotheque la propose, au choix de l'enseignant.
    testWidgets('page 604, Quitter, retourner : rien ne se rouvre seul, la '
        'Bibliotheque reprend a la page 604', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: surcharges(moteur),
        groupeId: 'g1',
      );
      await moteur.presenterContenu(
        ContenuPresente(
          page: 604,
          sourate: 114,
          verset: 1,
          presentePar: 'p1',
          emisLe: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(_commande(t.salle.seance.sortir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.seance.quitterCahier).last);
      await tester.pumpAndSettle();
      final int avant = moteur.contenusPresentesDemandes.length;
      await tester.tap(find.byKey(FinSeanceEnseignant.retourSalleKey));
      await tester.pumpAndSettle();
      expect(moteur.contenusPresentesDemandes.length, avant);
      expect(find.byKey(_croixRanger), findsNothing);

      // Plan de composition du 26/10/2026 : la Bibliotheque du panneau de
      // droite, « Reprendre page 604 ».
      await tester.tap(
        find.byKey(const ValueKey<String>('bibliotheque-deplier-coran')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('bibliotheque-reprendre-coran')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('bibliotheque-reprendre-coran')),
      );
      await tester.pumpAndSettle();
      expect(moteur.contenusPresentesDemandes.length, avant + 1);
      expect(moteur.contenusPresentesDemandes.last.page, 604);
    });

    testWidgets('Lot salle 3 : entrer, aucun support ; ouvrir, fermer, '
        'sortir, revenir : toujours ferme', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      await _monterSalle(
        tester,
        surcharges: surcharges(moteur),
        groupeId: 'g1',
      );
      // A l'entree : rien de presente, aucune croix.
      expect(moteur.contenusPresentesDemandes, isEmpty);
      expect(find.byKey(_croixRanger), findsNothing);

      // Ouvrir : la croix « Ranger dans la bibliotheque » apparait.
      await moteur.presenterContenu(
        ContenuPresente(
          page: 604,
          sourate: 114,
          verset: 1,
          presentePar: 'p1',
          emisLe: DateTime.now(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_croixRanger), findsOneWidget);
      expect(
        find.bySemanticsLabel(t.salle.seance.rangement.ranger),
        findsOneWidget,
      );

      // Fermer : un contenu retire part a la classe, la croix disparait.
      await tester.tap(find.byKey(_croixRanger));
      await tester.pumpAndSettle();
      expect(moteur.contenusPresentesDemandes.last.estRetire, isTrue);
      expect(find.byKey(_croixRanger), findsNothing);

      // Sortir puis revenir : toujours ferme, rien ne repart seul.
      await tester.tap(_commande(t.salle.seance.sortir));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.salle.seance.quitterCahier).last);
      await tester.pumpAndSettle();
      final int avant = moteur.contenusPresentesDemandes.length;
      await tester.tap(find.byKey(FinSeanceEnseignant.retourSalleKey));
      await tester.pumpAndSettle();
      expect(moteur.contenusPresentesDemandes.length, avant);
      expect(find.byKey(_croixRanger), findsNothing);
    });
  });

  // Directeur, test en production du 26/10/2026 (09:15) : le jeton LiveKit ne
  // porte aucun nom. La salle nomme chacun par l'annuaire de la seance
  // (« Sayyida Amina », « Yasmine »), montre la photo quand elle est connue,
  // et ne rend jamais l'identite technique.
  group('Annuaire de seance : des noms, jamais une identite', () {
    const String idProf = '7c1e9a40-1b2d-4c55-9e1a-0000000000aa';
    const String idEleve = '7c1e9a40-1b2d-4c55-9e1a-0000000000bb';
    const String idInconnu = '7c1e9a40-1b2d-4c55-9e1a-0000000000cc';
    const String url = 'https://exemple.invalid/amina.webp';

    GroupSummaryVM classe(String? photo, {String? seance}) => groupe(
      groupeId: 'g1',
      libelle: 'Classe du soir',
      nombreMembres: 3,
      seuilMax: 6,
      enseignant: EnseignantVM(
        enseignantId: idProf,
        titre: TitreEnseignant.sayyida,
        nomAffichage: 'Amina',
        photoUrlOuCle: photo,
      ),
      prochaineSeance: seance == null
          ? null
          : OccurrenceSeance(
              sessionId: seance,
              debutUtc: DateTime.utc(2026, 10, 26, 18),
              duree: const Duration(hours: 1),
              fuseauReferenceGroupe: 'Europe/Paris',
            ),
    );

    /// [entree] : `billet` (la Classe dans le billet), `accueil` (l'eleve
    /// arrive par son accueil, sans Classe dans le billet), `aucune`.
    Future<void> monter(
      WidgetTester tester, {
      required String? photo,
      String entree = 'billet',
      String role = 'student',
      ProfilEnseignant? profil,
    }) async {
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      final bool prof = role == 'teacher';
      await _monterSalle(
        tester,
        groupeId: entree == 'billet' ? 'g1' : null,
        surcharges: <Override>[
          ..._surcharges(
            video: FauxServiceVideo(acces0: _acces(role)),
            moteur: moteur,
            preVol: FauxServicePreVol(),
            role: prof ? AppRole.teacher : AppRole.student,
            presence: FauxServicePresence(
              lignes: <PresenceParticipant>[
                _presence(
                  EtatPresence.presente,
                  profilId: idProf,
                  prenom: 'Amina',
                  role: 'teacher',
                ),
                _presence(
                  EtatPresence.presente,
                  profilId: idEleve,
                  prenom: 'Yasmine',
                ),
              ],
            ),
          ),
          groupeProvider.overrideWith(
            (Ref _, String _) async =>
                entree == 'billet' ? classe(photo) : null,
          ),
          mesGroupesProvider.overrideWith(
            (Ref _) async => entree == 'accueil'
                ? <GroupSummaryVM>[classe(photo, seance: _seance)]
                : const <GroupSummaryVM>[],
          ),
          profilEnseignantParIdProvider.overrideWith(
            (Ref _, String id) async => id == idProf ? profil : null,
          ),
          photoEnseignantUrlProvider.overrideWith(
            (Ref _, String _) async => url,
          ),
        ],
      );
      // Le jeton ne porte que l'identite : aucun nom.
      moteur.publier(<ParticipantSalle>[
        _personne(identite: idEleve, role: 'student', nom: '', local: !prof),
        _personne(identite: idProf, role: 'teacher', nom: '', local: prof),
        _personne(identite: idInconnu, role: 'student', nom: ''),
      ]);
      await tester.pumpAndSettle();
    }

    void aucuneIdentite(WidgetTester tester) {
      for (final Element e in find.byType(RichText).evaluate()) {
        final String texte = (e.widget as RichText).text.toPlainText();
        for (final String id in <String>[idProf, idEleve, idInconnu]) {
          expect(
            texte,
            isNot(contains(id)),
            reason: 'identite rendue : $texte',
          );
        }
      }
    }

    testWidgets(
      'eleve : Sayyida Amina avec sa photo, l inconnu « Participant »',
      (WidgetTester tester) async {
        await monter(tester, photo: '$idProf/amina.webp');
        expect(find.textContaining('Sayyida Amina'), findsWidgets);
        expect(find.text(t.salle.participant), findsWidgets);
        aucuneIdentite(tester);
        // La photo rendue quand le profil en a une.
        expect(
          tester
              .widgetList<AvatarTile>(find.byType(AvatarTile))
              .where((AvatarTile a) => a.urlSignee == url),
          isNotEmpty,
        );
      },
    );

    testWidgets('sans photo : le cercle des initiales, sans URL', (
      WidgetTester tester,
    ) async {
      await monter(tester, photo: null);
      aucuneIdentite(tester);
      expect(
        tester
            .widgetList<AvatarTile>(find.byType(AvatarTile))
            .where((AvatarTile a) => a.urlSignee != null),
        isEmpty,
      );
    });

    testWidgets('sans Classe connue : le prenom seul, jamais l identite', (
      WidgetTester tester,
    ) async {
      await monter(tester, photo: null, entree: 'aucune');
      expect(find.textContaining('Amina'), findsWidgets);
      expect(find.textContaining('Sayyida'), findsNothing);
      aucuneIdentite(tester);
    });

    // Revue de la PR 60 (26/10/2026) : l'enseignant ne lit pas la vue des
    // familles ; sa propre fiche (`teacher_profiles`) le nomme et le montre.
    testWidgets('enseignant dans sa salle : Sayyida Amina et sa photo, '
        'sans Classe lisible', (WidgetTester tester) async {
      await monter(
        tester,
        photo: null,
        entree: 'aucune',
        role: 'teacher',
        profil: const ProfilEnseignant(
          prenom: 'Amina',
          identifiant: 'RA-26-1001',
          titre: 'sayyida',
          clePhoto: '$idProf/amina.webp',
        ),
      );
      // La salle recoit le nom titre (haut de la salle, vignette) et la
      // photo de sa vignette ; ici, sans camera, aucune image ne la couvre.
      expect(
        tester.widget<SalleSeance>(find.byType(SalleSeance)).vue.nomEnseignant,
        'Sayyida Amina',
      );
      expect(
        tester
            .widget<PorteeMediaSalle>(find.byType(PorteeMediaSalle))
            .photoVignette,
        url,
      );
      aucuneIdentite(tester);
    });

    // Revue de la PR 60 : l'eleve qui entre par son accueil n'a pas de
    // Classe dans son billet ; la Classe de cette seance la donne.
    testWidgets('eleve arrive par son accueil : l enseignant titre', (
      WidgetTester tester,
    ) async {
      await monter(tester, photo: null, entree: 'accueil');
      expect(find.textContaining('Sayyida Amina'), findsWidgets);
      aucuneIdentite(tester);
    });
  });
}

/// La croix « Ranger dans la bibliotheque » de la salle plein ecran.
const Key _croixRanger = ValueKey<String>('salle-ranger-support');
