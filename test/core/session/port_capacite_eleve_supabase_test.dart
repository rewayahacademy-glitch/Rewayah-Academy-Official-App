import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve.dart';
import 'package:rewayah_academy/core/session/port_capacite_eleve_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late PortCapaciteEleveSupabase port;
  Object? response;
  String? requestPath;
  String? requestBody;
  int responseStatus = HttpStatus.ok;

  setUp(() async {
    response = true;
    responseStatus = HttpStatus.ok;
    requestPath = null;
    requestBody = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requestPath = request.uri.path;
      requestBody = await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = responseStatus
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'fake-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    port = PortCapaciteEleveSupabase(client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'decode les verdicts booleens et appelle la RPC sans identifiant cible',
    () async {
      expect(await port.lire('profile-a'), isA<EleveAutonome>());
      expect(requestPath, '/rest/v1/rpc/ma_capacite_eleve');
      expect(requestBody, isNot(contains('profile-a')));

      response = false;
      expect(await port.lire('profile-b'), isA<PasEleve>());
      expect(requestBody, isNot(contains('profile-b')));
    },
  );

  test('ferme si la reponse n est pas un booleen', () async {
    response = 'true';
    expect(await port.lire('profile-a'), isA<CapaciteInconnue>());
  });

  test('ferme sur une erreur de transport serveur', () async {
    responseStatus = HttpStatus.internalServerError;
    response = <String, String>{'message': 'unavailable'};
    expect(await port.lire('profile-a'), isA<CapaciteInconnue>());
  });
}
