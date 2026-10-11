// Echanges avec l'administration (CTR-04, CT-6) : le modele des fils et le
// port de lecture et d'envoi.
//
// Un fil par mission seulement en V1 (UX_REVIEW_08 question 8) : il nait de
// « Ecrire a l'administration » ou de l'administration. Son titre est la
// Classe et la date de la mission, jamais un nom de personne (question 7).
// Le contexte de la visite est joint par le serveur (P-CTR-06) : le
// controleur ne le recopie pas.
//
// Aucun serveur n'est branche (K-28) : le port par defaut echoue, honnete,
// et la demonstration le remplace. Besoin serveur : `14_controleur/CT-BR.md`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/controle/modele_echanges.dart';
import '../../core/controle/port_echanges.dart';

export '../../core/controle/modele_echanges.dart';
export '../../core/controle/port_echanges.dart';

/// Le port par defaut, sans serveur : tout echoue, rien n'est simule.
class EchangesIndisponibles implements PortEchanges {
  /// Cree le port.
  const EchangesIndisponibles();

  @override
  Future<List<FilEchange>> fils() async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<FilEchange> filDeMission(String missionId) async =>
      throw StateError('Aucun serveur branche (BR-1).');

  @override
  Future<void> envoyer(String filId, String texte) async =>
      throw StateError('Aucun serveur branche (BR-1).');
}

/// Le port des echanges : neutre par defaut, remplace en demonstration.
final Provider<PortEchanges> portEchangesProvider = Provider<PortEchanges>(
  (Ref _) => const EchangesIndisponibles(),
);
