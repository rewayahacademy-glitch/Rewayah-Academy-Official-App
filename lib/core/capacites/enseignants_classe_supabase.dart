import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../planning/service_planning.dart';
import 'port_enseignants_classe.dart';

/// Charge la proposition depuis la RPC admin; aucun critère d'affectation
/// (genre, langue, fuseau, créneaux) n'est accepté du client.
class EnseignantsClasseSupabase implements PortEnseignantsClasse {
  const EnseignantsClasseSupabase(this._client);

  final SupabaseClient Function() _client;

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required String classeId,
  }) async {
    if (classeId.trim().isEmpty) {
      throw ArgumentError.value(classeId, 'classeId', 'Identifiant requis');
    }

    final List<dynamic> rows = await _client().rpc<List<dynamic>>(
      'enseignants_pour_classe',
      params: <String, dynamic>{'p_classe_id': classeId},
    );
    return rows.map(_enseignantDepuisJson).toList(growable: false);
  }

  EnseignantPropose _enseignantDepuisJson(dynamic raw) {
    if (raw is! Map) {
      throw const FormatException('Proposition enseignant invalide');
    }
    final Map<String, dynamic> row = Map<String, dynamic>.from(raw);
    final String titre = row['titre_public'] as String? ?? '';
    final GenreEnseignant? genre = switch (titre) {
      'sayid' => GenreEnseignant.homme,
      'sayyida' => GenreEnseignant.femme,
      _ => null,
    };
    final String prenom = row['first_name'] as String? ?? '';
    final String nom = row['last_name'] as String? ?? '';
    final String libelle = <String>[titre, prenom, nom]
        .where((String valeur) => valeur.trim().isNotEmpty)
        .join(' ');

    return EnseignantPropose(
      id: row['teacher_id'] as String,
      libelle: libelle,
      identifiant: row['immutable_id'] as String,
      genre: genre,
      classesActives: (row['classes_actives'] as num).toInt(),
      creneauxPris: _creneaux(row['creneaux_pris']),
      creneauxLibres: _creneaux(row['creneaux_libres']),
      fuseauIana: row['timezone_iana'] as String?,
    );
  }

  List<Creneau> _creneaux(dynamic raw) {
    if (raw is! List<dynamic>) {
      throw const FormatException('Liste de créneaux invalide');
    }
    return raw.map((dynamic item) {
      if (item is! Map) {
        throw const FormatException('Créneau invalide');
      }
      return Creneau.depuisJson(Map<String, dynamic>.from(item));
    }).toList(growable: false);
  }
}

/// Fournisseur de production. Le client n'est lu qu'au premier appel RPC.
final Provider<PortEnseignantsClasse> portEnseignantsClasseProvider =
    Provider<PortEnseignantsClasse>(
      (Ref _) => EnseignantsClasseSupabase(() => Supabase.instance.client),
    );
