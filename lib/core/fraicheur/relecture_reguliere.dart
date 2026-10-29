import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/app_delais.dart';

/// Relit une lecture toutes les [AppDelais.relectureAccueil] tant que [child]
/// est a l'ecran, et au retour dans l'application : le secours de la veille
/// temps reel (appareil de Hakim, 27/10/2026, ou une seance creee apres
/// l'ouverture de l'accueil n'y apparaissait jamais).
class RelectureReguliere extends StatefulWidget {
  /// Cree la relecture autour de [child].
  const RelectureReguliere({
    required this.relire,
    required this.child,
    super.key,
  });

  /// La relecture, par exemple `ref.invalidate(...)`.
  final VoidCallback relire;

  /// Le contenu.
  final Widget child;

  @override
  State<RelectureReguliere> createState() => _RelectureReguliereState();
}

class _RelectureReguliereState extends State<RelectureReguliere> {
  Timer? _minuteur;
  AppLifecycleListener? _cycle;

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(
      AppDelais.relectureAccueil,
      (Timer _) => widget.relire(),
    );
    _cycle = AppLifecycleListener(onResume: () => widget.relire());
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _cycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
