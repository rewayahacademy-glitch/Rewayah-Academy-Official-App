import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/capacites/progression_famille_supabase.dart';
import 'package:rewayah_academy/core/capacites/resume_seance_famille_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  Object? reponse;
  int statutHttp = HttpStatus.ok;
  Map<String, dynamic>? corpsRequete;

  setUp(() async {
    reponse = <String, Object?>{
      'niveau_humain': 'Lecture lente',
      'jalons': <String>['Lecture lente'],
      'seances': <Object?>[],
    };
    statutHttp = HttpStatus.ok;
    corpsRequete = null;
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      corpsRequete = jsonDecode(
        await utf8.decoder.bind(requete).join(),
      ) as Map<String, dynamic>;
      requete.response
        ..statusCode = statutHttp
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reponse));
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

  group('ProgressionFamilleSupabase', () {
    test('transmet la limite et décode les textes', () async {
      final ProgressionEleve progression = await ProgressionFamilleSupabase(
        client,
      ).progression('eleve-1');

      expect(corpsRequete, <String, dynamic>{
        'p_student_id': 'eleve-1',
        'p_limit': 20,
      });
      expect(progression.niveauHumain, 'Lecture lente');
      expect(progression.jalons, <String>['Lecture lente']);
    });

    test(
      'refuse une réponse nulle ou de forme invalide en FormatException',
      () async {
        reponse = null;
        await expectLater(
          ProgressionFamilleSupabase(client).progression('eleve-1'),
          throwsFormatException,
        );

        reponse = <Object?>[];
        await expectLater(
          ProgressionFamilleSupabase(client).progression('eleve-1'),
          throwsFormatException,
        );
      },
    );

    test('refuse un jalon qui n’est pas une chaîne', () async {
      reponse = <String, Object?>{
        'niveau_humain': null,
        'jalons': <Object?>['Valide', 42],
        'seances': <Object?>[],
      };

      await expectLater(
        ProgressionFamilleSupabase(client).progression('eleve-1'),
        throwsFormatException,
      );
    });

    test('propage un refus RPC sans le transformer en progression vide', () async {
      statutHttp = HttpStatus.forbidden;
      reponse = <String, Object?>{
        'code': '42501',
        'message': 'permission denied',
        'details': null,
        'hint': null,
      };

      await expectLater(
        ProgressionFamilleSupabase(client).progression('eleve-1'),
        throwsA(
          isA<PostgrestException>().having(
            (PostgrestException error) => error.code,
            'code',
            '42501',
          ),
        ),
      );
    });
  });

  group('ResumeSeanceFamilleSupabase', () {
    test('accepte null et un résumé textuel', () async {
      final ResumeSeanceFamilleSupabase port = ResumeSeanceFamilleSupabase(
        client,
      );
      reponse = null;
      expect(
        await port.resume(seanceId: 'seance-1', eleveId: 'eleve-1'),
        isNull,
      );
      reponse = 'Lecture régulière.';
      expect(
        await port.resume(seanceId: 'seance-1', eleveId: 'eleve-1'),
        'Lecture régulière.',
      );
    });

    test('refuse un type RPC inattendu en FormatException', () async {
      reponse = 12;
      await expectLater(
        ResumeSeanceFamilleSupabase(client)
            .resume(seanceId: 'seance-1', eleveId: 'eleve-1'),
        throwsFormatException,
      );
    });

    test('propage une erreur RPC de résumé sans produire un résumé vide', () async {
      statutHttp = HttpStatus.internalServerError;
      reponse = <String, Object?>{
        'code': 'XX000',
        'message': 'summary projection unavailable',
        'details': null,
        'hint': null,
      };

      await expectLater(
        ResumeSeanceFamilleSupabase(client)
            .resume(seanceId: 'seance-1', eleveId: 'eleve-1'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
