// RUBAN-TELEPHONE (directeur, 11/11/2026) : captures de TEST du ruban (la
// vignette de l'enseignant, la bande de cote, la capsule rangee, son propre
// cadre quand on est seul), rendues par la vraie page `/salle` (`SallePage`)
// avec le faux moteur du harnais : les « images » sont des aplats vides (le
// cadre montre son fond et la pastille du nom). Ce ne sont pas des captures
// de la vraie application ; le banc les refera apres fusion.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/ruban-telephone \
//   flutter test test/capture/ruban_telephone_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/coran/service_coran.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/tc_realtime/codec_message_pedagogique.dart';
import 'package:rewayah_academy/core/tc_realtime/port_realtime_pedagogique.dart'
    show MessagePedagogique;
import 'package:rewayah_academy/core/tc_realtime/types_message.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/synchro_salle.dart'
    show typeParoleSalle;

import '../support/harnais.dart';
import '../support/mushaf_15l.dart'
    show chargerPoliceMadina15, surchargesMadina15;
import '../teaching_core/e/faux/faux_classe.dart';
import 'outil_capture.dart';

const String _seance = 's1';

AccesSalle _acces(String role, {bool differee = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: role == 'teacher' || role == 'student',
    peutPublierVideo: role == 'teacher' || role == 'student',
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: role == 'masked_controller',
  ),
  publicationDifferee: differee,
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

String _profil(String role) => switch (role) {
  'teacher' => 't1',
  'guardian_observer' => 'g1',
  'masked_controller' => 'c1',
  _ => 'e1',
};

ParticipantSalle _personne(
  String id,
  String role, {
  required bool local,
  bool camera = true,
}) => ParticipantSalle(
  identite: id,
  nom: '',
  role: role,
  estLocal: local,
  micro: false,
  camera: camera,
  parle: false,
  qualite: QualiteLien.bonne,
);

PresenceParticipant _ligne(String id, String prenom, String role) =>
    PresenceParticipant(
      seanceId: _seance,
      profilId: id,
      role: role,
      prenom: prenom,
      identifiantImmuable: 'RA-26-$id',
      etat: EtatPresence.presente,
      consolide: false,
      entreLe: DateTime.now(),
    );

List<Override> _surcharges(
  String role,
  FauxMoteurSalle moteur, {
  bool differee = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(
      SessionState(
        resolue: true,
        role: switch (role) {
          'teacher' => AppRole.teacher,
          'guardian_observer' => AppRole.guardian,
          'masked_controller' => AppRole.controller,
          _ => AppRole.student,
        },
        profileId: _profil(role),
        accountStatus: AccountStatus.active,
        lectureProfil: LectureProfil.presente,
      ),
    ),
  ),
  servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
  serviceVideoProvider.overrideWithValue(
    FauxServiceVideo(acces0: _acces(role, differee: differee)),
  ),
  moteurSalleProvider.overrideWithValue(moteur),
  servicePresenceProvider.overrideWithValue(
    FauxServicePresence(
      lignes: <PresenceParticipant>[
        _ligne('t1', 'Amina', 'teacher'),
        _ligne('e1', 'Yasmine', 'student'),
        _ligne('e2', 'Ilyes', 'student'),
      ],
    ),
  ),
  portAnnonceObservationEnfantProvider.overrideWithValue(
    FauxAnnonceObservationEnfant(observe: false),
  ),
  portAnnonceObservationProvider.overrideWithValue(
    FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
  ),
  ...surchargesMadina15(page: 42),
  profilEnseignantParIdProvider.overrideWith(
    (Ref _, String id) async => id == 't1'
        ? const ProfilEnseignant(
            prenom: 'Amina',
            identifiant: 'RA-26-t1',
            titre: 'sayyida',
          )
        : null,
  ),
  pageCoranProvider.overrideWith(
    (Ref _, int n) async => PageCoran(
      numero: n,
      versets: <VersetCoran>[
        VersetCoran(
          sourateNumero: 2,
          numero: 255,
          texte: 'verset',
          pageNumero: n,
        ),
      ],
    ),
  ),
];

/// La classe : l'enseignant, deux eleves, et la personne devant l'ecran.
List<ParticipantSalle> _classe(String role, {bool seul = false}) {
  final String moi = _profil(role);
  return <ParticipantSalle>[
    if (!seul) ...<ParticipantSalle>[
      _personne('t1', 'teacher', local: moi == 't1'),
      _personne('e1', 'student', local: moi == 'e1'),
      _personne('e2', 'student', local: false),
    ],
    if (seul || (moi != 't1' && moi != 'e1'))
      _personne(moi, role, local: true, camera: seul || role == 'student'),
  ];
}

Future<FauxMoteurSalle> _monter(
  WidgetTester tester, {
  required String role,
  Size taille = const Size(390, 844),
  ThemeMode theme = ThemeMode.light,
  bool document = true,
  bool seul = false,
  bool cameraSeul = true,
  bool differee = false,
}) async {
  fixerVueCapture(tester, taille, taille.width < 600 ? 2 : 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle()
    ..avecImage.addAll(<String>['t1', 'e1', 'e2', 'g1', 'c1']);
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: _seance),
      surcharges: _surcharges(role, moteur, differee: differee),
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  final List<ParticipantSalle> classe = seul
      ? <ParticipantSalle>[
          _personne(_profil(role), role, local: true, camera: cameraSeul),
        ]
      : _classe(role);
  moteur.publier(classe);
  moteur.publierQualite(QualiteLien.bonne);
  await tester.pumpAndSettle();
  if (document) await _presenter(tester, moteur);
  return moteur;
}

ContenuPresente get _page42 => ContenuPresente(
  page: 42,
  sourate: 2,
  verset: 255,
  presentePar: 't1',
  emisLe: DateTime.now(),
);

Future<void> _presenter(WidgetTester tester, FauxMoteurSalle moteur) async {
  moteur.publierContenu(_page42);
  await tester.pumpAndSettle();
}

/// L'enseignant donne la parole a [profil] (recu par la classe).
Future<void> _parole(
  WidgetTester tester,
  FauxMoteurSalle moteur,
  String profil,
  String prenom,
) async {
  moteur.recevoirDonnees(
    PaquetDonnees(
      sujet: sujetProtocolePedagogique,
      charge: messageVersOctets(
        MessagePedagogique(
          type: typeParoleSalle,
          sessionId: _seance,
          emetteurProfilId: 't1',
          charge: <String, dynamic>{'profil': profil, 'prenom': prenom},
          emisLeUtc: DateTime.utc(2026, 11, 11, 10),
        ),
      ),
      fiable: true,
      emetteurIdentite: 't1',
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

/// Un toucher de l'ecran : les commandes reviennent.
Future<void> _toucher(WidgetTester tester) async {
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
}

typedef _Scene = ({
  String nom,
  String role,
  Size taille,
  bool document,
  bool seul,
  bool recite,
  ThemeMode theme,
  bool arabe,
});

_Scene _s(
  String nom,
  String role,
  Size taille, {
  bool document = true,
  bool seul = false,
  bool recite = false,
  ThemeMode theme = ThemeMode.light,
  bool arabe = false,
}) => (
  nom: nom,
  role: role,
  taille: taille,
  document: document,
  seul: seul,
  recite: recite,
  theme: theme,
  arabe: arabe,
);

const Size _t390 = Size(390, 844);
const Size _t1440 = Size(1440, 900);

final List<_Scene> _scenes = <_Scene>[
  _s('eleve_390_classe_clair', 'student', _t390, document: false),
  _s('eleve_390_document_clair', 'student', _t390),
  _s('eleve_390_document_sombre', 'student', _t390, theme: ThemeMode.dark),
  _s('eleve_390_recitation_clair', 'student', _t390, recite: true),
  _s('eleve_390_document_clair_ar', 'student', _t390, arabe: true),
  _s(
    'eleve_390_seul_camera_clair',
    'student',
    _t390,
    document: false,
    seul: true,
  ),
  _s(
    'eleve_390_seul_camera_sombre',
    'student',
    _t390,
    document: false,
    seul: true,
    theme: ThemeMode.dark,
  ),
  _s('eleve_1440_classe_clair', 'student', _t1440, document: false),
  _s('eleve_1440_document_clair', 'student', _t1440),
  _s('eleve_1440_recitation_clair', 'student', _t1440, recite: true),
  _s(
    'eleve_1440_recitation_sombre',
    'student',
    _t1440,
    recite: true,
    theme: ThemeMode.dark,
  ),
  _s(
    'eleve_1440_recitation_clair_ar',
    'student',
    _t1440,
    recite: true,
    arabe: true,
  ),
  _s(
    'eleve_1440_seul_camera_clair',
    'student',
    _t1440,
    document: false,
    seul: true,
  ),
  _s('enseignant_390_classe_clair', 'teacher', _t390, document: false),
  _s('enseignant_390_document_clair', 'teacher', _t390),
  _s('enseignant_390_document_sombre', 'teacher', _t390, theme: ThemeMode.dark),
  _s('enseignant_390_document_clair_ar', 'teacher', _t390, arabe: true),
  _s(
    'enseignant_390_seul_clair',
    'teacher',
    _t390,
    document: false,
    seul: true,
  ),
];

void main() {
  group('Capture : RUBAN-TELEPHONE', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
      await chargerPoliceMadina15();
    });
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    for (final _Scene s in _scenes) {
      testWidgets(s.nom, (WidgetTester tester) async {
        if (s.arabe) {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
        }
        final FauxMoteurSalle moteur = await _monter(
          tester,
          role: s.role,
          taille: s.taille,
          theme: s.theme,
          document: s.document,
          seul: s.seul,
        );
        if (s.recite) await _parole(tester, moteur, 'e2', 'Ilyes');
        // Les commandes et le ruban, au toucher.
        if (!s.seul) await _toucher(tester);
        expect(tester.takeException(), isNull);
        debugPrint('PNG ${await capturer(tester, 'ruban_${s.nom}')}');
      });
    }
  });
}
