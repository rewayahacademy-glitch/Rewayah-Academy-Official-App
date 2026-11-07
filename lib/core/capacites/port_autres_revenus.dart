// Les autres revenus d'un enseignant (REVENUS-VERITE point 5, 06/11/2026) :
// l'aide Internet, les primes et les missions que la direction attribue pour
// un mois, payables avec la paie (migration 20261110210000_autres_revenus.sql).
//
// La direction attribue et annule ; la comptabilite lit ; l'enseignant les lit
// dans « Mes revenus » (`mes_revenus_enseignant`). Le droit d'attribuer est une
// capacite rendue par le serveur (`peutAttribuer`), jamais un role lu ici.
// Aucun montant n'est calcule ici : le serveur rend chaque ligne et les totaux.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import '../i18n/strings.g.dart';
import 'capacite_indisponible.dart';

/// La nature d'un autre revenu.
enum NatureAutreRevenu {
  /// L'aide mensuelle pour la connexion (montant propose par la politique).
  aideInternet,

  /// Une somme en plus, decidee par la direction.
  prime,

  /// Un travail confie en plus des seances.
  mission,
}

/// Le nom serveur d'une nature (`aide_internet`, `prime`, `mission`).
String natureAutreRevenuServeur(NatureAutreRevenu n) => switch (n) {
  NatureAutreRevenu.aideInternet => 'aide_internet',
  NatureAutreRevenu.prime => 'prime',
  NatureAutreRevenu.mission => 'mission',
};

/// Le nom d'une nature, tel que l'enseignant et la direction le lisent.
String libelleNatureAutreRevenu(NatureAutreRevenu n) => switch (n) {
  NatureAutreRevenu.aideInternet => t.commun.autresRevenus.aideInternet,
  NatureAutreRevenu.prime => t.commun.autresRevenus.prime,
  NatureAutreRevenu.mission => t.commun.autresRevenus.mission,
};

/// La nature lue du serveur.
NatureAutreRevenu natureAutreRevenuJson(Object? v) => switch (v) {
  'aide_internet' => NatureAutreRevenu.aideInternet,
  'prime' => NatureAutreRevenu.prime,
  'mission' => NatureAutreRevenu.mission,
  _ => throw FormatException('nature d autre revenu inconnue: $v'),
};

/// Un autre revenu attribue pour un mois.
@immutable
class AutreRevenu {
  /// Cree la ligne.
  const AutreRevenu({
    required this.id,
    required this.nature,
    required this.libelle,
    required this.montant,
  });

  /// L'identifiant de la ligne.
  final String id;

  /// Sa nature.
  final NatureAutreRevenu nature;

  /// Le libelle saisi par la direction, lu tel quel par l'enseignant.
  final String libelle;

  /// Le montant, dans la devise de la politique du mois.
  final Montant montant;
}

/// Les autres revenus d'un enseignant pour un mois, vus par la direction.
@immutable
class AutresRevenusMois {
  /// Cree la vue.
  const AutresRevenusMois({
    required this.mois,
    required this.devise,
    required this.peutAttribuer,
    required this.lignes,
    this.aideInternetPolitique,
  });

  /// Le premier jour du mois.
  final DateTime mois;

  /// La devise de la politique du mois.
  final String devise;

  /// Vrai quand la personne connectee peut attribuer et annuler (direction).
  final bool peutAttribuer;

  /// Le montant d'aide Internet de la politique, propose ; nul s'il n'est pas
  /// fixe.
  final Montant? aideInternetPolitique;

  /// Les lignes non annulees, dans l'ordre d'attribution.
  final List<AutreRevenu> lignes;
}

/// Les autres revenus, cote direction et comptabilite.
abstract interface class PortAutresRevenus {
  /// Les autres revenus de [enseignantId] pour [mois] (premier jour).
  Future<AutresRevenusMois> lister(String enseignantId, DateTime mois);

  /// Attribue un autre revenu ; [cle] rend l'appel idempotent (un double
  /// toucher n'attribue jamais deux fois). [montantMineur] est le montant
  /// saisi, en unite mineure.
  Future<void> attribuer({
    required String enseignantId,
    required DateTime mois,
    required NatureAutreRevenu nature,
    required String libelle,
    required int montantMineur,
    required String cle,
  });

  /// Annule une ligne (elle reste dans l'historique, sans etre versee).
  Future<void> annuler(String id);
}

/// **Aucune source serveur** (demonstration, tests).
class AutresRevenusIndisponibles implements PortAutresRevenus {
  /// Cree l'implementation.
  const AutresRevenusIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible(
    'REVENUS-VERITE-5',
  );

  @override
  Future<AutresRevenusMois> lister(String enseignantId, DateTime mois) =>
      Future<AutresRevenusMois>.error(_manque);

  @override
  Future<void> attribuer({
    required String enseignantId,
    required DateTime mois,
    required NatureAutreRevenu nature,
    required String libelle,
    required int montantMineur,
    required String cle,
  }) => Future<void>.error(_manque);

  @override
  Future<void> annuler(String id) => Future<void>.error(_manque);
}

/// Le port des autres revenus ; `main.dart` le branche sur Supabase.
final Provider<PortAutresRevenus> portAutresRevenusProvider =
    Provider<PortAutresRevenus>((Ref _) => const AutresRevenusIndisponibles());
