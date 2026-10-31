import 'package:flutter/foundation.dart';

import '../tc_horloge/session_clock_vm.dart';

/// La seance en direct, independamment de l'ecran affiche.
///
/// C'est ce que lit la barre compacte « Seance toujours en direct » : de quoi nommer le
/// groupe, dire le temps restant, et y revenir d'un geste.
@immutable
class SessionEnCours {
  /// Declare une seance en direct.
  const SessionEnCours({
    required this.sessionId,
    required this.groupeId,
    required this.libelleGroupe,
    this.horloge,
    this.eleveId,
    this.interfaceGuidee = false,
  });

  /// La seance ouverte.
  final String sessionId;

  /// Le groupe dont elle est l'etat temporaire.
  final String groupeId;

  /// Le nom familier du groupe.
  final String libelleGroupe;

  /// L'eleve entre depuis l'appareil de son tuteur (D6), ou `null` : il
  /// faut le redire au retour par la barre, sans quoi le jeton redemande
  /// serait celui du tuteur.
  final String? eleveId;

  /// Vrai quand la salle s'ouvre dans l'Interface guidee de [eleveId].
  final bool interfaceGuidee;

  /// L'horloge de la seance, pour le temps restant.
  ///
  /// **Nullable depuis l'amendement §3 de `TC_CONTRACT_REQUEST_E.md`.**
  /// `maintenantServeurUtc()` (Agent A, CONTRACTS section 3) n'existe pas
  /// encore en base : un cours peut donc etre ouvert, la salle connectee, et
  /// l'horloge indisponible. Fabriquer une horloge locale serait l'invariant 9
  /// interdit ; taire tout le cours priverait la barre « Seance toujours en direct » de
  /// tout retour possible. `null` se rend donc sans le temps restant, jamais
  /// en cachant le cours lui-meme.
  final SessionClockVM? horloge;

  /// Le meme cours, avec une autre horloge.
  SessionEnCours avecHorloge(SessionClockVM? nouvelle) => SessionEnCours(
    sessionId: sessionId,
    groupeId: groupeId,
    libelleGroupe: libelleGroupe,
    horloge: nouvelle,
    eleveId: eleveId,
    interfaceGuidee: interfaceGuidee,
  );

  @override
  bool operator ==(Object other) =>
      other is SessionEnCours &&
      other.sessionId == sessionId &&
      other.groupeId == groupeId &&
      other.libelleGroupe == libelleGroupe &&
      other.horloge == horloge &&
      other.eleveId == eleveId &&
      other.interfaceGuidee == interfaceGuidee;

  @override
  int get hashCode => Object.hash(
    sessionId,
    groupeId,
    libelleGroupe,
    horloge,
    eleveId,
    interfaceGuidee,
  );
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
  /// La seance en direct, ou `null`. Emet a chaque changement.
  Stream<SessionEnCours?> suivre();

  /// La seance en direct a cet instant, sans attendre le flux.
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
