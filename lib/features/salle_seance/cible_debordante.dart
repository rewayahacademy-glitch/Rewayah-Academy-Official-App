// Une cible tactile plus grande que ce qu'elle montre, sans prendre de place
// dans la mise en page (lien « En savoir plus » du bandeau de la salle,
// JUR-APP-1).

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';

/// La zone qui recoit, pour ses descendants [CibleDebordante], les touches
/// tombees hors de leur boite mais dans leur cible tactile.
///
/// Sans elle, Flutter ne teste un enfant que dans la boite de ses parents :
/// une cible de 48 (72 en guidee) posee sur une ligne de texte de 16 ne
/// recevrait que les touches de la ligne. La zone teste d'abord le reste de
/// l'arbre, comme d'habitude : si la touche tombe sur une autre commande
/// (le chevron Retour, un bouton de l'en-tete), cette commande la garde. Ce
/// n'est que si rien de pressable ne l'a prise que la zone la donne a une
/// cible debordante qui la couvre. Une cible debordante ne l'emporte donc
/// jamais sur une autre commande, meme quand elle passe sous le chevron
/// (salle guidee a 320, le lien sous la mention). Elle ne dessine rien et ne
/// change aucune mesure.
///
/// Une cible ne s'etend jamais hors de la zone : la zone la plus proche (ici
/// l'en-tete de la salle) borne ce qu'elle peut couvrir.
class ZoneCiblesDebordantes extends SingleChildRenderObjectWidget {
  /// Cree la zone.
  const ZoneCiblesDebordantes({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderZoneCibles();
}

class _RenderZoneCibles extends RenderProxyBox {
  final Set<_RenderCibleDebordante> _cibles = <_RenderCibleDebordante>{};

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // L'arbre normal d'abord : une commande touchee garde la touche.
    final int avant = result.path.length;
    final bool arbre = super.hitTestChildren(result, position: position);
    if (result.path.skip(avant).any(_estCommande)) return true;
    // Rien de pressable n'a pris la touche : une cible debordante peut la
    // recevoir. Les entrees deja posees (fonds, textes) ne reagissent a rien.
    for (final _RenderCibleDebordante cible in _cibles) {
      if (!cible.attached || !cible.hasSize) continue;
      final bool touche = result.addWithPaintTransform(
        transform: cible.getTransformTo(this),
        position: position,
        hitTest: (BoxHitTestResult r, Offset p) =>
            cible.hitTestCible(r, position: p),
      );
      if (touche) return true;
    }
    return arbre;
  }

  /// Une entree qui reagit au doigt : l'ecouteur d'un `GestureDetector`
  /// (donc de tout `Pressable`, `InkWell` ou bouton Material).
  static bool _estCommande(HitTestEntry entree) {
    final Object cible = entree.target;
    return cible is RenderPointerListener && cible.onPointerDown != null;
  }
}

/// Un enfant qui garde sa taille visible (une ligne de texte) mais recoit les
/// touches sur une cible d'au moins [AppMetriques.cibleTactile] de cote,
/// centree sur lui en largeur et posee au-dessus de lui en hauteur.
///
/// La cible deborde de [debordementBas] au plus sous la ligne (la marge basse
/// de l'en-tete de la salle, `AppSpacing.sm`), le reste au-dessus : elle ne
/// mord jamais sur la surface du cours. Une touche dans la cible est rendue a
/// l'enfant en son centre, comme le fait Material pour ses cibles agrandies.
///
/// L'enfant doit etre lui-meme pressable sans cible minimale
/// (`Pressable(respecterCibleTactile: false)`) : c'est cet objet qui porte la
/// cible, sans la dessiner, pour que l'anneau de focus reste serre sur le
/// texte.
///
/// Le noeud semantique du lien garde la boite du texte, volontairement : a
/// 320 la cible agrandie passe sous le chevron Retour, et un noeud agrandi
/// le recouvrirait pour l'exploration au toucher des lecteurs d'ecran (le
/// defaut que la zone evite pour le doigt). Un lecteur d'ecran active le
/// lien par double-tape une fois le noeud atteint, ou il l'atteint en
/// balayant ; la taille du noeud n'y change rien.
class CibleDebordante extends SingleChildRenderObjectWidget {
  /// Cree la cible.
  const CibleDebordante({
    required Widget super.child,
    super.key,
    this.debordementBas = AppSpacing.sm,
  });

  /// Ce que la cible peut prendre sous la ligne visible, au plus.
  final double debordementBas;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCibleDebordante(
        context.findAncestorRenderObjectOfType<_RenderZoneCibles>(),
        cote: AppMetriques.of(context).cibleTactile,
        debordementBas: debordementBas,
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCibleDebordante)
      ..cote = AppMetriques.of(context).cibleTactile
      ..debordementBas = debordementBas
      ..zone = context.findAncestorRenderObjectOfType<_RenderZoneCibles>();
  }
}

class _RenderCibleDebordante extends RenderProxyBox {
  _RenderCibleDebordante(
    this._zone, {
    required this.cote,
    required this.debordementBas,
  });

  double cote;
  double debordementBas;

  _RenderZoneCibles? _zone;
  set zone(_RenderZoneCibles? valeur) {
    if (identical(valeur, _zone)) return;
    _zone?._cibles.remove(this);
    _zone = valeur;
    if (attached) _zone?._cibles.add(this);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _zone?._cibles.add(this);
  }

  @override
  void detach() {
    _zone?._cibles.remove(this);
    super.detach();
  }

  /// La cible, dans le repere de cet objet.
  Rect get cible {
    final double largeur = size.width > cote ? size.width : cote;
    final double marge = (cote - size.height) / 2;
    final double bas =
        size.height + (marge < debordementBas ? marge : debordementBas);
    return Rect.fromLTRB(
      (size.width - largeur) / 2,
      bas - (cote > size.height ? cote : size.height),
      (size.width + largeur) / 2,
      bas,
    );
  }

  /// Dans l'arbre normal, la cible ne prend que les touches de sa boite
  /// visible : elle ne peut pas y passer devant une voisine. Sa cible agrandie
  /// n'est testee que par la zone ([hitTestCible]), apres les autres
  /// commandes.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      super.hitTest(result, position: position);

  /// La touche [position] tombe dans la cible agrandie : elle est rendue a
  /// l'enfant en son centre.
  bool hitTestCible(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? enfant = child;
    if (enfant == null || !cible.contains(position)) return false;
    final Offset centre = enfant.size.center(Offset.zero);
    final bool touche = result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(centre),
      position: centre,
      hitTest: (BoxHitTestResult r, Offset p) => enfant.hitTest(r, position: p),
    );
    if (touche) result.add(BoxHitTestEntry(this, position));
    return touche;
  }
}
