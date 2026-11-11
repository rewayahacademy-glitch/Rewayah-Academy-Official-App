// Lot RESEAU-ELEVES (directeur, 11/11/2026) : la qualite du lien de chaque
// participant, filtree contre le clignotement. Un signe ne s'allume ni ne
// s'eteint pour un passage d'une seconde ; la phrase ne vient qu'apres
// plusieurs secondes de mauvais lien.

// fake_async est la dependance de flutter_test qui porte son horloge simulee.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/seuils_reseau.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 17);
DateTime _a(int secondes) => _t0.add(Duration(seconds: secondes));

ParticipantSalle _p(String id, QualiteLien q, {bool local = false}) =>
    ParticipantSalle(
      identite: id,
      nom: id,
      role: 'student',
      estLocal: local,
      micro: true,
      camera: false,
      parle: false,
      qualite: q,
    );

void main() {
  test('les durees sont celles de la regle : 3 s pour un signe, 8 s pour '
      'une phrase, et la phrase vient apres un signe deja stable', () {
    expect(tenueAvantChangement, const Duration(seconds: 3));
    expect(tenueAvantAlerte, const Duration(seconds: 8));
    expect(tenueAvantAlerte > tenueAvantChangement * 2, isTrue);
  });

  test('le seuil est celui du repli audio : mediocre et perdue seulement', () {
    expect(lienMauvais(QualiteLien.mediocre), isTrue);
    expect(lienMauvais(QualiteLien.perdue), isTrue);
    expect(lienMauvais(QualiteLien.bonne), isFalse);
    expect(lienMauvais(QualiteLien.excellente), isFalse);
    expect(lienMauvais(QualiteLien.inconnue), isFalse);
  });

  test('sans mesure stable : aucune barre (jamais un signal invente)', () {
    final FiltreQualite f = FiltreQualite();
    expect(f.etat(_t0).barres, isNull);
    f.mesurer(QualiteLien.excellente, _t0);
    expect(f.etat(_a(1)).barres, isNull, reason: 'pas encore 3 s');
    expect(f.etat(_a(3)).barres, 3);
  });

  test('la qualite qui change : 3, puis 1 barre, puis 3, chaque fois apres '
      '3 s tenues', () {
    final FiltreQualite f = FiltreQualite()
      ..mesurer(QualiteLien.excellente, _t0);
    expect(f.etat(_a(3)).barres, 3);
    f.mesurer(QualiteLien.mediocre, _a(10));
    expect(f.etat(_a(12)).barres, 3);
    expect(f.etat(_a(13)).barres, 1);
    expect(f.etat(_a(13)).faible, isTrue);
    f.mesurer(QualiteLien.bonne, _a(30));
    expect(f.etat(_a(32)).barres, 1);
    expect(f.etat(_a(33)).barres, 2);
  });

  test(
    'anti-clignotement : un mauvais passage d une seconde n allume rien',
    () {
      final FiltreQualite f = FiltreQualite()
        ..mesurer(QualiteLien.excellente, _t0);
      expect(f.etat(_a(5)).barres, 3);
      f.mesurer(QualiteLien.mediocre, _a(10));
      f.mesurer(QualiteLien.excellente, _a(11));
      for (int s = 10; s <= 30; s++) {
        expect(f.etat(_a(s)).barres, 3, reason: 'a ${s}s');
        expect(f.etat(_a(s)).alerte, isFalse);
      }
    },
  );

  test('anti-clignotement : un bon passage d une seconde n eteint ni le '
      'signe ni la phrase', () {
    final FiltreQualite f = FiltreQualite()..mesurer(QualiteLien.mediocre, _t0);
    expect(f.etat(_a(8)).alerte, isTrue);
    f.mesurer(QualiteLien.excellente, _a(20));
    f.mesurer(QualiteLien.mediocre, _a(21));
    for (int s = 20; s <= 40; s++) {
      expect(f.etat(_a(s)).barres, 1, reason: 'a ${s}s');
      expect(f.etat(_a(s)).alerte, isTrue, reason: 'a ${s}s');
    }
  });

  test('la phrase : apres 8 s de mauvais lien, pas avant ; elle part quand '
      'le lien est redevenu bon 3 s', () {
    final FiltreQualite f = FiltreQualite()
      ..mesurer(QualiteLien.excellente, _t0);
    f.mesurer(QualiteLien.mediocre, _a(10));
    expect(f.etat(_a(13)).alerte, isFalse, reason: 'signe seul');
    expect(f.etat(_a(17)).alerte, isFalse);
    expect(f.etat(_a(18)).alerte, isTrue);
    // Mediocre puis perdue : le mauvais lien continue, la phrase reste.
    f.mesurer(QualiteLien.perdue, _a(20));
    expect(f.etat(_a(23)).barres, 0);
    expect(f.etat(_a(23)).alerte, isTrue);
    f.mesurer(QualiteLien.bonne, _a(30));
    expect(f.etat(_a(32)).alerte, isTrue);
    expect(f.etat(_a(33)).alerte, isFalse);
    expect(f.etat(_a(33)).barres, 2);
  });

  test('l echeance suivante : la minuterie sait quand regarder de nouveau', () {
    final FiltreQualite f = FiltreQualite()..mesurer(QualiteLien.mediocre, _t0);
    expect(f.prochaineEcheance(_t0), _a(3));
    expect(f.prochaineEcheance(_a(3)), _a(8));
    expect(f.prochaineEcheance(_a(8)), isNull);
  });

  test('SuiviReseau : la minuterie rappelle la salle sans nouvelle mesure, '
      'et rien d autre ne sort', () {
    fakeAsync((FakeAsync async) {
      DateTime maintenant = _t0;
      int rappels = 0;
      final SuiviReseau suivi = SuiviReseau(
        quandChange: () => rappels++,
        horloge: () => maintenant,
      );
      suivi.mesurer(<ParticipantSalle>[
        _p('moi', QualiteLien.excellente, local: true),
        _p('yasmine', QualiteLien.mediocre),
      ]);
      expect(suivi.etats(), isEmpty, reason: 'aucune mesure stable');

      maintenant = _a(3);
      async.elapse(const Duration(seconds: 3));
      expect(rappels, 1);
      expect(suivi.etats()['moi']?.barres, 3);
      expect(suivi.etats()['yasmine']?.barres, 1);
      expect(suivi.etats()['yasmine']?.alerte, isFalse);

      maintenant = _a(8);
      async.elapse(const Duration(seconds: 5));
      expect(rappels, 2);
      expect(suivi.etats()['yasmine']?.alerte, isTrue);

      // Yasmine sort : son etat est oublie.
      suivi.mesurer(<ParticipantSalle>[
        _p('moi', QualiteLien.excellente, local: true),
      ]);
      expect(suivi.etats().containsKey('yasmine'), isFalse);
      async.elapse(const Duration(minutes: 1));
      expect(rappels, 2, reason: 'plus rien en attente');
      suivi.fermer();
    });
  });
}
