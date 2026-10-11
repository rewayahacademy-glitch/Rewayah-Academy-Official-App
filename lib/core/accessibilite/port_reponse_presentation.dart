/// BACK-FRONT-AGE-1 (MA-9) : la reponse du tuteur a la demande de presentation
/// standard d'un eleve mineur (MA-8, `port_demande_presentation.dart`).
///
/// Le tuteur voit les demandes en attente de son foyer et les accepte ou les
/// refuse. Aucune date de naissance, aucun age : le client ne lit que la
/// tranche (`age_eleve.dart`) ; ici le serveur dit seulement quelles demandes
/// existent. Un echec n'est jamais presente comme « refuse » : l'enregistrement
/// n'est pas confirme, la demande reste en attente.
///
/// Aucun branchement serveur : en production le port est absent
/// ([portReponsePresentationProvider] vaut `null`) et rien ne s'affiche.
/// Signature proposee en Contrats (C-22).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Une demande de presentation standard en attente.
@immutable
class DemandePresentation {
  /// Cree la demande. [demandeeLe] : heure murale du fuseau du foyer.
  const DemandePresentation({
    required this.id,
    required this.eleveId,
    required this.prenom,
    required this.demandeeLe,
  });

  /// L'identifiant de la demande.
  final String id;

  /// L'eleve qui la fait.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Quand elle a ete faite (heure murale du fuseau du foyer).
  final DateTime demandeeLe;
}

/// Le port de reponse du tuteur.
abstract interface class PortReponsePresentation {
  /// Les demandes en attente du foyer, la plus ancienne d'abord.
  Future<List<DemandePresentation>> enAttente();

  /// Accepte la demande : l'eleve passe a la presentation standard. Leve si
  /// l'enregistrement n'est pas confirme.
  Future<void> accepter(String demandeId);

  /// Refuse la demande. Leve si l'enregistrement n'est pas confirme.
  Future<void> refuser(String demandeId);
}

/// Le port : absent avant le branchement serveur.
final Provider<PortReponsePresentation?> portReponsePresentationProvider =
    Provider<PortReponsePresentation?>((Ref _) => null);

/// Les demandes en attente ; vide sans port.
final FutureProvider<List<DemandePresentation>> demandesPresentationProvider =
    FutureProvider<List<DemandePresentation>>((Ref ref) async {
      final PortReponsePresentation? port = ref.watch(
        portReponsePresentationProvider,
      );
      return port == null ? const <DemandePresentation>[] : port.enAttente();
    });
