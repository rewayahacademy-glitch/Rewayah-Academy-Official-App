// Les lectures de la Tresorerie (W04 ; CPT-BR-04, 05, 12) et les regles
// d'affichage des mouvements entre coffres que l'ecran tient en seconde
// barriere (spec §10.3, §10.4 ; DR-15). La regle reste serveur : ces filtres
// n'ajoutent jamais un mouvement, ils en retirent ou en durcissent.
//
// `retry` nul partout : pas de retentative silencieuse de Riverpod 3 derriere
// le bouton « Reessayer » des blocs (meme reglage que la Vue globale).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/capacites/port_tresorerie.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';

Duration? _sansRetentative(int _, Object _) => null;

/// La synthese : detenue, libre, protegee, transit.
final syntheseTresorerieProvider =
    FutureProvider.autoDispose<SyntheseTresorerie>(
      (Ref ref) => ref.watch(portTresorerieProvider).resume(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portTresorerieProvider],
    );

/// Les sept coffres.
final coffresTresorerieProvider = FutureProvider.autoDispose<List<SoldeCoffre>>(
  (Ref ref) => ref.watch(portTresorerieProvider).coffres(),
  retry: _sansRetentative,
  dependencies: <ProviderOrFamily>[portTresorerieProvider],
);

/// L'historique des allocations, tout coffre confondu.
final historiqueTresorerieProvider =
    FutureProvider.autoDispose<List<EntreeJournal>>(
      (Ref ref) => ref
          .watch(portTresorerieProvider)
          .historique(FiltreHistoriqueTresorerie.tout),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portTresorerieProvider],
    );

/// La prevision datee.
final previsionTresorerieProvider =
    FutureProvider.autoDispose<List<LignePrevision>>(
      (Ref ref) => ref.watch(portTresorerieProvider).prevision(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portTresorerieProvider],
    );

/// Les mouvements permis et refuses par la politique, lus ensemble : l'ecran
/// ne propose un geste qu'une fois les deux listes connues.
final mouvementsTresorerieProvider =
    FutureProvider.autoDispose<MouvementsCoffres>((Ref ref) async {
      final PortTresorerie port = ref.watch(portTresorerieProvider);
      final (List<MouvementPermis> permis, List<MouvementBloque> bloques) =
          await (port.mouvementsPermis(), port.mouvementsBloques()).wait;
      return MouvementsCoffres.depuis(permis: permis, bloques: bloques);
    },
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portTresorerieProvider],
    );

/// Les indicateurs de la Reserve strategique (lecture, CPT-BR-12).
final indicateursReserveProvider =
    FutureProvider.autoDispose<IndicateursReserve>(
      (Ref ref) => ref.watch(portPolitiqueReserveProvider).indicateurs(),
      retry: _sansRetentative,
      dependencies: <ProviderOrFamily>[portPolitiqueReserveProvider],
    );

/// La politique en vigueur (lecture, CPT-BR-12).
final politiqueReserveProvider = FutureProvider.autoDispose<PolitiqueReserve>(
  (Ref ref) => ref.watch(portPolitiqueReserveProvider).politique(),
  retry: _sansRetentative,
  dependencies: <ProviderOrFamily>[portPolitiqueReserveProvider],
);

/// Relit tout ce que l'ecran affiche, apres un mouvement ou sur
/// « Reessayer » de la page.
void relireTresorerie(WidgetRef ref) {
  ref
    ..invalidate(syntheseTresorerieProvider)
    ..invalidate(coffresTresorerieProvider)
    ..invalidate(historiqueTresorerieProvider)
    ..invalidate(previsionTresorerieProvider)
    ..invalidate(mouvementsTresorerieProvider)
    ..invalidate(indicateursReserveProvider)
    ..invalidate(politiqueReserveProvider);
}

/// Vrai pour un couple que le Comptable ne doit **jamais** se voir proposer,
/// quoi que rende la source (spec §10.4, DR-15) : un coffre vers lui-meme,
/// Fonds clients engages ou Taxes & obligations vers la Tresorerie libre
/// (ni vider les fonds clients, ni payer une depense ordinaire avec les
/// taxes).
bool coupleInterdit(Coffre origine, Coffre destination) =>
    origine == destination ||
    (destination == Coffre.tresorerieLibre &&
        (origine == Coffre.fondsClientsEngages ||
            origine == Coffre.taxesObligations));

/// Vrai quand le mouvement doit passer par une validation supplementaire :
/// ce que dit la source, **ou** une sortie d'un coffre protege (§10.3 « doit
/// etre traite comme sensible ») ; le retrait de la Reserve strategique
/// l'est donc toujours (§9.5). Jamais l'inverse : l'ecran ne rend pas
/// delegable ce que la source dit sensible.
bool estSensible(MouvementPermis m) => m.sensible || m.origine.protege;

/// Les mouvements de l'ecran, filtres et durcis.
class MouvementsCoffres {
  /// Cree les listes.
  const MouvementsCoffres({required this.offerts, required this.bloques});

  /// Filtre ce que rend la source : les couples interdits disparaissent des
  /// mouvements offerts ; un couple a la fois permis et refuse reste refuse.
  factory MouvementsCoffres.depuis({
    required List<MouvementPermis> permis,
    required List<MouvementBloque> bloques,
  }) {
    bool refuse(MouvementPermis m) => bloques.any(
      (MouvementBloque b) =>
          b.origine == m.origine && b.destination == m.destination,
    );
    return MouvementsCoffres(
      offerts: <MouvementPermis>[
        for (final MouvementPermis m in permis)
          if (!coupleInterdit(m.origine, m.destination) && !refuse(m)) m,
      ],
      bloques: bloques,
    );
  }

  /// Les couples que l'ecran propose.
  final List<MouvementPermis> offerts;

  /// Les couples refuses, avec leur raison.
  final List<MouvementBloque> bloques;

  /// Le premier mouvement offert vers la Reserve strategique (Alimenter).
  MouvementPermis? get alimentation => _premier(
    (MouvementPermis m) => m.destination == Coffre.reserveStrategique,
  );

  /// Le premier mouvement offert depuis la Reserve strategique (retrait).
  MouvementPermis? get retrait =>
      _premier((MouvementPermis m) => m.origine == Coffre.reserveStrategique);

  /// Le refus rendu pour l'alimentation de la Reserve, s'il y en a un.
  MouvementBloque? get alimentationBloquee => _bloque(
    (MouvementBloque b) => b.destination == Coffre.reserveStrategique,
  );

  /// Le refus rendu pour le retrait de la Reserve, s'il y en a un (R-FIN-10).
  MouvementBloque? get retraitBloque =>
      _bloque((MouvementBloque b) => b.origine == Coffre.reserveStrategique);

  MouvementPermis? _premier(bool Function(MouvementPermis) test) {
    for (final MouvementPermis m in offerts) {
      if (test(m)) return m;
    }
    return null;
  }

  MouvementBloque? _bloque(bool Function(MouvementBloque) test) {
    for (final MouvementBloque b in bloques) {
      if (test(b)) return b;
    }
    return null;
  }
}

/// Une part en pour mille ecrite en pourcent, sans `double` : 292 → « 29,2 ».
String pourcentDepuisPourMille(int pourMille) {
  final int absolu = pourMille.abs();
  final String signe = pourMille < 0 ? '−' : '';
  final int dixieme = absolu % 10;
  return dixieme == 0
      ? '$signe${absolu ~/ 10}'
      : '$signe${absolu ~/ 10},$dixieme';
}
