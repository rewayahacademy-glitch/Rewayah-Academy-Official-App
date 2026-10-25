import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

AccesSalle _acces(String role, {bool camera = false}) => AccesSalle(
  urlServeur: 'wss://exemple.invalid',
  jeton: 'jeton.signe',
  nomSalle: 'r_0123456789abcdef0123456789abcdef',
  fournisseur: FournisseurVideo.cloud,
  role: role,
  capacites: CapacitesSalle(
    peutPublier: true,
    peutPublierVideo: camera,
    peutPublierDonnees: role == 'teacher',
    peutRecevoir: true,
    invisible: false,
  ),
  expireLe: DateTime.utc(2026, 10, 24, 20),
);

void main() {
  test('D15 (S0.2) : adaptiveStream chez l enseignant seulement', () {
    expect(adaptiveStreamPour(_acces('teacher', camera: true)), isTrue);
    expect(adaptiveStreamPour(_acces('student')), isFalse);
    expect(adaptiveStreamPour(_acces('guardian_observer')), isFalse);
  });

  test('lot salle 3 (25/10/2026) : camera fermee a l entree, tous roles', () {
    // Le directeur : la camera d'un compte enfant s'allumait seule (D14,
    // retire). Elle est fermee comme le micro, meme quand le jeton permet
    // l'image ; un appui volontaire l'allume.
    for (final String role in <String>[
      'student',
      'teacher',
      'guardian_observer',
      'controller',
      'admin',
    ]) {
      for (final bool camera in <bool>[true, false]) {
        expect(
          cameraAllumeeALEntree(_acces(role, camera: camera)),
          isFalse,
          reason: '$role, image permise : $camera',
        );
      }
    }
  });

  test('le micro ne s ouvre que par un geste : aucun appel force', () {
    // Le seul appel au micro est celui du geste (`reglerMicro`), qui recoit
    // l'etat voulu ; rien n'ouvre le micro a la connexion.
    final String source = File('lib/core/video/livekit_session_provider.dart')
        .readAsStringSync();
    expect(source.contains('setMicrophoneEnabled(true)'), isFalse);
    expect(RegExp(r'setMicrophoneEnabled\(').allMatches(source), hasLength(1));
  });
}
