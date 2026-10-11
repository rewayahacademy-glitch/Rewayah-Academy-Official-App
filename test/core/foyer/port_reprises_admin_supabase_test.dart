import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/port_reprises_admin.dart';
import 'package:rewayah_academy/core/foyer/port_reprises_admin_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<({String path, String body})> calls =
      <({String path, String body})>[];
  Object response = <Object?>[];

  setUp(() async {
    calls.clear();
    response = <Object?>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final String body = await utf8.decoder.bind(request).join();
      calls.add((path: request.uri.path, body: body));
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.host}:${server.port}',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test(
    'lister mappe les lignes ouvertes et refusees sans perdre leurs dates',
    () async {
      response = <Object?>[
        <String, Object?>{
          'id': 'r1',
          'demandeur_prenom': 'Amine',
          'demandeur_nom': 'Test',
          'foyer_nom': 'Famille Test',
          'statut': 'a_examiner',
          'decidable': true,
          'deposee_le': '2026-10-11T12:30:00Z',
          'examen_possible_le': '2026-10-11T12:30:00Z',
          'redepot_possible_le': null,
        },
        <String, Object?>{
          'id': 'r2',
          'demandeur_prenom': 'Sara',
          'demandeur_nom': 'Test',
          'foyer_nom': 'Autre foyer',
          'statut': 'refusee_par_titulaire',
          'decidable': false,
          'deposee_le': null,
          'examen_possible_le': null,
          'redepot_possible_le': '2026-11-10T12:30:00Z',
        },
      ];

      final List<RepriseAdmin> rows = await PortReprisesAdminSupabase(
        () => client,
      ).lister();

      expect(calls.single.path, '/rest/v1/rpc/lister_reprises_admin');
      expect(rows, hasLength(2));
      expect(rows.first.etat, EtatRepriseAdmin.aExaminer);
      expect(rows.first.deposeeLe, DateTime.utc(2026, 10, 11, 12, 30));
      expect(rows.last.etat, EtatRepriseAdmin.refuseeParTitulaire);
      expect(rows.last.decidable, isFalse);
    },
  );

  test('decider envoie la cle et traduit deja_traitee', () async {
    response = <String, Object?>{
      'statut': 'deja_traitee',
      'foyer_personnel_cree': true,
    };

    final ResultatDecisionReprise result = await PortReprisesAdminSupabase(
      () => client,
    ).decider(repriseId: 'reprise-1', approuver: true, cle: 'cle-1');

    expect(result, isA<RepriseDejaTraitee>());
    expect(calls.single.path, '/rest/v1/rpc/decider_reprise_foyer');
    expect(jsonDecode(calls.single.body), <String, Object?>{
      'p_reprise_id': 'reprise-1',
      'p_approuver': true,
      'p_cle': 'cle-1',
    });
  });

  test('decider traduit une décision enregistrée', () async {
    response = <String, Object?>{'statut': 'decidee'};

    final ResultatDecisionReprise result = await PortReprisesAdminSupabase(
      () => client,
    ).decider(repriseId: 'reprise-2', approuver: false, cle: 'cle-2');

    expect(result, isA<RepriseDecidee>());
  });

  test('decider signale une vraie coupure reseau', () async {
    await server.close(force: true);

    final ResultatDecisionReprise result = await PortReprisesAdminSupabase(
      () => client,
    ).decider(repriseId: 'reprise-3', approuver: true, cle: 'cle-3');

    expect(result, isA<RepriseDecisionEchecReseau>());
  });

  test('decider propage une erreur de contrat au lieu de la masquer', () async {
    response = <String, Object?>{'statut': 'inconnu'};

    expect(
      () =>
          PortReprisesAdminSupabase(() => client)
              .decider(repriseId: 'reprise-1', approuver: false, cle: 'cle-2'),
      throwsFormatException,
    );
  });

  test('lister refuse un statut serveur inconnu', () async {
    response = <Object?>[
      <String, Object?>{
        'id': 'r1',
        'demandeur_prenom': 'Amine',
        'demandeur_nom': 'Test',
        'foyer_nom': 'Famille Test',
        'statut': 'autre',
        'decidable': false,
      },
    ];

    expect(
      () => PortReprisesAdminSupabase(() => client).lister(),
      throwsFormatException,
    );
  });
}
