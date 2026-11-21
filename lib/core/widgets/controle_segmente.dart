import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Un segment de [ControleSegmente].
@immutable
class Segment<T> {
  /// Cree un segment.
  const Segment({
    required this.valeur,
    required this.libelle,
    this.icone,
    this.apercu,
    this.libelleCourt,
  });

  /// PERSONNES-UNE-PAGE (pilote, 21/11/2026) : un mot court (« Equipe » pour
  /// « Direction et equipe (3) ») pose sous l'icone quand le libelle entier
  /// ne tient pas : deux icones voisines ne se distinguent jamais par le seul
  /// dessin. Le libelle entier reste lu par le lecteur d'ecran. `null` par
  /// defaut : rien ne change ailleurs.
  final String? libelleCourt;

  /// Une icone posee au-dessus du libelle (soleil, lune) : elle ne remplace
  /// jamais le libelle, l'etat ne repose pas sur le seul pictogramme.
  final AppIcon? icone;

  /// TB-7b : un apercu peint de la valeur, a la place de l'icone (pastille
  /// d'une couleur d'encre, trait d'une epaisseur). Comme l'icone, il ne
  /// remplace jamais le libelle ; il est muet pour le lecteur d'ecran.
  final Widget? apercu;

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
    this.dense = false,
    this.iconesSeules = false,
    this.motsCourts = false,
  });

  /// Avec [iconesSeules] : le [Segment.libelleCourt] de chaque segment est
  /// pose sous son icone (le libelle entier reste lu). L'appelant ne le
  /// demande que si ces mots tiennent ([largeurMotCourt]). Faux par defaut.
  final bool motsCourts;

  /// La marge laterale d'un segment en mots courts, des deux cotes : 4 de
  /// piste et 4 de marge interieure.
  static const double margeMotCourt = 2 * (AppSpacing.xs + AppSpacing.xs);

  /// Le style d'un mot court : plus petit que le libelle d'un onglet.
  /// La reduction qu'un mot court accepte pour tenir : un dixieme au plus.
  static const double reductionMotCourt = 0.9;

  static TextStyle styleMotCourt(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();

  /// PERSONNES-UNE-PAGE (b) (directeur, 20/11/2026 : des icones sur les
  /// onglets, « pour etre plus reconnaissable ») : quand les mots ne tiennent
  /// pas, un segment **qui porte une icone** la montre seule ; son nom reste
  /// dit au lecteur d'ecran et en infobulle. Un segment sans icone garde son
  /// mot. Faux par defaut : rien ne change ailleurs.
  final bool iconesSeules;

  /// Vrai : un petit rectangle a coins arrondis (`AppRadius.md`) au lieu de la
  /// pilule, pour les segments qui portent une icone au-dessus du libelle
  /// (choix du theme, THEME-SW-1). Le segment actif prend le rayon `sm`, plus
  /// petit que celui de la piste.
  final bool rectangle;

  /// Densite visuelle (CONNEXION-ALIGN, decision du pilote du 04/11/2026) :
  /// la piste visible fait 40 de haut et la pastille active 32, centrees dans
  /// la zone tactile de 48, qui ne change pas. Faux par defaut : rien ne
  /// change ailleurs.
  final bool dense;

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

    final BoxDecoration piste = palette.surfaceSunken.decoration(
      borderRadius: rectangle ? AppRadius.arrondiMd : AppRadius.arrondiFull,
    );
    // Hauteur intrinseque : les segments prennent tous la hauteur du plus
    // haut (un libelle qui passe a la ligne a 200 %), sans exiger du parent
    // une hauteur bornee. Deux a quatre segments : le cout est negligeable.
    final Widget rangee = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Segment<T> segment in segments)
            Expanded(
              child: _Segment<T>(
                segment: segment,
                voisins: <String>[
                  for (final Segment<T> s in segments)
                    if (!identical(s, segment)) s.libelle,
                ],
                selectionne: segment.valeur == valeur,
                onChange: onChange,
                arrondi: rectangle
                    ? AppRadius.arrondiSm
                    : AppRadius.arrondiFull,
                dense: dense,
                iconeSeule: iconesSeules && segment.icone != null,
                motCourt: iconesSeules && motsCourts && segment.icone != null
                    ? segment.libelleCourt
                    : null,
              ),
            ),
        ],
      ),
    );
    if (!dense) {
      return DecoratedBox(decoration: piste, child: rangee);
    }
    // La piste est peinte 4 en retrait de la zone tactile, en haut et en bas.
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: DecoratedBox(decoration: piste),
          ),
        ),
        rangee,
      ],
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.voisins,
    required this.selectionne,
    required this.onChange,
    required this.arrondi,
    required this.dense,
    this.iconeSeule = false,
    this.motCourt,
  });

  /// L'icone sans le mot ; le mot reste lu et en infobulle.
  final bool iconeSeule;

  /// Le mot court pose sous l'icone, ou `null` (l'icone seule).
  final String? motCourt;

  final Segment<T> segment;

  /// Les libelles des autres segments.
  final List<String> voisins;
  final bool selectionne;
  final ValueChanged<T> onChange;
  final BorderRadius arrondi;
  final bool dense;

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
          // Dense : 4 de piste et 4 de marge, la pastille fait 48 - 16 = 32.
          padding: dense
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                )
              : const EdgeInsets.all(AppSpacing.xs),
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
                // THEME-SW-1 : marge laterale de 8 (et non 12) ; le libelle
                // reduit au besoin son echelle (jamais sous 0,85) au lieu
                // d'etre coupe, sans toucher le contour de la pastille
                // (relecture COUPE-MOTS-1 : a 4, « Systeme » le touchait).
                padding: EdgeInsets.symmetric(
                  horizontal: motCourt == null ? AppSpacing.sm : AppSpacing.xs,
                  vertical: dense ? 0 : AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (segment.apercu case final Widget apercu) ...<Widget>[
                      ExcludeSemantics(child: apercu),
                      Ecart.vXs,
                    ] else if (segment.icone != null) ...<Widget>[
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
                      if (!iconeSeule || motCourt != null) Ecart.vXs,
                    ],
                    if (motCourt case final String court)
                      // Le mot court se voit, le libelle entier se lit.
                      Semantics(
                        label: segment.libelle,
                        child: ExcludeSemantics(
                          // Une ligne ; reduit d'un dixieme au plus (l'appelant
                          // ne demande les mots que s'ils tiennent ainsi).
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              court,
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: selectionne
                                  ? palette.washAccent.applyTo(
                                      ControleSegmente.styleMotCourt(contexte),
                                    )
                                  : palette.inkMuted.applyTo(
                                      ControleSegmente.styleMotCourt(contexte),
                                    ),
                            ),
                          ),
                        ),
                      )
                    else if (iconeSeule)
                      // Le nom, pour le lecteur d'ecran et au survol.
                      Tooltip(
                        message: segment.libelle,
                        child: Semantics(
                          label: segment.libelle,
                          child: const SizedBox.shrink(),
                        ),
                      )
                    else
                      // COUPE-MOTS-1 point 6 : les segments ont la meme
                      // largeur ; l'echelle est bornee par le mot le plus long
                      // de TOUS, pour que les voisins gardent la meme taille.
                      TexteSansCoupure(
                        segment.libelle,
                        voisins: voisins,
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
