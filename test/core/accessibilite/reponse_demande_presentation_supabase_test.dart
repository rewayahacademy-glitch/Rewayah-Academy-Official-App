import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/port_reponse_demande_presentation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<Uri> requests = <Uri>[];
  final List<String> bodies = <String>[];

  setUp(() async {
    requests.clear();
    bodies.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requests.add(request.uri);
      bodies.add(await utf8.decoder.bind(request).join());
      final String path = request.uri.path;
      final Object response = switch (path) {
        '/rest/v1/rpc/lire_demandes_presentation_en_attente' =>
          <Map<String, Object>>[
            <String, Object>{
              'id': 'demande-1',
              'eleve_id': 'eleve-1',
              'eleve_prenom': 'Amine',
              'cree_le': '2026-10-11T09:30:00Z',
            },
          ],
        '/rest/v1/profiles' => <String, String>{'household_id': 'foyer-1'},
        '/rest/v1/households' => <String, String>{'timezone': 'Europe/Paris'},
        '/rest/v1/rpc/accepter_demande_presentation' => 'acceptee',
        '/rest/v1/rpc/refuser_demande_presentation' => 'refusee',
        _ => const <Object>[],
      };
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'lit les demandes du RPC et conserve UTC avec le fuseau du foyer',
    () async {
      await client.auth.recoverSession(
        jsonEncode(<String, Object>{
          'access_token': _jwtFor('guardian-1'),
          'refresh_token': 'refresh-fictif',
          'token_type': 'bearer',
          'user': <String, String>{'id': 'guardian-1'},
        }),
      );
      final List<DemandePresentationEnAttente> rows =
          await ReponseDemandePresentationSupabase(client).enAttente();

      expect(rows, hasLength(1));
      expect(rows.single.id, 'demande-1');
      expect(rows.single.eleveId, 'eleve-1');
      expect(rows.single.creeeLe, DateTime.utc(2026, 10, 11, 9, 30));
      expect(rows.single.creeeLe.isUtc, isTrue);
      expect(rows.single.fuseauIana, 'Europe/Paris');
      expect(
        requests.first.path,
        endsWith('/rpc/lire_demandes_presentation_en_attente'),
      );
    },
  );

  test(
    'les decisions transmettent uniquement l identifiant de demande',
    () async {
      final ReponseDemandePresentationSupabase port =
          ReponseDemandePresentationSupabase(client);

      await port.accepter('demande-1');
      await port.refuser('demande-2');

      expect(requests.map((Uri uri) => uri.path), <String>[
        '/rest/v1/rpc/accepter_demande_presentation',
        '/rest/v1/rpc/refuser_demande_presentation',
      ]);
      expect(jsonDecode(bodies[0]), <String, String>{
        'p_demande_id': 'demande-1',
      });
      expect(jsonDecode(bodies[1]), <String, String>{
        'p_demande_id': 'demande-2',
      });
    },
  );

  test('une file vide ne lit ni profil ni fuseau', () async {
    await server.close(force: true);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requests.add(request.uri);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('[]');
      await request.response.close();
    });
    await client.dispose();
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    expect(
      await ReponseDemandePresentationSupabase(client).enAttente(),
      isEmpty,
    );
    expect(requests, hasLength(1));
  });
}

String _jwtFor(String subject) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode(<String, Object>{'alg': 'none', 'typ': 'JWT'})}.'
      '${encode(<String, Object>{'sub': subject})}.signature-fictive';
}
