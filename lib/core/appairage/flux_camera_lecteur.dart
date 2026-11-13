import 'flux_camera_lecteur_natif.dart'
    if (dart.library.js_interop) 'flux_camera_lecteur_web.dart'
    as plateforme;

/// La prise sur le flux de la camera ouvert par le lecteur de QR
/// (CAMERA-JUMELAGE, seance du directeur du 12/11/2026).
///
/// Sur le web, `mobile_scanner` 7.4.2 n'arrete jamais les pistes du flux
/// qu'il ouvre par `getUserMedia` : `stop()` et `dispose()` oublient le flux
/// sans appeler `track.stop()` (`mobile_scanner_web.dart`,
/// `polling_barcode_reader.dart`). L'application etant a page unique, la
/// camera arriere restait ouverte jusqu'a la salle, et la camera avant ne
/// pouvait plus s'ouvrir (`NotReadableError`).
///
/// Le paquet ne rend ni le flux ni l'element `<video>` par une API publique,
/// et cet element n'est pas encore dans le document quand `start()` se
/// termine (la vue de plateforme est inseree a la construction suivante).
/// La prise ecoute donc, pendant le seul demarrage du lecteur, les flux
/// attaches a un element `<video>` qui porte la signature de celui du
/// paquet ; elle ne ferme que ceux-la, jamais la visio de la salle.
abstract interface class PriseFluxCamera {
  /// Ouvre la fenetre d'ecoute, juste avant `start()`.
  void ouvrirCapture();

  /// Ferme la fenetre d'ecoute et rend les flux attaches pendant elle
  /// (jetons opaques).
  List<Object> fermerCapture();

  /// Arrete toutes les pistes de [flux] et les detache de leur element.
  void fermer(Iterable<Object> flux);
}

/// La prise de la plateforme courante (sans effet hors navigateur : les
/// paquets natifs ferment eux-memes la camera).
PriseFluxCamera priseFluxCameraDeLaPlateforme() =>
    plateforme.priseFluxCameraDeLaPlateforme();

/// Le cycle de vie de la camera du lecteur, separe du paquet pour se tester
/// sans navigateur : demarrer, arreter, liberer, et toujours fermer le flux.
class CycleCameraLecteur {
  /// Cree le cycle sur les trois commandes du moteur et sur [prise].
  CycleCameraLecteur({
    required this.demarrerMoteur,
    required this.arreterMoteur,
    required this.libererMoteur,
    required this.prise,
  });

  /// Demarre la camera du paquet (`MobileScannerController.start`).
  final Future<void> Function() demarrerMoteur;

  /// Arrete la camera du paquet (`MobileScannerController.stop`).
  final Future<void> Function() arreterMoteur;

  /// Rend la camera du paquet (`MobileScannerController.dispose`).
  final Future<void> Function() libererMoteur;

  /// La prise sur le flux ouvert par le paquet.
  final PriseFluxCamera prise;

  final List<Object> _flux = <Object>[];
  bool _libere = false;

  /// Vrai apres [liberer].
  bool get libere => _libere;

  /// Le nombre de flux ouverts et pas encore fermes (pour les tests).
  int get fluxOuverts => _flux.length;

  /// Demarre le moteur. Rend faux si [liberer] est arrive pendant le
  /// demarrage : le flux ouvert entre-temps est alors ferme aussitot, et le
  /// moteur arrete. Une erreur du moteur est relancee, apres fermeture du
  /// flux qu'il aurait ouvert avant d'echouer.
  Future<bool> demarrer() async {
    if (_libere) {
      return false;
    }
    prise.ouvrirCapture();
    List<Object> nouveaux = const <Object>[];
    try {
      await demarrerMoteur();
    } on Object {
      nouveaux = prise.fermerCapture();
      prise.fermer(nouveaux);
      rethrow;
    }
    nouveaux = prise.fermerCapture();
    if (_libere) {
      // `start()` a fini apres la liberation : personne ne fermerait ce flux.
      prise.fermer(nouveaux);
      try {
        await arreterMoteur();
      } on Object {
        // Moteur deja rendu.
      }
      return false;
    }
    _flux.addAll(nouveaux);
    return true;
  }

  /// Arrete le moteur, puis ferme le flux. Un nouveau [demarrer] rouvre un
  /// flux neuf.
  Future<void> arreter() async {
    if (_libere) {
      return;
    }
    try {
      await arreterMoteur();
    } finally {
      _fermerTout();
    }
  }

  /// Rend le moteur pour de bon, puis ferme le flux.
  Future<void> liberer() async {
    if (_libere) {
      return;
    }
    _libere = true;
    try {
      await libererMoteur();
    } finally {
      _fermerTout();
    }
  }

  void _fermerTout() {
    if (_flux.isEmpty) {
      return;
    }
    final List<Object> aFermer = List<Object>.of(_flux);
    _flux.clear();
    prise.fermer(aFermer);
  }
}
