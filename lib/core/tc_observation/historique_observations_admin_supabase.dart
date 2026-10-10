import 'package:flutter/material.dart' show DateTimeRange;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'guardian_session_visit.dart';
import 'port_historique_observations.dart';

/// La consultation admin des observations, lue dans `guardian_session_visit`
/// sous la policy `guardian_visit_admin` (`0032_tc_catalogue.sql`), contrat
/// K4, lot E du chantier Tuteur V1.
///
/// **La meme source que l'historique du tuteur, aucun second journal**, et
/// aucune ecriture. Seules les visites des tuteurs (`guardian_observer`) sont
/// lues : les visites de controle ont leur place dans le Journal.
///
/// Pagination par curseur : les visites les plus recentes d'abord (`entered_at`
/// puis `id`, sens **ecrits**, registre section 1 ter bis) ; le curseur est la
/// cle de la derniere visite lue. Une page incomplete est la derniere.
///
/// Groupement : par (seance, **observateur**, enfant). [grouperObservations]
/// seul fondrait les visites de deux responsables du meme enfant a la meme
/// seance ; chaque observateur est donc groupe a part.
///
/// Le provider de production est compose dans
/// `historique_observations_admin_provider.dart`.
class HistoriqueObservationsAdminSupabase
    implements PortHistoriqueObservationsAdmin {
  /// Cree l'adaptateur. Le client est lu a la demande.
  const HistoriqueObservationsAdminSupabase(this._client, {this.parPage = 50});

  final SupabaseClient Function() _client;

  /// Le nombre de visites par page.
  final int parPage;

  static const String _colonnes =
      'id, session_id, groupe_id, observateur_profile_id, role, '
      'enfant_profile_id, entered_at, left_at, duration_seconds, '
      'visit_number, policy_version, fin_de_visite';

  @override
  Future<({List<ObservationsSeance> lignes, String? curseur})> rechercher(
    FiltreObservationsAdmin filtre, {
    String? curseur,
  }) async {
    PostgrestFilterBuilder<List<Map<String, dynamic>>> requete = _client()
        .from('guardian_session_visit')
        .select(_colonnes)
        .eq('role', 'guardian_observer');
    if (filtre.tuteurId case final String id) {
      requete = requete.eq('observateur_profile_id', id);
    }
    if (filtre.eleveId case final String id) {
      requete = requete.eq('enfant_profile_id', id);
    }
    if (filtre.groupeId case final String id) {
      requete = requete.eq('groupe_id', id);
    }
    if (filtre.periode case final DateTimeRange periode) {
      requete = requete
          .gte('entered_at', periode.start.toUtc().toIso8601String())
          .lt('entered_at', periode.end.toUtc().toIso8601String());
    }
    if (filtre.seulementOuvertes) {
      requete = requete.isFilter('left_at', null);
    }
    if (CurseurVisites.lire(curseur) case final CurseurVisites c) {
      requete = requete.or(c.filtre);
    }
    final List<Map<String, dynamic>> lignes = await requete
        .order('entered_at', ascending: false)
        .order('id', ascending: false)
        .limit(parPage);
    return (
      lignes: grouperParObservateur(lignes),
      curseur: lignes.length < parPage
          ? null
          : CurseurVisites.apres(lignes.last)?.ecrire(),
    );
  }
}

/// La cle de la derniere visite lue : `entered_at` puis `id`.
class CurseurVisites {
  /// Cree un curseur.
  const CurseurVisites(this.entree, this.id);

  /// Le curseur apres une ligne brute, ou `null` si elle est incomplete.
  static CurseurVisites? apres(Map<String, dynamic> ligne) {
    final Object? id = ligne['id'];
    final DateTime? entree = DateTime.tryParse(
      ligne['entered_at'] as String? ?? '',
    );
    return id is String && id.isNotEmpty && entree != null
        ? CurseurVisites(entree.toUtc(), id)
        : null;
  }

  /// Relit un curseur ecrit par [ecrire]. `null` s'il est absent ou illisible.
  static CurseurVisites? lire(String? texte) {
    if (texte == null) {
      return null;
    }
    final int coupe = texte.indexOf('|');
    if (coupe <= 0) {
      return null;
    }
    final DateTime? entree = DateTime.tryParse(texte.substring(0, coupe));
    final String id = texte.substring(coupe + 1);
    // Un identifiant est un uuid : rien d'autre ne passe dans le filtre.
    if (entree == null || !RegExp(r'^[0-9a-fA-F-]{1,64}$').hasMatch(id)) {
      return null;
    }
    return CurseurVisites(entree.toUtc(), id);
  }

  /// L'instant d'entree, en UTC.
  final DateTime entree;

  /// L'identifiant de la visite.
  final String id;

  /// Le curseur en texte.
  String ecrire() => '${entree.toIso8601String()}|$id';

  /// Le filtre PostgREST des visites strictement plus anciennes (valeurs
  /// entre guillemets : l'horodatage porte des `:` et des `.`).
  String get filtre {
    final String quand = entree.toIso8601String();
    return 'entered_at.lt."$quand",'
        'and(entered_at.eq."$quand",id.lt."$id")';
  }
}

/// Groupe des lignes brutes par (seance, observateur, enfant), la seance la
/// plus recente d'abord. Chaque observateur passe par [grouperObservations] :
/// une seule regle de groupement et d'ecart des lignes incompletes.
List<ObservationsSeance> grouperParObservateur(
  Iterable<Map<String, dynamic>> lignes,
) {
  final Map<Object?, List<Map<String, dynamic>>> parObservateur =
      <Object?, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> ligne in lignes) {
    parObservateur
        .putIfAbsent(
          ligne['observateur_profile_id'],
          () => <Map<String, dynamic>>[],
        )
        .add(ligne);
  }
  final List<ObservationsSeance> groupes = <ObservationsSeance>[
    for (final List<Map<String, dynamic>> l in parObservateur.values)
      ...grouperObservations(l),
  ];
  DateTime premiere(ObservationsSeance s) => s.visites
      .map((GuardianSessionVisit v) => v.enteredAtUtc)
      .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
  return groupes..sort(
    (ObservationsSeance a, ObservationsSeance b) =>
        premiere(b).compareTo(premiere(a)),
  );
}
