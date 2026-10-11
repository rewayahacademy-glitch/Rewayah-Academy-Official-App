// Historique du controleur (CTR-05, CTR-06, CT-7) : le modele des rapports
// de mission et le port de lecture.
//
// Un rapport envoye n'est jamais reecrit (C10) : le detail est en lecture,
// seul « Ajouter un complement » l'enrichit (CT-8). Le statut vient du
// serveur, tel quel (doc 08 CTR-05) : Envoye, Complement ajoute, A terminer.
//
// Aucun serveur n'est branche (K-28) : le port par defaut echoue, honnete,
// et la demonstration le remplace. Besoin serveur : `14_controleur/CT-BR.md`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controle/modele_rapport_controle.dart';
import '../../core/controle/port_historique.dart';

export '../../core/controle/modele_rapport_controle.dart';
export '../../core/controle/port_historique.dart';

/// Le port par defaut, sans serveur : tout echoue, rien n'est simule.
class HistoriqueIndisponible implements PortHistorique {
  /// Cree le port.
  const HistoriqueIndisponible();

  @override
  Future<List<RapportControle>> rapports() async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<ComplementRapport> ajouterComplement(
    String rapportId, {
    required String texte,
    String? motif,
  }) async => throw StateError('Aucun serveur branche (BR-1).');
}

/// Le port de l'Historique : neutre par defaut, remplace en demonstration.
final Provider<PortHistorique> portHistoriqueProvider =
    Provider<PortHistorique>((Ref _) => const HistoriqueIndisponible());
