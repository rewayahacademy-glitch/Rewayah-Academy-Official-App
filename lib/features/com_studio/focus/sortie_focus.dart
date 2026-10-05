// Le Studio, Mode focus : la sortie (`FocusExitDock`, COM-STU-3 ; spec
// section 10.4, section 10.5, section 10.6, section 22 « Focus », section 23
// « Focus », section 24, R-COM-09, R-COM-10).
//
// Deux pieces :
//
// - [BandeauSortieFocus] (`FocusExitDock`) : la seule chose posee au-dessus
//   du canal en Focus. L'identite minimale « Le Studio », l'indicateur
//   discret « Focus active » (texte, jamais une couleur seule) et l'action
//   « Quitter le focus », visible et lue par le lecteur d'ecran sur tous les
//   gabarits. Sur ordinateur et tablette, l'indicateur rappelle la touche
//   Echap.
// - [GardeSortieFocus] : les deux autres sorties. Echap (si aucun dialogue
//   prioritaire n'est ouvert) et le retour explicite du telephone (geste ou
//   touche retour) quittent le Focus au lieu de quitter la page.
//
// Echap n'est pris que s'il n'est pas deja consomme : une feuille, un
// dialogue ou un menu ouvert par-dessus le recoit d'abord et se ferme, le
// Focus reste. Le focus clavier n'est jamais piege : la garde n'ajoute
// aucune portee de focus et ne prend jamais le focus elle-meme.
//
// Avec la reduction de mouvement, rien ne bouge : le bandeau apparait tel
// quel (`ApparitionDouce` neutralisee), et la disposition change d'un coup.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/mouvement/apparition_douce.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import 'bascule_focus.dart';

/// Le bandeau de sortie du Focus (`FocusExitDock`).
class BandeauSortieFocus extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauSortieFocus({super.key});

  /// La cle du bandeau, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('studio-focus-bandeau');

  /// La cle de l'indicateur « Focus active », pour les tests.
  static const ValueKey<String> cleIndicateur = ValueKey<String>(
    'studio-focus-indicateur',
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.com.studio.focus;
    // Le clavier physique est l'usage de l'ordinateur et de la tablette : le
    // telephone sort par le bouton ou le retour.
    final bool rappelEchap = AppGabarit.de(context) != Gabarit.mobile;
    // Un groupe a part pour le lecteur d'ecran : l'etat et « Quitter le
    // focus » restent deux noeuds distincts, jamais fondus dans la page
    // (COM-RC : la saisie du fil defile desormais dans sa propre zone).
    return ApparitionDouce(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Wrap(
          key: cle,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    t.com.studio.titre,
                    style: palette.inkStrong.applyTo(
                      textes.titleSmall ?? const TextStyle(),
                    ),
                  ),
                ),
                Ecart.vXs,
                // L'etat est dit en mots, et annonce une fois a l'entree.
                Semantics(
                  liveRegion: true,
                  child: Text(
                    rappelEchap ? f.actifAvecEchap : f.actif,
                    key: cleIndicateur,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                ),
              ],
            ),
            const BasculeFocus(),
          ],
        ),
      ),
    );
  }
}

/// Echap et le retour du telephone quittent le Focus, quand il est actif.
class GardeSortieFocus extends StatefulWidget {
  /// Cree la garde autour de [child].
  const GardeSortieFocus({
    required this.actif,
    required this.onQuitter,
    required this.child,
    super.key,
  });

  /// Le Focus est-il actif ? Sinon, la garde ne fait rien.
  final bool actif;

  /// Quitte le Focus (avec restauration).
  final VoidCallback onQuitter;

  /// La coquille du Studio.
  final Widget child;

  @override
  State<GardeSortieFocus> createState() => _GardeSortieFocusState();
}

class _GardeSortieFocusState extends State<GardeSortieFocus> {
  /// Le noeud de la garde : jamais focalisable, il recoit seulement les
  /// touches que ses descendants n'ont pas consommees.
  final FocusNode _noeud = FocusNode(
    debugLabel: 'studio-garde-focus',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_toucheSansFocus);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_toucheSansFocus);
    _noeud.dispose();
    super.dispose();
  }

  static bool _estEchap(KeyEvent e) =>
      e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape;

  /// Aucun dialogue, aucune feuille, aucun menu n'est ouvert par-dessus la
  /// page (un tel calque est une route au-dessus de la sienne).
  bool _aucunDialoguePrioritaire() {
    if (!mounted) return false;
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  /// Echap venu d'un descendant (le champ, un bouton du fil) et laisse
  /// passer par lui.
  KeyEventResult _touche(FocusNode _, KeyEvent evenement) {
    if (!widget.actif || !_estEchap(evenement)) {
      return KeyEventResult.ignored;
    }
    if (!_aucunDialoguePrioritaire()) return KeyEventResult.ignored;
    widget.onQuitter();
    return KeyEventResult.handled;
  }

  /// Echap quand aucun element de la page n'a le focus clavier (apres un
  /// clic sur le fond, le focus remonte a la portee de la page, au-dessus de
  /// la garde) : sans ce relais, Echap ne ferait rien.
  bool _toucheSansFocus(KeyEvent evenement) {
    if (!mounted || !widget.actif || !_estEchap(evenement)) return false;
    final FocusNode? primaire = FocusManager.instance.primaryFocus;
    // Un descendant a le focus : la garde le recoit par le chemin normal.
    if (primaire != null &&
        (primaire == _noeud || primaire.ancestors.contains(_noeud))) {
      return false;
    }
    // Le focus est ailleurs que sur la portee de la page (un dialogue, une
    // autre route) : ce n'est pas pour nous.
    if (primaire != null && !_noeud.ancestors.contains(primaire)) {
      return false;
    }
    if (!_aucunDialoguePrioritaire()) return false;
    widget.onQuitter();
    return true;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // Le retour explicite du telephone quitte le Focus, pas la page.
    canPop: !widget.actif,
    onPopInvokedWithResult: (bool sorti, Object? _) {
      if (!sorti && widget.actif) widget.onQuitter();
    },
    child: Focus(
      focusNode: _noeud,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _touche,
      child: widget.child,
    ),
  );
}
