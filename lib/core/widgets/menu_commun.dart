// Ce que `MenuActions` et `MenuFiltre` ont en commun (LISTES-1, 23/10/2026).
//
// Un seul systeme de menus (mission du directeur, defaut critique du menu du
// bouton d'action) : les deux composants restent sur `PopupMenuButton` (Echap,
// clic exterieur, un seul menu ouvert, bornage a l'ecran, miroir en arabe sont
// natifs et gardes par `test/core/widgets/menu_commun_test.dart`), et ce
// fichier porte le reste, une seule fois :
//
//   * le declencheur est un [Pressable] : l'anneau de focus du produit (2 points
//     d'accent), la cible tactile du mode, le clavier. L'`InkWell` interne de
//     `PopupMenuButton` ne peignait rien (0 pixel de difference mesure avec et
//     sans focus) : il est mis hors jeu (`enabled: false`) et le menu s'ouvre
//     par `showButtonMenu`, avec la meme ancre ;
//   * aucune infobulle sur le declencheur (`tooltip: ''`) : le libelle reste
//     dans la voix du lecteur d'ecran. L'infobulle de Material couvrait le
//     contenu et restait 60 a 100 ms apres le clic ;
//   * l'animation suit le budget de mouvement des feuilles ([AppMouvement]),
//     pas les 300 ms de Material ;
//   * la ligne d'une entree montre son focus par un anneau net, pas par un
//     calque d'accent a 4 % (contraste 1,06:1) ;
//   * la surface, le filet et l'ombre viennent du theme (`popupMenuTheme`,
//     [FormeFiletEtOmbre]), jamais d'ici.
//
// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
// (List-first, human-first).

import 'package:flutter/material.dart';

import '../theme/app_metriques.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Le budget de mouvement d'un menu : celui des feuilles de bas d'ecran
/// ([AppMouvement.feuilleOuverture], [AppMouvement.feuilleFermeture]).
///
/// La route d'un `PopupMenuButton` n'a qu'une duree (celle de l'ouverture,
/// reprise a la fermeture) : la sortie plus courte est portee par la courbe.
const AnimationStyle animationMenu = AnimationStyle(
  duration: AppMouvement.feuilleOuverture,
  reverseDuration: AppMouvement.feuilleFermeture,
  curve: AppMouvement.entree,
  reverseCurve: AppMouvement.sortie,
);

/// La largeur mini d'un menu (4 pas de 56, le pas de Material).
const double largeurMiniMenu = 224;

/// La largeur maxi d'un menu : au-dela, le libelle passe a la ligne.
const double largeurMaxiMenu = 320;

/// Les bornes de largeur d'un menu d'actions : assez large pour un libelle
/// d'action courant (« Admettre en Salle de verification et d'entretien »),
/// jamais tronque (il passe a la ligne).
const BoxConstraints contraintesMenu = BoxConstraints(
  minWidth: largeurMiniMenu,
  maxWidth: largeurMaxiMenu,
);

/// Le declencheur et la liste d'un menu, sur `PopupMenuButton`.
///
/// [declencheur] est ce que la personne voit et touche ; [libelle] ce que dit
/// le lecteur d'ecran. La liste est celle de [itemBuilder].
class MenuAncre<T> extends StatefulWidget {
  /// Cree l'ancre d'un menu.
  const MenuAncre({
    required this.declencheur,
    required this.libelle,
    required this.itemBuilder,
    required this.onSelected,
    this.contraintes,
    this.animation = animationMenu,
    this.arrondiFocus,
    super.key,
  });

  /// Ce qui ouvre le menu, selon l'etat d'interaction (survol, pression,
  /// focus) du [Pressable] qui le porte.
  final Widget Function(BuildContext context, EtatPression etat) declencheur;

  /// Le libelle lu par le lecteur d'ecran. **Jamais une infobulle.**
  final String libelle;

  /// Les entrees du menu.
  final PopupMenuItemBuilder<T> itemBuilder;

  /// Ce qui se passe quand une entree est choisie.
  final PopupMenuItemSelected<T> onSelected;

  /// Les bornes de la liste. `null` : celles de Material.
  final BoxConstraints? contraintes;

  /// L'animation de la liste.
  final AnimationStyle animation;

  /// L'arrondi de l'anneau de focus du declencheur.
  final BorderRadius? arrondiFocus;

  @override
  State<MenuAncre<T>> createState() => _EtatMenuAncre<T>();
}

class _EtatMenuAncre<T> extends State<MenuAncre<T>> {
  final GlobalKey<PopupMenuButtonState<T>> _cle =
      GlobalKey<PopupMenuButtonState<T>>();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Le survol et le focus d'une entree : un fond d'accent doux et opaque
    // (`washAccent`), pas le calque a 4 % du theme. Le menu capture les
    // themes de son ancre (`InheritedTheme.capture`), donc ce `Theme` suit la
    // liste jusque dans la route.
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: palette.washAccent.background,
        focusColor: palette.washAccent.background,
      ),
      child: PopupMenuButton<T>(
        key: _cle,
        // L'`InkWell` du bouton est mis hors jeu : le [Pressable] ci-dessous
        // porte le toucher, le clavier et l'anneau de focus.
        enabled: false,
        tooltip: '',
        position: PopupMenuPosition.under,
        constraints: widget.contraintes,
        popUpAnimationStyle: widget.animation,
        onSelected: widget.onSelected,
        itemBuilder: widget.itemBuilder,
        child: Pressable.selon(
          onPress: () => _cle.currentState?.showButtonMenu(),
          libelleSemantique: widget.libelle,
          arrondiFocus: widget.arrondiFocus,
          constructeur: widget.declencheur,
        ),
      ),
    );
  }
}

/// La ligne d'une entree de menu : sa hauteur est la cible tactile du mode,
/// son contenu est [child], et **son focus au clavier se voit** (anneau de
/// 2 points d'accent, arrondi des pastilles).
///
/// A poser dans un `PopupMenuItem` dont le `padding` est nul : la ligne porte
/// elle-meme ses marges, pour que l'anneau entoure toute la ligne et pas
/// seulement le texte.
class LigneEntreeMenu extends StatelessWidget {
  /// Cree la ligne.
  const LigneEntreeMenu({required this.child, super.key});

  /// Le contenu de la ligne.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // `Focus.maybeOf` avec dependance : la ligne se redessine quand le noeud
    // de focus de son `InkWell` (celui du `PopupMenuItem`) change. Le
    // marqueur ne se montre qu'en navigation au clavier : un menu ouvert au
    // doigt ne porte aucun anneau.
    final bool focus =
        (Focus.maybeOf(context)?.hasFocus ?? false) &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.arrondiXs,
          border: focus
              ? Border.fromBorderSide(
                  palette.inkAccent.asBorderSide(
                    width: Pressable.epaisseurFocus,
                  ),
                )
              : null,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                AppMetriques.of(context).cibleTactile - 2 * AppSpacing.xs,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(children: <Widget>[Expanded(child: child)]),
          ),
        ),
      ),
    );
  }
}

/// Le trait fin entre deux groupes d'entrees d'un menu.
///
/// Peint avec le filet de contour des surfaces (`contourCarte`), qui reste
/// visible en sombre ; `PopupMenuDivider` prenait la couleur du `Divider` du
/// theme (le filet le plus faible, invisible sur une surface sombre).
class SeparateurMenu<T> extends PopupMenuEntry<T> {
  /// Cree le trait.
  const SeparateurMenu({super.key});

  @override
  double get height => AppSpacing.md;

  @override
  bool represents(T? value) => false;

  @override
  State<SeparateurMenu<T>> createState() => _EtatSeparateurMenu<T>();
}

class _EtatSeparateurMenu<T> extends State<SeparateurMenu<T>> {
  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderSide filet = palette.contourCarte.asBorderSide();
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // La largeur de la liste, jamais une largeur propre : un trait
          // sans largeur naturelle ne pese pas sur la mesure de la liste.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: filet)),
              child: SizedBox(height: filet.width),
            ),
          ],
        ),
      ),
    );
  }
}
