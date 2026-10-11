import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? response;

  setUp(() async {
    response = true;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
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

  test('décode les deux verdicts booléens de la RPC', () async {
    final PortCapaciteEleveSupabase port = PortCapaciteEleveSupabase(client);
    expect(await port.lire('profil-adulte'), isA<EleveAutonome>());
    response = false;
    expect(await port.lire('profil-adulte'), isA<PasEleve>());
  });

  test('ferme si le résultat RPC a une forme inconnue', () async {
    response = 'true';
    expect(
      await PortCapaciteEleveSupabase(client).lire('profil-adulte'),
      isA<CapaciteInconnue>(),
    );
  });
}
