// PERSONNES-UNE-PAGE, etape (d) : la file des pieces avec la reference du
// dossier de candidature (`dossiers_en_attente_references`), et son repli
// silencieux sur `dossiers_en_attente` quand la fonction n'est pas au serveur.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _ligne({String? reference}) => <String, Object?>{
  'profile_id': 'p-1',
  'immutable_id': 'RA-26-7711',
  'first_name': 'Hind',
  'last_name': 'Essai',
  'role': 'teacher',
  'account_status': 'pending_kyc',
  'inscrit_le': '2026-11-10T09:00:00Z',
  'document_id': 'doc-1',
  'doc_type': 'passport',
  'document_gender': 'female',
  'object_key': 'cle',
  'depose_le': '2026-11-11T09:00:00Z',
  'etat_piece': 'a_verifier',
  'candidature_id': ?(reference == null ? null : 'c-1'),
  'candidature_reference': ?reference,
};

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<String> chemins = <String>[];
  bool nouvelleAbsente = false;

  setUp(() async {
    chemins.clear();
    nouvelleAbsente = false;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest requete) async {
      chemins.add(requete.uri.path);
      await utf8.decoder.bind(requete).join();
      final bool nouvelle = requete.uri.path.endsWith(
        'dossiers_en_attente_references',
      );
      if (nouvelle && nouvelleAbsente) {
        requete.response
          ..statusCode = HttpStatus.notFound
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, Object?>{
              'code': 'PGRST202',
              'message': 'Could not find the function',
            }),
          );
      } else {
        requete.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<Object?>[
              _ligne(reference: nouvelle ? 'CAND-00009' : null),
            ]),
          );
      }
      await requete.response.close();
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
    'lit la reference et l\'identifiant de la candidature du compte',
    () async {
      final List<DossierAValider> lus = await ServiceValidationSupabase(client)
          .enAttenteAvecReferences();
      expect(chemins, <String>['/rest/v1/rpc/dossiers_en_attente_references']);
      expect(lus.single.candidatureReference, 'CAND-00009');
      expect(lus.single.candidatureId, 'c-1');
      expect(lus.single.libelle, 'Hind Essai');
    },
  );

  test('fonction absente du serveur : repli silencieux sur la file simple, '
      'sans reference', () async {
    nouvelleAbsente = true;
    final List<DossierAValider> lus = await ServiceValidationSupabase(client)
        .enAttenteAvecReferences();
    expect(chemins, <String>[
      '/rest/v1/rpc/dossiers_en_attente_references',
      '/rest/v1/rpc/dossiers_en_attente',
    ]);
    expect(lus.single.candidatureReference, isNull);
    expect(lus.single.profilId, 'p-1');
  });

  test('l\'ancienne lecture ne rend pas de reference', () async {
    final List<DossierAValider> lus = await ServiceValidationSupabase(client)
        .enAttente();
    expect(lus.single.candidatureReference, isNull);
  });
}
