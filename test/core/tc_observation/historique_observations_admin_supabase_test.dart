import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/historique_observations_admin_supabase.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object body = const <Object>[];
  int status = 200;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      r.response.statusCode = status;
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(body));
      await r.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'fake',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });
  test('page vide sans curseur', () async {
    final p = await HistoriqueObservationsAdminSupabase(() => client)
        .rechercher(const FiltreObservationsAdmin());
    expect(p.lignes, isEmpty);
    expect(p.curseur, isNull);
  });
  test('42501 et P0002 remontent', () async {
    final a = HistoriqueObservationsAdminSupabase(() => client);
    for (final c in ['42501', 'P0002']) {
      body = {'code': c, 'message': 'denied', 'details': null, 'hint': null};
      status = 400;
      await expectLater(
        a.rechercher(const FiltreObservationsAdmin()),
        throwsA(isA<PostgrestException>()),
      );
    }
  });
  test('ligne malformee ne fabrique pas un resultat', () async {
    body = [
      {'id': 1, 'entered_at': 'bad'},
    ];
    final p = await HistoriqueObservationsAdminSupabase(() => client)
        .rechercher(const FiltreObservationsAdmin());
    expect(p.lignes, isEmpty);
    expect(p.curseur, isNull);
  });
}
