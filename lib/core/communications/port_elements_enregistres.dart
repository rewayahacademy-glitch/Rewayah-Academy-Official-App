// Les elements enregistres (`SavedForLater`, spec section 8.3 ; COM-BR-12).
//
// « Enregistrer » garde une REFERENCE vers l'objet canonique (message,
// publication, element du Studio), jamais une copie metier concurrente. Tant
// qu'aucun contrat serveur n'existe, le port de production dit
// « indisponible » et l'ecran ne propose pas l'action.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'modeles_communication.dart';

/// Un element enregistre : une reference a son objet canonique.
@immutable
class ElementEnregistre {
  /// Cree l'element.
  const ElementEnregistre({required this.objet, required this.enregistreLe});

  /// L'objet canonique (type, identifiant, libelle, destination).
  final ObjetLie objet;

  /// L'instant de l'enregistrement (UTC).
  final DateTime enregistreLe;
}

/// Les elements enregistres de la personne connectee.
abstract interface class PortElementsEnregistres {
  /// Les elements, le plus recent d'abord.
  Future<List<ElementEnregistre>> liste();

  /// Vrai si [objet] est enregistre.
  Future<bool> estEnregistre(ObjetLie objet);

  /// Enregistre [objet]. Sans effet s'il l'est deja.
  Future<void> enregistrer(ObjetLie objet);

  /// Retire [objet]. Sans effet s'il ne l'est pas.
  Future<void> retirer(ObjetLie objet);
}

/// Les elements enregistres tant qu'aucun contrat n'existe (COM-BR-12) :
/// chaque appel echoue avec [CapaciteIndisponible], jamais une liste vide
/// inventee.
class ElementsEnregistresIndisponibles implements PortElementsEnregistres {
  /// Cree l'implementation.
  const ElementsEnregistresIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible('COM-BR-12');

  @override
  Future<List<ElementEnregistre>> liste() =>
      Future<List<ElementEnregistre>>.error(_manque);

  @override
  Future<bool> estEnregistre(ObjetLie objet) => Future<bool>.error(_manque);

  @override
  Future<void> enregistrer(ObjetLie objet) => Future<void>.error(_manque);

  @override
  Future<void> retirer(ObjetLie objet) => Future<void>.error(_manque);
}

/// Les elements enregistres en memoire : **double de demonstration et de
/// test**, jamais branche en production (la demonstration le pose par
/// `overrideWithValue`, sous `environnementAutoriseDemo`).
class ElementsEnregistresMemoire implements PortElementsEnregistres {
  /// Cree une memoire vide. [maintenant] est injectable pour les tests.
  ElementsEnregistresMemoire({DateTime Function()? maintenant})
    : _maintenant = maintenant ?? _maintenantUtc;

  static DateTime _maintenantUtc() => DateTime.now().toUtc();

  final DateTime Function() _maintenant;
  final Map<ObjetLie, ElementEnregistre> _elements =
      <ObjetLie, ElementEnregistre>{};

  @override
  Future<List<ElementEnregistre>> liste() async {
    final List<ElementEnregistre> liste = _elements.values.toList()
      ..sort(
        (ElementEnregistre a, ElementEnregistre b) =>
            b.enregistreLe.compareTo(a.enregistreLe),
      );
    return List<ElementEnregistre>.unmodifiable(liste);
  }

  @override
  Future<bool> estEnregistre(ObjetLie objet) async =>
      _elements.containsKey(objet);

  @override
  Future<void> enregistrer(ObjetLie objet) async {
    _elements.putIfAbsent(
      objet,
      () => ElementEnregistre(objet: objet, enregistreLe: _maintenant()),
    );
  }

  @override
  Future<void> retirer(ObjetLie objet) async {
    _elements.remove(objet);
  }
}

/// Les elements enregistres employes par l'application.
final Provider<PortElementsEnregistres> portElementsEnregistresProvider =
    Provider<PortElementsEnregistres>(
      (Ref ref) => const ElementsEnregistresIndisponibles(),
    );
