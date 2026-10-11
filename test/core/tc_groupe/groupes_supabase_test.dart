import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/groupes_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<({String method, Uri uri})> requests = [];
  final List<({int status, String body})> responses = [];

  const groupA = '00000000-0000-4000-8000-000000000101';
  const groupB = '00000000-0000-4000-8000-000000000102';

  Map<String, dynamic> groupRow({Object threshold = 5}) => <String, dynamic>{
    'groupe_id': groupA,
    'libelle': 'Classe An-Nour',
    'type_public': 'enfant',
    'seuil_max': threshold,
    'couleur_jeton': 4,
    'nom_cours': 'Lecture',
    'teacher_id': '00000000-0000-4000-8000-000000000103',
    'teacher_prenom': 'Amina',
    'teacher_titre': 'sayyida',
    'teacher_photo_cle': 'enseignants/amina.webp',
    'teacher_country': 'France',
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

  test(
    'mesGroupes maps server rows and requests the household view in order',
    () async {
      enqueue([
        groupRow(),
        {...groupRow(), 'groupe_id': groupB, 'libelle': 'Classe B'},
      ]);

      final List<GroupSummaryVM> groups = await GroupesSupabase(client)
          .mesGroupes();

      expect(groups, hasLength(2));
      expect(groups.first.groupeId, groupA);
      expect(groups.first.seuilMax, 5);
      expect(groups.first.nombreMembres, 3);
      expect(groups.first.nomCours, 'Lecture');
      expect(groups.first.enseignant.titre, TitreEnseignant.sayyida);
      expect(groups.first.enseignant.pays, 'France');
      expect(requests.single.uri.path, endsWith('/mes_groupes_famille_v'));
      expect(
        requests.single.uri.queryParameters['order'],
        'libelle.asc.nullslast',
      );
    },
  );

  test('une liste vide reste vide', () async {
    enqueue(const <Object>[]);

    expect(await GroupesSupabase(client).mesGroupes(), isEmpty);
    expect(requests, hasLength(1));
  });

  test('42501 et P0002 restent des erreurs PostgREST', () async {
    for (final String code in ['42501', 'P0002']) {
      enqueue({
        'code': code,
        'message': 'denied',
        'details': null,
        'hint': null,
      }, status: 400);
      await expectLater(
        GroupesSupabase(client).mesGroupes(),
        throwsA(isA<PostgrestException>()),
      );
    }
  });

  test('une reponse de liste malformee remonte une erreur typee', () async {
    enqueue({'unexpected': 'object instead of row list'});

    await expectLater(
      GroupesSupabase(client).mesGroupes(),
      throwsA(isA<TypeError>()),
    );
  });

  test(
    'un seuil malforme est une erreur de format, pas une valeur inventee',
    () async {
      enqueue([groupRow(threshold: '5')]);

      await expectLater(
        GroupesSupabase(client).mesGroupes(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('groupe filtre par id et distingue absence et ligne valide', () async {
    enqueue(const <Object>[]);
    expect(await GroupesSupabase(client).groupe(groupA), isNull);
    expect(requests.single.uri.path, endsWith('/mes_groupes_famille_v'));
    expect(requests.single.uri.queryParameters['groupe_id'], 'eq.$groupA');

    enqueue([groupRow()]);
    final GroupSummaryVM? group = await GroupesSupabase(client).groupe(groupA);
    expect(group?.groupeId, groupA);
    expect(group?.libelle, 'Classe An-Nour');
  });
}
