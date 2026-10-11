import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/incidents_seances_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final requests = <Uri>[];
  final bodies = <Map<String, dynamic>>[];

  setUp(() async {
    requests.clear();
    bodies.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request.uri);
      bodies.add(
        jsonDecode(await utf8.decoder.bind(request.cast<List<int>>()).join())
            as Map<String, dynamic>,
      );
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode([
            {
              'id': 's1',
              'classe': 'A',
              'statut': 'tech_failure',
              'survenu_le': '2026-10-11T10:00:00Z',
              'enseignant': null,
            },
          ]),
        );
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'cle-factice',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'appelle seulement la RPC avec l’ancre UTC et une page plafonnée',
    () async {
      final results = await IncidentsSeancesSupabase(client)
          .dernieres24h(DateTime.utc(2026, 10, 11, 12));
      expect(results.single.id, 's1');
      expect(requests, hasLength(1));
      expect(requests.single.path, endsWith('/rpc/lister_incidents_seances'));
      final body = bodies.single;
      expect(body['p_limite'], 100);
      expect(body['p_offset'], 0);
    },
  );
}
