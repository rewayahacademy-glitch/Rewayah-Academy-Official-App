import 'package:flutter/widgets.dart';

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
/// Six valeurs, et chacune se DIT par un mot a l'ecran : un etat ne se
/// represente jamais par la seule couleur d'une pastille (invariant J7).
///
/// `preVol` a ete retire le 20 septembre 2026. Il etait declare depuis le lot
/// N2 et **jamais emis** : le moteur temps reel n'inspecte aucun peripherique,
/// c'est `ServicePreVol` qui le fait, et l'attente correspondante est deja
/// portee par `PhaseSalle.materiel`. Une valeur d'enumeration qu'aucun code ne
/// pose se lit comme une capacite existante ; elle coutait plus qu'elle ne
/// servait.
enum EtatSalle {
  /// Hors de la salle.
  absent,

  /// Connexion en cours.
  connexion,

  /// Connecte, lien sain.
  connecte,

  /// Connecte, mais le lien se degrade.
  ///
  /// **La seance continue** : rien ne se demonte, aucune commande ne se ferme.
  /// C'est un avertissement, pas une coupure -- et c'est precisement pour cela
  /// qu'il se distingue de [reconnexion], qui, elle, a deja perdu le lien.
  instable,

  /// Le lien est perdu, LiveKit retablit la connexion.
  reconnexion,

  /// Le lien vient d'etre retabli apres une coupure.
  ///
  /// **Distinct de [connecte], et c'est une exigence** : sans lui, un retour de
  /// reconnexion serait indiscernable d'une premiere connexion, et l'ecran ne
  /// pourrait ni le dire a l'usager ni republier l'etat pedagogique en cours.
  retabli,

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

/// Le sujet du canal de donnees qui porte le contenu presente.
///
/// **Un sujet nomme, jamais le canal nu.** LiveKit laisse passer n'importe quel
/// paquet ; le jour ou une seconde information voyagera par le meme canal, un
/// recepteur qui ne filtrerait pas la lirait comme un contenu presente et
/// ouvrirait une page au hasard devant une classe.
const String sujetContenuPresente = 'contenu-presente';

/// Ce que l'enseignant presente a la classe, a un instant donne.
///
/// **[QURAN-STAGE] Un pointeur, jamais du contenu.** Ce qui voyage sur le
/// reseau est une adresse -- page du mushaf, sourate, verset -- et chaque client
/// rend le Coran lui-meme, avec son propre lecteur, son propre grossissement,
/// sa propre edition. C'est ce qui interdit de transformer le Coran en PDF, en
/// image ou en video (invariant J6), et c'est aussi ce qui rend le paquet assez
/// court pour tenir dans un datagramme.
///
/// **Il n'ecrit jamais la position personnelle de l'eleve** (invariant J2,
/// `PositionLecture`) : l'etat presente est EPHEMERE, il vit le temps de la
/// seance, et une page tournee par l'enseignant pour toute la classe n'ecrase
/// pas le marque-page de personne. Le lecteur de l'eleve en fait ce qu'il veut
/// -- suivre, ou proposer de suivre ; il ne le subit pas.
@immutable
class ContenuPresente {
  /// Cree un pointeur de contenu.
  const ContenuPresente({
    required this.page,
    required this.sourate,
    required this.verset,
    required this.presentePar,
    required this.emisLe,
  });

  /// Lit un paquet recu du canal de donnees.
  ///
  /// Les defauts sont surs plutot qu'absents : un paquet tronque ouvre la
  /// premiere page, ce qui est visiblement faux et sans consequence, la ou une
  /// exception couperait le canal pour toute la seance.
  factory ContenuPresente.depuisJson(Map<String, dynamic> json) =>
      ContenuPresente(
        page: json['p'] as int? ?? 1,
        sourate: json['s'] as int? ?? 1,
        verset: json['v'] as int? ?? 1,
        presentePar: json['q'] as String? ?? '',
        emisLe: DateTime.fromMillisecondsSinceEpoch(
          json['t'] as int? ?? 0,
          isUtc: true,
        ).toLocal(),
      );

  /// La page du mushaf ouverte devant la classe.
  final int page;

  /// La sourate visee.
  final int sourate;

  /// Le verset vise dans cette sourate.
  final int verset;

  /// L'identite du presentateur, telle que le jeton l'a inscrite.
  ///
  /// Elle sert a repondre « qui a tourne la page », pas a decider d'un droit :
  /// la barriere reelle est `can_publish_data` dans le jeton signe.
  final String presentePar;

  /// Quand ce contenu a ete pose.
  ///
  /// **Il date le pointeur, il ne l'ordonne pas** : un paquet plus vieux que le
  /// dernier connu peut arriver apres lui sur un canal non fiable, et c'est
  /// cette date qui permet de ne pas reculer d'une page.
  final DateTime emisLe;

  /// L'adresse courte, « 2:255 ». Le meme format que `VersetCoran.reference`.
  String get reference => '$sourate:$verset';

  /// Ecrit le paquet qui voyage.
  ///
  /// Les cles sont courtes d'une lettre parce que ce paquet part a chaque tour
  /// de page, vers cinq ou six appareils, dont certains en 3G.
  Map<String, dynamic> versJson() => <String, dynamic>{
    'p': page,
    's': sourate,
    'v': verset,
    'q': presentePar,
    't': emisLe.toUtc().millisecondsSinceEpoch,
  };
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

  /// Le contenu presente a la classe, a chaque fois qu'il change.
  ///
  /// **Le dernier contenu connu est rendu immediatement a tout nouvel abonne.**
  /// Un ecran qui se remonte au milieu d'une seance -- rotation, retour de
  /// veille, reconnexion -- doit retrouver la page ouverte sans attendre que
  /// l'enseignant la tourne une seconde fois. C'est la meme raison qui fait
  /// exister [etatCourant] a cote de [etats].
  ///
  /// Le presentateur y lit aussi ce qu'il vient de publier : un seul chemin de
  /// rendu pour les deux cotes, donc aucune divergence possible entre ce que la
  /// classe voit et ce que l'enseignant croit montrer.
  Stream<ContenuPresente> get contenusPresentes;

  /// Presente un contenu a toute la salle.
  ///
  /// **Refuse en silence quand le jeton ne porte pas `can_publish_data`.** Un
  /// eleve ne presente pas, et ce n'est pas cette ligne qui l'en empeche : la
  /// barriere reelle est le jeton signe, que le serveur LiveKit fait respecter.
  /// Ce refus-ci n'est que la coherence cote client -- il evite d'envoyer un
  /// paquet dont on sait qu'il sera rejete, et il evite surtout qu'un ecran ne
  /// croie avoir presente quelque chose.
  Future<void> presenterContenu(ContenuPresente contenu);

  /// L'etat courant, pour un premier rendu sans attendre le flux.
  EtatSalle get etatCourant;

  /// L'image d'un participant, prete a poser dans l'arbre de widgets.
  ///
  /// Rend `null` quand ce participant ne publie aucune image : c'est le cas
  /// ordinaire, pas une panne -- camera fermee, politique qui l'interdit, ou
  /// degradation reseau en cours.
  ///
  /// **C'est par cette methode que la portabilite de l'ADR-001 survit au rendu.**
  /// Afficher une piste WebRTC demande un widget du SDK ; si la salle le
  /// construisait elle-meme, elle importerait `livekit_client`, et la promesse
  /// de changer de moteur sans rouvrir les ecrans tomberait. L'ecran ne recoit
  /// donc pas une piste, il recoit un [Widget] deja monte -- il ne sait meme pas
  /// de quelle classe il est.
  ///
  /// Le widget rendu est **volontairement sans cle** : c'est l'appelant qui
  /// connait sa place dans une liste, et c'est donc a lui de poser la cle qui
  /// empeche deux vignettes d'echanger leur etat.
  Widget? renduVideo(String identite);

  /// Libere les ressources.
  Future<void> liberer();
}
