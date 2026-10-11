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
      status = 200;
      body = const <Object>[];
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
    status = 200;
    body = {'unexpected': 'object instead of row list'};
    await expectLater(
      HistoriqueObservationsSupabase(() => client).mesObservations(),
      throwsA(isA<TypeError>()),
    );
  });
  test('une visite valide est renvoyee depuis le faux endpoint', () async {
    status = 200;
    body = [
      {
        'id': 'v1',
        'session_id': 's1',
        'groupe_id': 'g1',
        'observateur_profile_id': 't1',
        'role': 'guardian_observer',
        'enfant_profile_id': 'e1',
        'entered_at': '2026-10-11T08:00:00Z',
        'left_at': '2026-10-11T08:01:00Z',
        'duration_seconds': 60,
        'visit_number': 1,
        'policy_version': 'v1',
        'fin_de_visite': 'sortie_volontaire',
      },
    ];
    expect(
      (await HistoriqueObservationsSupabase(
        () => client,
      ).mesObservations()).single.visites.single.sessionId,
      's1',
    );
  });
}
