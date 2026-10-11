import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/historique_observations_supabase.dart';
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
  test(
    'liste vide et detail absent ne fabriquent pas une observation',
    () async {
      final a = HistoriqueObservationsSupabase(() => client);
      expect(await a.mesObservations(), isEmpty);
      expect(await a.detail(seanceId: 's'), isNull);
    },
  );
  test('42501 et P0002 remontent', () async {
    final a = HistoriqueObservationsSupabase(() => client);
    for (final code in ['42501', 'P0002']) {
      body = {'code': code, 'message': 'denied', 'details': null, 'hint': null};
      status = 400;
      await expectLater(
        a.mesObservations(),
        throwsA(isA<PostgrestException>()),
      );
    }
  });
  test('ligne malformee est ecartee', () async {
    body = [
      {'id': 1, 'session_id': null, 'entered_at': 'bad'},
    ];
    expect(
      await HistoriqueObservationsSupabase(() => client).mesObservations(),
      isEmpty,
    );
  });
}
