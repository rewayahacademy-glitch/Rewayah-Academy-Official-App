import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'entete_page.dart';
import 'page_shell.dart';

/// Le gabarit d'une etape de tache focalisee : l'ajout d'un profil eleve
/// (lot B), l'admission par etapes (lot A), et tout parcours a venir des
/// autres roles (demandes B-3 et A-2).
///
/// La **rangee d'etape** de la planche V6 (#12, #14) est la premiere ligne de
/// la page : disque retour de 48, barre de progression continue, « n sur N ».
/// Aucune action de coquille au-dessus (ni cloche ni bascule de theme :
/// `PageShell.actionsCoquille` a faux) ; puis le contenu ; puis l'action,
/// collee en bas par [PageShell]. L'admission peut y poser une
/// `ActionPrincipale(pilule: true)` ; ce gabarit n'impose pas la forme.
///
/// Un seul composant pour tous les parcours par etapes : un lot qui a besoin
/// d'une variante l'ajoute ici, il n'en recree pas une copie locale.
class PageEtape extends StatelessWidget {
  /// Cree une page d'etape.
  const PageEtape({
    required this.numero,
    required this.total,
    required this.child,
    super.key,
    this.onRetour,
    this.action,
    this.defilante = true,
  }) : assert(total > 0 && numero >= 1 && numero <= total, 'etape hors borne');

  /// Le rang de cette etape, a partir de 1.
  final int numero;

  /// Le nombre d'etapes du parcours.
  final int total;

  /// Le retour : etape precedente, ou sortie du parcours a la premiere.
  /// `null` quand il n'y a nulle part ou revenir (premiere etape d'un parcours
  /// dont la sortie est ailleurs) : pas de disque, la rangee reste (demande
  /// A-5.1).
  final VoidCallback? onRetour;

  /// Le contenu de l'etape (question, consigne, choix, champs).
  final Widget child;

  /// L'action collee en bas, en general une `ActionPrincipale`.
  final Widget? action;

  /// Faux quand le contenu gere son propre defilement.
  final bool defilante;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      actionsCoquille: false,
      entete: RangeeEtape(numero: numero, total: total, onRetour: onRetour),
      actions: action,
      defilante: defilante,
      child: child,
    );
  }
}

/// La rangee d'etape de la planche V6 : disque retour, progression continue,
/// « n sur N ». Lue « Etape n sur N ». Publique pour une etape rendue hors
/// de [PageEtape] (panneau centre sur bureau, dialogue).
class RangeeEtape extends StatelessWidget {
  /// Cree la rangee.
  const RangeeEtape({
    required this.numero,
    required this.total,
    super.key,
    this.onRetour,
  });

  /// Le rang de l'etape, a partir de 1.
  final int numero;

  /// Le nombre d'etapes.
  final int total;

  /// Le retour ; `null` : pas de disque, progression et rang gardes.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        if (onRetour case final VoidCallback retour) ...<Widget>[
          DisqueRetour(onPress: retour),
          Ecart.hXl,
        ],
        Expanded(
          child: Semantics(
            label: t.commun.etape.surLue(n: numero, total: total),
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: AppRadius.arrondiFull,
              child: SizedBox(
                height: AppSpacing.sm,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // La piste est une surface enfoncee : sur le fond de page,
                    // une piste transparente a filet ne se voit pas.
                    ColoredBox(color: palette.surfaceSunken.background),
                    FractionallySizedBox(
                      // Directionnel : en arabe, la progression part de droite.
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: numero / total,
                      child: ColoredBox(
                        // Neutre : le violet reste aux actions decisives (K-36).
                        color: palette.surfaceInverse.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Ecart.hXl,
        ExcludeSemantics(
          child: Text(
            t.commun.etape.sur(n: numero, total: total),
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
