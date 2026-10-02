import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Un segment de [ControleSegmente].
@immutable
class Segment<T> {
  /// Cree un segment.
  const Segment({required this.valeur, required this.libelle, this.icone});

  /// Une icone posee au-dessus du libelle (soleil, lune) : elle ne remplace
  /// jamais le libelle, l'etat ne repose pas sur le seul pictogramme.
  final AppIcon? icone;

  /// La valeur que le segment selectionne.
  final T valeur;

  /// Le libelle visible, deux mots au plus : « Seances », « Observations ».
  final String libelle;
}

/// Un controle segmente : deux a quatre vues exclusives d'une meme liste,
/// « Seances / Observations » dans l'Historique du tuteur et de
/// l'administration (maquette V8 D2, manifeste visuel Tuteur V1 section 3.4).
///
/// Piste `surfaceSunken` en pilule, segment actif sur `washAccent`, **renforce
/// d'un filet d'accent** : la selection ne repose jamais sur la seule couleur
/// de fond. (Pas de graisse ajoutee : Plus Jakarta Sans se pilote par l'axe
/// `wght`, et un `fontWeight` seul synthetiserait un faux gras.) Chaque segment est un bouton de 48 de haut au moins,
/// annonce « selectionne » au lecteur d'ecran, et partage la largeur a egalite
/// ; a 200 %, un libelle passe a la ligne au lieu d'etre coupe.
///
/// Ce n'est pas une navigation : le controle rend la main par [onChange], et
/// c'est l'ecran qui decide si le choix change une route (Historique :
/// `/tuteur/suivi` et `/tuteur/suivi/observations`).
class ControleSegmente<T> extends StatelessWidget {
  /// Cree un controle.
  const ControleSegmente({
    required this.segments,
    required this.valeur,
    required this.onChange,
    super.key,
    this.rectangle = false,
  });

  /// Vrai : un petit rectangle a coins arrondis (`AppRadius.md`) au lieu de la
  /// pilule, pour les segments qui portent une icone au-dessus du libelle
  /// (choix du theme, THEME-SW-1). Le segment actif prend le rayon `sm`, plus
  /// petit que celui de la piste.
  final bool rectangle;

  /// Les segments, dans l'ordre de lecture : deux a quatre. Un seul segment
  /// n'est pas un choix, et au-dela de quatre les libelles ne tiennent plus
  /// cote a cote sur un telephone.
  final List<Segment<T>> segments;

  /// La valeur selectionnee.
  final T valeur;

  /// Rappele avec la valeur d'un segment non selectionne qu'on presse.
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: palette.surfaceSunken.decoration(
        borderRadius: rectangle ? AppRadius.arrondiMd : AppRadius.arrondiFull,
      ),
      // Hauteur intrinseque : les segments prennent tous la hauteur du plus
      // haut (un libelle qui passe a la ligne a 200 %), sans exiger du parent
      // une hauteur bornee. Deux a quatre segments : le cout est negligeable.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final Segment<T> segment in segments)
              Expanded(
                child: _Segment<T>(
                  segment: segment,
                  selectionne: segment.valeur == valeur,
                  onChange: onChange,
                  arrondi: rectangle
                      ? AppRadius.arrondiSm
                      : AppRadius.arrondiFull,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selectionne,
    required this.onChange,
    required this.arrondi,
  });

  final Segment<T> segment;
  final bool selectionne;
  final ValueChanged<T> onChange;
  final BorderRadius arrondi;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();

    // Le segment deja choisi reste un bouton actif (sinon il serait annonce
    // « desactive ») ; le presser ne fait rien.
    return Semantics(
      selected: selectionne,
      inMutuallyExclusiveGroup: true,
      child: Pressable.selon(
        onPress: () {
          if (!selectionne) {
            onChange(segment.valeur);
          }
        },
        arrondiFocus: arrondi,
        constructeur: (BuildContext contexte, EtatPression etat) => Padding(
          // La cible fait toute la hauteur de la piste ; la pastille active
          // est posee dedans, a 4 du bord.
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: DecoratedBox(
            decoration: selectionne
                ? palette.washAccent.decoration(
                    borderRadius: arrondi,
                    side: palette.inkAccent.asBorderSide(),
                  )
                : BoxDecoration(
                    borderRadius: arrondi,
                    color: etat.survole || etat.presse
                        ? palette.calqueInteraction(presse: etat.presse)
                        : null,
                  ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (segment.icone != null) ...<Widget>[
                      ExcludeSemantics(
                        child: Icon(
                          selectionne
                              ? segment.icone!.actif
                              : segment.icone!.repos,
                          size: AppSpacing.xl,
                          color: selectionne
                              ? palette.washAccent.applyTo(base).color
                              : palette.inkMuted.applyTo(base).color,
                        ),
                      ),
                      Ecart.vXs,
                    ],
                    Text(
                      segment.libelle,
                      textAlign: TextAlign.center,
                      style: selectionne
                          ? palette.washAccent.applyTo(base)
                          : palette.inkMuted.applyTo(base),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
