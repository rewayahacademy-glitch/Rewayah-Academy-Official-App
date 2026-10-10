// Les modeles d'interface du socle Communications V1 (COM-F, spec section 19,
// section 20, lexique section 22).
//
// Ce sont des modeles NEUTRES : deja nettoyes par le port qui les rend, ils ne
// portent aucun role, aucune URL de stockage, aucun chemin interne, aucun
// jeton (spec section 12). Un widget lit ce qui est ici (un niveau
// d'attention, un objet lie, une fonction deja redigee), jamais le role de la
// personne connectee (lib/CLAUDE.md : un widget lit une capacite).
//
// Les voies (messages, vocal, Communaute, Studio, annonces) composent leurs
// propres modeles au-dessus de ceux-ci ; elles ne redefinissent pas un
// participant, un objet lie ou un niveau d'attention.

import 'package:flutter/foundation.dart';

import '../router/chemin_retour.dart';
import '../widgets/fil_discussion.dart' show EtatEnvoiMessage;
import 'port_pieces_jointes.dart';

export '../widgets/fil_discussion.dart' show EtatEnvoiMessage;

/// Le niveau d'attention d'un element (fil, notification, activite).
///
/// Ordonne du plus calme au plus pressant : [compareTo] et [estAuMoins]
/// suivent cet ordre. Un niveau ne se montre jamais par la couleur seule :
/// le badge non lu dit le mot et pose une icone (spec section 19,
/// `UnreadUrgencyBadge`).
enum NiveauAttention implements Comparable<NiveauAttention> {
  /// Pour information : rien a faire.
  information,

  /// A lire : un element non lu, sans action attendue.
  aLire,

  /// Action requise : la personne doit agir (lexique section 22).
  actionRequise,

  /// Urgent : a traiter avant le reste ; va en tete de l'ecran.
  urgent;

  @override
  int compareTo(NiveauAttention autre) => index - autre.index;

  /// Vrai si ce niveau vaut au moins [seuil].
  bool estAuMoins(NiveauAttention seuil) => index >= seuil.index;

  /// Le plus pressant de deux niveaux.
  NiveauAttention max(NiveauAttention autre) =>
      autre.index > index ? autre : this;
}

/// Ce qu'un badge d'attention doit dire d'un element : ses non-lus, son
/// niveau, une mention de la personne.
///
/// Calcule par le port, jamais deduit d'un role. [estVisible] est faux quand
/// il n'y a rien a signaler : le badge n'est alors pas rendu, plutot qu'un
/// « 0 » qui ne dit rien.
@immutable
class IndicateurAttention {
  /// Cree l'indicateur. [nonLus] ne peut pas etre negatif.
  const IndicateurAttention({
    this.nonLus = 0,
    this.niveau = NiveauAttention.information,
    this.mention = false,
  }) : assert(nonLus >= 0, 'Un nombre de non-lus est positif ou nul.');

  /// Rien a signaler.
  static const IndicateurAttention aucun = IndicateurAttention();

  /// Le nombre d'elements non lus.
  final int nonLus;

  /// Le niveau le plus pressant parmi les elements comptes.
  final NiveauAttention niveau;

  /// Vrai si la personne est mentionnee.
  final bool mention;

  /// Vrai s'il y a quelque chose a dire : un non-lu, une mention, ou un
  /// niveau au-dela de l'information.
  bool get estVisible =>
      nonLus > 0 || mention || niveau.estAuMoins(NiveauAttention.aLire);

  /// L'union de deux indicateurs (par exemple pour une section de canaux) :
  /// non-lus additionnes, niveau le plus pressant, mention si l'un mentionne.
  IndicateurAttention fusionner(IndicateurAttention autre) =>
      IndicateurAttention(
        nonLus: nonLus + autre.nonLus,
        niveau: niveau.max(autre.niveau),
        mention: mention || autre.mention,
      );

  @override
  bool operator ==(Object other) =>
      other is IndicateurAttention &&
      other.nonLus == nonLus &&
      other.niveau == niveau &&
      other.mention == mention;

  @override
  int get hashCode => Object.hash(nonLus, niveau, mention);

  @override
  String toString() =>
      'IndicateurAttention(nonLus: $nonLus, niveau: ${niveau.name}, '
      'mention: $mention)';
}

/// La nature de l'objet metier auquel un fil, une activite ou un element
/// enregistre est rattache (spec section 20, `ContextThreadHeader` ;
/// COM-BR-01).
enum TypeObjetLie {
  /// Une Classe.
  classe,

  /// Un eleve.
  eleve,

  /// Un dossier (admissions, famille).
  dossier,

  /// Une mission de controle.
  mission,

  /// Un remplacement.
  remplacement,

  /// Une publication de la Communaute enseignants.
  publication,

  /// Un canal du Studio.
  canal,

  /// Un message.
  message,

  /// Une annonce.
  annonce,

  /// Un autre objet autorise par le serveur.
  autre,
}

/// L'objet metier canonique auquel se rattache une communication.
///
/// **Toute action porte cet objet** (son [type] et son [id]), jamais
/// « l'objet courant » (lecons des roles, 15). [libelle] arrive deja nettoye
/// par le port (« Classe An-Nour », « Dossier de la famille ») : l'ecran ne le
/// compose pas. [destination] est un chemin interne valide a la construction
/// (`cheminRetourValide`) : une URL externe, un chemin vers la salle ou une
/// adresse de stockage deviennent `null`, jamais un lien suivi.
@immutable
class ObjetLie {
  /// Cree l'objet lie. [id] ne peut pas etre vide.
  ObjetLie({
    required this.type,
    required this.id,
    required this.libelle,
    String? destination,
  }) : assert(id.isNotEmpty, 'Un objet lie porte son identifiant.'),
       destination = cheminRetourValide(destination);

  /// La nature de l'objet.
  final TypeObjetLie type;

  /// L'identifiant de l'objet, tel que le serveur le connait.
  final String id;

  /// Le nom de l'objet, deja redige et nettoye par le port.
  final String libelle;

  /// Le chemin interne qui ouvre l'objet dans son module canonique ; `null`
  /// si l'objet n'a pas de destination (la ligne est alors rendue sans
  /// chevron, R-COM-11).
  final String? destination;

  /// Deux objets lies sont le meme objet s'ils ont le meme type et le meme
  /// identifiant : le libelle et la destination ne comptent pas.
  @override
  bool operator ==(Object other) =>
      other is ObjetLie && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'ObjetLie(${type.name}, $id)';
}

/// Une personne qui prend part a une communication, deja autorisee par le
/// serveur pour la personne qui lit.
///
/// Aucun role brut ici : [fonction] est un libelle deja redige
/// (« Enseignant de la Classe », « Administration »), jamais « admin » (K-53.6)
/// ni un genre en dur. Aucune coordonnee (telephone, adresse electronique) :
/// la spec section 3 refuse l'annuaire.
@immutable
class Participant {
  /// Cree le participant.
  const Participant({
    required this.id,
    required this.nomAffiche,
    this.fonction,
    this.estSoi = false,
  });

  /// Identifiant stable.
  final String id;

  /// Le nom tel qu'il s'affiche, deja autorise (prenom, ou titre et nom).
  final String nomAffiche;

  /// La fonction, deja redigee ; `null` si le serveur ne la donne pas.
  final String? fonction;

  /// Vrai pour la personne qui lit.
  final bool estSoi;

  @override
  bool operator ==(Object other) => other is Participant && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Participant($id)';
}

/// Un message d'une communication (fil metier, canal du Studio).
///
/// [etat] reprend [EtatEnvoiMessage] du fil partage (`FilDiscussion`) : un
/// message lu depuis le serveur vaut `envoye` ; un message ecrit ici reste
/// `enCours` jusqu'a l'accuse du serveur, et passe a `echec` (« non
/// confirme ») sinon, jamais a un faux succes (COM-BR-02).
@immutable
class MessageCommunication {
  /// Cree le message.
  const MessageCommunication({
    required this.id,
    required this.auteur,
    required this.texte,
    required this.envoyeLe,
    this.etat = EtatEnvoiMessage.envoye,
    this.piecesJointes = const <PieceJointe>[],
    this.mentionneSoi = false,
  });

  /// Identifiant stable, pour qu'un message ne soit jamais annonce deux fois.
  final String id;

  /// L'auteur, deja autorise.
  final Participant auteur;

  /// Le texte du message ; peut etre vide si le message ne porte qu'une
  /// piece jointe ou un vocal.
  final String texte;

  /// L'instant d'envoi (UTC), mis en mots par l'ecran.
  final DateTime envoyeLe;

  /// L'etat d'envoi.
  final EtatEnvoiMessage etat;

  /// Les pieces jointes (vocal compris), references opaques seulement.
  final List<PieceJointe> piecesJointes;

  /// Vrai si le message mentionne la personne qui lit.
  final bool mentionneSoi;

  /// Vrai si le message a ete ecrit par la personne qui lit.
  bool get deSoi => auteur.estSoi;
}

/// Le resume d'un fil, pour une liste de fils (messages metier) ou de
/// discussions.
///
/// Un fil n'existe a l'ecran que si le serveur l'a autorise : un refus est un
/// fil absent, jamais un fil vide (COM-BR-01).
@immutable
class ResumeFil {
  /// Cree le resume.
  const ResumeFil({
    required this.id,
    required this.objet,
    required this.interlocuteurs,
    this.apercu,
    this.dernierMessageLe,
    this.attention = IndicateurAttention.aucun,
  });

  /// Identifiant du fil.
  final String id;

  /// L'objet metier du fil (Classe, eleve, dossier, mission...).
  final ObjetLie objet;

  /// Les autres personnes du fil, deja autorisees.
  final List<Participant> interlocuteurs;

  /// Le debut du dernier message, deja tronque par le port ; `null` si aucun.
  final String? apercu;

  /// L'instant du dernier message (UTC) ; `null` si le fil est encore vide.
  final DateTime? dernierMessageLe;

  /// Ce que le badge doit dire de ce fil.
  final IndicateurAttention attention;
}
