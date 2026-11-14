// Revue du 13/11/2026 : les deux replis « serveur d'avant le lot » des
// adaptateurs de la salle, prouves sur l'adaptateur lui-meme (faux serveur
// HTTP), pas seulement sur la lecture des reponses.
//
// - `PauseSeanceSupabase.refuser` : quand `pause_seance_refuser` n'existe pas
//   (serveur d'avant PAUSE-SERVEUR), l'adaptateur relit `pause_seance_etat`
//   et rend cet etat, sans erreur ; toute autre erreur remonte.
// - `CamaradesSalleSupabase.camarades` : quand `camarades_classe_eleve`
//   n'existe pas (serveur d'avant CAMARADES), l'adaptateur relit
//   `participants_classe_eleve_adulte` ; un refus 42501 rend une liste vide
//   sans second appel ; les deux fonctions absentes rendent une liste vide ;
//   toute autre erreur remonte.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/pause_seance/pause_seance_supabase.dart';
import 'package:rewayah_academy/core/pause_seance/port_pause_seance.dart';
import 'package:rewayah_academy/features/salle/annuaire_seance.dart'
    show CamaradeSeance;
import 'package:rewayah_academy/features/salle/camarades_salle_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreur(String code, int statut) => http.Response(
  jsonEncode(<String, dynamic>{
    'code': code,
    'message': 'erreur $code',
    'details': null,
    'hint': null,
  }),
  statut,
  headers: _json,
);

http.Response _absente() => _erreur('PGRST202', 404);

SupabaseClient _client(
  http.Response Function(String fonction) repondre,
  List<String> appels,
) => SupabaseClient(
  'https://exemple.supabase.co',
  'cle-anonyme',
  httpClient: MockClient((http.Request r) async {
    final String fonction = r.url.pathSegments.last;
    appels.add(fonction);
    final http.Response h = repondre(fonction);
    return http.Response(h.body, h.statusCode, headers: h.headers, request: r);
  }),
);

void main() {
  group('pause : le Non sur un serveur d avant PAUSE-SERVEUR', () {
    test('fonction absente : l etat ancien est relu et rendu, sans '
        'erreur', () async {
      final List<String> appels = <String>[];
      final PauseSeanceSupabase port = PauseSeanceSupabase(
        _client(
          (String f) => f == 'pause_seance_refuser'
              ? _absente()
              : _ok(<String, dynamic>{
                  'statut': 'programmee',
                  'duree_prevue_minutes': 10,
                  'debut_prevu_utc': '2026-11-12T18:45:00Z',
                  'peut_piloter': true,
                }),
          appels,
        ),
      );
      final PauseSeance etat = await port.refuser(
        seanceId: 's1',
        cleIdempotence: 'c1',
      );
      expect(appels, <String>['pause_seance_refuser', 'pause_seance_etat']);
      expect(etat.statut, StatutPause.programmee);
      // L'etat ancien ne porte aucune proposition : rien ne sera repropose.
      expect(etat.proposerAUtc, isNull);
    });

    test('une autre erreur du serveur remonte, sans relecture', () async {
      final List<String> appels = <String>[];
      final PauseSeanceSupabase port = PauseSeanceSupabase(
        _client((String f) => _erreur('42501', 403), appels),
      );
      await expectLater(
        port.refuser(seanceId: 's1', cleIdempotence: 'c1'),
        throwsA(isA<PostgrestException>()),
      );
      expect(appels, <String>['pause_seance_refuser']);
    });
  });

  group('camarades : les prenoms sur un serveur d avant CAMARADES', () {
    const List<Map<String, dynamic>> lignes = <Map<String, dynamic>>[
      <String, dynamic>{
        'profile_id': 'a',
        'prenom': 'Yasmine',
        'est_moi': false,
      },
      <String, dynamic>{'profile_id': 'b', 'prenom': 'Idriss', 'est_moi': true},
    ];

    test('serveur a jour : une seule lecture, soi-meme ecarte', () async {
      final List<String> appels = <String>[];
      final List<CamaradeSeance> lus = await CamaradesSalleSupabase(
        _client((String f) => _ok(lignes), appels),
      ).camarades();
      expect(appels, <String>[CamaradesSalleSupabase.fonction]);
      expect(lus, <CamaradeSeance>[(id: 'a', prenom: 'Yasmine')]);
    });

    test('fonction absente : repli sur la lecture de l eleve adulte', () async {
      final List<String> appels = <String>[];
      final List<CamaradeSeance> lus = await CamaradesSalleSupabase(
        _client(
          (String f) =>
              f == CamaradesSalleSupabase.fonction ? _absente() : _ok(lignes),
          appels,
        ),
      ).camarades();
      expect(appels, <String>[
        CamaradesSalleSupabase.fonction,
        CamaradesSalleSupabase.fonctionAdulte,
      ]);
      expect(lus, <CamaradeSeance>[(id: 'a', prenom: 'Yasmine')]);
    });

    test('refus du serveur (compte qui n est pas eleve) : liste vide, aucun '
        'second appel', () async {
      final List<String> appels = <String>[];
      final List<CamaradeSeance> lus = await CamaradesSalleSupabase(
        _client((String f) => _erreur('42501', 403), appels),
      ).camarades();
      expect(appels, <String>[CamaradesSalleSupabase.fonction]);
      expect(lus, isEmpty);
    });

    test('les deux fonctions absentes : liste vide, sans erreur', () async {
      final List<String> appels = <String>[];
      final List<CamaradeSeance> lus = await CamaradesSalleSupabase(
        _client((String f) => _absente(), appels),
      ).camarades();
      expect(appels, hasLength(2));
      expect(lus, isEmpty);
    });

    test('une autre erreur remonte', () async {
      final List<String> appels = <String>[];
      await expectLater(
        CamaradesSalleSupabase(
          _client((String f) => _erreur('XX000', 500), appels),
        ).camarades(),
        throwsA(isA<PostgrestException>()),
      );
      expect(appels, <String>[CamaradesSalleSupabase.fonction]);
    });
  });
}
