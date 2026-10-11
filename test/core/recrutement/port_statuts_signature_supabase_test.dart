import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/recrutement/port_statuts_signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? responseBody;
  int responseStatus = HttpStatus.ok;
  Map<String, dynamic>? requestBody;

  setUp(() async {
    responseBody = <String, Object?>{
      'contrat': <String, Object?>{'status': 'signe_version_courante'},
      'accuse': <String, Object?>{
        'status': 'signe_ancienne_version',
        'version_signee': '2025-11',
      },
    };
    responseStatus = HttpStatus.ok;
    requestBody = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requestBody = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      request.response
        ..statusCode = responseStatus
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(responseBody));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'fake-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('transmet le dossier et décode les trois statuts permis', () async {
    responseBody = <String, Object?>{
      'contrat': <String, Object?>{'status': 'signe_version_courante'},
      'accuse': <String, Object?>{
        'status': 'signe_ancienne_version',
        'version_signee': '2025-11',
      },
    };

    final StatutsSignature? statuses = await StatutsSignatureSupabase(client)
        .pour('profile-42');

    expect(requestBody, <String, dynamic>{'p_profile_id': 'profile-42'});
    expect(statuses!.contrat, isA<SigneVersionCourante>());
    expect(statuses.accuse, isA<SigneAncienneVersion>());
    expect((statuses.accuse as SigneAncienneVersion).versionSignee, '2025-11');
    expect(statuses.complets, isFalse);

    responseBody = <String, Object?>{
      'contrat': <String, Object?>{'status': 'non_signe'},
      'accuse': <String, Object?>{'status': 'signe_version_courante'},
    };
    final StatutsSignature second = (await StatutsSignatureSupabase(client)
        .pour('profile-42'))!;
    expect(second.contrat, isA<NonSigne>());
    expect(second.accuse, isA<SigneVersionCourante>());
  });

  test('refuse un statut absent, inconnu ou une réponse mal formée', () async {
    for (final Object? invalidStatus in <Object?>[null, 'future_status', 7]) {
      responseBody = <String, Object?>{
        'contrat': <String, Object?>{'status': invalidStatus},
        'accuse': <String, Object?>{'status': 'non_signe'},
      };
      await expectLater(
        StatutsSignatureSupabase(client).pour('profile-42'),
        throwsFormatException,
      );
    }

    for (final Object? invalidVersion in <Object?>[null, 7, '', '   ']) {
      responseBody = <String, Object?>{
        'contrat': <String, Object?>{
          'status': 'signe_ancienne_version',
          'version_signee': invalidVersion,
        },
        'accuse': <String, Object?>{'status': 'non_signe'},
      };
      await expectLater(
        StatutsSignatureSupabase(client).pour('profile-42'),
        throwsFormatException,
      );
    }

    responseBody = <String, Object?>{'contrat': null, 'accuse': null};
    await expectLater(
      StatutsSignatureSupabase(client).pour('profile-42'),
      throwsFormatException,
    );
    responseBody = null;
    await expectLater(
      StatutsSignatureSupabase(client).pour('profile-42'),
      throwsFormatException,
    );
  });

  test('traduit P0002 en absence et propage les autres erreurs RPC', () async {
    responseStatus = HttpStatus.notFound;
    responseBody = <String, Object?>{'code': 'P0002', 'message': 'absent'};
    expect(
      await StatutsSignatureSupabase(client).pour('profile-absent'),
      isNull,
    );

    responseStatus = HttpStatus.forbidden;
    responseBody = <String, Object?>{'code': '42501', 'message': 'interdit'};
    await expectLater(
      StatutsSignatureSupabase(client).pour('profile-42'),
      throwsA(isA<PostgrestException>().having((e) => e.code, 'code', '42501')),
    );
  });
}
