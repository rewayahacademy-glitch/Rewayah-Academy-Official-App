// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/port_catalogue.dart (Agent B)
// Types de valeur copies depuis TEACHING_CORE_CONTRACTS.md sections 4 et 6.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// Agent A ne code AUCUNE bibliotheque (decision D-20) : l'Espace Groupe expose
// un emplacement, et son contenu arrive par ce port. Il n'existe pas de
// LibraryOutsideClass et de LibraryInsideClass.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_position.dart';

/// La nature d'une ressource.
enum TypeRessource {
  /// Le Coran.
  quran,

  /// Un texte structure.
  texteStructure,

  /// Un PDF.
  pdf,

  /// Une image.
  image,

  /// Une lecon.
  lecon,
}

/// Ce qu'une ressource permet de faire.
enum CapaciteRessource {
  /// Se parcourt page a page.
  pageable,

  /// Se cherche.
  searchable,

  /// Se zoome.
  zoomable,

  /// Se selectionne.
  selectable,

  /// Se met en focus.
  focusable,

  /// S'annote.
  annotatable,

  /// S'assigne.
  assignable,

  /// Se presente en classe.
  presentableInClass,

  /// Accepte le stylet.
  supportsStylus,

  /// Se consulte hors ligne.
  supportsOffline,
}

/// Qui peut ouvrir une ressource.
enum PolitiqueAcces {
  /// Tout le monde.
  publique,

  /// Les inscrits.
  inscrits,

  /// Le groupe auquel elle est assignee.
  groupeAssigne,

  /// L'enseignant seul.
  enseignantSeul,

  /// L'administration.
  admin,
}

/// Ce qu'une ressource autorise hors ligne.
enum PolitiqueOffline {
  /// Jamais.
  jamais,

  /// Sur demande.
  surDemande,

  /// Automatiquement.
  automatique,
}

/// L'etat hors ligne d'une ressource.
enum EtatOffline {
  /// A telecharger.
  aTelecharger,

  /// En cours de telechargement.
  enCours,

  /// En cache.
  enCache,

  /// Telechargee.
  telecharge,

  /// Indisponible.
  indisponible,
}

/// Le manifeste d'une ressource de la Bibliotheque.
@immutable
class LibraryResource {
  /// Cree un manifeste.
  const LibraryResource({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.resourceType,
    required this.language,
    required this.category,
    required this.levelScope,
    required this.accessPolicy,
    required this.offlinePolicy,
    required this.capabilities,
    this.coverAsset,
    this.edition,
    this.currentVersionId,
  });

  /// Identifiant de la ressource.
  final String id;

  /// Titre complet.
  final String title;

  /// Titre court, celui des couvertures.
  final String shortTitle;

  /// Cle d'asset ou cle Storage. **Jamais une URL signee.**
  final String? coverAsset;

  /// La nature de la ressource.
  final TypeRessource resourceType;

  /// L'edition, par exemple `madina-hafs-604`.
  final String? edition;

  /// La langue, par exemple `fr`.
  final String language;

  /// La categorie.
  final String category;

  /// Les codes de niveau du programme concernes.
  final List<String> levelScope;

  /// Qui peut l'ouvrir.
  final PolitiqueAcces accessPolicy;

  /// Ce qu'elle autorise hors ligne.
  final PolitiqueOffline offlinePolicy;

  /// La version publiee courante, `null` s'il n'y en a aucune.
  final String? currentVersionId;

  /// Ce qu'elle permet de faire. **La seule source du comportement offert.**
  final Set<CapaciteRessource> capabilities;
}

/// Le filtre du catalogue.
@immutable
class FiltreCatalogue {
  /// Cree un filtre.
  const FiltreCatalogue({
    this.types,
    this.langue,
    this.categorie,
    this.niveau,
    this.etatOffline,
  });

  /// Les natures retenues.
  final Set<TypeRessource>? types;

  /// La langue retenue.
  final String? langue;

  /// La categorie retenue.
  final String? categorie;

  /// Le niveau retenu.
  final String? niveau;

  /// L'etat hors ligne retenu.
  final EtatOffline? etatOffline;
}

/// La derniere lecture, pour l'action « Continuer ».
@immutable
class ReprisLecture {
  /// Cree une reprise.
  const ReprisLecture({
    required this.ressource,
    required this.position,
    required this.vueLeUtc,
  });

  /// La ressource concernee.
  final LibraryResource ressource;

  /// Ou la lecture s'est arretee.
  final ContentPosition position;

  /// Quand.
  final DateTime vueLeUtc;
}

/// Le catalogue de la Bibliotheque unique.
abstract class PortCatalogue {
  /// Toutes les ressources visibles.
  Future<List<LibraryResource>> tous({FiltreCatalogue? filtre});

  /// Les plus recentes.
  Future<List<LibraryResource>> recents({int limite = 10});

  /// Celles d'un groupe.
  Future<List<LibraryResource>> pourGroupe(String groupeId);

  /// Une ressource precise.
  Future<LibraryResource?> parId(String resourceId);

  /// Une recherche.
  Future<List<LibraryResource>> rechercher(
    String requete, {
    FiltreCatalogue? filtre,
  });

  /// « Continuer » : derniere ressource et derniere position.
  Future<ReprisLecture?> derniereLecture();
}

/// Le catalogue employe par l'Espace Groupe.
///
/// Declare **sans implementation** : Agent B le produit, Agent Z le branche.
/// Tant qu'il n'est pas surcharge, l'emplacement Bibliotheque de l'Espace
/// Groupe affiche son etat « non branche » plutot qu'une fausse etagere.
final Provider<PortCatalogue?> portCatalogueProvider = Provider<PortCatalogue?>(
  (Ref ref) => null,
);
