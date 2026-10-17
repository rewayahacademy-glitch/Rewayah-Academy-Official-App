import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/offres_admin_supabase.dart';
import 'package:rewayah_academy/core/offres/port_offres_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Les requetes que l'adaptateur emet, avec la reponse fournie par le test.
class _Trace {
  final List<http.Request> requetes = <http.Request>[];
  http.Response Function(http.Request) repondre = (http.Request _) =>
      http.Response('[]', 200, headers: _json);

  static const Map<String, String> _json = <String, String>{
    'content-type': 'application/json',
  };

  SupabaseClient client() => SupabaseClient(
    'https://exemple.supabase.co',
    'cle-anonyme',
    httpClient: MockClient((http.Request r) async {
      requetes.add(r);
      final http.Response h = repondre(r);
      return http.Response(
        h.body,
        h.statusCode,
        headers: h.headers,
        request: r,
      );
    }),
  );
}

http.Response _erreur(String message, {String code = 'P0001'}) => http.Response(
  jsonEncode(<String, String>{'code': code, 'message': message}),
  400,
  headers: _Trace._json,
);

void main() {
  test(
    'lister lit offres_horaires et trie : publiees, brouillons, retirees',
    () async {
      final _Trace trace = _Trace();
      trace.repondre = (http.Request _) => http.Response(
        jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'id': 'r',
            'type_public': 'enfant',
            'langue_code': 'poular',
            'fuseau_iana': 'Europe/Paris',
            'jours': <int>[5, 1, 3],
            'heure_locale': 9,
            'duree_minutes': 60,
            'etat': 'retiree',
            'retrait_motif': 'Doublon',
            'langues_cours': <String, String>{'nom_humain': 'Poular'},
          },
          <String, Object?>{
            'id': 'b',
            'type_public': 'adulte',
            'langue_code': 'francais',
            'fuseau_iana': 'Europe/Paris',
            'jours': <int>[2, 4, 6],
            'heure_locale': 20,
            'duree_minutes': 90,
            'etat': 'brouillon',
            'retrait_motif': null,
            'langues_cours': <String, String>{'nom_humain': 'Français'},
          },
          <String, Object?>{
            'id': 'p',
            'type_public': 'enfant',
            'langue_code': 'francais',
            'fuseau_iana': 'Europe/Paris',
            'jours': <int>[1, 3, 5],
            'heure_locale': 18,
            'duree_minutes': 60,
            'etat': 'publiee',
            'retrait_motif': null,
            'langues_cours': <String, String>{'nom_humain': 'Français'},
          },
        ]),
        200,
        headers: _Trace._json,
      );
      final List<OffreAdmin> offres = await OffresAdminSupabase(trace.client())
          .lister();

      expect(offres.map((OffreAdmin o) => o.id), <String>['p', 'b', 'r']);
      expect(offres.last.jours, <int>[1, 3, 5]);
      expect(offres.last.motifRetrait, 'Doublon');
      expect(offres.first.public, PublicOffre.enfants);
      expect(offres[1].public, PublicOffre.adultes);
      expect(offres.first.langueNom, 'Français');
      final http.Request r = trace.requetes.single;
      expect(r.method, 'GET');
      expect(r.url.path, '/rest/v1/offres_horaires');
      expect(r.url.queryParameters['select'], contains('retrait_motif'));
    },
  );

  test('creer appelle creer_offre_horaire avec les parametres p_*', () async {
    final _Trace trace = _Trace();
    trace.repondre = (http.Request _) =>
        http.Response('"offre-uuid"', 200, headers: _Trace._json);
    final String id = await OffresAdminSupabase(trace.client()).creer(
      typePublic: 'adulte',
      langueCode: 'francais',
      fuseauIana: 'Europe/Paris',
      jours: const <int>[1, 3, 5],
      heureLocale: 18,
      dureeMinutes: 90,
    );

    expect(id, 'offre-uuid');
    final http.Request r = trace.requetes.single;
    expect(r.url.path, '/rest/v1/rpc/creer_offre_horaire');
    expect(jsonDecode(r.body), <String, Object?>{
      'p_type_public': 'adulte',
      'p_langue_code': 'francais',
      'p_fuseau_iana': 'Europe/Paris',
      'p_jours': <int>[1, 3, 5],
      'p_heure_locale': 18,
      'p_duree_minutes': 90,
    });
  });

  test(
    'creer sans duree ne l envoie pas : le serveur applique la sienne',
    () async {
      final _Trace trace = _Trace();
      trace.repondre = (http.Request _) =>
          http.Response('"x"', 200, headers: _Trace._json);
      await OffresAdminSupabase(trace.client()).creer(
        typePublic: 'enfant',
        langueCode: 'poular',
        fuseauIana: 'Africa/Conakry',
        jours: const <int>[2, 4, 6],
        heureLocale: 10,
      );
      expect(
        (jsonDecode(trace.requetes.single.body) as Map<String, dynamic>)
            .containsKey('p_duree_minutes'),
        isFalse,
      );
    },
  );

  test('publier et retirer appellent leurs RPC', () async {
    final _Trace trace = _Trace();
    trace.repondre = (http.Request _) =>
        http.Response('', 204, headers: _Trace._json);
    final OffresAdminSupabase port = OffresAdminSupabase(trace.client());
    await port.publier('o-1');
    await port.retirer('o-2', motif: 'Doublon');

    expect(trace.requetes[0].url.path, '/rest/v1/rpc/publier_offre_horaire');
    expect(jsonDecode(trace.requetes[0].body), <String, Object?>{
      'p_offre_id': 'o-1',
    });
    expect(trace.requetes[1].url.path, '/rest/v1/rpc/retirer_offre_horaire');
    expect(jsonDecode(trace.requetes[1].body), <String, Object?>{
      'p_offre_id': 'o-2',
      'p_motif': 'Doublon',
    });
  });

  test('les refus du serveur deviennent des phrases lisibles', () async {
    final _Trace trace = _Trace();
    final OffresAdminSupabase port = OffresAdminSupabase(trace.client());

    trace.repondre = (http.Request _) =>
        _erreur('offre introuvable ou deja publiee');
    await expectLater(
      port.publier('o'),
      throwsA(
        isA<OffreAdminRefusee>().having(
          (OffreAdminRefusee e) => e.message,
          'message',
          'Cette offre est déjà publiée.',
        ),
      ),
    );

    trace.repondre = (http.Request _) =>
        _erreur("l'academie annonce 3 seances par semaine, 1 jours fournis");
    await expectLater(
      port.creer(
        typePublic: 'enfant',
        langueCode: 'francais',
        fuseauIana: 'Europe/Paris',
        jours: const <int>[1],
        heureLocale: 18,
      ),
      throwsA(isA<OffreAdminRefusee>()),
    );

    trace.repondre = (http.Request _) => _erreur(
      'duplicate key value violates unique constraint "offres_horaires_motif_unique"',
      code: '23505',
    );
    await expectLater(
      port.creer(
        typePublic: 'enfant',
        langueCode: 'francais',
        fuseauIana: 'Europe/Paris',
        jours: const <int>[1, 3, 5],
        heureLocale: 18,
      ),
      throwsA(
        isA<OffreAdminRefusee>().having(
          (OffreAdminRefusee e) => e.message,
          'message',
          'Une offre identique existe déjà.',
        ),
      ),
    );
  });

  test('un message de refus inconnu est rendu tel quel', () {
    expect(
      messageLisible(const PostgrestException(message: 'autre chose')),
      'autre chose',
    );
  });
}
