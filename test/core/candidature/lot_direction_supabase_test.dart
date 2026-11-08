// LISTES-1 : le traitement groupe des candidatures sur l'adaptateur Supabase :
// `apercu_lot_candidats` et `executer_lot_candidats` (CAND-L2A2, section 4).
// Ce que le test prouve :
// - chaque appel part sur SA RPC, avec les parametres que le serveur lit : le
//   geste, les identifiants, le jeton, le nombre saisi, la cle d'idempotence, le
//   motif, le modele et la reprise en `AAAA-MM-JJ` ;
// - l'apercu et le rapport sont lus tels que le serveur les rend : jamais un
//   total recalcule, jamais un succes sans compte ;
// - chaque refus rendu (jeton perime, aucun eligible, nombre discordant, geste
//   non groupable, cle reutilisee, motif, modele, reprise) devient son exception
//   nommee, rien d'ecrit ;
// - un lot sans reponse est « non confirme », et la meme cle peut le rejouer.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/candidatures_direction_supabase.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_lot_candidatures.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

class _Appel {
  _Appel(this.fonction, this.corps);

  final String fonction;
  final Map<String, dynamic> corps;
}

CandidaturesDirectionSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => CandidaturesDirectionSupabase(
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

CandidaturesDirectionSupabase _portSansReseau() =>
    CandidaturesDirectionSupabase(
      SupabaseClient(
        'https://exemple.supabase.co',
        'cle-anonyme',
        httpClient: MockClient(
          (http.Request _) async => throw http.ClientException('hors ligne'),
        ),
      ),
    );

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, String message) => http.Response(
  jsonEncode(<String, String>{'code': code, 'message': message}),
  400,
  headers: _json,
);

Map<String, Object?> _apercu() => <String, Object?>{
  'geste': 'mettre_en_pause',
  'effet': 'pause',
  'motifRequis': true,
  'modeleRequis': true,
  'eligibles': <Object?>[
    <String, Object?>{
      'id': 'c1',
      'reference': 'CAND-00001',
      'nomComplet': 'Amina Diallo',
      'etape': 'prequalification',
      'etat': 'en_examen',
      'issue': 'en_cours',
      'enPause': false,
      'version': 3,
    },
  ],
  'exclus': <Object?>[
    <String, Object?>{
      'id': 'c2',
      'reference': 'CAND-00002',
      'nomComplet': 'Bilal Haddad',
      'etape': 'prequalification',
      'etat': 'en_examen',
      'issue': 'en_cours',
      'enPause': true,
      'raison': 'transition_interdite',
      'detail': 'pause',
    },
    <String, Object?>{'id': 'c3', 'raison': 'hors_portee'},
    <String, Object?>{'id': 'c4', 'raison': 'absente'},
  ],
  'nombre': 1,
  'jeton': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
};

Map<String, Object?> _rapport({bool rejoue = false}) => <String, Object?>{
  'geste': 'mettre_en_pause',
  'nombre': 2,
  'reussies': 1,
  'exclues': 1,
  'refusees': 1,
  'rejoue': rejoue,
  'lignes': <Object?>[
    <String, Object?>{
      'id': 'c1',
      'reference': 'CAND-00001',
      'issue': 'reussie',
    },
    <String, Object?>{
      'id': 'c2',
      'reference': 'CAND-00002',
      'issue': 'exclue',
      'raison': 'transition_interdite',
      'detail': 'pause',
    },
    <String, Object?>{
      'id': 'c5',
      'reference': 'CAND-00005',
      'issue': 'refusee',
      'raison': 'conflit_candidature',
    },
  ],
};

DemandeLot _demande({
  GesteLot geste = GesteLot.mettreEnPause,
  DateTime? reprise,
}) => DemandeLot(
  geste: geste,
  ids: const <String>['c1', 'c2'],
  jeton: 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
  nombreConfirme: 1,
  cleIdempotence: 'cand-cle-du-lot',
  motif: 'Attente des pieces.',
  modele: 'pause_general',
  repriseLe: reprise,
);

void main() {
  group('l\'apercu', () {
    test(
      'part sur apercu_lot_candidats : le geste et les identifiants seulement',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final PortCandidaturesDirection port = _port(
          (_) => _ok(_apercu()),
          appels,
        );
        final ApercuLot a = await port.preparerLot(
          geste: GesteLot.mettreEnPause,
          ids: const <String>['c1', 'c2'],
        );
        expect(appels.single.fonction, 'apercu_lot_candidats');
        expect(appels.single.corps, <String, dynamic>{
          'p_geste': 'mettreEnPause',
          'p_ids': <String>['c1', 'c2'],
        });
        // Tel que le serveur le rend : le nombre, le jeton, les raisons.
        expect(a.nombre, 1);
        expect(a.jeton, 'a1b2c3d4e5f60718293a4b5c6d7e8f90');
        expect(a.motifRequis, isTrue);
        expect(a.modeleRequis, isTrue);
        expect(a.eligibles.single.nomComplet, 'Amina Diallo');
        expect(a.eligibles.single.version, 3);
        expect(a.exclus.map((ExclusLot e) => e.raison), <RaisonExclusion>[
          RaisonExclusion.transitionInterdite,
          RaisonExclusion.horsPortee,
          RaisonExclusion.absente,
        ]);
        expect(a.exclus.first.parLaPause, isTrue);
        // Hors portee et absente ne donnent ni nom ni reference.
        expect(a.exclus[1].nomComplet, isEmpty);
        expect(a.exclus[1].reference, isEmpty);
      },
    );

    test('les trois gestes ont leur valeur', () {
      expect(
        parametresApercuLot(GesteLot.leverPause, <String>['c1']).$2['p_geste'],
        'leverPause',
      );
      expect(
        parametresApercuLot(GesteLot.refuser, <String>['c1']).$2['p_geste'],
        'refuser',
      );
      expect(GesteLot.depuisGeste(GesteCandidature.refuser), GesteLot.refuser);
      // Les autres gestes ne se groupent pas : aucune valeur de lot.
      expect(
        GesteLot.depuisGeste(GesteCandidature.admettreVerifications),
        isNull,
      );
      expect(GesteLot.depuisGeste(GesteCandidature.rouvrir), isNull);
      expect(GesteLot.depuisSql('mettre_en_pause'), GesteLot.mettreEnPause);
    });

    test('une reponse sans jeton n\'est pas un apercu', () async {
      final PortCandidaturesDirection port = _port(
        (_) => _ok(<String, Object?>{'geste': 'refuser', 'nombre': 1}),
        <_Appel>[],
      );
      await expectLater(
        port.preparerLot(geste: GesteLot.refuser, ids: const <String>['c1']),
        throwsFormatException,
      );
    });

    test('geste_non_groupable est son exception', () async {
      final PortCandidaturesDirection port = _port(
        (_) => _ok(<String, Object?>{'erreur': 'geste_non_groupable'}),
        <_Appel>[],
      );
      await expectLater(
        port.preparerLot(geste: GesteLot.refuser, ids: const <String>['c1']),
        throwsA(isA<GesteNonGroupable>()),
      );
    });

    test('42501 : acces refuse ; genre inconnu ; fonction absente : capacite indisponible', () async {
      await expectLater(
        _port(
          (_) => _erreurPg('42501', 'gestes reserves'),
          <_Appel>[],
        ).preparerLot(geste: GesteLot.refuser, ids: const <String>['c1']),
        throwsA(isA<PermissionInsuffisante>()),
      );
      await expectLater(
        _port(
          (_) => _erreurPg('42501', 'genre du lecteur inconnu : aucun geste'),
          <_Appel>[],
        ).preparerLot(geste: GesteLot.refuser, ids: const <String>['c1']),
        throwsA(isA<GenreLecteurInconnu>()),
      );
      await expectLater(
        _port(
          (_) => _erreurPg('PGRST202', 'absente'),
          <_Appel>[],
        ).preparerLot(geste: GesteLot.refuser, ids: const <String>['c1']),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('l\'execution', () {
    test(
      'part sur executer_lot_candidats avec tout ce que le serveur lit',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final PortCandidaturesDirection port = _port(
          (_) => _ok(_rapport()),
          appels,
        );
        final RapportLot r = await port.executerLot(
          _demande(reprise: DateTime(2026, 11, 3)),
        );
        expect(appels.single.fonction, 'executer_lot_candidats');
        expect(appels.single.corps, <String, dynamic>{
          'p_geste': 'mettreEnPause',
          'p_ids': <String>['c1', 'c2'],
          'p_jeton': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
          'p_nombre_confirme': 1,
          'p_cle_idempotence': 'cand-cle-du-lot',
          'p_motif': 'Attente des pieces.',
          'p_modele': 'pause_general',
          'p_reprise_le': '2026-11-03',
        });
        expect(r.reussies, 1);
        expect(r.exclues, 1);
        expect(r.refusees, 1);
        expect(r.rejoue, isFalse);
        expect(r.lignes.map((LigneRapportLot l) => l.issue), <IssueLigneLot>[
          IssueLigneLot.reussie,
          IssueLigneLot.exclue,
          IssueLigneLot.refusee,
        ]);
        expect(r.lignes.last.raison, 'conflit_candidature');
        expect(r.lignes[1].parLaPause, isTrue);
      },
    );

    test('lever la pause n\'envoie ni modele ni reprise inventes', () {
      final (String, Map<String, dynamic>) p = parametresExecutionLot(
        DemandeLot(
          geste: GesteLot.leverPause,
          ids: const <String>['c1'],
          jeton: 'x' * 32,
          nombreConfirme: 1,
          cleIdempotence: 'cand-cle-du-lot',
        ),
      );
      expect(p.$2['p_modele'], isNull);
      expect(p.$2['p_motif'], isNull);
      expect(p.$2['p_reprise_le'], isNull);
    });

    test('un rapport rejoue se dit rejoue', () async {
      final PortCandidaturesDirection port = _port(
        (_) => _ok(_rapport(rejoue: true)),
        <_Appel>[],
      );
      expect((await port.executerLot(_demande())).rejoue, isTrue);
    });

    test(
      'une reponse sans compte n\'est pas un rapport, jamais un succes suppose',
      () async {
        final PortCandidaturesDirection port = _port(
          (_) => _ok(<String, Object?>{
            'geste': 'mettre_en_pause',
            'lignes': <Object?>[],
          }),
          <_Appel>[],
        );
        await expectLater(port.executerLot(_demande()), throwsFormatException);
      },
    );

    final Map<String, Matcher> refus = <String, Matcher>{
      'jeton_perime': isA<JetonPerime>(),
      'aucun_eligible': isA<AucunEligible>(),
      'geste_non_groupable': isA<GesteNonGroupable>(),
      'cle_idempotence_reutilisee': isA<CleLotReutilisee>(),
      'hors_portee': isA<CandidatureHorsPortee>(),
      'motif_requis': isA<MotifRequis>(),
      'modele_requis': isA<ModeleRequis>(),
      'modele_inconnu': isA<ModeleInconnu>(),
      'date_reprise_invalide': isA<RepriseInvalide>(),
    };
    for (final MapEntry<String, Matcher> e in refus.entries) {
      test('${e.key} : son exception, rien d\'ecrit', () async {
        final PortCandidaturesDirection port = _port(
          (_) => _ok(<String, Object?>{'erreur': e.key}),
          <_Appel>[],
        );
        await expectLater(port.executerLot(_demande()), throwsA(e.value));
      });
    }

    test('nombre_discordant dit le vrai nombre', () async {
      final PortCandidaturesDirection port = _port(
        (_) =>
            _ok(<String, Object?>{'erreur': 'nombre_discordant', 'nombre': 7}),
        <_Appel>[],
      );
      await expectLater(
        port.executerLot(_demande()),
        throwsA(
          isA<NombreDiscordant>().having(
            (NombreDiscordant n) => n.nombre,
            'nombre',
            7,
          ),
        ),
      );
    });

    test('un refus inconnu n\'est jamais un succes', () async {
      final PortCandidaturesDirection port = _port(
        (_) => _ok(<String, Object?>{'erreur': 'inconnu_de_cette_version'}),
        <_Appel>[],
      );
      await expectLater(port.executerLot(_demande()), throwsFormatException);
    });

    test('sans reponse : non confirme, la cle peut rejouer le lot', () async {
      await expectLater(
        _portSansReseau().executerLot(_demande()),
        throwsA(isA<GesteNonConfirme>()),
      );
    });
  });
}
