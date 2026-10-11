import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/progression_famille_supabase.dart';
import 'package:rewayah_academy/core/capacites/resume_seance_famille_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sortie reelle de public.progression_famille / resume_seance_famille
// (PG16, canon-fixes ea1a0da9, fixture scenarios_b08).
const String _reel =
    '{"jalons": ["Lecture lente"], "seances": [{"publie_le": '
    '"2026-10-11T21:24:32.7385+00:00", "session_id": '
    '"b0800000-0000-0000-0000-000000000301", "jalon_humain": "Lecture lente", '
    '"texte_famille": "Lecture régulière; revoir les liaisons."}], '
    '"jalon_humain": "Lecture lente", "niveau_humain": null}';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  Object? body;
  int status = HttpStatus.ok;
  final List<String> paths = <String>[];
  final List<Map<String, dynamic>> envoyes = <Map<String, dynamic>>[];

  setUp(() async {
    status = HttpStatus.ok;
    paths.clear();
    envoyes.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest r) async {
      paths.add(r.uri.path);
      final String raw = await utf8.decoder.bind(r).join();
      if (raw.isNotEmpty) {
        envoyes.add(jsonDecode(raw) as Map<String, dynamic>);
      }
      r.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(body is String && status != HttpStatus.ok
            ? body
            : jsonEncode(body));
      await r.response.close();
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

  group('progression_famille', () {
    test('lit la sortie reelle du serveur (niveau null, un jalon)', () async {
      body = jsonDecode(_reel);
      final p = await ProgressionFamilleSupabase(client).progression('eleve-1');
      expect(paths.single, '/rest/v1/rpc/progression_famille');
      expect(envoyes.single['p_student_id'], 'eleve-1');
      expect(p.eleveId, 'eleve-1');
      expect(p.niveauHumain, isNull);
      expect(p.jalons, <String>['Lecture lente']);
    });

    test('niveau humain texte', () async {
      body = <String, Object?>{'niveau_humain': 'Lecture lente', 'jalons': <Object?>[]};
      final p = await ProgressionFamilleSupabase(client).progression('e');
      expect(p.niveauHumain, 'Lecture lente');
      expect(p.jalons, isEmpty);
    });

    test('jalons non textuels : FormatException (pas TypeError)', () async {
      body = <String, Object?>{'niveau_humain': null, 'jalons': <Object?>[1, 2]};
      await expectLater(
        () async => ProgressionFamilleSupabase(client).progression('e'),
        throwsFormatException,
      );
    });

    test('niveau non textuel : FormatException (pas TypeError)', () async {
      body = <String, Object?>{'niveau_humain': 7, 'jalons': <Object?>[]};
      await expectLater(
        () async => ProgressionFamilleSupabase(client).progression('e'),
        throwsFormatException,
      );
    });

    test('jalons absents : FormatException', () async {
      body = <String, Object?>{'niveau_humain': null};
      await expectLater(
        () async => ProgressionFamilleSupabase(client).progression('e'),
        throwsFormatException,
      );
    });

    test('refus serveur : PostgrestException relancee', () async {
      status = HttpStatus.badRequest;
      body = '{"code":"P0001","message":"progression indisponible"}';
      await expectLater(
        () async => ProgressionFamilleSupabase(client).progression('e'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('resume_seance_famille', () {
    test('texte publie', () async {
      body = 'Lecture régulière; revoir les liaisons.';
      final String? t = await ResumeSeanceFamilleSupabase(client)
          .resume(seanceId: 's1', eleveId: 'e1');
      expect(paths.single, '/rest/v1/rpc/resume_seance_famille');
      expect(envoyes.single, <String, dynamic>{
        'p_session_id': 's1',
        'p_student_id': 'e1',
      });
      expect(t, 'Lecture régulière; revoir les liaisons.');
    });

    test('brouillon ou retire : null', () async {
      body = null;
      final String? t = await ResumeSeanceFamilleSupabase(client)
          .resume(seanceId: 's1', eleveId: 'e1');
      expect(t, isNull);
    });

    test('reponse non textuelle : FormatException', () async {
      body = <String, Object?>{'x': 1};
      await expectLater(
        () async => ResumeSeanceFamilleSupabase(client)
            .resume(seanceId: 's1', eleveId: 'e1'),
        throwsFormatException,
      );
    });

    test('refus serveur : PostgrestException relancee', () async {
      status = HttpStatus.badRequest;
      body = '{"code":"P0001","message":"résumé indisponible"}';
      await expectLater(
        () async => ResumeSeanceFamilleSupabase(client)
            .resume(seanceId: 's1', eleveId: 'e1'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
