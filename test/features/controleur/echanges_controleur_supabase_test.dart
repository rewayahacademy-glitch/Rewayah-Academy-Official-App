import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/controleur/echanges_controleur_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  setUp(() async {
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final String body = await utf8.decoder.bind(request).join();
      requests.add(jsonDecode(body) as Map<String, dynamic>);
      if (requests.length == 1) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, Object?>{
              'code': 'XX000',
              'message': 'temporary failure',
              'details': null,
              'hint': null,
            }),
          );
      } else {
        request.response.statusCode = HttpStatus.noContent;
      }
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

  test(
    'reutilise la cle client lors du retry apres une erreur reseau',
    () async {
      final EchangesControleurSupabase adapter = EchangesControleurSupabase(
        client,
      );

      await expectLater(adapter.envoyer('fil-1', ' Bonjour '), throwsException);
      await adapter.envoyer('fil-1', ' Bonjour ');

      expect(requests, hasLength(2));
      expect(requests[0]['p_cle_client'], requests[1]['p_cle_client']);
      expect(requests[0]['p_fil_id'], 'fil-1');
      expect(requests[0]['p_texte'], 'Bonjour');
    },
  );
}
