import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/planning_direction_supabase.dart';
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
              'debut': '2026-10-12T09:00:00Z',
              'duree_minutes': 60,
              'statut': 'planned',
              'enseignant': null,
            },
          ]),
        );
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

  test('demande la semaine et mappe les séances depuis la RPC', () async {
    final rows = await PlanningDirectionSupabase(client)
        .semaine(DateTime(2026, 10, 12));
    expect(rows.single.dureeMinutes, 60);
    expect(rows.single.classe, 'A');
    expect(requests.single.path, endsWith('/rpc/lister_planning_direction'));
    expect(
      bodies.single['p_lundi'],
      DateTime(2026, 10, 12).toUtc().toIso8601String(),
    );
    expect(bodies.single['p_limite'], 100);
  });
}
