import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/port_reprises_admin.dart';
import 'package:rewayah_academy/core/foyer/reprises_admin_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? response;
  int statusCode = HttpStatus.ok;
  final List<String> paths = <String>[];
  final List<Map<String, dynamic>> bodies = <Map<String, dynamic>>[];

  setUp(() async {
    response = <Object?>[
      <String, Object?>{
        'id': 'reprise-1',
        'demandeur_prenom': 'Sana',
        'demandeur_nom': 'A',
        'foyer_nom': 'Foyer A',
        'statut': 'a_examiner',
        'decidable': true,
        'deposee_le': '2026-10-11T17:30:00Z',
        'examen_possible_le': null,
        'redepot_possible_le': null,
      },
      <String, Object?>{
        'id': 'reprise-2',
        'demandeur_prenom': 'Meriem',
        'demandeur_nom': 'B',
        'foyer_nom': 'Foyer B',
        'statut': 'refusee_par_titulaire',
        'decidable': false,
        'deposee_le': null,
        'examen_possible_le': '2026-10-12T00:00:00+00:00',
        'redepot_possible_le': null,
      },
    ];
    statusCode = HttpStatus.ok;
    paths.clear();
    bodies.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      paths.add(request.uri.path);
      final String body = await utf8.decoder.bind(request).join();
      if (body.isNotEmpty) {
        final Object? decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) bodies.add(decoded);
      }
      request.response
        ..statusCode = statusCode
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

  test('lit les statuts et les dates rendus par le serveur', () async {
    final List<RepriseAdmin> rows = await ReprisesAdminSupabase(client)
        .lister();

    expect(rows, hasLength(2));
    expect(rows[0].id, 'reprise-1');
    expect(rows[0].etat, EtatRepriseAdmin.aExaminer);
    expect(rows[0].decidable, isTrue);
    expect(rows[0].deposeeLe, DateTime.parse('2026-10-11T17:30:00Z').toLocal());
    expect(rows[0].examenPossibleLe, isNull);
    expect(rows[1].etat, EtatRepriseAdmin.refuseeParTitulaire);
    expect(rows[1].decidable, isFalse);
    expect(rows[1].deposeeLe, isNull);
    expect(paths.single, endsWith('/lister_reprises_admin'));
  });

  test('envoie la clé stable et distingue les deux résultats métier', () async {
    response = <String, Object?>{
      'statut': 'decidee',
      'foyer_personnel_cree': true,
    };
    final ReprisesAdminSupabase adapter = ReprisesAdminSupabase(client);
    expect(
      await adapter.decider(
        repriseId: 'reprise-1',
        approuver: true,
        cle: 'cle-idempotence',
      ),
      isA<RepriseDecidee>(),
    );
    response = <String, Object?>{
      'statut': 'deja_traitee',
      'foyer_personnel_cree': false,
    };
    expect(
      await adapter.decider(
        repriseId: 'reprise-1',
        approuver: true,
        cle: 'cle-idempotence',
      ),
      isA<RepriseDejaTraitee>(),
    );
    expect(paths, <String>[
      '/rest/v1/rpc/decider_reprise_foyer',
      '/rest/v1/rpc/decider_reprise_foyer',
    ]);
    expect(
      bodies,
      everyElement(<String, dynamic>{
        'p_reprise_id': 'reprise-1',
        'p_approuver': true,
        'p_cle': 'cle-idempotence',
      }),
    );
  });

  test('refuse une réponse de liste mal formée', () async {
    response = <Object?>[
      <String, Object?>{
        'id': 'reprise-1',
        'demandeur_prenom': 'Sana',
        'demandeur_nom': 'A',
        'foyer_nom': 'Foyer A',
        'statut': 'statut-inconnu',
        'decidable': true,
      },
    ];
    await expectLater(
      ReprisesAdminSupabase(client).lister(),
      throwsFormatException,
    );
  });

  test(
    'ne transforme pas une erreur d’autorisation en résultat de réseau',
    () async {
      statusCode = HttpStatus.forbidden;
      response = <String, Object?>{
        'code': '42501',
        'message': 'administrateur requis',
        'details': null,
        'hint': null,
      };
      await expectLater(
        ReprisesAdminSupabase(client).decider(
          repriseId: 'reprise-1',
          approuver: false,
          cle: 'cle-idempotence',
        ),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
}
