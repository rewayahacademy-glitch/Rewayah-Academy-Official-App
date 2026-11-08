// RECHERCHE-LIVRAISON, D2 : l'adaptateur de `rechercher_personne_par_matricule`
// (RECH-BACK-3), sur un faux serveur HTTP local. Ce que le serveur rend decide ;
// l'adaptateur ne devine rien : un eleve, ou le meme vide ; une panne leve.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/resolution_ra_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  final List<Uri> adresses = <Uri>[];
  final List<Map<String, dynamic>> corps = <Map<String, dynamic>>[];
  int statut = 200;
  Object? reponse = <Object>[];

  setUp(() async {
    adresses.clear();
    corps.clear();
    statut = 200;
    reponse = <Object>[];
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      adresses.add(requete.uri);
      corps.add(
        jsonDecode(await utf8.decoder.bind(requete.cast<List<int>>()).join())
            as Map<String, dynamic>,
      );
      requete.response
        ..statusCode = statut
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reponse));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${serveur.address.address}:${serveur.port}',
      'cle-factice',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  Map<String, dynamic> ligne(String role) => <String, dynamic>{
    'profile_id': 'p-1',
    'matricule': 'RA-26-4817',
    'first_name': 'Yanis',
    'last_name': 'Fixture',
    'role': role,
  };

  test(
    'appelle seulement la RPC, avec la saisie canonique, rien d\'autre',
    () async {
      await ResolutionRaSupabase(client).resoudre('RA-26-4817');
      expect(
        adresses.single.path,
        endsWith('/rpc/rechercher_personne_par_matricule'),
      );
      expect(corps.single, <String, dynamic>{'p_saisie': 'RA-26-4817'});
    },
  );

  test(
    'un eleve : son identifiant et son prenom, jamais le nom ni la classe',
    () async {
      reponse = <Object>[ligne('student')];
      final ElevePourRa? e = await ResolutionRaSupabase(client)
          .resoudre('RA-26-4817');
      expect(e, isNotNull);
      expect(e!.eleveId, 'p-1');
      expect(e.prenom, 'Yanis');
      expect(e.classe, isNull);
    },
  );

  test(
    'une personne d\'un autre role n\'est pas resolue : le meme vide',
    () async {
      for (final String role in <String>[
        'teacher',
        'guardian',
        'admin',
        'controller',
      ]) {
        reponse = <Object>[ligne(role)];
        expect(
          await ResolutionRaSupabase(client).resoudre('RA-26-4817'),
          isNull,
          reason: role,
        );
      }
    },
  );

  test(
    'aucune ligne (inconnu, hors perimetre, quota) : null, le meme vide',
    () async {
      reponse = <Object>[];
      expect(await ResolutionRaSupabase(client).resoudre('RA-26-4817'), isNull);
    },
  );

  test('une panne du serveur leve, jamais null', () async {
    statut = 500;
    reponse = <String, dynamic>{'message': 'erreur'};
    await expectLater(
      ResolutionRaSupabase(client).resoudre('RA-26-4817'),
      throwsA(isA<Object>()),
    );
  });

  test('une reponse illisible leve (FormatException), jamais null', () {
    expect(
      () => elevePourRaDepuisReponse('pas une liste'),
      throwsFormatException,
    );
    expect(() => elevePourRaDepuisReponse(<Object>[3]), throwsFormatException);
    expect(
      () => elevePourRaDepuisReponse(<Object>[
        <String, dynamic>{'role': 'student'},
      ]),
      throwsFormatException,
    );
    expect(elevePourRaDepuisReponse(null), isNull);
  });
}
