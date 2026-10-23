// C11BIS-AFFECTATION (21/10/2026, CAND-Q15, lot c11bis) : la confirmation
// d'un enseignant pour une classe nee d'un regroupement.
//
// Ce que le test prouve :
// - chaque message que le serveur leve (`affecter_enseignant_classe_c11bis`,
//   `tc_verifier_affectation_enseignant` de 0082) devient un motif ferme ; un
//   message inconnu devient `inconnu`, jamais le texte lui-meme ;
// - l'adaptateur leve `AffectationRefusee` sur un verdict de la fonction
//   (P0001, 42501) et laisse passer tout le reste tel quel : reponse perdue,
//   passerelle 502/503/504 (corps HTML, statut HTTP comme code), jeton
//   expire, delai 57014, serialisation 40001, interblocage 40P01, verrou
//   55P03 (relecture du lot) ;
// - apres une creation, l'adaptateur relit la classe pour prendre sa
//   capacite au serveur ; une relecture perdue ne fait pas echouer la
//   creation, la capacite reste alors fermee.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart'
    show GenreClasse;
import 'package:rewayah_academy/core/offres/affectation_refusee.dart';
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/core/offres/regroupements_c11bis_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

const String _regroupement = 'aaaaaaaa-0000-4000-8000-000000000001';
const String _cle = 'bbbbbbbb-0000-4000-8000-000000000001';
const String _classe = 'cccccccc-0000-4000-8000-000000000001';

SupabaseClient _client(
  Future<http.Response> Function(http.Request r) repondre,
  List<http.Request> requetes,
) => SupabaseClient(
  'https://exemple.supabase.co',
  'cle-anonyme',
  httpClient: MockClient((http.Request r) async {
    requetes.add(r);
    final http.Response h = await repondre(r);
    return http.Response(h.body, h.statusCode, headers: h.headers, request: r);
  }),
);

http.Response _erreur(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

Map<String, Object?> _ligne({
  required String id,
  Map<String, Object?>? classe,
}) => <String, Object?>{
  'regroupement_id': id,
  'type_public': 'enfant',
  'langue_code': 'francais',
  'langue_nom': 'Français',
  'genre_public': 'hommes',
  'niveau': 'debut_lettres',
  'fuseau_iana': 'Europe/Paris',
  'occurrences': <Map<String, int>>[
    <String, int>{'jour_iso': 1, 'heure': 18, 'minute': 0},
  ],
  'nombre_eleves': 5,
  'quota': 5,
  'autres_fuseaux': <Object>[],
  'peut_creer_classe': classe == null,
  'classe': classe,
};

Map<String, Object?> _classeJson({required bool peut}) => <String, Object?>{
  'classe_id': _classe,
  'libelle': 'Garçons, lundi 18 h',
  'genre_classe': 'hommes',
  'peut_affecter_enseignant': peut,
};

void main() {
  group('motifRefusAffectation : un motif ferme par message serveur', () {
    // Les messages exacts du serveur (0079/F86, 0082), valeurs comprises.
    final Map<String, MotifRefusAffectation> attendus =
        <String, MotifRefusAffectation>{
          'classe indisponible': MotifRefusAffectation.classeIndisponible,
          'enseignant indisponible ou genre inconnu':
              MotifRefusAffectation.enseignantIndisponible,
          'enseignant incompatible avec le public de la classe':
              MotifRefusAffectation.genreIncompatible,
          'plafond horaire enseignant dépassé': MotifRefusAffectation.plafond,
          'enseignant non disponible: jour 1, heure 18, fuseau Europe/Paris, '
                  'semaine 0, instant 2026-10-26 17:00:00+00':
              MotifRefusAffectation.nonDisponible,
          'chevauchement avec une classe ou affectation active':
              MotifRefusAffectation.chevauchementClasse,
          'chevauchement avec une séance existante':
              MotifRefusAffectation.chevauchementSeance,
          'classe ou enseignant absent': MotifRefusAffectation.inconnu,
          'compatibilite enseignant non verifiable : source titre public '
                  'absente':
              MotifRefusAffectation.inconnu,
          '': MotifRefusAffectation.inconnu,
        };
    for (final MapEntry<String, MotifRefusAffectation> e in attendus.entries) {
      test('« ${e.key} » -> ${e.value.name}', () {
        expect(motifRefusAffectation(code: 'P0001', message: e.key), e.value);
      });
    }

    test('42501 : la garde ou la fonction fermee, quel que soit le texte', () {
      expect(
        motifRefusAffectation(
          code: '42501',
          message: "affectation reservee a l'administration",
        ),
        MotifRefusAffectation.reservee,
      );
      expect(
        motifRefusAffectation(
          code: '42501',
          message: 'permission denied for function x',
        ),
        MotifRefusAffectation.reservee,
      );
    });

    test('seuls P0001 et 42501 sont un verdict de la fonction', () {
      expect(estRefusAffectation('P0001'), isTrue);
      expect(estRefusAffectation('42501'), isTrue);
      for (final String? code in <String?>[
        null,
        '',
        '500',
        '502',
        '503',
        '504',
        'PGRST303',
        'PGRST202',
        '57014',
        '40001',
        '40P01',
        '55P03',
        '23505',
        '08006',
      ]) {
        expect(estRefusAffectation(code), isFalse, reason: '$code');
      }
    });

    test('le refus ne garde pas le texte du serveur', () {
      const AffectationRefusee refus = AffectationRefusee(
        MotifRefusAffectation.nonDisponible,
      );
      expect(refus.toString(), 'AffectationRefusee(nonDisponible)');
    });
  });

  group('RegroupementsC11bisSupabase.affecterEnseignant', () {
    Future<Object?> appeler(http.Response reponse) async {
      final List<http.Request> requetes = <http.Request>[];
      final RegroupementsC11bisSupabase port = RegroupementsC11bisSupabase(
        _client((http.Request _) async => reponse, requetes),
      );
      try {
        return await port.affecterEnseignant(
          classeId: _classe,
          enseignantId: 'dddddddd-0000-4000-8000-000000000001',
        );
      } on Object catch (e) {
        return e;
      } finally {
        final http.Request r = requetes.single;
        expect(r.url.path, '/rest/v1/rpc/affecter_enseignant_classe_c11bis');
        expect(jsonDecode(r.body), <String, String>{
          'p_groupe_id': _classe,
          'p_teacher_profile_id': 'dddddddd-0000-4000-8000-000000000001',
        });
      }
    }

    test('affecte et deja_affecte', () async {
      expect(
        await appeler(http.Response('"affecte"', 200, headers: _json)),
        ResultatAffectation.affecte,
      );
      expect(
        await appeler(http.Response('"deja_affecte"', 200, headers: _json)),
        ResultatAffectation.dejaAffecte,
      );
    });

    test(
      'un refus du serveur devient AffectationRefusee, motif ferme',
      () async {
        final Object? chevauchement = await appeler(
          _erreur(
            'P0001',
            'chevauchement avec une classe ou affectation active',
          ),
        );
        expect(
          chevauchement,
          isA<AffectationRefusee>().having(
            (AffectationRefusee e) => e.motif,
            'motif',
            MotifRefusAffectation.chevauchementClasse,
          ),
        );
        final Object? garde = await appeler(
          _erreur(
            '42501',
            "affectation reservee a l'administration",
            statut: 403,
          ),
        );
        expect(
          garde,
          isA<AffectationRefusee>().having(
            (AffectationRefusee e) => e.motif,
            'motif',
            MotifRefusAffectation.reservee,
          ),
        );
        final Object? inconnu = await appeler(
          _erreur('P0001', 'un message que le client ne connait pas'),
        );
        expect(
          inconnu,
          isA<AffectationRefusee>().having(
            (AffectationRefusee e) => e.motif,
            'motif',
            MotifRefusAffectation.inconnu,
          ),
        );
      },
    );

    // Relecture du lot : une reponse de passerelle (corps HTML, statut HTTP
    // comme code), un jeton expire, un delai ou un interblocage ne sont pas
    // un verdict de la fonction. La transaction a pu aboutir (504) ou etre
    // annulee sans verdict (57014, 40P01) : la meme personne reussirait en
    // pressant de nouveau. L'adaptateur laisse donc passer l'erreur, et la
    // feuille dit « non confirme », pas « choisissez-en un autre ».
    final Map<String, http.Response> pasUnRefus = <String, http.Response>{
      'passerelle 504, corps HTML': http.Response(
        '<html><body>504 Gateway Time-out</body></html>',
        504,
        headers: <String, String>{'content-type': 'text/html'},
      ),
      'passerelle 503, corps texte': http.Response(
        'upstream connect error',
        503,
      ),
      'passerelle 502, corps vide': http.Response('', 502),
      'jeton expire (PGRST303)': _erreur(
        'PGRST303',
        'JWT expired',
        statut: 401,
      ),
      'delai depasse (57014)': _erreur(
        '57014',
        'canceling statement due to statement timeout',
        statut: 500,
      ),
      'interblocage (40P01)': _erreur(
        '40P01',
        'deadlock detected',
        statut: 500,
      ),
      'serialisation (40001)': _erreur(
        '40001',
        'could not serialize access due to concurrent update',
        statut: 500,
      ),
      'verrou indisponible (55P03)': _erreur(
        '55P03',
        'could not obtain lock on row in relation "groupes"',
        statut: 500,
      ),
    };
    for (final MapEntry<String, http.Response> e in pasUnRefus.entries) {
      test('${e.key} : pas un refus, l erreur passe telle quelle', () async {
        final Object? resultat = await appeler(e.value);
        expect(resultat, isNot(isA<AffectationRefusee>()));
        expect(resultat, isA<PostgrestException>());
      });
    }

    test('une reponse perdue n est pas un refus', () async {
      final List<http.Request> requetes = <http.Request>[];
      final RegroupementsC11bisSupabase port = RegroupementsC11bisSupabase(
        _client(
          (http.Request _) async => throw http.ClientException('coupure'),
          requetes,
        ),
      );
      await expectLater(
        port.affecterEnseignant(
          classeId: _classe,
          enseignantId: 'dddddddd-0000-4000-8000-000000000001',
        ),
        throwsA(isNot(isA<AffectationRefusee>())),
      );
    });
  });

  group('RegroupementsC11bisSupabase.creerClasse relit la capacite', () {
    Future<ResultatCreationClasse> creer({
      required Future<http.Response> Function() relecture,
    }) async {
      int lectures = 0;
      final List<http.Request> requetes = <http.Request>[];
      final RegroupementsC11bisSupabase port = RegroupementsC11bisSupabase(
        _client((http.Request r) async {
          if (r.url.path == '/rest/v1/rpc/regroupements_c11bis_admin') {
            lectures++;
            if (lectures == 1) {
              return http.Response(
                jsonEncode(<Map<String, Object?>>[_ligne(id: _regroupement)]),
                200,
                headers: _json,
              );
            }
            return relecture();
          }
          expect(r.url.path, '/rest/v1/rpc/creer_classe_depuis_regroupement');
          return http.Response('"$_classe"', 200, headers: _json);
        }, requetes),
      );
      final ResultatCreationClasse resultat = await port.creerClasse(
        regroupementId: _regroupement,
        genre: GenreClasse.hommes,
        libelle: 'Garçons, lundi 18 h',
        cleEnvoi: _cle,
      );
      expect(lectures, 2);
      return resultat;
    }

    test(
      'capacite ouverte par le serveur : le bouton pourra s afficher',
      () async {
        final ResultatCreationClasse r = await creer(
          relecture: () async => http.Response(
            jsonEncode(<Map<String, Object?>>[
              _ligne(id: 'g:$_classe', classe: _classeJson(peut: true)),
            ]),
            200,
            headers: _json,
          ),
        );
        expect(r, isA<ClasseCreee>());
        final ClasseSansEnseignant classe = (r as ClasseCreee).classe;
        expect(classe.classeId, _classe);
        expect(classe.peutAffecterEnseignant, isTrue);
        expect(classe.genre, GenreClasse.hommes);
        expect(r.elevesIntegres, 5);
      },
    );

    test('deux lignes pour la meme classe : ouverte seulement si toutes '
        'le disent', () async {
      final ResultatCreationClasse r = await creer(
        relecture: () async => http.Response(
          jsonEncode(<Map<String, Object?>>[
            _ligne(id: _regroupement, classe: _classeJson(peut: false)),
            _ligne(id: 'g:$_classe', classe: _classeJson(peut: true)),
          ]),
          200,
          headers: _json,
        ),
      );
      expect((r as ClasseCreee).classe.peutAffecterEnseignant, isFalse);
    });

    test('relecture perdue : la classe est creee, la capacite reste '
        'fermee', () async {
      final ResultatCreationClasse r = await creer(
        relecture: () async => _erreur('XX000', 'panne', statut: 500),
      );
      expect(r, isA<ClasseCreee>());
      expect((r as ClasseCreee).classe.peutAffecterEnseignant, isFalse);
      expect(r.classe.classeId, _classe);
    });
  });
}
