// CAMARADES (directeur, 12/11/2026, journal D-040) : « la vraie video, c'est
// seulement celui qui recite ; sinon on ne voit que sa photo. »
//
// La regle du moteur, sans SDK : un eleve ne s'abonne qu'a la camera de
// l'enseignant et a celle du camarade qui recite ; l'enseignant garde tout ;
// le son n'est jamais desabonne.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/video_camarades.dart';

/// Une fausse piste distante : elle retient ce que la regle lui demande.
class _Piste implements PisteDistante {
  _Piste(this.identite, this.role, {this.estVideo = true, this.abonnee = true});

  @override
  final String identite;

  @override
  final String role;

  @override
  final bool estVideo;

  @override
  bool abonnee;

  int abonnements = 0;
  int desabonnements = 0;

  @override
  Future<void> abonner() async {
    abonnements++;
    abonnee = true;
  }

  @override
  Future<void> desabonner() async {
    desabonnements++;
    abonnee = false;
  }

  @override
  String toString() => '$identite/${estVideo ? 'video' : 'son'}';
}

/// La salle vue d'un appareil : l'enseignant, trois eleves, chacun avec son
/// micro et sa camera, tous recus (abonnement automatique de LiveKit).
List<_Piste> _salle() => <_Piste>[
  _Piste('t1', 'teacher'),
  _Piste('t1', 'teacher', estVideo: false),
  for (final String e in <String>['e2', 'e3', 'e4']) ...<_Piste>[
    _Piste(e, 'student'),
    _Piste(e, 'student', estVideo: false),
  ],
];

Set<String> _videosRecues(List<_Piste> pistes) => <String>{
  for (final _Piste p in pistes)
    if (p.estVideo && p.abonnee) p.identite,
};

void _sonIntact(List<_Piste> pistes) {
  for (final _Piste p in pistes.where((_Piste p) => !p.estVideo)) {
    expect(p.desabonnements, 0, reason: 'le son de $p a ete desabonne');
    expect(p.abonnee, isTrue, reason: 'le son de $p n\'est plus recu');
  }
}

void main() {
  group('la regle', () {
    test('chez un eleve : soi, l\'enseignant et le recitant seulement', () {
      bool voit(String role, String id, {bool local = false, String? r}) =>
          videoRecue(
            regardEleve: true,
            local: local,
            roleDistant: role,
            identite: id,
            recitant: r,
          );
      expect(voit('student', 'e1', local: true), isTrue);
      expect(voit('teacher', 't1'), isTrue);
      expect(voit('student', 'e2'), isFalse);
      expect(voit('student', 'e2', r: 'e2'), isTrue);
      expect(voit('student', 'e3', r: 'e2'), isFalse);
      // Un role illisible n'ouvre rien : seul l'enseignant signe passe.
      expect(voit('', 'x'), isFalse);
      expect(voit('student', 'e2', r: ''), isFalse);
    });

    test('ailleurs : rien ne change', () {
      for (final bool local in <bool>[false, true]) {
        expect(
          videoRecue(
            regardEleve: false,
            local: local,
            roleDistant: 'student',
            identite: 'e2',
            recitant: null,
          ),
          isTrue,
        );
      }
    });

    test('le recitant est lu dans les metadonnees du serveur', () {
      expect(
        recitantDesMetadonnees(
          '{"recitation":{"recitant":"e2","depuis":1731400000000},"x":1}',
        ),
        'e2',
      );
      expect(recitantDesMetadonnees(null), isNull);
      expect(recitantDesMetadonnees(''), isNull);
      expect(recitantDesMetadonnees('{"x":1}'), isNull);
      expect(recitantDesMetadonnees('{"recitation":null}'), isNull);
      expect(recitantDesMetadonnees('{"recitation":{"recitant":" "}}'), isNull);
      expect(recitantDesMetadonnees('pas du json'), isNull);
      expect(recitantDesMetadonnees('[1,2]'), isNull);
    });
  });

  group('les abonnements d\'un eleve', () {
    test('aucune recitation : l\'enseignant seul, aucun camarade', () async {
      final List<_Piste> pistes = _salle();
      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: null,
        pistes: pistes,
      );
      expect(_videosRecues(pistes), <String>{'t1'});
      _sonIntact(pistes);
    });

    test('un camarade recite : lui et l\'enseignant', () async {
      final List<_Piste> pistes = _salle();
      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: 'e3',
        pistes: pistes,
      );
      expect(_videosRecues(pistes), <String>{'t1', 'e3'});
      _sonIntact(pistes);
    });

    test('changement de recitant, puis fin de la recitation', () async {
      final List<_Piste> pistes = _salle();
      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: null,
        pistes: pistes,
      );
      expect(_videosRecues(pistes), <String>{'t1'});

      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: 'e2',
        pistes: pistes,
      );
      expect(_videosRecues(pistes), <String>{'t1', 'e2'});

      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: 'e4',
        pistes: pistes,
      );
      expect(_videosRecues(pistes), <String>{'t1', 'e4'});

      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: null,
        pistes: pistes,
      );
      expect(_videosRecues(pistes), <String>{'t1'});
      _sonIntact(pistes);
    });

    test('image suspendue (audio seul, lien perdu) : rien n\'est rabonne', () async {
      final List<_Piste> pistes = <_Piste>[
        _Piste('t1', 'teacher', abonnee: false),
        _Piste('e2', 'student', abonnee: false),
        _Piste('e2', 'student', estVideo: false),
      ];
      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: 'e2',
        videoSuspendue: true,
        pistes: pistes,
      );
      expect(_videosRecues(pistes), isEmpty);
      _sonIntact(pistes);
    });

    test('une piste deja dans le bon etat n\'est pas touchee', () async {
      final List<_Piste> pistes = _salle();
      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: null,
        pistes: pistes,
      );
      await accorderAbonnementsVideo(
        roleLocal: 'student',
        recitant: null,
        pistes: pistes,
      );
      for (final _Piste p in pistes) {
        expect(p.desabonnements, lessThanOrEqualTo(1));
        expect(p.abonnements, 0);
      }
    });
  });

  group('l\'enseignant et l\'observateur gardent tout', () {
    for (final String role in <String>[
      'teacher',
      'guardian_observer',
      'masked_controller',
      'admin_masked',
    ]) {
      test(role, () async {
        final List<_Piste> pistes = _salle();
        await accorderAbonnementsVideo(
          roleLocal: role,
          recitant: 'e2',
          pistes: pistes,
        );
        expect(_videosRecues(pistes), <String>{'t1', 'e2', 'e3', 'e4'});
        for (final _Piste p in pistes) {
          expect(p.abonnements + p.desabonnements, 0, reason: '$p touchee');
        }
      });
    }
  });
}
