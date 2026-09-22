import 'package:flutter/foundation.dart';

import '../tc_groupe/group_summary_vm.dart';
import '../tc_horloge/session_clock_vm.dart';
import '../video/video_session_provider.dart';

/// Qui enseigne, tel que l'en-tete de la Classe Live le nomme.
///
/// **Sayyid / Sayyida, jamais Ustaz** (decision D-02).
///
/// [photoCleOuUrl] est une **cle de stockage ou une URL deja resolue**, jamais
/// une URL signee persistee : une URL signee expire, et le depot a deja inscrit
/// cette lecon dans `lib/core/appairage/service_avatar.dart`. `null` signale une
/// photo **manquante**, ce qui est un etat d'erreur explicite et non un avatar
/// generique (decision D-01).
@immutable
class EnseignantDeClasse {
  /// Declare l'enseignant de la seance.
  const EnseignantDeClasse({
    required this.nomAffichage,
    this.titre,
    this.photoCleOuUrl,
    this.photoInconnue = false,
  });

  /// Le nom d'affichage autorise. Prenom, ou prenom et nom d'affichage.
  final String nomAffichage;

  /// Le titre. `null` tant que la base ne le porte pas.
  final TitreEnseignant? titre;

  /// La photo professionnelle publique. `null` = manquante, a signaler --
  /// sauf quand [photoInconnue] dit que l'appelant ne l'a pas lue.
  final String? photoCleOuUrl;

  /// Vrai quand l'ecran d'entree n'a pas lu la photo (un billet de salle ne la
  /// porte pas). On ne signale alors pas une photo « manquante » qu'on n'a
  /// pas cherchee : ce serait accuser l'enseignant sur une ignorance.
  final bool photoInconnue;

  /// Vrai quand la photo manque **et** qu'on le sait.
  bool get photoManquante => photoCleOuUrl == null && !photoInconnue;
}

/// La seance live, telle que la coque de classe et ses invites la lisent.
///
/// **Contrat produit par Agent E**, consomme par Agent G pour l'annonce
/// d'observation et par Agent Z pour la barre « Cours en cours ».
///
/// Il reunit ce qui identifie la seance -- la seance, le groupe, l'enseignant,
/// l'horloge -- et l'etat du lien tel que le **moteur existant** le rapporte.
/// [etatLien] est l'`EtatSalle` de `lib/core/video/` : ce n'est pas une
/// septieme machine a etats, c'est celle du moteur, transportee. Le produit en
/// compte deja assez (`VueSalle`, `etat_presence()`, `etatAccueilEleve`) pour
/// qu'une de plus soit une faute.
@immutable
class SessionLiveVM {
  /// Cree la vue d'une seance live.
  const SessionLiveVM({
    required this.sessionId,
    required this.libelleGroupe,
    required this.etatLien,
    this.groupeId,
    this.enseignant,
    this.horloge,
    this.supportActifId,
  });

  /// La seance.
  final String sessionId;

  /// Le groupe dont cette seance est l'etat temporaire.
  ///
  /// **Le Groupe est permanent, la Classe Live est un etat du Groupe**
  /// (decision D-19). `null` quand la seance a ete rejointe par son billet
  /// sans groupe connu de l'appelant (controleur, tuteur qui assiste, eleve
  /// venu de l'Accueil) : le cours existe, il n'a pas d'Espace Groupe ou
  /// revenir, et aucun travail ne peut y etre pose.
  final String? groupeId;

  /// Le nom familier du groupe, jamais un code backend.
  final String libelleGroupe;

  /// Qui enseigne. `null` quand l'appelant ne le sait pas encore : l'en-tete
  /// n'ecrit alors ni nom ni « photo manquante », plutot qu'un enseignant
  /// invente.
  final EnseignantDeClasse? enseignant;

  /// L'horloge de la seance. `null` tant que le port d'Agent A n'est pas
  /// branche : l'en-tete affiche alors le groupe sans temps restant, plutot
  /// qu'un compte a rebours calcule sur l'horloge de l'appareil.
  final SessionClockVM? horloge;

  /// L'etat du lien, rapporte par le moteur temps reel existant.
  final EtatSalle etatLien;

  /// La ressource presentee en ce moment. `null` = aucun support actif.
  ///
  /// **C'est ce seul champ qui decide de la composition de l'ecran** : support
  /// present, le support domine et la video devient secondaire ; support absent,
  /// la video reprend de l'espace (spec section 9.1).
  final String? supportActifId;

  /// Vrai quand un support est presente au groupe.
  bool get avecSupport => supportActifId != null;

  /// Vrai des que l'entree a abouti, quel que soit l'etat du lien.
  ///
  /// Les quatre etats qui suivent l'entree ont une chose en commun : **la
  /// seance continue**. Rien ne se demonte, aucune commande ne se ferme.
  bool get enSalle =>
      etatLien == EtatSalle.connecte ||
      etatLien == EtatSalle.instable ||
      etatLien == EtatSalle.reconnexion ||
      etatLien == EtatSalle.retabli;

  /// Vrai quand le lien est perdu et que le moteur tente de le retablir.
  bool get enReconnexion => etatLien == EtatSalle.reconnexion;

  /// Le temps restant, quand l'horloge le donne.
  ///
  /// **Jamais calcule ici** : il vient de `SessionClockVM`, lui meme derive de
  /// l'instant serveur de reference et non de l'horloge de l'appareil.
  Duration? get restant => horloge?.restant;

  /// La meme seance, avec un autre support actif.
  SessionLiveVM avecSupportActif(String? resourceId) => SessionLiveVM(
    sessionId: sessionId,
    groupeId: groupeId,
    libelleGroupe: libelleGroupe,
    enseignant: enseignant,
    etatLien: etatLien,
    horloge: horloge,
    supportActifId: resourceId,
  );

  /// La meme seance, avec un autre etat de lien.
  SessionLiveVM avecEtatLien(EtatSalle etat) => SessionLiveVM(
    sessionId: sessionId,
    groupeId: groupeId,
    libelleGroupe: libelleGroupe,
    enseignant: enseignant,
    etatLien: etat,
    horloge: horloge,
    supportActifId: supportActifId,
  );
}
