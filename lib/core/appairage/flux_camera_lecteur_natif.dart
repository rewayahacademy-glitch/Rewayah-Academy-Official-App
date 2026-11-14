import 'flux_camera_lecteur.dart';

/// Hors navigateur : sans effet. Les greffons natifs de `mobile_scanner`
/// rendent eux-memes la camera a l'arret.
PriseFluxCamera priseFluxCameraDeLaPlateforme() => const _PriseSansEffet();

class _PriseSansEffet implements PriseFluxCamera {
  const _PriseSansEffet();

  @override
  void ouvrirCapture() {}

  @override
  List<Object> fermerCapture() => const <Object>[];

  @override
  void fermer(Iterable<Object> flux) {}
}
