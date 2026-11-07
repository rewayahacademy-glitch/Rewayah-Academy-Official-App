// CAND-04 : l'adaptateur Supabase de l'inscription du candidat sur les RPC de
// CAND-L3 (`inscription_candidat_ouverte`, `inscrire_candidat`). Ce que le test
// prouve :
// - la forme envoyee : le code (nul pour le lien public), l'identite, le genre
//   SQL, le telephone international, la langue de l'ecran, la version de
//   confidentialite acceptee ; aucune autre cle ;
// - les dix issues du serveur deviennent chacune un resultat type, et
//   `acceptee` n'en a qu'un : le port ne distingue pas un succes d'un
//   depassement du plafond horaire (CAND-F03) ;
// - 42501 devient `PermissionInsuffisante`, une fonction absente du serveur
//   (lot non verse) devient `CapaciteIndisponible`, une panne reseau devient
//   `HorsLigneCandidature` (issue non confirmee) ;
// - une reponse mal formee n'est jamais un succes (`FormatException`).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/inscription_candidat_supabase.dart';
import 'package:rewayah_academy/core/candidature/port_inscription_candidat.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
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

SupabaseClient _client(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => SupabaseClient(
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
    return http.Response(h.body, h.statusCode, headers: h.headers, request: r);
  }),
);

InscriptionCandidatSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => InscriptionCandidatSupabase(_client(repondre, appels));

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

Future<ResultatInscriptionCandidat> _inscrire(
  InscriptionCandidatSupabase port, {
  String? code,
}) => port.inscrire(
  code: code,
  prenom: 'Amina',
  nom: 'Exemple',
  genre: 'female',
  telephone: '+33612345678',
  langue: 'fr',
  versionConfidentialite: '2026-10-v1',
);

void main() {
  group('ouverte', () {
    test('la cle de mise en ligne et la version attendue', () async {
      final List<_Appel> appels = <_Appel>[];
      final OuvertureInscriptionCandidat o = await _port(
        (_Appel a) => _ok(<String, Object?>{
          'ouverte': true,
          'versionConfidentialite': '2026-10-v1',
        }),
        appels,
      ).ouverte();
      expect(appels.single.fonction, 'inscription_candidat_ouverte');
      expect(o.ouverte, isTrue);
      expect(o.versionConfidentialite, '2026-10-v1');
    });

    test(
      'fermee par defaut : une cle absente ou fausse ne ouvre rien',
      () async {
        final OuvertureInscriptionCandidat o = await _port(
          (_Appel a) => _ok(<String, Object?>{'ouverte': false}),
          <_Appel>[],
        ).ouverte();
        expect(o.ouverte, isFalse);
        expect(o.versionConfidentialite, isNull);
        final OuvertureInscriptionCandidat vide = await _port(
          (_Appel a) => _ok(<String, Object?>{}),
          <_Appel>[],
        ).ouverte();
        expect(vide.ouverte, isFalse);
      },
    );

    test('42501, lot absent, panne et reponse mal formee', () async {
      await expectLater(
        _port(
          (_Appel a) => _erreurPg('42501', 'session requise', statut: 403),
          <_Appel>[],
        ).ouverte(),
        throwsA(isA<PermissionInsuffisante>()),
      );
      await expectLater(
        _port(
          (_Appel a) => _erreurPg('PGRST202', 'absente', statut: 404),
          <_Appel>[],
        ).ouverte(),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            dependanceInscriptionCandidat,
          ),
        ),
      );
      await expectLater(
        InscriptionCandidatSupabase(
          SupabaseClient(
            'https://exemple.supabase.co',
            'cle-anonyme',
            httpClient: MockClient(
              (http.Request r) async => throw http.ClientException('coupe'),
            ),
          ),
        ).ouverte(),
        throwsA(isA<HorsLigneCandidature>()),
      );
      await expectLater(
        _port((_Appel a) => _ok(<Object?>[]), <_Appel>[]).ouverte(),
        throwsFormatException,
      );
    });
  });

  group('inscrire', () {
    test(
      'la forme envoyee : sept parametres, le code nul pour le lien',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final ResultatInscriptionCandidat r = await _inscrire(
          _port(
            (_Appel a) => _ok(<String, Object?>{'resultat': 'acceptee'}),
            appels,
          ),
        );
        expect(r, isA<InscriptionAcceptee>());
        expect(appels.single.fonction, 'inscrire_candidat');
        expect(appels.single.corps, <String, Object?>{
          'p_code': null,
          'p_first_name': 'Amina',
          'p_last_name': 'Exemple',
          'p_gender': 'female',
          'p_telephone': '+33612345678',
          'p_langue': 'fr',
          'p_version_confidentialite': '2026-10-v1',
        });
      },
    );

    test('le code d invitation part tel quel', () async {
      final List<_Appel> appels = <_Appel>[];
      await _inscrire(
        _port(
          (_Appel a) => _ok(<String, Object?>{'resultat': 'acceptee'}),
          appels,
        ),
        code: 'ABCD-EFGH-JKMN',
      );
      expect(appels.single.corps['p_code'], 'ABCD-EFGH-JKMN');
    });

    final Map<String, Matcher> issues = <String, Matcher>{
      'acceptee': isA<InscriptionAcceptee>(),
      'fermee': isA<InscriptionFermee>(),
      'courriel_non_confirme': isA<InscriptionCourrielNonConfirme>(),
      'inconnue': isA<InscriptionCodeInconnu>(),
      'deja_utilisee': isA<InscriptionCodeDejaUtilise>(),
      'expiree': isA<InscriptionCodeExpire>(),
      'confidentialite_requise': isA<InscriptionConfidentialiteRequise>(),
      'confidentialite_perimee': isA<InscriptionConfidentialitePerimee>(),
      'confidentialite_indisponible':
          isA<InscriptionConfidentialiteIndisponible>(),
    };
    for (final MapEntry<String, Matcher> e in issues.entries) {
      test('${e.key} devient un resultat type', () async {
        final ResultatInscriptionCandidat r = await _inscrire(
          _port(
            (_Appel a) => _ok(<String, Object?>{'resultat': e.key}),
            <_Appel>[],
          ),
        );
        expect(r, e.value);
      });
    }

    test('invalide nomme les champs, dans l ordre du serveur', () async {
      final ResultatInscriptionCandidat r = await _inscrire(
        _port(
          (_Appel a) => _ok(<String, Object?>{
            'resultat': 'invalide',
            'champs': <String>['genre', 'telephone'],
          }),
          <_Appel>[],
        ),
      );
      expect((r as InscriptionInvalide).champs, <String>['genre', 'telephone']);
    });

    test(
      'la version courante est rendue avec les refus de confidentialite',
      () async {
        final ResultatInscriptionCandidat r = await _inscrire(
          _port(
            (_Appel a) => _ok(<String, Object?>{
              'resultat': 'confidentialite_perimee',
              'versionCourante': '2026-11-v2',
            }),
            <_Appel>[],
          ),
        );
        expect(
          (r as InscriptionConfidentialitePerimee).versionCourante,
          '2026-11-v2',
        );
      },
    );

    test('le succes et le plafond n ont qu une seule reponse', () async {
      // Le serveur rend {resultat: acceptee} dans les deux cas : le port n'a
      // aucun moyen de les distinguer.
      final ResultatInscriptionCandidat succes = await _inscrire(
        _port(
          (_Appel a) => _ok(<String, Object?>{'resultat': 'acceptee'}),
          <_Appel>[],
        ),
      );
      final ResultatInscriptionCandidat plafond = await _inscrire(
        _port(
          (_Appel a) => _ok(<String, Object?>{'resultat': 'acceptee'}),
          <_Appel>[],
        ),
      );
      expect(succes.runtimeType, plafond.runtimeType);
    });

    test('42501 : une session qui a deja un profil', () async {
      await expectLater(
        _inscrire(
          _port(
            (_Appel a) => _erreurPg('42501', 'reservee', statut: 403),
            <_Appel>[],
          ),
        ),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('fonction absente : capacite indisponible', () async {
      await expectLater(
        _inscrire(
          _port(
            (_Appel a) => _erreurPg('42883', 'inconnue', statut: 404),
            <_Appel>[],
          ),
        ),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('panne reseau : issue non confirmee', () async {
      await expectLater(
        _inscrire(
          InscriptionCandidatSupabase(
            SupabaseClient(
              'https://exemple.supabase.co',
              'cle-anonyme',
              httpClient: MockClient(
                (http.Request r) async => throw http.ClientException('coupe'),
              ),
            ),
          ),
        ),
        throwsA(isA<HorsLigneCandidature>()),
      );
    });

    test('un resultat inconnu n est jamais un succes', () async {
      await expectLater(
        _inscrire(
          _port(
            (_Appel a) => _ok(<String, Object?>{'resultat': 'peut-etre'}),
            <_Appel>[],
          ),
        ),
        throwsFormatException,
      );
    });
  });
}
