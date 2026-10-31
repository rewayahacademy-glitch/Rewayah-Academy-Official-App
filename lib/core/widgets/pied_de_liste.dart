import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'barre_precedent_suivant.dart';
import 'menu_filtre.dart';

/// Le pied d'une liste paginee : « 1-50 sur 614 », page precedente, page
/// suivante, et, **seulement si l'ecran la fournit**, la taille de page.
///
/// **Une seule rangee**, a la place des trois du `resume` de page, du compteur
/// et du selecteur de taille que chaque liste composait (LISTES-1). Il dit ou
/// l'on est dans la liste qu'on ne voit pas en entier : des centaines de lignes,
/// et le volume grandit.
///
/// **Il ne connait ni le serveur ni l'ordre** : l'ecran lui donne la tranche
/// affichee ([debut], [fin], [total]) et ce que font les fleches. Les fleches
/// reutilisent [BarrePrecedentSuivant] : aux bornes, la fleche n'est **pas
/// rendue** (jamais grisee), et sa place reste reservee pour que la position ne
/// bouge pas.
///
/// **La taille de page n'est jamais inventee** : quand le serveur impose la
/// sienne (Candidatures : 50, en dur), l'ecran ne passe pas [taillesProposees]
/// et aucun selecteur ne se montre. Un selecteur qui ne change rien serait un
/// faux controle.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class PiedDeListe extends StatelessWidget {
  /// Cree le pied.
  const PiedDeListe({
    required this.debut,
    required this.fin,
    required this.total,
    super.key,
    this.onPrecedent,
    this.onSuivant,
    this.taillePage,
    this.taillesProposees = const <int>[],
    this.onTaillePage,
    this.mention,
  });

  /// La taille de page que la **source** impose, dite en toutes lettres (« 50 par
  /// page »), quand l'ecran n'en offre pas le choix. Posee a la place du
  /// selecteur : au meme endroit, du meme cote, pour que deux listes ne
  /// composent pas deux pieds differents (LISTES-1, relecture visuelle C-12).
  /// Ignoree quand l'ecran fournit un vrai choix de taille.
  final String? mention;

  /// Le rang (a partir de 1) de la premiere ligne de la page.
  final int debut;

  /// Le rang de la derniere ligne de la page.
  final int fin;

  /// Le nombre de lignes de la liste entiere (apres filtres).
  final int total;

  /// Page precedente, ou `null` : on est a la premiere page (la fleche n'est
  /// pas rendue).
  final VoidCallback? onPrecedent;

  /// Page suivante, ou `null` : on est a la derniere page.
  final VoidCallback? onSuivant;

  /// La taille de page en cours, quand l'ecran en offre le choix.
  final int? taillePage;

  /// Les tailles proposees (25, 50, 100). Vide : pas de selecteur.
  final List<int> taillesProposees;

  /// Ce que fait le choix d'une taille. Sans lui, pas de selecteur.
  final ValueChanged<int>? onTaillePage;

  /// La cle du pied, pour les tests.
  static const Key cle = ValueKey<String>('pied-de-liste');

  /// La cle du selecteur de taille de page.
  static const Key cleTaille = ValueKey<String>('pied-de-liste-taille');

  /// La largeur du selecteur de taille (« 100 par page » y tient sans coupure,
  /// au texte agrandi il passe a la ligne).
  static const double largeurTaille = AppSpacing.respiration * 3;

  /// En dessous de cette largeur, le selecteur (ou la mention) de la taille de
  /// page n'est pas rendu : la navigation reste seule.
  static const double largeurDeuxColonnes = 480;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    final bool choixTaille =
        onTaillePage != null && taillesProposees.length > 1;

    final Widget navigation = BarrePrecedentSuivant(
      position: t.commun.listes.tranche(debut: debut, fin: fin, total: total),
      positionSemantique: t.commun.listes.trancheLue(
        debut: debut,
        fin: fin,
        total: total,
      ),
      libellePrecedent: t.commun.listes.precedente,
      libelleSuivant: t.commun.listes.suivante,
      onPrecedent: onPrecedent,
      onSuivant: onSuivant,
      etendue: false,
    );

    final String? dite = choixTaille ? null : mention;
    final Widget? taille = choixTaille
        ? SizedBox(
            key: cleTaille,
            width: largeurTaille,
            child: MenuFiltre<int>(
              libelle: t.commun.listes.taillePage,
              // Le selecteur dit ou l'on est, il ne filtre rien : neutre, la
              // taille courante portee par une coche.
              selecteurDeSection: true,
              valeur: taillePage,
              entrees: <EntreeFiltre<int>>[
                for (final int n in taillesProposees)
                  EntreeFiltre<int>(
                    valeur: n,
                    libelle: t.commun.listes.parPage(n: n),
                  ),
              ],
              onChoix: (int? n) {
                if (n != null && n != taillePage) onTaillePage!(n);
              },
            ),
          )
        : dite == null
        ? null
        : Text(
            dite,
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          );

    return Semantics(
      key: cle,
      container: true,
      child: LayoutBuilder(
        builder: (BuildContext contexte, BoxConstraints contraintes) {
          // A droite, comme la fin d'un tableau : la taille de page, puis la
          // tranche et les fleches. Etroit, le selecteur passe au-dessus.
          if (taille == null) {
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: navigation,
            );
          }
          if (contraintes.maxWidth >= largeurDeuxColonnes) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                taille,
                Ecart.hMd,
                Flexible(child: navigation),
              ],
            );
          }
          // Etroit (telephone), **la navigation seule** : le choix de la taille de
          // page et sa mention passaient au-dessus d'elle et portaient le pied a
          // 104 points sous trois cartes (relecture visuelle K-06). La taille
          // reste celle de la liste ; elle se change sur un ecran large.
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: navigation,
          );
        },
      ),
    );
  }
}
