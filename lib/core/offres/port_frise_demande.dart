/// SUIVI-FAMILLE (R20, directeur, 10/10/2026) : la frise « comme une
/// livraison » de chaque demande de creneau, par eleve.
///
/// Etapes : demande envoyee, liste d'attente (seulement s'il y a lieu), classe
/// creee, enseignant affecte, eleve integre, premiere seance. Le serveur
/// fournit l'horodatage de chaque etape atteinte, l'etape courante et, a
/// l'attente, un motif ; Flutter ne calcule ni etape, ni rang.
///
/// Garanties du modele (R11, R20) :
/// - **aucun rang de file, aucun autre demandeur** : le contrat ne porte ni
///   position ni nombre ; seul le motif d'attente, en categories fermees ;
/// - **heures murales du fuseau du foyer** ([EtapeFrise.quand]) : un instant
///   UTC est refuse, aucune heure ne s'affiche plutot qu'une heure fausse
///   (meme regle que `port_suivi_demandes.dart`) ;
/// - **jamais d'estimation inventee** : une date future n'existe que pour la
///   premiere seance, et seulement si le serveur la connait ;
/// - l'etat de chaque etape (fait, en cours, a venir) se deduit de la seule
///   etape courante donnee par le serveur.
///
/// Aucun branchement serveur ici : en production le port est absent
/// ([portFriseDemandesProvider] vaut `null`) ; l'ecran de suivi existant
/// reste alors intact. Signature proposee en Contrats (C-20).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Les etapes de la frise, dans l'ordre.
enum TypeEtapeFrise {
  /// La demande est arrivee a l'administration.
  envoyee,

  /// La famille attend qu'une place se libere (seulement s'il y a lieu).
  enAttente,

  /// Une classe a ete creee pour ce creneau.
  classeCreee,

  /// Un enseignant est affecte a la classe.
  enseignantAffecte,

  /// L'eleve est integre a la classe.
  eleveIntegre,

  /// La premiere seance.
  premiereSeance,
}

/// Pourquoi la famille attend. Categories fermees, texte de l'application :
/// aucun detail sur d'autres familles ne peut s'y glisser (R11).
enum MotifAttente {
  /// Toutes les classes de ce creneau sont pleines.
  classesPleines,

  /// Aucun enseignant n'est libre sur ce creneau.
  aucunEnseignantLibre,

  /// Motif absent ou inconnu : repli neutre, jamais un motif suppose.
  inconnu,
}

/// Pourquoi une demande est close (BACK-FRONT-SUIVI-1). Texte de
/// l'application, jamais un texte libre du serveur.
enum MotifClotureFrise {
  /// La famille a retire sa demande.
  retraitFamille,

  /// L'administration a retire ce creneau de ses offres.
  offreRetiree,

  /// La classe de ce creneau n'a pas pu etre constituee.
  classeNonConstituee,

  /// La direction n'a pas retenu la demande.
  refusDirection,

  /// L'eleve a deja une place en classe : la demande n'est plus necessaire.
  /// Ce n'est ni un refus ni une erreur.
  dejaEnClasse,

  /// Motif absent ou inconnu : repli neutre, jamais un motif suppose.
  inconnu,
}

/// L'etat d'une etape, deduit de l'etape courante.
enum EtatEtapeFrise {
  /// Franchie.
  fait,

  /// En cours.
  enCours,

  /// A venir.
  aVenir,
}

/// Une etape de la frise et son instant.
@immutable
class EtapeFrise {
  /// Cree l'etape. [quand] est l'heure murale locale rendue par l'adaptateur ;
  /// pour la premiere seance, elle n'existe que si le serveur la connait.
  EtapeFrise({required this.type, DateTime? quand})
    : assert(
        quand == null || !quand.isUtc,
        'quand est une heure murale, jamais UTC',
      ),
      quand = quand == null || !quand.isUtc ? quand : null;

  /// La nature de l'etape.
  final TypeEtapeFrise type;

  /// Son heure murale locale, nulle si le serveur n'en donne pas.
  final DateTime? quand;
}

/// La frise d'une demande pour un eleve.
@immutable
class FriseDemande {
  /// Cree la frise. Les [etapes] sont rangees dans l'ordre de la frise et
  /// dedoublonnees. [courante] : l'etape en cours, nulle quand tout est fait.
  /// [motifAttente] n'est garde que si [courante] est la liste d'attente.
  FriseDemande({
    required this.demandeId,
    required this.eleveId,
    required this.prenom,
    required this.fuseauIana,
    required Iterable<EtapeFrise> etapes,
    TypeEtapeFrise? courante,
    MotifAttente? motifAttente,
    this.cloture,
    this.peutChoisirAutreCreneau = false,
  }) : etapes = _rangees(etapes),
       courante = cloture == null ? courante : null,
       motifAttente = cloture == null && courante == TypeEtapeFrise.enAttente
           ? motifAttente ?? MotifAttente.inconnu
           : null;

  /// L'identifiant de la demande.
  final String demandeId;

  /// L'eleve concerne.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Le fuseau IANA du foyer, dans lequel toutes les heures sont rendues.
  final String fuseauIana;

  /// Les etapes, de la demande a la premiere seance.
  final List<EtapeFrise> etapes;

  /// L'etape en cours ; nulle quand toutes sont franchies, ou quand la
  /// demande est close.
  final TypeEtapeFrise? courante;

  /// Le motif de cloture ; nul tant que la demande vit. Une demande close n'a
  /// plus d'etape en cours : les etapes franchies restent visibles.
  final MotifClotureFrise? cloture;

  /// Capacite rendue par le serveur : la famille peut choisir un autre
  /// creneau pour cet eleve (demande close seulement).
  final bool peutChoisirAutreCreneau;

  /// Pourquoi la famille attend, nul hors attente.
  final MotifAttente? motifAttente;

  /// L'etat de [type] : avant la courante fait, la courante en cours, apres a
  /// venir. Sans courante, tout est fait (demande close comprise).
  EtatEtapeFrise etatDe(TypeEtapeFrise type) {
    final TypeEtapeFrise? c = courante;
    if (c == null || type.index < c.index) return EtatEtapeFrise.fait;
    return type == c ? EtatEtapeFrise.enCours : EtatEtapeFrise.aVenir;
  }

  static List<EtapeFrise> _rangees(Iterable<EtapeFrise> etapes) {
    final Map<TypeEtapeFrise, EtapeFrise> parType =
        <TypeEtapeFrise, EtapeFrise>{
          for (final EtapeFrise e in etapes) e.type: e,
        };
    return <EtapeFrise>[
      for (final TypeEtapeFrise t in TypeEtapeFrise.values)
        if (parType[t] case final EtapeFrise e) e,
    ];
  }
}

/// Le port des frises du foyer connecte.
abstract interface class PortFriseDemandes {
  /// Une frise par demande et par eleve, remise a jour a chaque passage
  /// d'etape.
  Stream<List<FriseDemande>> suivre();
}

/// Le port : absent avant le branchement serveur.
final Provider<PortFriseDemandes?> portFriseDemandesProvider =
    Provider<PortFriseDemandes?>((Ref _) => null);

/// Les frises du foyer. Sans port, aucune.
final StreamProvider<List<FriseDemande>> frisesDemandesProvider =
    StreamProvider<List<FriseDemande>>((Ref ref) {
      final PortFriseDemandes? port = ref.watch(portFriseDemandesProvider);
      if (port == null) return Stream<List<FriseDemande>>.value(const []);
      return port.suivre();
    });
