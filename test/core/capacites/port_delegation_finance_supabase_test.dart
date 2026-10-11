import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late List<Map<String, dynamic>> requests;

  setUp(() async {
    requests = <Map<String, dynamic>>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final String body = await utf8.decoder.bind(request).join();
      requests.add(<String, dynamic>{
        'path': request.uri.path,
        'body': body.isEmpty ? <String, dynamic>{} : jsonDecode(body),
      });
      final bool emptyList =
          request.uri.path.endsWith('/journal_delegation_finance') ||
          request.uri.path.endsWith('/sorties_en_attente_delegation_finance');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          emptyList
              ? '[]'
              : jsonEncode(<String, Object?>{
                  'version': '2',
                  'paiements_standards_autorises': false,
                  'plafond_par_transaction': null,
                  'plafond_par_lot': null,
                  'plafond_par_periode': null,
                  'remboursement_standard_autorise': false,
                  'alimentation_reserve_autorisee': false,
                  'retrait_reserve_interdit': true,
                  'premier_paiement_seconde_validation': true,
                  'coordonnees_recentes_seconde_validation': true,
                  'auto_payout_interdit': true,
                  'montant_manuel_interdit': true,
                  'politique_tarifaire_interdite': true,
                  'etat': 'suspendue',
                  'exceptions': <Object>[],
                }),
        );
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
    'renewal uses idempotency key and retains the suspended state',
    () async {
      final DelegationFinanceSupabase adapter = DelegationFinanceSupabase(
        client,
      );
      final PolitiqueDelegationFinance policy = await adapter.renouveler(
        cleIdempotence: 'df100000-0000-0000-0000-000000000001',
      );

      expect(
        requests.single['body']['p_cle'],
        'df100000-0000-0000-0000-000000000001',
      );
      expect(policy.etat, EtatDelegation.suspendue);
    },
  );

  test('dispatches control commands to their matching server RPCs', () async {
    final DelegationFinanceSupabase adapter = DelegationFinanceSupabase(client);
    await adapter.suspendreToutes(
      cleIdempotence: 'df100000-0000-0000-0000-000000000011',
    );
    await adapter.reactiver(
      cleIdempotence: 'df100000-0000-0000-0000-000000000012',
      raison: 'Reprise approuvée',
    );
    await adapter.renouveler(
      cleIdempotence: 'df100000-0000-0000-0000-000000000013',
    );
    expect(await adapter.sortiesEnAttente(), isEmpty);
    await adapter.annulerSortie(
      sortieId: 'df100000-0000-0000-0000-000000000014',
      cleIdempotence: 'df100000-0000-0000-0000-000000000015',
    );

    expect(
      requests.map((Map<String, dynamic> request) => request['path']),
      <String>[
        '/rest/v1/rpc/suspendre_toutes_delegations_finance',
        '/rest/v1/rpc/reactiver_delegation_finance',
        '/rest/v1/rpc/renouveler_delegation_finance',
        '/rest/v1/rpc/sorties_en_attente_delegation_finance',
        '/rest/v1/rpc/annuler_sortie_delegation_finance',
      ],
    );
    expect(requests[1]['body'], <String, dynamic>{
      'p_cle': 'df100000-0000-0000-0000-000000000012',
      'p_raison': 'Reprise approuvée',
    });
    expect(requests[4]['body'], <String, dynamic>{
      'p_sortie_id': 'df100000-0000-0000-0000-000000000014',
      'p_cle': 'df100000-0000-0000-0000-000000000015',
    });
  });
}
