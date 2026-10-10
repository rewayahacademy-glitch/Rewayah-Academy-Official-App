// TB-7a (plan V2 §9 ; revue du tour 2) : les traits que le depot
// d'annotations a pris pour un support, relus par la surface a page fixe.
//
// Sans cette relecture, l'encre posee par la personne disparaissait de
// l'ecran au lever du doigt (seules les notes de la vue etaient peintes),
// et des que la surface se remontait (ouverture des Commandes, zoom). Le
// depot fait foi : ce qui est peint apres le geste est ce qu'il a pris.
//
// Le fournisseur n'est pas libere avec la surface : il suit le flux du
// depot des sa premiere lecture, avant tout geste, et garde ce qu'il a
// recu quand la surface se remonte. Sans depot branche (salle de
// demonstration, avant TB-BR), il ne rend rien, sans erreur.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;

import '../../core/tc_outils/annotation_layer.dart';
import '../../core/tc_outils/port_annotations.dart';

/// Les traits du depot pour un support (identifiant de ressource), toutes
/// couches confondues ; la surface ne garde que ceux de la page montree.
final NotifierProviderFamily<NotesDeposees, List<TraitVectoriel>, String>
notesDeposeesProvider =
    NotifierProvider.family<NotesDeposees, List<TraitVectoriel>, String>(
      NotesDeposees.new,
    );

/// Le suivi du flux des couches d'un support.
class NotesDeposees extends Notifier<List<TraitVectoriel>> {
  /// Le suivi des couches du support [resourceId].
  NotesDeposees(this.resourceId);

  /// Le support suivi.
  final String resourceId;

  final Map<String, AnnotationLayer> _couches = <String, AnnotationLayer>{};

  @override
  List<TraitVectoriel> build() {
    final PortAnnotations depot;
    try {
      depot = ref.read(portAnnotationsProvider);
    } on Object {
      // Aucun depot branche : rien n'a pu etre pris, rien n'est rendu.
      return const <TraitVectoriel>[];
    }
    final StreamSubscription<AnnotationLayer> abonnement = depot
        .suivre(resourceId: resourceId)
        .listen(_recevoir, onError: (Object _) {});
    ref.onDispose(abonnement.cancel);
    return const <TraitVectoriel>[];
  }

  void _recevoir(AnnotationLayer couche) {
    _couches[couche.id] = couche;
    state = <TraitVectoriel>[
      for (final AnnotationLayer c in _couches.values) ...c.traits,
    ];
  }
}

/// TB-11b (plan V2 §10 « Les nouveaux traits locaux restent identifies
/// comme non partages jusqu'a reconciliation ») : les traits que la
/// personne a poses pendant que le tableau etait interrompu. Etat local de
/// la salle, jamais diffuse ; la surface ne le lit que tant que le tableau
/// n'est pas revenu (`SynchroTableau.partage` : la reconciliation du moteur
/// fait foi, TB-BR).
final NotifierProvider<TraitsNonPartages, Set<String>>
traitsNonPartagesProvider = NotifierProvider<TraitsNonPartages, Set<String>>(
  TraitsNonPartages.new,
);

/// Les identifiants des traits poses sans etre partages.
class TraitsNonPartages extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Le trait [id] vient d'etre pose sans etre partage.
  void ajouter(String id) => state = <String>{...state, id};

  /// Le trait [id] a ete retire (annule, gomme).
  void retirer(String id) {
    if (!state.contains(id)) return;
    state = <String>{...state}..remove(id);
  }
}
