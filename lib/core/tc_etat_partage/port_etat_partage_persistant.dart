import 'shared_content_state.dart';

/// Pourquoi une ecriture ou une lecture de l'etat durable a echoue.
enum MotifEchecEtatPartage {
  /// La revision proposee n'est pas strictement superieure a celle stockee.
  ///
  /// Deux enseignants -- ou le meme sur deux appareils -- ont pousse la meme
  /// revision. C'est **le cas normal d'une course**, pas une panne : l'appelant
  /// relit l'etat courant et repart de la.
  revisionObsolete,

  /// L'appelant n'a pas le droit d'ecrire l'etat de cette seance.
  ///
  /// Decide en base, jamais ici : la barriere est la policy RLS demandee dans
  /// `TC_CONTRACT_REQUEST_F.md`, pas un test cote client.
  droitRefuse,

  /// Le backend n'a pas repondu.
  reseau,

  /// La table d'etat partage n'existe pas encore sur ce deploiement.
  ///
  /// Valeur transitoire, et **nommee plutot que silencieuse** : tant que la
  /// migration demandee n'est pas appliquee, une Classe Live se comporte comme
  /// aujourd'hui -- la presentation vit le temps de la connexion et un arrivant
  /// tardif ne recupere rien. Un ecran doit pouvoir le dire.
  persistanceAbsente,
}

/// L'echec d'une operation sur l'etat durable.
class EchecEtatPartage implements Exception {
  /// Cree un echec.
  const EchecEtatPartage(this.motif, {this.revisionStockee});

  /// Ce qui a empeche l'operation.
  final MotifEchecEtatPartage motif;

  /// La revision que le backend detenait, quand il l'a dite.
  ///
  /// Elle evite un aller-retour supplementaire apres une course perdue :
  /// l'appelant sait immediatement de combien il est en retard.
  final int? revisionStockee;

  @override
  String toString() =>
      'EchecEtatPartage($motif${revisionStockee == null ? '' : ', revision stockee $revisionStockee'})';
}

/// La persistance minimale de l'etat partage d'une seance.
///
/// **Port produit par Agent F, absent de `TEACHING_CORE_CONTRACTS.md`.** Il y
/// est nomme dans `TEACHING_CORE_FILE_OWNERSHIP.md` (« Ports produits :
/// `PortRealtimePedagogique`, `PortEtatPartage`, `PortEtatPartagePersistant` »)
/// mais aucune signature n'en est donnee. Celle-ci est proposee a l'inscription
/// dans le contrat par `TC_CONTRACT_REQUEST_F.md`.
///
/// **C'est ce port, et lui seul, qui fait qu'un arrivant tardif n'a pas besoin
/// de l'historique des messages.** LiveKit n'est jamais une base de donnees :
/// il transporte, il ne conserve rien. Tant que la table demandee n'existe pas,
/// `EtatPartageMemoire` en tient lieu -- dans le processus, donc sans aucune
/// des garanties que la vraie implementation devra offrir.
///
/// **Aucune donnee sensible n'y transite** : `SharedContentState` ne porte que
/// des identifiants de ressource, des positions et un `profile_id` d'emetteur.
abstract class PortEtatPartagePersistant {
  /// L'etat durable de la seance, ou `null` si aucune presentation n'a eu lieu.
  ///
  /// Leve [EchecEtatPartage] sur panne. **Ne rend jamais un etat vide pour
  /// masquer une erreur** : « rien n'est presente » et « je n'ai pas pu lire »
  /// conduisent a deux ecrans differents.
  Future<SharedContentState?> lire(String sessionId);

  /// Ecrit une revision, si et seulement si elle est plus recente.
  ///
  /// Rend l'etat effectivement stocke. Leve
  /// [EchecEtatPartage] avec [MotifEchecEtatPartage.revisionObsolete] quand la
  /// revision proposee n'est pas strictement superieure a celle stockee :
  /// **c'est le point ou la monotonie devient une garantie et non une
  /// convention**, parce qu'elle est tenue par une contrainte serveur et non
  /// par la politesse des clients.
  Future<SharedContentState> enregistrer(SharedContentState etat);

  /// Efface l'etat d'une seance terminee.
  ///
  /// Appele par la fin de seance, jamais par une deconnexion : une coupure
  /// reseau ne termine pas un cours.
  Future<void> effacer(String sessionId);
}
