import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/consentements_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
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
  test('profil absent est une erreur, pas une liste vide', () async {
    final a = ConsentementsSupabase(
      acceptations: ServiceAcceptationsSupabase(client),
      dossier: ServiceDossierSupabase(client),
      profilId: null,
    );
    await expectLater(a.signees(), throwsA(isA<StateError>()));
    await expectLater(a.aRenouveler(), throwsA(isA<StateError>()));
  });
  test('liste vide reste vide et signale le contrat a renouveler', () async {
    final a = ConsentementsSupabase(
      acceptations: ServiceAcceptationsSupabase(client),
      dossier: ServiceDossierSupabase(client),
      profilId: 'profile',
    );
    expect(await a.signees(), isEmpty);
    expect(await a.aRenouveler(), hasLength(1));
  });
  test('42501 et P0002 ne sont pas convertis en liste vide', () async {
    final a = ConsentementsSupabase(
      acceptations: ServiceAcceptationsSupabase(client),
      dossier: ServiceDossierSupabase(client),
      profilId: 'profile',
    );
    for (final c in ['42501', 'P0002']) {
      body = {'code': c, 'message': 'denied', 'details': null, 'hint': null};
      status = 400;
      await expectLater(a.signees(), throwsA(isA<PostgrestException>()));
    }
  });
  test('accepter sans session echoue', () async {
    final a = ConsentementsSupabase(
      acceptations: ServiceAcceptationsSupabase(client),
      dossier: ServiceDossierSupabase(client),
      profilId: 'profile',
    );
    await expectLater(
      a.accepter(sorte: SorteContrat.conditionsTuteur, version: 'x'),
      throwsA(isA<StateError>()),
    );
  });
}
