import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/dossier/port_acces_pieces_kyc.dart';
import 'package:rewayah_academy/core/dossier/port_acces_pieces_kyc_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? response;
  String? rpcBody;

  setUp(() async {
    response = <String, Object?>{'type': 'memeGenre'};
    rpcBody = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      rpcBody = await utf8.decoder.bind(request).join();
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

  test('demande le verdict serveur sans lire le genre côté client', () async {
    final AccesPieceKyc acces = await PortAccesPiecesKycSupabase(client)
        .pour('dossier-1');

    expect(acces, isA<AccesMemeGenre>());
    expect(rpcBody, contains('dossier-1'));
    expect(rpcBody, isNot(contains('gender')));
  });

  test('décode l’exception et les raisons de refus fermées', () async {
    response = <String, Object?>{'type': 'exceptionSuperAdmin'};
    expect(
      await PortAccesPiecesKycSupabase(client).pour('dossier-2'),
      isA<AccesExceptionSuperAdmin>(),
    );

    for (final (String reason, RefusPieceKyc expected)
        in <(String, RefusPieceKyc)>[
          ('genreDifferent', RefusPieceKyc.genreDifferent),
          ('adminSansGenre', RefusPieceKyc.adminSansGenre),
          ('profilNonAutorise', RefusPieceKyc.profilNonAutorise),
        ]) {
      response = <String, Object?>{'type': 'refus', 'raison': reason};
      expect(
        await PortAccesPiecesKycSupabase(client).pour('dossier-2'),
        isA<AccesRefuse>().having(
          (AccesRefuse value) => value.raison,
          'raison',
          expected,
        ),
      );
    }
  });

  test('refuse les formes inconnues et les identifiants vides', () async {
    response = <String, Object?>{'type': 'refus', 'raison': 'autre'};
    expect(
      () => PortAccesPiecesKycSupabase(client).pour('dossier-3'),
      throwsFormatException,
    );
    rpcBody = null;
    expect(
      await PortAccesPiecesKycSupabase(client).pour('  '),
      isA<AccesRefuse>(),
    );
    expect(rpcBody, isNull);
  });

  test('lit le statut super-admin via le RPC auth.uid courant', () async {
    response = true;
    expect(await PortAccesPiecesKycSupabase(client).exceptionActive(), isTrue);
    response = false;
    expect(await PortAccesPiecesKycSupabase(client).exceptionActive(), isFalse);
    response = 'true';
    expect(
      () => PortAccesPiecesKycSupabase(client).exceptionActive(),
      throwsFormatException,
    );
  });
}
