// CPT-SUPPR-EXPORT : l'adaptateur des demandes de suppression (direction).
// Decodage strict, noms de fonctions et parametres, refus metier mappes,
// erreurs serveur (fonction absente, refus, hors ligne).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_suppressions_admin.dart';
import 'package:rewayah_academy/core/capacites/suppressions_admin_supabase.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> _ligne({
  String statut = 'en_attente',
  Object? situation = const <String, Object?>{
    'solde_du': true,
    'montants_dus': <Object?>[
      <String, Object?>{'devise': 'USD', 'total_mineur': 4500},
    ],
    'seances_a_venir': 2,
  },
}) => <String, Object?>{
  'id': 'd1',
  'statut': statut,
  'motif': 'Nous partons',
  'delai_jours': 14,
  'demandee_le': '2026-10-01T10:00:00+00:00',
  'echeance_le': '2026-10-15T10:00:00+00:00',
  'annulee_le': null,
  'traitee_le': null,
  'profil_id': 'p1',
  'matricule': 'RA-26-4817',
  'role': 'guardian',
  'prenom': 'Awa',
  'nom': 'Bah',
  'delai_ecoule': true,
  'eleves_du_foyer': 2,
  'situation': situation,
};

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

SuppressionsAdminSupabase _adaptateur(_Faux faux) =>
    SuppressionsAdminSupabase.avecAppel(faux.call);

PostgrestException _pg(String code, [String message = 'x']) =>
    PostgrestException(message: message, code: code);

void main() {
  group('lister', () {
    test('decode une demande en attente avec sa situation', () async {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => <Object?>[_ligne()],
      );
      final List<DemandeSuppressionAdmin> l = await _adaptateur(faux).lister();
      expect(faux.appels.single.$1, 'demandes_suppression_lister');
      expect(faux.appels.single.$2, isNull);
      final DemandeSuppressionAdmin d = l.single;
      expect(d.id, 'd1');
      expect(d.statut, StatutSuppression.enAttente);
      expect(d.matricule, 'RA-26-4817');
      expect(d.role, AppRole.guardian);
      expect(d.prenom, 'Awa');
      expect(d.delaiEcoule, isTrue);
      expect(d.elevesDuFoyer, 2);
      expect(d.motif, 'Nous partons');
      expect(d.echeanceLe.toUtc(), DateTime.utc(2026, 10, 15, 10));
      expect(d.situation!.montantsDus, <Montant>[const Montant(4500, 'USD')]);
      expect(d.situation!.seancesAVenir, 2);
      // Des seances a venir : le serveur refuserait, le geste n'est pas ouvert.
      expect(d.traitable, isFalse);
    });

    test('traitable : en attente, delai ecoule, aucune seance', () async {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => <Object?>[
          _ligne(
            situation: <String, Object?>{
              'solde_du': false,
              'montants_dus': <Object?>[],
              'seances_a_venir': 0,
            },
          ),
        ],
      );
      final DemandeSuppressionAdmin d = (await _adaptateur(
        faux,
      ).lister()).single;
      expect(d.traitable, isTrue);
    });

    test('une demande close n a pas de situation', () async {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => <Object?>[
          _ligne(statut: 'traitee', situation: null),
        ],
      );
      final DemandeSuppressionAdmin d = (await _adaptateur(
        faux,
      ).lister()).single;
      expect(d.statut, StatutSuppression.traitee);
      expect(d.situation, isNull);
      expect(d.traitable, isFalse);
    });

    test('un statut inconnu est refuse, pas devine', () async {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => <Object?>[
          _ligne(statut: 'mystere'),
        ],
      );
      expect(_adaptateur(faux).lister(), throwsFormatException);
    });

    test('un role illisible reste nul', () async {
      final Map<String, Object?> ligne = _ligne()..['role'] = 'inconnu';
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => <Object?>[ligne],
      );
      expect((await _adaptateur(faux).lister()).single.role, isNull);
    });

    test('une reponse qui n est pas une liste est refusee', () {
      final _Faux faux = _Faux((String _, Map<String, dynamic>? _) => 'x');
      expect(_adaptateur(faux).lister(), throwsFormatException);
    });

    test('fonction absente : capacite indisponible', () {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => throw _pg('PGRST202'),
      );
      expect(_adaptateur(faux).lister(), throwsA(isA<CapaciteIndisponible>()));
    });

    test('refus 42501 : permission insuffisante', () {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => throw _pg('42501'),
      );
      expect(
        _adaptateur(faux).lister(),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('hors ligne : l erreur remonte telle quelle', () {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) =>
            throw const SocketException('coupe'),
      );
      expect(_adaptateur(faux).lister(), throwsA(isA<SocketException>()));
    });
  });

  group('traiter', () {
    test('envoie p_id et rend traitee', () async {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => <String, Object?>{'id': 'd1'},
      );
      expect(
        await _adaptateur(faux).traiter('d1'),
        ResultatTraitementSuppression.traitee,
      );
      expect(faux.appels.single.$1, 'traiter_demande_suppression');
      expect(faux.appels.single.$2, <String, dynamic>{'p_id': 'd1'});
    });

    final Map<(String, String), ResultatTraitementSuppression> refus =
        <(String, String), ResultatTraitementSuppression>{
          ('55000', 'demande deja traitee '):
              ResultatTraitementSuppression.dejaTraitee,
          ('55000', 'demande deja annulee '):
              ResultatTraitementSuppression.dejaTraitee,
          ('55000', "delai de reflexion en cours jusqu'au 2026-10-15"):
              ResultatTraitementSuppression.delaiEnCours,
          ('55000', "des seances a venir existent : les annuler d'abord"):
              ResultatTraitementSuppression.seancesAVenir,
          ('P0002', 'demande introuvable'):
              ResultatTraitementSuppression.introuvable,
        };
    refus.forEach(((String, String) cle, ResultatTraitementSuppression r) {
      test('refus ${cle.$1} "${cle.$2}" devient ${r.name}', () async {
        final _Faux faux = _Faux(
          (String _, Map<String, dynamic>? _) => throw _pg(cle.$1, cle.$2),
        );
        expect(await _adaptateur(faux).traiter('d1'), r);
      });
    });

    test('42501 : permission insuffisante (pas de double verification)', () {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => throw _pg('42501'),
      );
      expect(
        _adaptateur(faux).traiter('d1'),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('un 55000 inconnu et une coupure remontent, sans faux succes', () {
      final _Faux inconnu = _Faux(
        (String _, Map<String, dynamic>? _) => throw _pg('55000', 'autre'),
      );
      expect(
        _adaptateur(inconnu).traiter('d1'),
        throwsA(isA<PostgrestException>()),
      );
      final _Faux coupe = _Faux(
        (String _, Map<String, dynamic>? _) =>
            throw const SocketException('coupe'),
      );
      expect(_adaptateur(coupe).traiter('d1'), throwsA(isA<SocketException>()));
    });

    test('fonction absente : capacite indisponible', () {
      final _Faux faux = _Faux(
        (String _, Map<String, dynamic>? _) => throw _pg('PGRST202'),
      );
      expect(
        _adaptateur(faux).traiter('d1'),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });
  });

  test('sans adaptateur branche, la fonction est indisponible', () {
    expect(
      const SuppressionsAdminIndisponibles().lister(),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });
}
