import 'package:flutter/foundation.dart';

import '../tc_horloge/session_clock_vm.dart';

/// Le cours en cours, independamment de l'ecran affiche.
///
/// C'est ce que lit la barre compacte « Cours en cours » : de quoi nommer le
/// groupe, dire le temps restant, et y revenir d'un geste.
@immutable
class SessionEnCours {
  /// Declare un cours en cours.
  const SessionEnCours({
    required this.sessionId,
    required this.libelleGroupe,
    this.groupeId,
    this.horloge,
  });

  /// La seance ouverte.
  final String sessionId;

  /// Le groupe dont elle est l'etat temporaire.
  ///
  /// `null` quand la seance a ete rejointe par son billet sans que l'appelant
  /// connaisse le groupe (un controleur, un tuteur qui assiste) : le cours
  /// existe, il n'a simplement pas d'Espace Groupe ou revenir.
  final String? groupeId;

  /// Le nom familier du groupe.
  final String libelleGroupe;

  /// L'horloge de la seance, pour le temps restant.
  ///
  /// **Nullable depuis l'amendement §3 de `TC_CONTRACT_REQUEST_E.md`.**
  /// `maintenantServeurUtc()` (Agent A, CONTRACTS section 3) n'existe pas
  /// encore en base : un cours peut donc etre ouvert, la salle connectee, et
  /// l'horloge indisponible. Fabriquer une horloge locale serait l'invariant 9
  /// interdit ; taire tout le cours priverait la barre « Cours en cours » de
  /// tout retour possible. `null` se rend donc sans le temps restant, jamais
  /// en cachant le cours lui-meme.
  final SessionClockVM? horloge;

  /// Le meme cours, avec une autre horloge.
  SessionEnCours avecHorloge(SessionClockVM? nouvelle) => SessionEnCours(
    sessionId: sessionId,
    groupeId: groupeId,
    libelleGroupe: libelleGroupe,
    horloge: nouvelle,
  );

  @override
  bool operator ==(Object other) =>
      other is SessionEnCours &&
      other.sessionId == sessionId &&
      other.groupeId == groupeId &&
      other.libelleGroupe == libelleGroupe &&
      other.horloge == horloge;

  @override
  int get hashCode => Object.hash(sessionId, groupeId, libelleGroupe, horloge);
}

/// La session live, au niveau **applicatif**.
///
/// **Contrat produit par Agent E** (`TEACHING_CORE_CONTRACTS.md` section 12),
/// et le second invariant du lot (spec section 9.4, decision D-24).
///
/// Le controleur de room n'est pas attache au widget de la page Classe. Revenir
/// au Groupe, a l'Accueil ou ouvrir la Bibliotheque **n'appelle pas
/// `disconnect`**. Un ecran demonte ne quitte pas un cours : seul [quitter] le
/// fait, et il n'est appele que par un geste explicite.
///
/// Le socle est deja bon : `moteurSalleProvider` est un Provider **racine**,
/// donc unique pour l'application. Ce qui manquait etait un proprietaire du
/// cycle de vie au-dessus des ecrans -- c'est ce port.
abstract class PortSessionPersistante {
  /// Le cours en cours, ou `null`. Emet a chaque changement.
  Stream<SessionEnCours?> suivre();

  /// Le cours en cours a cet instant, sans attendre le flux.
  Future<SessionEnCours?> courante();

  /// Sortie **volontaire**.
  ///
  /// **Annonce la sortie au serveur AVANT de deconnecter le moteur**, et cet
  /// ordre porte une information que rien d'autre ne porte : LiveKit emet le
  /// meme evenement `left` dans les deux cas, seule l'ecriture `quitter_salle`
  /// (`source='user_action'`) distingue une sortie voulue d'une perte de
  /// reseau. Annoncer apres laisserait le webhook arriver le premier et inscrire
  /// une deconnexion.
  Future<void> quitter();
}
