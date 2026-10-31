import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'menu_commun.dart';
import 'pressable.dart';

/// Une action proposee par un [MenuActions].
@immutable
class EntreeAction {
  /// Cree une entree.
  const EntreeAction({
    required this.libelle,
    required this.onChoix,
    this.destructif = false,
    this.icone,
    this.separateurAvant = false,
  });

  /// Le libelle affiche. Il passe a la ligne au lieu d'etre tronque.
  final String libelle;

  /// Ce qui se passe quand l'action est choisie.
  final VoidCallback onChoix;

  /// Vrai pour une action qui retire ou cloture : rendue en ton alerte, au
  /// **meme corps** que les autres entrees (elle etait plus petite et plus
  /// legere), et **toujours separee** des autres par un trait.
  final bool destructif;

  /// Une icone facultative, du catalogue de l'application ([AppIcons]) : le
  /// composant n'en invente aucune. Rendue a gauche du libelle, a l'encre
  /// douce (ton alerte pour une action destructive).
  final AppIcon? icone;

  /// Vrai : un trait fin precede cette entree (nouveau groupe d'actions).
  /// Le trait entre une action destructive et ses voisines est pose seul.
  final bool separateurAvant;
}

/// Le menu des actions d'un objet : une ligne de liste ou de table, une carte,
/// un panneau. Le « ... » en bout de ligne.
///
/// **Un seul composant, sur `PopupMenuButton`** comme [MenuFiltre] : Echap,
/// clic exterieur, un seul menu ouvert, bornage a l'ecran et miroir en arabe
/// sont ceux de Flutter, et ne se refont pas (`menu_commun.dart`). Surface,
/// filet, ombre et rayon viennent du theme (`popupMenuTheme`), les memes que
/// ceux de [MenuFiltre] : jamais un style local.
///
/// **L'ordre est celui de l'appelant** : l'action la plus frequente d'abord,
/// les actions destructives a la suite. Un trait fin se pose a chaque changement
/// de groupe (de l'ordinaire au destructif, ou l'inverse) et devant une entree
/// qui le demande ([EntreeAction.separateurAvant]). Le composant **ne reordonne
/// rien** : l'ordre d'un menu est une regle de l'ecran (par exemple
/// `gestes_proposes.dart`), prouvee par ses tests ; un ecran qui entremele les
/// destructifs et les autres obtient autant de traits, et range ses entrees s'il
/// veut un seul groupe. Une action incompatible avec l'etat de l'objet n'est pas
/// proposee (elle n'est pas grisee, `lib/CLAUDE.md`).
///
/// **Pas d'infobulle** sur le declencheur : le libelle (« Actions : {objet} »)
/// reste dans la voix du lecteur d'ecran. L'infobulle de Material couvrait
/// la ligne suivante et restait affichee apres le clic, ce qui se voyait
/// comme un petit panneau sombre et transparent.
///
/// **Quand l'employer** (regle LISTES-1) : le menu « ... » d'une ligne porte
/// toutes les actions de la ligne ; au plus une action rapide visible peut le
/// precede (DESIGN-GOV 4 bis). Il ne remplace pas le geste principal de la
/// ligne.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class MenuActions extends StatelessWidget {
  /// Cree un menu d'actions.
  const MenuActions({
    required this.actions,
    this.objet,
    this.libelle,
    this.points = false,
    this.fermetureNette = false,
    super.key,
  });

  /// Vrai : le menu s'ouvre et disparait d'un coup, sans fondu (le fondu de
  /// sortie dure environ 200 ms, pendant lesquelles il resterait par-dessus).
  /// Pour une action qui anime l'ecran juste derriere le menu (TB-RC n.17 :
  /// la copie du support range ne vole plus sous un menu qui s'efface
  /// encore). L'action part aussitot, comme avant.
  final bool fermetureNette;

  /// Vrai pour le declencheur « ... » (trois points horizontaux, image CLV-07)
  /// au lieu de l'icone de menu : le menu d'un panneau, **et le menu d'une
  /// ligne de table ou d'une carte** (LISTES-1).
  final bool points;

  /// Les actions proposees.
  final List<EntreeAction> actions;

  /// Le nom de l'objet dont le menu est ouvert (« Classe 3 », « Amina
  /// Diallo ») : la voix dit « Actions : Classe 3 ». Jamais affiche.
  final String? objet;

  /// Le libelle complet du declencheur, quand l'appelant a mieux que
  /// « Actions : {objet} » (« Autres gestes »). Prend le pas sur [objet].
  final String? libelle;

  /// Ce que dit le lecteur d'ecran pour le declencheur.
  String get _libelleSemantique =>
      libelle ??
      (objet == null
          ? t.commun.listes.actions
          : t.commun.listes.actionsDe(objet: objet!));

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    final TextStyle corps =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();

    return MenuAncre<int>(
      libelle: _libelleSemantique,
      contraintes: contraintesMenu,
      animation: fermetureNette ? AnimationStyle.noAnimation : animationMenu,
      arrondiFocus: AppRadius.arrondiFull,
      onSelected: (int index) => actions[index].onChoix(),
      itemBuilder: (BuildContext _) => <PopupMenuEntry<int>>[
        for (int i = 0; i < actions.length; i++) ...<PopupMenuEntry<int>>[
          if (i > 0 &&
              (actions[i].separateurAvant ||
                  actions[i].destructif != actions[i - 1].destructif))
            const SeparateurMenu<int>(),
          PopupMenuItem<int>(
            value: i,
            height: cible,
            padding: EdgeInsets.zero,
            child: LigneEntreeMenu(
              child: _ContenuEntree(
                entree: actions[i],
                style: corps,
                palette: palette,
              ),
            ),
          ),
        ],
      ],
      declencheur: (BuildContext _, EtatPression etat) => SizedBox(
        width: cible,
        height: cible,
        // Un disque doux au survol et a la pression : la cible se voit avant
        // le clic (le carre d'encre de Material n'avait aucun arrondi).
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: etat.survole || etat.presse
                ? palette.washAccent.background
                : null,
          ),
          // K-54 : le declencheur est centre dans sa cible.
          child: Center(
            child: points
                ? _TroisPoints(
                    couleur: palette.inkStrong
                        .asIconTheme(size: AppSpacing.xs)
                        .color,
                  )
                : Icon(AppIcons.menu.repos),
          ),
        ),
      ),
    );
  }
}

/// Le contenu d'une entree : l'icone facultative, puis le libelle, qui passe
/// a la ligne entre ses mots (jamais coupe, jamais en ellipse).
class _ContenuEntree extends StatelessWidget {
  const _ContenuEntree({
    required this.entree,
    required this.style,
    required this.palette,
  });

  final EntreeAction entree;
  final TextStyle style;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final AppInkColor encreTexte = entree.destructif
        ? palette.inkAlert
        : palette.inkStrong;
    final AppInkColor encreIcone = entree.destructif
        ? palette.inkAlert
        : palette.inkMuted;
    final AppIcon? icone = entree.icone;
    return Row(
      children: <Widget>[
        if (icone != null) ...<Widget>[
          Icon(
            icone.repos,
            size: AppSpacing.xxl,
            color: encreIcone.asIconTheme().color,
          ),
          Ecart.hMd,
        ],
        Expanded(
          child: TexteSansCoupure(
            entree.libelle,
            style: encreTexte.applyTo(style),
          ),
        ),
      ],
    );
  }
}

/// Trois points horizontaux, a l'encre forte : le declencheur d'un menu de
/// panneau.
class _TroisPoints extends StatelessWidget {
  const _TroisPoints({required this.couleur});

  final Color? couleur;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.xs,
    children: <Widget>[
      for (int i = 0; i < 3; i++)
        SizedBox.square(
          dimension: AppSpacing.xs,
          child: DecoratedBox(
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
        ),
    ],
  );
}
