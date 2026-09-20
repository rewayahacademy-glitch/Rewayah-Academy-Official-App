// TC-STUB-PORT: canonique = lib/core/tc_observation/port_annonce_observation.dart (Agent G)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 14.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// Ce port est stube et non traite en slot parce que sa chaine de types est
// CLOSE : `AnnonceObservation` ne porte qu'une chaine, une duree et un
// identifiant. C'est le critere de l'AMENDEMENT 2 du contrat.
//
// Cote Agent E, il n'alimente qu'une ligne d'annonce dans l'en-tete de la
// Classe Live : « Tuteur d'Amina observe » et le temps restant. **Pas de
// notification de sortie** (decision D-14).

import 'package:flutter/foundation.dart';

/// Ce que l'enseignant lit d'un observateur present.
@immutable
class AnnonceObservation {
  /// Cree une annonce.
  const AnnonceObservation({
    required this.libelle,
    this.tempsRestant,
    this.enfantConcerneId,
  });

  /// Le libelle deja redige, par exemple « Tuteur d'Amina observe ».
  final String libelle;

  /// Le temps d'observation restant, quand la politique en borne un.
  final Duration? tempsRestant;

  /// L'enfant concerne, pour l'indicateur discret cote eleve.
  final String? enfantConcerneId;
}

/// Les observateurs annonces pendant une seance.
abstract class PortAnnonceObservation {
  /// « Tuteur d'Amina observe » + temps restant. Pas de notification de sortie.
  Stream<List<AnnonceObservation>> annonces(String sessionId);
}
