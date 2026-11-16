// BE-S1 : les lectures du serveur pour la file et le dossier de la direction.
// Ce que le test prouve :
// - l'historique lit `details`, `responsableNom` et `responsableAvantNom`
//   quand le serveur les rend, et reste intact sans eux (ancien serveur) ;
// - le dossier lit `responsableNom`, nul sans responsable ;
// - `voisins_candidature` recoit la reference, le filtre et le tri tels que la
//   liste les recoit ; rend precedent, suivant, rang et total ; `hors_liste` est
//   une valeur, `absente` et `hors_portee` sont deux exceptions distinctes ;
//   une fonction absente est une capacite indisponible, jamais une file vide.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/candidatures_direction_supabase.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
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

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, String message) => http.Response(
  jsonEncode(<String, String>{'code': code, 'message': message}),
  400,
  headers: _json,
);

Map<String, Object?> _evenement(
  int id,
  String type, [
  Map<String, Object?>? plus,
]) => <String, Object?>{
  'id': id,
  'type': type,
  'quand': '2026-11-16T10:00:00.000000Z',
  'auteur': 'direction',
  ...?plus,
};

Map<String, Object?> _dossier({String? responsableNom}) => <String, Object?>{
  'id': 'c1',
  'reference': 'CAND-c1',
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
  'responsableId': responsableNom == null ? null : 'r1',
  'courrielAObtenir': true,
  'indicatifAConfirmer': false,
  'derniereActivite': '2026-10-20T09:00:00.000000Z',
  'recueLe': '2026-10-01T09:00:00.000000Z',
  'version': 3,
  'source': 'lien_public',
  'reponses': <Object?>[],
  'responsableNom': responsableNom,
};

void main() {
  group('filtre : les cles BE-S1', () {
    const Map<String, FiltreCandidatures> cas = <String, FiltreCandidatures>{
      'pieceEnAttente': FiltreCandidatures(pieceEnAttente: true),
      'responsable': FiltreCandidatures(responsable: 'moi'),
      'ijaza': FiltreCandidatures(ijaza: 'pret_test'),
      'langueExplication': FiltreCandidatures(langueExplication: 'fr'),
      'riwaya': FiltreCandidatures(riwaya: 'hafs'),
      'public': FiltreCandidatures(publicVise: 'adultes'),
      'jours': FiltreCandidatures(jours: <int>[1, 2]),
      'heureMin': FiltreCandidatures(heureMin: 18),
      'heureMax': FiltreCandidatures(heureMax: 24),
      'joursMin': FiltreCandidatures(joursMin: 4),
    };
    const Map<String, Object> attendu = <String, Object>{
      'pieceEnAttente': true,
      'responsable': 'moi',
      'ijaza': 'pret_test',
      'langueExplication': 'fr',
      'riwaya': 'hafs',
      'public': 'adultes',
      'jours': <int>[1, 2],
      'heureMin': 18,
      'heureMax': 24,
      'joursMin': 4,
    };
    for (final MapEntry<String, FiltreCandidatures> e in cas.entries) {
      test('${e.key} : envoyee seule, avec la valeur posee', () {
        expect(filtreEnJson(e.value), <String, Object>{e.key: attendu[e.key]!});
        expect(e.value.estVide, isFalse);
        expect(e.value.nombreAxes, 1);
      });
    }

    test('absentes par defaut : aucune cle envoyee, filtre vide', () {
      expect(filtreEnJson(const FiltreCandidatures()), isEmpty);
      expect(const FiltreCandidatures().estVide, isTrue);
    });

    test('la phrase du lot : ijaza, le soir, quatre jours', () {
      expect(
        filtreEnJson(
          const FiltreCandidatures(
            ijaza: 'oui',
            heureMin: 18,
            heureMax: 24,
            joursMin: 4,
          ),
        ),
        <String, Object>{
          'ijaza': 'oui',
          'heureMin': 18,
          'heureMax': 24,
          'joursMin': 4,
        },
      );
    });

    test('avec : change un axe, garde les autres, rend null possible', () {
      const FiltreCandidatures base = FiltreCandidatures(
        responsable: 'aucun',
        jours: <int>[3],
        joursMin: 2,
      );
      final FiltreCandidatures change = base.avec(
        responsable: () => 'moi',
        joursMin: () => null,
      );
      expect(change.responsable, 'moi');
      expect(change.jours, <int>[3]);
      expect(change.joursMin, isNull);
      expect(base.avec(pieceEnAttente: () => false).pieceEnAttente, isFalse);
    });

    test(
      'egalite et hachage : deux filtres egaux, listes de jours comprises',
      () {
        const FiltreCandidatures a = FiltreCandidatures(jours: <int>[1, 2]);
        const FiltreCandidatures b = FiltreCandidatures(jours: <int>[1, 2]);
        const FiltreCandidatures c = FiltreCandidatures(jours: <int>[2, 1]);
        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(a == c, isFalse);
        expect(
          const FiltreCandidatures(ijaza: 'oui') ==
              const FiltreCandidatures(ijaza: 'non'),
          isFalse,
        );
        expect(a.efface.estVide, isTrue);
      },
    );

    test('envoyee a lister : le filtre part tel quel dans p_filtre', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'lignes': <Object?>[],
          'total': 0,
          'page': 1,
          'taillePage': 50,
          'compteursEtapes': <String, int>{},
          'compteursAlertes': <String, Object?>{},
        }),
        appels,
      );
      await port.lister(
        filtre: const FiltreCandidatures(
          pieceEnAttente: true,
          responsable: 'moi',
        ),
        tri: TriCandidatures.activite,
        page: 1,
      );
      expect(appels.single.corps['p_filtre'], <String, dynamic>{
        'pieceEnAttente': true,
        'responsable': 'moi',
      });
    });
  });

  group('dossier', () {
    test('lit le nom du responsable, nul sans responsable', () async {
      final CandidaturesDirectionSupabase avec = _port(
        (_Appel _) => _ok(_dossier(responsableNom: 'Direction Un')),
        <_Appel>[],
      );
      expect((await avec.lire('c1')).responsableNom, 'Direction Un');
      final CandidaturesDirectionSupabase sans = _port(
        (_Appel _) => _ok(_dossier()),
        <_Appel>[],
      );
      expect((await sans.lire('c1')).responsableNom, isNull);
    });
  });

  group('historique', () {
    test('lit details, responsableNom et responsableAvantNom', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'evenements': <Object?>[
            _evenement(2, 'responsable', <String, Object?>{
              'details': <String, Object?>{
                'geste': 'definir_responsable',
                'changements': <String, Object?>{
                  'pays_residence': <String, Object?>{
                    'avant': 'FR',
                    'apres': 'BE',
                  },
                },
              },
              'responsableNom': 'Direction Un',
              'responsableAvantNom': 'Direction Trois',
            }),
            _evenement(1, 'controle', <String, Object?>{
              'details': <String, Object?>{
                'controle': 'pays_versement_modifie',
                'paysAvant': 'FR',
                'paysApres': 'BE',
              },
            }),
          ],
          'curseurSuivant': null,
        }),
        <_Appel>[],
      );
      final PageHistorique page = await port.historique('c1');
      expect(page.evenements[0].responsableNom, 'Direction Un');
      expect(page.evenements[0].responsableAvantNom, 'Direction Trois');
      expect(page.evenements[0].details['geste'], 'definir_responsable');
      expect(page.evenements[1].details['paysApres'], 'BE');
      expect(page.evenements[1].responsableNom, isNull);
    });

    test('un ancien serveur sans details : vide, jamais une erreur', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'evenements': <Object?>[_evenement(1, 'transition')],
          'curseurSuivant': null,
        }),
        <_Appel>[],
      );
      final PageHistorique page = await port.historique('c1');
      expect(page.evenements.single.details, isEmpty);
      expect(page.evenements.single.responsableNom, isNull);
    });
  });

  group('voisins', () {
    test('envoie la reference, le filtre et le tri de la liste', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'precedent': 'CAND-A',
          'suivant': 'CAND-C',
          'rang': 2,
          'total': 3,
        }),
        appels,
      );
      final VoisinsCandidature v = await port.voisins(
        'CAND-B',
        filtre: const FiltreCandidatures(paysResidence: 'FR'),
        tri: TriCandidatures.nom,
      );
      expect(appels.single.fonction, 'voisins_candidature');
      expect(appels.single.corps, <String, dynamic>{
        'p_reference': 'CAND-B',
        'p_filtre': <String, dynamic>{'paysResidence': 'FR'},
        'p_tri': TriCandidatures.nom.valeurSql,
      });
      expect(v.precedent, 'CAND-A');
      expect(v.suivant, 'CAND-C');
      expect(v.rang, 2);
      expect(v.total, 3);
      expect(v.horsListe, isFalse);
    });

    test('au debut et a la fin : pas de precedent, pas de suivant', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{
          'precedent': null,
          'suivant': null,
          'rang': 1,
          'total': 1,
        }),
        <_Appel>[],
      );
      final VoisinsCandidature v = await port.voisins(
        'CAND-A',
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.activite,
      );
      expect(v.precedent, isNull);
      expect(v.suivant, isNull);
    });

    test('hors_liste est une valeur, avec rang et total nuls', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel _) => _ok(<String, Object?>{'erreur': 'hors_liste'}),
        <_Appel>[],
      );
      final VoisinsCandidature v = await port.voisins(
        'CAND-A',
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.activite,
      );
      expect(v.horsListe, isTrue);
      expect(v.rang, isNull);
      expect(v.total, isNull);
    });

    test('absente et hors_portee sont deux exceptions distinctes', () async {
      Future<Object?> avec(String erreur) async {
        final CandidaturesDirectionSupabase port = _port(
          (_Appel _) => _ok(<String, Object?>{'erreur': erreur}),
          <_Appel>[],
        );
        try {
          await port.voisins(
            'CAND-A',
            filtre: const FiltreCandidatures(),
            tri: TriCandidatures.activite,
          );
        } on Object catch (e) {
          return e;
        }
        return null;
      }

      expect(await avec('absente'), isA<CandidatureIntrouvable>());
      expect(await avec('hors_portee'), isA<CandidatureHorsPortee>());
    });

    test('une reponse sans rang ni total n est pas des voisins', () {
      expect(
        () => VoisinsCandidature.depuisJson(const <String, Object?>{
          'suivant': 'x',
        }),
        throwsFormatException,
      );
    });

    test(
      'un refus 42501 est un acces refuse ; une fonction absente, indisponible',
      () async {
        final CandidaturesDirectionSupabase refus = _port(
          (_Appel _) => _erreurPg('42501', 'candidatures reservees'),
          <_Appel>[],
        );
        await expectLater(
          refus.voisins(
            'CAND-A',
            filtre: const FiltreCandidatures(),
            tri: TriCandidatures.activite,
          ),
          throwsA(isA<PermissionInsuffisante>()),
        );
        final CandidaturesDirectionSupabase absente = _port(
          (_Appel _) => _erreurPg('PGRST202', 'absente'),
          <_Appel>[],
        );
        await expectLater(
          absente.voisins(
            'CAND-A',
            filtre: const FiltreCandidatures(),
            tri: TriCandidatures.activite,
          ),
          throwsA(isA<CapaciteIndisponible>()),
        );
      },
    );
  });
}
