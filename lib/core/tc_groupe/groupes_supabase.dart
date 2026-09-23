import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_summary_vm.dart';
import 'port_groupes.dart';

/// Le nom de la vue serveur qui rend les groupes d'un foyer.
///
/// `mes_groupes_famille_v` (migration `0033`, verifiee presente en production
/// le 23 septembre 2026) : l'eleve et le tuteur de son foyer, filtres par la
/// RLS, sans roster nomme, sans coordonnee, sans paiement.
const String vueMesGroupesFamille = 'mes_groupes_famille_v';

/// Lit une ligne de `mes_groupes_famille_v` en carte de groupe.
///
/// **Fonction pure**, testable sans client : c'est elle qui porte le contrat
/// entre la vue SQL et l'interface. Aucune valeur n'est inventee :
///
/// * `seuil_max` vient de la ligne ; une ligne sans seuil est une ligne
///   invalide, et elle leve plutot que d'afficher « 5 » ;
/// * `prochaineSeance` reste `null` : la vue ne porte aucune occurrence, et
///   l'horloge ne s'obtient que par `horloge_seance(p_session_id)`. Une carte
///   sans occurrence dit « aucune seance planifiee », jamais un compte a
///   rebours fabrique ;
/// * le niveau humain reste `null` tant que la vue ne joint pas
///   `programme_niveaux` : la carte n'affiche alors que le cours.
GroupSummaryVM groupeDepuisLigne(Map<String, dynamic> ligne) {
  final Object? seuil = ligne['seuil_max'];
  if (seuil is! int || seuil <= 0) {
    throw const FormatException('mes_groupes_famille_v : seuil_max absent');
  }
  final Object? nbMembres = ligne['nb_membres'];
  final int? couleur = ligne['couleur_jeton'] as int?;
  final String? prenom = ligne['teacher_prenom'] as String?;

  return GroupSummaryVM(
    groupeId: ligne['groupe_id'] as String,
    libelle: (ligne['libelle'] as String?) ?? '',
    couleurJeton: JetonCouleurGroupe(
      index: couleur ?? 0,
      codeStable: 'g${(couleur ?? 0).toString().padLeft(2, '0')}',
    ),
    enseignant: EnseignantVM(
      enseignantId: (ligne['teacher_id'] as String?) ?? '',
      // `teacher_profiles.titre` est nullable en base : un titre absent est une
      // donnee a completer par l'administration, pas une valeur a deviner. Le
      // repli sur Sayyid est ecrit ici, une seule fois, et signale dans
      // docs/current/08 comme limite de V0.
      titre:
          TitreEnseignant.depuisSql(ligne['teacher_titre'] as String?) ??
          TitreEnseignant.sayyid,
      // Prenom nul quand l'identite est masquee a un agent (`agent_identite_masquee()`).
      nomAffichage: prenom ?? '',
      photoUrlOuCle: ligne['teacher_photo_cle'] as String?,
    ),
    nomCours: ligne['nom_cours'] as String?,
    nombreMembres: nbMembres is int ? nbMembres : 0,
    seuilMax: seuil,
    typePublic:
        TypePublicGroupeVM.depuisSql(ligne['type_public'] as String?) ??
        TypePublicGroupeVM.enfant,
    // La vue exclut deja `ended_at is not null`.
    actif: true,
  );
}

/// L'adaptateur reel du port des groupes.
///
/// Il ne fait qu'une chose : lire la vue et la traduire. Le filtrage par role
/// est serveur (RLS et `est_du_foyer()`), jamais ici. En production c'est lui
/// qui repond ; le double de demonstration ne sort plus du mode Playground.
class GroupesSupabase implements PortGroupes {
  /// Cree l'adaptateur.
  const GroupesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GroupSummaryVM>> mesGroupes() async {
    final List<Map<String, dynamic>> lignes = await _client
        .from(vueMesGroupesFamille)
        .select()
        .order('libelle', ascending: true);
    return lignes.map(groupeDepuisLigne).toList(growable: false);
  }

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) async {
    final Map<String, dynamic>? ligne = await _client
        .from(vueMesGroupesFamille)
        .select()
        .eq('groupe_id', groupeId)
        .maybeSingle();
    return ligne == null ? null : groupeDepuisLigne(ligne);
  }
}
