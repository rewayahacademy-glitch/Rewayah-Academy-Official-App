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
    status = 200;
    body = const <Object>[];
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
    status = 200;
    body = {'unexpected': 'object instead of row list'};
    await expectLater(
      HistoriqueObservationsAdminSupabase(() => client)
          .rechercher(const FiltreObservationsAdmin()),
      throwsA(isA<TypeError>()),
    );
  });
  test('une visite valide forme une ligne admin', () async {
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
    final p = await HistoriqueObservationsAdminSupabase(() => client)
        .rechercher(const FiltreObservationsAdmin());
    expect(p.lignes.single.seanceId, 's1');
    expect(p.curseur, isNull);
  });
}
