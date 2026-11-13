import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Une etape du programme publie, avec son code stable (le code qui rattache un
/// document, d'une version du programme a l'autre).
@immutable
class EtapeProgramme {
  /// Cree une etape.
  const EtapeProgramme({
    required this.code,
    required this.nom,
    this.cycle = '',
    this.ordre = 0,
  });

  /// Lit une etape rendue par le serveur.
  factory EtapeProgramme.depuisJson(Map<String, dynamic> json) =>
      EtapeProgramme(
        code: json['code'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        cycle: json['cycle'] as String? ?? '',
        ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      );

  /// Le code stable (texte), jamais saisi a la main.
  final String code;

  /// Le nom humain de l'etape.
  final String nom;

  /// Le niveau (le cycle) de l'etape.
  final String cycle;

  /// Sa place dans le programme.
  final int ordre;
}

/// Les etapes du programme publie (BIBLIOTHEQUE-UNE, D3) : la direction
/// rattache un document par un choix, jamais en tapant un code. Liste vide tant
/// qu'aucun programme n'est publie.
abstract interface class PortEtapesProgramme {
  /// Les etapes du programme publie, par ordre.
  Future<List<EtapeProgramme>> publiees();
}

/// Aucune etape (tests, demonstration, programme non publie).
final class EtapesAucune implements PortEtapesProgramme {
  /// Cree le port vide.
  const EtapesAucune();

  @override
  Future<List<EtapeProgramme>> publiees() async => const <EtapeProgramme>[];
}

/// Le port employe par l'application.
final Provider<PortEtapesProgramme> portEtapesProgrammeProvider =
    Provider<PortEtapesProgramme>((Ref ref) => const EtapesAucune());
