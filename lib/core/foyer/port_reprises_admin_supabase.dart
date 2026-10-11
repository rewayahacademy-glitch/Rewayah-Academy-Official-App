import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_reprises_admin.dart';

/// Adaptateur Supabase de la file et des décisions B-04.
class PortReprisesAdminSupabase implements PortReprisesAdmin {
  const PortReprisesAdminSupabase(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<List<RepriseAdmin>> lister() async {
    final Object? resultat = await _client().rpc('lister_reprises_admin');
    if (resultat is! List<Object?>) {
      throw const FormatException('Réponse invalide de lister_reprises_admin');
    }
    return resultat.map(_reprise).toList(growable: false);
  }

  @override
  Future<ResultatDecisionReprise> decider({
    required String repriseId,
    required bool approuver,
    required String cle,
  }) async {
    try {
      final Object? resultat = await _client().rpc(
        'decider_reprise_foyer',
        params: <String, Object?>{
          'p_reprise_id': repriseId,
          'p_approuver': approuver,
          'p_cle': cle,
        },
      );
      if (resultat is! Map<Object?, Object?>) {
        throw const FormatException(
          'Réponse invalide de decider_reprise_foyer',
        );
      }
      return switch (resultat['statut']) {
        'decidee' => const RepriseDecidee(),
        'deja_traitee' => const RepriseDejaTraitee(),
        _ => throw const FormatException(
          'Statut inconnu de decider_reprise_foyer',
        ),
      };
    } on IOException {
      return const RepriseDecisionEchecReseau();
    } on TimeoutException {
      return const RepriseDecisionEchecReseau();
    }
  }

  static RepriseAdmin _reprise(Object? valeur) {
    if (valeur is! Map<Object?, Object?>) {
      throw const FormatException('Ligne invalide de lister_reprises_admin');
    }
    final String? id = valeur['id'] as String?;
    final String? prenom = valeur['demandeur_prenom'] as String?;
    final String? nom = valeur['demandeur_nom'] as String?;
    final String? foyer = valeur['foyer_nom'] as String?;
    final String? statut = valeur['statut'] as String?;
    final bool? decidable = valeur['decidable'] as bool?;
    if (id == null ||
        prenom == null ||
        nom == null ||
        foyer == null ||
        decidable == null) {
      throw const FormatException('Champs requis absents de la reprise');
    }
    final EtatRepriseAdmin etat = switch (statut) {
      'a_examiner' => EtatRepriseAdmin.aExaminer,
      'refusee_par_titulaire' => EtatRepriseAdmin.refuseeParTitulaire,
      _ => throw const FormatException('Statut inconnu de reprise'),
    };
    return RepriseAdmin(
      id: id,
      demandeurPrenom: prenom,
      demandeurNom: nom,
      foyerNom: foyer,
      etat: etat,
      decidable: decidable,
      deposeeLe: _date(valeur['deposee_le']),
      examenPossibleLe: _date(valeur['examen_possible_le']),
    );
  }

  static DateTime? _date(Object? valeur) {
    if (valeur == null) return null;
    if (valeur is! String) {
      throw const FormatException('Date invalide de reprise');
    }
    return DateTime.parse(valeur);
  }
}
