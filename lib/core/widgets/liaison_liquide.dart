// GOUTTE D'HUILE (directeur, 11/11/2026) : relier deux silhouettes
// quelconques par un cou de matiere. `pontMetaballe` (la barre, PR 420) ne
// sait relier que deux disques ; ici, un cercle et un rectangle arrondi
// (le rond d'un profil et la carte de son contenu) se ramenent chacun a un
// disque : celui du rond, et, pour un rectangle, le disque de son coin le plus
// proche de l'autre silhouette. Le calcul du cou reste celui de la barre : le
// composant de la barre n'est pas touche (ses captures ne changent pas).
//
// Pur : aucune animation, aucun widget. Reutilisable partout (« la barre est
// un laboratoire »).
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'indicateur_liquide.dart' show pontMetaballe;

/// Une silhouette que le cou peut relier : un disque, ou un rectangle dont les
/// coins sont arrondis de [rayon].
@immutable
class SilhouetteLiquide {
  /// Un disque de centre [centre] et de rayon [rayon].
  SilhouetteLiquide.disque(Offset centre, double rayon)
    : rect = Rect.fromCircle(center: centre, radius: rayon),
      rayon = rayon;

  /// Un rectangle [rect] aux coins arrondis de [rayon] (au plus la moitie de
  /// son petit cote).
  SilhouetteLiquide.rectangle(this.rect, double rayon)
    : rayon = math.max(0, math.min(rayon, rect.shortestSide / 2));

  /// La boite de la silhouette.
  final Rect rect;

  /// Le rayon de ses coins (celui du disque pour un cercle).
  final double rayon;

  /// Le disque par lequel la silhouette se relie a un point [vers] : le disque
  /// du rond lui-meme, ou, pour un rectangle, le disque de coin le plus proche
  /// de [vers] qui reste dans le rectangle (le cou s'accroche au bord, a
  /// l'aplomb de l'autre silhouette).
  ({Offset centre, double rayon}) ancre(Offset vers) {
    // Le rectangle ou peut se poser le centre du disque d'accroche : celui de
    // la silhouette moins son rayon. Pour un disque, il se reduit a un point
    // (et, a un arrondi pres, ses bornes peuvent se croiser : le milieu).
    final Rect interieur = rect.deflate(rayon);
    final Offset centre = Offset(
      _borner(vers.dx, interieur.left, interieur.right),
      _borner(vers.dy, interieur.top, interieur.bottom),
    );
    return (centre: centre, rayon: rayon);
  }
}

/// Le cou entre [a] et [b] : une forme molle qui les relie, de plus en plus
/// fine quand [v] baisse (0,5 : pleine ; 0 : un fil), vide quand elles sont
/// trop loin ([portee] fois la somme des rayons) ou que l'une contient
/// l'autre. Se peint sous les silhouettes : seule sa part entre elles se voit.
Path pontEntreSilhouettes(
  SilhouetteLiquide a,
  SilhouetteLiquide b, {
  double v = 0.5,
  double portee = 4,
}) {
  final ({Offset centre, double rayon}) pa = _ancres(a, b).$1;
  final ({Offset centre, double rayon}) pb = _ancres(a, b).$2;
  return pontMetaballe(
    pa.centre,
    pa.rayon,
    pb.centre,
    pb.rayon,
    v: v,
    portee: portee,
  );
}

/// L'ecart entre les deux silhouettes, mesure entre leurs disques
/// d'accroche : negatif quand elles se chevauchent.
double ecartEntreSilhouettes(SilhouetteLiquide a, SilhouetteLiquide b) {
  final (
    ({Offset centre, double rayon}) pa,
    ({Offset centre, double rayon}) pb,
  ) = _ancres(
    a,
    b,
  );
  return (pb.centre - pa.centre).distance - pa.rayon - pb.rayon;
}

/// Les deux disques d'accroche, calcules l'un par rapport a l'autre (deux
/// passes : le premier choix d'un rectangle depend du centre de l'autre
/// silhouette, le second du disque d'accroche trouve).
(({Offset centre, double rayon}), ({Offset centre, double rayon})) _ancres(
  SilhouetteLiquide a,
  SilhouetteLiquide b,
) {
  ({Offset centre, double rayon}) pa = a.ancre(b.rect.center);
  ({Offset centre, double rayon}) pb = b.ancre(pa.centre);
  pa = a.ancre(pb.centre);
  pb = b.ancre(pa.centre);
  return (pa, pb);
}

/// [v] borne entre [bas] et [haut] ; le milieu quand les bornes se croisent
/// (un disque : sa zone d'accroche est un point).
double _borner(double v, double bas, double haut) =>
    bas >= haut ? (bas + haut) / 2 : v.clamp(bas, haut).toDouble();
