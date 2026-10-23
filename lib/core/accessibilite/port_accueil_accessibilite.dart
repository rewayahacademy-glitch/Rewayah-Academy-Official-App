// DASH-MA-PROD : la source de l'Accueil de l'eleve en Mode Accessibilite.
//
// Aucun serveur ici (K-28, avant BR-1) : en production, le port neutre dit
// « pas encore disponible » (`CapaciteIndisponible`) ; la demonstration et
// les tests posent un double. Une donnee absente ne remplit jamais l'ecran
// (D10) : ni prenom de remplacement, ni Classe inventee.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderOrFamily` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../capacites/capacite_indisponible.dart';
import '../tc_groupe/group_home_vm.dart';

/// Ce que l'Accueil du Mode Accessibilite lit.
@immutable
class DonneesAccueilAccessibilite {
  /// Cree les donnees.
  const DonneesAccueilAccessibilite({
    required this.prenom,
    required this.tutoiement,
    required this.espace,
  });

  /// Le prenom de l'eleve, jamais son age.
  final String prenom;

  /// Vrai pour l'eleve mineur (MA4) : suit l'age legal, jamais la
  /// presentation.
  final bool tutoiement;

  /// La Classe et sa prochaine seance ; nul quand aucune Classe n'est encore
  /// attribuee (etat vide).
  final GroupHomeVM? espace;
}

/// Le port de l'Accueil du Mode Accessibilite.
abstract interface class PortAccueilAccessibilite {
  /// Lit l'Accueil. `CapaciteIndisponible` : la source n'existe pas encore ;
  /// toute autre erreur : la lecture a echoue (elle se reessaie).
  Future<DonneesAccueilAccessibilite> lire();
}

/// Le port neutre de production : la lecture de l'Accueil cote serveur
/// arrive avec BR-1 (ligne MA-BR). L'ecran le dit, sans rien inventer.
class AccueilAccessibiliteIndisponible implements PortAccueilAccessibilite {
  /// Cree le port neutre.
  const AccueilAccessibiliteIndisponible();

  @override
  Future<DonneesAccueilAccessibilite> lire() =>
      Future<DonneesAccueilAccessibilite>.error(
        const CapaciteIndisponible('MA-BR'),
      );
}

/// Le port employe par l'application : neutre par defaut (K-09).
/// Surchargeable dans un `ProviderScope` imbrique (demonstration).
final Provider<PortAccueilAccessibilite> portAccueilAccessibiliteProvider =
    Provider<PortAccueilAccessibilite>(
      (Ref _) => const AccueilAccessibiliteIndisponible(),
      dependencies: const <ProviderOrFamily>[],
    );

/// La lecture de l'Accueil, relancee par `ref.invalidate` (« Reessayer »).
///
/// Aucune retentative automatique (`retry` nul) : Riverpod 3 relancerait la
/// lecture en echec, et une capacite absente ne revient pas en insistant ;
/// seule la personne relance, par « Reessayer » (`BlocAsynchrone`).
final FutureProvider<DonneesAccueilAccessibilite>
donneesAccueilAccessibiliteProvider =
    FutureProvider<DonneesAccueilAccessibilite>(
      (Ref ref) => ref.watch(portAccueilAccessibiliteProvider).lire(),
      dependencies: <ProviderOrFamily>[portAccueilAccessibiliteProvider],
      retry: (int _, Object _) => null,
    );
