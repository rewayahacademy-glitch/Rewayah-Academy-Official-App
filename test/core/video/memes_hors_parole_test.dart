import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

ParticipantSalle _p({bool parle = false, bool micro = true}) =>
    ParticipantSalle(
      identite: 'a',
      nom: 'A',
      role: 'student',
      estLocal: false,
      micro: micro,
      camera: false,
      parle: parle,
      qualite: QualiteLien.excellente,
    );

void main() {
  test('Lot salle 3 (e) : un changement d orateur seul ne compte pas', () {
    expect(
      memesHorsParole(
        <ParticipantSalle>[_p()],
        <ParticipantSalle>[_p(parle: true)],
      ),
      isTrue,
    );
  });

  test('Lot salle 3 (e) : un micro, une arrivee ou un depart comptent', () {
    expect(
      memesHorsParole(
        <ParticipantSalle>[_p()],
        <ParticipantSalle>[_p(micro: false)],
      ),
      isFalse,
    );
    expect(
      memesHorsParole(<ParticipantSalle>[_p()], <ParticipantSalle>[_p(), _p()]),
      isFalse,
    );
    expect(
      memesHorsParole(<ParticipantSalle>[_p()], <ParticipantSalle>[]),
      isFalse,
    );
  });
}
