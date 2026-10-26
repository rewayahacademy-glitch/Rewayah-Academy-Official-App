import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/repli_audio.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

List<NiveauRepli> _suite(List<QualiteLien> mesures) {
  final RepliAudio repli = RepliAudio();
  return <NiveauRepli>[for (final QualiteLien q in mesures) repli.mesurer(q)];
}

/// Lot salle 3 (audit reseau du 25/10/2026) : repli audio seul avec
/// hysteresis, jamais de clignotement.
void main() {
  test('mauvais, bon, mauvais : la video ne revient pas entre les deux', () {
    expect(
      _suite(<QualiteLien>[
        QualiteLien.mediocre,
        QualiteLien.bonne,
        QualiteLien.mediocre,
      ]),
      <NiveauRepli>[
        NiveauRepli.videoBasse,
        NiveauRepli.videoBasse,
        NiveauRepli.videoBasse,
      ],
    );
  });

  test('retour seulement apres deux bonnes mesures consecutives', () {
    expect(
      _suite(<QualiteLien>[
        QualiteLien.mediocre,
        QualiteLien.bonne,
        QualiteLien.excellente,
      ]),
      <NiveauRepli>[
        NiveauRepli.videoBasse,
        NiveauRepli.videoBasse,
        NiveauRepli.aucun,
      ],
    );
  });

  test('perdu : audio seul, qui ne remonte pas sur une mesure mediocre', () {
    expect(
      _suite(<QualiteLien>[
        QualiteLien.perdue,
        QualiteLien.mediocre,
        QualiteLien.bonne,
        QualiteLien.bonne,
      ]),
      <NiveauRepli>[
        NiveauRepli.audioSeul,
        NiveauRepli.audioSeul,
        NiveauRepli.audioSeul,
        NiveauRepli.aucun,
      ],
    );
  });

  test('une mesure inconnue ne change rien, ni n interrompt le compte', () {
    final RepliAudio repli = RepliAudio();
    expect(repli.mesurer(QualiteLien.inconnue), NiveauRepli.aucun);
    repli
      ..mesurer(QualiteLien.mediocre)
      ..mesurer(QualiteLien.bonne);
    expect(repli.mesurer(QualiteLien.inconnue), NiveauRepli.videoBasse);
    expect(repli.mesurer(QualiteLien.bonne), NiveauRepli.aucun);
    expect(repli.videoSuspendue, isFalse);
  });
}
