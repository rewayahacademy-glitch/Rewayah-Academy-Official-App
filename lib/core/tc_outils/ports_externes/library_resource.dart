// TC-STUB-PORT: canonique = lib/core/tc_bibliotheque/library_resource.dart (Agent B)
// Signature copiee depuis TEACHING_CORE_CONTRACTS.md section 4.
// Agent Z supprime ce fichier a l'integration et pointe sur le canonique.
//
// **Volontairement partiel.** La regle du stub est de copier « uniquement les
// types de valeur NECESSAIRES ». Le Teaching Dock ne lit de `LibraryResource`
// que ses capacites : il n'affiche ni titre, ni couverture, ni politique
// d'acces, et il ne construit jamais une ressource. Copier la classe entiere
// creerait une surface de divergence pour rien. Les identifiants de ressource
// circulent en `String`, exactement comme dans `ContentPosition.resourceId`.

/// Ce qu'un support sait faire.
///
/// **La seule source du comportement offert** (invariant 4 du contrat) : le
/// Teaching Dock ne devine jamais qu'un support est annotable, il lit cette
/// liste. Un outil dont la capacite est absente n'est pas grise, il n'est pas
/// propose -- un bouton qui ne peut pas aboutir n'est pas rendu (`lib/CLAUDE.md`).
enum CapaciteRessource {
  /// Le support se parcourt page par page.
  pageable,

  /// Le support se cherche.
  searchable,

  /// Le support se grossit.
  zoomable,

  /// On peut y selectionner une plage.
  selectable,

  /// On peut y mettre une plage au centre.
  focusable,

  /// On peut y poser une couche d'annotation.
  annotatable,

  /// On peut en tirer un travail a preparer.
  assignable,

  /// Le support peut etre presente en classe.
  presentableInClass,

  /// Le support se prete a l'ecriture au stylet.
  supportsStylus,

  /// Le support est disponible hors ligne.
  supportsOffline,
}
