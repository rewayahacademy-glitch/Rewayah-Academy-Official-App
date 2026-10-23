import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late ServicePlanningSupabase service;
  String? requestPath;
  String? requestQuery;

  setUp(() async {
    requestPath = null;
    requestQuery = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requestPath = request.uri.path;
      requestQuery = request.uri.query;
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<Object>[]));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'fake-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    service = ServicePlanningSupabase(client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('un eleve precis : la requete porte student_id = eleveId', () async {
    await service.seances(eleveId: 'eleve-a');
    expect(requestPath, '/rest/v1/mes_seances_v');
    expect(requestQuery, contains('student_id=eq.eleve-a'));
  });

  test('le foyer (sans eleveId) : aucun filtre student_id', () async {
    await service.seances();
    expect(requestPath, '/rest/v1/mes_seances_v');
    expect(requestQuery, isNot(contains('student_id')));
  });
}
