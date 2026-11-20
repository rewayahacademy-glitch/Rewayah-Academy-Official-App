// VIVANT : la case haute des pieces d'identite a valider. Une pile de cartes
// qu'on feuillette du doigt ; toucher une carte ouvre le dossier de la
// personne, dans la file des pieces.
//
// **Feuilleter ne decide rien.** La maquette validait a droite et redemandait
// a gauche, avec « Annuler ». Le serveur n'offre pas ce geste : la decision
// d'une piece (`decider_dossier`) ne s'annule pas, un refus exige un motif
// ecrit, et la direction doit avoir vu le document. La decision reste donc
// dans le dossier (`DecisionPiece`), ou la piece s'ouvre (contrat de
// navigation §2 : jamais une decision lourde sur un simple glissement).
import 'package:flutter/material.dart';

import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/vivant/nombre_rouleaux.dart';
import '../../core/vivant/pile_feuilletee.dart';
import '../../core/vivant/toucher_vivant.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../admin_candidatures/files_candidatures.dart' show depuisQuand;
import '../admin_candidatures/libelles_candidatures.dart' show libellePays;
import 'bento_vivant.dart' show CaseVivante;

/// La case des pieces a valider.
class CasePieces extends StatefulWidget {
  /// Cree la case.
  const CasePieces({
    required this.attente,
    required this.maintenant,
    required this.onOuvrirFile,
    required this.onOuvrirDossier,
    super.key,
    this.lignes,
    this.plusAncienneDabord = false,
    this.hauteurMin = 0,
  });

  /// Le nombre de pieces et la plus ancienne, lus au serveur.
  final Attente attente;

  /// L'instant courant.
  final DateTime maintenant;

  /// Ouvre la file des pieces (la liste deja filtree).
  final VoidCallback onOuvrirFile;

  /// Ouvre le dossier d'une personne.
  final ValueChanged<LigneCandidature> onOuvrirDossier;

  /// Les personnes de la file, dans l'ordre de la pile ; `null` : non lues.
  final List<LigneCandidature>? lignes;

  /// Vrai : toute la file est lue et rangee, la plus ancienne en premier.
  final bool plusAncienneDabord;

  /// La hauteur minimale de la case.
  final double hauteurMin;

  /// La cle de l'en-tete (le nombre : il ouvre la file).
  static const Key cleNombre = ValueKey<String>('vivant-pieces-nombre');

  /// La cle de la pile.
  static const Key clePile = ValueKey<String>('vivant-pieces-pile');

  /// La cle de la carte du dessus.
  static const Key cleCarte = ValueKey<String>('vivant-pieces-carte');

  @override
  State<CasePieces> createState() => _EtatCasePieces();
}

class _EtatCasePieces extends State<CasePieces> {
  final GlobalKey<EtatPileFeuilletee> _pile = GlobalKey<EtatPileFeuilletee>(
    debugLabel: 'pile des pieces',
  );
  int _dessus = 0;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final v = t.admin.tableau.vivant;
    final int n = widget.attente.nombre;
    final List<LigneCandidature> lignes =
        widget.lignes ?? const <LigneCandidature>[];
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String libelle = t.admin.candidatures.attentes.pieceAValider;
    final String? depuis = depuisQuand(
      widget.attente.plusAncien,
      widget.maintenant,
    );
    final int rang = lignes.isEmpty ? 0 : _dessus.clamp(0, lignes.length - 1);
    return CaseVivante(
      paire: palette.surfaceRaised,
      hauteurMin: widget.hauteurMin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Le nombre ouvre la file : la liste deja filtree.
          ToucherVivant(
            key: CasePieces.cleNombre,
            onPress: widget.onOuvrirFile,
            libelleSemantique: <String>['$n $libelle', ?depuis].join(', '),
            arrondiFocus: AppRadius.arrondiSm,
            enfoncement: 0.97,
            child: Row(
              children: <Widget>[
                NombreRouleaux(
                  n,
                  style: (textes.displaySmall ?? const TextStyle()).copyWith(
                    color: palette.inkAccent.applyTo(const TextStyle()).color,
                  ),
                ),
                Ecart.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        libelle,
                        style: AppTypography.graisse(
                          textes.bodySmall ?? const TextStyle(),
                          FontWeight.w600,
                        ),
                      ),
                      if (depuis != null) Text(depuis, style: doux),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (n == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                v.piecesVide,
                style: doux,
                textAlign: TextAlign.center,
              ),
            )
          else if (lignes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: PileFeuilletee(
                key: _pile,
                nombre: lignes.length,
                onDessus: (int i) => setState(() => _dessus = i),
                constructeur:
                    (BuildContext context, int i, {required bool dessus}) =>
                        // Seule la carte du dessus se touche ; dessous, les
                        // cartes sont un decor.
                        dessus
                        ? _CartePiece(
                            key: CasePieces.cleCarte,
                            ligne: lignes[i],
                            onPress: () => widget.onOuvrirDossier(lignes[i]),
                          )
                        : _CartePiece(ligne: lignes[i]),
              ),
            ),
          // Rien sous le nombre quand la file vide tient en une phrase.
          if (n == 0 || lignes.isEmpty) const SizedBox.shrink(),
          if (n > 0 && lignes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (lignes.length > 1)
                    BarrePrecedentSuivant(
                      position: v.piecePosition(
                        rang: rang + 1,
                        total: lignes.length,
                      ),
                      libellePrecedent: v.piecePrecedente,
                      libelleSuivant: v.pieceSuivante,
                      onPrecedent: () => _pile.currentState?.precedente(),
                      onSuivant: () => _pile.currentState?.suivante(),
                    ),
                  Text(
                    lignes.length > 1 ? v.piecesAide : v.pieceAide,
                    style: doux,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// La carte d'une piece : la personne, puis sa piece dessinee (une photo, des
/// lignes), sans aucune donnee du document.
class _CartePiece extends StatelessWidget {
  const _CartePiece({required this.ligne, super.key, this.onPress});

  final LigneCandidature ligne;
  final VoidCallback? onPress;

  static const double rayon = AppRadius.lg;
  static const double marge = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Color encre = palette.surfaceOverlay.onBackground;
    final double interieur = AppRadius.interieur(rayon, marge);
    final Widget carte = DecoratedBox(
      // L'ombre portee, sous la forme.
      decoration: BoxDecoration(
        borderRadius: AppRadius.arrondiLg,
        boxShadow: AppElevation.niveau2(palette.ombre),
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          // Un cran au-dessus de la case : la carte se detache dans les
          // deux themes.
          color: palette.surfaceOverlay.background,
          shape: AppRadius.coinContinu(
            rayon,
            bordure: palette.borderHairline.asBorderSide(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(marge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AvatarNom(
                prenom: ligne.nomComplet,
                role: libellePays(ligne.paysResidence),
                disposition: DispositionAvatar.enLigne,
                diametre: AppAvatar.petit,
              ),
              Ecart.vMd,
              // La piece deposee, dessinee : une photo, des lignes.
              ExcludeSemantics(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: palette.washAccent.background,
                    shape: AppRadius.coinContinu(interieur),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: AppSpacing.titreEcran,
                          height: AppSpacing.respiration,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: palette.surfacePrimary.background,
                              shape: AppRadius.coinContinu(AppRadius.xs),
                            ),
                            child: Icon(
                              AppIcons.profil.actif,
                              size: AppSpacing.xxxl,
                              color: palette.surfacePrimary.onBackground,
                            ),
                          ),
                        ),
                        Ecart.hMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: AppSpacing.sm,
                            children: <Widget>[
                              for (final double l in <double>[0.9, 0.6, 0.75])
                                FractionallySizedBox(
                                  widthFactor: l,
                                  child: SizedBox(
                                    height: AppSpacing.sm,
                                    child: DecoratedBox(
                                      decoration: ShapeDecoration(
                                        color: palette.washAccent.onBackground
                                            .withValues(alpha: 0.2),
                                        shape: const StadiumBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                              Text(
                                t.admin.tableau.vivant.pieceIdentite,
                                style: AppTypography.graisse(
                                  (textes.labelSmall ?? const TextStyle())
                                      .copyWith(
                                        color: palette.washAccent.onBackground,
                                      ),
                                  FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final VoidCallback? geste = onPress;
    if (geste == null) {
      return DefaultTextStyle.merge(
        style: TextStyle(color: encre),
        child: carte,
      );
    }
    return ToucherVivant(
      onPress: geste,
      libelleSemantique: t.admin.tableau.vivant.ouvrirDossierDe(
        deNom: deDevant(
          ligne.nomComplet,
          cle: 'admin.tableau.vivant.ouvrirDossierDe',
        ),
      ),
      arrondiFocus: const BorderRadius.all(Radius.circular(rayon)),
      enfoncement: 0.97,
      child: carte,
    );
  }
}
