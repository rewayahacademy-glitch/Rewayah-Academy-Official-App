import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../widgets/selection_si_visible.dart';
import 'app_transitions.dart';
import 'mouvement.dart';
import 'retour_navigateur.dart';

/// Page empilee : la descente du catalogue (`AppTransitions.descente`, axe
/// partage horizontal, en miroir en arabe). Duree nulle quand les animations
/// sont reduites ; sur le web, le retour est un fondu court.
Page<void> pageGlissee(
  BuildContext context,
  GoRouterState etat,
  Widget enfant,
) {
  final bool reduit = Mouvement.reduit(context);
  final Duration entree = AppTransitions.dureeDescente(context);
  return CustomTransitionPage<void>(
    key: etat.pageKey,
    name: etat.name ?? etat.path,
    arguments: <String, String>{
      ...etat.pathParameters,
      ...etat.uri.queryParameters,
    },
    restorationId: etat.pageKey.value,
    transitionDuration: reduit ? Duration.zero : entree,
    reverseTransitionDuration: reduit
        ? Duration.zero
        : AppTransitions.sortieDe(entree),
    transitionsBuilder: _descente,
    child: enfant,
  );
}

/// Adapte un constructeur d'ecran en `pageBuilder` qui utilise
/// [pageGlissee].
GoRouterPageBuilder glissee(Widget Function(GoRouterState etat) ecran) =>
    (BuildContext context, GoRouterState etat) =>
        pageGlissee(context, etat, ecran(etat));

/// Part de la transition pendant laquelle la page recouverte s'efface,
/// avant que la nouvelle n'apparaisse (fondu en passage, LG-FLASH).
const double partEffacement = AppTransitions.partEffacement;

Widget _descente(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaire,
  Widget enfantRoute,
) {
  // Selection du texte : une page masquee n'inscrit rien (07/11/2026).
  final Widget child = SelectionSiVisible(child: enfantRoute);
  // Regle 9 : fondu court pour un retour du navigateur seulement ; la fleche
  // de l'application garde l'axe partage inverse.
  if (fonduDeRetourWeb(
    web: kIsWeb,
    retourEnCours: animation.status == AnimationStatus.reverse,
    retourDuNavigateur: RetourNavigateur.recent(),
  )) {
    return AppTransitions.fonduCourt(animation, child);
  }
  return AppTransitions.descente(context, animation, secondaire, child);
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
