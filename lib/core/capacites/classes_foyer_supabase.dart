import 'package:supabase_flutter/supabase_flutter.dart';

import '../tc_groupe/groupes_supabase.dart';
import 'port_classes_foyer.dart';

/// Les classes d'un eleve, depuis ses lignes d'appartenance et la vue des
/// classes du foyer.
///
/// **Pure**, testable sans client. [appartenances] sont les lignes
/// `groupe_membres` de l'eleve encore ouvertes ; [groupes] les lignes de
/// `mes_groupes_famille_v`. Une appartenance dont la classe n'est pas dans la
/// vue (classe close, hors du foyer) est ignoree : rien n'est invente. L'ordre
/// suit [groupes], deja trie par la requete.
List<ClasseFoyer> classesDepuisLignes({
  required String eleveId,
  required List<Map<String, dynamic>> appartenances,
  required List<Map<String, dynamic>> groupes,
}) {
  final Set<String> ids = <String>{
    for (final Map<String, dynamic> ligne in appartenances)
      if (ligne['groupe_id'] case final String id) id,
  };
  return <ClasseFoyer>[
    for (final Map<String, dynamic> ligne in groupes)
      if (ids.contains(ligne['groupe_id']))
        ClasseFoyer(eleveId: eleveId, classe: groupeDepuisLigne(ligne)),
  ];
}

/// L'adaptateur reel du port des classes du foyer (contrat K6).
///
/// Deux lectures sous RLS, aucune ecriture :
///
/// 1. `groupe_membres` : les appartenances **ouvertes** de l'eleve (policy
///    `groupe_membres_lecture`, `0019`, qui ouvre les lignes des eleves du
///    foyer). C'est ce qui dit **quel eleve** est dans quelle classe, ce que
///    la vue seule ne dit pas ;
/// 2. `mes_groupes_famille_v` : l'identite de ces classes (libelle, cours,
///    enseignant, effectif), lue par la meme fonction que l'Espace Groupe
///    (`groupeDepuisLigne`).
///
/// Classes courantes seulement : une classe quittee n'a plus de ligne ouverte
/// (dependance DB-CRS-01 pour l'historique). Chaque `.order` precise son sens.
class ClassesFoyerSupabase implements PortClassesFoyer {
  /// Cree l'adaptateur.
  const ClassesFoyerSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ClasseFoyer>> classesDe(String eleveId) async {
    final List<Map<String, dynamic>> appartenances = await _client
        .from('groupe_membres')
        .select('groupe_id')
        .eq('student_id', eleveId)
        .isFilter('left_at', null)
        .order('joined_at', ascending: true);
    final List<String> ids = <String>[
      for (final Map<String, dynamic> ligne in appartenances)
        if (ligne['groupe_id'] case final String id) id,
    ];
    if (ids.isEmpty) {
      return const <ClasseFoyer>[];
    }
    final List<Map<String, dynamic>> groupes = await _client
        .from(vueMesGroupesFamille)
        .select()
        .inFilter('groupe_id', ids)
        .order('libelle', ascending: true);
    return classesDepuisLignes(
      eleveId: eleveId,
      appartenances: appartenances,
      groupes: groupes,
    );
  }

  @override
  Future<ClasseFoyer?> classe({
    required String groupeId,
    required String eleveId,
  }) async {
    for (final ClasseFoyer c in await classesDe(eleveId)) {
      if (c.classe.groupeId == groupeId) {
        return c;
      }
    }
    return null;
  }
}
