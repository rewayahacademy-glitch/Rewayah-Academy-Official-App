// Les Messages metier : le port et ses modeles (COM-MSG-1 ; spec section 3,
// COM-BR-01 et COM-BR-02).
//
// Un fil metier est TOUJOURS lie a un objet identifiable (Classe, eleve,
// dossier, mission, remplacement ; spec section 3.1). Il n'existe ni bouton
// global « Nouveau message », ni annuaire, ni coordonnee : les modeles ne
// portent aucun numero, aucune adresse electronique (le `Participant` du socle
// n'en a pas), et le port ne sait pas « ecrire a quelqu'un », seulement
// ouvrir le fil d'un objet.
//
// Les paires autorisees (spec section 3.2) sont decidees par le SERVEUR : un
// fil qu'il refuse est un fil ABSENT (`fil` rend `null`), jamais un fil vide
// ni un fil rendu avec une alerte (R-COM-02). L'ecran garde en plus une
// defense de surface : il ne rend pas un resume dont l'objet n'est pas un
// objet de fil metier (une annonce, une publication ou un canal n'y ont pas
// leur place, spec section 13.3 et section 14).
//
// Tant qu'aucun contrat n'existe, le port de production rend
// `CapaciteIndisponible('COM-BR-01')` (lecture) et `('COM-BR-02')` (envoi) :
// l'ecran dit « pas encore disponible », sans « Reessayer » ni liste vide
// inventee. La demonstration le remplace sous `environnementAutoriseDemo`.
//
// Recherche (ThreadSearch, COM-BR-01, reserve COM-BR-A05) : en V1, un filtre
// local sur `fils()` (`recherche_fils.dart`) ; il ne peut donc jamais rendre
// plus que ce que la personne a le droit de lire. Aucune methode
// `rechercher` n'est ajoutee tant que BR-1 n'a pas confirme le besoin d'une
// recherche serveur.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/communications/port_pieces_jointes.dart';

export '../../core/communications/modeles_communication.dart';
export '../../core/communications/port_pieces_jointes.dart'
    show EtatPieceJointe, NaturePieceJointe, PieceJointe, ReferencePieceJointe;

/// Les natures d'objet qu'un fil metier peut porter (spec section 3.1).
///
/// Une publication, un canal, un message ou une annonce ne sont pas des
/// objets de fil metier : un resume qui en porterait un n'est pas rendu.
const Set<TypeObjetLie> typesObjetsFilMetier = <TypeObjetLie>{
  TypeObjetLie.classe,
  TypeObjetLie.eleve,
  TypeObjetLie.dossier,
  TypeObjetLie.mission,
  TypeObjetLie.remplacement,
  TypeObjetLie.autre,
};

/// Vrai si [resume] peut figurer dans la liste des Messages metier.
bool estFilMetier(ResumeFil resume) =>
    typesObjetsFilMetier.contains(resume.objet.type);

/// Une capacite d'action sur un fil, portee par le fil rendu (COM-BR-16,
/// forme b : la capacite liee a un objet voyage avec l'objet). Fermee par
/// defaut ; le serveur refuse quand meme.
enum CapaciteFil {
  /// Ecrire et envoyer un message dans ce fil.
  ecrire,
}

/// Un objet du contexte d'un fil, et si la personne peut encore l'ouvrir.
///
/// Un objet devenu inaccessible (eleve retire de la Classe, dossier clos)
/// reste nomme pour que le fil se comprenne, mais n'ouvre plus rien (spec
/// section 25, « objet lie inaccessible »).
@immutable
class ElementContexteFil {
  /// Cree l'element.
  const ElementContexteFil({required this.objet, this.accessible = true});

  /// L'objet, deja nettoye par le port.
  final ObjetLie objet;

  /// Faux : l'objet n'est plus accessible a la personne qui lit.
  final bool accessible;

  /// Le chemin qui ouvre l'objet, seulement s'il est accessible et qu'il en
  /// a un.
  String? get destination => accessible ? objet.destination : null;
}

/// Un fil metier ouvert : son contexte, ses participants, ses messages.
@immutable
class FilMetier {
  /// Cree le fil. [contexte] ne peut pas etre vide : son premier element est
  /// l'objet principal du fil.
  FilMetier({
    required this.id,
    required List<ElementContexteFil> contexte,
    required List<Participant> participants,
    required List<MessageCommunication> messages,
    this.attention = IndicateurAttention.aucun,
    Set<CapaciteFil> capacites = const <CapaciteFil>{},
  }) : assert(contexte.isNotEmpty, 'Un fil metier est lie a un objet.'),
       contexte = List<ElementContexteFil>.unmodifiable(contexte),
       participants = List<Participant>.unmodifiable(participants),
       messages = List<MessageCommunication>.unmodifiable(messages),
       capacites = Set<CapaciteFil>.unmodifiable(capacites);

  /// Identifiant du fil.
  final String id;

  /// Les objets du fil, le principal d'abord (Classe, puis eleve...).
  final List<ElementContexteFil> contexte;

  /// Les personnes du fil, la personne qui lit comprise ([Participant.estSoi]).
  final List<Participant> participants;

  /// Les messages, du plus ancien au plus recent.
  final List<MessageCommunication> messages;

  /// Ce que le badge doit dire de ce fil.
  final IndicateurAttention attention;

  /// Les actions ouvertes a la personne qui lit.
  final Set<CapaciteFil> capacites;

  /// L'objet principal du fil.
  ObjetLie get objet => contexte.first.objet;

  /// Les autres personnes du fil.
  List<Participant> get interlocuteurs => <Participant>[
    for (final Participant p in participants)
      if (!p.estSoi) p,
  ];

  /// Vrai si la personne qui lit peut [capacite] dans ce fil.
  bool peut(CapaciteFil capacite) => capacites.contains(capacite);

  /// Les pieces jointes du fil (vocaux compris), de la plus recente a la
  /// plus ancienne.
  List<PieceJointe> get piecesJointes => <PieceJointe>[
    for (final MessageCommunication m in messages.reversed) ...m.piecesJointes,
  ];
}

/// Qui est l'interlocuteur, vu de l'objet de la page (COM-MSG-2) : un fait
/// rendu par le serveur sur la personne a qui l'on ecrit, jamais le role de
/// la personne qui lit. Il choisit seulement le libelle de l'entree.
enum NatureInterlocuteur {
  /// La famille d'un eleve (son tuteur).
  famille,

  /// L'Administration ou l'equipe autorisee.
  administration,

  /// Une autre personne (enseignant, eleve adulte, controleur) : l'entree
  /// la nomme.
  personne,
}

/// Une conversation qu'une page peut ouvrir sur son objet (COM-MSG-2 ; spec
/// section 3.2, section 21) : l'interlocuteur deja autorise, l'objet precis
/// du fil (la Classe, un eleve de la Classe, le dossier), et le fil s'il
/// existe deja.
///
/// La liste est decidee par le SERVEUR (paires autorisees, section 3.2) :
/// une famille d'un autre foyer n'y figure jamais (R-COM-02). Aucune
/// coordonnee : le [Participant] du socle n'en porte pas.
@immutable
class ConversationPossible {
  /// Cree la conversation possible.
  const ConversationPossible({
    required this.interlocuteur,
    required this.objet,
    this.nature = NatureInterlocuteur.personne,
    this.filId,
    this.attention = IndicateurAttention.aucun,
  });

  /// La personne a qui l'on ecrit, deja autorisee.
  final Participant interlocuteur;

  /// Ce que l'interlocuteur est vu de l'objet (libelle de l'entree).
  final NatureInterlocuteur nature;

  /// L'objet du fil : celui que `filPourObjet` recoit quand le fil manque.
  final ObjetLie objet;

  /// Le fil existant, ou `null` s'il reste a ouvrir.
  final String? filId;

  /// Ce que le badge doit dire du fil existant.
  final IndicateurAttention attention;
}

/// Les Messages metier (COM-BR-01, COM-BR-02).
abstract interface class PortMessagesMetier {
  /// Les fils que la personne a le droit de lire, le plus recent d'abord.
  /// Un fil refuse n'y figure pas.
  Future<List<ResumeFil>> fils();

  /// Le fil [filId], ou `null` s'il n'existe pas ou si le serveur le refuse
  /// a la personne qui lit (jamais un fil vide a sa place).
  Future<FilMetier?> fil(String filId);

  /// Le fil canonique de l'objet ([type], [objetId]), cree par le serveur
  /// s'il manque ; `null` si la paire n'est pas autorisee (spec section 3.2).
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId);

  /// Les conversations que la page de l'objet ([type], [objetId]) peut
  /// ouvrir (une Classe, un dossier), dans l'ordre du serveur (COM-MSG-2).
  /// Vide : aucune paire autorisee sur cet objet.
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  );

  /// Marque le fil comme lu : ses non-lus baissent dans `fils()`.
  Future<void> marquerLu(String filId);

  /// Envoie [texte] dans le fil [filId]. Le futur se termine sur l'accuse du
  /// serveur et echoue sinon ; [cleIdempotence] est generee par l'ecran et
  /// rejouee telle quelle a chaque nouvel essai du meme message.
  Future<void> envoyer(String filId, String texte, String cleIdempotence);
}

/// Les Messages metier tant qu'aucun contrat n'existe : tout rend
/// [CapaciteIndisponible], jamais une liste vide ni un faux succes.
class MessagesMetierIndisponibles implements PortMessagesMetier {
  /// Cree l'implementation.
  const MessagesMetierIndisponibles();

  @override
  Future<List<ResumeFil>> fils() =>
      Future<List<ResumeFil>>.error(const CapaciteIndisponible('COM-BR-01'));

  @override
  Future<FilMetier?> fil(String filId) =>
      Future<FilMetier?>.error(const CapaciteIndisponible('COM-BR-01'));

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) =>
      Future<FilMetier?>.error(const CapaciteIndisponible('COM-BR-01'));

  @override
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  ) => Future<List<ConversationPossible>>.error(
    const CapaciteIndisponible('COM-BR-01'),
  );

  @override
  Future<void> marquerLu(String filId) =>
      Future<void>.error(const CapaciteIndisponible('COM-BR-01'));

  @override
  Future<void> envoyer(String filId, String texte, String cleIdempotence) =>
      Future<void>.error(const CapaciteIndisponible('COM-BR-02'));
}

/// Les Messages metier employes par l'application. `lib/main.dart` ne
/// branche rien avant BR-1 ; la demonstration le remplace par
/// `overrideWithValue`, sous `environnementAutoriseDemo`.
final Provider<PortMessagesMetier> portMessagesMetierProvider =
    Provider<PortMessagesMetier>(
      (Ref ref) => const MessagesMetierIndisponibles(),
    );
