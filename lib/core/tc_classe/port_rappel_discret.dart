/// L'echec d'un rappel discret.
///
/// **La seule chose qui se dit a l'ecran.** Le rappel reussi ne produit aucun
/// message, aucune coche, aucun accuse : la spec section 10.2 interdit la boucle
/// « envoye / revenu / confirme ». L'enseignant verra l'eleve reagir, ou il ne
/// le verra pas ; une notification de plus ne l'aiderait pas, elle lui
/// demanderait de lire.
class EchecRappel implements Exception {
  /// Cree un echec.
  const EchecRappel(this.motif);

  /// Pourquoi le rappel n'est pas parti.
  final MotifEchecRappel motif;

  @override
  String toString() => 'EchecRappel($motif)';
}

/// Pourquoi un rappel discret n'est pas parti.
///
/// Trois motifs, et **aucun ne nomme l'eleve** : ce qui a echoue est un envoi,
/// pas une personne.
enum MotifEchecRappel {
  /// Le transport a refuse le paquet, ou personne ne l'ecoute.
  transport,

  /// L'appelant n'a pas le droit d'emettre dans cette seance.
  ///
  /// La barriere reelle est le jeton signe (`can_publish_data`) : ce motif ne
  /// decide rien, il nomme un refus deja prononce ailleurs.
  droitRefuse,

  /// Le cooldown court encore.
  ///
  /// **Ce n'est pas une erreur de l'enseignant** : c'est la protection contre le
  /// spam de la spec section 10.2, et elle se dit sans reproche.
  cooldown,
}

/// Le rappel discret adresse a un eleve.
///
/// **Contrat produit par Agent E** (`TEACHING_CORE_CONTRACTS.md` section 12).
///
/// Ce que ce port garantit, et qui n'est pas negociable :
///
/// - **aucun micro n'est ouvert a distance.** Rien ici ne touche un peripherique
///   de qui que ce soit ; l'evenement demande une vibration breve, un son doux
///   si le profil l'autorise, et une impulsion visuelle ;
/// - **reussite silencieuse.** [rappeler] ne rend rien. Un message n'apparait
///   qu'en levant [EchecRappel] ;
/// - **aucun accuse de reception.** Il n'existe pas de methode qui dirait que
///   l'eleve a vu le rappel, et il n'en existera pas : ce serait la boucle de
///   notifications que la spec refuse ;
/// - **un cooldown court**, expose par [cooldown] pour que l'interface puisse
///   desactiver l'action plutot que la laisser echouer.
abstract class PortRappelDiscret {
  /// Appelle un eleve, discretement.
  ///
  /// Leve [EchecRappel] si le transport refuse. Ne rend rien en cas de succes :
  /// le succes ne se dit pas.
  Future<void> rappeler({required String sessionId, required String academyId});

  /// Le delai minimal entre deux rappels adresses au meme eleve.
  Duration get cooldown;

  /// Depuis quand cet eleve est encore sous cooldown. `null` = il ne l'est pas.
  ///
  /// **Ajout d'Agent E au contrat, sans divergence de signature** :
  /// `TEACHING_CORE_CONTRACTS.md` expose `cooldown` mais rien qui dise ou l'on
  /// en est. Sans cette lecture, l'interface ne pourrait qu'envoyer pour
  /// apprendre que c'est trop tot -- donc afficher un echec la ou la spec
  /// demande de ne rien afficher. La demande d'amendement est ecrite en section
  /// 2 de `docs/teaching-core/TC_CONTRACT_REQUEST_E.md`.
  Duration? cooldownRestant({
    required String sessionId,
    required String academyId,
  });
}
