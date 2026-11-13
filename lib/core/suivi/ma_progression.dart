/// MA-PROGRESSION-ECRAN (12/11/2026) : « ou il etait, ou il est, ou il va, a
/// quelle vitesse », lu d'un seul appel, `ma_progression` (migration
/// 20261123830000), pour l'eleve, le titulaire de son profil et le tuteur de
/// son foyer.
///
/// Le serveur decide de tout : la garde est celle de `suivi_pedagogique_eleve`
/// (que `ma_progression` appelle), l'etape, la date limite et la vitesse
/// viennent de la base, les sourates de `sourates_eleve`, le reglage de
/// l'etape de ce que la direction a rempli. **Rien n'est calcule ici**, rien
/// n'est invente : une donnee absente cache sa ligne.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import 'port_suivi_pedagogique.dart';

/// Ou en est l'eleve d'une etape du cycle, rendu par le serveur.
enum StatutEtape {
  /// L'eleve l'a franchie.
  franchie('franchie'),

  /// L'eleve y est.
  enCours('en_cours'),

  /// Elle vient apres.
  aVenir('a_venir');

  const StatutEtape(this.valeurSql);

  /// La valeur rendue par la base.
  final String valeurSql;

  /// Lit une valeur de la base ; nulle si elle est inconnue (jamais un
  /// statut suppose).
  static StatutEtape? depuisSql(Object? valeur) {
    for (final StatutEtape s in StatutEtape.values) {
      if (s.valeurSql == valeur) return s;
    }
    return null;
  }
}

/// Une etape du cycle de l'eleve, dans l'ordre du programme.
@immutable
class EtapeDuCycle {
  /// Cree une etape.
  const EtapeDuCycle({
    required this.ordre,
    required this.nom,
    required this.statut,
    this.atteinteLe,
  });

  /// Son rang dans le cycle.
  final int ordre;

  /// Son nom humain.
  final String nom;

  /// Franchie, en cours ou a venir.
  final StatutEtape statut;

  /// Le jour ou l'eleve y est entre ; nul quand le serveur ne le sait pas.
  final DateTime? atteinteLe;
}

/// Ce que la direction a regle pour l'etape en cours : vide tant qu'elle n'a
/// rien rempli.
@immutable
class ReglageEtape {
  /// Cree un reglage.
  const ReglageEtape({this.heuresRevisionSemaine, this.repetitionsEstimees});

  /// Les heures de revision par semaine.
  final double? heuresRevisionSemaine;

  /// Les repetitions estimees.
  final int? repetitionsEstimees;

  /// Aucun des deux n'est rempli.
  bool get vide => heuresRevisionSemaine == null && repetitionsEstimees == null;
}

/// La progression d'un eleve, telle que `ma_progression` la rend.
@immutable
class MaProgression {
  /// Cree une progression.
  const MaProgression({
    this.suivi,
    this.cycle = const <EtapeDuCycle>[],
    this.sourates,
    this.reglage,
  });

  /// Lit la reponse de `ma_progression`. Pure, pour les tests ; nulle quand
  /// elle est illisible ou ne porte rien a montrer (ni etape, ni sourates).
  static MaProgression? depuisJson(Object? brut) {
    final Object? ligne = brut is List
        ? (brut.isEmpty ? null : brut.first)
        : brut;
    if (ligne is! Map) return null;
    final Object? etape = ligne['etape'];
    final SuiviPedagogique? suivi = etape is Map
        ? SuiviPedagogique.depuisJson(<String, Object?>{
            'etape_nom': etape['nom'],
            'etape_ordre': etape['ordre'],
            'objectifs': etape['objectifs'],
            'duree_prevue_semaines': etape['duree_prevue_semaines'],
            'date_limite': etape['date_limite'],
            'semaines_ecoulees': etape['semaines_ecoulees'],
            'rythme': etape['rythme'],
            'page_reprise': etape['page_reprise'],
          })
        : null;
    final Object? cru = ligne['sourates'];
    final SouratesValidees? sourates = cru is Map
        ? SouratesValidees.depuis(
            cru['sourates_validees'],
            cru['sourates_total'],
          )
        : null;
    final Object? etapes = ligne['etapes_du_cycle'];
    final List<EtapeDuCycle> cycle = <EtapeDuCycle>[
      if (suivi != null && etapes is List)
        for (final Object? e in etapes)
          if (e is Map) ?_etapeDuCycle(e),
    ];
    final Object? r = ligne['reglage'];
    final ReglageEtape? reglage = suivi != null && r is Map
        ? _reglage(r)
        : null;
    if (suivi == null && sourates == null) return null;
    return MaProgression(
      suivi: suivi,
      cycle: cycle,
      sourates: sourates,
      reglage: reglage,
    );
  }

  static EtapeDuCycle? _etapeDuCycle(Map<Object?, Object?> e) {
    final Object? ordre = e['ordre'];
    final String nom = '${e['nom'] ?? ''}'.trim();
    final StatutEtape? statut = StatutEtape.depuisSql(e['statut']);
    if (ordre is! num || nom.isEmpty || statut == null) return null;
    return EtapeDuCycle(
      ordre: ordre.toInt(),
      nom: nom,
      statut: statut,
      atteinteLe: DateTime.tryParse('${e['atteinte_le']}'),
    );
  }

  static ReglageEtape? _reglage(Map<Object?, Object?> r) {
    final Object? h = r['heures_revision_semaine'];
    final Object? n = r['repetitions_estimees'];
    final double? heures = h is num && h > 0 ? h.toDouble() : null;
    final int? reps = n is num && n > 0 ? n.toInt() : null;
    final ReglageEtape reglage = ReglageEtape(
      heuresRevisionSemaine: heures,
      repetitionsEstimees: reps,
    );
    return reglage.vide ? null : reglage;
  }

  /// L'etape en cours et son rythme ; nul sans Classe active ni etape
  /// publiee (les sourates restent alors rendues).
  final SuiviPedagogique? suivi;

  /// Les etapes du cycle, dans l'ordre ; vide sans etape.
  final List<EtapeDuCycle> cycle;

  /// Les sourates des bases validees au cahier ; nulles quand le serveur ne
  /// les rend pas.
  final SouratesValidees? sourates;

  /// Le reglage de l'etape en cours ; nul tant que la direction n'a rien
  /// rempli.
  final ReglageEtape? reglage;
}

/// Le port.
abstract interface class PortMaProgression {
  /// La progression de [eleveId] ; nulle quand il n'y a rien a montrer.
  Future<MaProgression?> pourEleve(String eleveId);
}

/// Le port : absent tant que `main.dart` ne le pose pas ; sans lui, le bloc
/// n'est pas pose.
final Provider<PortMaProgression?> portMaProgressionProvider =
    Provider<PortMaProgression?>((Ref _) => null);

/// La progression d'un eleve ; `null` sans port ou sans rien a montrer.
final FutureProviderFamily<MaProgression?, String> maProgressionProvider =
    FutureProvider.family<MaProgression?, String>((Ref ref, String eleveId) {
      final PortMaProgression? port = ref.watch(portMaProgressionProvider);
      if (port == null) return Future<MaProgression?>.value();
      return port.pourEleve(eleveId);
    }, retry: (int _, Object _) => null);

/// Le reglage d'une etape, tel que la direction l'a rempli (une ligne par
/// etape reglee).
@immutable
class ReglageParEtape {
  /// Cree un reglage.
  const ReglageParEtape({
    required this.codeTechnique,
    this.heuresRevisionSemaine,
    this.repetitionsEstimees,
  });

  /// L'etape, par son code technique (stable entre les versions).
  final String codeTechnique;

  /// Les heures de revision par semaine ; nulles : non reglees.
  final double? heuresRevisionSemaine;

  /// Les repetitions estimees ; nulles : non reglees.
  final int? repetitionsEstimees;
}

/// Le reglage par la direction : lire ce qui est rempli, le modifier. Le
/// serveur garde la porte (direction seule, `regler_etape_progression`).
abstract interface class PortReglagesProgression {
  /// Les reglages remplis.
  Future<List<ReglageParEtape>> lire();

  /// Regle une etape ; une valeur nulle la vide.
  Future<void> regler({
    required String codeTechnique,
    double? heuresRevisionSemaine,
    int? repetitionsEstimees,
  });
}

/// Le port du reglage : absent tant que `main.dart` ne le pose pas ; sans
/// lui, la saisie n'est pas proposee.
final Provider<PortReglagesProgression?> portReglagesProgressionProvider =
    Provider<PortReglagesProgression?>((Ref _) => null);

/// Les reglages remplis ; `null` sans port.
final FutureProvider<List<ReglageParEtape>?> reglagesProgressionProvider =
    FutureProvider<List<ReglageParEtape>?>((Ref ref) async {
      final PortReglagesProgression? port = ref.watch(
        portReglagesProgressionProvider,
      );
      return port?.lire();
    }, retry: (int _, Object _) => null);
