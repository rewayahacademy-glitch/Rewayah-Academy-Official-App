// N1 (02/11/2026) : les capacites Communications servies par le serveur
// (`com_mes_capacites`, migration 20261105400000), branchees dans `main.dart`
// a la place du port neutre.
//
// Le serveur dit quoi RENDRE ; il reste seul juge a l'envoi
// (`com_envoyer_message`, `com_annonce_publier`). Un refus (compte non
// valide, mineur) ou une fonction pas encore installee se lit comme une
// capacite indisponible : le provider rend alors l'ensemble ferme, jamais un
// ensemble invente.

import '../capacites/capacite_indisponible.dart';
import 'capacites_communication.dart';
import 'communications_supabase.dart';

/// Les capacites lues par `com_mes_capacites()`.
class CapacitesCommunicationsSupabase implements PortCapacitesCommunications {
  /// Cree l'adaptateur sur un appel RPC.
  const CapacitesCommunicationsSupabase(this._appel);

  final AppelRpc _appel;

  /// Ce que rend une lecture refusee.
  static const CapaciteIndisponible manque = CapaciteIndisponible('COM-BR-16');

  @override
  Future<CapacitesCommunication> capacites() async {
    final Object? brut;
    try {
      brut = await _appel('com_mes_capacites', <String, dynamic>{});
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw manque;
      rethrow;
    }
    return capacitesCommunicationJson(objetJson(brut));
  }
}

/// Les capacites decrites par le JSON du serveur : seule une valeur `true`
/// ouvre une capacite ; une cle absente ou d'un autre type la laisse fermee.
CapacitesCommunication capacitesCommunicationJson(Map<String, dynamic> m) =>
    CapacitesCommunication(<CapaciteCommunication>{
      if (m['publier_annonce'] == true) CapaciteCommunication.publierAnnonce,
      if (m['programmer'] == true) CapaciteCommunication.programmer,
      if (m['ecrire_dans_fil'] == true) CapaciteCommunication.ecrireDansFil,
      if (m['envoyer_vocal'] == true) CapaciteCommunication.envoyerVocal,
    });
