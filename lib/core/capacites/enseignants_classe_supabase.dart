// L'adaptateur Supabase des enseignants proposables pour une classe a creer
// (CLASSE-FORM-1), sur la RPC `enseignants_pour_public(text)` (migration
// 20261016100900). Repris de l'adaptateur Codex (commit 21b8fff1), aligne sur
// le port : le formulaire n'a pas encore de classe, il passe le public.
//
// Le serveur rend tous les enseignants valides, sans filtre de genre : le
// classement et les raisons d'incompatibilite se font a l'ecran
// (`classerEnseignants`, D4). Le genre ne se lit que par le titre public
// (sayyid / sayyida, D3), jamais par `profiles.gender`.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/service_groupes.dart' show TypePublicGroupe;
import '../planning/service_planning.dart' show Creneau;
import 'port_enseignants_classe.dart';

/// Les enseignants proposables servis par Supabase.
class EnseignantsClasseSupabase implements PortEnseignantsClasse {
  /// Cree l'adaptateur sur le client de l'application.
  const EnseignantsClasseSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async {
    final Object? brut = await _client.rpc<Object?>(
      'enseignants_pour_public',
      params: <String, dynamic>{'p_type_public': public.valeurSql},
    );
    if (brut is! List) throw const FormatException('Liste attendue.');
    return List<EnseignantPropose>.unmodifiable(<EnseignantPropose>[
      for (final Object? ligne in brut) enseignantProposeJson(_objet(ligne)),
    ]);
  }
}

/// Une ligne de `enseignants_pour_public`.
EnseignantPropose enseignantProposeJson(Map<String, dynamic> m) {
  final String identifiant = m['immutable_id'] as String? ?? '';
  final String nom = <Object?>[
    m['first_name'],
    m['last_name'],
  ].whereType<String>().join(' ').trim();
  return EnseignantPropose(
    id: m['teacher_id'] as String,
    libelle: nom.isEmpty ? identifiant : nom,
    identifiant: identifiant,
    genre: switch (m['titre_public']) {
      'sayyid' => GenreEnseignant.homme,
      'sayyida' => GenreEnseignant.femme,
      _ => null,
    },
    classesActives: (m['classes_actives'] as num?)?.toInt() ?? 0,
    creneauxPris: _creneaux(m['creneaux_pris']) ?? const <Creneau>[],
    creneauxLibres: _creneaux(m['creneaux_libres']),
    fuseauIana: m['timezone_iana'] as String?,
  );
}

/// Nul quand la source ne rend pas la liste (jamais une liste vide inventee).
List<Creneau>? _creneaux(Object? brut) {
  if (brut is! List) return null;
  return List<Creneau>.unmodifiable(<Creneau>[
    for (final Object? c in brut) Creneau.depuisJson(_objet(c)),
  ]);
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}
