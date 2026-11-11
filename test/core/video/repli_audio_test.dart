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

  // Defaut R-3 du constat de la salle (11/11/2026) : LiveKit ne publie la
  // qualite qu'a ses changements ; sans battement, l'image ne revenait jamais.
  group('battement', () {
    test('mediocre puis bon et stable : un battement ramene la video', () {
      final RepliAudio repli = RepliAudio()
        ..mesurer(QualiteLien.mediocre)
        ..mesurer(QualiteLien.bonne);
      expect(repli.niveau, NiveauRepli.videoBasse);
      expect(repli.battre(), NiveauRepli.aucun);
    });

    test('le lien reste mediocre : les battements ne ramenent rien', () {
      final RepliAudio repli = RepliAudio()..mesurer(QualiteLien.mediocre);
      expect(repli.battre(), NiveauRepli.videoBasse);
      expect(repli.battre(), NiveauRepli.videoBasse);
      expect(repli.battre(), NiveauRepli.videoBasse);
    });

    test('lien perdu puis bon : deux mesures, dont un battement', () {
      final RepliAudio repli = RepliAudio()
        ..mesurer(QualiteLien.perdue)
        ..mesurer(QualiteLien.excellente);
      expect(repli.niveau, NiveauRepli.audioSeul);
      expect(repli.battre(), NiveauRepli.aucun);
    });

    test('sans mesure, ou apres une mesure inconnue, rien ne change', () {
      final RepliAudio repli = RepliAudio();
      expect(repli.battre(), NiveauRepli.aucun);
      repli
        ..mesurer(QualiteLien.mediocre)
        ..mesurer(QualiteLien.inconnue);
      expect(repli.derniereMesure, QualiteLien.mediocre);
      expect(repli.battre(), NiveauRepli.videoBasse);
    });

    test('remettre efface la derniere mesure', () {
      final RepliAudio repli = RepliAudio()
        ..mesurer(QualiteLien.mediocre)
        ..remettre();
      expect(repli.derniereMesure, isNull);
      expect(repli.battre(), NiveauRepli.aucun);
    });
  });
}
