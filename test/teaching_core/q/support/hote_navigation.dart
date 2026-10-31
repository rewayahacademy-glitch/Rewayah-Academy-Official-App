// Hote de navigation : un GoRouter de test, hors de `lib/`.
//
// PROPRIETE : Agent Q (test/teaching_core/q/). Aucune ligne de production.
//
// POURQUOI ICI ET PAS AILLEURS. `tool/verifier_jetons.dart` fait echouer la CI
// si un second fichier de `lib/` construit un `GoRouter` (decision D-04). Ce
// fichier vit sous `test/`, donc hors de la regle : c'est exactement le
// mecanisme que l'ownership prescrit pour developper et tester un ecran sans
// toucher au routeur global.
//
// CE QUE L'ARBRE DE WIDGETS DEMONTRE. La session est portee par un
// `InheritedWidget` place **AU-DESSUS** du `MaterialApp.router`. C'est la
// forme minimale de la decision D-24 : « le controleur de room est au niveau
// applicatif, pas attache au widget de la page Classe ». Aucune page ne peut
// donc couper la salle en se demontant -- sauf si elle le fait expres, ce que
// [EcranQuiPossedeLaRoom] permet de verifier.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../faux/faux_moteur_salle.dart';

/// Les chemins de test, sous le prefixe reserve `/tc/`.
abstract final class CheminsTc {
  /// Mes groupes.
  static const String groupes = '/tc/groupes';

  /// L'accueil.
  static const String accueil = '/tc/accueil';

  /// La Bibliotheque.
  static const String bibliotheque = '/tc/bibliotheque';

  /// La Classe Live.
  static const String classe = '/tc/classe';
}

/// Le porteur applicatif de la session, au-dessus du routeur.
class PorteurSession extends InheritedWidget {
  /// Cree un porteur.
  const PorteurSession({
    required this.session,
    required super.child,
    super.key,
  });

  /// La session persistante.
  final FauxSessionPersistante session;

  /// Le porteur le plus proche.
  static FauxSessionPersistante de(BuildContext context) {
    final PorteurSession? p = context
        .dependOnInheritedWidgetOfExactType<PorteurSession>();
    assert(p != null, 'aucun PorteurSession au-dessus de cet ecran');
    return p!.session;
  }

  @override
  bool updateShouldNotify(PorteurSession oldWidget) =>
      oldWidget.session != session;
}

/// La barre compacte « Seance toujours en direct », visible partout pendant une seance.
class BarreCoursEnCours extends StatelessWidget {
  /// Cree la barre.
  const BarreCoursEnCours({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionEnCoursDouble? session = PorteurSession.de(context).courante;
    if (session == null) return const SizedBox.shrink();
    return Semantics(
      container: true,
      child: Text(
        'Seance toujours en direct - ${session.libelleGroupe}',
        key: const Key('barre-cours-en-cours'),
      ),
    );
  }
}

/// Un ecran ordinaire : il n'a **aucun** pouvoir sur la session.
///
/// Son `dispose` ne touche a rien, et c'est tout le propos.
class EcranOrdinaire extends StatefulWidget {
  /// Cree un ecran.
  const EcranOrdinaire({required this.titre, super.key});

  /// Le titre affiche, qui sert aussi de cle de recherche au test.
  final String titre;

  @override
  State<EcranOrdinaire> createState() => _EcranOrdinaireEtat();
}

class _EcranOrdinaireEtat extends State<EcranOrdinaire> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        Text(widget.titre),
        const BarreCoursEnCours(),
      ],
    ),
  );
}

/// L'ANTI-PATRON, reproduit volontairement.
///
/// C'est la forme exacte du defaut nomme par la decision D-24 :
/// `_SallePageEtat.dispose()` appelle inconditionnellement `_moteur.quitter()`.
/// Il existe ici pour une seule raison -- prouver que le test Q-12 sait faire
/// la difference. Un test qui ne verrait pas cet ecran-la ne prouverait rien
/// sur les autres.
class EcranQuiPossedeLaRoom extends StatefulWidget {
  /// Cree l'ecran fautif.
  const EcranQuiPossedeLaRoom({required this.moteur, super.key});

  /// Le moteur que cet ecran s'arroge.
  final FauxMoteurSalle moteur;

  @override
  State<EcranQuiPossedeLaRoom> createState() => _EcranQuiPossedeLaRoomEtat();
}

class _EcranQuiPossedeLaRoomEtat extends State<EcranQuiPossedeLaRoom> {
  @override
  void dispose() {
    unawaited(widget.moteur.quitter());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Classe (fautive)'));
}

/// Construit le routeur de test.
GoRouter routeurDeTest({
  String depart = CheminsTc.groupes,
  FauxMoteurSalle? moteurFautif,
}) => GoRouter(
  initialLocation: depart,
  routes: <RouteBase>[
    GoRoute(
      path: CheminsTc.groupes,
      builder: (BuildContext c, GoRouterState s) =>
          const EcranOrdinaire(titre: 'Mes groupes'),
    ),
    GoRoute(
      path: CheminsTc.accueil,
      builder: (BuildContext c, GoRouterState s) =>
          const EcranOrdinaire(titre: 'Accueil'),
    ),
    GoRoute(
      path: CheminsTc.bibliotheque,
      builder: (BuildContext c, GoRouterState s) =>
          const EcranOrdinaire(titre: 'Bibliotheque'),
    ),
    GoRoute(
      path: CheminsTc.classe,
      builder: (BuildContext c, GoRouterState s) => moteurFautif == null
          ? const EcranOrdinaire(titre: 'Classe')
          : EcranQuiPossedeLaRoom(moteur: moteurFautif),
    ),
  ],
);

/// L'application de test : le porteur de session **au-dessus** du routeur.
Widget appDeTest({
  required FauxSessionPersistante session,
  required GoRouter routeur,
}) => PorteurSession(
  session: session,
  child: MaterialApp.router(
    routerConfig: routeur,
    debugShowCheckedModeBanner: false,
  ),
);
