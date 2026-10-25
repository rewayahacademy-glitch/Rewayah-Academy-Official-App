import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
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
  // Decision du directeur du 25/10/2026 (audit reseau, lot salle 3
  // section 7) : reseaux faibles. Revient sur D15 (24/10/2026 : 720p a
  // 1,2 Mbit/s, adaptiveStream chez l'enseignant seulement).
  test('reseaux faibles : 360p, couche 180p, 450 kbit/s, 20 i/s, parole', () {
    final lk.RoomOptions o = optionsSalle();
    expect(o.adaptiveStream, isTrue, reason: 'pour tous les roles');
    expect(o.dynacast, isTrue);
    expect(
      o.defaultCameraCaptureOptions.params,
      lk.VideoParametersPresets.h360_169,
    );
    final lk.VideoPublishOptions v = o.defaultVideoPublishOptions;
    expect(v.simulcast, isTrue);
    expect(v.videoSimulcastLayers, <lk.VideoParameters>[
      lk.VideoParametersPresets.h180_169,
    ]);
    expect(v.videoEncoding?.maxBitrate, 450000);
    expect(v.videoEncoding?.maxFramerate, 20);
    expect(
      v.degradationPreference,
      lk.DegradationPreference.maintainResolution,
    );
    final lk.AudioPublishOptions a = o.defaultAudioPublishOptions;
    expect(a.encoding?.maxBitrate, 24000);
    expect(a.dtx, isTrue);
    expect(a.red, isTrue);
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
