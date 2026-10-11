import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/classes_foyer_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<({String method, Uri uri})> requests = [];
  final List<({int status, String body})> responses = [];

  const eleveId = '00000000-0000-4000-8000-000000000101';
  const groupeId = '00000000-0000-4000-8000-000000000102';

  Map<String, dynamic> groupeRow({Object seuil = 8}) => <String, dynamic>{
    'groupe_id': groupeId,
    'libelle': 'Classe An-Nour',
    'type_public': 'adulte',
    'seuil_max': seuil,
    'weekday': 2,
    'hour_local': '18:00:00',
    'timezone_iana': 'Europe/Paris',
    'couleur_jeton': 4,
    'nom_cours': 'Lecture',
    'programme_niveau_id': null,
    'teacher_id': '00000000-0000-4000-8000-000000000103',
    'teacher_prenom': 'Amina',
    'teacher_titre': 'sayyida',
    'teacher_photo_cle': null,
    'nb_membres': 3,
  };

  void enqueue(Object body, {int status = 200}) {
    responses.add((status: status, body: jsonEncode(body)));
  }

  setUp(() async {
    requests.clear();
    responses.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final response = responses.removeAt(0);
      requests.add((method: request.method, uri: request.uri));
      await request.drain<void>();
      request.response.statusCode = response.status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(response.body);
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'fake-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('joins open memberships to the household view and preserves view ordering', () async {
    enqueue([
      {'groupe_id': groupeId},
      {'groupe_id': '00000000-0000-4000-8000-000000000199'},
    ]);
    enqueue([groupeRow()]);

    final result = await ClassesFoyerSupabase(client).classesDe(eleveId);

    expect(result, hasLength(1));
    expect(result.single.eleveId, eleveId);
    expect(result.single.classe.groupeId, groupeId);
    expect(result.single.classe.libelle, 'Classe An-Nour');
    expect(requests, hasLength(2));
    expect(requests.first.uri.path, endsWith('/groupe_membres'));
    expect(requests.first.uri.queryParameters['student_id'], 'eq.$eleveId');
    expect(requests.first.uri.queryParameters['left_at'], 'is.null');
    expect(requests.first.uri.queryParameters['order'], 'joined_at.asc.nullslast');
    expect(requests.last.uri.path, endsWith('/mes_groupes_famille_v'));
    expect(requests.last.uri.queryParameters['order'], 'libelle.asc.nullslast');
  });

  test('empty membership returns empty without querying the view', () async {
    enqueue(const <Object>[]);

    expect(await ClassesFoyerSupabase(client).classesDe(eleveId), isEmpty);
    expect(requests, hasLength(1));
  });

  test('42501 and P0002 remain typed PostgREST errors', () async {
    final adapter = ClassesFoyerSupabase(client);
    for (final code in ['42501', 'P0002']) {
      enqueue({
        'code': code,
        'message': 'denied',
        'details': null,
        'hint': null,
      }, status: 400);
      await expectLater(adapter.classesDe(eleveId), throwsA(isA<PostgrestException>()));
    }
  });

  test('malformed membership rows do not become an invented empty list', () async {
    enqueue({'unexpected': 'object instead of row list'});

    await expectLater(
      ClassesFoyerSupabase(client).classesDe(eleveId),
      throwsA(isA<TypeError>()),
    );
  });

  test('a malformed view row is a format error, not a fabricated class', () async {
    enqueue([
      {'groupe_id': groupeId},
    ]);
    enqueue([groupeRow(seuil: 'unknown')]);

    await expectLater(
      ClassesFoyerSupabase(client).classesDe(eleveId),
      throwsA(isA<FormatException>()),
    );
  });
}
