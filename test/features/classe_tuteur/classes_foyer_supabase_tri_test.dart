// Tri PostgREST de l'adaptateur des classes du foyer (revue C m6 ; `03`
// section 1 ter bis-2) : PostgREST trie en DECROISSANT quand l'appel n'ecrit
// rien. Le test fait parler le VRAI client Supabase a un serveur HTTP local
// (aucune dependance ajoutee, aucun service reel) et lit le sens envoye.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/classes_foyer_supabase.dart';
import 'package:rewayah_academy/core/tc_groupe/groupes_supabase.dart';
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
      // Une appartenance ouverte, puis aucune classe dans la vue : seul
      // l'ordre demande compte ici.
      final Object corps = requete.uri.path.endsWith('/groupe_membres')
          ? <Map<String, String>>[
              <String, String>{'groupe_id': 'classe-a'},
            ]
          : const <Object>[];
      requete.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(corps));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${serveur.address.address}:${serveur.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  test('les appartenances arrivent de la plus ancienne a la plus recente, '
      'les classes par libelle croissant', () async {
    await ClassesFoyerSupabase(client).classesDe('foyer-a-eleve-1');

    expect(requetes, hasLength(2));
    final Uri appartenances = requetes[0];
    expect(appartenances.path, endsWith('/groupe_membres'));
    expect(appartenances.queryParameters['order'], 'joined_at.asc.nullslast');
    expect(appartenances.queryParameters['student_id'], 'eq.foyer-a-eleve-1');
    expect(appartenances.queryParameters['left_at'], 'is.null');

    final Uri classes = requetes[1];
    expect(classes.path, endsWith('/$vueMesGroupesFamille'));
    expect(classes.queryParameters['order'], 'libelle.asc.nullslast');
  });

  test('aucune appartenance : une seule lecture, aucune classe', () async {
    await serveur.close(force: true);
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      requetes.add(requete.uri);
      requete.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('[]');
      await requete.response.close();
    });
    await client.dispose();
    client = SupabaseClient(
      'http://${serveur.address.address}:${serveur.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    expect(await ClassesFoyerSupabase(client).classesDe('e'), isEmpty);
    expect(requetes, hasLength(1));
    expect(requetes.single.queryParameters['order'], 'joined_at.asc.nullslast');
  });
}
