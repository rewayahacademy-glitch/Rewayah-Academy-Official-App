import 'package:flutter/foundation.dart';

import '../../core/video/service_video.dart';
import '../../core/video/video_session_provider.dart';

/// Le role tenu dans la seance, tel que le jeton le nomme.
///
/// **Il ne vient pas de la session, il vient du jeton.** `sessionProvider` porte
/// le role du compte, que le client a lu lui-meme ; celui-ci est signe par le
/// backend et c'est lui que le serveur LiveKit fera respecter. Choisir la vue
/// d'apres le compte donnerait un ecran qui promet des commandes que le jeton
/// refuse.
///
/// Quatre valeurs, et non trois : le catalogue nomme `ELV-03`, `ENS-03` et
/// `CTR-02`, mais `participant_role` connait aussi `guardian_observer`, le
/// tuteur qui presse « Assister » depuis `TUT-01`. Il entre muet et **visible**,
/// la ou le controleur entre invisible.
enum RoleSalle {
  /// L'enseignant. Seul a publier une image sans condition.
  enseignant,

  /// L'eleve. Sa camera depend de la politique de son profil (ADR-009).
  eleve,

  /// Le tuteur qui assiste. Il voit, il entend, il ne publie rien, et
  /// l'enseignant le voit arriver.
  tuteurObservateur,

  /// Le controleur qualite. Invisible, muet, et inscrit au journal (ADR-011).
  controleur,

  /// Un role que cette version de l'application ne connait pas.
  ///
  /// **Le repli est le plus ferme, pas le plus ouvert** : le jour ou la base
  /// gagnera un cinquieme role, une application non mise a jour donnera une
  /// salle en lecture seule plutot qu'un jeu de commandes devine.
  inconnu;

  /// Lit la valeur de `participant_role` rendue par le backend.
  static RoleSalle depuis(String? valeur) => switch (valeur) {
    'teacher' => RoleSalle.enseignant,
    'student' => RoleSalle.eleve,
    'guardian_observer' => RoleSalle.tuteurObservateur,
    'masked_controller' => RoleSalle.controleur,
    _ => RoleSalle.inconnu,
  };
}

/// Pourquoi la salle n'ouvre pas.
///
/// **Quatre causes, et pas les motifs du backend tels quels.** `MotifRefusSalle`
/// decrit ce que le backend a repondu ; celle-ci decrit ce que l'usager doit
/// faire, ce qui n'est pas la meme liste : un micro absent est une impasse que
/// le backend ne connait pas, et il se repare sur l'appareil.
///
/// Le backend, lui, ne dit jamais pourquoi il refuse l'acces -- ni « seance
/// inconnue », ni « vous n'y etes pas inscrit », ni « trop tot » : un
/// participant qui tente une salle qui n'est pas la sienne n'a pas a l'apprendre.
/// [acces] couvre donc les trois cas d'un seul message, et c'est voulu.
enum CauseImpasse {
  /// Aucun micro utilisable, ou permission refusee. Se repare ici.
  materiel,

  /// La salle n'est pas ouverte a cette personne, a cet instant.
  acces,

  /// La video n'est pas branchee sur ce deploiement. Rien a faire pour
  /// l'usager, et le dire evite qu'il cherche la faute sur son appareil.
  configuration,

  /// Le reseau ou le backend n'a pas repondu. Se reessaye.
  reseau;

  /// Traduit le refus du backend en ce que l'usager peut comprendre.
  static CauseImpasse depuis(MotifRefusSalle motif) => switch (motif) {
    MotifRefusSalle.videoNonConfiguree ||
    MotifRefusSalle.fournisseurIndisponible => CauseImpasse.configuration,
    MotifRefusSalle.acces => CauseImpasse.acces,
    MotifRefusSalle.reseau => CauseImpasse.reseau,
  };

  /// Vrai quand reessayer a un sens. Un refus d'acces n'en a pas : l'heure
  /// n'aura pas change, et un bouton qui echoue deux fois use la confiance.
  bool get seReessaye => this == materiel || this == reseau;
}

/// Ou en est l'entree en salle.
///
/// Les trois premieres phases sont des attentes, et elles se disent chacune par
/// **un mot different** : « Verification de votre micro » et « Connexion au
/// cours » n'echouent pas pour les memes raisons, donc ne se corrigent pas de la
/// meme facon. Un unique « Chargement... » obligerait a deviner.
enum PhaseSalle {
  /// Le materiel est en cours d'inspection (pre-vol).
  materiel,

  /// Le jeton d'entree est demande au backend.
  ouverture,

  /// La connexion au serveur temps reel est en cours.
  connexion,

  /// En salle, lien sain.
  enSalle,

  /// En salle, lien degrade. **La seance continue** : c'est un avertissement,
  /// pas une coupure, et il se dit par un mot -- jamais par la seule couleur
  /// d'une pastille (invariant J7).
  instable,

  /// Le lien est perdu, le SDK retablit la connexion. **Ce n'est pas une
  /// absence** : la seance continue, l'ecran ne se demonte pas.
  reconnexion,

  /// En salle, apres une coupure qui vient d'etre refermee.
  ///
  /// Une phase a elle seule, et non un retour silencieux a [enSalle] : quelqu'un
  /// qui a vu l'ecran annoncer une reconnexion a besoin de lire qu'elle a
  /// abouti. Sans mot de fin, il reste a se demander si le cours l'entend.
  retabli,

  /// Une impasse, avec sa cause. C'est le seul etat qui offre une sortie.
  refus,
}

/// Ce que la salle montre, a un instant donne.
///
/// **Fonction pure, comme `deciderRedirection` et `etatAccueilEleve`** : les
/// quatre roles, les six phases et les quatre refus se verifient sans monter
/// d'ecran, sans reseau et sans SDK. C'est la seule maniere de tester une salle
/// dont la connexion reelle n'est pas encore prouvable.
@immutable
class VueSalle {
  const VueSalle._({
    required this.phase,
    required this.cause,
    required this.role,
    required this.peutParler,
    required this.peutMontrer,
    required this.peutPresenter,
    required this.invisible,
    required this.moi,
    required this.dominant,
    required this.autres,
    required this.qualite,
  });

  /// Calcule la vue a partir de tout ce que l'ecran observe.
  factory VueSalle.depuis({
    required bool materielPret,
    required AccesSalle? acces,
    required EtatSalle etatMoteur,
    required List<ParticipantSalle> participants,
    required QualiteLien qualite,
    CauseImpasse? impasse,
  }) {
    final RoleSalle role = RoleSalle.depuis(acces?.role);
    final CapacitesSalle? capacites = acces?.capacites;
    final bool invisible = capacites?.invisible ?? false;

    // L'ordre des tests est l'ordre de la verite : une impasse connue passe
    // devant tout le reste, y compris devant un moteur qui se croirait
    // connecte.
    final PhaseSalle phase;
    if (impasse != null) {
      phase = PhaseSalle.refus;
    } else if (!materielPret) {
      phase = PhaseSalle.materiel;
    } else if (acces == null) {
      phase = PhaseSalle.ouverture;
    } else {
      phase = switch (etatMoteur) {
        EtatSalle.connecte => PhaseSalle.enSalle,
        EtatSalle.instable => PhaseSalle.instable,
        EtatSalle.reconnexion => PhaseSalle.reconnexion,
        EtatSalle.retabli => PhaseSalle.retabli,
        EtatSalle.echec => PhaseSalle.refus,
        EtatSalle.absent || EtatSalle.connexion => PhaseSalle.connexion,
      };
    }

    // **Le controleur ne figure pas dans sa propre liste.** LiveKit le cache
    // des autres ; il ne se cache pas de lui-meme. Sans ce retrait, son ecran
    // afficherait trois personnes la ou l'enseignant en voit deux, et la
    // verification visuelle de l'invisibilite -- « il voit exactement ce que
    // voit l'enseignant » -- ne voudrait plus rien dire.
    final ParticipantSalle? moi = invisible ? null : _local(participants);
    final List<ParticipantSalle> distants = participants
        .where((ParticipantSalle p) => !p.estLocal)
        .toList();

    final ParticipantSalle? dominant = _dominant(distants, role);

    return VueSalle._(
      phase: phase,
      // Un moteur qui echoue sans cause nommee est un echec de lien : c'est la
      // seule cause qui explique un silence, et la seule qui se reessaye.
      cause: impasse ?? CauseImpasse.reseau,
      role: role,
      peutParler: capacites?.peutPublier ?? false,
      peutMontrer: capacites?.peutPublierVideo ?? false,
      peutPresenter: capacites?.peutPublierDonnees ?? false,
      invisible: invisible,
      moi: moi,
      dominant: dominant,
      autres: distants
          .where((ParticipantSalle p) => p.identite != dominant?.identite)
          .toList(),
      qualite: qualite,
    );
  }

  /// Soi-meme dans la liste publiee par le moteur.
  static ParticipantSalle? _local(List<ParticipantSalle> participants) {
    for (final ParticipantSalle candidat in participants) {
      if (candidat.estLocal) {
        return candidat;
      }
    }
    return null;
  }

  /// Qui vient en premier.
  ///
  /// Pour l'eleve, c'est l'enseignant : la fiche produit l'ecrit, et l'ADR-001
  /// en donne la raison pedagogique -- les makharij se lisent sur une bouche.
  /// Pour l'enseignant, c'est l'eleve, pour la meme raison, en sens inverse.
  /// Pour qui observe, l'enseignant d'abord, faute de quoi le premier venu.
  ///
  /// Depuis le pivot groupes, « en premier » ne veut plus dire « en grand » :
  /// avec cinq eleves, la scene est une galerie et personne n'occupe seul le
  /// cadre. Ce que ce choix decide est donc l'**ordre de lecture**, ce qui
  /// revient au meme a deux et reste juste a six.
  static ParticipantSalle? _dominant(
    List<ParticipantSalle> distants,
    RoleSalle moi,
  ) {
    if (distants.isEmpty) {
      return null;
    }
    final String recherche = moi == RoleSalle.enseignant
        ? 'student'
        : 'teacher';
    for (final ParticipantSalle candidat in distants) {
      if (candidat.role == recherche) {
        return candidat;
      }
    }
    return distants.first;
  }

  /// Ou en est l'entree.
  final PhaseSalle phase;

  /// La cause de l'impasse. Ne vaut que quand [phase] est [PhaseSalle.refus] ;
  /// le defaut est le reseau, la cause la plus probable d'un echec muet.
  final CauseImpasse cause;

  /// Le role tenu, tel que le jeton le nomme.
  final RoleSalle role;

  /// Le jeton autorise la voix. Faux pour un observateur et un controleur.
  final bool peutParler;

  /// Le jeton autorise l'image. Faux pour un eleve dont la politique camera
  /// l'interdit, ce qui est le defaut d'un mineur.
  final bool peutMontrer;

  /// Le jeton autorise la diffusion du contenu presente (`can_publish_data`).
  ///
  /// Reserve a l'enseignant : c'est lui qui presente le Coran. Un enseignant
  /// sans ce droit ne doit voir AUCUNE commande de presentation, plutot qu'un
  /// bouton que le moteur refuserait en silence -- l'invariant J7 vaut ici comme
  /// ailleurs : un etat ne se dit jamais par l'absence de reaction.
  ///
  /// C'est la premiere consommation de `CapacitesSalle.peutPublierDonnees` du
  /// depot : la capacite existait cote jeton depuis le lot N2, sans lecteur.
  /// Elle est derivee en booleen plutot que d'ouvrir l'`AccesSalle` -- donc le
  /// jeton signe -- a toutes les features (`CONTRACT_REQUEST_B` §1).
  final bool peutPresenter;

  /// Personne ne voit ce participant, et il ne se voit pas lui-meme.
  final bool invisible;

  /// Sa propre vignette. Nulle quand on est invisible.
  final ParticipantSalle? moi;

  /// Qui occupe le grand cadre.
  final ParticipantSalle? dominant;

  /// Les autres participants distants, hors le dominant.
  final List<ParticipantSalle> autres;

  /// La qualite du lien local, telle que le SDK la rapporte.
  final QualiteLien qualite;

  /// Vrai quand on est le seul dans la salle.
  bool get seulEnSalle => dominant == null && autres.isEmpty;

  /// Vrai des que l'entree a abouti, quel que soit l'etat du lien.
  ///
  /// Les quatre phases qui suivent l'entree -- en salle, instable, reconnexion,
  /// retabli -- ont une chose en commun : **la seance continue.** Les commandes
  /// restent actives, l'ecran ne se demonte pas, le bandeau reste la. Reunir ce
  /// fait ici plutot que dans chaque widget evite qu'une cinquieme phase n'en
  /// oublie une au passage.
  bool get dansLaSalle =>
      phase == PhaseSalle.enSalle ||
      phase == PhaseSalle.instable ||
      phase == PhaseSalle.reconnexion ||
      phase == PhaseSalle.retabli;

  /// La liste des participants est-elle montree a ce role ?
  ///
  /// L'enseignant en a besoin pour savoir qui est la -- et depuis le pivot du
  /// 19 septembre 2026, ce sont cinq ou six enfants, pas un seul. Le controleur
  /// l'a comme **test de sa propre invisibilite** : il doit y lire exactement ce
  /// que l'enseignant y lit.
  ///
  /// L'eleve ne la voit pas, et le motif a change. **L'ancien -- « une seance
  /// est plafonnee a deux participants (ADR-004) » -- est invalide depuis le
  /// pivot groupes** : une liste de six lignes apprendrait quelque chose. Ce qui
  /// tient encore : un enfant en mode enfant n'a droit qu'a deux commandes, et
  /// donner a un mineur la liste nominative de ses camarades est une decision de
  /// protection des mineurs, pas un choix d'interface. Elle appartient a
  /// l'operateur ; elle n'est donc pas prise ici.
  bool get voitLesParticipants =>
      role == RoleSalle.enseignant || role == RoleSalle.controleur;

  /// La liste des participants, dans l'ordre ou elle se lit.
  ///
  /// **Soi-meme en premier quand on est visible, et absent sinon.** C'est ce qui
  /// fait tenir le test visuel de l'ADR-011 : l'enseignant y lit deux lignes,
  /// lui et son eleve ; le controleur y lit les deux memes personnes, sans
  /// s'y trouver. Les deux ecrans montrent donc exactement la meme salle.
  List<ParticipantSalle> get participantsListes => <ParticipantSalle>[
    if (moi case final ParticipantSalle local) local,
    if (dominant case final ParticipantSalle grand) grand,
    ...autres,
  ];

  /// Le lien merite-t-il d'etre dit en clair ?
  ///
  /// Seules les deux valeurs basses se disent. Annoncer « connexion
  /// excellente » pendant un cours n'apporte rien et occuperait la place que
  /// le Coran prendra.
  bool get lienADire =>
      qualite == QualiteLien.mediocre || qualite == QualiteLien.perdue;
}
