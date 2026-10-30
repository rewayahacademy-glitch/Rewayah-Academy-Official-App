import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart'
    show groupesEnseignantProvider;
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/politique_camera.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';

// K4 n° 13 (pilote, 30/10/2026) : un nouveau jeton quand la politique de
// camera de l'eleve change pendant la seance.

AccesSalle _acces(String role, {bool camera = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.$camera',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: role == 'teacher' || camera,
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

/// La politique en memoire ; `null` : illisible.
class _FaussePolitique implements PolitiqueCamera {
  bool? autorisee = false;
  final List<String> lectures = <String>[];

  @override
  Future<bool?> cameraAutorisee(String eleveId) async {
    lectures.add(eleveId);
    return autorisee;
  }
}

List<Override> _surcharges({
  required AppRole role,
  required FauxServiceVideo video,
  required FauxMoteurSalle moteur,
  required _FaussePolitique politique,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: role,
        profileId: 'p1',
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(video),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(),
  ),
  portAnnonceObservationProvider.overrideWithValue(FauxAnnonceObservation()),
  groupesEnseignantProvider.overrideWith(
    (Ref _) async => const <GroupeEnseignant>[],
  ),
  politiqueCameraProvider.overrideWithValue(politique),
];

Future<void> _monter(WidgetTester tester, List<Override> surcharges) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.salle,
      surcharges: surcharges,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.salle,
          builder: (BuildContext _, GoRouterState _) =>
              const SallePage(seanceId: 's1'),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

ParticipantSalle _moi({required bool micro}) => ParticipantSalle(
  identite: 'p1',
  nom: 'Yanis',
  role: 'student',
  estLocal: true,
  micro: micro,
  camera: false,
  parle: false,
  qualite: QualiteLien.bonne,
);

void main() {
  group('jetonCameraPerime', () {
    test('un eleve dont la politique a change', () {
      expect(
        jetonCameraPerime(_acces('student'), cameraAutorisee: true),
        isTrue,
      );
      expect(
        jetonCameraPerime(
          _acces('student', camera: true),
          cameraAutorisee: false,
        ),
        isTrue,
      );
    });

    test('rien quand la politique suit le jeton ou est illisible', () {
      expect(
        jetonCameraPerime(_acces('student'), cameraAutorisee: false),
        isFalse,
      );
      expect(
        jetonCameraPerime(_acces('student'), cameraAutorisee: null),
        isFalse,
      );
    });

    test('jamais pour un autre role que l eleve', () {
      expect(
        jetonCameraPerime(_acces('teacher'), cameraAutorisee: false),
        isFalse,
      );
      expect(
        jetonCameraPerime(_acces('guardian_observer'), cameraAutorisee: true),
        isFalse,
      );
    });
  });

  group('La salle de l eleve suit sa politique de camera', () {
    testWidgets('camera ouverte par le tuteur : nouveau jeton, micro garde', (
      WidgetTester tester,
    ) async {
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student'),
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      final _FaussePolitique politique = _FaussePolitique();
      await _monter(
        tester,
        _surcharges(
          role: AppRole.student,
          video: video,
          moteur: moteur,
          politique: politique,
        ),
      );
      expect(moteur.entrees, hasLength(1));
      moteur.publier(<ParticipantSalle>[_moi(micro: true)]);
      await tester.pump();

      // Rien ne change : aucune demande de jeton.
      await tester.pump(intervallePolitiqueCamera);
      expect(politique.lectures, <String>['p1']);
      expect(video.demandes, hasLength(1));

      // Le tuteur ouvre la camera.
      politique.autorisee = true;
      video.acces0 = _acces('student', camera: true);
      await tester.pump(intervallePolitiqueCamera);
      await tester.pump();

      expect(video.demandes, hasLength(2));
      expect(moteur.entrees, hasLength(2));
      expect(moteur.entrees.last.capacites.peutPublierVideo, isTrue);
      expect(moteur.microDemande, <bool>[true]);

      // Le jeton suit la politique : plus de nouvelle demande.
      await tester.pump(intervallePolitiqueCamera);
      expect(video.demandes, hasLength(2));
    });

    testWidgets('camera fermee par le tuteur : le jeton la retire', (
      WidgetTester tester,
    ) async {
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('student', camera: true),
      );
      final FauxMoteurSalle moteur = FauxMoteurSalle();
      final _FaussePolitique politique = _FaussePolitique()..autorisee = true;
      await _monter(
        tester,
        _surcharges(
          role: AppRole.student,
          video: video,
          moteur: moteur,
          politique: politique,
        ),
      );

      politique.autorisee = false;
      video.acces0 = _acces('student');
      await tester.pump(intervallePolitiqueCamera);
      await tester.pump();

      expect(moteur.entrees, hasLength(2));
      expect(moteur.entrees.last.capacites.peutPublierVideo, isFalse);
      expect(moteur.microDemande, isEmpty);
    });

    testWidgets('l enseignant ne relit rien', (WidgetTester tester) async {
      final FauxServiceVideo video = FauxServiceVideo(
        acces0: _acces('teacher'),
      );
      final _FaussePolitique politique = _FaussePolitique();
      await _monter(
        tester,
        _surcharges(
          role: AppRole.teacher,
          video: video,
          moteur: FauxMoteurSalle(),
          politique: politique,
        ),
      );
      await tester.pump(intervallePolitiqueCamera * 2);
      expect(politique.lectures, isEmpty);
    });
  });
}
