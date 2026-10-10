/// R14, R15 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : une relecture
/// reguliere qui ne fait pas partir tous les appareils a la meme seconde.
///
/// Avec 300 eleves qui entrent a 18:00, un `Timer.periodic` de 10 s pose a
/// l'ouverture de la salle fait tomber 300 requetes sur la meme seconde,
/// toutes les 10 s, pendant tout le cours. Trois corrections, sans changer
/// la cadence moyenne :
///
/// - **la premiere lecture reste immediate** (l'ecran ne reste pas sur
///   « inconnu » une periode entiere) ;
/// - **la deuxieme part apres un decalage tire au hasard**, uniforme entre
///   la moitie et une fois et demie la cadence (moyenne : la cadence) : les
///   appareils se repartissent sur toute la periode ;
/// - **chaque intervalle suivant varie de plus ou moins 20 %** (moyenne : la
///   cadence) : les appareils ne se resynchronisent pas d'eux-memes ;
/// - **apres un echec, l'intervalle double** (2, 4, 8 fois la cadence, borne
///   a [SondageRegulier.reculMax] fois), avec la meme variation ; la
///   premiere lecture qui aboutit le ramene a la cadence. Un serveur sature
///   n'est pas relance plus fort par ceux qui n'obtiennent pas de reponse.
///
/// Une minuterie annulable a chaque tour, et non une boucle `async*` qui
/// attend : le depot a mesure le defaut inverse (un `Future.delayed` qui
/// continue apres la sortie de salle, `service_presence.dart`).
///
/// L'intervalle est compte d'un depart de lecture au suivant, sans attendre
/// la reponse : une lecture lente ne ralentit pas la cadence, comme le
/// `Timer.periodic` qu'il remplace.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Une relecture reguliere, decalee au hasard et ralentie apres un echec.
class SondageRegulier {
  /// Cree la relecture. [lire] rend vrai quand la lecture a abouti (une
  /// exception vaut un echec). [hasard] se fixe dans les tests.
  SondageRegulier({
    required this.cadence,
    required this.lire,
    math.Random? hasard,
    this.reculMax = 8,
  }) : _hasard = hasard ?? math.Random();

  /// La cadence moyenne, sans echec.
  final Duration cadence;

  /// La lecture. Vrai : aboutie.
  final Future<bool> Function() lire;

  /// Le plus grand multiple de [cadence] atteint apres des echecs repetes.
  final int reculMax;

  final math.Random _hasard;
  Timer? _minuterie;
  bool _arrete = false;
  int _echecs = 0;

  /// Le nombre d'echecs consecutifs (0 apres une lecture aboutie).
  @visibleForTesting
  int get echecs => _echecs;

  /// Lance la premiere lecture tout de suite et planifie la suivante.
  void demarrer() {
    _arrete = false;
    unawaited(_lire());
    _planifier(premier: true);
  }

  /// Arrete la relecture : aucune lecture ne part plus, la minuterie en
  /// cours est annulee.
  void arreter() {
    _arrete = true;
    _minuterie?.cancel();
    _minuterie = null;
  }

  /// Le delai avant la prochaine lecture. Le premier : entre 0,5 et 1,5 fois
  /// la cadence. Les suivants : la cadence (multipliee par 2 a chaque echec
  /// consecutif, jusqu'a [reculMax]), a plus ou moins 20 %.
  @visibleForTesting
  Duration delaiSuivant({bool premier = false}) {
    final double u = _hasard.nextDouble();
    if (premier) return cadence * (0.5 + u);
    final int multiple = _echecs == 0
        ? 1
        : math.min(reculMax, 1 << math.min(_echecs, 30));
    return cadence * (multiple * (0.8 + 0.4 * u));
  }

  void _planifier({bool premier = false}) {
    if (_arrete) return;
    _minuterie = Timer(delaiSuivant(premier: premier), _tic);
  }

  void _tic() {
    if (_arrete) return;
    _planifier();
    unawaited(_lire());
  }

  Future<void> _lire() async {
    bool aboutie;
    try {
      aboutie = await lire();
    } on Object {
      aboutie = false;
    }
    if (_arrete) return;
    final bool retour = aboutie && _echecs > 0;
    _echecs = aboutie ? 0 : _echecs + 1;
    // La minuterie en cours a ete posee avec le recul de la panne : sans
    // replanifier, le retour a la cadence attendrait un recul de plus.
    if (retour) {
      _minuterie?.cancel();
      _planifier();
    }
  }
}
