// SCENE-CLASSE (directeur, 11/11/2026) : captures de TEST de la scene en mode
// Classe, rendue par la vraie page `/salle` (`SallePage`) avec le faux moteur
// du harnais (aucune video : les cadres montrent la photo ou l'initiale ;
// quelques-uns ont une « image », un aplat, pour montrer l'etiquette du nom).
// La preuve qui fait foi reste le banc (vraie application) :
// `docs/current/captures/E2E/salle-banc/scene-classe-*`.
//
// CAPTURE_DIR=$PWD/docs/current/captures/E2E/scene-classe \
//   flutter test test/capture/scene_classe_capture_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/port_annonce_observation.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';
import 'package:rewayah_academy/core/widgets/grille_visages.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import '../support/harnais.dart';
import '../teaching_core/e/faux/faux_classe.dart';
import 'outil_capture.dart';

AccesSalle _acces(String role) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: true,
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.now().add(const Duration(minutes: 10)),
);

const List<String> _prenoms = <String>[
  'Yasmine',
  'Ilyes',
  'Maryam',
  'Abdurrahman',
  'Khadija',
  'Yusuf',
];

/// La classe de [n] personnes vue par [role] : l'enseignant, des eleves, et
/// soi-meme (camera allumee).
List<ParticipantSalle> _classe(String role, int n) {
  final bool enseignant = role == 'teacher';
  return <ParticipantSalle>[
    ParticipantSalle(
      identite: 't1',
      nom: 'Omar',
      role: 'teacher',
      estLocal: enseignant,
      micro: true,
      camera: true,
      parle: false,
      qualite: QualiteLien.bonne,
    ),
    for (int i = 0; i < n - 1; i++)
      ParticipantSalle(
        identite: 'e$i',
        nom: _prenoms[i],
        role: 'student',
        estLocal: !enseignant && i == n - 2,
        micro: i.isOdd,
        camera: true,
        parle: false,
        qualite: QualiteLien.bonne,
      ),
  ];
}

Future<void> _capturer(
  WidgetTester tester,
  String nom, {
  required String role,
  required int n,
  required Size taille,
  ThemeMode theme = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, taille.width < 600 ? 2 : 1);
  final FauxMoteurSalle moteur = FauxMoteurSalle()
    ..avecImage.addAll(<String>['t1', 'e1']);
  await tester.pumpWidget(
    hoteCapture(
      const SallePage(seanceId: 's1'),
      surcharges: <Override>[
        sourceSessionProvider.overrideWithValue(
          FausseSourceSession(
            SessionState(
              resolue: true,
              role: role == 'teacher' ? AppRole.teacher : AppRole.student,
              profileId: role == 'teacher' ? 't1' : 'e${n - 2}',
              accountStatus: AccountStatus.active,
              lectureProfil: LectureProfil.presente,
            ),
          ),
        ),
        servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
        serviceVideoProvider.overrideWithValue(
          FauxServiceVideo(acces0: _acces(role)),
        ),
        moteurSalleProvider.overrideWithValue(moteur),
        servicePresenceProvider.overrideWithValue(FauxServicePresence()),
        portAnnonceObservationEnfantProvider.overrideWithValue(
          FauxAnnonceObservationEnfant(observe: false),
        ),
        portAnnonceObservationProvider.overrideWithValue(
          FauxAnnonceObservation(lignes: const <AnnonceObservation>[]),
        ),
      ],
      themeMode: theme,
    ),
  );
  await tester.pumpAndSettle();
  moteur.publier(_classe(role, n));
  await tester.pumpAndSettle();
  expect(find.byKey(GrilleVisages.cle), findsOneWidget);
  expect(tester.takeException(), isNull);
  debugPrint('PNG ${await capturer(tester, nom)}');
}

void main() {
  group('Capture : SCENE-CLASSE', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final int n in <int>[2, 3, 4, 6, 7]) {
      for (final (Size taille, String nomTaille) in const <(Size, String)>[
        (Size(390, 844), '390'),
        (Size(1440, 900), '1440'),
      ]) {
        testWidgets('eleve $n personnes $nomTaille', (
          WidgetTester tester,
        ) async {
          await _capturer(
            tester,
            'sceneclasse_eleve_${n}p_${nomTaille}_clair',
            role: 'student',
            n: n,
            taille: taille,
          );
        });
      }
    }
    for (final (Size taille, String nomTaille) in const <(Size, String)>[
      (Size(390, 844), '390'),
      (Size(1440, 900), '1440'),
    ]) {
      testWidgets('eleve 7 personnes $nomTaille sombre', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'sceneclasse_eleve_7p_${nomTaille}_sombre',
          role: 'student',
          n: 7,
          taille: taille,
          theme: ThemeMode.dark,
        );
      });
      testWidgets('enseignant 4 personnes $nomTaille', (
        WidgetTester tester,
      ) async {
        await _capturer(
          tester,
          'sceneclasse_enseignant_4p_${nomTaille}_clair',
          role: 'teacher',
          n: 4,
          taille: taille,
        );
      });
    }
    testWidgets('eleve 4 personnes 390 arabe', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _capturer(
        tester,
        'sceneclasse_eleve_4p_390_clair_ar',
        role: 'student',
        n: 4,
        taille: const Size(390, 844),
      );
    });
  });
}
