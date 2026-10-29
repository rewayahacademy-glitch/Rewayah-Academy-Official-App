import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_delais.dart';

/// Le delai jusqu'a la prochaine relecture programmee : le premier des
/// [instants] encore a venir, plus [alea] ; `null` quand aucun n'est a venir.
/// Pure, pour etre testee.
Duration? prochainDelaiRelecture(
  List<DateTime> instants,
  DateTime maintenant,
  Duration alea,
) {
  final List<DateTime> aVenir =
      instants.where((DateTime i) => i.isAfter(maintenant)).toList()..sort();
  return aVenir.isEmpty ? null : aVenir.first.difference(maintenant) + alea;
}

/// Un alea entre zero et [AppDelais.aleaRelecture] : deux mille eleves dont la
/// seance commence a la meme minute ne relisent pas dans la meme seconde.
Duration aleaRelecture([math.Random? hasard]) => Duration(
  milliseconds: (hasard ?? math.Random()).nextInt(
    AppDelais.aleaRelecture.inMilliseconds + 1,
  ),
);

/// Les relectures d'un accueil d'eleve, sans minuterie fixe (decision du
/// directeur du 29/10/2026, apres l'appareil de Hakim du 27/10) :
///
/// - la veille temps reel reste la source principale (`veille_fraicheur.dart`,
///   qui relit aussi tout au retour du reseau) ;
/// - au retour dans l'application, une relecture ;
/// - une seule relecture programmee a la fois, au premier des [instants] a
///   venir (quelques minutes avant la seance connue, puis a son debut), avec
///   un leger alea.
class RelecturesAccueil extends StatefulWidget {
  /// Cree les relectures autour de [child].
  const RelecturesAccueil({
    required this.relire,
    required this.instants,
    required this.child,
    this.horloge = DateTime.now,
    this.alea = aleaRelecture,
    super.key,
  });

  /// La relecture, par exemple `ref.invalidate(...)`.
  final VoidCallback relire;

  /// Les instants de relecture de la seance connue (vide : aucune).
  final List<DateTime> instants;

  /// Le contenu.
  final Widget child;

  /// L'instant courant, injectable pour les tests.
  final DateTime Function() horloge;

  /// L'alea de chaque relecture programmee, injectable pour les tests.
  final Duration Function() alea;

  @override
  State<RelecturesAccueil> createState() => _RelecturesAccueilState();
}

class _RelecturesAccueilState extends State<RelecturesAccueil> {
  Timer? _programmee;
  AppLifecycleListener? _cycle;

  @override
  void initState() {
    super.initState();
    _cycle = AppLifecycleListener(onResume: () => widget.relire());
    _programmer();
  }

  @override
  void didUpdateWidget(RelecturesAccueil ancien) {
    super.didUpdateWidget(ancien);
    if (!_memesInstants(ancien.instants, widget.instants)) {
      _programmer();
    }
  }

  static bool _memesInstants(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!a[i].isAtSameMomentAs(b[i])) return false;
    }
    return true;
  }

  void _programmer() {
    _programmee?.cancel();
    final Duration? delai = prochainDelaiRelecture(
      widget.instants,
      widget.horloge(),
      widget.alea(),
    );
    if (delai == null) return;
    _programmee = Timer(delai, () {
      widget.relire();
      // L'instant passe ne compte plus : la suivante, s'il en reste une.
      _programmer();
    });
  }

  @override
  void dispose() {
    _programmee?.cancel();
    _cycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
