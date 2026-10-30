// Mes classes (directeur, 30/10/2026) : « Rejoindre » parait a T-20 pile,
// « En cours » a T0, la fin a la fin, sans recharger et sans lire le serveur
// toutes les 30 s par carte (decision du pilote, point (d)).
//
// Une horloge de Classe est lue une fois a l'affichage, puis une fois a
// chacune de ses bascules (ouverture de la salle, debut, fin, fin de grace),
// et a chaque signal de la veille temps reel. Entre deux lectures, le compte a
// rebours avance a la minute, derive de l'instant serveur de la lecture plus
// le temps attendu : jamais de l'horloge de l'appareil, qui derive.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StreamProviderFamily` n'est pas exporte par l'entree principale de
// `flutter_riverpod` : meme convention que `port_horloge_seance.dart`.
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;

import '../fraicheur/generation_veille.dart';
import 'port_horloge_seance.dart';
import 'session_clock_vm.dart';

/// La marge apres une bascule avant de relire : le serveur doit deja la voir.
const Duration margeBascule = Duration(seconds: 1);

/// L'attente apres une lecture en echec avant la suivante (un seul essai, pas
/// une cadence).
const Duration attenteApresEchec = Duration(seconds: 30);

/// La prochaine bascule de [horloge] strictement apres [maintenantServeurUtc],
/// ou `null` quand la seance est finie, grace comprise. Pure.
DateTime? prochaineBascule(
  SessionClockVM horloge,
  DateTime maintenantServeurUtc,
) {
  for (final DateTime b in <DateTime>[
    horloge.joinOpensAtUtc,
    horloge.debutUtc,
    horloge.finPrevueUtc,
    horloge.finPrevueUtc.add(horloge.graceApresFin),
  ]) {
    if (b.isAfter(maintenantServeurUtc)) return b;
  }
  return null;
}

/// Le flux d'une horloge de Classe : [lire] a l'abonnement, puis a chaque
/// bascule (plus [margeBascule]) ; entre deux, l'horloge vieillie a chaque
/// minute pleine de l'instant serveur estime. Sans horloge (aucune seance
/// prevue), le flux rend `null` et se ferme : la veille temps reel le relance.
/// Un seul minuteur a la fois, annule avec l'abonnement.
Stream<SessionClockVM?> suivreAuxBascules(
  Future<SessionClockVM?> Function() lire,
) {
  late final StreamController<SessionClockVM?> flux;
  Timer? minuteur;
  bool fini = false;
  late final Future<void> Function() lecture;

  // Entre la lecture et la bascule : l'instant serveur estime est celui de la
  // lecture, plus ce qui a ete attendu depuis.
  void vieillir(SessionClockVM lue, DateTime estime, DateTime relecture) {
    final DateTime minute = DateTime.utc(
      estime.year,
      estime.month,
      estime.day,
      estime.hour,
      estime.minute,
    ).add(const Duration(minutes: 1));
    final DateTime suivant = minute.isBefore(relecture) ? minute : relecture;
    minuteur = Timer(suivant.difference(estime), () {
      if (fini) return;
      if (!suivant.isBefore(relecture)) {
        unawaited(lecture());
        return;
      }
      flux.add(lue.aLInstant(suivant));
      vieillir(lue, suivant, relecture);
    });
  }

  lecture = () async {
    final SessionClockVM? lue;
    try {
      lue = await lire();
    } on Object catch (e, pile) {
      if (fini) return;
      flux.addError(e, pile);
      minuteur = Timer(attenteApresEchec, () => unawaited(lecture()));
      return;
    }
    if (fini) return;
    flux.add(lue);
    final DateTime? bascule = lue == null
        ? null
        : prochaineBascule(lue, lue.calculeeAUtc);
    if (lue == null || bascule == null) {
      fini = true;
      unawaited(flux.close());
      return;
    }
    vieillir(lue, lue.calculeeAUtc, bascule.add(margeBascule));
  };

  flux = StreamController<SessionClockVM?>(
    onListen: () => unawaited(lecture()),
    onCancel: () {
      fini = true;
      minuteur?.cancel();
    },
  );
  return flux.stream;
}

/// L'horloge vivante d'une Classe : `horloge_classe` lue a l'affichage, a
/// chaque bascule et a chaque signal de la veille. Liberee quand plus aucun
/// ecran ne la regarde : la lecture suivante est de nouveau « a l'affichage ».
final StreamProviderFamily<SessionClockVM?, String>
horlogeClasseVivanteProvider = StreamProvider.autoDispose
    .family<SessionClockVM?, String>((Ref ref, String groupeId) {
      ref.watch(generationVeilleProvider);
      final PortHorlogeSeance port = ref.watch(portHorlogeSeanceProvider);
      return suivreAuxBascules(() => port.horlogeDe(groupeId: groupeId));
    });
