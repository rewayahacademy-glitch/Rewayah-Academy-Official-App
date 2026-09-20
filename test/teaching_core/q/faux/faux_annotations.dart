// Faux depot d'annotations, pose a cote d'un depot de versions.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// LES DEUX MAGASINS SONT SEPARES, ET C'EST LE SUJET. La source d'un support
// est immuable : une annotation ne cree jamais une copie du support et
// n'altere jamais `resource_version` (CONTRACTS sections 5 et 10). Deux
// magasins distincts rendent la faute **possible a commettre** dans le
// double -- et donc detectable par le test.

import 'package:rewayah_academy/core/tc_bibliotheque/resource_version.dart';

import '../../fixtures/contrats/contrats_d_outils.dart';

/// Le magasin des versions publiees. **Personne ne les modifie.**
class FauxDepotVersions {
  /// Cree un depot a partir de versions deja publiees.
  FauxDepotVersions(Iterable<ResourceVersion> versions)
    : _parId = <String, ResourceVersion>{
        for (final ResourceVersion v in versions) v.id: v,
      };

  final Map<String, ResourceVersion> _parId;

  /// Le nombre d'ecritures subies. **Doit rester a zero.**
  int ecritures = 0;

  /// Lit une version.
  ResourceVersion? parId(String versionId) => _parId[versionId];

  /// Remplace une version. Existe **uniquement** pour que le test puisse
  /// verifier que personne ne l'appelle.
  void remplacer(ResourceVersion version) {
    ecritures++;
    _parId[version.id] = version;
  }
}

/// Le magasin des couches d'annotation.
class FauxDepotAnnotations {
  /// Cree un depot vide.
  FauxDepotAnnotations({required this.horlogeUtc});

  /// L'horloge de reference, en UTC.
  final DateTime horlogeUtc;

  final Map<String, AnnotationLayer> _couches = <String, AnnotationLayer>{};

  /// Ouvre ou recupere une couche.
  AnnotationLayer couche({
    required String coucheId,
    required String resourceId,
    required String auteurProfilId,
    String? resourceVersionId,
    String? sessionId,
    PorteeAnnotation portee = PorteeAnnotation.seance,
  }) => _couches.putIfAbsent(
    coucheId,
    () => AnnotationLayer(
      id: coucheId,
      resourceId: resourceId,
      resourceVersionId: resourceVersionId,
      sessionId: sessionId,
      auteurProfilId: auteurProfilId,
      portee: portee,
      traits: const <TraitVectoriel>[],
      marqueurs: const <MarqueurSemantique>[],
      majAUtc: horlogeUtc,
    ),
  );

  /// Ajoute un trait a une couche.
  AnnotationLayer ajouterTrait(String coucheId, TraitVectoriel trait) {
    final AnnotationLayer avant = _couches[coucheId]!;
    final AnnotationLayer apres = avant.copieAvec(
      traits: <TraitVectoriel>[...avant.traits, trait],
      majAUtc: horlogeUtc,
    );
    _couches[coucheId] = apres;
    return apres;
  }

  /// Pose un marqueur semantique sur une couche.
  AnnotationLayer poserMarqueur(String coucheId, MarqueurSemantique marqueur) {
    final AnnotationLayer avant = _couches[coucheId]!;
    final AnnotationLayer apres = avant.copieAvec(
      marqueurs: <MarqueurSemantique>[...avant.marqueurs, marqueur],
      majAUtc: horlogeUtc,
    );
    _couches[coucheId] = apres;
    return apres;
  }

  /// La couche telle qu'elle est enregistree.
  AnnotationLayer? parId(String coucheId) => _couches[coucheId];
}
