// Mes classes (directeur, 30/10/2026) : « Rejoindre » parait a l'ouverture
// exacte de la salle, sans recharger, et « En direct » a T0, la fin a la fin.
//
// Le battement d'une minute de la Journee n'etait pas aligne : pose a 14:00:40,
// il ne voyait 14:40 qu'a 14:40:40. Ce minuteur se rearme a chaque passage sur
// la prochaine bascule connue (ouverture, debut, fin, fin de grace) ou, a
// defaut, sur la prochaine minute pleine, pour que le compte a rebours avance.
// Un seul `Timer` a la fois, jamais un battement a la seconde.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../controle/service_controle.dart' show graceApresFin;
import '../video/pre_vol.dart' show seuilOuvertureSalle;

/// Les instants ou l'etat d'une seance change : ouverture de la salle (le
/// seuil unique [seuilOuvertureSalle]), debut, fin prevue, fin de la grace.
List<DateTime> basculesSeance(DateTime debut, DateTime fin) => <DateTime>[
  debut.subtract(seuilOuvertureSalle),
  debut,
  fin,
  fin.add(graceApresFin),
];

/// Reconstruit [constructeur] a la prochaine bascule de [instants] et a chaque
/// minute pleine, avec l'heure lue par [lire].
class CadenceSeance extends StatefulWidget {
  /// Cree le minuteur.
  const CadenceSeance({
    required this.lire,
    required this.constructeur,
    this.instants = const <DateTime>[],
    super.key,
  });

  /// L'horloge (`DateTime.now` en production, simulee dans les tests).
  final DateTime Function() lire;

  /// Les bascules a voir a l'instant exact (voir [basculesSeance]).
  final List<DateTime> instants;

  /// L'ecran, a l'heure donnee.
  final Widget Function(DateTime maintenant) constructeur;

  @override
  State<CadenceSeance> createState() => _CadenceSeanceEtat();
}

class _CadenceSeanceEtat extends State<CadenceSeance> with CadenceSeanceEtat {
  @override
  DateTime lireCadence() => widget.lire();

  @override
  void initState() {
    super.initState();
    suivreBascules(widget.instants);
  }

  @override
  void didUpdateWidget(CadenceSeance ancien) {
    super.didUpdateWidget(ancien);
    suivreBascules(widget.instants);
  }

  @override
  Widget build(BuildContext context) => widget.constructeur(maintenantCadence);
}

/// Le minuteur de [CadenceSeance], pour un ecran qui porte lui-meme l'heure
/// (un `ConsumerState` dont les lectures doivent rester dans son `build`).
/// [maintenantCadence] avance a la prochaine bascule donnee a
/// [suivreBascules] et a chaque minute pleine ; un seul `Timer` a la fois.
mixin CadenceSeanceEtat<T extends StatefulWidget> on State<T> {
  Timer? _minuteurCadence;
  List<DateTime> _instantsCadence = const <DateTime>[];
  bool _armeCadence = false;

  /// L'horloge (`DateTime.now` en production, simulee dans les tests).
  DateTime lireCadence();

  /// L'heure de la derniere bascule ou minute vue.
  late DateTime maintenantCadence = lireCadence();

  /// Les bascules a voir a l'instant exact. Sans effet si elles n'ont pas
  /// change : peut s'appeler a chaque `build`.
  void suivreBascules(List<DateTime> instants) {
    if (_armeCadence && _memes(instants, _instantsCadence)) return;
    _instantsCadence = List<DateTime>.of(instants);
    _armeCadence = true;
    _armer();
  }

  static bool _memes(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!a[i].isAtSameMomentAs(b[i])) return false;
    }
    return true;
  }

  void _armer() {
    _minuteurCadence?.cancel();
    final DateTime m = lireCadence();
    DateTime prochain = DateTime(
      m.year,
      m.month,
      m.day,
      m.hour,
      m.minute,
    ).add(const Duration(minutes: 1));
    for (final DateTime i in _instantsCadence) {
      if (i.isAfter(m) && i.isBefore(prochain)) prochain = i;
    }
    _minuteurCadence = Timer(prochain.difference(m), () {
      if (!mounted) return;
      setState(() => maintenantCadence = lireCadence());
      _armer();
    });
  }

  @override
  void dispose() {
    _minuteurCadence?.cancel();
    super.dispose();
  }
}
