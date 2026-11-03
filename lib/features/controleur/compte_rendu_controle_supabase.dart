// N3, D3 (03/11/2026) : l'envoi du compte rendu du controleur, par
// `controleur_envoyer_compte_rendu` (migration 20261107800000).
//
//   transmettreVisite : la visite part des la sortie de la salle, sans
//                       reponse (decision C2 du 27/09/2026) ;
//   envoyer           : la reponse « Rien a signaler » ;
//   envoyerObservation: une observation (CTR-03A), « Ajouter une
//                       observation » ou « Signaler un point important ».
//
// Une seule reponse par visite. La cle d'envoi est gardee par seance pour la
// duree de l'application : un nouvel essai apres un delai depasse rejoue la
// meme demande, et le serveur rend le meme resultat au lieu d'un doublon.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'compte_rendu_controle.dart';
import 'observation_controle.dart';

/// Le compte rendu, envoye au serveur.
class EnvoiCompteRenduSupabase implements EnvoiCompteRendu {
  /// Cree l'adaptateur.
  EnvoiCompteRenduSupabase(this._client);

  final SupabaseClient _client;
  final Map<String, String> _cles = <String, String>{};

  String _cle(String seanceId) =>
      _cles.putIfAbsent(seanceId, () => const Uuid().v4());

  Future<void> _envoyer(
    String seanceId, {
    String? choix,
    Map<String, dynamic>? observation,
  }) async {
    final Object? brut = await _client.rpc<Object?>(
      'controleur_envoyer_compte_rendu',
      params: <String, dynamic>{
        'p_seance_id': seanceId,
        'p_choix': choix,
        'p_observation': observation,
        'p_cle': choix == null ? null : _cle(seanceId),
      },
    );
    if (brut is! Map || brut['transmise_le'] == null) {
      throw const FormatException('Compte rendu non confirme.');
    }
    if (choix != null && brut['envoye_le'] == null) {
      throw const FormatException('Compte rendu non confirme.');
    }
  }

  @override
  Future<void> transmettreVisite(String seanceId) => _envoyer(seanceId);

  @override
  Future<void> envoyer(String seanceId, ChoixCompteRendu choix) =>
      _envoyer(seanceId, choix: choixServeur(choix));

  @override
  Future<void> envoyerObservation(
    String seanceId,
    ObservationControle observation,
  ) => _envoyer(
    seanceId,
    choix: observation.important ? 'point_important' : 'ajouter_observation',
    observation: observationServeur(observation),
  );
}

/// Le choix tel que le serveur le nomme.
String choixServeur(ChoixCompteRendu choix) => switch (choix) {
  ChoixCompteRendu.rienASignaler => 'rien_a_signaler',
  ChoixCompteRendu.ajouterObservation => 'ajouter_observation',
  ChoixCompteRendu.pointImportant => 'point_important',
};

/// L'observation telle que le serveur la lit.
Map<String, dynamic> observationServeur(ObservationControle o) =>
    <String, dynamic>{
      'nature': switch (o.nature) {
        NatureObservation.pointPositif => 'point_positif',
        NatureObservation.aSuivre => 'a_suivre',
        NatureObservation.interventionAdmin => 'intervention_admin',
      },
      'domaine': switch (o.domaine) {
        DomaineObservation.pedagogie => 'pedagogie',
        DomaineObservation.interaction => 'interaction',
        DomaineObservation.gestionClasse => 'gestion_classe',
        DomaineObservation.respectCadre => 'respect_cadre',
        DomaineObservation.climat => 'climat',
        DomaineObservation.autre => 'autre',
      },
      'personne': switch (o.personne) {
        PersonneConcernee.enseignant => 'enseignant',
        PersonneConcernee.classeEntiere => 'classe_entiere',
        PersonneConcernee.elevePrecis => 'eleve_precis',
        PersonneConcernee.aucun => 'aucun',
      },
      if (o.personne == PersonneConcernee.elevePrecis) 'eleve_id': o.eleveId,
      'texte': o.texte,
    };

/// Le roster de la visite (CTR-03A) : les eleves de la seance observee,
/// prenom et initiale du nom, par `controleur_roster_visite` (N3).
Future<List<EleveRoster>> rosterVisiteSupabase(
  SupabaseClient client,
  String seanceId,
) async {
  final Object? brut = await client.rpc<Object?>(
    'controleur_roster_visite',
    params: <String, dynamic>{'p_seance_id': seanceId},
  );
  if (brut is! List) throw const FormatException('Roster invalide.');
  return rosterDepuis(brut);
}

/// Le roster lu dans la reponse du serveur.
List<EleveRoster> rosterDepuis(List<Object?> lignes) => <EleveRoster>[
  for (final Object? l in lignes)
    if (l is Map && l['id'] is String && l['prenom'] is String)
      EleveRoster(
        id: l['id'] as String,
        prenom: l['prenom'] as String,
        initialeNom: l['initiale'] as String?,
      )
    else
      throw const FormatException('Eleve du roster invalide.'),
];
