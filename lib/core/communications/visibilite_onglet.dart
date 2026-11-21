// PERSONNES-PERF (20/11/2026) : savoir si l'application est vue (onglet au
// premier plan, application ouverte) ou cachee (autre onglet, fenetre reduite,
// ecran verrouille), pour que la veille des messages espace ses relectures de
// repli quand personne ne regarde, et relise tout de suite au retour.
//
// En production, le navigateur annonce la visibilite du document au moteur
// Flutter, qui la rend comme un etat du cycle de vie (`hidden` quand l'onglet
// est cache). Muette par defaut (toujours vue) : tests, galerie,
// demonstration ; l'adaptateur Flutter est branche au demarrage reel
// (`lib/main.dart`).

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Par ou l'application sait si elle est vue.
abstract interface class PortVisibilite {
  /// Vrai si l'application est vue en ce moment.
  bool get visible;

  /// Chaque changement de visibilite (vrai : vue), sans repetition.
  Stream<bool> changements();
}

/// Toujours vue, ne change jamais : tests, galerie, demonstration.
class VisibiliteToujours implements PortVisibilite {
  /// Cree la visibilite muette.
  const VisibiliteToujours();

  @override
  bool get visible => true;

  @override
  Stream<bool> changements() => const Stream<bool>.empty();
}

/// La visibilite lue dans le cycle de vie de Flutter.
class VisibiliteFlutter implements PortVisibilite {
  /// Cree l'adaptateur (le lien au cycle de vie se pose a la premiere ecoute).
  const VisibiliteFlutter();

  /// Vue : au premier plan (`resumed`), ou visible sans le clavier
  /// (`inactive`, une fenetre a cote a le focus). Cachee sinon. Pure.
  static bool estVue(AppLifecycleState? etat) =>
      etat == null ||
      etat == AppLifecycleState.resumed ||
      etat == AppLifecycleState.inactive;

  @override
  bool get visible => estVue(WidgetsBinding.instance.lifecycleState);

  @override
  Stream<bool> changements() {
    AppLifecycleListener? ecoute;
    late final StreamController<bool> flux;
    flux = StreamController<bool>(
      onListen: () {
        ecoute = AppLifecycleListener(
          onStateChange: (AppLifecycleState etat) {
            if (!flux.isClosed) flux.add(estVue(etat));
          },
        );
      },
      onCancel: () async {
        ecoute?.dispose();
        ecoute = null;
        await flux.close();
      },
    );
    return flux.stream.distinct();
  }
}

/// Le port employe par l'application : toujours vue par defaut.
final Provider<PortVisibilite> portVisibiliteProvider =
    Provider<PortVisibilite>((Ref ref) => const VisibiliteToujours());
