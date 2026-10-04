// Les capacites Communications de la personne connectee (COM-BR-16 ;
// 02_DECOUPAGE, COM-F, complements COM-0b « Capacites Communications »,
// COM-BR-A01).
//
// **Un widget lit une capacite, jamais un role** (CLAUDE.md). Publier une
// annonce, la programmer, moderer, ouvrir les parametres d'un canal, ecrire
// dans un fil : chacune de ces actions n'est rendue que si la capacite est
// donnee ici. Une capacite absente n'est pas rendue (jamais grisee) ; le
// serveur refuse quand meme (COM-BR-A01).
//
// **Source unique** : [capacitesCommunicationProvider], lu par toutes les
// voies. En production, le port est neutre ([CapacitesCommunicationsIndisponibles]) :
// il leve `CapaciteIndisponible('COM-BR-16')`, comme tout port COM neutre
// (COM-BR-A09), et le provider rend alors l'ensemble ferme. Tout est donc
// ferme par defaut ; seules la demonstration et les tests ouvrent quelque
// chose, par surcharge de [portCapacitesCommunicationsProvider] avec
// [CapacitesCommunicationsFixes], jamais dans `main.dart`.
//
// Une capacite liee a un objet (ecrire dans CE fil, parametres de CE canal)
// est aussi portee par l'objet rendu, sur le modele de
// `lib/core/tc_bibliotheque/library_resource.dart` (`peut(capacite)`) : les
// voies l'ajoutent a leurs modeles, sans rouvrir ce fichier.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// Une action de communication soumise a capacite (COM-BR-16).
enum CapaciteCommunication {
  /// Publier une annonce (Classe pour l'enseignant, audience large pour
  /// l'Administration).
  publierAnnonce,

  /// Programmer une annonce a une date future.
  programmer,

  /// Moderer : ouvrir la file, masquer, restaurer, rejeter, approuver.
  moderer,

  /// Ouvrir les parametres d'un canal du Studio.
  parametresCanal,

  /// Ecrire dans un fil.
  ecrireDansFil,
}

/// Les capacites Communications de la personne connectee.
@immutable
class CapacitesCommunication {
  /// Cree un ensemble de capacites.
  CapacitesCommunication([
    Set<CapaciteCommunication> capacites = const <CapaciteCommunication>{},
  ]) : capacites = Set<CapaciteCommunication>.unmodifiable(capacites);

  /// Tout ferme : la valeur par defaut, et celle de la production tant que
  /// COM-BR-16 n'a pas de contrat.
  static final CapacitesCommunication aucune = CapacitesCommunication();

  /// Les capacites ouvertes.
  final Set<CapaciteCommunication> capacites;

  /// Vrai si [capacite] est ouverte.
  bool peut(CapaciteCommunication capacite) => capacites.contains(capacite);

  @override
  bool operator ==(Object other) =>
      other is CapacitesCommunication && setEquals(other.capacites, capacites);

  @override
  int get hashCode => Object.hashAllUnordered(capacites);
}

/// La source des capacites Communications, projetees par le serveur.
abstract interface class PortCapacitesCommunications {
  /// Les capacites de la personne connectee.
  Future<CapacitesCommunication> capacites();
}

/// Le port de production tant qu'aucun contrat n'existe (COM-BR-16) : il leve
/// [CapaciteIndisponible], jamais un ensemble invente.
class CapacitesCommunicationsIndisponibles
    implements PortCapacitesCommunications {
  /// Cree l'implementation.
  const CapacitesCommunicationsIndisponibles();

  @override
  Future<CapacitesCommunication> capacites() =>
      Future<CapacitesCommunication>.error(
        const CapaciteIndisponible('COM-BR-16'),
      );
}

/// Un ensemble fixe, pour la demonstration (hors production) et les tests.
class CapacitesCommunicationsFixes implements PortCapacitesCommunications {
  /// Cree le port avec les capacites ouvertes [ouvertes].
  const CapacitesCommunicationsFixes(this.ouvertes);

  /// Les capacites ouvertes.
  final Set<CapaciteCommunication> ouvertes;

  @override
  Future<CapacitesCommunication> capacites() =>
      Future<CapacitesCommunication>.value(CapacitesCommunication(ouvertes));
}

/// Le port employe par l'application : neutre en production.
final Provider<PortCapacitesCommunications>
portCapacitesCommunicationsProvider = Provider<PortCapacitesCommunications>(
  (Ref ref) => const CapacitesCommunicationsIndisponibles(),
);

/// Les capacites lues une fois, **la seule source que lit un widget**.
///
/// Une capacite indisponible (port neutre) donne l'ensemble ferme
/// ([CapacitesCommunication.aucune]) : une action absente n'est pas rendue,
/// et l'ecran n'a rien a reessayer. Toute autre erreur reste une erreur, que
/// l'ecran traite comme une lecture en echec.
final FutureProvider<CapacitesCommunication> capacitesCommunicationProvider =
    FutureProvider<CapacitesCommunication>((Ref ref) async {
      try {
        return await ref.watch(portCapacitesCommunicationsProvider).capacites();
      } on CapaciteIndisponible {
        return CapacitesCommunication.aucune;
      }
    });
