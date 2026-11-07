// SUPPRIMER : l'adaptateur des retraits de comptes (direction et tuteur).
// Noms de fonctions et parametres, decodage strict, refus par compte, refus
// metier du tuteur, erreurs serveur (fonction absente, refus, autre).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/capacites/retraits_comptes_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
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

PostgrestException _pg(String code, [String message = 'x']) =>
    PostgrestException(message: message, code: code);

Map<String, Object?> _ligne({
  bool restaurable = true,
  Object? anonymise,
  Object? restaure,
}) => <String, Object?>{
  'retrait_id': 'r1',
  'profile_id': 'p1',
  'matricule': 'RA-26-4817',
  'nom': 'Awa Bah',
  'role': 'student',
  'source': 'direction',
  'motif': 'Doublon',
  'retire_le': '2026-11-03T10:00:00+00:00',
  'anonymiser_le': '2026-12-03T10:00:00+00:00',
  'anonymise_le': anonymise,
  'restaure_le': restaure,
  'restaurable': restaurable,
};

void main() {
  group('retirer', () {
    test('appelle direction_supprimer_comptes et lit chaque compte', () async {
      final _Faux faux = _Faux(
        (_, _) => <Object?>[
          <String, Object?>{
            'id': 'p1',
            'statut': 'retire',
            'retrait_id': 'r1',
            'anonymiser_le': '2026-12-03T10:00:00+00:00',
          },
          <String, Object?>{
            'id': 'p2',
            'statut': 'refuse',
            'raison': 'seances_a_venir',
            'seances': <Object?>[
              <String, Object?>{'session_id': 's1'},
              <String, Object?>{'session_id': 's2'},
            ],
          },
          <String, Object?>{
            'id': 'p3',
            'statut': 'refuse',
            'raison': 'nouveau',
          },
        ],
      );
      final List<ResultatRetrait> r = await RetraitsComptesSupabase.avecAppel(
        faux.call,
      ).retirer(<String>['p1', 'p2', 'p3'], motif: '  ');
      expect(faux.appels.single.$1, 'direction_supprimer_comptes');
      expect(faux.appels.single.$2, <String, dynamic>{
        'p_ids': <String>['p1', 'p2', 'p3'],
        'p_motif': null,
        'p_anonymiser_maintenant': false,
      });
      expect(r[0].retire, isTrue);
      expect(r[0].anonymiserLe, DateTime.utc(2026, 12, 3, 10).toLocal());
      expect(r[1].retire, isFalse);
      expect(r[1].raison, RaisonRefusRetrait.seancesAVenir);
      expect(r[1].seancesAVenir, 2);
      expect(r[2].raison, RaisonRefusRetrait.erreur);
    });

    test('un statut inconnu est une erreur de format', () async {
      final _Faux faux = _Faux(
        (_, _) => <Object?>[
          <String, Object?>{'id': 'p1', 'statut': 'peut-etre'},
        ],
      );
      expect(
        RetraitsComptesSupabase.avecAppel(faux.call).retirer(<String>['p1']),
        throwsFormatException,
      );
    });

    test('42501 : permission insuffisante ; PGRST202 : indisponible', () async {
      expect(
        RetraitsComptesSupabase.avecAppel(
          _Faux((_, _) => throw _pg('42501')).call,
        ).retirer(<String>['p1']),
        throwsA(isA<PermissionInsuffisante>()),
      );
      expect(
        RetraitsComptesSupabase.avecAppel(
          _Faux((_, _) => throw _pg('PGRST202')).call,
        ).retirer(<String>['p1']),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  group('lister', () {
    test('lit une page, son curseur, et passe le curseur', () async {
      final _Faux faux = _Faux(
        (_, _) => <String, Object?>{
          'lignes': <Object?>[_ligne()],
          'suivant': <String, Object?>{
            'apres_le': '2026-11-03T10:00:00+00:00',
            'apres_id': 'r1',
          },
        },
      );
      final PortRetraitsComptes port = RetraitsComptesSupabase.avecAppel(
        faux.call,
      );
      final PageRetraits page = await port.lister();
      expect(faux.appels.single.$1, 'retraits_comptes_lister');
      expect(faux.appels.single.$2, <String, dynamic>{
        'p_etat': 'en_cours',
        'p_apres_le': null,
        'p_apres_id': null,
      });
      final RetraitCompte l = page.lignes.single;
      expect(l.nom, 'Awa Bah');
      expect(l.role, AppRole.student);
      expect(l.source, SourceRetrait.direction);
      expect(l.restaurable, isTrue);
      expect(page.suivant!.apresId, 'r1');

      await port.lister(etat: EtatRetraits.tous, apres: page.suivant);
      expect(faux.appels.last.$2, <String, dynamic>{
        'p_etat': 'tous',
        'p_apres_le': '2026-11-03T10:00:00.000Z',
        'p_apres_id': 'r1',
      });
    });

    test('sans suivant : derniere page', () async {
      final PageRetraits page = await RetraitsComptesSupabase.avecAppel(
        _Faux(
          (_, _) => <String, Object?>{
            'lignes': <Object?>[
              _ligne(restaurable: false, anonymise: '2026-12-03T10:00:00Z'),
            ],
            'suivant': null,
          },
        ).call,
      ).lister(etat: EtatRetraits.anonymises);
      expect(page.suivant, isNull);
      expect(page.lignes.single.anonymiseLe, isNotNull);
      expect(page.lignes.single.restaurable, isFalse);
    });
  });

  group('restaurer', () {
    test('appelle direction_restaurer_comptes et lit chaque compte', () async {
      final _Faux faux = _Faux(
        (_, _) => <Object?>[
          <String, Object?>{
            'id': 'p1',
            'statut': 'restaure',
            'classes_quittees': 2,
            'classes_a_reaffecter': true,
          },
          <String, Object?>{
            'id': 'p2',
            'statut': 'refuse',
            'raison': 'deja_anonymise',
          },
        ],
      );
      final List<ResultatRestauration> r =
          await RetraitsComptesSupabase.avecAppel(faux.call)
              .restaurer(<String>['p1', 'p2']);
      expect(faux.appels.single.$1, 'direction_restaurer_comptes');
      expect(faux.appels.single.$2, <String, dynamic>{
        'p_ids': <String>['p1', 'p2'],
      });
      expect(r[0].restaure, isTrue);
      expect(r[0].classesQuittees, 2);
      expect(r[1].raison, RaisonRefusRetrait.dejaAnonymise);
    });
  });

  group('supprimerProfilEnfant', () {
    test('appelle tuteur_supprimer_profil_enfant', () async {
      final _Faux faux = _Faux(
        (_, _) => <String, Object?>{'id': 'e1', 'statut': 'retire'},
      );
      expect(
        await RetraitsComptesSupabase.avecAppel(faux.call)
            .supprimerProfilEnfant('e1'),
        ResultatSuppressionEnfant.retire,
      );
      expect(faux.appels.single.$1, 'tuteur_supprimer_profil_enfant');
      expect(faux.appels.single.$2, <String, dynamic>{'p_eleve': 'e1'});
    });

    test('refus metier : hors foyer, deja retire', () async {
      expect(
        await RetraitsComptesSupabase.avecAppel(
          _Faux((_, _) => throw _pg('42501', 'profil_hors_foyer')).call,
        ).supprimerProfilEnfant('e1'),
        ResultatSuppressionEnfant.horsFoyer,
      );
      expect(
        await RetraitsComptesSupabase.avecAppel(
          _Faux((_, _) => throw _pg('55000', 'deja_retire')).call,
        ).supprimerProfilEnfant('e1'),
        ResultatSuppressionEnfant.dejaRetire,
      );
    });

    test('autre 42501 : permission ; autre erreur : remonte', () async {
      expect(
        RetraitsComptesSupabase.avecAppel(
          _Faux((_, _) => throw _pg('42501', 'reservee')).call,
        ).supprimerProfilEnfant('e1'),
        throwsA(isA<PermissionInsuffisante>()),
      );
      expect(
        RetraitsComptesSupabase.avecAppel(
          _Faux((_, _) => throw _pg('XX000')).call,
        ).supprimerProfilEnfant('e1'),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  test("l'implementation par defaut dit indisponible", () {
    expect(
      const RetraitsComptesIndisponibles().lister(),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });
}
