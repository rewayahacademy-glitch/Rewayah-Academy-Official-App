import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/port_reponse_presentation.dart';
import 'package:rewayah_academy/core/accessibilite/reponse_presentation_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? response;
  final List<String> paths = <String>[];

  setUp(() async {
    response = <Object?>[
      <String, Object?>{
        'id': 'demande-1',
        'eleve_id': 'eleve-1',
        'eleve_prenom': 'Mariam',
        'cree_le_utc': '2026-10-11T17:30:00+00:00',
        'heure_foyer': '2026-10-11T19:30:00',
        'fuseau_iana': 'Europe/Paris',
      },
    ];
    paths.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      paths.add(request.uri.path);
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = HttpStatus.ok
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

  test(
    'lit la projection UTC et le fuseau du foyer sans identifiant de foyer',
    () async {
      final List<DemandePresentation> demandes =
          await ReponsePresentationSupabase(client).enAttente();

      expect(demandes, hasLength(1));
      expect(demandes.single.id, 'demande-1');
      expect(demandes.single.demandeeLe.hour, 19);
      expect(demandes.single.instantUtc, DateTime.utc(2026, 10, 11, 17, 30));
      expect(demandes.single.fuseauIana, 'Europe/Paris');
      expect(
        paths.single,
        endsWith('/lire_demandes_presentation_en_attente_avec_fuseau'),
      );
    },
  );

  test(
    'confirme uniquement les statuts attendus des RPC de décision',
    () async {
      response = 'acceptee';
      await ReponsePresentationSupabase(client).accepter('demande-1');
      response = 'refusee';
      await ReponsePresentationSupabase(client).refuser('demande-2');
      expect(paths, <String>[
        '/rest/v1/rpc/accepter_demande_presentation',
        '/rest/v1/rpc/refuser_demande_presentation',
      ]);
    },
  );

  test('refuse une projection serveur incomplète', () async {
    response = <Object?>[
      <String, Object?>{'id': 'demande-1', 'eleve_id': 'eleve-1'},
    ];
    await expectLater(
      ReponsePresentationSupabase(client).enAttente(),
      throwsFormatException,
    );
  });
}
