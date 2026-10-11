import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_horloge/horloge_supabase.dart';
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
  test('sans session id et RPC vide: aucune horloge fabriquee', () async {
    status = 200;
    body = const <Object>[];
    final a = HorlogeSeanceSupabase(client);
    expect(await a.horlogeDe(groupeId: 'g'), isNull);
    expect(await a.horlogeDe(groupeId: 'g', sessionId: 's'), isNull);
  });
  test('42501 et P0002 remontent', () async {
    for (final c in ['42501', 'P0002']) {
      body = {'code': c, 'message': 'denied', 'details': null, 'hint': null};
      status = 400;
      await expectLater(
        HorlogeSeanceSupabase(client).horlogeDe(groupeId: 'g', sessionId: 's'),
        throwsA(isA<PostgrestException>()),
      );
    }
  });
  test('reponse malformee echoue au parsing', () async {
    status = 200;
    body = [
      {'debut_utc': 12},
    ];
    await expectLater(
      HorlogeSeanceSupabase(client).horlogeDe(groupeId: 'g', sessionId: 's'),
      throwsA(isA<TypeError>()),
    );
  });
  test('maintenant serveur retourne la valeur HTTP UTC', () async {
    status = 200;
    body = '2026-10-11T08:30:00Z';
    expect(
      await HorlogeSeanceSupabase(client).maintenantServeurUtc(),
      DateTime.utc(2026, 10, 11, 8, 30),
    );
  });
}
