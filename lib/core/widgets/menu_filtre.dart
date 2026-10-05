import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_elevation.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Une valeur proposee par un [MenuFiltre].
@immutable
class EntreeFiltre<T> {
  /// Cree une entree.
  const EntreeFiltre({
    required this.valeur,
    required this.libelle,
    this.compteur,
  });

  /// La valeur retenue. **Nulle pour l'entree « tous »**, qui relache le
  /// filtre.
  final T? valeur;

  /// Le libelle lisible.
  final String libelle;

  /// Combien d'elements portent cette valeur. Rendu a cote du libelle : c'est
  /// lui qui dit ou regarder.
  final int? compteur;
}

/// Un axe de filtre **ouvert**, rendu en menu et non en pastilles.
///
/// **Pourquoi ce composant existe**, et ce qu'il remplace : `ADM-04` rendait
/// une pastille par type d'evenement et une par acteur, `ADM-08` une par etat
/// et une par role. Le vocabulaire d'evenements vit en base et grandit a
/// chaque migration, la liste des acteurs grandit avec l'academie : le journal
/// portait donc une vingtaine de boutons qui repoussaient la liste sous le
/// pli, et l'operateur l'a dit sans detour le 18 septembre 2026.
///
/// La regle qui en sort, et qui vaut pour tout ecran d'administration :
///
///   * **un axe ferme se rend en pastilles** -- la periode a trois valeurs, un
///     etat de compte en a quatre : ce sont de vrais selecteurs, tout se voit
///     d'un coup d'oeil et un tap suffit ;
///   * **un axe ouvert se rend en menu** -- une liste qui grandit avec les
///     donnees ne peut pas s'etaler, sinon l'accent finit par decorer un
///     inventaire au lieu de porter la selection (registre produit : « accent
///     color used for primary actions, current selection, and state
///     indicators only, not decoration »).
///
/// `PopupMenuButton` et non `DropdownMenu` : un `DropdownMenu` est un champ de
/// saisie, et un filtre n'est pas une saisie. Le bouton porte la selection
/// courante, ce qui evite d'avoir a ouvrir le menu pour savoir ou l'on en est.
class MenuFiltre<T> extends StatelessWidget {
  /// Cree un menu de filtre.
  const MenuFiltre({
    required this.libelle,
    required this.valeur,
    required this.entrees,
    required this.onChoix,
    super.key,
    this.selecteurDeSection = false,
  });

  /// Vrai : le menu ne filtre pas, il **dit ou l'on est** parmi des sections
  /// (`SelecteurSection`, au-dela de quatre sections sur telephone). Le bouton
  /// prend toute la largeur, reste neutre (une section n'est pas un filtre
  /// retenu) et la section courante porte une coche dans la liste : la
  /// selection ne repose pas sur la seule position.
  final bool selecteurDeSection;

  /// Le nom de l'axe : « Événement », « Acteur », « Rôle ».
  final String libelle;

  /// La valeur courante. Nulle quand le filtre est relache.
  final T? valeur;

  /// Les valeurs proposees, l'entree « tous » comprise.
  final List<EntreeFiltre<T>> entrees;

  /// Ce qui se passe quand une valeur est choisie.
  final void Function(T? valeur) onChoix;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool actif = valeur != null && !selecteurDeSection;

    final EntreeFiltre<T>? retenue = entrees
        .where((EntreeFiltre<T> e) => e.valeur == valeur)
        .firstOrNull;

    // Le bouton dit l'axe quand rien n'est filtre, et la valeur retenue
    // sinon : sans cela il faudrait ouvrir le menu pour savoir ou l'on en est.
    final String texte = (actif || selecteurDeSection) && retenue != null
        ? retenue.libelle
        : libelle;

    // Le selecteur de section mesure sa largeur pour y caler sa liste ; un
    // filtre n'en a pas besoin (et reste mesurable par un parent
    // `IntrinsicWidth`, qu'un `LayoutBuilder` ne sait pas renseigner).
    if (!selecteurDeSection) {
      return _bouton(context, palette, textes, actif, texte, null);
    }
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) =>
          _bouton(contexte, palette, textes, actif, texte, contraintes),
    );
  }

  Widget _bouton(
    BuildContext context,
    AppPalette palette,
    TextTheme textes,
    bool actif,
    String texte,
    BoxConstraints? contraintes,
  ) {
    // ONGLETS-COUPE-1 : le selecteur de section ouvre une liste de la largeur
    // de son declencheur, alignee sur lui ; un filtre garde la largeur
    // naturelle de Material.
    final double? largeurListe =
        contraintes != null && contraintes.maxWidth.isFinite
        ? contraintes.maxWidth
        : null;
    return PopupMenuButton<_Choix<T>>(
      tooltip: libelle,
      position: PopupMenuPosition.under,
      constraints: largeurListe == null
          ? null
          : BoxConstraints.tightFor(width: largeurListe),
      // ONGLETS-COUPE-1 : l'elevation de Material est remplacee par le filet
      // et l'ombre des jetons (niveau 2 en clair, aucune en sombre, comme une
      // boite de dialogue). L'ombre Material, noire, se dessinait en sombre
      // et, sous `flutter test`, en un trait noir de 6 px qui debordait de
      // 3 px a gauche du declencheur.
      elevation: 0,
      shape: _FiletEtOmbre(
        filet: palette.borderHairline.asBorderSide(),
        ombres: AppElevation.dialogue(palette),
        arrondi: AppRadius.arrondiSm,
      ),
      onSelected: (_Choix<T> choix) => onChoix(choix.valeur),
      itemBuilder: (BuildContext _) => <PopupMenuEntry<_Choix<T>>>[
        for (final EntreeFiltre<T> entree in entrees)
          PopupMenuItem<_Choix<T>>(
            // Enveloppee : `PopupMenuButton` ignore une valeur nulle et
            // n'appellerait jamais `onSelected` sur l'entree « tous ».
            value: _Choix<T>(entree.valeur),
            child: Row(
              children: <Widget>[
                // Jamais coupe dans un mot (« Fonctionnalite / s » a 320 px,
                // texte x2) : il passe a la ligne entre les mots, et un mot
                // trop long se reduit (ONGLETS-COUPE-1).
                Expanded(child: TexteSansCoupure(entree.libelle)),
                if (selecteurDeSection && entree.valeur == valeur) ...<Widget>[
                  Ecart.hMd,
                  Icon(
                    AppIcons.succes.actif,
                    size: AppSpacing.lg,
                    color: palette.inkAccent.asIconTheme().color,
                  ),
                ],
                if (entree.compteur != null) ...<Widget>[
                  Ecart.hMd,
                  Text(
                    '${entree.compteur}',
                    style: palette.inkMuted.applyTo(
                      // Chiffres tabulaires : une colonne de comptes ne doit
                      // pas danser d'une ligne a l'autre.
                      (textes.bodySmall ?? const TextStyle()).copyWith(
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: actif || selecteurDeSection ? '$libelle : $texte' : libelle,
        child: Container(
          constraints: BoxConstraints(
            minHeight: AppMetriques.of(context).cibleTactile,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: actif
                ? palette.washAccent.background
                : palette.surfaceRaised.background,
            // Le meme arrondi que `FilterPill` : les deux affordances de
            // filtre se lisent comme une seule famille.
            borderRadius: AppRadius.arrondiFull,
            border: Border.fromBorderSide(
              actif || selecteurDeSection
                  ? palette.borderStrong.asBorderSide()
                  : palette.borderHairline.asBorderSide(),
            ),
          ),
          // K-54 : libelle et chevron centres dans le bouton, y compris quand
          // le parent l'etire. Selecteur de section (ONGLETS-1) : le nom au
          // debut, le chevron au bout, sur toute la largeur.
          child: Center(
            widthFactor: selecteurDeSection ? null : 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: selecteurDeSection
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: selecteurDeSection
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: selecteurDeSection
                      // Un nom de section n'est jamais tronque ni coupe dans
                      // un mot : il passe a la ligne entre les mots, et un
                      // mot trop long se reduit (texte x2, 320 px,
                      // ONGLETS-COUPE-1).
                      ? TexteSansCoupure(
                          texte,
                          textAlign: TextAlign.start,
                          style: palette.inkStrong.applyTo(
                            textes.labelLarge ?? const TextStyle(),
                          ),
                        )
                      : Text(
                          texte,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: (actif ? palette.inkAccent : palette.inkStrong)
                              .applyTo(textes.labelLarge ?? const TextStyle()),
                        ),
                ),
                Ecart.hXs,
                Icon(
                  // Vers le bas, la ou le menu s'ouvre. Un chevron vers la
                  // droite promettrait de mener ailleurs.
                  AppIcons.menuDeroulant.repos,
                  size: AppSpacing.lg,
                  color: (actif ? palette.inkAccent : palette.inkMuted)
                      .asIconTheme()
                      .color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L'enveloppe d'une valeur de menu.
///
/// `PopupMenuButton` traite une valeur nulle comme « aucune valeur » et
/// n'appelle alors jamais `onSelected` : l'entree « tous » ne relacherait
/// jamais le filtre. L'envelopper rend la valeur nulle selectionnable.
@immutable
class _Choix<T> {
  const _Choix(this.valeur);

  final T? valeur;
}

/// Le contour de la liste d'un [MenuFiltre] : un filet et les ombres des
/// jetons ([AppElevation]), a la place de l'elevation de Material.
///
/// Les ombres sont peintes **hors** de la forme (la liste reste nette), puis
/// le filet par-dessus le bord. « Une surface elevee porte un filet ET une
/// ombre » ([AppElevation]) ; en sombre, la liste se detache par sa surface et
/// son filet ([AppElevation.dialogue]).
class _FiletEtOmbre extends ShapeBorder {
  const _FiletEtOmbre({
    required this.filet,
    required this.ombres,
    required this.arrondi,
  });

  final BorderSide filet;
  final List<BoxShadow> ombres;
  final BorderRadius arrondi;

  RRect _forme(Rect rect, TextDirection? sens) =>
      arrondi.resolve(sens).toRRect(rect);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(filet.strokeInset);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_forme(rect, textDirection).deflate(filet.strokeInset));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_forme(rect, textDirection));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final RRect forme = _forme(rect, textDirection);
    if (ombres.isNotEmpty) {
      canvas
        ..save()
        ..clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect.inflate(rect.shortestSide + rect.longestSide)),
            Path()..addRRect(forme),
          ),
        );
      for (final BoxShadow ombre in ombres) {
        canvas.drawRRect(
          forme.shift(ombre.offset).inflate(ombre.spreadRadius),
          ombre.toPaint(),
        );
      }
      canvas.restore();
    }
    canvas.drawRRect(forme.deflate(filet.strokeInset), filet.toPaint());
  }

  @override
  ShapeBorder scale(double t) => _FiletEtOmbre(
    filet: filet.scale(t),
    ombres: <BoxShadow>[for (final BoxShadow o in ombres) o.scale(t)],
    arrondi: arrondi * t,
  );

  @override
  bool operator ==(Object other) =>
      other is _FiletEtOmbre &&
      other.filet == filet &&
      other.arrondi == arrondi &&
      _memesOmbres(other.ombres, ombres);

  @override
  int get hashCode => Object.hash(filet, arrondi, Object.hashAll(ombres));
}

bool _memesOmbres(List<BoxShadow> a, List<BoxShadow> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
