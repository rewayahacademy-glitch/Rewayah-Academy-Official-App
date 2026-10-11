import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance.dart';
import 'package:rewayah_academy/core/capacites/port_delegation_finance_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late Map<String, dynamic> requestBody;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      requestBody = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, Object?>{
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

      expect(requestBody['p_cle'], 'df100000-0000-0000-0000-000000000001');
      expect(policy.etat, EtatDelegation.suspendue);
    },
  );
}
