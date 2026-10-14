import 'package:flutter/foundation.dart';

/// Les domaines de recherche (spec RECH-03 §3, §12).
///
/// **Un domaine est un moteur metier, jamais un index commun** : chacun porte
/// sa propre autorite de lecture et la liste exacte de ses champs
/// recherchables. L'ordre de l'enumeration est l'ordre d'affichage stable.
enum DomaineRecherche {
  /// Classes et seances (RECH-D1).
  classes,

  /// Supports de la Bibliotheque (RECH-D1).
  supports,

  /// Familles, eleves et identifiant RA exact (RECH-D2, apres Immatriculation).
  personnes,

  /// Enseignants et remplacements (RECH-D3).
  enseignants,

  /// Projection pedagogique : eleves d'une classe, travaux (RECH-D3).
  pedagogie,

  /// Missions et rapports de controle (RECH-D3).
  controle,

  /// Offres de remplacement d'un enseignant (RECH-D3).
  remplacements,

  /// Finance FI et CPT (RECH-D4).
  finances,

  /// Fils de Messagerie et du Studio, jamais le corps des messages (RECH-D4).
  fils,
}

/// L'espace depuis lequel la recherche est ouverte.
///
/// **Un choix d'interface, jamais une preuve d'autorisation** (spec §7.1) : le
/// serveur l'intersecte avec les capacites reelles de la personne. Un adulte
/// autonome garde le role `guardian` ; son espace d'eleve est une capacite.
enum EspaceRecherche {
  /// Espace du tuteur et du foyer.
  famille,

  /// Espace de l'eleve, interface standard.
  eleve,

  /// Espace de l'eleve en Interface guidee.
  eleveGuide,

  /// Espace de l'enseignant.
  enseignant,

  /// Espace du controleur.
  controleur,

  /// Espace de la comptabilite.
  comptable,

  /// Espace de l'administration et de la direction.
  administration,
}

/// Le contexte d'une recherche : un choix de l'interface, a intersecter cote
/// serveur avec les droits (spec §8.2).
@immutable
class ContexteRecherche {
  /// Cree un contexte.
  const ContexteRecherche({required this.espace, this.domaineCible});

  /// L'espace actif demande.
  final EspaceRecherche espace;

  /// Le domaine propre a la page d'ouverture (Bibliotheque, Espace Classe) :
  /// il passe en premier et borne la recherche (§6.1 point 4). `null` : la
  /// surface commune.
  final DomaineRecherche? domaineCible;

  @override
  bool operator ==(Object other) =>
      other is ContexteRecherche &&
      other.espace == espace &&
      other.domaineCible == domaineCible;

  @override
  int get hashCode => Object.hash(espace, domaineCible);
}

/// La nature d'un resultat, pour l'icone et le libelle de contexte.
enum TypeResultat {
  /// Une classe.
  classe,

  /// Une seance.
  seance,

  /// Un support de la Bibliotheque.
  support,

  /// Une personne autorisee (eleve, adulte du foyer).
  personne,

  /// Un enseignant.
  enseignant,

  /// Un remplacement.
  remplacement,

  /// Un eleve vu en projection pedagogique.
  eleveClasse,

  /// Une mission de controle.
  mission,

  /// Une operation financiere.
  operation,

  /// Un fil de discussion.
  fil,
}

/// Les destinations qu'un resultat peut ouvrir : une liste blanche
/// (spec §8.2). Une chaine venue de la base ne devient jamais une adresse.
enum KindCible {
  /// La classe.
  classe,

  /// Le support de la Bibliotheque.
  support,

  /// La fiche d'un eleve (foyer ou projection pedagogique).
  eleve,

  /// L'enseignant.
  enseignant,

  /// La mission de controle.
  mission,

  /// L'operation financiere.
  operation,

  /// Le fil.
  fil,

  /// Le canal du Studio.
  canal,

  /// L'ecran des remplacements de l'enseignant.
  remplacement,
}

/// Ce qu'un resultat ouvre : un genre ferme et une reference opaque.
@immutable
class CibleRecherche {
  /// Cree une cible.
  const CibleRecherche({required this.kind, required this.reference});

  /// Le genre de destination.
  final KindCible kind;

  /// La reference opaque de l'objet, jamais une adresse.
  final String reference;

  @override
  bool operator ==(Object other) =>
      other is CibleRecherche &&
      other.kind == kind &&
      other.reference == reference;

  @override
  int get hashCode => Object.hash(kind, reference);
}

/// Un resultat : **une liste blanche**, jamais un export du modele de base
/// (spec §8.2, SEC-R10). Aucun lien signe, aucun champ prive.
@immutable
class ResultatRecherche {
  /// Cree un resultat.
  const ResultatRecherche({
    required this.type,
    required this.reference,
    required this.titre,
    required this.cible,
    this.contexte,
    this.extrait,
  });

  /// La nature du resultat.
  final TypeResultat type;

  /// La reference opaque, stable dans une reponse.
  final String reference;

  /// Le titre, en texte pur : le surlignage est segmente cote interface,
  /// jamais insere comme HTML (SEC-R11).
  final String titre;

  /// Une courte ligne de contexte (« Votre classe · Mercredi · 18 h »).
  final String? contexte;

  /// Un extrait court autorise, en texte pur.
  final String? extrait;

  /// La destination.
  final CibleRecherche cible;
}

/// Les issues d'un domaine qui n'est pas `ok` (spec §8.2, §13.3).
///
/// Chacune a son texte : **une panne n'est jamais « aucun resultat »**.
enum StatutRecherche {
  /// Le domaine est en panne ou n'est pas raccorde.
  indisponible,

  /// Le delai est depasse.
  delai,

  /// Trop de demandes : le serveur limite le rythme.
  limite,

  /// La session a expire.
  sessionExpiree,

  /// Le contexte (droit, affectation, mission) a ete retire.
  contexteRevoque,

  /// La requete est invalide pour ce domaine.
  requeteInvalide,

  /// Le curseur est perime ou ne correspond plus au contexte.
  curseurPerime,
}

/// La reponse d'un domaine : un succes (`ok`, eventuellement sans element :
/// le seul vide confirme) ou un echec nomme.
@immutable
sealed class ReponseDomaine {
  const ReponseDomaine(this.domaine);

  /// Le domaine interroge.
  final DomaineRecherche domaine;
}

/// Le domaine a repondu. Une liste vide ici est un **vide confirme**.
final class ReponseOk extends ReponseDomaine {
  /// Cree une reponse reussie.
  const ReponseOk(
    super.domaine, {
    required this.elements,
    this.curseurSuivant,
    this.aPlus = false,
  });

  /// Les resultats de la page.
  final List<ResultatRecherche> elements;

  /// Le curseur opaque de la page suivante, signe cote serveur et lie a
  /// l'appelant, au contexte, a la requete et au filtre.
  final String? curseurSuivant;

  /// Vrai quand d'autres resultats existent : jamais un total (SEC-R09).
  final bool aPlus;
}

/// Le domaine n'a pas pu repondre ; le motif se dit sans reveler l'existence
/// d'un objet prive.
final class ReponseEchec extends ReponseDomaine {
  /// Cree une reponse en echec.
  const ReponseEchec(super.domaine, this.statut);

  /// Le motif.
  final StatutRecherche statut;
}
