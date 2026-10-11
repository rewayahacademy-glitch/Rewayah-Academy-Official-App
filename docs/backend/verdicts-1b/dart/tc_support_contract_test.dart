import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/capacites/support_supabase.dart';
import 'package:rewayah_academy/core/tc_parcours/feedback_supabase.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/signalement_supabase.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Formes deduites des corps pg_get_functiondef de canon-fixes ea1a0da9
// (canal_support, question_feedback_pour, tendance_feedback_comprehension,
// deposer_student_concern, mes_student_concerns).
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
        final Object? d = jsonDecode(raw);
        if (d is Map<String, dynamic>) envoyes.add(d);
      }
      r.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(body is String ? body : jsonEncode(body));
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

  group('support', () {
    test('canal courriel', () async {
      body = <Object?>[
        <String, Object?>{'nature': 'courriel', 'adresse': 'aide@example.test'},
      ];
      final CanalSupport? c = await SupportSupabase(client).canal();
      expect(paths.single, '/rest/v1/rpc/canal_support');
      expect(c!.nature, NatureCanalSupport.courriel);
      expect(c.adresse, 'aide@example.test');
    });
    test('aucun canal : null', () async {
      body = <Object?>[];
      expect(await SupportSupabase(client).canal(), isNull);
    });
    test('nature inconnue : FormatException', () async {
      body = <Object?>[
        <String, Object?>{'nature': 'telephone', 'adresse': '0102'},
      ];
      await expectLater(
        SupportSupabase(client).canal(),
        throwsFormatException,
      );
    });
  });

  group('feedback', () {
    test('question absente : null', () async {
      body = null;
      expect(await FeedbackSupabase(client).questionPour('s'), isNull);
    });
    test('question complete', () async {
      body = <String, Object?>{
        'id': 'q1',
        'intitule': 'Avez-vous compris ?',
        'libelles': <String, Object?>{
          'difficile': 'Difficile',
          'bien': 'Bien',
          'tres_bien': 'Tres bien',
        },
      };
      final QuestionFeedback? q = await FeedbackSupabase(client).questionPour('s');
      expect(q!.id, 'q1');
      expect(q.libelles.length, ReponseFeedback.values.length);
    });
    test('tendance sous le seuil : rien expose', () async {
      body = <String, Object?>{
        'groupe_id': 'g',
        'nombre_echantillons': 2,
        'seuil_minimum': 5,
        'visible_par_enseignant': false,
        'repartition': null,
      };
      final TendanceFeedback t =
          await FeedbackSupabase(client).tendance(groupeId: 'g');
      expect(t.visibleParEnseignant, isFalse);
      expect(t.repartition, isNull);
    });
    test('tendance visible : ratios decimaux acceptes', () async {
      body = <String, Object?>{
        'groupe_id': 'g',
        'nombre_echantillons': 6,
        'seuil_minimum': 5,
        'visible_par_enseignant': true,
        'repartition': <String, Object?>{
          'difficile': 0.3333333333,
          'bien': 0.5,
          'tres_bien': 0.1666666667,
        },
      };
      final TendanceFeedback t =
          await FeedbackSupabase(client).tendance(groupeId: 'g');
      expect(t.repartition![ReponseFeedback.bien], 0.5);
    });
    test('doublon 23505 : dejaDepose', () async {
      status = HttpStatus.conflict;
      body = '{"code":"23505","message":"doublon"}';
      await expectLater(
        FeedbackSupabase(client).soumettre(
          sessionId: 's',
          questionId: 'q',
          reponse: ReponseFeedback.bien,
        ),
        throwsA(
          isA<EchecFeedback>().having(
            (EchecFeedback e) => e.motif,
            'motif',
            MotifEchecFeedback.dejaDepose,
          ),
        ),
      );
    });
  });

  group('signalement', () {
    Map<String, Object?> ligne() => <String, Object?>{
      'id': 'c1',
      'categorie': 'pedagogique',
      'groupe_id': 'g1',
      'session_id': null,
      'academy_id': 'EL-001',
      'enseignant_id': 't1',
      'internal_details': 'details',
      'family_summary': null,
      'statut': 'ouvert',
      'cree_le': '2026-10-11T21:00:00+00:00',
      'transmis_le': null,
      'transmis_a': null,
    };
    test('mes signalements : liste de jsonb', () async {
      body = <Object?>[ligne()];
      final List<StudentConcern> l =
          await SignalementSupabase(client).mesSignalements();
      expect(paths.single, '/rest/v1/rpc/mes_student_concerns');
      expect(l.single.categorie, CategorieSignalement.pedagogique);
      expect(l.single.creeLeUtc.isUtc, isTrue);
    });
    test('statut inconnu : FormatException', () async {
      body = <Object?>[ligne()..['statut'] = 'zzz'];
      await expectLater(
        SignalementSupabase(client).mesSignalements(),
        throwsFormatException,
      );
    });
    test('transmettre : envoie la cible SQL', () async {
      body = null;
      await SignalementSupabase(client).transmettre(
        concernId: 'c1',
        cible: CibleTransmission.tuteurDuMineur,
      );
      expect(envoyes.single['p_cible'], 'tuteur_du_mineur');
      expect(envoyes.single['p_concern_id'], 'c1');
    });
  });
}
