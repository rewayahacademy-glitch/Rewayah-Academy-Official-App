// Lot RESEAU-PREUVE (directeur, 11/11/2026) : l'envoi borne du releve de
// qualite de connexion. L'appareil n'envoie que SA ligne, seulement quand
// l'etat change, jamais plus d'une fois toutes les 10 secondes, et il se tait
// quand le serveur refuse.

// fake_async est la dependance de flutter_test qui porte son horloge simulee.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/releve_qualite.dart';
import 'package:rewayah_academy/core/video/releve_qualite_supabase.dart';
import 'package:rewayah_academy/core/video/seuils_reseau.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 17);

typedef _Ligne = ({String seance, String profil, EtatReleve etat, bool micro});

class _FauxPort implements PortReleveQualite {
  final List<_Ligne> lignes = <_Ligne>[];
  final List<Duration> instants = <Duration>[];
  Duration Function() horloge = () => Duration.zero;
  ReponseReleve reponse = ReponseReleve.ecrite;
  bool panne = false;

  @override
  Future<ReponseReleve> noter({
    required String seanceId,
    required String profilId,
    required EtatReleve etat,
    required bool microOuvert,
  }) async {
    lignes.add((
      seance: seanceId,
      profil: profilId,
      etat: etat,
      micro: microOuvert,
    ));
    instants.add(horloge());
    if (panne) throw StateError('serveur injoignable');
    return reponse;
  }
}

ParticipantSalle _p(
  String id, {
  bool local = false,
  bool micro = true,
  String role = 'student',
}) => ParticipantSalle(
  identite: id,
  nom: id,
  role: role,
  estLocal: local,
  micro: micro,
  camera: false,
  parle: false,
  qualite: QualiteLien.inconnue,
);

EtatReseau _e(QualiteLien q) => EtatReseau(qualite: q);

/// Monte un envoi sur l'horloge simulee, et rend de quoi observer la salle.
({
  EnvoiReleve envoi,
  _FauxPort port,
  void Function(QualiteLien, {bool micro}) moi,
})
_monter(FakeAsync async, {String role = 'student'}) {
  final _FauxPort port = _FauxPort()..horloge = () => async.elapsed;
  final EnvoiReleve envoi = EnvoiReleve(
    port: () => port,
    horloge: () => _t0.add(async.elapsed),
  );
  void moi(QualiteLien q, {bool micro = true}) {
    envoi.observer(
      seanceId: 's1',
      participants: <ParticipantSalle>[
        _p('prof', role: 'teacher'),
        _p('moi', local: true, micro: micro, role: role),
        _p('autre'),
      ],
      etats: <String, EtatReseau>{
        'prof': _e(QualiteLien.perdue),
        'moi': _e(q),
        'autre': _e(QualiteLien.mediocre),
      },
    );
    async.flushMicrotasks();
  }

  return (envoi: envoi, port: port, moi: moi);
}

void main() {
  test('trois etats seulement, et les mots sont ceux du serveur', () {
    expect(EtatReleve.values.map((EtatReleve e) => e.name), <String>[
      'bon',
      'faible',
      'perdu',
    ]);
    expect(etatRelevePour(QualiteLien.excellente), EtatReleve.bon);
    expect(etatRelevePour(QualiteLien.bonne), EtatReleve.bon);
    expect(etatRelevePour(QualiteLien.mediocre), EtatReleve.faible);
    expect(etatRelevePour(QualiteLien.perdue), EtatReleve.perdu);
    expect(
      etatRelevePour(QualiteLien.inconnue),
      isNull,
      reason: 'sans mesure, rien ne s ecrit : jamais un etat invente',
    );
  });

  test('le rythme : dix secondes entre deux lignes', () {
    expect(intervalleEnvoi, const Duration(seconds: 10));
  });

  test('le premier etat stable part tout de suite, avec la seance, le '
      'participant local et son micro', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne);
      expect(m.port.lignes, <_Ligne>[
        (seance: 's1', profil: 'moi', etat: EtatReleve.bon, micro: true),
      ]);
    });
  });

  test('l appareil n ecrit que SA ligne : jamais celle de l enseignant ni '
      'd un autre eleve, meme quand leur lien est mauvais', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(minutes: 2));
      m.moi(QualiteLien.mediocre);
      async.elapse(const Duration(minutes: 2));
      expect(m.port.lignes, hasLength(2));
      expect(
        m.port.lignes.every((_Ligne l) => l.profil == 'moi'),
        isTrue,
        reason:
            'le lien perdu de l enseignant et le lien faible de l autre '
            'eleve ne sont jamais envoyes par cet appareil',
      );
    });
  });

  test('un etat qui ne change pas ne part qu une fois', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      for (int i = 0; i < 50; i++) {
        m.moi(QualiteLien.bonne);
        async.elapse(const Duration(seconds: 30));
      }
      m.moi(QualiteLien.excellente);
      async.elapse(const Duration(minutes: 1));
      expect(
        m.port.lignes,
        hasLength(1),
        reason: 'excellente et bonne sont le meme etat garde : bon',
      );
    });
  });

  test(
    'pas de flot : un lien qui bat toutes les 3 s pendant une minute '
    'donne au plus une ligne par 10 s, et le dernier etat n est pas perdu',
    () {
      fakeAsync((FakeAsync async) {
        final m = _monter(async);
        for (int i = 0; i < 20; i++) {
          m.moi(i.isEven ? QualiteLien.mediocre : QualiteLien.bonne);
          async.elapse(const Duration(seconds: 3));
        }
        // Le dernier etat observe (i = 19 : bon) part a l'echeance.
        async.elapse(const Duration(seconds: 30));
        expect(m.port.lignes.length, lessThanOrEqualTo(8));
        expect(m.port.lignes.last.etat, EtatReleve.bon);
        for (int i = 1; i < m.port.instants.length; i++) {
          expect(
            m.port.instants[i] - m.port.instants[i - 1],
            greaterThanOrEqualTo(intervalleEnvoi),
            reason: 'entre la ligne ${i - 1} et la ligne $i',
          );
        }
        // Deux lignes de suite ne portent jamais le meme etat.
        for (int i = 1; i < m.port.lignes.length; i++) {
          expect(m.port.lignes[i].etat, isNot(m.port.lignes[i - 1].etat));
        }
      });
    },
  );

  test('entre deux envois : au moins dix secondes, mesurees', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(seconds: 4));
      m.moi(QualiteLien.perdue);
      expect(m.port.lignes, hasLength(1), reason: '4 s : trop tot');
      async.elapse(const Duration(seconds: 5));
      expect(m.port.lignes, hasLength(1), reason: '9 s : trop tot');
      async.elapse(const Duration(seconds: 1));
      expect(m.port.lignes, hasLength(2), reason: '10 s : la ligne part');
      expect(m.port.lignes.last.etat, EtatReleve.perdu);
    });
  });

  test('un etat revenu a l etat deja ecrit avant l echeance ne part pas', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(seconds: 4));
      m.moi(QualiteLien.mediocre);
      async.elapse(const Duration(seconds: 3));
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(minutes: 1));
      expect(m.port.lignes, hasLength(1));
    });
  });

  test('le micro : sur un bon lien il ne s ecrit pas ; sur un lien faible, '
      'son changement est une ligne', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne, micro: false);
      async.elapse(const Duration(seconds: 20));
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(seconds: 20));
      expect(
        m.port.lignes,
        hasLength(1),
        reason:
            'les prises de parole sur '
            'un bon lien ne sont pas gardees',
      );
      m.moi(QualiteLien.mediocre);
      async.elapse(const Duration(seconds: 20));
      m.moi(QualiteLien.mediocre, micro: false);
      async.elapse(const Duration(seconds: 20));
      expect(m.port.lignes.map((_Ligne l) => (l.etat, l.micro)), <Object>[
        (EtatReleve.bon, false),
        (EtatReleve.faible, true),
        (EtatReleve.faible, false),
      ]);
    });
  });

  test('un observateur (tuteur, controleur, direction) n envoie rien', () {
    fakeAsync((FakeAsync async) {
      for (final String role in <String>[
        'guardian_observer',
        'masked_controller',
        'admin_masked',
        'admin_visible',
        '',
      ]) {
        final m = _monter(async, role: role);
        m.moi(QualiteLien.perdue);
        async.elapse(const Duration(minutes: 1));
        expect(m.port.lignes, isEmpty, reason: 'role « $role »');
      }
    });
  });

  test('l enseignant envoie sa ligne', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async, role: 'teacher');
      m.moi(QualiteLien.mediocre);
      expect(m.port.lignes.single.etat, EtatReleve.faible);
    });
  });

  test('sans mesure stable du participant local : rien', () {
    fakeAsync((FakeAsync async) {
      final _FauxPort port = _FauxPort();
      final EnvoiReleve envoi = EnvoiReleve(
        port: () => port,
        horloge: () => _t0.add(async.elapsed),
      );
      envoi.observer(
        seanceId: 's1',
        participants: <ParticipantSalle>[_p('moi', local: true), _p('autre')],
        etats: <String, EtatReseau>{'autre': _e(QualiteLien.perdue)},
      );
      envoi.observer(
        seanceId: 's1',
        participants: <ParticipantSalle>[_p('autre')],
        etats: <String, EtatReseau>{'autre': _e(QualiteLien.perdue)},
      );
      async.elapse(const Duration(minutes: 1));
      expect(port.lignes, isEmpty);
    });
  });

  test(
    'le serveur refuse : l appareil se tait jusqu a la prochaine entree',
    () {
      fakeAsync((FakeAsync async) {
        final m = _monter(async);
        m.port.reponse = ReponseReleve.refusee;
        m.moi(QualiteLien.bonne);
        expect(m.port.lignes, hasLength(1));
        for (int i = 0; i < 10; i++) {
          async.elapse(const Duration(seconds: 30));
          m.moi(i.isEven ? QualiteLien.perdue : QualiteLien.bonne);
        }
        expect(m.port.lignes, hasLength(1), reason: 'plus aucun essai');
        m.envoi.remettre();
        m.port.reponse = ReponseReleve.ecrite;
        m.moi(QualiteLien.perdue);
        expect(
          m.port.lignes,
          hasLength(2),
          reason:
              'une nouvelle entree en '
              'salle repart',
        );
      });
    },
  );

  test('le serveur ignore (rythme, plafond) : rien n est retente', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.port.reponse = ReponseReleve.ignoree;
      m.moi(QualiteLien.mediocre);
      async.elapse(const Duration(minutes: 5));
      m.moi(QualiteLien.mediocre);
      async.elapse(const Duration(minutes: 5));
      expect(m.port.lignes, hasLength(1));
    });
  });

  test('serveur injoignable : trois essais espaces de dix secondes, puis le '
      'silence jusqu au prochain changement ; le cours ne s arrete pas', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.port.panne = true;
      m.moi(QualiteLien.mediocre);
      expect(m.port.lignes, hasLength(1));
      async.elapse(const Duration(seconds: 9));
      expect(m.port.lignes, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(m.port.lignes, hasLength(2));
      async.elapse(const Duration(seconds: 10));
      expect(m.port.lignes, hasLength(echecsAvantSilence));
      async.elapse(const Duration(minutes: 10));
      m.moi(QualiteLien.mediocre);
      async.elapse(const Duration(minutes: 10));
      expect(
        m.port.lignes,
        hasLength(echecsAvantSilence),
        reason: 'le meme etat ne relance pas les essais',
      );
      m.port.panne = false;
      m.moi(QualiteLien.bonne);
      expect(m.port.lignes, hasLength(echecsAvantSilence + 1));
      expect(m.port.lignes.last.etat, EtatReleve.bon);
    });
  });

  test('sortie de la salle : plus rien ne part, meme une ligne en attente', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(seconds: 2));
      m.moi(QualiteLien.perdue);
      m.envoi.fermer();
      async.elapse(const Duration(minutes: 1));
      expect(m.port.lignes, hasLength(1));
    });
  });

  test('une nouvelle entree en salle renvoie le premier etat stable, sans '
      'passer sous le rythme', () {
    fakeAsync((FakeAsync async) {
      final m = _monter(async);
      m.moi(QualiteLien.bonne);
      async.elapse(const Duration(seconds: 2));
      m.envoi.remettre();
      m.moi(QualiteLien.perdue);
      expect(
        m.port.lignes,
        hasLength(1),
        reason: 'sortie puis entree en 2 s : le serveur ignorerait la ligne',
      );
      async.elapse(const Duration(seconds: 8));
      expect(m.port.lignes, hasLength(2));
      expect(m.port.lignes.last.etat, EtatReleve.perdu);
      // Une entree plus tardive part tout de suite, meme avec le meme etat.
      async.elapse(const Duration(minutes: 1));
      m.envoi.remettre();
      m.moi(QualiteLien.perdue);
      expect(m.port.lignes, hasLength(3));
    });
  });

  test('le port par defaut n ecrit rien', () async {
    expect(
      await const ReleveQualiteMuet().noter(
        seanceId: 's1',
        profilId: 'moi',
        etat: EtatReleve.perdu,
        microOuvert: true,
      ),
      ReponseReleve.ignoree,
    );
  });

  test('la reponse du serveur : true, la ligne est ecrite ; tout le reste, '
      'ignoree', () {
    expect(reponseReleveDepuis(true), ReponseReleve.ecrite);
    expect(reponseReleveDepuis(false), ReponseReleve.ignoree);
    expect(reponseReleveDepuis(null), ReponseReleve.ignoree);
    expect(reponseReleveDepuis('true'), ReponseReleve.ignoree);
    expect(codeReleveRefuse, '42501');
  });

  test('le serveur refuse, ou le releve n est pas installe : l appareil '
      's arrete ; une panne se retente', () {
    expect(releveAArreter('42501'), isTrue);
    expect(
      releveAArreter('PGRST202'),
      isTrue,
      reason: 'fonction absente : la migration n est pas installee',
    );
    expect(releveAArreter('42883'), isTrue);
    expect(releveAArreter(null), isFalse);
    expect(releveAArreter('57014'), isFalse);
    expect(releveAArreter('PGRST301'), isFalse);
  });
}
