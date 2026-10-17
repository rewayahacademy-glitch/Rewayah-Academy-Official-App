import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'entete_page.dart';
import 'offline_banner.dart';
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
/// `PageParcours` lui delegue (lot E3, audit d'entree du 17/10, L3).
///
/// **Borne sur grand ecran** (demande du directeur du 17/10 : pas de cartes
/// du mobile etirees) : la rangee d'etape, le contenu et l'action tiennent
/// dans une seule colonne centree de [largeurColonne], la largeur de lecture
/// deja retenue par l'ajout d'un profil eleve. Sur telephone la colonne
/// prend toute la largeur et rien ne change. Hors telephone, l'action prend
/// la largeur de son contenu (et non 1136 points pour un verbe) et se range
/// au bord de fin de la colonne : a droite en francais, a gauche en arabe.
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
    this.bandeauHorsLigne = const OfflineBanner(),
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

  /// La largeur maximale de la colonne d'etape (rangee, contenu, action).
  /// La largeur de lecture d'une tache focalisee : environ 68 caracteres de
  /// texte courant, celle de la colonne de l'ajout d'un profil eleve.
  static const double largeurColonne = AppPage.largeurDialogue;

  /// La cle de la colonne bornee du contenu (mesuree par les tests).
  static const Key colonneKey = ValueKey<String>('page-etape-colonne');

  /// La cle du bloc d'action borne (mesure par les tests).
  static const Key actionKey = ValueKey<String>('page-etape-action');

  /// Le bandeau hors ligne de la page (voir [PageShell.bandeauHorsLigne]) :
  /// une etape des Communications y pose le sien (D-FUS-3).
  final Widget bandeauHorsLigne;

  @override
  Widget build(BuildContext context) {
    final bool telephone = AppGabarit.de(context) == Gabarit.mobile;
    final Widget? zoneAction = switch (action) {
      null => null,
      final Widget a => _ColonneEtape(
        child: KeyedSubtree(
          key: actionKey,
          child: telephone
              ? a
              // Hors telephone : la largeur du contenu de l'action (la plus
              // large de ses lignes), au bord de fin de la colonne.
              : Align(
                  alignment: AlignmentDirectional.centerEnd,
                  heightFactor: 1,
                  child: IntrinsicWidth(child: a),
                ),
        ),
      ),
    };
    return PageShell(
      actionsCoquille: false,
      entete: _ColonneEtape(
        child: RangeeEtape(numero: numero, total: total, onRetour: onRetour),
      ),
      actions: zoneAction,
      defilante: defilante,
      bandeauHorsLigne: bandeauHorsLigne,
      child: _ColonneEtape(cle: colonneKey, child: child),
    );
  }
}

/// La colonne d'etape : centree, bornee a [PageEtape.largeurColonne]. Sur
/// telephone, la largeur offerte est deja plus etroite : elle la prend.
class _ColonneEtape extends StatelessWidget {
  const _ColonneEtape({required this.child, this.cle});

  final Widget child;
  final Key? cle;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      key: cle,
      constraints: const BoxConstraints(maxWidth: PageEtape.largeurColonne),
      // Toute la largeur de la colonne, meme pour un contenu court : il
      // commence au bord de debut de la colonne, il n'est pas centre.
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
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
                        color: palette.surfacePrimary.background,
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
