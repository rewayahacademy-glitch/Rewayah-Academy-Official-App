// Presence fictive de la demonstration tuteur (P2-07).
//
// Aucun appel serveur : l'etat se deduit de l'identifiant des seances
// fictives (`demo-seance-<eleve>-<jours>`), passe = finalisee, a venir =
// planifiee. Tout autre identifiant rend `null` (inconnu, invariant J3).

import '../../core/presence/service_presence.dart';

/// Presence hors serveur des seances fictives.
class PresenceDemo implements ServicePresence {
  const PresenceDemo();

  static final RegExp _motif = RegExp(r'^demo-seance-(.+?)-(-?\d+)$');

  @override
  Future<List<PresenceParticipant>?> presence(String seanceId) async {
    final RegExpMatch? m = _motif.firstMatch(seanceId);
    if (m == null) {
      return null;
    }
    final String eleveId = m.group(1)!;
    final int jours = int.parse(m.group(2)!);
    return <PresenceParticipant>[
      PresenceParticipant(
        seanceId: seanceId,
        profilId: eleveId,
        role: 'student',
        prenom: '',
        identifiantImmuable: '',
        etat: jours < 0 ? EtatPresence.finalisee : EtatPresence.planifiee,
        consolide: jours < 0,
      ),
    ];
  }
}
