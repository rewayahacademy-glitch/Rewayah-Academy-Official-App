// Les regles de portee des annonces (`AudienceRulesMatrix`, spec section 13.4,
// section 17 COM-W04 ; COM-BR-11).
//
// La matrice affichee a l'Administration vient du serveur, ligne par ligne :
// qui peut publier, vers quelles audiences, avec ou sans validation. Ce n'est
// PAS le droit de la personne connectee (COM-BR-16, `capacites_communication`)
// : c'est la regle de l'ecole, montree pour etre relue.
//
// **Aucune ligne inventee depuis la maquette** (correction obligatoire de
// COM-W04) : le port de production est neutre, il leve
// `CapaciteIndisponible('COM-BR-11')` et l'ecran dit « pas encore
// disponible ». Les lignes de demonstration (spec section 13.4, rien de plus)
// vivent dans `lib/features/demo/communications/com_annonces_demo.dart` et
// portent `demonstration: true`, que l'ecran dit en clair.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';

/// Une ligne de la matrice : un public d'auteurs et sa regle.
@immutable
class RegleAudience {
  /// Cree la ligne.
  const RegleAudience({
    required this.id,
    required this.auteurs,
    required this.peutPublier,
    required this.audiences,
    this.validationRequise,
  });

  /// Identifiant stable de la ligne.
  final String id;

  /// Qui publie, deja redige par le serveur (« Enseignants »).
  final String auteurs;

  /// Vrai si ce public peut publier une annonce.
  final bool peutPublier;

  /// Vers quelles audiences, deja redige (« Sa Classe seulement ») ; vide
  /// quand le public ne publie pas.
  final String audiences;

  /// Vrai si une publication de ce public attend une validation ; `null`
  /// tant que le serveur ne le dit pas. HYPOTHESE : COM-BR-11 cite une
  /// « validation » sans la definir, et ni la spec section 13.4 ni section 17
  /// COM-W04 n'en prevoient. L'ecran ne montre la colonne que si au moins
  /// une ligne la renseigne ; la demonstration ne l'invente pas.
  final bool? validationRequise;
}

/// La matrice rendue par le serveur.
@immutable
class ReglesAudience {
  /// Cree la matrice.
  const ReglesAudience({required this.regles, this.demonstration = false});

  /// Les lignes, dans l'ordre du serveur.
  final List<RegleAudience> regles;

  /// Vrai pour des donnees de demonstration, dit en clair a l'ecran.
  final bool demonstration;
}

/// La source de la matrice (COM-BR-11).
abstract interface class PortReglesAudience {
  /// Les regles de portee en vigueur.
  Future<ReglesAudience> regles();
}

/// Le port de production tant qu'aucun contrat n'existe : il leve
/// `CapaciteIndisponible('COM-BR-11')`, jamais une matrice inventee.
class ReglesAudienceIndisponibles implements PortReglesAudience {
  /// Cree l'implementation.
  const ReglesAudienceIndisponibles();

  /// Ce qui manque.
  static const CapaciteIndisponible manque = CapaciteIndisponible('COM-BR-11');

  @override
  Future<ReglesAudience> regles() => Future<ReglesAudience>.error(manque);
}

/// Le port employe par l'application : neutre en production.
final Provider<PortReglesAudience> portReglesAudienceProvider =
    Provider<PortReglesAudience>(
      (Ref ref) => const ReglesAudienceIndisponibles(),
    );

/// La matrice, lue une fois.
final FutureProvider<ReglesAudience> reglesAudienceProvider =
    FutureProvider<ReglesAudience>(
      (Ref ref) => ref.watch(portReglesAudienceProvider).regles(),
    );
