// La barre de selection d'une liste (promue de `lib/features/comptable/paiements/`
// vers le core par `ADM-20`, `docs/current/CATALOGUE_ECRANS_RECRUTEMENT.md`
// section 4 : « promue vers `lib/core/widgets/`, jamais recopiee »).
//
// Collee en bas d'une page (`PageShell.actions`) des qu'une ligne est retenue.
// Elle dit **combien** de lignes sont retenues, jamais un total : un total est
// rendu par la source, l'ecran n'additionne rien (CPT-PAY-1, FI6).
//
// Deux gestes seulement, et un seul bouton plein :
//
//   * « Tout relacher » est un bouton discret (tertiaire) ;
//   * l'action de la selection est le seul bouton plein (K-56). **Un bouton qui
//     ne peut pas aboutir n'est pas rendu** : sans [onAction] (hors ligne,
//     destination absente, droit absent), la [phrase] dit pourquoi a sa place.
//
// L'ecran donne ses textes ; la barre ne contient aucun libelle propre, de sorte
// que le Comptable (« Payer la selection ») et les Candidatures (« Agir sur la
// selection ») partagent le meme composant.
//
// **Variante compacte (LISTES-1, 23/10/2026)** : [BarreSelection.compacte], sur
// UNE ligne : le compte, les operations compatibles avec toute la selection, et
// « Deselectionner ». Elle ne coute pas la hauteur de la barre complete (plus de
// 140 points) a une liste dont le contenu est la priorite. Aucune operation
// n'y est inventee : l'ecran passe celles que le serveur sait faire, et
// seulement celles-la. Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
// (List-first, human-first).

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';

/// La barre de selection : complete (titre, phrase, boutons, a coller en bas de
/// page) ou, avec [BarreSelection.compacte], sur une seule ligne au-dessus
/// d'une liste.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class BarreSelection extends StatelessWidget {
  /// Cree la barre.
  const BarreSelection({
    required this.titre,
    required this.phrase,
    required this.libelleRelacher,
    required this.onRelacher,
    this.libelleAction,
    this.onAction,
    this.avantActions,
    super.key,
  }) : operations = const <Widget>[],
       compacte = false;

  /// La barre **compacte**, sur une ligne : [titre] (le compte : « 3
  /// selectionnees »), les [operations] compatibles avec toute la selection,
  /// puis « Deselectionner » ([libelleRelacher], par defaut le mot commun).
  ///
  /// Les [operations] sont des `ActionPrincipale` (`compacte: true` et
  /// `pleineLargeur: false`, sinon sur telephone chacune prend toute la ligne)
  /// de niveau secondaire, tertiaire ou destructif : **au plus un bouton plein par
  /// ecran** (K-56), la barre ne le compte pas pour l'ecran. Une operation que
  /// la selection ne permet pas n'est pas rendue (jamais grisee) : si la
  /// liste est vide, la barre dit seulement le compte et « Deselectionner ». La
  /// [phrase], facultative, vient sur une seconde ligne : la limite d'une
  /// operation qui ne se fait qu'une a une (« Les autres gestes se font depuis
  /// la fiche »).
  const BarreSelection.compacte({
    required this.titre,
    required this.onRelacher,
    this.operations = const <Widget>[],
    this.libelleRelacher = '',
    this.phrase = '',
    super.key,
  }) : libelleAction = null,
       onAction = null,
       avantActions = null,
       compacte = true;

  /// Vrai pour la barre sur une ligne ([BarreSelection.compacte]).
  final bool compacte;

  /// Les operations de la barre compacte : des `ActionPrincipale` compactes.
  final List<Widget> operations;

  /// Combien de lignes sont retenues (« 3 candidatures retenues »).
  final String titre;

  /// Une phrase sous le titre : ce que l'action fera, ou pourquoi elle n'est
  /// pas offerte (hors ligne, pas encore ouverte).
  final String phrase;

  /// Le libelle de « Tout relacher ». Vide, pour la barre compacte : le mot
  /// commun « Deselectionner ».
  final String libelleRelacher;

  /// Relache toute la selection.
  final VoidCallback onRelacher;

  /// Le libelle de l'action de la selection.
  final String? libelleAction;

  /// L'action de la selection, ou `null` : elle n'est alors pas rendue (jamais
  /// grisee) et [phrase] dit pourquoi.
  final VoidCallback? onAction;

  /// Un complement pose entre la phrase et les boutons (l'export de la
  /// selection du Comptable).
  final Widget? avantActions;

  /// La cle de l'action de la selection.
  static const Key cleAction = ValueKey<String>('barre-selection-action');

  /// La cle de « Tout relacher ».
  static const Key cleRelacher = ValueKey<String>('barre-selection-relacher');

  /// La cle de la barre.
  static const Key cleBarre = ValueKey<String>('barre-selection');

  @override
  Widget build(BuildContext context) {
    if (compacte) return _construireCompacte(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? action = onAction;
    final Widget? complement = avantActions;
    return Semantics(
      key: cleBarre,
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            phrase,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          if (complement != null) ...<Widget>[complement, Ecart.vMd],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.end,
            children: <Widget>[
              ActionPrincipale(
                key: cleRelacher,
                libelle: libelleRelacher,
                niveau: NiveauAction.tertiaire,
                onPress: onRelacher,
              ),
              if (action != null && libelleAction != null)
                ActionPrincipale(
                  key: cleAction,
                  libelle: libelleAction!,
                  onPress: action,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// La largeur a partir de laquelle « Deselectionner » se range au bout de la
  /// barre, loin des operations (on ne le confond pas avec elles).
  static const double largeurCoteACote = 640;

  /// La barre sur une ligne. Etroit, tout passe a la ligne : la barre grandit,
  /// elle ne coupe rien.
  Widget _construireCompacte(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String relacher = libelleRelacher.isEmpty
        ? t.commun.listes.deselectionner
        : libelleRelacher;
    final Widget compte = Text(
      titre,
      style: palette.washAccent.applyTo(textes.labelLarge ?? const TextStyle()),
    );
    final Widget deselectionner = ActionPrincipale(
      key: cleRelacher,
      libelle: relacher,
      niveau: NiveauAction.tertiaire,
      compacte: true,
      pleineLargeur: false,
      encre: palette.washAccent,
      onPress: onRelacher,
    );
    return Semantics(
      key: cleBarre,
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        // Le fond doux de l'accent : la barre se voit au-dessus d'une table
        // blanche sans devenir un aplat (une seule zone pleine par ecran).
        decoration: palette.washAccent.decoration(
          borderRadius: AppRadius.arrondiSm,
          side: palette.borderStrong.asBorderSide(),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LayoutBuilder(
                builder: (BuildContext contexte, BoxConstraints c) {
                  final Widget aide = Text(
                    phrase,
                    style: palette.washAccent.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  );
                  if (c.maxWidth >= largeurCoteACote) {
                    // **Une seule ligne** (relecture visuelle C-17) : le compte, les
                    // operations, la limite dite sans prendre une seconde ligne, puis
                    // « Deselectionner » au bout, loin des operations.
                    return Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.xs,
                            children: <Widget>[compte, ...operations],
                          ),
                        ),
                        if (phrase.isNotEmpty) ...<Widget>[
                          Ecart.hMd,
                          Expanded(flex: 2, child: aide),
                        ],
                        Ecart.hMd,
                        deselectionner,
                      ],
                    );
                  }
                  // Etroit (relecture visuelle C-26) : le compte et « Deselectionner »
                  // puis les operations groupees entre elles (jamais cachees par un
                  // defilement), la limite dessous.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[compte, deselectionner],
                      ),
                      if (operations.isNotEmpty)
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: operations,
                        ),
                      if (phrase.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                            bottom: AppSpacing.sm,
                          ),
                          child: aide,
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
