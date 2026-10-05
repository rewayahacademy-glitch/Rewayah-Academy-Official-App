import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'mouvement.dart';

/// Page empilee : glisse court depuis le bord de lecture et fondu. Le sens
/// suit la direction du texte (arabe : depuis la gauche). Duree nulle quand
/// les animations sont reduites.
Page<void> pageGlissee(
  BuildContext context,
  GoRouterState etat,
  Widget enfant,
) {
  final bool reduit = Mouvement.reduit(context);
  return CustomTransitionPage<void>(
    key: etat.pageKey,
    name: etat.name ?? etat.path,
    arguments: <String, String>{
      ...etat.pathParameters,
      ...etat.uri.queryParameters,
    },
    restorationId: etat.pageKey.value,
    transitionDuration: reduit ? Duration.zero : Mouvement.long,
    reverseTransitionDuration: reduit ? Duration.zero : Mouvement.moyen,
    transitionsBuilder: _glisseEtFondu,
    child: enfant,
  );
}

/// Adapte un constructeur d'ecran en `pageBuilder` qui utilise
/// [pageGlissee].
GoRouterPageBuilder glissee(Widget Function(GoRouterState etat) ecran) =>
    (BuildContext context, GoRouterState etat) =>
        pageGlissee(context, etat, ecran(etat));

Widget _glisseEtFondu(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaire,
  Widget child,
) {
  final CurvedAnimation courbe = CurvedAnimation(
    parent: animation,
    curve: Mouvement.accentuee,
    reverseCurve: Mouvement.sortie,
  );
  final double dx = Directionality.of(context) == TextDirection.rtl
      ? -0.06
      : 0.06;
  return RepaintBoundary(
    child: FadeTransition(
      opacity: courbe,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(dx, 0),
          end: Offset.zero,
        ).animate(courbe),
        child: child,
      ),
    ),
  );
}

/// Fondu simple quand l'onglet actif d'une barre change ([index]). L'enfant
/// n'est jamais recree : seule son opacite bouge, ce qui preserve l'etat des
/// branches (`StatefulNavigationShell`).
class FonduOnglet extends StatefulWidget {
  /// Cree le fondu d'onglet.
  const FonduOnglet({super.key, required this.index, required this.child});

  /// L'onglet actif.
  final int index;

  /// Le contenu des onglets.
  final Widget child;

  @override
  State<FonduOnglet> createState() => _FonduOngletState();
}

class _FonduOngletState extends State<FonduOnglet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: Mouvement.moyen,
    value: 1,
  );
  late final CurvedAnimation _opacite = CurvedAnimation(
    parent: _controleur,
    curve: Mouvement.entree,
  );

  @override
  void didUpdateWidget(FonduOnglet ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.index != widget.index && !Mouvement.reduit(context)) {
      _controleur.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _opacite.dispose();
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(opacity: _opacite, child: widget.child),
  );
}
