import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/suivi/groupes_seances.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'ne charge que les séances terminées dans la fenêtre historique',
    () async {
      Uri? requete;
      final SupabaseClient client = SupabaseClient(
        'http://localhost:54321',
        'cle-publique-test',
        httpClient: MockClient((http.Request request) async {
          requete = request.url;
          return http.Response(
            jsonEncode(<Map<String, String>>[
              <String, String>{'id': 's-1', 'groupe_id': 'g-1'},
            ]),
            200,
            headers: <String, String>{'content-type': 'application/json'},
            request: request,
          );
        }),
      );

      try {
        final ServiceGroupesSeances service = ServiceGroupesSeancesSupabase(
          () => client,
        );
        expect(await service.groupesDesSeances(), <String, String>{
          's-1': 'g-1',
        });

        expect(
          requete?.queryParameters['status'],
          'in.("ended","student_absent","tech_failure")',
        );
      } finally {
        await client.dispose();
      }
    },
  );
}
