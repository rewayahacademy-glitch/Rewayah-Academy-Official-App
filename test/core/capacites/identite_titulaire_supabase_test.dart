import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/identite_titulaire_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  const Object body = <Object>[];
  const int status = 200;
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
}
