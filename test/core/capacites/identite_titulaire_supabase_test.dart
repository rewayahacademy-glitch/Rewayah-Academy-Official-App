import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/identite_titulaire_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  const Object body = <Object>[];
  int status = 200;
  Object reponse = body;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      r.response.statusCode = status;
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(reponse));
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
  Future<void> ouvrirSession() => client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-token',
      'expires_in': 3600,
      'refresh_token': 'fake-refresh',
      'token_type': 'bearer',
      'user': {
        'id': '00000000-0000-0000-0000-000000000001',
        'app_metadata': {'provider': 'google'},
        'user_metadata': <String, Object>{},
        'aud': 'authenticated',
        'created_at': '2026-10-11T08:00:00Z',
        'email': 'titulaire@example.test',
      },
    }),
  );
  test('sans session echoue au lieu de fabriquer une identite', () async {
    await expectLater(
      IdentiteTitulaireSupabase(client).lire(),
      throwsA(isA<StateError>()),
    );
  });
  test('modification reste indisponible', () async {
    await expectLater(
      IdentiteTitulaireSupabase(client).modifier(prenom: 'A'),
      throwsA(isA<Exception>()),
    );
  });
  test(
    'session et profil valides rendent l identite depuis le faux HTTP',
    () async {
      await ouvrirSession();
      reponse = [
        {'first_name': 'Mina', 'last_name': 'Rami', 'account_status': 'active'},
      ];
      final identite = await IdentiteTitulaireSupabase(client).lire();
      expect(identite.prenom, 'Mina');
      expect(identite.nom, 'Rami');
      expect(identite.courriel, 'titulaire@example.test');
    },
  );
  test('profil absent et P0002 ne fabriquent pas une identite', () async {
    await ouvrirSession();
    reponse = const <Object>[];
    await expectLater(
      IdentiteTitulaireSupabase(client).lire(),
      throwsA(isA<StateError>()),
    );
    for (final code in ['42501', 'P0002']) {
      status = 400;
      reponse = {
        'code': code,
        'message': 'denied',
        'details': null,
        'hint': null,
      };
      await expectLater(
        IdentiteTitulaireSupabase(client).lire(),
        throwsA(isA<PostgrestException>()),
      );
      status = 200;
    }
  });
  test('champ de statut mal type echoue explicitement', () async {
    await ouvrirSession();
    reponse = [
      {'first_name': 'Mina', 'last_name': 'Rami', 'account_status': 42},
    ];
    await expectLater(
      IdentiteTitulaireSupabase(client).lire(),
      throwsA(isA<TypeError>()),
    );
  });
}
