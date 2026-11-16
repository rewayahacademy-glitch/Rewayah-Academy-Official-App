// MAJEUR (directeur, 16/11/2026) : le cœur de l'attestation « 18 ans ou plus ».
// Ce que le test prouve :
// - le modele lit la cle `majorite` de l'etat du candidat (vraie, fausse, sans
//   declaration) et un serveur d'avant, qui ne la rend pas, vaut « non servie » :
//   jamais un candidat bloque par une question que le serveur ne pose pas ;
// - l'adaptateur envoie `p_majeur`, rend la declaration relue, jamais un faux
//   succes ; `declaration_deja_faite` et `majorite_requise` deviennent deux
//   exceptions typees, distinctes ;
// - le dossier de la direction lit `majorite` ; le filtre de la file envoie la cle
//   `majorite` seulement quand elle est posee.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/candidatures_direction_supabase.dart';
import 'package:rewayah_academy/core/candidature/ma_candidature_supabase.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
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

MaCandidatureSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => MaCandidatureSupabase(
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

http.Response _erreurPg(String code, String message) => http.Response(
  jsonEncode(<String, String>{'code': code, 'message': message}),
  400,
  headers: _json,
);

Map<String, Object?> _bloc(Object? majorite) => <String, Object?>{
  'candidature': true,
  'etape': 'prequalification',
  'etat': 'a_completer',
  'issue': 'en_cours',
  'version': 3,
  'majorite': ?majorite,
};

void main() {
  group('le modele', () {
    test('vraie, fausse, sans declaration', () {
      final MajoriteCandidature oui = CandidatureDossier.depuisJson(
        _bloc(<String, Object?>{
          'declaree': true,
          'attesteeLe': '2026-11-16T09:00:00.000000Z',
        }),
      ).majorite;
      expect(oui.servie, isTrue);
      expect(oui.attestee, isTrue);
      expect(oui.aAttester, isFalse);
      expect(oui.permetDAvancer, isTrue);
      expect(oui.attesteeLe?.toUtc(), DateTime.utc(2026, 11, 16, 9));

      final MajoriteCandidature non = CandidatureDossier.depuisJson(
        _bloc(<String, Object?>{'declaree': false, 'attesteeLe': null}),
      ).majorite;
      expect(non.moinsDe18, isTrue);
      expect(non.permetDAvancer, isFalse);
      expect(non.aAttester, isFalse);

      final MajoriteCandidature aFaire = CandidatureDossier.depuisJson(
        _bloc(<String, Object?>{'declaree': null, 'attesteeLe': null}),
      ).majorite;
      expect(aFaire.aAttester, isTrue);
      expect(aFaire.permetDAvancer, isFalse);
    });

    test(
      'un serveur d avant ne rend pas la cle : non servie, rien ne se bloque',
      () {
        final MajoriteCandidature m = CandidatureDossier.depuisJson(_bloc(null))
            .majorite;
        expect(m.servie, isFalse);
        expect(m.aAttester, isFalse);
        expect(m.permetDAvancer, isTrue);
        expect(m, MajoriteCandidature.nonServie);
      },
    );

    test('une cle mal formee vaut non servie', () {
      expect(
        CandidatureDossier.depuisJson(_bloc('oui')).majorite.servie,
        isFalse,
      );
    });

    test('l egalite compte l attestation', () {
      expect(
        CandidatureDossier.depuisJson(
              _bloc(<String, Object?>{'declaree': true}),
            ) ==
            CandidatureDossier.depuisJson(
              _bloc(<String, Object?>{'declaree': false}),
            ),
        isFalse,
      );
    });
  });

  group('l adaptateur du candidat', () {
    test('envoie p_majeur et rend la declaration relue', () async {
      final List<_Appel> appels = <_Appel>[];
      final MaCandidatureSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'majorite': <String, Object?>{
            'declaree': true,
            'attesteeLe': '2026-11-16T09:00:00.000000Z',
          },
          'candidature': _bloc(null),
        }),
        appels,
      );
      final MajoriteCandidature m = await port.attesterMajorite(majeur: true);
      expect(appels.single.fonction, 'attester_majorite');
      expect(appels.single.corps, <String, dynamic>{'p_majeur': true});
      expect(m.attestee, isTrue);
    });

    test('moins de 18 ans : p_majeur faux', () async {
      final List<_Appel> appels = <_Appel>[];
      final MaCandidatureSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'majorite': <String, Object?>{'declaree': false, 'attesteeLe': null},
        }),
        appels,
      );
      final MajoriteCandidature m = await port.attesterMajorite(majeur: false);
      expect(appels.single.corps, <String, dynamic>{'p_majeur': false});
      expect(m.moinsDe18, isTrue);
    });

    test(
      'jamais un faux succes : sans declaration relue, ou contraire',
      () async {
        final MaCandidatureSupabase sans = _port(
          (_Appel _) => _ok(<String, Object?>{'candidature': _bloc(null)}),
          <_Appel>[],
        );
        await expectLater(
          sans.attesterMajorite(majeur: true),
          throwsFormatException,
        );
        final MaCandidatureSupabase contraire = _port(
          (_Appel _) => _ok(<String, Object?>{
            'majorite': <String, Object?>{'declaree': false},
          }),
          <_Appel>[],
        );
        await expectLater(
          contraire.attesterMajorite(majeur: true),
          throwsFormatException,
        );
      },
    );

    test(
      'declaration_deja_faite et majorite_requise : deux exceptions distinctes',
      () async {
        Future<Object?> avec(String erreur) async {
          final MaCandidatureSupabase port = _port(
            (_Appel _) => _ok(<String, Object?>{'erreur': erreur}),
            <_Appel>[],
          );
          try {
            await port.attesterMajorite(majeur: true);
          } on Object catch (e) {
            return e;
          }
          return null;
        }

        expect(
          await avec('declaration_deja_faite'),
          isA<DeclarationDejaFaite>(),
        );
        expect(await avec('majorite_requise'), isA<MajoriteRequise>());
      },
    );

    test(
      'le refus de l envoi est une exception typee, sans code a l ecran',
      () async {
        final MaCandidatureSupabase port = _port(
          (_Appel _) => _ok(<String, Object?>{'erreur': 'majorite_requise'}),
          <_Appel>[],
        );
        await expectLater(
          port.envoyerReponses(
            versionQuestionnaire: 'x',
            reponses: const <String, Object?>{},
            accordRemuneration: true,
            versionConditions: 'v',
            versionAttendue: 1,
            cleIdempotence: 'cle',
          ),
          throwsA(isA<MajoriteRequise>()),
        );
      },
    );

    test('42501 : acces refuse', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel _) => _erreurPg('42501', 'attestation reservee'),
        <_Appel>[],
      );
      await expectLater(
        port.attesterMajorite(majeur: true),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });
  });

  group('la direction', () {
    test(
      'le dossier lit majorite, nul sans declaration, non servi sans la cle',
      () {
        Map<String, Object?> dossier(Object? majorite) => <String, Object?>{
          'id': 'c1',
          'reference': 'CAND-00001',
          'nomComplet': 'Amina Diallo',
          'type': 'enseignant',
          'etape': 'prequalification',
          'etat': 'en_examen',
          'issue': 'en_cours',
          'enPause': false,
          'repriseLe': null,
          'restreinte': false,
          'indisponible': false,
          'indisponibleJusquAu': null,
          'paiement': 'a_verifier',
          'paysResidence': 'SN',
          'responsableId': null,
          'courrielAObtenir': true,
          'indicatifAConfirmer': false,
          'derniereActivite': '2026-10-20T09:00:00.000000Z',
          'recueLe': '2026-10-01T09:00:00.000000Z',
          'version': 2,
          'source': 'lien_public',
          'reponses': <Object?>[],
          'majorite': ?majorite,
        };
        expect(
          DetailCandidature.depuisJson(
            dossier(<String, Object?>{
              'declaree': true,
              'attesteeLe': '2026-11-16T09:00:00.000000Z',
            }),
          ).majorite.attestee,
          isTrue,
        );
        expect(
          DetailCandidature.depuisJson(
            dossier(<String, Object?>{'declaree': null, 'attesteeLe': null}),
          ).majorite.aAttester,
          isTrue,
        );
        expect(
          DetailCandidature.depuisJson(dossier(null)).majorite.servie,
          isFalse,
        );
      },
    );

    test('le filtre envoie majorite seulement quand elle est posee', () {
      expect(filtreEnJson(const FiltreCandidatures()), isEmpty);
      for (final String v in <String>['attestee', 'non_attestee', 'moins_18']) {
        expect(filtreEnJson(FiltreCandidatures(majorite: v)), <String, Object>{
          'majorite': v,
        });
      }
      expect(const FiltreCandidatures(majorite: 'moins_18').estVide, isFalse);
      expect(const FiltreCandidatures(majorite: 'moins_18').nombreAxes, 1);
    });

    test('avec, egalite et hachage tiennent compte de majorite', () {
      const FiltreCandidatures base = FiltreCandidatures(majorite: 'attestee');
      expect(base.avec(majorite: () => 'moins_18').majorite, 'moins_18');
      expect(base.avec(majorite: () => null).majorite, isNull);
      expect(base.avec(recherche: 'x').majorite, 'attestee');
      expect(base, const FiltreCandidatures(majorite: 'attestee'));
      expect(
        base.hashCode,
        const FiltreCandidatures(majorite: 'attestee').hashCode,
      );
      expect(base == const FiltreCandidatures(majorite: 'moins_18'), isFalse);
    });
  });
}
