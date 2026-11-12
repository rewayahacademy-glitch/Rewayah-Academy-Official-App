/// ESPACE-APPRENDRE (lot 5) : les dates importantes de l'ecole (evaluations,
/// fermetures, rencontres de recitation), derriere un port.
///
/// Elles viendront du calendrier (lot 2, CALENDRIER-ET-PAUSES), pas encore
/// livre : aucune table de calendrier n'existe en production (releve du
/// 12/11/2026). **L'implementation de production rend donc « rien de publie »**
/// ([DatesEcoleNonPubliees]) et l'onglet Programme dit « Les dates de l'ecole
/// seront affichees ici ». Aucune date n'est inventee, aucun exemple n'est pose.
/// Quand le lot 2 arrive, il remplace [portDatesEcoleProvider] ; l'ecran ne
/// change pas.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// La sorte d'une date de l'ecole.
enum GenreDateEcole {
  /// Un petit bilan ou un examen.
  evaluation,

  /// Une fermeture de l'academie.
  fermeture,

  /// Une rencontre de recitation.
  rencontre,
}

/// Une date de l'ecole qui concerne l'eleve.
@immutable
class DateEcole {
  /// Cree une date.
  const DateEcole({required this.jour, required this.genre, this.libelle});

  /// Le jour (la date seule, sans heure).
  final DateTime jour;

  /// La sorte.
  final GenreDateEcole genre;

  /// Son nom (« Aid al-Adha »), ou `null` : le nom de la sorte s'affiche.
  final String? libelle;
}

/// Le port : les dates de l'ecole qui concernent [eleveId], dans l'ordre.
abstract interface class PortDatesEcole {
  /// Les dates publiees ; vide quand rien n'est publie.
  Future<List<DateEcole>> pourEleve(String eleveId);
}

/// L'implementation de production, tant que le calendrier n'existe pas : rien
/// n'est publie.
class DatesEcoleNonPubliees implements PortDatesEcole {
  /// Cree le port.
  const DatesEcoleNonPubliees();

  @override
  Future<List<DateEcole>> pourEleve(String eleveId) async =>
      const <DateEcole>[];
}

/// Le port employe par l'application.
final Provider<PortDatesEcole> portDatesEcoleProvider =
    Provider<PortDatesEcole>((Ref _) => const DatesEcoleNonPubliees());

/// Les dates de l'ecole d'un eleve.
final FutureProviderFamily<List<DateEcole>, String> datesEcoleProvider =
    FutureProvider.family<List<DateEcole>, String>(
      (Ref ref, String eleveId) =>
          ref.watch(portDatesEcoleProvider).pourEleve(eleveId),
      retry: (int _, Object _) => null,
    );
