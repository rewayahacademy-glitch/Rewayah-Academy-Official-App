// Sens du tri des requetes PostgREST du lot A (03_DECISIONS §1 ter bis.2 :
// `.order(...)` sans `ascending` trie DECROISSANT cote PostgREST). Chaque
// service est branche sur un vrai SupabaseClient pointe vers un serveur HTTP
// local qui enregistre la requete emise : on verifie le parametre `order`
// reellement envoye, pas une intention de code.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  final List<Uri> requetes = <Uri>[];

  setUp(() async {
    requetes.clear();
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      requetes.add(requete.uri);
      requete.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<Object>[]));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${serveur.address.host}:${serveur.port}',
      'cle-de-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  String ordreDe(String table) => requetes
      .singleWhere((Uri u) => u.path.endsWith('/$table'))
      .queryParameters['order']!;

  // Admission, lot B (29/10/2026) : les langues de cours se lisent par
  // `langues_cours_publiques()`, lisible sans compte, qui trie elle-meme par
  // `ordre` croissant (prouve par scenarios_langues_cours_publiques.sql).
  test(
    'langues_cours se lit par la fonction publique, triee par le serveur',
    () async {
      await ServiceOffresSupabase(client).langues();
      expect(requetes.single.path, endsWith('/rpc/langues_cours_publiques'));
      expect(requetes.single.queryParameters.containsKey('order'), isFalse);
    },
  );

  test('cohortes_age est trie par ordre CROISSANT', () async {
    await ServiceOffresSupabase(client).cohortes();
    expect(ordreDe('cohortes_age'), startsWith('ordre.asc'));
  });

  test(
    'contract_acceptances va de la plus recente a la plus ancienne',
    () async {
      await ServiceAcceptationsSupabase(client).acceptations('p1');
      expect(ordreDe('contract_acceptances'), startsWith('accepted_at.desc'));
    },
  );
}
