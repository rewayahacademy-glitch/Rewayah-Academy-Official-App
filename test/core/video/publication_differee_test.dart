// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026, defaut SEC-1) : tant que
// l'enseignant n'est pas dans la salle, le serveur refuse le micro et la
// camera d'un eleve. L'application lit ce que le serveur accorde, et le lui
// redemande si un message s'est perdu ; elle ne decide rien.

// fake_async est la dependance de flutter_test qui porte son horloge simulee
// (version fixee par le SDK) ; pubspec.yaml n'est pas modifie par ce lot.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/politique_camera.dart';
import 'package:rewayah_academy/core/video/publication_differee.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

Map<String, dynamic> _reponse({
  String role = 'student',
  bool publier = true,
  bool video = false,
  Object? differee,
}) => <String, dynamic>{
  'ws_url': 'wss://exemple',
  'token': 'jeton',
  'room_name': 'salle',
  'provider': 'cloud',
  'role': role,
  'expire_le': '2026-11-11T18:05:00Z',
  'capabilities': <String, dynamic>{
    'can_publish': publier,
    'can_publish_video': video,
    'can_publish_data': role == 'teacher',
    'can_subscribe': true,
    'can_moderate': role == 'teacher',
    'hidden': false,
  },
  'publication_differee': ?differee,
};

ParticipantSalle _participant(String role, {bool local = false}) =>
    ParticipantSalle(
      identite: '$role-$local',
      nom: '',
      role: role,
      estLocal: local,
      micro: false,
      camera: false,
      parle: false,
      qualite: QualiteLien.bonne,
    );

void main() {
  group('le jeton differe, tel que le serveur le rend', () {
    test('publication differee : ni micro ni camera, et l\'acces le dit', () {
      final AccesSalle acces = AccesSalle.depuisJson(
        _reponse(video: true, differee: true),
      );
      expect(acces.publicationDifferee, isTrue);
      expect(acces.capacites.peutPublier, isFalse);
      expect(acces.capacites.peutPublierVideo, isFalse);
      // Le reste ne change pas.
      expect(acces.capacites.peutRecevoir, isTrue);
      expect(acces.capacites.peutPublierDonnees, isFalse);
    });

    test('sans le champ (serveur d\'avant ce lot) : rien ne change', () {
      for (final Object? valeur in <Object?>[null, false, 'true', 1]) {
        final AccesSalle acces = AccesSalle.depuisJson(
          _reponse(video: true, differee: valeur),
        );
        expect(acces.publicationDifferee, isFalse, reason: '$valeur');
        expect(acces.capacites.peutPublier, isTrue, reason: '$valeur');
        expect(acces.capacites.peutPublierVideo, isTrue, reason: '$valeur');
      }
    });

    test('la demande est retenue pour le filet', () {
      final AccesSalle acces = AccesSalle.depuisJson(_reponse(differee: true))
          .pourLaDemande(seanceId: 's1', eleveId: 'e1');
      expect(acces.seanceId, 's1');
      expect(acces.eleveId, 'e1');
      expect(acces.publicationDifferee, isTrue);
      final AccesSalle? rendu = accesApresPermissions(
        acces,
        peutPublier: true,
        camera: false,
      );
      expect(rendu?.seanceId, 's1');
      expect(rendu?.eleveId, 'e1');
    });
  });

  group('les droits suivent ce que LiveKit accorde', () {
    final AccesSalle differe = AccesSalle.depuisJson(
      _reponse(video: true, differee: true),
    );

    test('l\'enseignant entre : le micro seul est rendu', () {
      final AccesSalle? neuf = accesApresPermissions(
        differe,
        peutPublier: true,
        camera: false,
      );
      expect(neuf, isNotNull);
      expect(neuf!.publicationDifferee, isFalse);
      expect(neuf.capacites.peutPublier, isTrue);
      expect(neuf.capacites.peutPublierVideo, isFalse);
    });

    test('l\'enseignant entre : micro et camera sont rendus', () {
      final AccesSalle? neuf = accesApresPermissions(
        differe,
        peutPublier: true,
        camera: true,
      );
      expect(neuf!.publicationDifferee, isFalse);
      expect(neuf.capacites.peutPublier, isTrue);
      expect(neuf.capacites.peutPublierVideo, isTrue);
    });

    test('la camera ne va jamais sans le droit de publier', () {
      expect(
        accesApresPermissions(differe, peutPublier: false, camera: true),
        isNull,
        reason: 'toujours differe : rien ne change pour l\'ecran',
      );
    });

    test('une annonce qui ne change rien ne reconstruit rien', () {
      final AccesSalle ordinaire = AccesSalle.depuisJson(_reponse());
      expect(
        accesApresPermissions(ordinaire, peutPublier: true, camera: false),
        isNull,
      );
    });

    test('le serveur referme le droit d\'un eleve : il attend de nouveau', () {
      final AccesSalle ordinaire = AccesSalle.depuisJson(_reponse(video: true));
      final AccesSalle? neuf = accesApresPermissions(
        ordinaire,
        peutPublier: false,
        camera: false,
      );
      expect(neuf!.publicationDifferee, isTrue);
      expect(neuf.capacites.peutPublier, isFalse);
      expect(neuf.capacites.peutPublierVideo, isFalse);
    });

    test('un autre role n\'est jamais « en attente »', () {
      final AccesSalle enseignant = AccesSalle.depuisJson(
        _reponse(role: 'teacher', video: true),
      );
      final AccesSalle? neuf = accesApresPermissions(
        enseignant,
        peutPublier: false,
        camera: false,
      );
      expect(neuf!.publicationDifferee, isFalse);
      // Le canal de donnees et la moderation ne sont pas touches.
      expect(neuf.capacites.peutPublierDonnees, isTrue);
      expect(neuf.capacites.peutModerer, isTrue);
    });

    test('en attente, la politique de camera ne redemande pas de jeton', () {
      expect(jetonCameraPerime(differe, cameraAutorisee: true), isFalse);
      final AccesSalle? rendu = accesApresPermissions(
        differe,
        peutPublier: true,
        camera: false,
      );
      // Le droit rendu, la veille reprend son role ordinaire.
      expect(jetonCameraPerime(rendu!, cameraAutorisee: true), isTrue);
      expect(jetonCameraPerime(rendu, cameraAutorisee: false), isFalse);
    });
  });

  // RECITATION-MICRO-SEUL (directeur, 11/11/2026) : pendant la recitation
  // d'un camarade, le serveur ferme le micro SEUL ; la camera reste.
  group('RECITATION-MICRO-SEUL : le droit se lit source par source', () {
    final AccesSalle ouvert = AccesSalle.depuisJson(_reponse(video: true));

    test('sans liste de sources, LiveKit autorise tout', () {
      expect(droitsAccordes(peutPublier: true, sources: const <String>[]), (
        micro: true,
        camera: true,
      ));
    });

    test('borne a la camera : le micro est ferme, la camera reste', () {
      expect(
        droitsAccordes(peutPublier: true, sources: const <String>['CAMERA']),
        (micro: false, camera: true),
      );
    });

    test('borne au micro (camera interdite par le profil)', () {
      expect(
        droitsAccordes(
          peutPublier: true,
          sources: const <String>['MICROPHONE'],
        ),
        (micro: true, camera: false),
      );
    });

    test('sans droit de publier, la liste ne donne rien', () {
      expect(
        droitsAccordes(
          peutPublier: false,
          sources: const <String>['MICROPHONE', 'CAMERA'],
        ),
        (micro: false, camera: false),
      );
    });

    test('un camarade recite : pas de micro, la camera permise, et '
        'l\'acces dit que le micro attend', () {
      final AccesSalle? neuf = accesApresPermissions(
        ouvert,
        peutPublier: true,
        micro: false,
        camera: true,
      );
      expect(neuf, isNotNull);
      expect(neuf!.capacites.peutPublier, isFalse, reason: 'le micro');
      expect(neuf.capacites.peutPublierVideo, isTrue, reason: 'la camera');
      expect(neuf.publicationDifferee, isTrue);
    });

    test('camera interdite par le profil : la recitation ferme tout', () {
      final AccesSalle sansCamera = AccesSalle.depuisJson(_reponse());
      final AccesSalle? neuf = accesApresPermissions(
        sansCamera,
        peutPublier: false,
        micro: false,
        camera: false,
      );
      expect(neuf!.capacites.peutPublier, isFalse);
      expect(neuf.capacites.peutPublierVideo, isFalse);
      expect(neuf.publicationDifferee, isTrue);
    });

    test('la recitation se termine : le micro revient, la camera n\'a pas '
        'bouge', () {
      final AccesSalle pendant = accesApresPermissions(
        ouvert,
        peutPublier: true,
        micro: false,
        camera: true,
      )!;
      final AccesSalle? apres = accesApresPermissions(
        pendant,
        peutPublier: true,
        micro: true,
        camera: true,
      );
      expect(apres!.capacites.peutPublier, isTrue);
      expect(apres.capacites.peutPublierVideo, isTrue);
      expect(apres.publicationDifferee, isFalse);
    });

    test('sans le parametre (appel d\'avant ce lot) : le micro suit le droit '
        'de publier', () {
      final AccesSalle? neuf = accesApresPermissions(
        AccesSalle.depuisJson(_reponse(video: true, differee: true)),
        peutPublier: true,
        camera: true,
      );
      expect(neuf!.capacites.peutPublier, isTrue);
    });

    test('pendant la recitation, la politique de camera ne redemande pas de '
        'jeton', () {
      final AccesSalle pendant = accesApresPermissions(
        ouvert,
        peutPublier: true,
        micro: false,
        camera: true,
      )!;
      expect(jetonCameraPerime(pendant, cameraAutorisee: true), isFalse);
      expect(jetonCameraPerime(pendant, cameraAutorisee: false), isFalse);
    });
  });

  group('RECITATION-MICRO-SEUL : le micro ne se rouvre pas seul', () {
    final AccesSalle ouvert = AccesSalle.depuisJson(_reponse(video: true));
    final AccesSalle pendant = accesApresPermissions(
      ouvert,
      peutPublier: true,
      micro: false,
      camera: true,
    )!;

    test('le serveur ferme le micro devant l\'enseignant : le micro voulu '
        'est oublie', () {
      expect(
        microFermeDevantEnseignant(
          avant: ouvert,
          apres: pendant,
          enseignantPresent: true,
        ),
        isTrue,
      );
    });

    test('camera interdite, tout se ferme devant l\'enseignant : oublie '
        'aussi', () {
      final AccesSalle sansCamera = AccesSalle.depuisJson(_reponse());
      final AccesSalle ferme = accesApresPermissions(
        sansCamera,
        peutPublier: false,
        camera: false,
      )!;
      expect(
        microFermeDevantEnseignant(
          avant: sansCamera,
          apres: ferme,
          enseignantPresent: true,
        ),
        isTrue,
      );
    });

    test('sans enseignant dans la salle (apres son depart) : ce n\'est pas '
        'une recitation, rien n\'est oublie ici', () {
      final AccesSalle ferme = accesApresPermissions(
        ouvert,
        peutPublier: false,
        camera: false,
      )!;
      expect(
        microFermeDevantEnseignant(
          avant: ouvert,
          apres: ferme,
          enseignantPresent: false,
        ),
        isFalse,
      );
    });

    test('le micro revient, ou n\'etait deja pas permis : rien a oublier', () {
      expect(
        microFermeDevantEnseignant(
          avant: pendant,
          apres: ouvert,
          enseignantPresent: true,
        ),
        isFalse,
      );
      expect(
        microFermeDevantEnseignant(
          avant: pendant,
          apres: pendant,
          enseignantPresent: true,
        ),
        isFalse,
      );
    });
  });

  test('l\'enseignant est dans la salle : par son role, jamais soi-meme', () {
    expect(enseignantDansLaSalle(const <ParticipantSalle>[]), isFalse);
    expect(
      enseignantDansLaSalle(<ParticipantSalle>[
        _participant('student', local: true),
        _participant('student'),
        _participant('guardian_observer'),
        _participant('admin_visible'),
      ]),
      isFalse,
    );
    expect(
      enseignantDansLaSalle(<ParticipantSalle>[
        _participant('student', local: true),
        _participant('teacher'),
      ]),
      isTrue,
    );
    expect(
      enseignantDansLaSalle(<ParticipantSalle>[
        _participant('teacher', local: true),
      ]),
      isFalse,
    );
  });

  group('le filet : redemander au serveur, jamais rester muet', () {
    final AccesSalle differe = AccesSalle.depuisJson(_reponse(differee: true));
    final AccesSalle ouvert = AccesSalle.depuisJson(_reponse());

    test('les ecarts : 2, 4, 8 puis 15 secondes', () {
      expect(
        <int>[
          for (int i = 0; i < 6; i++) FiletPublication.delaiAvant(i).inSeconds,
        ],
        <int>[2, 4, 8, 15, 15, 15],
      );
    });

    test('sans enseignant, ou sans attente, rien n\'est demande', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final FiletPublication filet = FiletPublication((_) async => demandes++)
          ..observer(acces: differe, enseignantPresent: false);
        temps.elapse(const Duration(minutes: 1));
        filet.observer(acces: ouvert, enseignantPresent: true);
        temps.elapse(const Duration(minutes: 1));
        filet.observer(acces: null, enseignantPresent: true);
        temps.elapse(const Duration(minutes: 1));
        expect(demandes, 0);
      });
    });

    test('le webhook a fait son travail a temps : aucune demande', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final FiletPublication filet = FiletPublication((_) async => demandes++)
          ..observer(acces: differe, enseignantPresent: true);
        temps.elapse(const Duration(seconds: 1));
        // LiveKit annonce le droit rendu avant la premiere demande.
        filet.observer(acces: ouvert, enseignantPresent: true);
        temps.elapse(const Duration(minutes: 1));
        expect(demandes, 0);
      });
    });

    test('webhook perdu : demande apres 2 s, puis encore, sans abandonner', () {
      fakeAsync((FakeAsync temps) {
        final List<AccesSalle> demandes = <AccesSalle>[];
        final FiletPublication filet = FiletPublication((AccesSalle a) async {
          demandes.add(a);
        })..observer(acces: differe, enseignantPresent: true);
        // Chaque evenement de la salle repasse par `observer` : il ne doit ni
        // avancer ni retarder la demande.
        temps.elapse(const Duration(milliseconds: 1900));
        filet.observer(acces: differe, enseignantPresent: true);
        expect(demandes, isEmpty);
        temps.elapse(const Duration(milliseconds: 200));
        expect(demandes, hasLength(1));
        expect(identical(demandes.single, differe), isTrue);
        temps.elapse(const Duration(seconds: 4));
        expect(demandes, hasLength(2));
        temps.elapse(const Duration(seconds: 8));
        expect(demandes, hasLength(3));
        temps.elapse(const Duration(minutes: 2));
        expect(demandes.length, greaterThanOrEqualTo(10));
        // Le droit arrive enfin : tout s'arrete.
        filet.observer(acces: ouvert, enseignantPresent: true);
        final int avant = demandes.length;
        temps.elapse(const Duration(minutes: 2));
        expect(demandes, hasLength(avant));
      });
    });

    test('une demande en echec n\'arrete pas le filet', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        FiletPublication((_) async {
          demandes++;
          throw StateError('reseau');
        }).observer(acces: differe, enseignantPresent: true);
        temps.elapse(const Duration(seconds: 7));
        expect(demandes, 2);
      });
    });

    test('l\'enseignant ressort, ou l\'eleve quitte : plus de demande', () {
      fakeAsync((FakeAsync temps) {
        int demandes = 0;
        final FiletPublication filet = FiletPublication((_) async => demandes++)
          ..observer(acces: differe, enseignantPresent: true);
        temps.elapse(const Duration(seconds: 3));
        expect(demandes, 1);
        filet.observer(acces: differe, enseignantPresent: false);
        temps.elapse(const Duration(minutes: 1));
        expect(demandes, 1);
        // Il revient : le filet repart de la premiere attente.
        filet.observer(acces: differe, enseignantPresent: true);
        temps.elapse(const Duration(seconds: 3));
        expect(demandes, 2);
        filet.arreter();
        temps.elapse(const Duration(minutes: 1));
        expect(demandes, 2);
      });
    });
  });
}
