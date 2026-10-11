import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_titulaire_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ProfilEleveTitulaireSupabase', () {
    test(
      'lit uniquement la RPC sans identifiant fourni par le client',
      () async {
        Uri? requete;
        final SupabaseClient client = SupabaseClient(
          'http://localhost:54321',
          'cle-publique-test',
          httpClient: MockClient((http.Request request) async {
            requete = request.url;
            return http.Response(
              'true',
              200,
              headers: <String, String>{'content-type': 'application/json'},
              request: request,
            );
          }),
        );

        try {
          expect(await ProfilEleveTitulaireSupabase(client).existe(), isTrue);
          expect(requete?.path, '/rest/v1/rpc/profil_eleve_titulaire_existe');
        } finally {
          await client.dispose();
        }
      },
    );

    test(
      'la création appelle sa RPC dédiée et laisse remonter les erreurs',
      () async {
        Uri? requete;
        final SupabaseClient client = SupabaseClient(
          'http://localhost:54321',
          'cle-publique-test',
          httpClient: MockClient((http.Request request) async {
            requete = request.url;
            return http.Response(
              '"00000000-0000-0000-0000-000000000001"',
              200,
              headers: <String, String>{'content-type': 'application/json'},
              request: request,
            );
          }),
        );

        try {
          await ProfilEleveTitulaireSupabase(client).creer();
          expect(requete?.path, '/rest/v1/rpc/creer_profil_eleve_titulaire');
        } finally {
          await client.dispose();
        }

        final SupabaseClient refus = SupabaseClient(
          'http://localhost:54321',
          'cle-publique-test',
          httpClient: MockClient(
            (http.Request request) async => http.Response(
              '{"message":"denied","code":"42501"}',
              403,
              headers: <String, String>{'content-type': 'application/json'},
              request: request,
            ),
          ),
        );

        try {
          await expectLater(
            ProfilEleveTitulaireSupabase(refus).creer(),
            throwsA(isA<PostgrestException>()),
          );
        } finally {
          await refus.dispose();
        }
      },
    );

    test('refuse une réponse de lecture d’un type inattendu', () async {
      final SupabaseClient client = SupabaseClient(
        'http://localhost:54321',
        'cle-publique-test',
        httpClient: MockClient(
          (http.Request request) async => http.Response(
            'null',
            200,
            headers: <String, String>{'content-type': 'application/json'},
            request: request,
          ),
        ),
      );

      try {
        await expectLater(
          ProfilEleveTitulaireSupabase(client).existe(),
          throwsFormatException,
        );
      } finally {
        await client.dispose();
      }
    });
  });
}
