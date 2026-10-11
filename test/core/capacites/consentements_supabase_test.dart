import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/consentements_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<({String method, Uri uri, String body})> requetes = [];
  Object body = const <Object>[];
  String? corpsBrut;
  int status = 200;
  setUp(() async {
    status = 200;
    body = const <Object>[];
    corpsBrut = null;
    requetes.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      final octets = await r.fold<List<int>>(
        <int>[],
        (precedents, bloc) => precedents..addAll(bloc),
      );
      final corps = utf8.decode(octets);
      requetes.add((method: r.method, uri: r.uri, body: corps));
      r.response.statusCode = status;
      r.response.headers.contentType = ContentType.json;
      r.response.write(corpsBrut ?? jsonEncode(body));
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
        'id': '00000000-0000-0000-0000-000000000002',
        'app_metadata': {'provider': 'google'},
        'user_metadata': <String, Object>{},
        'aud': 'authenticated',
        'created_at': '2026-10-11T08:00:00Z',
        'email': 'titulaire@example.test',
      },
    }),
  );
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
    status = 200;
    body = const <Object>[];
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
  test('reponse HTTP de forme incorrecte remonte une erreur typee', () async {
    corpsBrut = '{"unexpected":"object instead of row list"}';
    final a = ConsentementsSupabase(
      acceptations: ServiceAcceptationsSupabase(client),
      dossier: ServiceDossierSupabase(client),
      profilId: 'profile',
    );
    await expectLater(a.signees(), throwsA(isA<TypeError>()));
  });
  test(
    'acceptation valide emise par HTTP ne demande pas un renouvellement',
    () async {
      status = 200;
      body = [
        {
          'contract_kind': 'guardian_terms',
          'version': VersionsContrat.pour(SorteContrat.conditionsTuteur),
          'accepted_at': '2026-10-11T08:00:00Z',
        },
      ];
      final a = ConsentementsSupabase(
        acceptations: ServiceAcceptationsSupabase(client),
        dossier: ServiceDossierSupabase(client),
        profilId: 'profile',
      );
      expect(await a.signees(), hasLength(1));
      expect(await a.aRenouveler(), isEmpty);
    },
  );
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
  test('accepter envoie une insertion pour le profil de la session', () async {
    await ouvrirSession();
    final a = ConsentementsSupabase(
      acceptations: ServiceAcceptationsSupabase(client),
      dossier: ServiceDossierSupabase(client),
      profilId: 'profile',
    );
    await a.accepter(sorte: SorteContrat.conditionsTuteur, version: 'v1');
    expect(requetes.single.method, 'POST');
    expect(requetes.single.uri.path, endsWith('/contract_acceptances'));
    expect(jsonDecode(requetes.single.body), {
      'profile_id': '00000000-0000-0000-0000-000000000002',
      'contract_kind': 'guardian_terms',
      'version': 'v1',
    });
  });
}
