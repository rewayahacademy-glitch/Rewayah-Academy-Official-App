// Le Studio, Aujourd'hui : le port de l'activite et ses modeles (COM-STU-2 ;
// spec section 7, section 8.1 ; contrat COM-BR-15).
//
// `Aujourd'hui` est un AGREGATEUR D'ATTENTION, pas un deuxieme centre
// operationnel (spec section 7) : chaque ligne vient du serveur, deja typee
// (section 8.1), avec l'objet canonique qu'elle concerne et la destination
// qui l'ouvre dans son module (Finance, Planning, dossier, Classe,
// Admissions). Le Studio n'execute aucune action metier : il n'offre que
// « ouvrir » (R-COM-11) et « marquer lu » (COM-BR-15).
//
// La destination est verifiee deux fois. `ObjetLie` la passe deja par
// `cheminRetourValide` (aucune URL externe, ni salle, ni stockage). Puis
// [destinationModule] la garde seulement si elle mene bien au module annonce
// par la ligne : une ligne Finance n'ouvre jamais un canal du Studio, et une
// ligne d'un module sans page (Finance, Planning, `admin_domaine.dart:99`)
// est rendue sans chevron, jamais avec un bouton grise.
//
// Tant qu'aucun contrat n'existe, le port de production rend
// `CapaciteIndisponible('COM-BR-15')` : l'ecran dit « pas encore
// disponible », sans « Reessayer » ni liste vide inventee. La demonstration
// le remplace sous `environnementAutoriseDemo`.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/modeles_communication.dart';
import '../../core/router/routes.dart';

export '../../core/communications/modeles_communication.dart';

/// Le type d'une ligne d'activite (spec section 8.1).
enum TypeActivite {
  /// Un message non lu.
  messageNonLu,

  /// Une mention de la personne.
  mention,

  /// Une reponse a un message de la personne.
  reponse,

  /// Une annonce importante.
  annonceImportante,

  /// Une decision demandee a la personne.
  decisionDemandee,

  /// Un fichier partage.
  fichierPartage,

  /// Une action locale du Studio (un canal cree, un element epingle).
  actionStudio,

  /// Un changement contextuel venu d'un module canonique.
  changementModule,
}

/// Le module canonique d'ou vient une ligne, et ou elle s'ouvre (spec
/// section 7, regle anti-doublon).
enum ModuleCanonique {
  /// Le Studio lui-meme (un canal).
  studio,

  /// Finance.
  finance,

  /// Planning.
  planning,

  /// Un dossier (famille, personne).
  dossiers,

  /// Une Classe.
  classes,

  /// Admissions.
  admissions,

  /// Administration des communications (annonces, messages).
  communications;

  /// Le debut de chemin des pages de ce module, ou `null` s'il n'a pas de
  /// page aujourd'hui.
  ///
  /// Finance suit son domaine admin (`AdminDomaine.finance.chemin`, nul tant
  /// qu'aucune page n'existe) ; Planning n'a aucune page cote administration
  /// (DASH_STRATEGIE section 3.1, Q2 : « aucun lien Planning tant que la page
  /// n'existe pas »). Une ligne de ces modules est rendue sans chevron.
  String? get racine => switch (this) {
    ModuleCanonique.studio => Routes.adminStudio,
    ModuleCanonique.finance => AdminDomaine.finance.chemin,
    ModuleCanonique.planning => null,
    ModuleCanonique.dossiers => Routes.adminPersonnes,
    ModuleCanonique.classes => Routes.adminOperationsGroupes,
    ModuleCanonique.admissions => Routes.adminPersonnesDossiers,
    ModuleCanonique.communications => Routes.adminOperationsCommunications,
  };
}

/// Vrai si [chemin] est [racine] ou l'une de ses sous-pages (segment par
/// segment : `/admin/studio-x` n'est pas sous `/admin/studio`).
bool _sous(String chemin, String racine) {
  final String sansRequete = chemin.split('?').first;
  return sansRequete == racine || sansRequete.startsWith('$racine/');
}

/// La destination [chemin] gardee seulement si elle mene au [module] : un
/// chemin hors de son module, ou un module sans page, rend `null` (la ligne
/// est alors rendue sans chevron).
String? destinationModule(ModuleCanonique module, String? chemin) {
  final String? racine = module.racine;
  if (chemin == null || racine == null) return null;
  return _sous(chemin, racine) ? chemin : null;
}

/// La rubrique d'Aujourd'hui ou une ligne se range (spec section 7, blocs 1
/// a 5 ; les brouillons et les acces rapides ne sont pas des lignes
/// d'activite).
enum RubriqueAujourdhui {
  /// A traiter aujourd'hui.
  aTraiter,

  /// Mentions et reponses.
  mentions,

  /// Decisions en attente.
  decisions,

  /// Echeances proches.
  echeances,

  /// Activite recente.
  activite,
}

/// Ou s'ouvre une ligne du Studio : un chemin interne, un argument de
/// navigation (l'identifiant d'un dossier, qui ne passe jamais par
/// l'adresse, `app_router.dart`), et le module pour le dire.
@immutable
class DestinationStudio {
  /// Cree la destination.
  const DestinationStudio({
    required this.chemin,
    required this.module,
    this.argument,
  });

  /// Le chemin interne.
  final String chemin;

  /// Le module canonique ouvert.
  final ModuleCanonique module;

  /// L'argument de navigation (`extra`), s'il y en a un.
  final Object? argument;

  @override
  bool operator ==(Object other) =>
      other is DestinationStudio &&
      other.chemin == chemin &&
      other.module == module &&
      other.argument == argument;

  @override
  int get hashCode => Object.hash(chemin, module, argument);

  @override
  String toString() => 'DestinationStudio($chemin, ${module.name})';
}

/// Une ligne d'activite (`ActivityInbox`, spec section 8.1) : type, source,
/// auteur si autorise, heure, libelle court, niveau d'attention, destination,
/// lu ou non lu, action requise.
@immutable
class ActiviteStudio {
  /// Cree la ligne. [id] et [libelle] ne peuvent pas etre vides.
  const ActiviteStudio({
    required this.id,
    required this.type,
    required this.module,
    required this.libelle,
    required this.survenueLe,
    required this.objet,
    this.auteur,
    this.niveau = NiveauAttention.information,
    this.lu = false,
    this.actionRequise = false,
    this.echeance,
  }) : assert(id != '', 'Une ligne d activite porte son identifiant.'),
       assert(libelle != '', 'Une ligne d activite porte son libelle.');

  /// Identifiant de la ligne, tel que le serveur le connait.
  final String id;

  /// Le type de la ligne.
  final TypeActivite type;

  /// Le module canonique d'ou elle vient, et ou elle s'ouvre (la source).
  final ModuleCanonique module;

  /// Le libelle court, deja redige et nettoye par le serveur.
  final String libelle;

  /// L'instant de l'evenement (UTC).
  final DateTime survenueLe;

  /// L'objet canonique concerne, avec sa destination validee.
  final ObjetLie objet;

  /// L'auteur, seulement si le serveur l'autorise ; `null` sinon.
  final Participant? auteur;

  /// Le niveau d'attention calcule par le serveur.
  final NiveauAttention niveau;

  /// Vrai si la personne l'a deja lue.
  final bool lu;

  /// Vrai si la ligne attend une action de la personne (dans son module).
  final bool actionRequise;

  /// L'echeance (UTC), pour une ligne qui en a une ; `null` sinon.
  final DateTime? echeance;

  /// Le niveau montre : au moins « Action requise » si une action est
  /// attendue.
  NiveauAttention get niveauRendu =>
      actionRequise ? niveau.max(NiveauAttention.actionRequise) : niveau;

  /// Ce que le badge dit de la ligne : non lue, niveau, mention.
  IndicateurAttention get indicateur => IndicateurAttention(
    nonLus: lu ? 0 : 1,
    niveau: niveauRendu,
    mention: type == TypeActivite.mention,
  );

  /// La rubrique d'Aujourd'hui de la ligne, une seule : une ligne n'est
  /// jamais montree deux fois.
  ///
  /// L'urgence passe avant tout (« une alerte urgente va toujours en
  /// tete ») ; puis la decision demandee, la mention ou la reponse,
  /// l'echeance, l'action requise ; le reste est l'activite recente.
  RubriqueAujourdhui get rubrique {
    if (niveau == NiveauAttention.urgent) return RubriqueAujourdhui.aTraiter;
    if (type == TypeActivite.decisionDemandee) {
      return RubriqueAujourdhui.decisions;
    }
    if (type == TypeActivite.mention || type == TypeActivite.reponse) {
      return RubriqueAujourdhui.mentions;
    }
    if (echeance != null) return RubriqueAujourdhui.echeances;
    if (actionRequise || niveau == NiveauAttention.actionRequise) {
      return RubriqueAujourdhui.aTraiter;
    }
    return RubriqueAujourdhui.activite;
  }

  /// La destination canonique de la ligne, ou `null` si elle n'en a pas
  /// (module sans page, chemin hors de son module, aucun chemin) : la ligne
  /// est alors rendue sans chevron ni geste (R-COM-11).
  ///
  /// Un dossier s'ouvre par son identifiant passe en argument, jamais dans
  /// l'adresse (`app_router.dart`, route des dossiers).
  DestinationStudio? get destination {
    final String? chemin = destinationModule(module, objet.destination);
    if (chemin == null) return null;
    final bool dossier =
        objet.type == TypeObjetLie.dossier &&
        chemin.split('?').first == Routes.adminPersonnesDossiers;
    return DestinationStudio(
      chemin: chemin,
      module: module,
      argument: dossier ? objet.id : null,
    );
  }

  /// La meme ligne, lue.
  ActiviteStudio marqueeLue() => ActiviteStudio(
    id: id,
    type: type,
    module: module,
    libelle: libelle,
    survenueLe: survenueLe,
    objet: objet,
    auteur: auteur,
    niveau: niveau,
    lu: true,
    actionRequise: actionRequise,
    echeance: echeance,
  );
}

/// Les lignes de [activites] rangees par rubrique, chaque rubrique dans son
/// ordre : les echeances de la plus proche a la plus lointaine ; les autres
/// du niveau le plus pressant au plus calme, puis de la plus recente a la
/// plus ancienne. Toutes les rubriques sont presentes, vides comprises.
Map<RubriqueAujourdhui, List<ActiviteStudio>> rangerActivites(
  Iterable<ActiviteStudio> activites,
) {
  final Map<RubriqueAujourdhui, List<ActiviteStudio>> rangees =
      <RubriqueAujourdhui, List<ActiviteStudio>>{
        for (final RubriqueAujourdhui r in RubriqueAujourdhui.values)
          r: <ActiviteStudio>[],
      };
  for (final ActiviteStudio a in activites) {
    rangees[a.rubrique]!.add(a);
  }
  int parAttention(ActiviteStudio a, ActiviteStudio b) {
    final int niveau = b.niveauRendu.compareTo(a.niveauRendu);
    if (niveau != 0) return niveau;
    return b.survenueLe.compareTo(a.survenueLe);
  }

  for (final MapEntry<RubriqueAujourdhui, List<ActiviteStudio>> e
      in rangees.entries) {
    if (e.key == RubriqueAujourdhui.echeances) {
      e.value.sort((ActiviteStudio a, ActiviteStudio b) {
        final int date = a.echeance!.compareTo(b.echeance!);
        return date != 0 ? date : parAttention(a, b);
      });
    } else {
      e.value.sort(parAttention);
    }
  }
  return rangees;
}

/// L'activite du Studio (COM-BR-15).
abstract interface class PortActiviteStudio {
  /// Les lignes d'activite de la personne, deja autorisees : une ligne d'un
  /// canal qui ne lui est pas ouvert n'y figure pas (R-COM-08).
  Future<List<ActiviteStudio>> activites();

  /// Marque la ligne [activiteId] comme lue.
  Future<void> marquerLu(String activiteId);
}

/// L'activite tant qu'aucun contrat n'existe : tout rend
/// [CapaciteIndisponible], jamais une liste vide ni un faux succes.
class ActiviteStudioIndisponible implements PortActiviteStudio {
  /// Cree l'implementation.
  const ActiviteStudioIndisponible();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'COM-BR-15',
  );

  @override
  Future<List<ActiviteStudio>> activites() =>
      Future<List<ActiviteStudio>>.error(_absente);

  @override
  Future<void> marquerLu(String activiteId) => Future<void>.error(_absente);
}

/// L'activite employee par l'application. `lib/main.dart` ne branche rien
/// avant BR-1 ; la demonstration la remplace par `overrideWithValue`, sous
/// `environnementAutoriseDemo`.
final Provider<PortActiviteStudio> portActiviteStudioProvider =
    Provider<PortActiviteStudio>(
      (Ref ref) => const ActiviteStudioIndisponible(),
    );
