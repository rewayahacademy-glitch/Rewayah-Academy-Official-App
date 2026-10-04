// COM-VOC-1 : la machine du composer vocal, avec une horloge fixe. Les
// dix-sept etats de la spec (11.2), les durees exactes malgre les pauses, la
// limite de 3:00 (R-COM-04), et la regle centrale : aucun etat d'arret ne
// mene a l'envoi, seul `envoyer()` y mene (11.3).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_vocal/etats_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 4, 10);
DateTime _a(int secondes) => _t0.add(Duration(seconds: secondes));

void main() {
  test('dix-sept etats, dans l ordre de la spec', () {
    expect(EtatVocal.values, hasLength(17));
    expect(EtatVocal.values.first, EtatVocal.repos);
    expect(EtatVocal.values[7], EtatVocal.limiteAtteinte);
    expect(EtatVocal.values.last, EtatVocal.finLecture);
  });

  test('la limite V1 vaut 3:00, la limite proche 2:30', () {
    expect(dureeMaxVocal, const Duration(minutes: 3));
    expect(seuilLimiteProcheVocal, const Duration(minutes: 2, seconds: 30));
    final MachineEnregistrementVocal m = MachineEnregistrementVocal();
    expect(m.dureeMax, dureeMaxVocal);
  });

  test(
    'R-COM-03 : pause, reprise, arret, pre-ecoute ; la pause ne compte pas',
    () {
      final MachineEnregistrementVocal m = MachineEnregistrementVocal()
        ..demarrer(_a(0));
      expect(m.etat, EtatVocal.enregistrement);
      expect(m.ecoule(_a(5)), const Duration(seconds: 5));

      m.mettreEnPause(_a(5));
      expect(m.etat, EtatVocal.pause);
      expect(m.ecoule(_a(60)), const Duration(seconds: 5));

      m.reprendre(_a(60));
      expect(m.etat, EtatVocal.reprise);
      expect(m.ecoule(_a(67)), const Duration(seconds: 12));

      expect(m.arreter(_a(67)), const Duration(seconds: 12));
      expect(m.etat, EtatVocal.preEcoute);
      expect(m.duree, const Duration(seconds: 12));
      expect(m.ecoule(_a(500)), const Duration(seconds: 12));
    },
  );

  test('aucun arret ne mene a l envoi : seul envoyer() y mene', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal()
      ..demarrer(_a(0))
      ..arreter(_a(10));
    expect(m.etat, isNot(EtatVocal.envoi));
    final MachineEnregistrementVocal limite = MachineEnregistrementVocal()
      ..demarrer(_a(0));
    expect(limite.tic(_a(180)), isTrue);
    limite.arreter(_a(180), limite: true);
    expect(limite.etat, EtatVocal.limiteAtteinte);
    expect(limite.etat, isNot(EtatVocal.envoi));

    m.envoyer();
    expect(m.etat, EtatVocal.envoi);
  });

  test('R-COM-04 : limite proche a 2:30, arret a 3:00, duree bornee', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal()
      ..demarrer(_a(0));
    expect(m.tic(_a(149)), isFalse);
    expect(m.etat, EtatVocal.enregistrement);
    expect(m.tic(_a(150)), isFalse);
    expect(m.etat, EtatVocal.limiteProche);
    expect(m.restant(_a(150)), const Duration(seconds: 30));
    expect(m.tic(_a(180)), isTrue);
    // L'arret arrive en retard : la duree reste bornee a 3:00.
    expect(m.arreter(_a(185), limite: true), dureeMaxVocal);
    expect(m.etat, EtatVocal.limiteAtteinte);
  });

  test('reprise apres le seuil : directement en limite proche', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal()
      ..demarrer(_a(0))
      ..mettreEnPause(_a(160))
      ..reprendre(_a(200));
    expect(m.etat, EtatVocal.limiteProche);
    expect(m.ecoule(_a(210)), const Duration(seconds: 170));
  });

  test(
    'suppression : confirmation, garder revient, confirmer remet a zero',
    () {
      final MachineEnregistrementVocal m = MachineEnregistrementVocal()
        ..demarrer(_a(0))
        ..arreter(_a(20))
        ..demanderSuppression();
      expect(m.etat, EtatVocal.supprimer);
      m.garder();
      expect(m.etat, EtatVocal.preEcoute);
      m
        ..demanderSuppression()
        ..confirmerSuppression();
      expect(m.etat, EtatVocal.repos);
      expect(m.duree, Duration.zero);

      final MachineEnregistrementVocal enPause = MachineEnregistrementVocal()
        ..demarrer(_a(0))
        ..mettreEnPause(_a(4))
        ..demanderSuppression();
      expect(enPause.suppressionEnPause, isTrue);
      enPause.garder();
      expect(enPause.etat, EtatVocal.pause);
    },
  );

  test('envoi : echec garde le vocal, reessai, accuse', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal()
      ..demarrer(_a(0))
      ..arreter(_a(9))
      ..envoyer()
      ..echouer();
    expect(m.etat, EtatVocal.echecEnvoi);
    expect(m.duree, const Duration(seconds: 9));
    m
      ..envoyer()
      ..confirmerEnvoi();
    expect(m.etat, EtatVocal.envoye);
    // Un autre vocal peut suivre.
    m.demarrer(_a(30));
    expect(m.etat, EtatVocal.enregistrement);
  });

  test('permission : requise, refusee, fermer', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal()
      ..exigerPermission();
    expect(m.etat, EtatVocal.permissionRequise);
    m.refuserPermission();
    expect(m.etat, EtatVocal.permissionRefusee);
    m.fermer();
    expect(m.etat, EtatVocal.repos);
    m
      ..exigerPermission()
      ..demarrer(_a(0));
    expect(m.etat, EtatVocal.enregistrement);
  });

  test('un evenement hors de propos leve StateError', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal();
    expect(m.envoyer, throwsStateError);
    expect(() => m.mettreEnPause(_a(0)), throwsStateError);
    expect(() => m.arreter(_a(0)), throwsStateError);
    m.demarrer(_a(0));
    expect(m.envoyer, throwsStateError);
    expect(() => m.reprendre(_a(1)), throwsStateError);
  });

  test('etats du lecteur deduits de la lecture', () {
    expect(etatDuLecteur(const EtatLectureAudio()), EtatVocal.vocalRecu);
    expect(
      etatDuLecteur(const EtatLectureAudio(enLecture: true)),
      EtatVocal.lecture,
    );
    expect(
      etatDuLecteur(const EtatLectureAudio(position: Duration(seconds: 3))),
      EtatVocal.pauseLecture,
    );
    expect(
      etatDuLecteur(
        const EtatLectureAudio(position: Duration(seconds: 28), termine: true),
      ),
      EtatVocal.finLecture,
    );
  });

  test('un vocal ne dit jamais son identifiant', () {
    const EnregistrementVocal v = EnregistrementVocal(
      id: 'secret-local-42',
      duree: Duration(seconds: 3),
    );
    expect(v.toString(), isNot(contains('secret')));
  });

  test('vocal attendu : pre-ecoute ou suppression demandee, rien d autre', () {
    final MachineEnregistrementVocal m = MachineEnregistrementVocal()
      ..demarrer(_a(0));
    expect(m.vocalAttendu, isFalse);
    m.arreter(_a(4));
    expect(m.vocalAttendu, isTrue);
    m.demanderSuppression();
    expect(m.vocalAttendu, isTrue);
    m.confirmerSuppression();
    expect(m.vocalAttendu, isFalse);
    m
      ..demarrer(_a(10))
      ..mettreEnPause(_a(12))
      ..demanderSuppression();
    expect(m.suppressionEnPause, isTrue);
    expect(m.vocalAttendu, isFalse);
  });
}
