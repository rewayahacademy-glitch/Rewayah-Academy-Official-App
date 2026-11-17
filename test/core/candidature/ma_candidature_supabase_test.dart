// CAND-01 : l'adaptateur Supabase du candidat sur les RPC de CAND-L2A1 et de
// L6. Ce que le test prouve :
// - les refus metier arrivent DANS la reponse (`{"erreur": ...}`) et deviennent
//   une exception typee, un par code, sans jamais afficher le code ;
// - 42501 devient `PermissionInsuffisante`, une fonction absente du serveur
//   (lot non verse) devient `CapaciteIndisponible`, une panne reseau devient
//   `HorsLigneCandidature` (issue non confirmee) ;
// - aucun montant n'est lu : ni `parElevePresentEtParHeure` ni `devise` ;
// - le virement bancaire et les operateurs mobiles se lisent a part, les lignes
//   hors monnaie mobile ne deviennent jamais un operateur.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/ma_candidature_supabase.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';

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
      // Une RPC sans parametre envoie `null` comme corps.
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

http.Response _erreurPg(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

Map<String, dynamic> _bloc({int version = 4}) => <String, dynamic>{
  'candidature': true,
  'etape': 'prequalification',
  'etat': 'en_examen',
  'issue': 'en_cours',
  'version': version,
};

void main() {
  group('lectures', () {
    test('les conditions : la part par public, jamais un montant', () async {
      final List<_Appel> appels = <_Appel>[];
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{
          'disponible': true,
          'version': 'v2.0.0',
          'dateEffet': '2026-11-01',
          'enVigueur': false,
          'parElevePresentEtParHeure': 1.99,
          'devise': 'USD',
          'publics': <Map<String, Object>>[
            <String, Object>{
              'public': 'enfant',
              'partPourMille': 470,
              'parElevePresentEtParHeure': 1.99,
            },
          ],
        }),
        appels,
      );
      final ConditionsRemuneration c = await port.conditionsRemuneration();
      expect(appels.single.fonction, 'conditions_remuneration_candidat');
      expect(c.version, 'v2.0.0');
      expect(c.publics.single.partPourMille, 470);
    });

    test('des conditions indisponibles : capacite indisponible', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{'disponible': false}),
        <_Appel>[],
      );
      await expectLater(
        port.conditionsRemuneration(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('un questionnaire indisponible : capacite indisponible', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{'disponible': false}),
        <_Appel>[],
      );
      await expectLater(
        port.questionnaire(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('le questionnaire se lit tel que le serveur le rend', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(questionnaireJsonDeTest(versionBrouillon: 5)),
        <_Appel>[],
      );
      final Questionnaire q = await port.questionnaire();
      expect(q.version, 'salle-examen-1');
      expect(q.versionBrouillon, 5);
      expect(q.champs.length, 17);
    });

    test(
      'un lot serveur non verse (fonction absente) : capacite indisponible',
      () async {
        for (final String code in <String>['PGRST202', '42883']) {
          final MaCandidatureSupabase port = _port(
            (_Appel a) => _erreurPg(code, 'fonction absente', statut: 404),
            <_Appel>[],
          );
          await expectLater(
            port.questionnaire(),
            throwsA(isA<CapaciteIndisponible>()),
            reason: code,
          );
          await expectLater(
            port.conditionsRemuneration(),
            throwsA(isA<CapaciteIndisponible>()),
            reason: code,
          );
        }
      },
    );

    test('42501 : permission insuffisante, jamais un faux contenu', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _erreurPg('42501', 'refuse', statut: 403),
        <_Appel>[],
      );
      await expectLater(
        port.questionnaire(),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('une panne reseau : issue non confirmee', () async {
      final MaCandidatureSupabase port = MaCandidatureSupabase(
        SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          httpClient: MockClient(
            (http.Request r) async => throw http.ClientException('coupe'),
          ),
        ),
      );
      await expectLater(
        port.questionnaire(),
        throwsA(isA<HorsLigneCandidature>()),
      );
    });

    test(
      'les moyens confirmes : virement et operateurs mobiles a part',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final MaCandidatureSupabase port = _port(
          (_Appel a) => _ok(<String, Object>{
            'pays': 'GN',
            'lignes': <Map<String, Object?>>[
              <String, Object?>{
                'methode': 'virement_bancaire',
                'operateur': null,
                'operateurNom': null,
                'devise': 'USD',
              },
              <String, Object?>{
                'methode': 'mobile_money',
                'operateur': 'orange_money',
                'operateurNom': 'Orange Money',
                'devise': 'GNF',
              },
              <String, Object?>{
                'methode': 'mobile_money',
                'operateur': 'orange_money',
                'operateurNom': 'Orange Money',
                'devise': 'USD',
              },
              <String, Object?>{
                'methode': 'mobile_money',
                'operateur': 'wave',
                'operateurNom': ' ',
                'devise': 'GNF',
              },
            ],
          }),
          appels,
        );
        final MoyensConfirmes m = await port.moyensConfirmes('GN');
        expect(appels.single.fonction, 'options_paiement_confirmees');
        expect(appels.single.corps['p_pays'], 'GN');
        expect(m.virementBancaire, isTrue);
        expect(m.aucun, isFalse);
        // Un operateur n'apparait qu'une fois ; sans nom, son code seul.
        expect(m.operateurs.map((OperateurPaiement o) => o.code), <String>[
          'orange_money',
          'wave',
        ]);
        expect(m.operateurs.first.nom, 'Orange Money');
      },
    );

    test('un pays sans ligne confirmee : aucun moyen', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{'pays': 'ML', 'lignes': <Object>[]}),
        <_Appel>[],
      );
      expect((await port.moyensConfirmes('ML')).aucun, isTrue);
    });
  });

  group('ecritures', () {
    test(
      'le brouillon porte la version attendue et rend la suivante',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final MaCandidatureSupabase port = _port(
          (_Appel a) => _ok(<String, Object>{
            'versionBrouillon': 3,
            'questionnaireVersion': 'salle-examen-1',
            'manquants': <String>['paysVersement'],
            'complet': false,
          }),
          appels,
        );
        final ResultatBrouillon r = await port.enregistrerBrouillon(
          versionQuestionnaire: 'salle-examen-1',
          reponses: <String, Object?>{'langueMaternelle': 'poular'},
          versionBrouillon: 2,
          cleIdempotence: 'cand-cle-brouillon',
        );
        expect(appels.single.fonction, 'enregistrer_reponses_salle_examen');
        expect(appels.single.corps['p_version_attendue'], 2);
        expect(appels.single.corps['p_cle_idempotence'], 'cand-cle-brouillon');
        expect(appels.single.corps['p_reponses'], <String, Object?>{
          'langueMaternelle': 'poular',
        });
        expect(r.versionBrouillon, 3);
        expect(r.complet, isFalse);
        expect(r.manquants, <String>['paysVersement']);
      },
    );

    test('un conflit de brouillon rend la version courante', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{
          'erreur': 'conflit_brouillon',
          'versionCourante': 7,
        }),
        <_Appel>[],
      );
      await expectLater(
        port.enregistrerBrouillon(
          versionQuestionnaire: 'salle-examen-1',
          reponses: <String, Object?>{},
          versionBrouillon: 2,
          cleIdempotence: 'cand-k',
        ),
        throwsA(
          isA<ConflitBrouillon>().having(
            (ConflitBrouillon e) => e.versionCourante,
            'version',
            7,
          ),
        ),
      );
    });

    test(
      'l envoi : tous les parametres, et le bloc candidature relu',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final MaCandidatureSupabase port = _port(
          (_Appel a) => _ok(<String, Object>{'candidature': _bloc()}),
          appels,
        );
        final CandidatureDossier c = await port.envoyerReponses(
          versionQuestionnaire: 'salle-examen-1',
          reponses: reponsesCompletesDeTest(),
          accordRemuneration: true,
          versionConditions: 'v2.0.0',
          versionAttendue: 3,
          cleIdempotence: 'cand-cle-envoi',
        );
        final Map<String, dynamic> corps = appels.single.corps;
        expect(appels.single.fonction, 'envoyer_reponses_salle_examen');
        expect(corps['p_questionnaire_version'], 'salle-examen-1');
        expect(corps['p_accord_remuneration'], true);
        expect(corps['p_version_conditions'], 'v2.0.0');
        expect(corps['p_version_attendue'], 3);
        expect(corps['p_cle_idempotence'], 'cand-cle-envoi');
        expect(c.etat, EtatCandidature.enExamen);
        expect(c.version, 4);
      },
    );

    test('une reponse sans le bloc candidature n est pas un succes', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{'ok': true}),
        <_Appel>[],
      );
      await expectLater(
        port.envoyerReponses(
          versionQuestionnaire: 'v',
          reponses: <String, Object?>{},
          accordRemuneration: true,
          versionConditions: 'c',
          versionAttendue: 1,
          cleIdempotence: 'cand-k',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    final Map<String, (Map<String, Object?>, Matcher)> refus =
        <String, (Map<String, Object?>, Matcher)>{
          'conflit_candidature': (
            <String, Object?>{'versionCourante': 9},
            isA<ConflitCandidature>().having(
              (ConflitCandidature e) => e.versionCourante,
              'version',
              9,
            ),
          ),
          'transition_interdite': (
            <String, Object?>{'raison': 'pause'},
            isA<TransitionInterdite>().having(
              (TransitionInterdite e) => e.enPause,
              'pause',
              isTrue,
            ),
          ),
          'questionnaire_perime': (
            <String, Object?>{'versionCourante': 'salle-examen-2'},
            isA<QuestionnairePerime>().having(
              (QuestionnairePerime e) => e.versionCourante,
              'version',
              'salle-examen-2',
            ),
          ),
          'reponses_invalides': (
            <String, Object?>{
              'champs': <String>['paysVersement'],
            },
            isA<ReponsesInvalides>().having(
              (ReponsesInvalides e) => e.champs,
              'champs',
              <String>['paysVersement'],
            ),
          ),
          'reponses_incompletes': (
            <String, Object?>{
              'champs': <String>['publics', 'riwayat'],
            },
            isA<ReponsesIncompletes>().having(
              (ReponsesIncompletes e) => e.champs,
              'champs',
              <String>['publics', 'riwayat'],
            ),
          ),
          'accord_remuneration_requis': (
            <String, Object?>{},
            isA<AccordRemunerationRequis>(),
          ),
          'conditions_indisponibles': (
            <String, Object?>{},
            isA<CapaciteIndisponible>(),
          ),
          'conditions_perimees': (
            <String, Object?>{'versionCourante': 'v3'},
            isA<ConditionsPerimees>().having(
              (ConditionsPerimees e) => e.versionCourante,
              'version',
              'v3',
            ),
          ),
          'engagement_non_accepte': (
            <String, Object?>{'versionRequise': 'c2', 'publie': true},
            isA<EngagementNonAccepte>()
                .having((EngagementNonAccepte e) => e.publie, 'publie', true)
                .having(
                  (EngagementNonAccepte e) => e.versionRequise,
                  'version',
                  'c2',
                ),
          ),
          'absente': (<String, Object?>{}, isA<CandidatureAbsente>()),
          'hors_portee': (<String, Object?>{}, isA<PermissionInsuffisante>()),
        };
    for (final MapEntry<String, (Map<String, Object?>, Matcher)> e
        in refus.entries) {
      test('refus « ${e.key} » : une exception typee', () async {
        final MaCandidatureSupabase port = _port(
          (_Appel a) => _ok(<String, Object?>{'erreur': e.key, ...e.value.$1}),
          <_Appel>[],
        );
        await expectLater(
          port.envoyerReponses(
            versionQuestionnaire: 'v',
            reponses: <String, Object?>{},
            accordRemuneration: true,
            versionConditions: 'c',
            versionAttendue: 1,
            cleIdempotence: 'cand-k',
          ),
          throwsA(e.value.$2),
        );
      });
    }

    test('des plages qui se chevauchent : la cause nommee est lue', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'erreur': 'reponses_invalides',
          'champs': <String>['disponibilitesDeclarees'],
          'motifs': <String, Object?>{
            'disponibilitesDeclarees': 'plages_qui_se_chevauchent',
          },
        }),
        <_Appel>[],
      );
      await expectLater(
        port.enregistrerBrouillon(
          versionQuestionnaire: 'v',
          reponses: <String, Object?>{},
          versionBrouillon: 0,
          cleIdempotence: 'cand-k',
        ),
        throwsA(
          isA<ReponsesInvalides>()
              .having((ReponsesInvalides e) => e.champs, 'champs', <String>[
                'disponibilitesDeclarees',
              ])
              .having(
                (ReponsesInvalides e) => e.plagesQuiSeChevauchent,
                'chevauchement',
                isTrue,
              ),
        ),
      );
    });

    test('sans cause nommee, aucun motif n est invente', () async {
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'erreur': 'reponses_invalides',
          'champs': <String>['riwayat'],
        }),
        <_Appel>[],
      );
      await expectLater(
        port.enregistrerBrouillon(
          versionQuestionnaire: 'v',
          reponses: <String, Object?>{},
          versionBrouillon: 0,
          cleIdempotence: 'cand-k',
        ),
        throwsA(
          isA<ReponsesInvalides>()
              .having((ReponsesInvalides e) => e.motifs, 'motifs', isEmpty)
              .having(
                (ReponsesInvalides e) => e.plagesQuiSeChevauchent,
                'chevauchement',
                isFalse,
              ),
        ),
      );
    });

    test(
      'un refus inconnu n est jamais un succes ni un texte affiche',
      () async {
        final MaCandidatureSupabase port = _port(
          (_Appel a) => _ok(<String, Object>{'erreur': 'inventee'}),
          <_Appel>[],
        );
        await expectLater(
          port.retirer(versionAttendue: 1, cleIdempotence: 'cand-k'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('le retrait : version attendue, cle, et le bloc relu', () async {
      final List<_Appel> appels = <_Appel>[];
      final MaCandidatureSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{
          'candidature': <String, Object>{
            'candidature': true,
            'etape': 'prequalification',
            'issue': 'retiree',
            'version': 5,
          },
        }),
        appels,
      );
      final CandidatureDossier c = await port.retirer(
        versionAttendue: 4,
        cleIdempotence: 'cand-cle-retrait',
      );
      expect(appels.single.fonction, 'retrait_candidat');
      expect(appels.single.corps['p_version_attendue'], 4);
      expect(appels.single.corps['p_cle_idempotence'], 'cand-cle-retrait');
      expect(c.issue, IssueCandidature.retiree);
    });

    test('une cle d idempotence est neuve a chaque appel, 8 a 200 signes', () {
      final String a = nouvelleCleIdempotence();
      final String b = nouvelleCleIdempotence();
      expect(a, isNot(b));
      expect(a.length, inInclusiveRange(8, 200));
      expect(a, startsWith('cand-'));
    });
  });
}
