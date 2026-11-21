// PERSONNES-PERF : les demandes de photos d'une meme image de l'ecran partent
// en UN appel `photos_personnes` (au lieu d'un par avatar), une demande en vol
// est rejointe, et la reponse rendue a chaque demandeur ne change pas.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:rewayah_academy/core/photos/photos_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _id(int n) => '9e9c0000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

void main() {
  group('PhotosSupabase.sources', () {
    late List<List<String>> appels;
    late PhotosSupabase port;

    setUp(() {
      appels = <List<String>>[];
      port = PhotosSupabase(
        SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          httpClient: MockClient((http.Request r) async {
            expect(r.url.pathSegments.last, 'photos_personnes');
            final List<String> ids = <String>[
              for (final Object? i
                  in (jsonDecode(r.body) as Map<String, dynamic>)['p_ids']
                      as List<dynamic>)
                i! as String,
            ];
            appels.add(ids);
            // Le serveur ne rend que les personnes dont la photo est visible :
            // ici, une sur deux.
            return http.Response(
              jsonEncode(<Map<String, Object?>>[
                for (final String id in ids)
                  if (int.parse(id.substring(id.length - 2)).isEven)
                    <String, Object?>{
                      'profile_id': id,
                      'seau': 'avatars',
                      'cle': '$id/photo.png',
                    },
              ]),
              200,
              headers: <String, String>{'content-type': 'application/json'},
              request: r,
            );
          }),
        ),
      );
    });

    test('cinquante avatars de la meme image : un seul appel', () async {
      final List<Future<Map<String, SourcePhoto>>> demandes =
          <Future<Map<String, SourcePhoto>>>[
            for (int n = 1; n <= 50; n++) port.sources(<String>[_id(n)]),
          ];
      final List<Map<String, SourcePhoto>> reponses = await Future.wait(
        demandes,
      );
      expect(appels, hasLength(1));
      expect(appels.single.toSet(), <String>{
        for (int n = 1; n <= 50; n++) _id(n),
      });
      for (int n = 1; n <= 50; n++) {
        final Map<String, SourcePhoto> r = reponses[n - 1];
        if (n.isEven) {
          expect(r.keys, <String>[_id(n)]);
          expect(r[_id(n)]!.seau, 'avatars');
          expect(r[_id(n)]!.cle, '${_id(n)}/photo.png');
        } else {
          // Sans photo visible : absente, comme avant.
          expect(r, isEmpty);
        }
      }
    });

    test('une demande en vol pour la meme personne est rejointe', () async {
      final Future<Map<String, SourcePhoto>> a = port.sources(<String>[_id(2)]);
      await Future<void>.value();
      final Future<Map<String, SourcePhoto>> b = port.sources(<String>[
        _id(2),
        _id(2),
      ]);
      final List<Map<String, SourcePhoto>> r = await Future.wait(
        <Future<Map<String, SourcePhoto>>>[a, b],
      );
      expect(appels, hasLength(1));
      expect(appels.single, <String>[_id(2)]);
      expect(r[0].keys, <String>[_id(2)]);
      expect(r[1].keys, <String>[_id(2)]);
    });

    test('deux images separees : deux appels, rien de garde', () async {
      await port.sources(<String>[_id(2)]);
      await port.sources(<String>[_id(2)]);
      expect(appels, hasLength(2));
    });

    test('une liste vide ne part pas au serveur', () async {
      expect(await port.sources(const <String>[]), isEmpty);
      expect(appels, isEmpty);
    });
  });

  group('RegroupementPhotos (relecture du 21/11, S1)', () {
    SourcePhoto source(String id) =>
        SourcePhoto(seau: 'avatars', cle: '$id/photo.png');

    test('un identifiant qui n\'est pas un UUID ne part pas : les autres '
        'photos sont rendues', () async {
      final List<List<String>> appels = <List<String>>[];
      final RegroupementPhotos r = RegroupementPhotos((List<String> ids) async {
        appels.add(ids);
        return <String, SourcePhoto>{
          for (final String id in ids) id: source(id),
        };
      });
      final List<Map<String, SourcePhoto>> rep = await Future.wait(
        <Future<Map<String, SourcePhoto>>>[
          r.demander(<String>[_id(2)]),
          r.demander(<String>['Administration Rewayah']),
          r.demander(<String>[_id(4), 'pas-un-uuid']),
        ],
      );
      expect(appels, hasLength(1));
      expect(appels.single.toSet(), <String>{_id(2), _id(4)});
      expect(rep[0].keys, <String>[_id(2)]);
      expect(rep[1], isEmpty);
      expect(rep[2].keys, <String>[_id(4)]);
    });

    test(
      'le lot echoue : un appel par identifiant, 50 avatars rendus',
      () async {
        int appels = 0;
        final RegroupementPhotos r = RegroupementPhotos((
          List<String> ids,
        ) async {
          appels += 1;
          if (ids.length > 1) throw StateError('erreur du serveur sur le lot');
          return <String, SourcePhoto>{ids.single: source(ids.single)};
        });
        final List<Map<String, SourcePhoto>> rep = await Future.wait(
          <Future<Map<String, SourcePhoto>>>[
            for (int n = 1; n <= 50; n++) r.demander(<String>[_id(n)]),
          ],
        );
        expect(appels, 51);
        for (int n = 1; n <= 50; n++) {
          expect(rep[n - 1].keys, <String>[_id(n)]);
        }
      },
    );

    test('seul le fautif echoue ; rien n\'est garde apres l\'echec', () async {
      int appels = 0;
      final RegroupementPhotos r = RegroupementPhotos((List<String> ids) async {
        appels += 1;
        if (ids.contains(_id(13))) throw StateError('refus');
        return <String, SourcePhoto>{
          for (final String id in ids) id: source(id),
        };
      });
      final Future<Map<String, SourcePhoto>> bon = r.demander(<String>[_id(2)]);
      final Future<Map<String, SourcePhoto>> fautif = r.demander(<String>[
        _id(13),
      ]);
      expect((await bon).keys, <String>[_id(2)]);
      await expectLater(fautif, throwsStateError);
      expect(appels, 3);
      await expectLater(r.demander(<String>[_id(13)]), throwsStateError);
      expect(appels, 4);
    });
  });

  group('PhotosSupabase : changement de compte (S1)', () {
    test('une demande en vol pour un compte n\'est jamais rejointe par un '
        'autre compte', () async {
      String compte = 'compte-a';
      final List<String> parCompte = <String>[];
      final Completer<void> lacher = Completer<void>();
      final PhotosSupabase port = PhotosSupabase(
        SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((http.Request r) async {
            parCompte.add(compte);
            await lacher.future;
            return http.Response(
              '[]',
              200,
              headers: <String, String>{'content-type': 'application/json'},
              request: r,
            );
          }),
        ),
        compteCourant: () => compte,
      );
      final Future<Map<String, SourcePhoto>> a = port.sources(<String>[_id(2)]);
      await pumpEventQueue();
      compte = 'compte-b';
      final Future<Map<String, SourcePhoto>> b = port.sources(<String>[_id(2)]);
      await pumpEventQueue();
      lacher.complete();
      await Future.wait(<Future<Map<String, SourcePhoto>>>[a, b]);
      // Deux appels : le second compte n'a pas rejoint la lecture du premier.
      expect(parCompte, <String>['compte-a', 'compte-b']);
    });
  });
}
