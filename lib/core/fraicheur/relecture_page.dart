// R3 (30/10/2026) : au telephone, rien ne se rafraichissait. Tirer pour
// rafraichir dans le composant de page commun (`PageShell`), et relire a
// chaque retour sur un onglet (changement d'onglet de la coquille, retour
// dans l'application).
//
// La relecture est celle de la veille de fraicheur (`veille_fraicheur.dart`) :
// toutes ses familles (classes, seances, notifications). Une lecture qui doit
// suivre ce geste s'ajoute a `lecturesVeillees`, comme pour un signal du
// serveur : c'est la seule liste qui decide de ce qui se relit.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import 'port_veille.dart' show FamilleLecture;
import 'veille_fraicheur.dart' show invaliderFamille;

/// L'intervalle minimal entre deux relectures automatiques (onglet, retour
/// dans l'application) : passer d'un onglet a l'autre en rafale ne relit pas
/// a chaque geste. Tirer pour rafraichir relit toujours.
const Duration intervalleRelectureAutomatique = Duration(seconds: 10);

/// Relit toutes les lectures veillees. Sans personne connectee, rien (R9 :
/// aucune lecture ne part sans session).
final Provider<void Function()> relectureGeneraleProvider =
    Provider<void Function()>(
      (Ref ref) => () {
        if (ref.read(sessionProvider).profileId == null) {
          return;
        }
        for (final FamilleLecture famille in FamilleLecture.values) {
          invaliderFamille(ref, famille);
        }
      },
    );

/// Ce que `PageShell` appelle quand on tire la page vers le bas, et ce que la
/// coquille appelle au changement d'onglet. Pose une fois par l'application
/// ([RelectureGenerale]) ; absent (une page testee seule), la page ne se
/// tire pas et rien ne change.
class RelecturePage extends InheritedWidget {
  /// Cree la relecture.
  const RelecturePage({
    required this.relire,
    required this.relireAuRetour,
    required super.child,
    super.key,
  });

  /// La relecture du geste « tirer pour rafraichir ».
  final Future<void> Function() relire;

  /// La relecture automatique (onglet, retour) : bornee par
  /// [intervalleRelectureAutomatique].
  final VoidCallback relireAuRetour;

  /// La relecture du geste, ou `null` hors de l'application.
  static Future<void> Function()? de(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RelecturePage>()?.relire;

  /// La relecture automatique, ou `null` hors de l'application.
  static VoidCallback? auRetourDe(BuildContext context) =>
      context.getInheritedWidgetOfExactType<RelecturePage>()?.relireAuRetour;

  @override
  bool updateShouldNotify(RelecturePage ancien) => false;
}

/// Pose [RelecturePage] au-dessus de toutes les routes, et relit au retour
/// dans l'application. **Montee par `RewayahApp` seulement.**
class RelectureGenerale extends ConsumerStatefulWidget {
  /// Cree la relecture autour de [child].
  const RelectureGenerale({
    required this.child,
    this.horloge = DateTime.now,
    super.key,
  });

  /// Le contenu.
  final Widget child;

  /// L'instant courant, injectable pour les tests.
  final DateTime Function() horloge;

  @override
  ConsumerState<RelectureGenerale> createState() => _RelectureGeneraleState();
}

class _RelectureGeneraleState extends ConsumerState<RelectureGenerale> {
  AppLifecycleListener? _cycle;
  DateTime? _derniere;

  @override
  void initState() {
    super.initState();
    _cycle = AppLifecycleListener(onResume: _relireAuRetour);
  }

  @override
  void dispose() {
    _cycle?.dispose();
    super.dispose();
  }

  Future<void> _relire() async {
    _derniere = widget.horloge();
    ref.read(relectureGeneraleProvider)();
  }

  void _relireAuRetour() {
    final DateTime? derniere = _derniere;
    if (derniere != null &&
        widget.horloge().difference(derniere) <
            intervalleRelectureAutomatique) {
      return;
    }
    unawaited(_relire());
  }

  @override
  Widget build(BuildContext context) => RelecturePage(
    relire: _relire,
    relireAuRetour: _relireAuRetour,
    child: widget.child,
  );
}
