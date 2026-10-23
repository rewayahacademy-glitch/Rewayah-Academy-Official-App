// ADM-21 : l'adaptateur Supabase de la direction sur la candidature : `lire`,
// `lireContact`, `historique`, `moyensConfirmes` et les dix RPC de gestes de
// CAND-L2A2. Ce que le test prouve :
// - chaque geste part sur SA RPC, avec les parametres que CAND-L2A2 lit, la
//   version attendue et la cle d'idempotence ; un jour part en `AAAA-MM-JJ`,
//   jamais une cle sans le geste qui la porte ;
// - le dossier lu n'a aucun champ de contact, de genre ni de piece ; ce que le
//   serveur ne sert pas encore (`controles`, `piece`) reste nul ;
// - chaque refus RENDU par le serveur devient son exception nommee, avec ce
//   qu'il porte (controles nommes, etat courant, version courante) ; hors
//   portee et absente restent deux erreurs ;
// - 42501 « genre du lecteur inconnu » devient une exception propre, tout autre
//   42501 `PermissionInsuffisante` ; une fonction absente est une capacite
//   indisponible, pas une panne ;
// - un geste sans reponse est « non confirme » ; une lecture sans reponse
//   remonte telle quelle (jamais un faux vide) ;
// - une reponse sans candidature relue n'est pas un succes.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/candidatures_direction_supabase.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
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

/// Un adaptateur dont le serveur repond par [repondre] (ou ne repond pas).
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

/// Un adaptateur dont le reseau est coupe.
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

http.Response _erreurPg(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

Map<String, Object?> _etat({int version = 4, String etat = 'en_examen'}) =>
    <String, Object?>{
      'id': 'c1',
      'reference': 'CAND-00001',
      'type': 'enseignant',
      'etape': 'prequalification',
      'etat': etat,
      'issue': 'en_cours',
      'enPause': false,
      'paiement': 'compatible',
      'version': version,
    };

Map<String, Object?> _succes({int version = 4, bool rejoue = false}) =>
    <String, Object?>{'candidature': _etat(version: version), 'rejoue': rejoue};

Map<String, Object?> _dossier() => <String, Object?>{
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
  'courrielAObtenir': false,
  'indicatifAConfirmer': false,
  'derniereActivite': '2026-10-20T09:00:00.000000Z',
  'recueLe': '2026-10-01T09:00:00.000000Z',
  'version': 3,
  'source': 'lien_public',
  'pauseModele': null,
  'refusModele': null,
  'restrictionCause': null,
  'reponses': <Map<String, Object?>>[
    <String, Object?>{
      'questionnaireVersion': 'salle-examen-1',
      'reponses': <String, Object?>{'langueMaternelle': 'poular'},
      'source': 'candidat',
      'soumisLe': '2026-10-18T14:00:00.000000Z',
    },
  ],
  'controles': null,
  'piece': null,
};

DemandeGeste _demande(GesteCandidature g) {
  const String id = 'c1';
  const int v = 3;
  const String cle = 'cand-cle-de-test';
  switch (g) {
    case GesteCandidature.demanderComplement:
      return DemandeGeste.demanderComplement(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        elements: const <String>['langues', 'versement'],
        motif: 'Preciser.',
      );
    case GesteCandidature.cloreComplement:
      return DemandeGeste.cloreComplement(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        motif: 'Recu.',
      );
    case GesteCandidature.admettreVerifications:
      return DemandeGeste.admettreVerifications(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
      );
    case GesteCandidature.confirmerMoyenPaiement:
      return DemandeGeste.confirmerMoyenPaiement(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        moyen: const MoyenVersement.mobile('orange_money'),
      );
    case GesteCandidature.infirmerMoyenPaiement:
      return DemandeGeste.infirmerMoyenPaiement(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        moyen: const MoyenVersement.virement(),
        motif: 'Compte clos.',
      );
    case GesteCandidature.mettreEnPause:
      return DemandeGeste.mettreEnPause(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        motif: 'Pas de besoin.',
        modele: 'pause_general',
        repriseLe: DateTime(2026, 11, 5),
      );
    case GesteCandidature.leverPause:
      return DemandeGeste.leverPause(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
      );
    case GesteCandidature.refuser:
      return DemandeGeste.refuser(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        motif: 'Niveau.',
        modele: 'refus_niveau',
      );
    case GesteCandidature.consignerRetrait:
      return DemandeGeste.consignerRetrait(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        canal: CanalRetrait.courriel,
        demandeRecueLe: DateTime(2026, 10, 9),
        motif: 'Demande recue.',
      );
    case GesteCandidature.rouvrir:
      return DemandeGeste.rouvrir(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        motif: 'Erreur.',
      );
    case GesteCandidature.definirResponsable:
      return DemandeGeste.definirResponsable(
        candidatureId: id,
        versionAttendue: v,
        cleIdempotence: cle,
        responsableId: 'r1',
      );
  }
}

void main() {
  group('chaque geste part sur sa RPC, avec ses parametres', () {
    final Map<GesteCandidature, (String, Map<String, Object?>)> attendu =
        <GesteCandidature, (String, Map<String, Object?>)>{
          GesteCandidature.demanderComplement: (
            'demander_complement_candidat',
            <String, Object?>{
              'p_elements': <String>['langues', 'versement'],
              'p_motif': 'Preciser.',
            },
          ),
          GesteCandidature.cloreComplement: (
            'demander_complement_candidat',
            <String, Object?>{
              'p_elements': <String>['complement_clos'],
              'p_motif': 'Recu.',
            },
          ),
          GesteCandidature.admettreVerifications: (
            'admettre_salle_verification',
            <String, Object?>{},
          ),
          GesteCandidature.confirmerMoyenPaiement: (
            'confirmer_moyen_paiement_candidat',
            <String, Object?>{
              'p_methode': 'mobile_money',
              'p_operateur': 'orange_money',
            },
          ),
          GesteCandidature.infirmerMoyenPaiement: (
            'infirmer_moyen_paiement_candidat',
            <String, Object?>{
              'p_methode': 'virement_bancaire',
              'p_operateur': null,
              'p_motif': 'Compte clos.',
            },
          ),
          GesteCandidature.mettreEnPause: (
            'mettre_en_pause_candidat',
            <String, Object?>{
              'p_motif': 'Pas de besoin.',
              'p_modele': 'pause_general',
              'p_reprise_le': '2026-11-05',
            },
          ),
          GesteCandidature.leverPause: (
            'lever_pause_candidat',
            <String, Object?>{'p_motif': null},
          ),
          GesteCandidature.refuser: (
            'refuser_candidat',
            <String, Object?>{'p_motif': 'Niveau.', 'p_modele': 'refus_niveau'},
          ),
          GesteCandidature.consignerRetrait: (
            'consigner_retrait_candidat',
            <String, Object?>{
              'p_canal': 'courriel',
              'p_demande_recue_le': '2026-10-09',
              'p_motif': 'Demande recue.',
            },
          ),
          GesteCandidature.rouvrir: (
            'rouvrir_candidat',
            <String, Object?>{'p_motif': 'Erreur.'},
          ),
          GesteCandidature.definirResponsable: (
            'definir_responsable_candidat',
            <String, Object?>{'p_responsable_id': 'r1'},
          ),
        };

    for (final GesteCandidature g in GesteCandidature.values) {
      test(g.name, () async {
        final List<_Appel> appels = <_Appel>[];
        final CandidaturesDirectionSupabase port = _port(
          (_Appel _) => _ok(_succes()),
          appels,
        );
        final ResultatGeste r = await port.geste(_demande(g));
        final _Appel a = appels.single;
        final (String fonction, Map<String, Object?> propres) = attendu[g]!;
        expect(a.fonction, fonction);
        // La version attendue et la cle d'idempotence partent avec CHAQUE geste.
        expect(a.corps['p_id'], 'c1');
        expect(a.corps['p_version_attendue'], 3);
        expect(a.corps['p_cle_idempotence'], 'cand-cle-de-test');
        for (final MapEntry<String, Object?> e in propres.entries) {
          expect(a.corps[e.key], e.value, reason: e.key);
        }
        // Rien d'autre que ce que la RPC lit.
        expect(a.corps.keys.toSet(), <String>{
          'p_id',
          'p_version_attendue',
          'p_cle_idempotence',
          ...propres.keys,
        });
        // Le resultat est la candidature relue au serveur.
        expect(r.candidature.version, 4);
        expect(r.candidature.etat, EtatCandidature.enExamen);
        expect(r.rejoue, isFalse);
      });
    }

    test('une cle rejouee rend le premier resultat, marque rejoue', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(_succes(rejoue: true)),
        <_Appel>[],
      );
      final ResultatGeste r = await port.geste(
        _demande(GesteCandidature.refuser),
      );
      expect(r.rejoue, isTrue);
    });

    test('le complement demande rend ses elements', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          ..._succes(),
          'aCompleter': <String>['langues', 'versement'],
        }),
        <_Appel>[],
      );
      final ResultatGeste r = await port.geste(
        _demande(GesteCandidature.demanderComplement),
      );
      expect(r.elementsDemandes, <String>['langues', 'versement']);
    });
  });

  group('un refus rendu par le serveur devient son exception nommee', () {
    Future<Object> refuse(Map<String, Object?> corps) async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(corps),
        <_Appel>[],
      );
      try {
        await port.geste(_demande(GesteCandidature.admettreVerifications));
      } on Object catch (e) {
        return e;
      }
      fail('un refus devait etre leve');
    }

    test('conflit : la version courante', () async {
      final Object e = await refuse(<String, Object?>{
        'erreur': 'conflit_candidature',
        'versionCourante': 7,
      });
      expect(e, isA<ConflitGeste>());
      expect((e as ConflitGeste).versionCourante, 7);
    });

    test('transition interdite : l\'etat courant nomme, et la pause', () async {
      final Object e = await refuse(<String, Object?>{
        'erreur': 'transition_interdite',
        'geste': 'admettre_verifications',
        'etape': 'prequalification',
        'etat': 'a_completer',
        'issue': 'en_cours',
        'enPause': true,
        'raison': 'pause',
      });
      final GesteInterdit g = e as GesteInterdit;
      expect(g.etape, EtapeCandidature.prequalification);
      expect(g.etat, EtatCandidature.aCompleter);
      expect(g.issue, IssueCandidature.enCours);
      expect(g.enPause, isTrue);
      expect(g.parLaPause, isTrue);
    });

    test('controles non satisfaits : chacun nomme avec sa cause', () async {
      final Object e = await refuse(<String, Object?>{
        'erreur': 'controles_non_satisfaits',
        'controles': <Map<String, Object?>>[
          <String, Object?>{'nom': 'cadre_religieux', 'cause': 'non_accepte'},
          <String, Object?>{'nom': 'paiement_compatible', 'cause': null},
        ],
      });
      final ControlesNonSatisfaits c = e as ControlesNonSatisfaits;
      expect(c.controles, hasLength(2));
      expect(c.controles.first.nom, 'cadre_religieux');
      expect(c.controles.first.cause, 'non_accepte');
      expect(c.controles.last.cause, isNull);
    });

    test('moyen non confirmable : declare ou non, etat de la ligne', () async {
      final Object e = await refuse(<String, Object?>{
        'erreur': 'moyen_non_confirmable',
        'cause': 'ligne_non_confirmee',
        'etatLigne': 'en_verification',
      });
      final MoyenNonConfirmable m = e as MoyenNonConfirmable;
      expect(m.nonDeclare, isFalse);
      expect(m.etatLigne, 'en_verification');
      final Object n = await refuse(<String, Object?>{
        'erreur': 'moyen_non_confirmable',
        'cause': 'non_declare',
      });
      expect((n as MoyenNonConfirmable).nonDeclare, isTrue);
    });

    final Map<String, Matcher> simples = <String, Matcher>{
      'motif_requis': isA<MotifRequis>(),
      'modele_requis': isA<ModeleRequis>(),
      'modele_inconnu': isA<ModeleInconnu>(),
      'elements_requis': isA<ElementsRequis>(),
      'elements_invalides': isA<ElementsInvalides>(),
      'aucun_complement': isA<AucunComplement>(),
      'date_reprise_invalide': isA<RepriseInvalide>(),
      'date_demande_invalide': isA<DateDemandeInvalide>(),
      'moyen_non_declare': isA<MoyenNonDeclare>(),
      'responsable_invalide': isA<ResponsableInvalide>(),
      'cle_idempotence_reutilisee': isA<CleReutilisee>(),
      'absente': isA<CandidatureIntrouvable>(),
      'hors_portee': isA<CandidatureHorsPortee>(),
    };
    for (final MapEntry<String, Matcher> e in simples.entries) {
      test(e.key, () async {
        expect(await refuse(<String, Object?>{'erreur': e.key}), e.value);
      });
    }

    test('hors portee et absente restent deux erreurs distinctes', () async {
      final Object a = await refuse(<String, Object?>{'erreur': 'absente'});
      final Object h = await refuse(<String, Object?>{'erreur': 'hors_portee'});
      expect(a, isNot(isA<CandidatureHorsPortee>()));
      expect(h, isNot(isA<CandidatureIntrouvable>()));
    });

    test('un refus inconnu n\'est jamais pris pour un succes', () async {
      final Object e = await refuse(<String, Object?>{'erreur': 'nouveau'});
      expect(e, isA<FormatException>());
    });

    test('une reponse sans candidature relue n\'est pas un succes', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{'rejoue': false}),
        <_Appel>[],
      );
      await expectLater(
        port.geste(_demande(GesteCandidature.refuser)),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('les refus de la base', () {
    test('42501 « genre du lecteur inconnu » et tout autre 42501', () async {
      final CandidaturesDirectionSupabase genre = _port(
        (_Appel _) => _erreurPg(
          '42501',
          'genre du lecteur inconnu : aucun geste tant qu\'il n\'est pas renseigne',
        ),
        <_Appel>[],
      );
      await expectLater(
        genre.geste(_demande(GesteCandidature.refuser)),
        throwsA(isA<GenreLecteurInconnu>()),
      );
      final CandidaturesDirectionSupabase refus = _port(
        (_Appel _) =>
            _erreurPg('42501', 'gestes reserves a la direction active'),
        <_Appel>[],
      );
      await expectLater(
        refus.geste(_demande(GesteCandidature.refuser)),
        throwsA(isA<PermissionInsuffisante>()),
      );
      await expectLater(
        refus.lire('c1'),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test(
      'une fonction absente (lot non verse) : capacite indisponible',
      () async {
        for (final String code in <String>['PGRST202', '42883']) {
          final CandidaturesDirectionSupabase port = _port(
            (_Appel _) => _erreurPg(code, 'fonction absente', statut: 404),
            <_Appel>[],
          );
          await expectLater(
            port.geste(_demande(GesteCandidature.refuser)),
            throwsA(
              isA<CapaciteIndisponible>().having(
                (CapaciteIndisponible e) => e.dependance,
                'dependance',
                dependanceGestesCandidature,
              ),
            ),
          );
          await expectLater(
            port.lire('c1'),
            throwsA(
              isA<CapaciteIndisponible>().having(
                (CapaciteIndisponible e) => e.dependance,
                'dependance',
                dependanceDetailCandidature,
              ),
            ),
          );
          await expectLater(
            port.historique('c1'),
            throwsA(
              isA<CapaciteIndisponible>().having(
                (CapaciteIndisponible e) => e.dependance,
                'dependance',
                dependanceHistoriqueCandidature,
              ),
            ),
          );
        }
      },
    );

    test('un argument refuse (22023) remonte tel quel', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _erreurPg('22023', 'cle d\'idempotence invalide'),
        <_Appel>[],
      );
      await expectLater(
        port.geste(_demande(GesteCandidature.refuser)),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('un geste sans reponse est non confirme', () async {
      await expectLater(
        _portSansReseau().geste(_demande(GesteCandidature.refuser)),
        throwsA(isA<GesteNonConfirme>()),
      );
    });

    test(
      'une lecture sans reponse remonte telle quelle, jamais un faux vide',
      () async {
        await expectLater(
          _portSansReseau().lire('c1'),
          throwsA(isNot(isA<GesteNonConfirme>())),
        );
        await expectLater(
          _portSansReseau().historique('c1'),
          throwsA(anything),
        );
      },
    );
  });

  group('lecture du dossier', () {
    test(
      'le dossier : aucun contact, aucun genre, les blocs non servis nuls',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final CandidaturesDirectionSupabase port = _port(
          (_Appel _) => _ok(_dossier()),
          appels,
        );
        final DetailCandidature d = await port.lire('c1');
        expect(appels.single.fonction, 'lire_candidature');
        expect(appels.single.corps, <String, Object?>{'p_id': 'c1'});
        expect(d.version, 3);
        expect(d.ligne.reference, 'CAND-00001');
        expect(d.provenance, ProvenanceCandidature.lienPublic);
        expect(d.documents.single.questionnaireVersion, 'salle-examen-1');
        expect(d.documents.single.importe, isFalse);
        expect(d.controles, isNull);
        expect(d.piece, isNull);
        expect(d.blocages, isEmpty);
        // Le serveur ne dit pas le cote : jamais devine.
        expect(d.autreCote, isFalse);
      },
    );

    test('« Vos autres talents » : lues avec le dossier, jamais devinees', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          ..._dossier(),
          'autresCompetences': <String, Object?>{
            'domaines': <String, String>{
              'comptabilite': 'metier',
              'autre': 'debutant',
              // Un niveau que cette version ne connait pas : ignore, pas un
              // niveau presume.
              'assistanat': 'expert',
            },
            'autreTexte': 'Secrétariat médical',
            'disponibilite': 'mi_temps',
            'accord': true,
            'accordLe': '2026-10-22T14:05:00Z',
            'majLe': '2026-10-22T14:05:00Z',
          },
        }),
        <_Appel>[],
      );
      final DetailCandidature d = await port.lire('c1');
      final ReponsesAutresCompetences? r = d.autresCompetences;
      expect(r, isNotNull);
      expect(r!.domaines, <String, NiveauCompetence>{
        'comptabilite': NiveauCompetence.metier,
        'autre': NiveauCompetence.debutant,
      });
      expect(r.autreTexte, 'Secrétariat médical');
      expect(r.disponibilite, DisponibiliteMission.miTemps);
      expect(r.accord, isTrue);
      expect(r.accordLe, DateTime.utc(2026, 10, 22, 14, 5));
    });

    test('sans reponse : aucune competence, jamais un bloc vide', () async {
      for (final Object? brut in <Object?>[
        null,
        <String, Object?>{},
        // Une disponibilite inconnue n'est pas une reponse.
        <String, Object?>{
          'domaines': <String, String>{'comptabilite': 'metier'},
          'disponibilite': 'jamais',
          'accord': true,
        },
      ]) {
        final CandidaturesDirectionSupabase port = _port(
          (_Appel _) => _ok(<String, Object?>{
            ..._dossier(),
            'autresCompetences': brut,
          }),
          <_Appel>[],
        );
        expect((await port.lire('c1')).autresCompetences, isNull);
      }
      // Et un dossier d'avant le lot n'a pas la cle.
      final CandidaturesDirectionSupabase ancien = _port(
        (_Appel _) => _ok(_dossier()),
        <_Appel>[],
      );
      expect((await ancien.lire('c1')).autresCompetences, isNull);
    });

    test('l accord retire reste lu tel quel : pas d accord, pas de date', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          ..._dossier(),
          'autresCompetences': <String, Object?>{
            'domaines': <String, String>{'comptabilite': 'experience'},
            'autreTexte': null,
            'disponibilite': 'pas_maintenant',
            'accord': false,
            'accordLe': null,
            'majLe': '2026-10-22T14:05:00Z',
          },
        }),
        <_Appel>[],
      );
      final ReponsesAutresCompetences r =
          (await port.lire('c1')).autresCompetences!;
      expect(r.accord, isFalse);
      expect(r.accordLe, isNull);
      expect(r.autreTexte, isNull);
      expect(r.disponibilite, DisponibiliteMission.pasMaintenant);
    });

    test('hors portee et absente sont rendues, jamais confondues', () async {
      await expectLater(
        _port(
          (_Appel _) => _ok(<String, Object?>{'erreur': 'hors_portee'}),
          <_Appel>[],
        ).lire('c1'),
        throwsA(isA<CandidatureHorsPortee>()),
      );
      await expectLater(
        _port(
          (_Appel _) => _ok(<String, Object?>{'erreur': 'absente'}),
          <_Appel>[],
        ).lire('c1'),
        throwsA(isA<CandidatureIntrouvable>()),
      );
    });

    test('des controles servis : nom, valeur, cause', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          ..._dossier(),
          'controles': <Map<String, Object?>>[
            <String, Object?>{
              'nom': 'paiement_compatible',
              'valeur': true,
              'cause': null,
            },
            <String, Object?>{
              'nom': 'cadre_religieux',
              'valeur': false,
              'cause': 'non_accepte',
            },
          ],
          'piece': 'a_corriger',
          'autreCote': true,
        }),
        <_Appel>[],
      );
      final DetailCandidature d = await port.lire('c1');
      expect(d.controles, hasLength(2));
      expect(d.blocages.single.nom, 'cadre_religieux');
      expect(d.piece, EtatPiece.aCorriger);
      expect(d.autreCote, isTrue);
    });

    test('une reponse sans version n\'est pas un dossier', () async {
      final Map<String, Object?> sans = _dossier()..remove('version');
      await expectLater(
        _port((_Appel _) => _ok(sans), <_Appel>[]).lire('c1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('le contact : une lecture, ses valeurs validees et brutes', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'courriel': null,
          'telephone': null,
          'courrielBrut': 'amina.diallo@exemple',
          'telephoneBrut': '0771234567',
        }),
        appels,
      );
      final ContactCandidat c = await port.lireContact('c1');
      expect(appels.single.fonction, 'lire_contact_candidature');
      expect(c.courriel, isNull);
      expect(c.courrielAffiche, 'amina.diallo@exemple');
      expect(c.telephoneAffiche, '0771234567');
      expect(c.vide, isFalse);
    });

    test('le contact refuse a la direction non nommee : permission', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _erreurPg(
          '42501',
          'contact des candidatures reserve a la direction nommee',
        ),
        <_Appel>[],
      );
      await expectLater(
        port.lireContact('c1'),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test(
      'l\'historique : le curseur part, l\'auteur est une categorie',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final CandidaturesDirectionSupabase port = _port(
          (_Appel _) => _ok(<String, Object?>{
            'evenements': <Map<String, Object?>>[
              <String, Object?>{
                'id': 9,
                'type': 'transition',
                'quand': '2026-10-19T10:00:00.000000Z',
                'etapeAvant': 'prequalification',
                'etapeApres': 'prequalification',
                'etatAvant': 'en_examen',
                'etatApres': 'a_completer',
                'issueAvant': 'en_cours',
                'issueApres': 'en_cours',
                'auteur': 'direction',
                'motif': 'Preciser.',
              },
              <String, Object?>{'id': 8, 'type': 'creee', 'auteur': 'systeme'},
            ],
            'curseurSuivant': 8,
          }),
          appels,
        );
        final PageHistorique p = await port.historique('c1', curseur: 12);
        expect(appels.single.fonction, 'historique_candidature');
        expect(appels.single.corps, <String, Object?>{
          'p_id': 'c1',
          'p_curseur': 12,
        });
        expect(p.curseurSuivant, 8);
        expect(p.evenements.first.auteur, AuteurEvenement.direction);
        expect(p.evenements.first.motif, 'Preciser.');
        expect(p.evenements.last.auteur, AuteurEvenement.systeme);
        // Sans curseur, aucune cle de curseur.
        final List<_Appel> premiers = <_Appel>[];
        await _port(
          (_Appel _) => _ok(<String, Object?>{
            'evenements': <Object?>[],
            'curseurSuivant': null,
          }),
          premiers,
        ).historique('c1');
        expect(premiers.single.corps, <String, Object?>{'p_id': 'c1'});
      },
    );

    test(
      'les moyens confirmes d\'un pays : virement et operateurs nommes',
      () async {
        final List<_Appel> appels = <_Appel>[];
        final CandidaturesDirectionSupabase port = _port(
          (_Appel _) => _ok(<String, Object?>{
            'pays': 'SN',
            'lignes': <Map<String, Object?>>[
              <String, Object?>{
                'methode': 'virement_bancaire',
                'operateur': null,
                'operateurNom': null,
              },
              <String, Object?>{
                'methode': 'mobile_money',
                'operateur': 'orange_money',
                'operateurNom': 'Orange Money',
              },
            ],
          }),
          appels,
        );
        final MoyensConfirmes m = await port.moyensConfirmes('SN');
        expect(appels.single.fonction, 'options_paiement_confirmees');
        expect(appels.single.corps, <String, Object?>{'p_pays': 'SN'});
        expect(m.virementBancaire, isTrue);
        expect(m.operateurs.single.nom, 'Orange Money');
      },
    );

    test(
      'le responsable : aucune liste n\'est servie par le serveur',
      () async {
        await expectLater(
          _port(
            (_Appel _) => _ok(<String, Object?>{}),
            <_Appel>[],
          ).responsablesPossibles('c1'),
          throwsA(isA<CapaciteIndisponible>()),
        );
      },
    );
  });

  group('la reference d\'une adresse', () {
    test('est resolue par la recherche exacte de la file', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(<String, Object?>{
          'lignes': <Map<String, Object?>>[
            <String, Object?>{..._dossier(), 'id': 'c1'},
          ],
          'total': 1,
          'page': 1,
          'taillePage': 50,
          'compteursEtapes': <String, int>{},
          'compteursAlertes': <String, Object?>{},
        }),
        appels,
      );
      expect(await identifiantDeReference(port, 'CAND‑00001'), 'c1');
      final Map<String, dynamic> filtre =
          appels.single.corps['p_filtre'] as Map<String, dynamic>;
      // Les traits d'union insecables reviennent au trait d'union de la donnee.
      expect(filtre['recherche'], 'CAND-00001');
    });

    test('une reference que la file ne rend pas : absente', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'lignes': <Object?>[],
          'total': 0,
          'page': 1,
          'taillePage': 50,
          'compteursEtapes': <String, int>{},
          'compteursAlertes': <String, Object?>{},
        }),
        <_Appel>[],
      );
      await expectLater(
        identifiantDeReference(port, 'CAND-00099'),
        throwsA(isA<CandidatureIntrouvable>()),
      );
    });
  });
}
