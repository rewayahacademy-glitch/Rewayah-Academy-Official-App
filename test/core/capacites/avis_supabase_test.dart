// AVIS-PUBLICS : l'adaptateur des avis. Noms de fonctions et parametres,
// decodage strict, erreurs serveur mappees (22023 champ, P0002 lien ferme,
// 55000 etat, 42501 refus, PGRST202 fonction absente), reseau remonte tel quel.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/avis_supabase.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_avis.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Faux {
  _Faux(this.reponse);
  final Object? Function(String, Map<String, dynamic>?) reponse;
  final List<(String, Map<String, dynamic>?)> appels =
      <(String, Map<String, dynamic>?)>[];

  Future<Object?> call(String f, Map<String, dynamic>? p) async {
    appels.add((f, p));
    return reponse(f, p);
  }
}

AvisSupabase _adaptateur(_Faux faux) => AvisSupabase.avecAppel(faux.call);

PostgrestException _pg(String code, [String message = 'x']) =>
    PostgrestException(message: message, code: code);

final DepotAvis _depot = DepotAvis(
  nom: '  Awa B.  ',
  qualite: QualiteAvis.eleveAdulte,
  pays: 'gn',
  depuis: DateTime(2024, 3, 17),
  note: 5,
  titre: '   ',
  texte: '  Un avis assez long pour passer.  ',
  accord: true,
);

Map<String, Object?> _ligneAvis({String statut = 'publie'}) =>
    <String, Object?>{
      'id': 'a1',
      'lien_id': 'l1',
      'lien_libelle': 'Familles octobre 2026',
      'nom_affiche': 'Awa B.',
      'qualite': 'parent',
      'pays': 'GN',
      'depuis': '2024-03-01',
      'note': 4,
      'titre': null,
      'texte': 'Un texte.',
      'accord_public_le': '2026-10-18T09:00:00+00:00',
      'statut': statut,
      'motif': null,
      'depose_le': '2026-10-18T09:00:00+00:00',
      'modere_le': null,
      'modere_par': null,
      'publie_le': null,
    };

void main() {
  group('lien_etat et depot', () {
    test('avis_lien_etat : le jeton part, ouvert revient', () async {
      final _Faux f = _Faux((_, _) => <String, Object?>{'ouvert': true});
      expect(await _adaptateur(f).lienOuvert('abc'), isTrue);
      expect(f.appels.single.$1, 'avis_lien_etat');
      expect(f.appels.single.$2, <String, dynamic>{'p_jeton': 'abc'});
    });

    test('une reponse sans ouvert est refusee', () async {
      final _Faux f = _Faux((_, _) => <String, Object?>{});
      expect(_adaptateur(f).lienOuvert('abc'), throwsA(isA<FormatException>()));
    });

    test('avis_deposer : valeurs nettoyees, mois au premier du mois', () async {
      final _Faux f = _Faux((_, _) => null);
      await _adaptateur(f).deposer('abc', _depot);
      expect(f.appels.single.$1, 'avis_deposer');
      expect(f.appels.single.$2, <String, dynamic>{
        'p_jeton': 'abc',
        'p_nom': 'Awa B.',
        'p_qualite': 'eleve_adulte',
        'p_pays': 'GN',
        'p_depuis': '2024-03-01',
        'p_note': 5,
        'p_titre': null,
        'p_texte': 'Un avis assez long pour passer.',
        'p_accord': true,
      });
    });

    test('22023 nomme le champ ; P0002 dit le lien ferme', () async {
      for (final (String message, ChampAvis? champ) in <(String, ChampAvis?)>[
        ('nom', ChampAvis.nom),
        ('p_pays', ChampAvis.pays),
        ('depuis', ChampAvis.depuis),
        ('note', ChampAvis.note),
        ('texte', ChampAvis.texte),
        ('titre', ChampAvis.titre),
        ('accord', ChampAvis.accord),
        ('qualite', ChampAvis.qualite),
        ('autre chose', null),
      ]) {
        final _Faux f = _Faux((_, _) => throw _pg('22023', message));
        await expectLater(
          _adaptateur(f).deposer('abc', _depot),
          throwsA(
            isA<ChampAvisInvalide>().having(
              (ChampAvisInvalide e) => e.champ,
              'champ',
              champ,
            ),
          ),
          reason: message,
        );
      }
      final _Faux ferme = _Faux((_, _) => throw _pg('P0002'));
      await expectLater(
        _adaptateur(ferme).deposer('abc', _depot),
        throwsA(isA<LienAvisFerme>()),
      );
    });

    test('une panne reseau remonte telle quelle', () async {
      final _Faux f = _Faux((_, _) => throw Exception('reseau'));
      await expectLater(
        _adaptateur(f).deposer('abc', _depot),
        throwsA(isA<Exception>()),
      );
    });

    test('fonction absente : capacite indisponible', () async {
      final _Faux f = _Faux((_, _) => throw _pg('PGRST202'));
      await expectLater(
        _adaptateur(f).lienOuvert('abc'),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('direction', () {
    test('avis_lien_creer : parametres et jeton rendu une fois', () async {
      final _Faux f = _Faux(
        (_, _) => <String, Object?>{
          'id': 'l1',
          'jeton': 'secret',
          'expire_le': '2027-01-17T10:00:00+00:00',
        },
      );
      final LienAvisCree c = await _adaptateur(f)
          .creerLien(libelle: ' Familles ', jours: 90, avisMax: 200);
      expect(f.appels.single.$1, 'avis_lien_creer');
      expect(f.appels.single.$2, <String, dynamic>{
        'p_libelle': 'Familles',
        'p_jours': 90,
        'p_avis_max': 200,
      });
      expect(c.id, 'l1');
      expect(c.jeton, 'secret');
      expect(c.expireLe.toUtc(), DateTime.utc(2027, 1, 17, 10));
    });

    test('avis_liens_lister : decodage strict', () async {
      final _Faux f = _Faux(
        (_, _) => <Object?>[
          <String, Object?>{
            'id': 'l1',
            'libelle': 'Familles',
            'cree_le': '2026-10-01T10:00:00+00:00',
            'expire_le': '2026-12-30T10:00:00+00:00',
            'avis_max': 200,
            'avis_recus': 12,
            'ferme': false,
            'actif': true,
          },
        ],
      );
      final List<LienAvis> liens = await _adaptateur(f).listerLiens();
      expect(f.appels.single.$1, 'avis_liens_lister');
      expect(liens.single.avisRecus, 12);
      expect(liens.single.actif, isTrue);
      final _Faux casse = _Faux(
        (_, _) => <Object?>[
          <String, Object?>{'id': 'l1'},
        ],
      );
      expect(_adaptateur(casse).listerLiens(), throwsA(isA<FormatException>()));
    });

    test('une liste nulle est une liste vide', () async {
      final _Faux f = _Faux((_, _) => null);
      expect(await _adaptateur(f).listerLiens(), isEmpty);
      expect(await _adaptateur(f).listerAvis(), isEmpty);
    });

    test('avis_lien_fermer', () async {
      final _Faux f = _Faux((_, _) => null);
      await _adaptateur(f).fermerLien('l1');
      expect(f.appels.single.$1, 'avis_lien_fermer');
      expect(f.appels.single.$2, <String, dynamic>{'p_id': 'l1'});
    });

    test('avis_lister_admin : filtre et decodage complet', () async {
      final _Faux f = _Faux((_, _) => <Object?>[_ligneAvis()]);
      final List<AvisAdmin> l = await _adaptateur(f)
          .listerAvis(statut: StatutAvis.enAttente);
      expect(f.appels.single.$1, 'avis_lister_admin');
      expect(f.appels.single.$2, <String, dynamic>{'p_statut': 'en_attente'});
      final AvisAdmin a = l.single;
      expect(a.lienLibelle, 'Familles octobre 2026');
      expect(a.nomAffiche, 'Awa B.');
      expect(a.qualite, QualiteAvis.parent);
      expect(a.pays, 'GN');
      expect(a.depuis, DateTime(2024, 3));
      expect(a.note, 4);
      expect(a.titre, isNull);
      expect(a.statut, StatutAvis.publie);
      expect(a.accordPublicLe, isNotNull);
      await _adaptateur(f).listerAvis();
      expect(f.appels.last.$2, <String, dynamic>{'p_statut': null});
    });

    test('un statut ou une qualite inconnus sont refuses', () async {
      final _Faux f = _Faux((_, _) => <Object?>[_ligneAvis(statut: 'autre')]);
      expect(_adaptateur(f).listerAvis(), throwsA(isA<FormatException>()));
    });

    test('avis_moderer : statut, motif nettoye', () async {
      final _Faux f = _Faux((_, _) => null);
      await _adaptateur(f).moderer('a1', StatutAvis.refuse, motif: ' Doublon ');
      expect(f.appels.single.$1, 'avis_moderer');
      expect(f.appels.single.$2, <String, dynamic>{
        'p_id': 'a1',
        'p_statut': 'refuse',
        'p_motif': 'Doublon',
      });
      await _adaptateur(f).moderer('a1', StatutAvis.publie);
      expect(f.appels.last.$2!['p_motif'], isNull);
    });

    test('moderation : refus metier et refus de droit', () async {
      for (final (String code, String message, RefusModeration raison)
          in <(String, String, RefusModeration)>[
            ('P0002', 'avis introuvable', RefusModeration.introuvable),
            ('22023', 'statut', RefusModeration.etatChange),
            ('55000', 'x', RefusModeration.etatChange),
            ('22023', 'motif', RefusModeration.motifManquant),
          ]) {
        final _Faux f = _Faux((_, _) => throw _pg(code, message));
        await expectLater(
          _adaptateur(f).moderer('a1', StatutAvis.publie),
          throwsA(
            isA<ModerationAvisRefusee>().having(
              (ModerationAvisRefusee e) => e.raison,
              'raison',
              raison,
            ),
          ),
          reason: code,
        );
      }
      final _Faux refus = _Faux((_, _) => throw _pg('42501'));
      await expectLater(
        _adaptateur(refus).listerAvis(),
        throwsA(isA<PermissionInsuffisante>()),
      );
      final _Faux reseau = _Faux((_, _) => throw _pg('08006'));
      await expectLater(
        _adaptateur(reseau).moderer('a1', StatutAvis.publie),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
