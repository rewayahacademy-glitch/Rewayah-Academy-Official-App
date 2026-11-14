/// PROGRAMME-PUBLIE (14/11/2026) : le programme de l'academie, tel que le
/// serveur le publie (`programme_publie`, migration 20261125600000), lisible par
/// l'eleve et sa famille meme sans etape propre.
///
/// **Aucun calcul ici** : le serveur decide ce qui sort (version publiee
/// seulement ; matieres et durees selon la tranche d'age et la regle de
/// `ma_progression`, aucune duree pour l'enfant de 6 a 9 ans qui lit pour
/// lui-meme). Ce fichier ne fait que lire la reponse et la rendre telle quelle ;
/// une valeur absente reste absente.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Une etape du programme publie.
@immutable
class EtapeProgramme {
  /// Cree une etape.
  const EtapeProgramme({
    required this.code,
    required this.ordre,
    required this.nom,
    this.objectifs = const <String>[],
    this.matierePrincipale,
    this.matiereSecondaire,
    this.dureePrevueSemaines,
    this.dateLimiteSemaines,
  });

  /// Le code stable de l'etape.
  final String code;

  /// Sa place dans le cycle.
  final int ordre;

  /// Son nom.
  final String nom;

  /// Ses objectifs.
  final List<String> objectifs;

  /// Sa matiere principale, quand le serveur la donne.
  final String? matierePrincipale;

  /// Sa matiere secondaire, quand le serveur la donne.
  final String? matiereSecondaire;

  /// Sa duree prevue en semaines ; nulle quand le serveur la retient.
  final int? dureePrevueSemaines;

  /// Sa date limite en semaines ; nulle quand le serveur la retient.
  final int? dateLimiteSemaines;
}

/// Un cycle (un niveau) du programme publie.
@immutable
class CycleProgramme {
  /// Cree un cycle.
  const CycleProgramme({
    required this.code,
    required this.nom,
    required this.ordre,
    this.etapes = const <EtapeProgramme>[],
  });

  /// Le code stable du cycle.
  final String code;

  /// Son nom.
  final String nom;

  /// Sa place dans le programme.
  final int ordre;

  /// Ses etapes, dans l'ordre.
  final List<EtapeProgramme> etapes;
}

/// Le programme publie : ses cycles, dans l'ordre. Vide quand aucune version
/// n'est publiee.
@immutable
class ProgrammePublie {
  /// Cree un programme.
  const ProgrammePublie({this.cycles = const <CycleProgramme>[]});

  /// Lit la reponse de `programme_publie`. Pure, pour les tests ; un programme
  /// vide quand la reponse est illisible ou ne porte aucun cycle.
  factory ProgrammePublie.depuisJson(Object? brut) {
    final Object? ligne = brut is List
        ? (brut.isEmpty ? null : brut.first)
        : brut;
    if (ligne is! Map) return const ProgrammePublie();
    final Object? cycles = ligne['cycles'];
    if (cycles is! List) return const ProgrammePublie();
    return ProgrammePublie(
      cycles: <CycleProgramme>[
        for (final Object? c in cycles)
          if (c is Map && '${c['nom'] ?? ''}'.isNotEmpty)
            CycleProgramme(
              code: '${c['code'] ?? ''}',
              nom: '${c['nom']}',
              ordre: _entier(c['ordre']) ?? 0,
              etapes: <EtapeProgramme>[
                for (final Object? e
                    in (c['etapes'] is List
                        ? c['etapes'] as List<Object?>
                        : const <Object?>[]))
                  if (e is Map && '${e['nom'] ?? ''}'.isNotEmpty)
                    EtapeProgramme(
                      code: '${e['code'] ?? ''}',
                      ordre: _entier(e['ordre']) ?? 0,
                      nom: '${e['nom']}',
                      objectifs: <String>[
                        for (final Object? o
                            in (e['objectifs'] is List
                                ? e['objectifs'] as List<Object?>
                                : const <Object?>[]))
                          if ('${o ?? ''}'.trim().isNotEmpty) '$o',
                      ],
                      matierePrincipale: _texte(e['matiere_principale']),
                      matiereSecondaire: _texte(e['matiere_secondaire']),
                      dureePrevueSemaines: _entier(e['duree_prevue_semaines']),
                      dateLimiteSemaines: _entier(e['date_limite_semaines']),
                    ),
              ],
            ),
      ],
    );
  }

  /// Les cycles, dans l'ordre.
  final List<CycleProgramme> cycles;

  /// Vrai quand il n'y a rien a montrer.
  bool get vide => cycles.every((CycleProgramme c) => c.etapes.isEmpty);
}

int? _entier(Object? v) => v is num ? v.toInt() : null;

String? _texte(Object? v) {
  final String s = '${v ?? ''}'.trim();
  return s.isEmpty ? null : s;
}

/// Le port.
abstract interface class PortProgrammePublie {
  /// Le programme publie, vu pour [eleveId] (sa tranche decide des matieres et
  /// des durees, cote serveur).
  Future<ProgrammePublie> pourEleve(String eleveId);
}

/// Le port : absent tant que `main.dart` ne le pose pas ; sans lui, l'onglet
/// garde sa phrase sans etape.
final Provider<PortProgrammePublie?> portProgrammePublieProvider =
    Provider<PortProgrammePublie?>((Ref _) => null);

/// Le programme publie, vu pour un eleve ; `null` sans port.
final FutureProviderFamily<ProgrammePublie?, String> programmePublieProvider =
    FutureProvider.family<ProgrammePublie?, String>((Ref ref, String eleveId) {
      final PortProgrammePublie? port = ref.watch(portProgrammePublieProvider);
      if (port == null) return Future<ProgrammePublie?>.value();
      return port.pourEleve(eleveId);
    }, retry: (int _, Object _) => null);
