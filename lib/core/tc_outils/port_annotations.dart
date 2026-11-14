import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'annotation_layer.dart';
import 'fonction_indisponible.dart';

/// La lecture et l'ecriture des couches d'annotation.
///
/// **Contrat produit par Agent D** (`TEACHING_CORE_CONTRACTS.md` section 10),
/// consomme par C, E, F et Q.
///
/// Aucune methode ne prend, ne rend ni ne modifie le support : une couche ne
/// connait de lui que son identifiant. C'est ce qui rend l'invariant « une
/// annotation n'altere jamais `resource_version` » verifiable a la lecture de
/// l'interface, sans avoir a auditer chaque implementation.
abstract class PortAnnotations {
  /// La couche d'une portee donnee, ou `null` si elle n'existe pas.
  Future<AnnotationLayer?> couche({
    required String resourceId,
    String? sessionId,
    required PorteeAnnotation portee,
  });

  /// Le flux des couches d'un support, toutes portees confondues.
  Stream<AnnotationLayer> suivre({
    required String resourceId,
    String? sessionId,
  });

  /// Ajoute un trait a une couche.
  Future<void> ajouterTrait(String coucheId, TraitVectoriel trait);

  /// Retire un trait d'une couche.
  Future<void> retirerTrait(String coucheId, String traitId);

  /// Pose un marqueur semantique.
  Future<void> poserMarqueur(String coucheId, MarqueurSemantique marqueur);

  /// Retire un marqueur semantique.
  Future<void> retirerMarqueur(String coucheId, String marqueurId);

  /// Annule le dernier geste de la couche.
  Future<void> annulerDernier(String coucheId);
}

/// Une implementation en memoire des couches d'annotation.
///
/// **DOUBLE LOCAL ASSUME.** Aucune table `annotation_layer` n'existe en base
/// (`TEACHING_CORE_EXISTING_MAPPING.md` section 10.5), et la phase parallele
/// interdit d'en creer une : la demande SQL est ecrite dans
/// `TC_CONTRACT_REQUEST_D.md` section 3. Ce double rend le lot D utilisable et
/// testable de bout en bout **sans mentir** : les couches vivent le temps de la
/// session applicative, et une portee « enregistree » n'est pas plus durable
/// qu'une portee « temporaire » tant que le serveur n'existe pas.
///
/// Il applique en revanche **toutes** les regles du contrat, pour qu'Agent Z
/// n'ait qu'a rebrancher l'ecriture : creation a la demande, remplacement d'un
/// marqueur sur une plage deja marquee, annulation du dernier geste, et
/// notification du flux a chaque changement.
class AnnotationsMemoire implements PortAnnotations {
  /// Cree un depot en memoire, pour l'auteur donne.
  AnnotationsMemoire(
    this._auteurProfilId, {
    Uuid? generateur,
    DateTime Function()? maintenant,
  }) : _generateur = generateur ?? const Uuid(),
       _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final String _auteurProfilId;
  final Uuid _generateur;
  final DateTime Function() _maintenant;

  final Map<String, AnnotationLayer> _couches = <String, AnnotationLayer>{};
  final Map<String, StreamController<AnnotationLayer>> _flux =
      <String, StreamController<AnnotationLayer>>{};

  /// Les couches connues, pour les tests et pour l'inspection.
  Iterable<AnnotationLayer> get couches => _couches.values;

  @override
  Future<AnnotationLayer?> couche({
    required String resourceId,
    String? sessionId,
    required PorteeAnnotation portee,
  }) async {
    for (final AnnotationLayer couche in _couches.values) {
      if (couche.resourceId == resourceId &&
          couche.sessionId == sessionId &&
          couche.portee == portee) {
        return couche;
      }
    }
    // Creation a la demande : sans serveur, refuser ici reviendrait a rendre
    // le stylet inutilisable. La question « qui cree la couche » est posee a
    // Agent Z dans le CONTRACT_REQUEST.
    final AnnotationLayer neuve = AnnotationLayer(
      id: _generateur.v4(),
      resourceId: resourceId,
      sessionId: sessionId,
      auteurProfilId: _auteurProfilId,
      portee: portee,
      majAUtc: _maintenant(),
    );
    _couches[neuve.id] = neuve;
    _publier(neuve);
    return neuve;
  }

  @override
  Stream<AnnotationLayer> suivre({
    required String resourceId,
    String? sessionId,
  }) => _controleur(resourceId, sessionId).stream;

  @override
  Future<void> ajouterTrait(String coucheId, TraitVectoriel trait) async =>
      _muter(coucheId, (AnnotationLayer couche) {
        assert(
          trait.ancrage.resourceId == couche.resourceId,
          'un trait s ancre dans la ressource de sa couche',
        );
        return couche.avecTrait(trait, majAUtc: _maintenant());
      });

  @override
  Future<void> retirerTrait(String coucheId, String traitId) async => _muter(
    coucheId,
    (AnnotationLayer couche) =>
        couche.sansTrait(traitId, majAUtc: _maintenant()),
  );

  @override
  Future<void> poserMarqueur(
    String coucheId,
    MarqueurSemantique marqueur,
  ) async => _muter(
    coucheId,
    (AnnotationLayer couche) =>
        couche.avecMarqueur(marqueur, majAUtc: _maintenant()),
  );

  @override
  Future<void> retirerMarqueur(String coucheId, String marqueurId) async =>
      _muter(
        coucheId,
        (AnnotationLayer couche) =>
            couche.sansMarqueur(marqueurId, majAUtc: _maintenant()),
      );

  @override
  Future<void> annulerDernier(String coucheId) async => _muter(
    coucheId,
    (AnnotationLayer couche) => couche.sansDernier(majAUtc: _maintenant()),
  );

  /// Oublie les couches dont la portee ne survit pas a la seance.
  ///
  /// Le seul geste de cycle de vie que le double assume : il rend visible, des
  /// maintenant, la difference entre les trois portees.
  void fermerSeance(String sessionId) {
    _couches.removeWhere(
      (String _, AnnotationLayer couche) =>
          couche.sessionId == sessionId && !couche.portee.estDurable,
    );
  }

  /// Ferme les flux ouverts.
  Future<void> liberer() async {
    for (final StreamController<AnnotationLayer> controleur in _flux.values) {
      await controleur.close();
    }
    _flux.clear();
  }

  void _muter(
    String coucheId,
    AnnotationLayer Function(AnnotationLayer couche) transformation,
  ) {
    final AnnotationLayer? couche = _couches[coucheId];
    if (couche == null) {
      // Une couche inconnue n'est pas une erreur reseau : c'est un appel qui
      // n'a pas de sens. On le signale plutot que de le perdre.
      throw StateError('couche d annotation inconnue : $coucheId');
    }
    final AnnotationLayer modifiee = transformation(couche);
    _couches[coucheId] = modifiee;
    _publier(modifiee);
  }

  void _publier(AnnotationLayer couche) =>
      _controleur(couche.resourceId, couche.sessionId).add(couche);

  StreamController<AnnotationLayer> _controleur(
    String resourceId,
    String? sessionId,
  ) => _flux.putIfAbsent(
    '$resourceId|${sessionId ?? ''}',
    StreamController<AnnotationLayer>.broadcast,
  );
}

/// Le depot d'annotations quand aucun serveur n'est branche.
///
/// SALLE-ROBUSTE : aucune couche n'existe (`couche` rend `null`, que les
/// ecrans traitent deja comme « rien a annoter »), aucun flux n'emet, et toute
/// ecriture leve [FonctionIndisponible]. Il ne simule rien : un trait dessine
/// ici ne serait pas conserve, et le dire vaut mieux que le laisser croire.
class AnnotationsIndisponibles implements PortAnnotations, PortIndisponible {
  /// Cree le depot indisponible.
  const AnnotationsIndisponibles();

  static const FonctionIndisponible _echec = FonctionIndisponible(
    'annotations',
  );

  @override
  Future<AnnotationLayer?> couche({
    required String resourceId,
    String? sessionId,
    required PorteeAnnotation portee,
  }) async => null;

  @override
  Stream<AnnotationLayer> suivre({
    required String resourceId,
    String? sessionId,
  }) => const Stream<AnnotationLayer>.empty();

  @override
  Future<void> ajouterTrait(String coucheId, TraitVectoriel trait) =>
      Future<void>.error(_echec);

  @override
  Future<void> retirerTrait(String coucheId, String traitId) =>
      Future<void>.error(_echec);

  @override
  Future<void> poserMarqueur(String coucheId, MarqueurSemantique marqueur) =>
      Future<void>.error(_echec);

  @override
  Future<void> retirerMarqueur(String coucheId, String marqueurId) =>
      Future<void>.error(_echec);

  @override
  Future<void> annulerDernier(String coucheId) => Future<void>.error(_echec);
}

/// Le depot d'annotations employe par l'application.
///
/// Sans serveur, il rend [AnnotationsIndisponibles] : l'ecran se vide au lieu
/// de lever. Agent Z le surcharge a l'integration (`AnnotationsMemoire` pour
/// les tests et la demonstration).
final Provider<PortAnnotations> portAnnotationsProvider =
    Provider<PortAnnotations>((Ref ref) => const AnnotationsIndisponibles());
