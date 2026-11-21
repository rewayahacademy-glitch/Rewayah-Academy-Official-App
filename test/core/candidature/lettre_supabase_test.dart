// LETTRE-SERVEUR : l'adaptateur Supabase de la lettre aux candidats
// enseignants, sur `public.lire_lettre_candidats(p_langue text)`
// (`20261130970000_lettre_candidats.sql`). Ce que le test prouve :
// - la forme envoyee : la seule langue, sous `p_langue`, a la bonne RPC ;
// - la lettre ouverte et les refus passent tels quels a
//   `LectureLettre.depuisJson` (manques dans l'ordre du serveur) ;
// - 42501 devient `PermissionInsuffisante`, une fonction absente du serveur
//   (migration non installee) `CapaciteIndisponible`, une panne de reseau
//   `HorsLigneCandidature` (la page l'affiche hors connexion) ;
// - une reponse mal formee n'est jamais une lettre (`FormatException`).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/lettre_supabase.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/features/candidature/lettre/port_lettre.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

class _Appel {
  _Appel(this.fonction, this.corps);

  final String fonction;
  final Map<String, dynamic> corps;
}

LettreSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => LettreSupabase(
  SupabaseClient(
    'https://exemple.supabase.co',
    'cle-anonyme',
    httpClient: MockClient((http.Request r) async {
      final Object? corps = r.body.isEmpty ? null : jsonDecode(r.body);
      final _Appel a = _Appel(
        r.url.pathSegments.last,
        corps is Map<String, dynamic> ? corps : <String, dynamic>{},
      );
      appels.add(a);
      final http.Response h = repondre(a);
      return http.Response(
        h.body,
        h.statusCode,
        headers: h.headers,
        request: r,
      );
    }),
  ),
);

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, {int statut = 400}) => http.Response(
  jsonEncode(<String, String>{'code': code, 'message': 'refus'}),
  statut,
  headers: _json,
);

void main() {
  test('la lettre ouverte : la langue seule, sous p_langue', () async {
    final List<_Appel> appels = <_Appel>[];
    final LectureLettre lu = await _port(
      (_Appel _) => _ok(<String, Object>{
        'acces': true,
        'version': '2026-11-20',
        'langue': 'ar',
        'parties': <Map<String, String>>[
          <String, String>{'code': 'p1', 'titre': 'Titre un', 'corps': 'Un.'},
          <String, String>{
            'code': 'p2',
            'titre': 'Titre deux',
            'corps': 'Deux.',
          },
        ],
      }),
      appels,
    ).lire(langue: 'ar');
    expect(appels.single.fonction, fonctionLireLettre);
    expect(appels.single.corps, <String, dynamic>{'p_langue': 'ar'});
    expect(lu.acces, isTrue);
    expect(lu.langue, 'ar');
    expect(lu.version, '2026-11-20');
    expect(lu.parties.map((PartieLettre p) => p.code), <String>['p1', 'p2']);
    expect(lu.parties.last.corps, 'Deux.');
  });

  test('refus accords : les manques dans l\'ordre du serveur', () async {
    final LectureLettre lu = await _port(
      (_Appel _) => _ok(<String, Object>{
        'acces': false,
        'raison': 'accords',
        'manques': <String>['contrat', 'conduite', 'cadre'],
        'acceptable': false,
      }),
      <_Appel>[],
    ).lire(langue: 'fr');
    expect(lu.acces, isFalse);
    expect(lu.raison, RaisonRefusLettre.accords);
    expect(lu.manques, <AccordManquant>[
      AccordManquant.contrat,
      AccordManquant.conduite,
      AccordManquant.cadre,
    ]);
    expect(lu.acceptable, isFalse);
    expect(lu.parties, isEmpty);
  });

  test('refus role et compte : aucune partie', () async {
    for (final String raison in <String>['role', 'compte']) {
      final LectureLettre lu = await _port(
        (_Appel _) => _ok(<String, Object>{'acces': false, 'raison': raison}),
        <_Appel>[],
      ).lire(langue: 'en');
      expect(lu.acces, isFalse);
      expect(lu.raison?.name, raison);
      expect(lu.parties, isEmpty);
    }
  });

  test('42501 : PermissionInsuffisante', () async {
    await expectLater(
      _port(
        (_Appel _) => _erreurPg('42501', statut: 403),
        <_Appel>[],
      ).lire(langue: 'fr'),
      throwsA(isA<PermissionInsuffisante>()),
    );
  });

  test('fonction absente du serveur : CapaciteIndisponible', () async {
    for (final String code in <String>['PGRST202', '42883']) {
      await expectLater(
        _port(
          (_Appel _) => _erreurPg(code, statut: 404),
          <_Appel>[],
        ).lire(langue: 'fr'),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            dependanceLettre,
          ),
        ),
      );
    }
  });

  test('panne de reseau : HorsLigneCandidature', () async {
    final LettreSupabase port = LettreSupabase.avecAppel(
      (String _, Map<String, dynamic>? _) =>
          Future<Object?>.error(Exception('reseau')),
    );
    await expectLater(
      port.lire(langue: 'fr'),
      throwsA(isA<HorsLigneCandidature>()),
    );
  });

  test('reponse mal formee : FormatException, jamais une lettre', () async {
    for (final Object? brut in <Object?>[
      null,
      <int>[1],
      <String, Object>{'acces': true, 'parties': <Object>[]},
      <String, Object>{'acces': false, 'raison': 'inconnue'},
    ]) {
      await expectLater(
        _port((_Appel _) => _ok(brut), <_Appel>[]).lire(langue: 'fr'),
        throwsFormatException,
      );
    }
  });
}
