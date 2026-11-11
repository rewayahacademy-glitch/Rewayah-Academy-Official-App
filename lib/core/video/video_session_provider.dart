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
  static FournisseurVideo depuis(String? valeur) => valeur == 'self_hosted'
      ? FournisseurVideo.autoHeberge
      : FournisseurVideo.cloud;
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
    this.peutModerer = false,
  });

  /// Lit les capacites rendues par `create-room-token`.
  factory CapacitesSalle.depuisJson(Map<String, dynamic> json) =>
      CapacitesSalle(
        peutPublier: json['can_publish'] as bool? ?? false,
        peutPublierVideo: json['can_publish_video'] as bool? ?? false,
        peutPublierDonnees: json['can_publish_data'] as bool? ?? false,
        peutRecevoir: json['can_subscribe'] as bool? ?? true,
        invisible: json['hidden'] as bool? ?? false,
        peutModerer: json['can_moderate'] as bool? ?? false,
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

  /// Il peut couper le micro ou la camera d'un eleve, le faire sortir et le
  /// readmettre (30/10/2026). Reserve a l'enseignant effectif de la seance ;
  /// la fonction `salle-gestes` le reverifie en base a chaque geste.
  final bool peutModerer;

  /// Les memes capacites, avec les droits de publication que le serveur
  /// LiveKit accorde a cet instant (MICRO-AVANT-ENSEIGNANT, 11/11/2026).
  ///
  /// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : [micro] dit si le droit
  /// de publier ([peutPublier], le `canPublish` de LiveKit) couvre le micro.
  /// Pendant la recitation d'un camarade, le serveur garde le droit de
  /// publier pour la camera et ferme le micro seul : [peutPublier] vrai,
  /// [micro] faux. Absent : le micro suit [peutPublier], comme avant ce lot.
  /// Le champ [CapacitesSalle.peutPublier] reste « peut publier sa voix ».
  CapacitesSalle avecPublication({
    required bool peutPublier,
    required bool peutPublierVideo,
    bool? micro,
  }) => CapacitesSalle(
    peutPublier: peutPublier && (micro ?? true),
    peutPublierVideo: peutPublier && peutPublierVideo,
    peutPublierDonnees: peutPublierDonnees,
    peutRecevoir: peutRecevoir,
    invisible: invisible,
    peutModerer: peutModerer,
  );
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
    this.publicationDifferee = false,
    this.seanceId,
    this.eleveId,
  });

  /// Lit la reponse de `create-room-token`.
  ///
  /// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026) : `publication_differee`
  /// dit que le jeton d'un eleve est signe **sans droit de publier**, parce
  /// que son enseignant n'est pas encore dans la salle. `capabilities` porte
  /// alors les droits qu'il retrouvera ; ceux qu'il a maintenant sont fermes,
  /// et c'est ce que [capacites] dit, pour qu'aucun ecran ne rende un bouton
  /// que le serveur refuserait.
  factory AccesSalle.depuisJson(Map<String, dynamic> json) {
    final CapacitesSalle decidees = CapacitesSalle.depuisJson(
      (json['capabilities'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
    final bool differee = json['publication_differee'] == true;
    return AccesSalle(
      urlServeur: json['ws_url'] as String? ?? '',
      jeton: json['token'] as String? ?? '',
      nomSalle: json['room_name'] as String? ?? '',
      fournisseur: FournisseurVideo.depuis(json['provider'] as String?),
      role: json['role'] as String? ?? '',
      capacites: differee
          ? decidees.avecPublication(
              peutPublier: false,
              peutPublierVideo: false,
            )
          : decidees,
      publicationDifferee: differee,
      expireLe:
          DateTime.tryParse(json['expire_le'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Le role dont le droit de publier attend l'enseignant.
  static const String roleEleve = 'student';

  /// Vrai quand le droit de publier de cet eleve attend son enseignant
  /// (MICRO-AVANT-ENSEIGNANT) : le serveur LiveKit refuse son micro et sa
  /// camera tant que l'enseignant n'est pas dans la salle. Decide par le
  /// serveur, jamais par l'ecran.
  ///
  /// RECITATION-MICRO-SEUL (11/11/2026) : vrai aussi quand le serveur ferme
  /// le micro seul (la recitation d'un camarade) ; la camera se lit alors
  /// dans [CapacitesSalle.peutPublierVideo], qui reste vraie si le jeton de
  /// l'eleve la lui donne.
  final bool publicationDifferee;

  /// La seance pour laquelle cet acces a ete demande, quand le service qui
  /// l'a emis la connait : elle sert a redemander au serveur, jamais a
  /// decider d'un droit.
  final String? seanceId;

  /// L'eleve pour qui un tuteur a demande cet acces (D6), ou `null`.
  final String? eleveId;

  /// Le meme acces, rattache a la demande qui l'a obtenu.
  AccesSalle pourLaDemande({required String seanceId, String? eleveId}) =>
      _copie(seanceId: seanceId, eleveId: eleveId);

  /// Le meme acces, avec les droits de publication que le serveur LiveKit
  /// accorde a cet instant (il les change quand l'enseignant entre). Pour un
  /// eleve, un droit de publier ferme est un droit qui attend l'enseignant.
  ///
  /// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : [micro] faux avec
  /// [peutPublier] vrai, c'est le micro seul ferme (la recitation d'un
  /// camarade) : la camera reste permise ([peutPublierVideo]), et
  /// [publicationDifferee] dit que le MICRO attend.
  AccesSalle avecPublication({
    required bool peutPublier,
    required bool peutPublierVideo,
    bool? micro,
  }) => _copie(
    capacites: capacites.avecPublication(
      peutPublier: peutPublier,
      peutPublierVideo: peutPublierVideo,
      micro: micro,
    ),
    publicationDifferee: role == roleEleve && !(peutPublier && (micro ?? true)),
  );

  AccesSalle _copie({
    CapacitesSalle? capacites,
    bool? publicationDifferee,
    String? seanceId,
    String? eleveId,
  }) => AccesSalle(
    urlServeur: urlServeur,
    jeton: jeton,
    nomSalle: nomSalle,
    fournisseur: fournisseur,
    role: role,
    capacites: capacites ?? this.capacites,
    expireLe: expireLe,
    publicationDifferee: publicationDifferee ?? this.publicationDifferee,
    seanceId: seanceId ?? this.seanceId,
    eleveId: eleveId ?? this.eleveId,
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

  /// L'enseignant a fait sortir ce participant de la salle (30/10/2026) :
  /// le serveur l'a retire, et ne lui rend un jeton qu'apres readmission.
  retire,
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

/// Vrai si [a] et [b] ne different que par `parle` (qui parle en ce moment) :
/// memes personnes, dans le meme ordre, memes micro, camera et qualite.
bool memesHorsParole(List<ParticipantSalle> a, List<ParticipantSalle> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    final ParticipantSalle x = a[i];
    final ParticipantSalle y = b[i];
    if (x.identite != y.identite ||
        x.nom != y.nom ||
        x.role != y.role ||
        x.estLocal != y.estLocal ||
        x.micro != y.micro ||
        x.camera != y.camera ||
        x.qualite != y.qualite) {
      return false;
    }
  }
  return true;
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
    this.clePhotoEnseignant,
  });

  /// L'identifiant de profil. C'est le backend qui l'a inscrit dans le jeton.
  /// **Jamais rendu a l'ecran** (directeur, 26/10/2026) : une chaine
  /// technique ne nomme personne.
  final String identite;

  /// Le nom affichable : celui du jeton s'il en porte un (vide sinon),
  /// puis celui de l'annuaire de la seance (`AnnuaireSeance`).
  final String nom;

  /// La cle de la photo publique de l'enseignant (seau `photos_enseignants`),
  /// quand l'annuaire la connait ; `null` : le cercle sans image (les eleves,
  /// dont aucune cle n'est lisible en salle).
  final String? clePhotoEnseignant;

  /// Le meme participant, nomme par l'annuaire de la seance.
  ParticipantSalle nomme({required String nom, String? clePhotoEnseignant}) =>
      ParticipantSalle(
        identite: identite,
        nom: nom,
        role: role,
        estLocal: estLocal,
        micro: micro,
        camera: camera,
        parle: parle,
        qualite: qualite,
        clePhotoEnseignant: clePhotoEnseignant,
      );

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

/// Le suffixe qui marque un sujet comme ephemere (non fiable) a la reception.
///
/// **Arbitrage Agent Z, `TC_CONTRACT_REQUEST_F.md` §1.4 Q1.** LiveKit ne
/// remonte pas `DataPacket_Kind` au recepteur (verifie sur `livekit_client
/// 2.12.0` : `DataReceivedEvent` ne porte que `participant`, `data`, `topic`).
/// La seule facon de reconstituer la fiabilite d'un paquet recu est donc de la
/// porter dans le sujet lui-meme. Convention : tout sujet qui se termine par
/// ce suffixe a ete publie en mode non fiable ; tout le reste, y compris
/// [sujetContenuPresente], est traite comme fiable. Un protocole applicatif
/// qui a besoin d'un canal ephemere nomme donc son sujet fiable `xxx` et son
/// sujet ephemere `xxx-l` (c'est le choix deja fait par Agent F,
/// `tc-pedagogique` / `tc-pedagogique-l`) : le socle n'a besoin de connaitre
/// aucun nom de sujet particulier, seulement ce suffixe.
const String suffixeSujetEphemere = '-l';

/// Le sujet pose sur le reseau pour [sujet] : le suffixe ephemere s'ajoute
/// quand le paquet part en mode non fiable (revue de la PR 54 : sans lui, le
/// recepteur classait le pointeur fiable et le canal ephemere le jetait).
String sujetSurLeReseau(String sujet, {required bool fiable}) =>
    fiable || sujet.endsWith(suffixeSujetEphemere)
    ? sujet
    : '$sujet$suffixeSujetEphemere';

/// Le paquet recu sous le sujet reseau [sujetRecu] : la fiabilite se lit au
/// suffixe, puis le sujet revient a son nom logique, celui que les
/// protocoles filtrent.
PaquetDonnees paquetDepuisLeReseau({
  required String sujetRecu,
  required List<int> charge,
  String? emetteurIdentite,
}) {
  final bool ephemere = sujetRecu.endsWith(suffixeSujetEphemere);
  return PaquetDonnees(
    sujet: ephemere
        ? sujetRecu.substring(0, sujetRecu.length - suffixeSujetEphemere.length)
        : sujetRecu,
    charge: charge,
    fiable: !ephemere,
    emetteurIdentite: emetteurIdentite,
  );
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
/// **PARTAGE-GENERIQUE (directeur, 11/11/2026, CAHIER-SALLE §7) : le support
/// est generique.** Le pointeur dit aussi QUEL support est ouvert
/// ([support], [version]) et combien de pages il a ([total]). Sans
/// identifiant, c'est le Coran ([supportCoran]) : son paquet ne change pas,
/// et un paquet d'avant ce lot se lit comme avant. Pour un autre support, la
/// page voyage sous une cle
/// nouvelle et l'ancienne cle dit « rien n'est presente » : une application
/// pas encore mise a jour n'ouvre donc jamais une page du Coran a la place
/// d'un autre livre (voir [versJson]).
///
/// **Il n'ecrit jamais la position personnelle de l'eleve** (invariant J2,
/// `PositionLecture`) : l'etat presente est EPHEMERE, il vit le temps de la
/// seance, et une page tournee par l'enseignant pour toute la classe n'ecrase
/// pas le marque-page de personne. Le lecteur de l'eleve en fait ce qu'il veut
/// -- suivre, ou proposer de suivre ; il ne le subit pas.
@immutable
class ContenuPresente {
  /// Cree un pointeur de contenu. Sans [support], c'est le Coran.
  const ContenuPresente({
    required this.page,
    required this.sourate,
    required this.verset,
    required this.presentePar,
    required this.emisLe,
    this.support = supportCoran,
    this.version = versionCoran,
    this.total,
  });

  /// La page [page] d'un support qui n'est pas le Coran : [support] est son
  /// identifiant dans la Bibliotheque, [version] sa version publiee, [total]
  /// son nombre de pages.
  const ContenuPresente.deSupport({
    required this.support,
    required this.version,
    required this.page,
    required int this.total,
    required this.presentePar,
    required this.emisLe,
  }) : sourate = 0,
       verset = 0;

  /// Lit un paquet recu du canal de donnees.
  ///
  /// Les defauts sont surs plutot qu'absents : un paquet tronque ouvre la
  /// premiere page, ce qui est visiblement faux et sans consequence, la ou une
  /// exception couperait le canal pour toute la seance.
  ///
  /// Un paquet sans identifiant de support (application d'avant
  /// PARTAGE-GENERIQUE) est le Coran. Une valeur d'un type inattendu se lit
  /// comme absente : jamais une exception.
  factory ContenuPresente.depuisJson(Map<String, dynamic> json) {
    int? entier(String cle) => switch (json[cle]) {
      final int v => v,
      final num v => v.toInt(),
      _ => null,
    };
    String? texte(String cle) => switch (json[cle]) {
      final String v when v.isNotEmpty => v,
      _ => null,
    };
    final String support = texte('d') ?? supportCoran;
    final bool coran = support == supportCoran;
    final int? total = entier('n');
    return ContenuPresente(
      // Le Coran lit sa page ou il l'a toujours lue ; un autre support la lit
      // sous sa cle a lui (`g`), l'ancienne cle (`p`) valant alors 0.
      page: coran
          ? (entier('p') ?? 1)
          : switch (entier('g')) {
              final int g when g >= 1 => g,
              _ => 1,
            },
      sourate: coran ? (entier('s') ?? 1) : 0,
      verset: coran ? (entier('v') ?? 1) : 0,
      presentePar: json['q'] is String ? json['q'] as String : '',
      emisLe: DateTime.fromMillisecondsSinceEpoch(
        entier('t') ?? 0,
        isUtc: true,
      ).toLocal(),
      support: support,
      version: texte('e') ?? versionCoran,
      total: total != null && total >= 1 ? total : null,
    );
  }

  /// L'identifiant du Coran de la salle (mushaf de Medine, 15 lignes) : celui
  /// d'un paquet qui ne nomme aucun support.
  static const String supportCoran = 'mushaf-madina-15';

  /// La version du Coran de la salle.
  static const String versionCoran = '1';

  /// L'identifiant du support ouvert devant la classe.
  final String support;

  /// La version du support : un trait pose sur une page reste attache a elle.
  final String version;

  /// Le nombre de pages du support, ou `null` quand le paquet ne le dit pas
  /// (le Coran : chaque application le connait).
  final int? total;

  /// La page ouverte devant la classe (du mushaf, ou du support).
  final int page;

  /// La sourate visee (le Coran seulement ; 0 pour un autre support).
  final int sourate;

  /// Le verset vise dans cette sourate (le Coran seulement).
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

  /// La page qui signale « rien n'est presente » : l'enseignant a range le
  /// support (lot salle 3, directeur, 25/10/2026 : un support ouvert se
  /// ferme). Elle voyage comme une page, pour que la classe et un eleve qui
  /// arrive apres l'apprennent par le meme canal et le meme rejeu.
  static const int pageRetiree = 0;

  /// Le contenu « rien n'est presente », pose par [presentePar].
  factory ContenuPresente.retire({
    required String presentePar,
    required DateTime emisLe,
  }) => ContenuPresente(
    page: pageRetiree,
    sourate: 0,
    verset: 0,
    presentePar: presentePar,
    emisLe: emisLe,
  );

  /// Vrai quand le support presente est le Coran.
  bool get estCoran => support == supportCoran;

  /// Vrai quand ce contenu dit que rien n'est presente.
  bool get estRetire => estCoran && page == pageRetiree;

  /// L'adresse courte, « 2:255 ». Le meme format que `VersetCoran.reference`.
  String get reference => '$sourate:$verset';

  /// Ecrit le paquet qui voyage.
  ///
  /// Les cles sont courtes d'une lettre parce que ce paquet part a chaque tour
  /// de page, vers cinq ou six appareils, dont certains en 3G.
  ///
  /// **Compatibilite (PARTAGE-GENERIQUE).** Le paquet du Coran ne change pas
  /// d'un octet (`p`, `s`, `v`, `q`, `t`, sans identifiant : l'absence
  /// d'identifiant EST le Coran) : une application ancienne ouvre la meme
  /// page qu'avant. Un autre support ecrit `p = 0` : l'application ancienne
  /// lit « rien n'est presente » et garde la video de l'enseignant en grand,
  /// au lieu d'ouvrir la page du Coran de meme numero. Sa vraie page voyage
  /// sous `g`, avec son identifiant (`d`), sa version (`e`) et son nombre de
  /// pages (`n`). Toujours une adresse, jamais un contenu (invariant J6).
  Map<String, dynamic> versJson() => <String, dynamic>{
    'p': estCoran ? page : pageRetiree,
    's': sourate,
    'v': verset,
    'q': presentePar,
    't': emisLe.toUtc().millisecondsSinceEpoch,
    if (!estCoran) ...<String, dynamic>{
      'd': support,
      'e': version,
      'g': page,
      'n': ?total,
    },
  };
}

/// Un paquet de donnees applicatif recu de la salle.
///
/// Le socle ne le decode pas : il transporte des octets sous un sujet nomme.
/// Ajoute a la demande d'Agent F (`TC_CONTRACT_REQUEST_F.md` §1.1) pour
/// generaliser le canal de donnees que [presenterContenu] avait ouvert en
/// premier : le protocole pedagogique a besoin de son propre sujet, d'un
/// canal non fiable et de destinataires cibles, que [ContenuPresente] ne
/// porte pas.
@immutable
class PaquetDonnees {
  /// Cree un paquet.
  const PaquetDonnees({
    required this.sujet,
    required this.charge,
    required this.fiable,
    this.emetteurIdentite,
  });

  /// Le sujet nomme du paquet. Chaine vide quand l'emetteur n'en a pose aucun.
  final String sujet;

  /// Les octets recus, tels quels.
  final List<int> charge;

  /// Vrai quand le paquet est arrive par le canal fiable.
  ///
  /// Derive du suffixe du sujet : voir [suffixeSujetEphemere].
  final bool fiable;

  /// L'identite du participant emetteur, telle que le jeton l'a inscrite.
  /// `null` quand le paquet vient du serveur ou que le SDK ne la donne pas.
  /// **Elle ne decide d'aucun droit** : la barriere est le jeton signe.
  final String? emetteurIdentite;
}

/// Pourquoi une publication de donnees n'a pas eu lieu.
enum MotifEchecPublication {
  /// Le jeton signe n'accorde pas `can_publish_data` a l'appelant.
  droitRefuse,

  /// Aucune salle ouverte.
  horsSalle,

  /// Le transport a refuse le paquet.
  transport,
}

/// L'echec d'une publication de donnees.
///
/// **Toujours levee, jamais avalee** : c'est la seule difference de contrat
/// avec [VideoSessionProvider.presenterContenu], qui refuse en silence. Un
/// appelant qui a besoin de savoir qu'un envoi a echoue (`PortRappelDiscret`,
/// CONTRACTS section 12 : « un message n'apparait QUE si l'envoi echoue ») ne
/// peut pas le savoir si la primitive se tait.
class EchecPublicationDonnees implements Exception {
  /// Cree l'echec.
  const EchecPublicationDonnees(this.motif, [this.detail]);

  /// Ce qui a empeche la publication.
  final MotifEchecPublication motif;

  /// Detail technique, pour le journal de developpement uniquement.
  final String? detail;

  @override
  String toString() =>
      'EchecPublicationDonnees($motif${detail == null ? '' : ', $detail'})';
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
/// UX-038 (31/10/2026) : pourquoi la salle est tombee en echec, quand le
/// fournisseur le sait. [EtatSalle] reste `echec` (lu par de nombreux
/// ecrans) ; ce motif s'y ajoute a cote, sans toucher les autres
/// fournisseurs : seul celui qui sait le dire l'implemente.
abstract interface class MotifEchecSalle {
  /// Vrai quand le serveur a ferme cette salle parce que le meme compte l'a
  /// ouverte ailleurs (autre onglet, autre appareil). Remis a faux a chaque
  /// entree.
  bool get ouverteAilleurs;
}

/// ECRAN-EVEILLE (directeur, 11/11/2026) : ce que sait faire un moteur qui
/// reprend **seul** l'appel apres une veille, un onglet cache ou une coupure
/// du reseau.
///
/// Plainte du directeur : « il ne faut pas que l'extinction de l'ecran coupe
/// le reseau ou bien coupe la voix ou le micro ». Meme motif que
/// [MotifEchecSalle] : seul le moteur qui sait le faire l'implemente, les
/// doubles de test et les demonstrations n'ont rien a changer.
abstract interface class RepriseAutomatique {
  /// D'ou tirer un jeton neuf quand celui de l'entree a expire pendant la
  /// coupure (le jeton vit 15 minutes par defaut, `video_config`). `null`
  /// hors seance confiee : le moteur reprend alors avec le jeton qu'il a,
  /// tant qu'il vaut.
  set sourceJeton(Future<AccesSalle> Function()? source);

  /// L'application vient de passer au premier plan ([visible] vrai) ou de
  /// le quitter. Au retour, le moteur reconfirme l'appel, rend au micro et a
  /// la camera l'etat **voulu** avant la coupure (jamais plus, jamais sans le
  /// droit du serveur), relance le son recu, et accelere une reprise en
  /// attente.
  void premierPlan({required bool visible});
}

/// MICRO-AVANT-ENSEIGNANT (directeur, 11/11/2026) : les droits de publication
/// changent pendant la seance, quand le serveur les rend a l'eleve a l'entree
/// de son enseignant. Meme principe que [MotifEchecSalle] : seul le
/// fournisseur qui sait le dire l'implemente, les autres ne changent pas.
abstract interface class DroitsPublicationVivants {
  /// L'acces courant, a chaque fois que le serveur change les droits de
  /// publication du participant local. [VideoSessionProvider.accesCourant]
  /// rend le meme a tout instant.
  Stream<AccesSalle> get accesMisAJour;
}

/// FERMETURE-SALLE (directeur, 11/11/2026, seconde moitie de SEC-1, journal
/// D-018) : le serveur ferme la salle pour tous quand la seance est finie et
/// que l'enseignant n'y est plus. Meme principe que [MotifEchecSalle] : seul
/// le moteur qui sait le dire l'implemente.
///
/// [EtatSalle] reste `echec` (lu par de nombreux ecrans) ; ce motif s'y
/// ajoute a cote. Il se distingue de [EtatSalle.retire] (l'enseignant a fait
/// sortir ce participant) et d'une connexion perdue : ici, personne n'a ete
/// ecarte et rien n'est en panne, la seance est terminee.
abstract interface class FermetureParLeServeur {
  /// Vrai quand le serveur a ferme la salle elle-meme (salle supprimee).
  /// Remis a faux a chaque entree.
  bool get salleFermee;

  /// La fin du depassement autorise de la seance en cours (fin prevue +
  /// `grace_after_end_minutes`, servie par le serveur), ou `null` si elle
  /// n'est pas connue. Le moteur s'en sert seulement pour demander au serveur,
  /// a ce moment-la, de relire la regle : il ne ferme rien lui-meme.
  set finPorteUtc(DateTime? fin);
}

abstract interface class VideoSessionProvider {
  /// Entre dans la salle avec l'acces emis par le backend.
  Future<void> rejoindre(AccesSalle acces);

  /// Quitte la salle. Libere tout : pistes, rendus, ecouteurs, minuteries.
  Future<void> quitter();

  /// Ouvre ou ferme le micro.
  Future<void> reglerMicro({required bool actif});

  /// Ouvre ou ferme la camera. Sans effet si le jeton ne le permet pas.
  Future<void> reglerCamera({required bool actif});

  /// D14 (S0.2) : la phrase du navigateur quand la camera n'a pas pu
  /// s'allumer d'elle-meme a l'entree, ou `null`. Un allumage reussi
  /// l'efface.
  String? get erreurCameraEntree;

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

  /// Pose un paquet de donnees applicatif sur le canal de la salle.
  ///
  /// [fiable] a `true` : ordonne et garanti. A `false` : perte acceptee, pour
  /// ce qui doit etre FRAIS plutot que complet -- un pointeur, un apercu de
  /// trait. Exiger une garantie de livraison pour trente paquets par seconde
  /// encombrerait le canal qui porte les tours de page.
  ///
  /// [destinataires] vide vaut diffusion a toute la salle ; sinon le paquet
  /// n'est remis qu'a ces identites (rappel discret).
  ///
  /// **Leve [EchecPublicationDonnees]. N'avale JAMAIS.**
  Future<void> publierDonnees({
    required String sujet,
    required List<int> charge,
    required bool fiable,
    List<String> destinataires = const <String>[],
  });

  /// Les paquets de donnees recus, **tous sujets confondus**.
  ///
  /// Flux de diffusion, **sans rejeu** : contrairement a [contenusPresentes],
  /// il ne rend pas le dernier paquet a un nouvel abonne. La reprise d'etat
  /// d'un protocole applicatif ne passe pas par le realtime mais par un port
  /// backend qui lui est propre.
  ///
  /// Il livre aussi les paquets de sujet [sujetContenuPresente] : chaque
  /// consommateur filtre son propre sujet. Un paquet vu sur deux flux
  /// distincts ne gene personne ; un paquet jete silencieusement, si.
  Stream<PaquetDonnees> get donneesRecues;

  /// L'acces courant, ou `null` hors salle.
  ///
  /// Permet a un adaptateur feature-level de lire les capacites signees sans
  /// se faire repasser l'`AccesSalle` par l'ecran, ce qui multiplierait les
  /// endroits ou il pourrait diverger.
  AccesSalle? get accesCourant;
}
