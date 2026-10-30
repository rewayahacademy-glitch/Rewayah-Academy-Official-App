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

class _CadenceSeanceEtat extends State<CadenceSeance> {
  Timer? _minuteur;
  late DateTime _maintenant = widget.lire();

  @override
  void initState() {
    super.initState();
    _armer();
  }

  @override
  void didUpdateWidget(CadenceSeance ancien) {
    super.didUpdateWidget(ancien);
    _armer();
  }

  void _armer() {
    _minuteur?.cancel();
    final DateTime m = widget.lire();
    DateTime prochain = DateTime(
      m.year,
      m.month,
      m.day,
      m.hour,
      m.minute,
    ).add(const Duration(minutes: 1));
    for (final DateTime i in widget.instants) {
      if (i.isAfter(m) && i.isBefore(prochain)) prochain = i;
    }
    _minuteur = Timer(prochain.difference(m), () {
      if (!mounted) return;
      setState(() => _maintenant = widget.lire());
      _armer();
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.constructeur(_maintenant);
}
