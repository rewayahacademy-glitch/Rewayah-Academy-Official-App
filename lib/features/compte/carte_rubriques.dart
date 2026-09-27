import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/pressable.dart';

// Composants du Compte du tuteur (lot E, chantier Tuteur V1).
//
// **Pourquoi ce fichier existe.** Les cartes de « Mon compte » (maquettes V3,
// `mon compte tuteur ... .png`) portent leur en-tete DANS le rectangle :
// medaillon, titre, resume, pastille a droite, puis les rubriques a filets.
// Le composant partage `GroupeReglages` pose son titre AU-DESSUS de la
// surface, sans medaillon ni resume : il ne peut pas rendre ces cartes sans
// un ecart de placement. `lib/core/widgets/` appartient au coordinateur ;
// la demande de l'etendre (`entete`, `corps`) est deposee dans
// `pilotage-tuteur-v1/demandes/E.md`. En attendant, et comme le prevoit la
// regle d'ownership (« un composant utilise par un seul lot vit dans le
// dossier de ce lot »), la carte vit ici, **sur le meme modele de donnees**
// (`LigneRubrique`) et les memes jetons que `GroupeReglages`, pour que sa
// promotion ne change rien a l'ecran.

/// Une carte de rubriques du Compte : UN seul rectangle, en-tete a medaillon,
/// corps facultatif, puis des rubriques separees par un filet fin en retrait
/// (decision du directeur, 24/09 : « carte groupee = un seul rectangle »).
class CarteRubriques extends StatelessWidget {
  /// Cree une carte.
  const CarteRubriques({
    required this.icone,
    required this.titre,
    super.key,
    this.resume = const <String>[],
    this.fin,
    this.corps,
    this.lignes = const <LigneRubrique>[],
  });

  /// L'icone du medaillon, rendue pleine.
  final AppIcon icone;

  /// Le titre de la carte, annonce comme en-tete.
  final String titre;

  /// Des lignes de resume sous le titre, en encre attenuee.
  final List<String> resume;

  /// Un element a droite de l'en-tete : une pastille d'etat, par exemple.
  final Widget? fin;

  /// Un contenu sous l'en-tete, aligne sur le titre (les avatars du foyer).
  final Widget? corps;

  /// Les rubriques, dans l'ordre d'affichage.
  final List<LigneRubrique> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Un filet separe l'en-tete de la premiere rubrique seulement quand
    // l'en-tete porte un resume ou un corps (maquettes V3 : pas de filet sous
    // « Securite et connexion », un filet sous le resume des informations).
    final bool filetSousEntete = resume.isNotEmpty || corps != null;

    return SurfaceCarte(
      child: LayoutBuilder(
        builder: (BuildContext _, BoxConstraints contraintes) {
          // La pastille se tient a droite du titre quand la carte a la place
          // de la maquette ; sur un telephone reel (la maquette est dessinee
          // environ 1,4 fois plus dense), elle passe sous le resume plutot que
          // de couper le titre en deux lignes.
          final bool finADroite =
              contraintes.maxWidth >= _largeurPastilleADroite;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  lignes.isEmpty ? AppSpacing.lg : AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Medaillon(icone: icone),
                    Ecart.hMd,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Semantics(
                              header: true,
                              child: Text(
                                titre,
                                style: palette.inkStrong.applyTo(
                                  textes.titleMedium ?? const TextStyle(),
                                ),
                              ),
                            ),
                            for (final String ligne in resume) ...<Widget>[
                              Ecart.vXs,
                              Text(
                                ligne,
                                style: palette.inkMuted.applyTo(
                                  textes.bodyMedium ?? const TextStyle(),
                                ),
                              ),
                            ],
                            if (fin != null && !finADroite) ...<Widget>[
                              Ecart.vSm,
                              fin!,
                            ],
                            if (corps != null) ...<Widget>[Ecart.vSm, corps!],
                          ],
                        ),
                      ),
                    ),
                    if (fin != null && finADroite) ...<Widget>[Ecart.hSm, fin!],
                  ],
                ),
              ),
              for (int i = 0; i < lignes.length; i++)
                _Rubrique(ligne: lignes[i], filet: i > 0 || filetSousEntete),
              if (lignes.isNotEmpty) Ecart.vSm,
            ],
          );
        },
      ),
    );
  }

  /// La largeur de carte a partir de laquelle la pastille tient a droite du
  /// titre sans le couper.
  static const double _largeurPastilleADroite = AppPage.largeurDialogue;
}

/// La surface commune des cartes du Compte : `surfaceRaised`, filet de carte,
/// rayon `md`, sans ombre (maquettes V3). Memes jetons que `GroupeReglages`.
class SurfaceCarte extends StatelessWidget {
  /// Cree la surface.
  const SurfaceCarte({required this.child, super.key});

  /// Le contenu.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Le filet est repeint AU PREMIER PLAN : le fond d'une rubrique (survol,
    // pression) court d'un bord a l'autre et recouvrait sinon le filet
    // lateral de la carte (planche sombre du 24/09).
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppRadius.arrondiMd,
        border: Border.fromBorderSide(palette.contourCarte.asBorderSide()),
      ),
      child: DecoratedBox(
        decoration: AppElevation.avecFilet(
          surface: palette.surfaceRaised,
          filet: palette.contourCarte,
          ombre: palette.ombre,
          arrondi: AppRadius.arrondiMd,
        ),
        child: ClipRRect(borderRadius: AppRadius.arrondiMd, child: child),
      ),
    );
  }
}

/// Le medaillon d'une carte : cercle de 48 `washAccent`, anneau d'accent de
/// 1, icone pleine d'accent (manifeste visuel section 3.4).
class Medaillon extends StatelessWidget {
  /// Cree le medaillon.
  const Medaillon({required this.icone, super.key});

  /// L'icone, rendue dans sa forme pleine.
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppTouchTarget.standard,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.washAccent.background,
            border: Border.fromBorderSide(palette.inkAccent.asBorderSide()),
          ),
          child: Center(
            child: IconTheme(
              data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
              child: Icon(icone.actif),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une rubrique de carte : icone d'accent, libelle, legende ou valeur,
/// chevron quand elle mene ailleurs. Le filet est pose AU-DESSUS de la
/// rubrique, en retrait des deux cotes (maquettes V3 : il court sous l'icone).
class _Rubrique extends StatelessWidget {
  const _Rubrique({required this.ligne, required this.filet});

  final LigneRubrique ligne;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    if (ligne.controle != null || ligne.onPress == null) {
      return MergeSemantics(child: _contenu(context, const EtatPression()));
    }
    return Pressable.selon(
      onPress: ligne.onPress,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: _contenu,
    );
  }

  Widget _contenu(BuildContext context, EtatPression etat) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Color fond = etat.survole || etat.presse
        ? Color.alphaBlend(
            palette.calqueInteraction(presse: etat.presse),
            palette.surfaceRaised.background,
          )
        : palette.surfaceRaised.background;
    final TextStyle styleSecondaire = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    return ColoredBox(
      color: fond,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: filet
                ? Border(top: palette.contourCarte.asBorderSide())
                : null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTouchTarget.standard,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  ExcludeSemantics(
                    child:
                        ligne.meneur ??
                        SizedBox(
                          width: AppTouchTarget.standard,
                          child: IconTheme(
                            data: palette.inkAccent.asIconTheme(
                              size: AppSpacing.xxl,
                            ),
                            child: Icon(ligne.icone?.repos),
                          ),
                        ),
                  ),
                  Ecart.hMd,
                  Expanded(
                    // `stretch` donne au `Wrap` toute la largeur : la valeur
                    // se cale alors a droite, contre le chevron (maquette),
                    // et passe dessous quand le texte est agrandi.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          alignment: WrapAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              ligne.libelle,
                              style: palette.inkStrong.applyTo(
                                textes.bodyLarge ?? const TextStyle(),
                              ),
                            ),
                            if (ligne.valeur != null)
                              Text(ligne.valeur!, style: styleSecondaire),
                          ],
                        ),
                        if (ligne.legende != null) ...<Widget>[
                          Ecart.vXs,
                          Text(ligne.legende!, style: styleSecondaire),
                        ],
                      ],
                    ),
                  ),
                  if (ligne.controle != null) ...<Widget>[
                    Ecart.hSm,
                    ligne.controle!,
                  ],
                  if (ligne.onPress != null &&
                      ligne.controle == null) ...<Widget>[
                    Ecart.hSm,
                    ExcludeSemantics(
                      child: IconTheme(
                        data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                        child: Icon(AppIcons.chevron.repos),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le bouton d'en-tete qui ouvre les preferences : carre arrondi a filet,
/// engrenage d'accent, cible de 48 (maquettes V3, en haut a droite).
class BoutonEntete extends StatelessWidget {
  /// Cree le bouton.
  const BoutonEntete({
    required this.icone,
    required this.libelle,
    required this.onPress,
    super.key,
  });

  /// L'icone.
  final AppIcon icone;

  /// Ce que lit le lecteur d'ecran, et l'infobulle.
  final String libelle;

  /// L'action.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Tooltip(
      message: libelle,
      child: Pressable(
        onPress: onPress,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiSm,
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: AppTouchTarget.standard,
            child: DecoratedBox(
              decoration: AppElevation.avecFilet(
                surface: palette.surfaceRaised,
                filet: palette.contourCarte,
                ombre: palette.ombre,
                arrondi: AppRadius.arrondiSm,
              ),
              child: Center(
                child: IconTheme(
                  data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(icone.repos),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La colonne des sous-pages du Compte : largeur de lecture des reglages
/// (`AppPage.largeurReglages`), calee au debut. Sur bureau, la page ne
/// s'etire pas sur 1 100 points de large.
class ColonneSousPage extends StatelessWidget {
  /// Cree la colonne.
  const ColonneSousPage({required this.child, super.key});

  /// Le contenu.
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
      child: child,
    ),
  );
}
