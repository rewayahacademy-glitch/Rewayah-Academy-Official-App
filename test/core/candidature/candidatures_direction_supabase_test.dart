// ADM-20 : l'adaptateur Supabase de la direction sur `capacites_candidatures` et
// `lister_candidatures` (CAND-L1, redefinies par CAND-L2A2). Ce que le test
// prouve :
// - la forme envoyee : seules les cles que le serveur connait, avec les valeurs
//   ecrites en base, jamais une cle sans valeur (une cle inconnue serait
//   refusee, 22023) ;
// - la forme lue : la ligne n'a aucun champ de contact, de genre ni de piece ;
//   un compteur nul reste nul ; une etape inconnue ne casse pas la liste ;
// - les refus : 42501 « genre du lecteur inconnu » devient une exception propre,
//   tout autre 42501 devient `PermissionInsuffisante` ; une fonction absente
//   (lot non verse) devient une capacite indisponible ; le reste remonte tel
//   quel (jamais un faux vide) ;
// - une reponse sans total, sans page ou sans taille de page n'est pas une
//   page.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/candidatures_direction_supabase.dart';
import 'package:rewayah_academy/core/candidature/modeles_autres_competences.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';
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

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

Map<String, Object?> _ligne(String id, {String etape = 'prequalification'}) =>
    <String, Object?>{
      'id': id,
      'reference': 'CAND-$id',
      'nomComplet': 'Amina Diallo',
      'type': 'enseignant',
      'etape': etape,
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
    };

Map<String, Object?> _page({
  List<Map<String, Object?>>? lignes,
  Object? total = 1,
  Object? page = 1,
  Object? taille = 50,
}) => <String, Object?>{
  'lignes': lignes ?? <Map<String, Object?>>[_ligne('c1')],
  'total': total,
  'page': page,
  'taillePage': taille,
  'compteursEtapes': <String, int>{
    'recue': 0,
    'invitee': 2,
    'prequalification': 5,
    'verifications': 3,
    'confirmee': 1,
  },
  'compteursAlertes': <String, int?>{
    'informationsManquantes': 4,
    'confirmeesIndisponibles': 1,
    'entretiensEnRetard': null,
    'bloquees': null,
  },
};

void main() {
  group('capacites_candidatures', () {
    test('les capacites rendues, une cle absente vaut faux', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{
          'peutLire': true,
          'peutVoirContact': false,
          'peutLireHorsGenre': true,
          'genreLecteurConnu': true,
          'peutDecider': true,
          'peutImporter': false,
          'gestes': <String, bool>{'agirEnLot': true, 'garderPourSuivi': false},
        }),
        appels,
      );
      final CapacitesCandidatures c = await port.capacites();
      expect(appels.single.fonction, 'capacites_candidatures');
      expect(c.peutLire, isTrue);
      expect(c.peutLireHorsGenre, isTrue);
      expect(c.peutAgirEnLot, isTrue);
      expect(c.peutGarderPourSuivi, isFalse);
      expect(c.peutImporter, isFalse);
      expect(c.peutMenerEntretien, isFalse);
    });

    test('avant CAND-L2A2 (sans gestes) : aucun geste, aucun lot', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(<String, Object>{
          'peutLire': true,
          'peutDecider': false,
        }),
        <_Appel>[],
      );
      final CapacitesCandidatures c = await port.capacites();
      expect(c.gestes, isEmpty);
      expect(c.peutAgirEnLot, isFalse);
    });

    test('une fonction absente : capacite indisponible', () async {
      for (final String code in <String>['PGRST202', '42883']) {
        final CandidaturesDirectionSupabase port = _port(
          (_Appel a) => _erreurPg(code, 'fonction absente', statut: 404),
          <_Appel>[],
        );
        await expectLater(
          port.capacites(),
          throwsA(
            isA<CapaciteIndisponible>().having(
              (CapaciteIndisponible e) => e.dependance,
              'dependance',
              dependanceFileCandidatures,
            ),
          ),
          reason: code,
        );
      }
    });
  });

  group('lister_candidatures', () {
    test('un filtre vide n\'envoie aucune cle, tri et page tels quels', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(_page()),
        appels,
      );
      await port.lister(
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.activite,
        page: 1,
      );
      expect(appels.single.fonction, 'lister_candidatures');
      expect(appels.single.corps['p_filtre'], <String, dynamic>{});
      expect(appels.single.corps['p_tri'], 'activite');
      expect(appels.single.corps['p_page'], 1);
    });

    test('chaque axe pose est envoye avec sa valeur ecrite en base', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(_page()),
        appels,
      );
      await port.lister(
        filtre: const FiltreCandidatures(
          recherche: '  amina  ',
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienAPlanifier,
          issue: IssueCandidature.enCours,
          enPause: false,
          paiement: EtatVersement.aVerifier,
          paysResidence: 'SN',
        ),
        tri: TriCandidatures.recente,
        page: 3,
      );
      expect(appels.single.corps['p_filtre'], <String, dynamic>{
        'recherche': 'amina',
        'etape': 'verifications',
        'etat': 'entretien_a_planifier',
        'issue': 'en_cours',
        'enPause': false,
        'paiement': 'a_verifier',
        'paysResidence': 'SN',
      });
      expect(appels.single.corps['p_tri'], 'recente');
      expect(appels.single.corps['p_page'], 3);
    });

    test('seules les cles que le serveur connait partent', () {
      const List<String> connues = <String>[
        'type',
        'etape',
        'etat',
        'issue',
        'enPause',
        'paiement',
        'paysResidence',
        'recherche',
        // CAND-AUTRES : les quatre axes des autres competences.
        'competenceDomaine',
        'competenceNiveauMin',
        'competenceDisponibilite',
        'competenceAccord',
      ];
      final Map<String, Object> envoye = filtreEnJson(
        const FiltreCandidatures(
          recherche: 'x',
          etape: EtapeCandidature.recue,
          etat: EtatCandidature.aCompleter,
          issue: IssueCandidature.retiree,
          enPause: true,
          paiement: EtatVersement.incompatible,
          paysResidence: 'FR',
          competenceDomaine: 'comptabilite',
          competenceNiveauMin: NiveauCompetence.experience,
          competenceDisponibilite: DisponibiliteMission.miTemps,
          competenceAccord: true,
        ),
      );
      expect(connues, containsAll(envoye.keys));
      expect(
        envoye.keys,
        containsAll(<String>[
          'competenceDomaine',
          'competenceNiveauMin',
          'competenceDisponibilite',
          'competenceAccord',
        ]),
      );
    });

    test('les autres competences : un code ou une famille, un niveau, la '
        'disponibilite exacte, l accord, avec leurs valeurs ecrites en base', () {
      expect(
        filtreEnJson(
          const FiltreCandidatures(
            competenceDomaine: 'finances_droit',
            competenceNiveauMin: NiveauCompetence.metier,
            competenceDisponibilite: DisponibiliteMission.plus,
            competenceAccord: true,
          ),
        ),
        <String, Object>{
          'competenceDomaine': 'finances_droit',
          'competenceNiveauMin': 'metier',
          'competenceDisponibilite': 'plus',
          'competenceAccord': true,
        },
      );
    });

    test('une cle sans valeur ne part pas : aucun axe de competence', () {
      expect(filtreEnJson(const FiltreCandidatures()), isEmpty);
      expect(
        filtreEnJson(
          const FiltreCandidatures(competenceNiveauMin: NiveauCompetence.debutant),
        ),
        <String, Object>{'competenceNiveauMin': 'debutant'},
      );
    });

    test('un filtre de competence part avec la page demandee', () async {
      final List<_Appel> appels = <_Appel>[];
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(_page()),
        appels,
      );
      await port.lister(
        filtre: const FiltreCandidatures(
          competenceDomaine: 'comptabilite',
          competenceAccord: true,
        ),
        tri: TriCandidatures.activite,
        page: 2,
      );
      expect(appels.single.corps['p_filtre'], <String, dynamic>{
        'competenceDomaine': 'comptabilite',
        'competenceAccord': true,
      });
      expect(appels.single.corps['p_page'], 2);
    });

    group('la recherche part comme le serveur la compare', () {
      test('une reference copiee a l\'ecran (traits d\'union insecables) retrouve la donnee', () {
        // L'ecran affiche CAND-0000A1 avec des traits d'union insecables
        // (U+2011) ; la donnee et la recherche du serveur gardent le trait
        // d'union ordinaire.
        expect(
          filtreEnJson(const FiltreCandidatures(recherche: ' CAND\u20110000A1 ')),
          <String, Object>{'recherche': 'CAND-0000A1'},
        );
        expect(
          filtreEnJson(const FiltreCandidatures(recherche: 'CAND\u20130000A1')),
          <String, Object>{'recherche': 'CAND-0000A1'},
        );
      });

      test('le serveur refuse plus de 200 caracteres : la recherche est bornee', () {
        final String longue = 'a' * 350;
        final Object? envoye = filtreEnJson(FiltreCandidatures(recherche: longue))['recherche'];
        expect(envoye, isA<String>());
        expect((envoye! as String).length, FiltreCandidatures.longueurRechercheMax);
      });

      test('un nom arabe passe tel quel, sans couper un caractere', () {
        final String arabe = 'م' * 250;
        final String envoye =
            FiltreCandidatures(recherche: arabe).rechercheEnvoyee;
        expect(envoye.runes.length, FiltreCandidatures.longueurRechercheMax);
        expect(filtreEnJson(const FiltreCandidatures(recherche: 'أمينة'))['recherche'], 'أمينة');
      });

      test('seuls des blancs : aucune cle de recherche', () {
        expect(filtreEnJson(const FiltreCandidatures(recherche: '   ')), isEmpty);
      });
    });

    test('la page lue : lignes, total reel, compteurs, rien de personnel', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(
          _page(
            lignes: <Map<String, Object?>>[
              _ligne('c1'),
              _ligne('c2', etape: 'confirmee'),
            ],
            total: 128,
          ),
        ),
        <_Appel>[],
      );
      final PageCandidatures p = await port.lister(
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.activite,
        page: 1,
      );
      expect(p.lignes, hasLength(2));
      expect(p.total, 128);
      expect(p.pages, 3);
      expect(p.debut, 1);
      expect(p.fin, 2);
      expect(p.compteursEtapes[EtapeCandidature.prequalification], 5);
      expect(p.compteursEtapes[EtapeCandidature.invitee], 2);
      expect(p.compteursAlertes.informationsManquantes, 4);
      // Un compteur non servi reste nul : jamais un zero invente.
      expect(p.compteursAlertes.bloquees, isNull);
      expect(p.compteursAlertes.entretiensEnRetard, isNull);
      expect(p.compteursAlertes.tousServis, isFalse);
      final LigneCandidature l = p.lignes.first;
      expect(l.reference, 'CAND-c1');
      expect(l.etape, EtapeCandidature.prequalification);
      expect(l.etat, EtatCandidature.enExamen);
      expect(l.paiement, EtatVersement.aVerifier);
      expect(l.courrielAObtenir, isTrue);
      expect(l.derniereActivite.isUtc, isTrue);
    });

    test('une ligne sans identifiant n\'est pas inventee', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(
          _page(
            lignes: <Map<String, Object?>>[
              _ligne('c1'),
              <String, Object?>{'reference': 'CAND-x'},
            ],
          ),
        ),
        <_Appel>[],
      );
      final PageCandidatures p = await port.lister(
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.activite,
        page: 1,
      );
      expect(p.lignes, hasLength(1));
    });

    test('une etape que cette version ne connait pas ne casse pas la liste', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _ok(
          _page(lignes: <Map<String, Object?>>[_ligne('c1', etape: 'future')]),
        ),
        <_Appel>[],
      );
      final PageCandidatures p = await port.lister(
        filtre: const FiltreCandidatures(),
        tri: TriCandidatures.activite,
        page: 1,
      );
      expect(p.lignes.single.etape, isNull);
    });

    test('une reponse sans total, sans page ou sans taille n\'est pas une page', () async {
      for (final Map<String, Object?> corps in <Map<String, Object?>>[
        _page(total: null),
        _page(page: null),
        _page(taille: 0),
        <String, Object?>{'lignes': <Object?>[]},
      ]) {
        final CandidaturesDirectionSupabase port = _port(
          (_Appel a) => _ok(corps),
          <_Appel>[],
        );
        await expectLater(
          port.lister(
            filtre: const FiltreCandidatures(),
            tri: TriCandidatures.activite,
            page: 1,
          ),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('42501 « genre du lecteur inconnu » : exception propre', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _erreurPg(
          '42501',
          'genre du lecteur inconnu : aucune candidature lisible tant qu\'il n\'est pas renseigne',
          statut: 403,
        ),
        <_Appel>[],
      );
      await expectLater(
        port.lister(
          filtre: const FiltreCandidatures(),
          tri: TriCandidatures.activite,
          page: 1,
        ),
        throwsA(isA<GenreLecteurInconnu>()),
      );
    });

    test('tout autre 42501 : permission insuffisante', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _erreurPg(
          '42501',
          'candidatures reservees a la direction active',
          statut: 403,
        ),
        <_Appel>[],
      );
      await expectLater(
        port.lister(
          filtre: const FiltreCandidatures(),
          tri: TriCandidatures.activite,
          page: 1,
        ),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('un lot serveur non verse : capacite indisponible, pas une liste vide', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _erreurPg('PGRST202', 'fonction absente', statut: 404),
        <_Appel>[],
      );
      await expectLater(
        port.lister(
          filtre: const FiltreCandidatures(),
          tri: TriCandidatures.activite,
          page: 1,
        ),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('un filtre refuse (22023) remonte tel quel', () async {
      final CandidaturesDirectionSupabase port = _port(
        (_Appel a) => _erreurPg('22023', 'filtre de candidatures inconnu : alerte'),
        <_Appel>[],
      );
      await expectLater(
        port.lister(
          filtre: const FiltreCandidatures(),
          tri: TriCandidatures.activite,
          page: 1,
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('une panne reseau remonte : l\'ecran ne montre pas un faux vide', () async {
      final CandidaturesDirectionSupabase port = CandidaturesDirectionSupabase(
        SupabaseClient(
          'https://exemple.supabase.co',
          'cle-anonyme',
          httpClient: MockClient(
            (http.Request r) async => throw http.ClientException('coupe'),
          ),
        ),
      );
      await expectLater(
        port.lister(
          filtre: const FiltreCandidatures(),
          tri: TriCandidatures.activite,
          page: 1,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('modeles', () {
    test('le filtre : egalite, axes poses, effacement', () {
      const FiltreCandidatures a = FiltreCandidatures(recherche: ' x ');
      const FiltreCandidatures b = FiltreCandidatures(recherche: 'x');
      expect(a, b);
      expect(a.nombreAxes, 1);
      expect(a.estVide, isFalse);
      expect(a.efface.estVide, isTrue);
      expect(
        a.avec(etape: () => EtapeCandidature.confirmee).nombreAxes,
        2,
      );
      expect(
        a.avec(etape: () => EtapeCandidature.confirmee).avec(etape: () => null),
        a,
      );
    });

    test('le filtre : les quatre axes de competence se comptent, se '
        'comparent et s efface', () {
      const FiltreCandidatures vide = FiltreCandidatures();
      final FiltreCandidatures f = vide
          .avec(competenceDomaine: () => 'comptabilite')
          .avec(competenceNiveauMin: () => NiveauCompetence.experience)
          .avec(competenceDisponibilite: () => DisponibiliteMission.miTemps)
          .avec(competenceAccord: () => true);
      expect(f.estVide, isFalse);
      expect(f.nombreAxes, 4);
      expect(f.efface, vide);
      expect(f.efface.estVide, isTrue);
      // Un axe de plus : un autre filtre, donc une autre lecture.
      expect(f, isNot(f.avec(competenceAccord: () => null)));
      expect(f.avec(competenceAccord: () => null).nombreAxes, 3);
      expect(f.hashCode, equals(
        vide
            .avec(competenceDomaine: () => 'comptabilite')
            .avec(competenceNiveauMin: () => NiveauCompetence.experience)
            .avec(competenceDisponibilite: () => DisponibiliteMission.miTemps)
            .avec(competenceAccord: () => true)
            .hashCode,
      ));
    });

    test('la requete : deux requetes egales partagent leur lecture', () {
      expect(
        const RequeteCandidatures(page: 2),
        const RequeteCandidatures(page: 2),
      );
      expect(
        const RequeteCandidatures(page: 2),
        isNot(const RequeteCandidatures(page: 3)),
      );
    });

    test('une page vide : une page, aucune ligne', () {
      const PageCandidatures p = PageCandidatures(
        lignes: <LigneCandidature>[],
        total: 0,
        page: 1,
        taillePage: 50,
        compteursEtapes: <EtapeCandidature, int>{},
        compteursAlertes: CompteursAlertes(),
      );
      expect(p.pages, 1);
      expect(p.debut, 0);
      expect(p.fin, 0);
    });
  });
}
