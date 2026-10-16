import 'package:supabase_flutter/supabase_flutter.dart';

import 'compte_rendu_controle.dart';
import 'historique_controleur.dart';
import 'observation_controle.dart';

/// Adaptateur B-12. Les DTO sont des projections de RPC; aucune table de
/// contacts, KYC ou profil brut n'est interrogée par l'application.
class HistoriqueControleurSupabase implements PortHistorique {
  const HistoriqueControleurSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RapportControle>> rapports() async {
    final Object? value = await _client.rpc<Object?>(
      'controleur_lister_rapports',
    );
    if (value is! List) {
      throw const FormatException('Liste de rapports invalide.');
    }
    return value
        .map((Object? item) {
          if (item is! Map) throw const FormatException('Rapport invalide.');
          return _rapport(Map<String, dynamic>.from(item));
        })
        .toList(growable: false);
  }

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) async {
    final String contenu = texte.trim();
    final String? raison = motif?.trim();
    if (contenu.isEmpty) throw ArgumentError.value(texte, 'texte');
    final Object? value = await _client.rpc<Object?>(
      'controleur_ajouter_complement',
      params: <String, dynamic>{
        'p_rapport_id': rapportId,
        'p_texte': contenu,
        'p_motif': raison == null || raison.isEmpty ? null : raison,
      },
    );
    if (value is! Map) throw const FormatException('Complément invalide.');
    final Map<String, dynamic> row = Map<String, dynamic>.from(value);
    return ComplementRapport(
      date: _date(row, 'date'),
      texte: _string(row, 'texte'),
      motif: row['motif'] as String?,
      auteur: row['auteur'] as String?,
    );
  }
}

RapportControle _rapport(Map<String, dynamic> row) {
  final Object? brutPresents = row['presents'];
  final Object? brutComplements = row['complements'];
  if (brutPresents is! List || brutComplements is! List) {
    throw const FormatException('Projection du rapport invalide.');
  }
  final Object? brutFaits = row['faits'];
  final Object? brutObservation = row['observation'];
  return RapportControle(
    id: _string(row, 'id'),
    missionId: _string(row, 'mission_id'),
    seanceId: row['seance_id'] as String?,
    classe: _string(row, 'classe'),
    enseignant: _string(row, 'enseignant'),
    paysEnseignant: row['pays_enseignant'] as String?,
    debut: _date(row, 'debut'),
    dureeObservee: Duration(seconds: _integer(row, 'duree_observee_secondes')),
    statut: switch (row['statut']) {
      'envoye' => StatutRapport.envoye,
      'complement_ajoute' => StatutRapport.complementAjoute,
      'a_terminer' => StatutRapport.aTerminer,
      _ => throw const FormatException('Statut de rapport inconnu.'),
    },
    faits: brutFaits == null
        ? null
        : _faits(Map<String, dynamic>.from(brutFaits as Map)),
    choix: switch (row['choix']) {
      null => null,
      'rien_a_signaler' => ChoixCompteRendu.rienASignaler,
      'ajouter_observation' => ChoixCompteRendu.ajouterObservation,
      'point_important' => ChoixCompteRendu.pointImportant,
      _ => throw const FormatException('Choix du rapport inconnu.'),
    },
    observation: brutObservation == null
        ? null
        : _observation(Map<String, dynamic>.from(brutObservation as Map)),
    eleve: row['eleve'] as String?,
    presents: brutPresents
        .map((Object? value) {
          if (value is! String) {
            throw const FormatException('Présence invalide.');
          }
          return value;
        })
        .toList(growable: false),
    complements: brutComplements
        .map((Object? item) {
          if (item is! Map) throw const FormatException('Complément invalide.');
          final Map<String, dynamic> complement = Map<String, dynamic>.from(
            item,
          );
          return ComplementRapport(
            date: _date(complement, 'date'),
            texte: _string(complement, 'texte'),
            motif: complement['motif'] as String?,
            auteur: complement['auteur'] as String?,
          );
        })
        .toList(growable: false),
  );
}

FaitsVisite _faits(Map<String, dynamic> row) => FaitsVisite(
  debutPrevu: _date(row, 'debut_prevu'),
  finPrevue: _date(row, 'fin_prevue'),
  debutReel: _date(row, 'debut_reel'),
  finReelle: row['fin_reelle'] == null ? null : _date(row, 'fin_reelle'),
  participantsAttendus: _integer(row, 'participants_attendus'),
  participantsPresents: _integer(row, 'participants_presents'),
  reconnexions: _integer(row, 'reconnexions'),
);

ObservationControle _observation(Map<String, dynamic> row) =>
    ObservationControle(
      important: row['important'] as bool? ?? false,
      nature: switch (row['nature']) {
        'point_positif' => NatureObservation.pointPositif,
        'a_suivre' => NatureObservation.aSuivre,
        'intervention_admin' => NatureObservation.interventionAdmin,
        _ => throw const FormatException('Nature d’observation inconnue.'),
      },
      domaine: switch (row['domaine']) {
        'pedagogie' => DomaineObservation.pedagogie,
        'interaction' => DomaineObservation.interaction,
        'gestion_classe' => DomaineObservation.gestionClasse,
        'respect_cadre' => DomaineObservation.respectCadre,
        'climat' => DomaineObservation.climat,
        'autre' => DomaineObservation.autre,
        _ => throw const FormatException('Domaine d’observation inconnu.'),
      },
      personne: switch (row['personne']) {
        'enseignant' => PersonneConcernee.enseignant,
        'classe_entiere' => PersonneConcernee.classeEntiere,
        'eleve_precis' => PersonneConcernee.elevePrecis,
        'aucun' => PersonneConcernee.aucun,
        _ => throw const FormatException('Personne concernée inconnue.'),
      },
      eleveId: row['eleve_id'] as String?,
      texte: _string(row, 'texte'),
    );

String _string(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  if (value is! String) throw FormatException('Champ $key invalide.');
  return value;
}

int _integer(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  if (value is! int) throw FormatException('Champ $key invalide.');
  return value;
}

DateTime _date(Map<String, dynamic> row, String key) {
  final Object? value = row[key];
  if (value is! String) throw FormatException('Date $key invalide.');
  final DateTime? date = DateTime.tryParse(value);
  if (date == null) throw FormatException('Date $key invalide.');
  return date.toLocal();
}
