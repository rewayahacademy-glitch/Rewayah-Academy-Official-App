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

  test('D14 : la camera de l eleve autorise s allume a l entree', () {
    expect(cameraAllumeeALEntree(_acces('student', camera: true)), isTrue);
    expect(cameraAllumeeALEntree(_acces('student')), isFalse);
    expect(cameraAllumeeALEntree(_acces('teacher', camera: true)), isFalse);
  });
}
