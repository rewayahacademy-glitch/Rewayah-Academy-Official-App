import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/recrutement/port_statuts_signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? response;

  setUp(() async {
    response = <String, Object?>{
      'contrat': <String, Object?>{'status': 'non_signe'},
      'accuse': <String, Object?>{
        'status': 'signe_ancienne_version',
        'version_signee': '2026-09',
      },
    };
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

  test('decode explicit unsigned and signed-old statuses', () async {
    final StatutsSignature? statuses = await StatutsSignatureSupabase(client)
        .pour('profile-1');

    expect(statuses?.contrat, isA<NonSigne>());
    expect(
      statuses?.accuse,
      isA<SigneAncienneVersion>().having(
        (SigneAncienneVersion value) => value.versionSignee,
        'signed version',
        '2026-09',
      ),
    );
  });

  test(
    'reject unknown or absent status instead of reporting unsigned',
    () async {
      for (final Object? status in <Object?>['unexpected', null, 7]) {
        response = <String, Object?>{
          'contrat': <String, Object?>{'status': status},
          'accuse': <String, Object?>{'status': 'non_signe'},
        };
        await expectLater(
          StatutsSignatureSupabase(client).pour('profile-1'),
          throwsFormatException,
        );
      }
    },
  );

  test('reject old-signature status without a non-empty version', () async {
    for (final Object? version in <Object?>[null, '', '   ', 42]) {
      response = <String, Object?>{
        'contrat': <String, Object?>{
          'status': 'signe_ancienne_version',
          if (version case final Object value) 'version_signee': value,
        },
        'accuse': <String, Object?>{'status': 'non_signe'},
      };
      await expectLater(
        StatutsSignatureSupabase(client).pour('profile-1'),
        throwsFormatException,
      );
    }
  });
}
