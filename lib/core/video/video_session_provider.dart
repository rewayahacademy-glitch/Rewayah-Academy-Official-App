import 'package:flutter/foundation.dart';

/// Le fournisseur qui sert une seance. Decide en base, jamais ici.
///
/// Les deux coexistent par decision de l'operateur du 12 septembre 2026 :
/// le Cloud pour eprouver, l'auto-heberge pour encaisser la charge. Le client
/// ne choisit pas, il constate -- et n'affiche cette information nulle part :
/// elle ne sert qu'au diagnostic.
enum FournisseurVideo {
  /// LiveKit Cloud.
  cloud,

  /// Serveur LiveKit auto-heberge.
  autoHeberge;

  /// Lit la valeur rendue par la base.
  static FournisseurVideo depuis(String? valeur) =>
      valeur == 'self_hosted' ? FournisseurVideo.autoHeberge : FournisseurVideo.cloud;
}

/// Ce qu'un participant a le droit de faire dans la salle.
///
/// **Ces valeurs ne sont pas des preferences d'interface.** Elles sont
/// calculees en base par `autoriser_jeton_video()` et inscrites dans le jeton
/// signe : un client modifie ne gagne rien a les retourner, le serveur LiveKit
/// refusera la publication. L'interface les lit pour ne pas proposer un bouton
/// qui ne marcherait pas -- c'est tout ce qu'elle en fait.
@immutable
class CapacitesSalle {
  /// Cree un jeu de capacites.
  const CapacitesSalle({
    required this.peutPublier,
    required this.peutPublierVideo,
    required this.peutPublierDonnees,
    required this.peutRecevoir,
    required this.invisible,
  });

  /// Lit les capacites rendues par `create-room-token`.
  factory CapacitesSalle.depuisJson(Map<String, dynamic> json) => CapacitesSalle(
    peutPublier: json['can_publish'] as bool? ?? false,
    peutPublierVideo: json['can_publish_video'] as bool? ?? false,
    peutPublierDonnees: json['can_publish_data'] as bool? ?? false,
    peutRecevoir: json['can_subscribe'] as bool? ?? true,
    invisible: json['hidden'] as bool? ?? false,
  );

  /// Le participant peut publier au moins sa voix.
  final bool peutPublier;

  /// Il peut publier son image. Faux par defaut pour un eleve : la politique
  /// camera d'un mineur vaut `forbidden` tant que personne ne l'a ouverte.
  final bool peutPublierVideo;

  /// Il peut diffuser l'etat partage de seance. Reserve a l'enseignant : c'est
  /// lui qui presente le Coran.
  final bool peutPublierDonnees;

  /// Il recoit les flux des autres.
  final bool peutRecevoir;

  /// Il n'apparait dans la liste de personne. C'est `CTR-02`, l'observation
  /// invisible, et elle est appliquee par le serveur.
  final bool invisible;
}

/// Le droit d'entrer dans une salle, tel que le backend l'a emis.
///
/// **L'URL du serveur voyage ici, et nulle part ailleurs.** C'est le contrat de
/// portabilite de l'ADR-001 : aucune constante d'adresse LiveKit n'existe dans
/// le code Flutter, donc changer de fournisseur ne demande ni redeploiement
/// d'application ni passage par les stores.
@immutable
class AccesSalle {
  /// Cree un acces.
  const AccesSalle({
    required this.urlServeur,
    required this.jeton,
    required this.nomSalle,
    required this.fournisseur,
    required this.role,
    required this.capacites,
    required this.expireLe,
  });

  /// Lit la reponse de `create-room-token`.
  factory AccesSalle.depuisJson(Map<String, dynamic> json) => AccesSalle(
    urlServeur: json['ws_url'] as String? ?? '',
    jeton: json['token'] as String? ?? '',
    nomSalle: json['room_name'] as String? ?? '',
    fournisseur: FournisseurVideo.depuis(json['provider'] as String?),
    role: json['role'] as String? ?? '',
    capacites: CapacitesSalle.depuisJson(
      (json['capabilities'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
    ),
    expireLe:
        DateTime.tryParse(json['expire_le'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  /// L'adresse du serveur, donnee par le backend a chaque session.
  final String urlServeur;

  /// Le jeton signe. Court par principe.
  final String jeton;

  /// Le nom de salle, opaque : il ne porte aucune donnee personnelle.
  final String nomSalle;

  /// Le serveur qui sert cette seance.
  final FournisseurVideo fournisseur;

  /// Le role du porteur, pour placer l'enseignant au centre sans redemander
  /// la base a chaque rendu.
  final String role;

  /// Ce que le porteur a le droit de faire.
  final CapacitesSalle capacites;

  /// L'instant ou le jeton cesse de valoir.
  final DateTime expireLe;
}

/// L'etat de la connexion, tel que l'usager doit le comprendre.
///
/// Volontairement court (specification section 41) : « ICE failed », « RTP
/// timeout » et « SDP negotiation error » n'ont rien a faire devant un enfant
/// ni devant un enseignant. Ils restent dans les journaux de developpement.
enum EtatSalle {
  /// Hors de la salle.
  absent,

  /// Verification du materiel avant d'entrer.
  preVol,

  /// Connexion en cours.
  connexion,

  /// Connecte.
  connecte,

  /// Le reseau est instable, LiveKit retablit la connexion.
  reconnexion,

  /// La connexion n'a pas pu etre retablie.
  echec,
}

/// La qualite du lien, telle que LiveKit la rapporte.
///
/// **Aucune mesure maison ici** (specification section 30) : LiveKit publie
/// deja `connectionQuality`, construire un second systeme de mesure en
/// parallele couterait du CPU pour un resultat moins bon.
enum QualiteLien {
  /// Inconnue, generalement avant la premiere mesure.
  inconnue,

  /// Bonne.
  excellente,

  /// Correcte.
  bonne,

  /// Degradee : la video doit ceder avant la voix.
  mediocre,

  /// Perdue.
  perdue,
}

/// Un participant de la salle, reduit a ce que l'interface affiche.
///
/// Le modele est plat et immuable **pour que le rendu soit ciblable** : la
/// specification section 15 interdit un `setState()` global a chaque evenement
/// WebRTC, et un objet par participant permet de ne reconstruire que la
/// vignette qui change.
@immutable
class ParticipantSalle {
  /// Cree un participant.
  const ParticipantSalle({
    required this.identite,
    required this.nom,
    required this.role,
    required this.estLocal,
    required this.micro,
    required this.camera,
    required this.parle,
    required this.qualite,
  });

  /// L'identifiant de profil. C'est le backend qui l'a inscrit dans le jeton.
  final String identite;

  /// Le nom affichable.
  final String nom;

  /// Le role porte dans la seance.
  final String role;

  /// Vrai pour soi-meme.
  final bool estLocal;

  /// Le micro publie.
  final bool micro;

  /// L'image publie.
  final bool camera;

  /// Une activite audio est detectee.
  ///
  /// **Ce n'est pas une preuve de recitation** (specification section 31) :
  /// parler n'est ni le tajwid correct, ni une participation pedagogique
  /// validee. Le signal ne dit qu'une chose : du son sort de ce micro.
  final bool parle;

  /// La qualite de son lien.
  final QualiteLien qualite;
}

/// Le moteur temps reel de la salle, vu par le produit.
///
/// Cette abstraction existe pour une seule raison, et la specification
/// section 12 la donne : **proteger le domaine metier d'une dependance
/// excessive a LiveKit.** Elle ne recopie pas l'implementation interne du SDK,
/// elle expose ce dont `ELV-03`, `ENS-03` et `CTR-02` ont besoin, et rien de
/// plus.
///
/// Les flux sont separes par nature (etat, participants, qualite) et non
/// reunis en un seul objet d'etat : c'est ce qui permet a une vignette de se
/// reconstruire sans que toute la salle le fasse.
abstract interface class VideoSessionProvider {
  /// Entre dans la salle avec l'acces emis par le backend.
  Future<void> rejoindre(AccesSalle acces);

  /// Quitte la salle. Libere tout : pistes, rendus, ecouteurs, minuteries.
  Future<void> quitter();

  /// Ouvre ou ferme le micro.
  Future<void> reglerMicro({required bool actif});

  /// Ouvre ou ferme la camera. Sans effet si le jeton ne le permet pas.
  Future<void> reglerCamera({required bool actif});

  /// Coupe toute video, emise comme recue.
  ///
  /// C'est le mode « economie de donnees » de l'ADR-001, et le dernier palier
  /// de la degradation : la voix passe, l'image non.
  Future<void> reglerAudioSeul({required bool actif});

  /// L'etat de la connexion.
  Stream<EtatSalle> get etats;

  /// Les participants presents.
  Stream<List<ParticipantSalle>> get participants;

  /// La qualite du lien local.
  Stream<QualiteLien> get qualite;

  /// L'etat courant, pour un premier rendu sans attendre le flux.
  EtatSalle get etatCourant;

  /// Libere les ressources.
  Future<void> liberer();
}
