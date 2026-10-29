/// Les seuils de temps de l'interface, poses une seule fois.
///
/// **Aucune politique reseau n'existe**, ni cote serveur ni dans `lib/core`
/// (dependance DB-TRV-03 du chantier Tuteur V1) : sans ces deux valeurs, chaque
/// ecran inventerait la sienne, et un meme chargement serait « prolonge » ici
/// et « normal » ailleurs. Elles vivent dans le theme parce qu'elles decident
/// de ce que l'interface **dit**, pas de ce que le reseau fait.
///
/// Ce ne sont pas des durees de mouvement (celles-la vivent dans
/// `app_mouvement.dart`) : elles ne rythment aucune animation.
///
/// **Valeurs proposees par le contrat K5, non mesurees.** Elles se confirment
/// en recette, sur un reseau reel et lent, et se changent ici seulement.
abstract final class AppDelais {
  /// Au-dela, un chargement encore en cours devient un « chargement
  /// prolonge » : l'ecran garde son squelette et ajoute une phrase qui le dit.
  ///
  /// Sous dix secondes, le seuil au-dela duquel une attente sans explication
  /// perd l'attention ; assez long pour qu'un reseau mobile ordinaire ne
  /// declenche jamais le message.
  static const Duration chargementProlonge = Duration(seconds: 8);

  /// Au-dela, une requete sans reponse est tenue pour perdue : l'ecran passe a
  /// l'etat d'echec et propose de reessayer, une fois, jamais en boucle.
  ///
  /// Toujours plus long que [chargementProlonge] : on dit d'abord que c'est
  /// long, et seulement ensuite que c'est perdu.
  static const Duration requeteMax = Duration(seconds: 20);

  /// La relecture programmee d'un accueil d'eleve qui precede sa seance
  /// connue (la seconde tombe a l'heure de debut). Decision du directeur du
  /// 29/10/2026 : aucune minuterie fixe.
  static const Duration avantSeanceRelecture = Duration(minutes: 5);

  /// L'alea maximal ajoute a chaque relecture programmee, contre les rafales.
  static const Duration aleaRelecture = Duration(seconds: 30);

  /// Passe ce delai sans que le canal temps reel de la veille soit rejoint, un
  /// avertissement part vers la supervision (29/10/2026).
  static const Duration veilleNonRejointe = Duration(seconds: 15);
  /// Le plus long qu'un appel du demarrage (session, profil) peut retenir
  /// l'ouverture (lot ouverture rapide, 29/10/2026). Passe ce delai, l'ecran
  /// dit ce qui manque et propose « Reessayer », au lieu de rester bloque.
  static const Duration demarrageMax = Duration(seconds: 10);

  /// Avant de se deconnecter, les cahiers de transmission encore en file ont
  /// cette duree pour partir ; au-dela, la personne choisit de les perdre ou
  /// d'annuler (fiche du 27/10/2026, ligne 16, arbitrage du pilote).
  static const Duration envoiAvantDeconnexion = Duration(seconds: 3);
}
