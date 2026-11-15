import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/partage_pedagogique_supabase.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Des libelles de test : les codes du serveur, reconnaissables.
class _Libelles implements LibellesPartagePedagogique {
  const _Libelles();

  @override
  String appreciation(String code) => 'apprec:$code';

  @override
  String pointARenforcer(String code) => 'point:$code';

  @override
  String rubrique(String code) => 'rubrique:$code';

  @override
  String valeur(String rubrique, String code) => 'valeur:$rubrique:$code';
}

class _Appels {
  final List<(String, Map<String, dynamic>?)> faits =
      <(String, Map<String, dynamic>?)>[];
}

PartagePedagogiqueSupabase _adaptateur(
  Object? Function(String, Map<String, dynamic>?) reponse, [
  _Appels? appels,
]) {
  Future<Object?> appel(String f, Map<String, dynamic>? p) async {
    appels?.faits.add((f, p));
    return reponse(f, p);
  }

  return PartagePedagogiqueSupabase.avecAppel(
    appel,
    libelles: const _Libelles(),
  );
}

PartagePedagogiqueSupabase _qui(Object erreur) =>
    PartagePedagogiqueSupabase.avecAppel(
      (String f, Map<String, dynamic>? p) => Future<Object?>.error(erreur),
      libelles: const _Libelles(),
    );

Map<String, dynamic> _classe() => <String, dynamic>{
  'classe_id': 'c1',
  'actif': false,
  'version': '3',
  'total': 2,
  'page': 1,
  'modifie_le': '2026-10-18T10:00:00+00:00',
  'eleves': <Map<String, dynamic>>[
    <String, dynamic>{
      'eleve_id': 'e1',
      'libelle': 'Aya A',
      'regle': 'regleClasse',
      'source': 'classe',
      'visible': false,
      'situation': 'actif',
      'modifie_le': null,
    },
    <String, dynamic>{
      'eleve_id': 'e2',
      'libelle': 'Bilal A',
      'regle': 'toujours',
      'source': 'exceptionEleve',
      'visible': true,
      'situation': 'retire',
      'modifie_le': '2026-10-18T09:00:00+00:00',
    },
  ],
};

Map<String, dynamic> _apercu() => <String, dynamic>{
  'seance_id': 's1',
  'eleve_id': 'e1',
  'eleve_prenom': 'Aya',
  'classe_libelle': 'Classe A',
  'seance_le': '2026-10-17T18:00:00+00:00',
  'enseignant': 'Yacine',
  'etat': 'confirmeNonPartage',
  'regle_effective': false,
  'source_regle': 'classe',
  'apercu': <String, dynamic>{
    'travaille': 'Al-Fatiha',
    'appreciation': 'acquis',
    'a_renforcer': <String>['madd'],
    'a_preparer': <String>['Relire'],
    'commentaire_partage': null,
    'corrige_le': null,
  },
  'version': '4',
  'historique': <Map<String, dynamic>>[
    <String, dynamic>{
      'quand': '2026-10-18T08:00:00+00:00',
      'type': 'revocation',
      'auteur': 'Direction',
    },
    <String, dynamic>{
      'quand': '2026-10-17T20:00:00+00:00',
      'type': 'partage_automatique',
      'auteur': null,
    },
  ],
  'mis_a_jour_le': '2026-10-18T08:00:00+00:00',
};

void main() {
  group('compteRenduFamille', () {
    test('decode la projection et nomme les codes', () async {
      final _Appels appels = _Appels();
      final PortPartagePedagogique port = _adaptateur((
        String f,
        Map<String, dynamic>? p,
      ) {
        return <String, dynamic>{
          'etat': 'partage',
          'travaille': 'Lecture',
          'appreciation': 'a_renforcer',
          'a_renforcer': <String>['makharij', 'waqf'],
          'a_preparer': <String>['Page 3'],
          'commentaire_partage': null,
          'corrige_le': '2026-10-18T10:00:00+00:00',
        };
      }, appels);
      final CompteRenduFamille cr = await port.compteRenduFamille(
        seanceId: 's1',
        eleveId: 'e1',
      );
      expect(appels.faits.single.$1, 'compte_rendu_famille');
      expect(appels.faits.single.$2, <String, dynamic>{
        'p_seance_id': 's1',
        'p_eleve_id': 'e1',
      });
      expect(cr.etat, EtatCompteRendu.partage);
      expect(cr.travaille, 'Lecture');
      expect(cr.appreciation, 'apprec:a_renforcer');
      expect(cr.aRenforcer, <String>['point:makharij', 'point:waqf']);
      expect(cr.aPreparer, <String>['Page 3']);
      expect(cr.commentairePartage, isNull);
      expect(cr.corrigeLe, isNotNull);
    });

    test('un etat sans contenu ne lit aucun champ', () async {
      for (final (String code, EtatCompteRendu etat)
          in <(String, EtatCompteRendu)>[
            ('nonPartage', EtatCompteRendu.nonPartage),
            ('enAttente', EtatCompteRendu.enAttente),
            ('aucunChamp', EtatCompteRendu.aucunChamp),
          ]) {
        final CompteRenduFamille cr =
            await _adaptateur(
              (String f, Map<String, dynamic>? p) => <String, dynamic>{
                'etat': code,
                // Meme si le serveur en disait trop, rien ne passe.
                'travaille': 'ne doit pas sortir',
              },
            ).compteRenduFamille(seanceId: 's', eleveId: 'e');
        expect(cr.etat, etat);
        expect(cr.aDuContenu, isFalse);
      }
    });

    test('refuse un etat ou un code inconnu', () async {
      await expectLater(
        _adaptateur(
          (String f, Map<String, dynamic>? p) => <String, dynamic>{
            'etat': 'inventé',
          },
        ).compteRenduFamille(seanceId: 's', eleveId: 'e'),
        throwsFormatException,
      );
      await expectLater(
        _adaptateur(
          (String f, Map<String, dynamic>? p) => <String, dynamic>{
            'etat': 'partage',
            'travaille': null,
            'appreciation': null,
            'a_renforcer': <String>[],
            'a_preparer': <String>[],
            'commentaire_partage': null,
            'corrige_le': null,
          },
        ).compteRenduFamille(seanceId: 's', eleveId: 'e'),
        completes,
      );
      expect(
        () => PartagePedagogiqueSupabase.decoderCompteRenduFamille(
          <String, dynamic>{
            'etat': 'partage',
            'travaille': 'x',
            'appreciation': 'excellent',
            'a_renforcer': <String>[],
            'a_preparer': <String>[],
          },
          const LibellesPartageSlang(),
        ),
        throwsFormatException,
      );
    });
  });

  group('partage de classe', () {
    test('decode le reglage, ses eleves et la version', () async {
      final PartageClasse c = await _adaptateur(
        (String f, Map<String, dynamic>? p) => _classe(),
      ).partageClasse(classeId: 'c1', page: 2, recherche: 'bil');
      expect(c.actif, isFalse);
      expect(c.version, '3');
      expect(c.total, 2);
      expect(c.eleves, hasLength(2));
      expect(c.eleves[0].regle, ReglePartageEleve.regleClasse);
      expect(c.eleves[0].source, SourceRegle.classe);
      expect(c.eleves[1].regle, ReglePartageEleve.toujours);
      expect(c.eleves[1].source, SourceRegle.exceptionEleve);
      expect(c.eleves[1].situation, SituationEleveClasse.retire);
      expect(c.eleves[1].modifieLe, isNotNull);
    });

    test('envoie les bons parametres', () async {
      final _Appels appels = _Appels();
      final PortPartagePedagogique port = _adaptateur(
        (String f, Map<String, dynamic>? p) => _classe(),
        appels,
      );
      await port.partageClasse(classeId: 'c1', page: 2, recherche: 'bil');
      await port.definirPartageClasse(
        classeId: 'c1',
        actif: false,
        versionAttendue: '2',
        cleIdempotence: 'k1',
      );
      await port.definirRegleEleve(
        classeId: 'c1',
        eleveId: 'e1',
        regle: ReglePartageEleve.jamais,
        versionAttendue: '3',
        cleIdempotence: 'k2',
      );
      expect(appels.faits.map((a) => a.$1), <String>[
        'partage_classe',
        'definir_partage_classe',
        'definir_regle_partage_eleve',
      ]);
      expect(appels.faits[0].$2, <String, dynamic>{
        'p_classe_id': 'c1',
        'p_page': 2,
        'p_recherche': 'bil',
      });
      expect(appels.faits[1].$2, <String, dynamic>{
        'p_classe_id': 'c1',
        'p_actif': false,
        'p_version_attendue': '2',
        'p_cle_idempotence': 'k1',
      });
      expect(appels.faits[2].$2, <String, dynamic>{
        'p_classe_id': 'c1',
        'p_eleve_id': 'e1',
        'p_regle': 'jamais',
        'p_version_attendue': '3',
        'p_cle_idempotence': 'k2',
      });
    });

    test('refuse une forme inattendue', () async {
      final Map<String, dynamic> sansVersion = _classe()..remove('version');
      await expectLater(
        _adaptateur(
          (String f, Map<String, dynamic>? p) => sansVersion,
        ).partageClasse(classeId: 'c1'),
        throwsFormatException,
      );
      final Map<String, dynamic> regleInconnue = _classe();
      ((regleInconnue['eleves']! as List<dynamic>)[0]
              as Map<String, dynamic>)['regle'] =
          'peut-etre';
      await expectLater(
        _adaptateur(
          (String f, Map<String, dynamic>? p) => regleInconnue,
        ).partageClasse(classeId: 'c1'),
        throwsFormatException,
      );
    });
  });

  group('erreurs du serveur', () {
    test('42501 devient PermissionInsuffisante', () async {
      await expectLater(
        _qui(
          const PostgrestException(message: 'refuse', code: '42501'),
        ).partageClasse(classeId: 'c1'),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('40001 devient ConflitPartage, sans rien ecrire de plus', () async {
      await expectLater(
        _qui(
          const PostgrestException(message: 'conflit_partage', code: '40001'),
        ).definirPartageClasse(
          classeId: 'c1',
          actif: true,
          versionAttendue: '1',
          cleIdempotence: 'k',
        ),
        throwsA(isA<ConflitPartage>()),
      );
    });

    test('une fonction absente devient CapaciteIndisponible', () async {
      await expectLater(
        _qui(
          const PostgrestException(message: 'absente', code: 'PGRST202'),
        ).compteRenduFamille(seanceId: 's', eleveId: 'e'),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('une panne reseau remonte telle quelle', () async {
      await expectLater(
        _qui(StateError('reseau')).partageClasse(classeId: 'c1'),
        throwsStateError,
      );
    });
  });

  group('cahiers de la direction', () {
    test('liste paginee, filtre par etat', () async {
      final _Appels appels = _Appels();
      final PageCahiersClasse page = await _adaptateur(
        (String f, Map<String, dynamic>? p) => <String, dynamic>{
          'lignes': <Map<String, dynamic>>[
            <String, dynamic>{
              'seance_id': 's1',
              'eleve_id': 'e1',
              'eleve_prenom': 'Aya',
              'seance_le': '2026-10-17T18:00:00+00:00',
              'etat': 'revoque',
            },
          ],
          'total': 51,
          'page': 2,
        },
        appels,
      ).comptesRendusClasse(
        classeId: 'c1',
        page: 2,
        filtreEtat: EtatDiffusion.revoque,
      );
      expect(appels.faits.single.$2, <String, dynamic>{
        'p_classe_id': 'c1',
        'p_page': 2,
        'p_filtre_etat': 'revoque',
      });
      expect(page.total, 51);
      expect(page.page, 2);
      expect(page.lignes.single.etat, EtatDiffusion.revoque);
      expect(page.lignes.single.elevePrenom, 'Aya');
    });

    test('comptes rendus d un eleve', () async {
      final List<LigneCompteRendu> lignes = await _adaptateur(
        (String f, Map<String, dynamic>? p) => <String, dynamic>{
          'lignes': <Map<String, dynamic>>[
            <String, dynamic>{
              'seance_id': 's1',
              'seance_le': '2026-10-17T18:00:00+00:00',
              'etat': 'partageAuto',
            },
          ],
        },
      ).comptesRendusEleve(classeId: 'c1', eleveId: 'e1');
      expect(lignes.single.etat, EtatDiffusion.partageAuto);
    });

    test('cahier brut : rubriques nommees, motif interne separe', () async {
      final CahierAdmin cahier = await _adaptateur(
        (String f, Map<String, dynamic>? p) => <String, dynamic>{
          'seance_id': 's1',
          'eleve_id': 'e1',
          'eleve_prenom': 'Aya',
          'classe_libelle': 'Classe A',
          'seance_le': '2026-10-17T18:00:00+00:00',
          'confirme': true,
          'enseignant': 'Yacine',
          'evaluation': <String, dynamic>{
            'performance': 'enProgres',
            'faiblesses': <String>['madd', 'waqf'],
            'travail_maison': 'Relire la page 3',
            'suite': 'renforcer',
            'cle_inconnue': 'ignoree',
          },
          'details_internes': <Map<String, dynamic>>[
            <String, dynamic>{'libelle': 'Texte du serveur', 'texte': 'secret'},
          ],
          'corrige_le': null,
        },
      ).lireCahierAdmin(seanceId: 's1', eleveId: 'e1');
      expect(cahier.confirme, isTrue);
      expect(cahier.evaluation.map((r) => r.libelle), <String>[
        'rubrique:performance',
        'rubrique:faiblesses',
        'rubrique:travail_maison',
        'rubrique:suite',
      ]);
      expect(cahier.evaluation[0].texte, 'valeur:performance:enProgres');
      expect(cahier.evaluation[1].texte, 'point:madd, point:waqf');
      expect(cahier.detailsInternes.single.libelle, 'rubrique:motif_exception');
      expect(cahier.detailsInternes.single.texte, 'secret');
    });
  });

  group('apercu, publication, revocation', () {
    test('decode l apercu et l historique', () async {
      final ApercuAdmin a = await _adaptateur(
        (String f, Map<String, dynamic>? p) => _apercu(),
      ).apercuFamilial(seanceId: 's1', eleveId: 'e1');
      expect(a.etat, EtatDiffusion.confirmeNonPartage);
      expect(a.regleEffective, isFalse);
      expect(a.sourceRegle, SourceRegle.classe);
      expect(a.version, '4');
      expect(a.apercu.appreciation, 'apprec:acquis');
      expect(a.apercu.aRenforcer, <String>['point:madd']);
      expect(a.publiable, isTrue);
      expect(a.historique, hasLength(2));
      expect(a.historique!.first.type, 'revocation');
      expect(a.historique!.last.auteur, isNull);
    });

    test('un apercu sans champ n est pas un compte rendu vide', () async {
      final Map<String, dynamic> vide = _apercu();
      vide['apercu'] = <String, dynamic>{
        'travaille': null,
        'appreciation': null,
        'a_renforcer': <String>[],
        'a_preparer': <String>[],
        'commentaire_partage': null,
        'corrige_le': null,
      };
      final ApercuAdmin a = await _adaptateur(
        (String f, Map<String, dynamic>? p) => vide,
      ).apercuFamilial(seanceId: 's1', eleveId: 'e1');
      expect(a.apercu.etat, EtatCompteRendu.aucunChamp);
      expect(a.publiable, isFalse);
    });

    test('publier ecrit puis relit l apercu', () async {
      final _Appels appels = _Appels();
      final ApercuAdmin a = await _adaptateur((
        String f,
        Map<String, dynamic>? p,
      ) {
        if (f == 'apercu_familial') return _apercu();
        return <String, dynamic>{'etat': 'partageManuel'};
      }, appels).publier(
        seanceId: 's1',
        eleveId: 'e1',
        versionAttendue: '4',
        cleIdempotence: 'k',
      );
      expect(appels.faits.map((x) => x.$1), <String>[
        'publier_resume_seance',
        'apercu_familial',
      ]);
      expect(appels.faits.first.$2, <String, dynamic>{
        'p_session_id': 's1',
        'p_student_id': 'e1',
        'p_version_attendue': '4',
        'p_cle_idempotence': 'k',
      });
      expect(a.seanceId, 's1');
    });

    test('revoquer ecrit puis relit, et un conflit ne relit rien', () async {
      final _Appels appels = _Appels();
      await _adaptateur((String f, Map<String, dynamic>? p) {
        if (f == 'apercu_familial') return _apercu();
        return <String, dynamic>{'etat': 'revoque'};
      }, appels).revoquer(
        seanceId: 's1',
        eleveId: 'e1',
        versionAttendue: '4',
        cleIdempotence: 'k',
      );
      expect(appels.faits.map((x) => x.$1), <String>[
        'revoquer_resume_seance',
        'apercu_familial',
      ]);

      await expectLater(
        _qui(
          const PostgrestException(message: 'conflit_partage', code: '40001'),
        ).revoquer(
          seanceId: 's1',
          eleveId: 'e1',
          versionAttendue: '1',
          cleIdempotence: 'k',
        ),
        throwsA(isA<ConflitPartage>()),
      );
    });
  });

  group('libelles de l application', () {
    test('tous les codes du serveur ont un mot', () {
      const LibellesPartageSlang l = LibellesPartageSlang();
      for (final String c in <String>['a_renforcer', 'acquis']) {
        expect(l.appreciation(c), isNotEmpty);
      }
      for (final String c in <String>[
        'makharij',
        'madd',
        'ghunna',
        'waqf',
        'fluidite',
        'memorisation',
      ]) {
        expect(l.pointARenforcer(c), isNotEmpty);
      }
      for (final String c in <String>[
        'performance',
        'faiblesses',
        'point_phonetique',
        'travail_maison',
        'objectif_personnel',
        'suite',
        'motif_exception',
      ]) {
        expect(l.rubrique(c), isNotEmpty);
      }
      // Les mots interdits aux familles ne sont jamais ceux de l'appreciation.
      expect(l.appreciation('a_renforcer'), isNot('À revoir'));
      expect(l.appreciation('acquis'), isNot('Maîtrisé'));
    });
  });
}
