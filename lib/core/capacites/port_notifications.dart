import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../communications/modeles_communication.dart' show NiveauAttention;
import '../router/chemin_retour.dart';
import 'capacite_indisponible.dart';

export '../communications/modeles_communication.dart' show NiveauAttention;

/// La nature d'une notification : le catalogue initial par role de la spec
/// Communications V1 (section 13.2). Le port la donne, deja choisie par le
/// serveur pour la personne connectee ; l'ecran n'en deduit jamais un role,
/// il n'en tire que le mot qui la nomme (« Annonce de Classe »).
enum TypeNotification {
  /// Une annonce de Classe (tuteur, eleve adulte) : ouvre l'annonce, puis sa
  /// Classe (R-COM-12).
  annonceClasse,

  /// Un changement de seance (tuteur, eleve adulte).
  changementSeance,

  /// La validation ou le refus d'un dossier (tuteur).
  decisionDossier,

  /// Un message metier (tuteur, eleve adulte, enseignant).
  messageMetier,

  /// Une reponse attendue de la personne (tuteur).
  reponseAttendue,

  /// L'acces ou un paiement, seulement si le contrat existe (tuteur).
  accesFinance,

  /// Une observation, seulement si la politique existe (tuteur).
  observation,

  /// Un travail ou une ressource deja emis par le module existant (eleve
  /// adulte).
  travailRessource,

  /// Une annonce de la direction (enseignant).
  annonceDirection,

  /// Un changement de planning (enseignant).
  changementPlanning,

  /// Un remplacement, seulement si le contrat existe (enseignant).
  remplacement,

  /// Une mention dans la Communaute enseignants.
  mentionCommunaute,

  /// Une reponse dans la Communaute enseignants.
  reponseCommunaute,

  /// Un message de l'Administration (enseignant).
  messageAdministration,

  /// Un dossier a traiter (Administration).
  dossierATraiter,

  /// Un signalement de la Communaute (Administration).
  signalementCommunaute,

  /// Une reponse a un fil metier autorise (Administration).
  reponseFil,

  /// Une annonce planifiee a publier (Administration).
  annoncePlanifiee,

  /// Un evenement operationnel deja fourni par un module existant
  /// (Administration).
  evenementOperationnel,

  /// Une mission (controleur).
  mission,

  /// Un changement de mission (controleur).
  changementMission,

  /// Une reponse de l'Administration (controleur).
  reponseAdministration,

  /// Une mention dans Le Studio (equipe interne).
  mentionStudio,

  /// Une reponse dans Le Studio (equipe interne).
  reponseStudio,

  /// Une decision demandee (equipe interne).
  decisionDemandee,

  /// Un element assigne (equipe interne).
  elementAssigne,

  /// Une annonce interne (equipe interne).
  annonceInterne,

  /// Un evenement contextuel autorise (equipe interne).
  evenementContextuel,

  /// Une notification sans type connu : les notifications d'avant le
  /// catalogue, et tout type que l'ecran ne sait pas encore nommer.
  autre,
}

/// Une notification.
///
/// Le nom `NotificationTuteur` est garde (COM-0, matrice : un renommage se
/// ferait sur validation) : la meme notification sert desormais le centre
/// partage de chaque role (`/tuteur`, `/enseignant`, `/controleur`, `/admin`).
@immutable
class NotificationTuteur {
  /// Cree une notification. [destination] est validee a la construction : un
  /// chemin externe, la salle, la classe ou l'entree d'agent deviennent
  /// `null`, jamais un lien suivi.
  ///
  /// Les champs du centre partage (COM-ANN-1, COM-BR-09) sont **optionnels**
  /// : une notification qui ne les donne pas reste une notification lue, de
  /// niveau information, sans type ni mention, comme avant le catalogue.
  NotificationTuteur({
    required this.id,
    required this.titre,
    required this.date,
    String? destination,
    this.niveau = NiveauAttention.information,
    this.lue = true,
    this.type = TypeNotification.autre,
    this.mention = false,
    this.texte,
    this.annonceId,
  }) : destination = cheminRetourValide(destination);

  /// Identifiant.
  final String id;

  /// Titre, deja redige.
  final String titre;

  /// Date d'emission.
  final DateTime date;

  /// Chemin interne ouvert au toucher, deja valide. `null` : aucun.
  final String? destination;

  /// Le niveau d'attention (spec section 13.1) : information, a lire, action
  /// requise ou urgent. Toujours dit par un mot, jamais par la couleur seule.
  final NiveauAttention niveau;

  /// Vrai si la personne l'a deja lue. Le port le dit ; l'ecran ne le
  /// suppose jamais.
  final bool lue;

  /// La nature de la notification (catalogue section 13.2).
  final TypeNotification type;

  /// Vrai si la notification mentionne la personne (filtre « Mentions »).
  final bool mention;

  /// Le texte complet, deja redige, montre dans le detail ; `null` si le
  /// titre dit tout.
  final String? texte;

  /// L'annonce de Classe que la notification ouvre (R-COM-12) ; `null` pour
  /// toute autre notification. Un identifiant, jamais un contenu : l'annonce
  /// est relue par son propre port.
  final String? annonceId;

  /// Vrai si la notification attend une action : action requise ou urgent.
  bool get demandeAction => niveau.estAuMoins(NiveauAttention.actionRequise);

  /// La meme notification, marquee lue.
  NotificationTuteur marqueeLue() => NotificationTuteur(
    id: id,
    titre: titre,
    date: date,
    destination: destination,
    niveau: niveau,
    type: type,
    mention: mention,
    texte: texte,
    annonceId: annonceId,
  );
}

/// Les notifications de la personne connectee (contrat K6, COM-BR-09).
abstract interface class PortNotifications {
  /// Les notifications, la plus recente d'abord.
  Future<List<NotificationTuteur>> liste();

  /// Une notification precise.
  Future<NotificationTuteur?> detail(String id);
}

/// Un port qui sait enregistrer la lecture d'une notification (COM-BR-09,
/// `marquerLue(id)`).
///
/// Interface **separee** : un port qui ne la porte pas (le port neutre de
/// production, les doubles d'avant le centre partage) n'enregistre rien, et
/// l'ecran ne pretend pas qu'une notification est lue tant que le port ne
/// l'a pas relue ainsi.
abstract interface class PortLectureNotifications {
  /// Enregistre que la personne a lu la notification [id]. Leve en cas
  /// d'echec : l'ecran garde alors la notification non lue.
  Future<void> marquerLue(String id);
}

/// Un port qui sait marquer lues **toutes** les notifications de la personne
/// en une fois (fiche « Fraicheur et notifications » du 27/10/2026, ligne 14 :
/// ouvrir la page Notifications marque lues ; le point disparait sur tous les
/// appareils par la veille Realtime).
///
/// Interface separee, comme [PortLectureNotifications] : un port qui ne la
/// porte pas ne marque rien, et l'ecran ne pretend rien.
abstract interface class PortLectureGroupeeNotifications {
  /// Enregistre que la personne a lu toutes ses notifications non lues. Leve
  /// en cas d'echec : rien n'est alors suppose lu.
  Future<void> marquerToutesLues();
}

/// Les notifications tant qu'aucune source n'existe (DB-CPT-04) : « Les
/// notifications ne sont pas encore disponibles », cloche sans pastille,
/// jamais un faux etat vide. Aucun adaptateur prevu.
class NotificationsIndisponibles implements PortNotifications {
  /// Cree l'implementation.
  const NotificationsIndisponibles();

  @override
  Future<List<NotificationTuteur>> liste() =>
      Future<List<NotificationTuteur>>.error(
        const CapaciteIndisponible('DB-CPT-04'),
      );

  @override
  Future<NotificationTuteur?> detail(String id) =>
      Future<NotificationTuteur?>.error(
        const CapaciteIndisponible('DB-CPT-04'),
      );
}

/// Les notifications employees par l'application.
final Provider<PortNotifications> portNotificationsProvider =
    Provider<PortNotifications>(
      (Ref ref) => const NotificationsIndisponibles(),
    );
