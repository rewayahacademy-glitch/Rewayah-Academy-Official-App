// Le Studio, Mode focus : la restauration (`FocusStateRestorer`, COM-STU-3 ;
// spec section 10.5, section 20 « FocusStateRestorer », R-COM-10).
//
// Le Focus est un ETAT local du canal (COM-W03F), jamais une route : le canal,
// son fil, son champ et l'espace adaptatif restent montes pendant tout le
// Focus (la coquille du Studio garde leur sous-arbre par une cle globale).
// Ce qui ne survit pas de soi-meme a ce changement de disposition, c'est ce
// qui depend de la LARGEUR : en Focus, le fil passe a la largeur de lecture,
// ses bulles se recomposent, et la position de lecture en pixels perd son
// sens (elle est meme rognee si le fil raccourcit). D'ou ce restaurateur.
//
// Avant le Focus, il capture localement, aupres des sources inscrites :
//
// - la position de lecture du fil (scroll) ;
// - le champ du canal (brouillon et selection) ;
// - la recherche locale (texte, filtre, surface ouverte) ;
// - le panneau droit (ouvert ou ferme).
//
// A la sortie, il capture une seconde fois (juste avant que la disposition
// revienne), puis, une image plus tard, il restaure : les positions et les
// panneaux d'apres la capture d'ENTREE, le texte saisi d'apres la capture de
// SORTIE. Un texte ecrit pendant le Focus n'est donc jamais remplace par un
// texte plus ancien : aucune perte de texte saisi n'est acceptable (section
// 10.5). Tout se remet sans animation (section 20).
//
// Rien ne quitte l'appareil : ni serveur, ni stockage. La memoire tient le
// temps du Focus.

import 'package:flutter/widgets.dart';

/// Une source d'etat local que le Focus capture puis restaure.
abstract interface class SourceEtatFocus {
  /// Ce que la source vaut maintenant ; nul si elle n'a rien a garder (un
  /// fil pas encore mesure, un canal sans champ).
  Object? capturer();

  /// Remet la source en etat, a la sortie du Focus. [entree] est la capture
  /// d'avant le Focus, [sortie] celle d'au moment de quitter.
  void restaurer({required Object? entree, required Object? sortie});
}

/// Les valeurs capturees, par cle de source.
@immutable
class InstantaneFocus {
  /// Cree l'instantane.
  const InstantaneFocus(this.valeurs);

  /// Un instantane sans source.
  static const InstantaneFocus vide = InstantaneFocus(<String, Object?>{});

  /// Les valeurs, par cle de source.
  final Map<String, Object?> valeurs;

  /// La valeur de la source [cle], ou nul.
  Object? operator [](String cle) => valeurs[cle];
}

/// Le restaurateur d'etat du Focus (`FocusStateRestorer`).
///
/// Les sources s'inscrivent sous une cle (le fil, le champ, la recherche, le
/// panneau). [retenir] capture avant le Focus ; [restaurer] remet chaque
/// source a la sortie. Une source retiree pendant le Focus n'est pas
/// restauree ; une source inscrite pendant le Focus recoit `entree` nulle.
class RestaurateurEtatFocus {
  final Map<String, SourceEtatFocus> _sources = <String, SourceEtatFocus>{};
  InstantaneFocus? _entree;

  /// Les cles des sources inscrites, pour les tests.
  Iterable<String> get cles => _sources.keys;

  /// L'instantane d'entree retenu, tant que le Focus dure.
  InstantaneFocus? get entree => _entree;

  /// Inscrit [source] sous [cle] (remplace une source plus ancienne).
  void inscrire(String cle, SourceEtatFocus source) => _sources[cle] = source;

  /// Retire [source] de [cle], si c'est bien elle qui y est inscrite.
  void retirer(String cle, SourceEtatFocus source) {
    if (identical(_sources[cle], source)) _sources.remove(cle);
  }

  /// Capture toutes les sources inscrites, maintenant.
  InstantaneFocus capturer() => InstantaneFocus(<String, Object?>{
    for (final MapEntry<String, SourceEtatFocus> e in _sources.entries)
      e.key: e.value.capturer(),
  });

  /// Retient l'etat d'avant le Focus.
  void retenir() => _entree = capturer();

  /// Remet chaque source, avec la capture d'entree et [sortie] (la capture
  /// prise au moment de quitter). Sans capture d'entree, rien n'est fait.
  void restaurer(InstantaneFocus sortie) {
    final InstantaneFocus? entree = _entree;
    _entree = null;
    if (entree == null) return;
    for (final MapEntry<String, SourceEtatFocus> e
        in _sources.entries.toList()) {
      e.value.restaurer(entree: entree[e.key], sortie: sortie[e.key]);
    }
  }

  /// Oublie la capture sans rien restaurer : le Focus a pris fin parce que
  /// la personne est allee ailleurs (un autre canal, une autre vue).
  void oublier() => _entree = null;
}

/// Une position de lecture : en pixels, et « au bas du fil ».
@immutable
class PositionLecture {
  /// Cree la position.
  const PositionLecture({required this.pixels, required this.enBas});

  /// Le decalage, en pixels logiques.
  final double pixels;

  /// Vrai si la lecture etait au bas du fil (dernier message visible) : elle
  /// y revient, meme si le fil a grandi entre-temps.
  final bool enBas;

  @override
  bool operator ==(Object other) =>
      other is PositionLecture &&
      other.pixels == pixels &&
      other.enBas == enBas;

  @override
  int get hashCode => Object.hash(pixels, enBas);

  @override
  String toString() => 'PositionLecture($pixels, enBas: $enBas)';
}

/// La source « position de lecture » d'une zone defilante.
class SourceDefilement implements SourceEtatFocus {
  /// Cree la source ; [position] rend la position du fil, ou nul s'il n'est
  /// pas encore mesure.
  SourceDefilement(this.position);

  /// La position du fil, lue a chaque capture et restauration (le fil peut
  /// avoir ete reconstruit entre-temps).
  final ScrollPosition? Function() position;

  /// En deca de cet ecart avec la fin, la lecture est « au bas du fil ».
  static const double toleranceBas = 1;

  @override
  Object? capturer() {
    final ScrollPosition? p = position();
    if (p == null || !p.hasPixels || !p.hasContentDimensions) return null;
    return PositionLecture(
      pixels: p.pixels,
      enBas: p.maxScrollExtent - p.pixels <= toleranceBas,
    );
  }

  @override
  void restaurer({required Object? entree, required Object? sortie}) {
    if (entree is! PositionLecture) return;
    final ScrollPosition? p = position();
    if (p == null || !p.hasPixels || !p.hasContentDimensions) return;
    final double cible = (entree.enBas ? p.maxScrollExtent : entree.pixels)
        .clamp(p.minScrollExtent, p.maxScrollExtent);
    // Sans animation : la lecture reprend la ou elle etait.
    if (p.pixels != cible) p.jumpTo(cible);
  }
}

/// La source « champ de saisie » : son texte et sa selection.
///
/// Restaure d'apres la capture de SORTIE : ce qui a ete ecrit pendant le
/// Focus reste ; un texte plus ancien ne le remplace jamais.
class SourceChamp implements SourceEtatFocus {
  /// Cree la source ; [controleur] rend le controleur du champ, ou nul sans
  /// champ (canal en lecture seule).
  SourceChamp(this.controleur);

  /// Le controleur du champ, lu a chaque capture et restauration.
  final TextEditingController? Function() controleur;

  @override
  Object? capturer() => controleur()?.value;

  @override
  void restaurer({required Object? entree, required Object? sortie}) {
    final TextEditingController? c = controleur();
    if (c == null) return;
    final Object? voulu = sortie ?? entree;
    if (voulu is! TextEditingValue) return;
    if (c.text != voulu.text) {
      // Le champ a ete recree vide : le texte saisi est remis tel quel.
      c.value = voulu.copyWith(composing: TextRange.empty);
    } else if (c.selection != voulu.selection && voulu.selection.isValid) {
      c.selection = voulu.selection;
    }
  }
}

/// Une source faite de deux fonctions : lire la valeur, et la remettre si
/// elle a change. Restauree d'apres la capture d'ENTREE.
class SourceValeur<T> implements SourceEtatFocus {
  /// Cree la source.
  SourceValeur({required this.lire, required this.ecrire});

  /// Lit la valeur courante.
  final T Function() lire;

  /// Remet une valeur capturee.
  final void Function(T valeur) ecrire;

  @override
  Object? capturer() => _Boite<T>(lire());

  @override
  void restaurer({required Object? entree, required Object? sortie}) {
    if (entree is! _Boite<T>) return;
    if (lire() != entree.valeur) ecrire(entree.valeur);
  }
}

/// Une valeur capturee, meme nulle (nul veut dire « rien capture »).
@immutable
class _Boite<T> {
  const _Boite(this.valeur);

  final T valeur;
}
