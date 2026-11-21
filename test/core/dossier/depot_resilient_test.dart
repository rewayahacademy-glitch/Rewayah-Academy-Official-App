// PE-B10 : un depot qui survit a une panne passagere, sans jamais creer deux
// fichiers ni deux lignes pour un meme depot.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/depot_resilient.dart';
import 'package:rewayah_academy/core/dossier/echec_depot.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/photos/photo_personne.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _sansAttente(int _) async {}

String _jwt(String uid) {
  String b(Map<String, Object> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final int exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  return '${b(<String, Object>{'alg': 'HS256', 'typ': 'JWT'})}.'
      '${b(<String, Object>{'sub': uid, 'exp': exp, 'role': 'authenticated'})}.sig';
}

const String _uid = '11111111-2222-3333-4444-555555555555';

/// Un faux Supabase : chaque requete est rangee, et la reponse vient de
/// [repondre], qui recoit le chemin et le numero de l'appel sur ce chemin.
class _Faux {
  _Faux(this.repondre);

  final http.Response Function(String chemin, int rang, http.Request r)
  repondre;
  final List<String> chemins = <String>[];
  final List<String> corps = <String>[];
  final Map<String, int> _rangs = <String, int>{};

  MockClient get client => MockClient((http.Request r) async {
    final String chemin = r.url.path.startsWith('/storage/v1/object/kyc/')
        ? '/storage/v1/object/kyc'
        : r.url.path;
    chemins.add('${r.method} $chemin');
    if (r.method == 'POST' && chemin == '/rest/v1/kyc_documents') {
      corps.add(r.body);
    }
    final int rang = _rangs[chemin] = (_rangs[chemin] ?? 0) + 1;
    final http.Response brute = repondre(chemin, rang, r);
    // Le client PostgREST lit la requete d'origine dans la reponse.
    return http.Response(
      brute.body,
      brute.statusCode,
      headers: brute.headers,
      request: r,
    );
  });
}

Future<SupabaseClient> _client(_Faux faux) async {
  final SupabaseClient c = SupabaseClient(
    'https://exemple.supabase.co',
    'anon',
    httpClient: faux.client,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final int exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  await c.auth.recoverSession(
    jsonEncode(<String, Object>{
      'access_token': _jwt(_uid),
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': exp,
      'refresh_token': 'r',
      'user': <String, Object>{
        'id': _uid,
        'aud': 'authenticated',
        'app_metadata': <String, Object>{},
        'user_metadata': <String, Object>{},
        'created_at': '2026-11-20T00:00:00Z',
      },
    }),
  );
  return c;
}

final PieceAEnvoyer _piece = PieceAEnvoyer(
  octets: Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]),
  nomFichier: 'piece.jpg',
  type: TypePiece.passeport,
);

http.Response _ok([String corps = '{}', int statut = 200]) => http.Response(
  corps,
  statut,
  headers: <String, String>{'content-type': 'application/json'},
);

void main() {
  group('avecNouveauxEssais', () {
    test('une panne passagere est reessayee deux fois, pas plus', () async {
      int appels = 0;
      await expectLater(
        avecNouveauxEssais<void>(() async {
          appels++;
          throw const StorageException('Gateway', statusCode: '544');
        }, attendre: _sansAttente),
        throwsA(isA<StorageException>()),
      );
      expect(appels, 1 + nouveauxEssaisDepot);
    });

    test('un refus n est jamais reessaye', () async {
      int appels = 0;
      await expectLater(
        avecNouveauxEssais<void>(() async {
          appels++;
          throw const StorageException('mime type', statusCode: '415');
        }, attendre: _sansAttente),
        throwsA(isA<StorageException>()),
      );
      expect(appels, 1);
    });

    test('relecture S1 : une session refusee n est ni rafraichie ni '
        'reessayee', () async {
      int appels = 0;
      await expectLater(
        avecNouveauxEssais<void>(() async {
          appels++;
          throw const StorageException('jwt expired', statusCode: '400');
        }, attendre: _sansAttente),
        throwsA(isA<StorageException>()),
      );
      expect(appels, 1);
    });

    test(
      'relecture M2 : un essai bloque depasse son delai et se reessaie',
      () async {
        int appels = 0;
        await avecNouveauxEssais<void>(
          () {
            appels++;
            // Le premier essai ne repond jamais ; le second aboutit.
            return appels == 1
                ? Completer<void>().future
                : Future<void>.value();
          },
          attendre: _sansAttente,
          delai: const Duration(milliseconds: 20),
        );
        expect(appels, 2);
      },
    );

    test(
      'relecture M2 : bloque a chaque essai, l erreur est une coupure',
      () async {
        Object? erreur;
        try {
          await avecNouveauxEssais<void>(
            () => Completer<void>().future,
            attendre: _sansAttente,
            delai: const Duration(milliseconds: 10),
          );
        } on Object catch (e) {
          erreur = e;
        }
        expect(erreur, isA<TimeoutException>());
        expect(causeEchecDepot(erreur!), CauseEchecDepot.reseau);
      },
    );

    test('409 au premier essai n est pas compte comme reussi', () async {
      await expectLater(
        avecNouveauxEssais<void>(
          () async {
            throw const StorageException(
              'The resource already exists',
              statusCode: '409',
              error: 'Duplicate',
            );
          },
          attendre: _sansAttente,
          dejaFait: (_) {},
        ),
        throwsA(isA<StorageException>()),
      );
    });

    test('« existe deja » a un nouvel essai vaut succes', () async {
      int appels = 0;
      await avecNouveauxEssais<void>(
        () async {
          appels++;
          if (appels == 1) {
            throw const StorageException('Gateway', statusCode: '504');
          }
          throw const StorageException(
            'The resource already exists',
            error: 'Duplicate',
            statusCode: '409',
          );
        },
        attendre: _sansAttente,
        dejaFait: (_) {},
      );
      expect(appels, 2);
    });
  });

  group('ServiceDossierSupabase.deposerPiece', () {
    test(
      'une panne de l envoi reprend l envoi seul, avec la meme cle',
      () async {
        final List<String> cles = <String>[];
        final _Faux faux = _Faux((String chemin, int rang, http.Request r) {
          if (chemin == '/storage/v1/object/kyc') {
            cles.add(r.url.path);
            return rang == 1
                ? _ok(
                    '{"statusCode":"544","error":"Timeout","message":"x"}',
                    544,
                  )
                : _ok('{"Key":"k"}');
          }
          if (chemin == '/functions/v1/kyc-confirme') {
            return _ok('{"confirme":true}');
          }
          return _ok('', 201);
        });
        final SupabaseClient c = await _client(faux);
        await ServiceDossierSupabase(
          c,
          attendre: _sansAttente,
        ).deposerPiece(_piece);

        expect(cles, hasLength(2));
        expect(
          cles.toSet(),
          hasLength(1),
          reason: 'une seule cle, un seul fichier',
        );
        expect(
          faux.chemins.where((String p) => p == 'POST /rest/v1/kyc_documents'),
          hasLength(1),
        );
      },
    );

    test('reponse perdue a l insertion : le nouvel essai ne cree pas de '
        'seconde ligne', () async {
      final _Faux faux = _Faux((String chemin, int rang, http.Request r) {
        if (chemin == '/rest/v1/kyc_documents') {
          return rang == 1
              ? _ok('{"code":"503","message":"indisponible"}', 503)
              : _ok('{"code":"23505","message":"duplicate key value"}', 409);
        }
        if (chemin == '/functions/v1/kyc-confirme') {
          return _ok('{"confirme":true}');
        }
        return _ok('{"Key":"k"}');
      });
      final SupabaseClient c = await _client(faux);
      await ServiceDossierSupabase(
        c,
        attendre: _sansAttente,
      ).deposerPiece(_piece);

      expect(faux.corps, hasLength(2));
      final Set<Object?> ids = <Object?>{
        for (final String b in faux.corps) (jsonDecode(b) as Map)['id'],
      };
      expect(ids, hasLength(1), reason: 'le meme identifiant de ligne');
      // Le fichier n'est envoye qu'une fois : on reprend a l'etape echouee.
      expect(
        faux.chemins.where((String p) => p == 'POST /storage/v1/object/kyc'),
        hasLength(1),
      );
    });

    test('relecture B1 : 403 de la confirmation (base en panne) : deux '
        'nouveaux essais, puis « indisponible », jamais « refus »', () async {
      final _Faux faux = _Faux((String chemin, int rang, http.Request r) {
        if (chemin == '/functions/v1/kyc-confirme') {
          return _ok('{"error":"confirmation refusee"}', 403);
        }
        return _ok('{"Key":"k"}');
      });
      final SupabaseClient c = await _client(faux);
      Object? erreur;
      try {
        await ServiceDossierSupabase(
          c,
          attendre: _sansAttente,
        ).deposerPiece(_piece);
      } on Object catch (e) {
        erreur = e;
      }
      expect(erreur, isA<ConfirmationIndisponible>());
      expect(causeEchecDepot(erreur!), CauseEchecDepot.indisponible);
      expect(
        faux.chemins.where(
          (String p) => p == 'POST /functions/v1/kyc-confirme',
        ),
        hasLength(1 + nouveauxEssaisDepot),
      );
      expect(faux.corps, isEmpty, reason: 'aucune ligne sans confirmation');
    });

    test('relecture B2 : 401 de la confirmation puis 200 : le depot aboutit, '
        'sans aucun rafraichissement de session', () async {
      final _Faux faux = _Faux((String chemin, int rang, http.Request r) {
        if (chemin == '/functions/v1/kyc-confirme') {
          return rang == 1
              ? _ok('{"error":"authentification requise"}', 401)
              : _ok('{"confirme":true}');
        }
        if (chemin == '/rest/v1/kyc_documents') return _ok('', 201);
        return _ok('{"Key":"k"}');
      });
      final SupabaseClient c = await _client(faux);
      await ServiceDossierSupabase(
        c,
        attendre: _sansAttente,
      ).deposerPiece(_piece);
      expect(faux.corps, hasLength(1));
      expect(
        faux.chemins.where((String p) => p.contains('/auth/v1/token')),
        isEmpty,
        reason: 'S1 : aucun refreshSession force',
      );
      expect(c.auth.currentSession, isNotNull);
    });

    test('le type annonce au seau vient de l extension retenue', () {
      expect(_piece.typeMime, 'image/jpeg');
      expect(
        PieceAEnvoyer(
          octets: Uint8List(0),
          nomFichier: 'piece.png',
          type: TypePiece.passeport,
        ).typeMime,
        'image/png',
      );
    });

    test('un contenu refuse (422) n est pas reessaye et se nomme', () async {
      final _Faux faux = _Faux((String chemin, int rang, http.Request r) {
        if (chemin == '/functions/v1/kyc-confirme') {
          return _ok('{"error":"contenu_non_conforme"}', 422);
        }
        return _ok('{"Key":"k"}');
      });
      final SupabaseClient c = await _client(faux);
      await expectLater(
        ServiceDossierSupabase(c, attendre: _sansAttente).deposerPiece(_piece),
        throwsA(isA<ContenuPieceNonConforme>()),
      );
      expect(
        faux.chemins.where(
          (String p) => p == 'POST /functions/v1/kyc-confirme',
        ),
        hasLength(1),
      );
      expect(faux.corps, isEmpty);
    });
  });

  test(
    'relecture S2 : la lecture du seau de ma photo se reessaie aussi',
    () async {
      final _PhotosEnPanne port = _PhotosEnPanne();
      final String seau = await seauDeMaPhoto(
        port,
        'moi',
        attendre: _sansAttente,
      );
      expect(port.appels, 2);
      expect(seau, 'photos_enseignants');
    },
  );
}

class _PhotosEnPanne extends PhotosNeutres {
  int appels = 0;

  @override
  Future<Map<String, SourcePhoto>> sources(List<String> profileIds) async {
    appels++;
    if (appels == 1) {
      throw const PostgrestException(message: 'indisponible', code: '503');
    }
    return <String, SourcePhoto>{
      'moi': const SourcePhoto(seau: 'photos_enseignants', cle: null),
    };
  }
}
