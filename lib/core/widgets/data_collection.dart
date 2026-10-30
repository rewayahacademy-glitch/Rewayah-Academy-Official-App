import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';
import 'case_a_cocher.dart';
import 'page_shell.dart' show RelaisTetePage, TetePageConfiee;
import 'pressable.dart';

/// Ce qu'une colonne devient quand le tableau se replie en cartes.
///
/// C'est la regle de transformation de `docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md`
/// section 4, portee par le type plutot que par la vigilance : « la colonne
/// identifiante devient le titre, deux a trois colonnes deviennent la ligne
/// secondaire, le reste passe dans le detail ».
enum RoleColonne {
  /// Le titre de la carte. **Une seule par collection.**
  identifiante,

  /// Rejoint la ligne secondaire de la carte, avec les autres, separees par un
  /// point median.
  secondaire,

  /// Prend sa propre ligne sous les autres. Pour ce qui est long : un contenu
  /// libre, une phrase, un objet serialise. Deux a trois colonnes se lisent sur
  /// une ligne commune ; une douzaine de mots, non.
  aPart,
}

/// La definition d'une colonne, valable pour les deux rendus.
///
/// **Une seule definition pour le tableau et pour la carte.** Deux listes de
/// colonnes divergeraient au premier ajout, et c'est exactement ce que
/// `05-regles-responsive.md` section 4 demande d'eviter.
@immutable
class ColonneDonnees<T> {
  /// Cree une colonne.
  const ColonneDonnees({
    required this.titre,
    required this.texte,
    this.role = RoleColonne.secondaire,
    this.flex = 1,
    this.tabulaire = false,
    this.rendu,
    this.rendreMemeSiTexteVide = false,
    this.tri,
    this.ligneDense = true,
  });

  /// LISTES-2 : faux, la colonne n'entre pas dans la ligne secondaire d'une
  /// ligne dense de telephone ([DataCollection.densiteTelephone]) ; elle reste
  /// au tableau. Pour garder cette ligne sur une ligne : l'essentiel seulement
  /// (« matricule · classe · tuteur »).
  final bool ligneDense;

  /// L'en-tete de colonne, en rendu tableau. Il sert aussi de libelle parle en
  /// rendu carte, ou aucun en-tete n'est visible.
  final String titre;

  /// La valeur, en texte. **Toujours renseignee, meme quand [rendu] l'est** :
  /// c'est elle que lisent les technologies d'assistance et le point median de
  /// la carte.
  final String Function(T ligne) texte;

  /// Ce que la colonne devient en rendu carte.
  final RoleColonne role;

  /// Sa part de largeur, en rendu tableau.
  final int flex;

  /// Vrai pour les chiffres et les horodatages : sans les chiffres tabulaires,
  /// une colonne de dates fait danser celle d'a cote a chaque ligne.
  final bool tabulaire;

  /// Un rendu riche facultatif : une pastille d'etat, une puce. Le texte reste
  /// obligatoire a cote, il ne le remplace pas.
  final Widget Function(BuildContext context, T ligne)? rendu;

  /// Pour une colonne [RoleColonne.aPart] dont [rendu] ne depend pas de
  /// [texte] : `false` (par defaut) garde le comportement existant, ou un
  /// [texte] vide fait disparaitre la cellule entiere en rendu carte -- c'est
  /// ce qui masque la cellule « Observer » de `CTR-01` quand la ligne ne
  /// l'est pas. `true` rend [rendu] meme si [texte] est vide : c'est le cas
  /// d'un menu d'actions, qui n'a rien a dire en texte.
  ///
  /// **Pour le menu d'une ligne, preferer [DataCollection.actionsLigne]**
  /// (LISTES-1) : la colonne d'actions y est posee hors de la cible de la ligne,
  /// a une largeur fixe, sans cellule vide ni `flex: 0` recopies page apres page.
  /// Ce parametre reste pour les autres cellules a part ; les pages qui portaient
  /// le patron (classes, programmes, progression, evaluations, qualite,
  /// contractuels) ne sont pas migrees par le socle : c'est leur lot (LISTES-1,
  /// lot 4).
  final bool rendreMemeSiTexteVide;

  /// Le tri de cette colonne, **fourni par l'ecran** : l'en-tete devient un
  /// bouton qui l'appelle, avec l'indicateur du sens en cours. `null` : la
  /// colonne n'est pas triable, son en-tete reste un simple titre. La
  /// collection ne trie jamais elle-meme : elle ne connait pas l'ordre voulu
  /// (serveur, ordre metier), et n'en invente aucun.
  final TriColonne? tri;
}

/// Le sens d'un tri de colonne.
enum SensTri {
  /// Du plus petit au plus grand, de A a Z, du plus ancien au plus recent.
  croissant,

  /// L'inverse.
  decroissant,
}

/// Le tri d'une colonne, tel que l'ecran le fournit (LISTES-1).
@immutable
class TriColonne {
  /// Cree un tri.
  const TriColonne({required this.onTrier, this.sens});

  /// Le sens du tri **en cours sur cette colonne**, ou `null` : la table n'est
  /// pas triee sur elle. L'en-tete montre alors deux fleches douces (« on peut
  /// trier ici »), puis une fleche nette quand le tri est pose.
  final SensTri? sens;

  /// Ce que l'ecran fait au toucher de l'en-tete : il choisit le sens, charge
  /// l'ordre ou trie ses lignes. La collection ne fait rien d'autre qu'appeler.
  final VoidCallback onTrier;
}

/// La selection multiple d'une table, telle que l'ecran la tient (LISTES-1).
///
/// L'ecran **possede** la selection (ensemble d'identifiants, cle de requete) :
/// la collection n'en garde rien. Elle pose une colonne de cases, et une case
/// d'en-tete a trois etats qui **ne cochent que la page visible** (les lignes
/// recues), jamais « tous les resultats » d'un filtre : la page n'est pas le
/// jeu complet, et un geste groupe sur des profils qu'on ne voit pas serait une
/// selection silencieuse.
@immutable
class SelectionCollection<T> {
  /// Cree la selection.
  const SelectionCollection({
    required this.estCochee,
    required this.onBasculer,
    required this.onBasculerPage,
    required this.libelleLigne,
    this.estCochable,
  });

  /// Dit si la ligne est cochee.
  final bool Function(T ligne) estCochee;

  /// Coche ou vide la case d'une ligne.
  final void Function(T ligne) onBasculer;

  /// Coche (`true`) ou vide (`false`) **toute la page** : les lignes recues,
  /// pas les resultats qu'on ne voit pas.
  final void Function(bool cocher) onBasculerPage;

  /// L'objet de la case d'une ligne, pour le lecteur d'ecran (« Amina Diallo » :
  /// « Cocher Amina Diallo »).
  final String Function(T ligne) libelleLigne;

  /// Dit si la case d'une ligne est posee. `null` : toutes le sont. Une ligne
  /// qu'on ne peut pas retenir n'a **pas de case** (jamais une case grisee) et
  /// ne compte pas dans l'etat de la case d'en-tete.
  final bool Function(T ligne)? estCochable;

  /// L'etat de la case d'en-tete pour [lignes] : cochee quand toutes les lignes
  /// cochables le sont, vide quand aucune, partielle (`null`) sinon.
  bool? etatPage(List<T> lignes) {
    int cochables = 0;
    int cochees = 0;
    for (final T ligne in lignes) {
      if (estCochable?.call(ligne) ?? true) {
        cochables++;
        if (estCochee(ligne)) cochees++;
      }
    }
    if (cochables == 0 || cochees == 0) return false;
    return cochees == cochables ? true : null;
  }
}

/// Un tableau dense sur desktop, une liste de cartes ailleurs.
///
/// **Le composant unique de `07-catalogue-composants.md` (P1).** Il n'existait
/// pas avant `ADM-04`, premier ecran du produit dont la forme naturelle est un
/// tableau (`05-regles-responsive.md` section 3).
///
/// Le seuil est le desktop et non la tablette : une tablette en portrait n'a
/// pas la largeur d'un tableau dense, et un tableau retreci est precisement ce
/// que la regle interdit.
///
/// **Il defile lui-meme**, et la page qui le porte passe donc `defilante: false`
/// a son `PageShell`. C'est ce qui permet a l'en-tete de colonnes de rester
/// collee en haut pendant que les lignes defilent : un en-tete pris dans le
/// defilement de la page disparaitrait a la premiere molette, et une colonne de
/// journal sans son en-tete ne se lit plus. Pour que l'en-tete reste colle, la
/// page pose la collection dans une [PlaceCollection] (ou une `ColonneCorps` a
/// `minimumEtire`) et **ne passe pas** [defileAvecLaPage] : sinon tout defile
/// avec la page et l'en-tete s'en va (c'etait celui de Candidatures).
///
/// **Densite (LISTES-1).** Une ligne de table mesure **une cible tactile du
/// mode** (48, 72 en Interface guidee) quand son contenu tient, **plus 8** quand
/// elle porte une case ou un menu (la place de l'anneau de focus de leur
/// cible) ; elle ne grandit que si son contenu l'exige, une alerte, un texte
/// sur deux lignes. Les marges verticales sont celles du jeton `sm`. Les cellules
/// sont centrees dans la hauteur de la ligne.
///
/// **Ce que l'ecran peut ajouter, tout est facultatif** (les 19 pages qui
/// emploient ce composant n'ont rien a changer) :
///
///   * [selection] : une colonne de cases ([CaseACocher]) et une case d'en-tete
///     « cocher la page » a trois etats, qui ne coche que la page visible ;
///   * [actionsLigne] : une colonne d'actions en fin de ligne (un `MenuActions`,
///     au plus une action rapide devant), **hors de la cible de la ligne** : la
///     ligne et le menu sont deux arrets de tabulation, et le menu n'ouvre pas
///     la ligne. Remplace le patron « `rendreMemeSiTexteVide` et `flex: 0` »
///     que chaque page recopiait ;
///   * [ColonneDonnees.tri] : l'en-tete d'une colonne devient un bouton de tri,
///     que **l'ecran** fournit (indicateur du sens, `Semantics`). La collection
///     ne trie rien.
///
/// Sous le seuil du bureau, la collection se replie en cartes : la case se
/// pose avant la carte et le menu apres, hors de la cible de la carte. Il n'y
/// a pas de case d'en-tete en cartes : « cocher la page » est une commande de
/// table.
///
/// Regle LISTES-1 : `docs/current/DECISION-LISTES-2026-10-23.md`
/// (List-first, human-first).
class DataCollection<T> extends StatelessWidget {
  /// Cree une collection.
  const DataCollection({
    required this.colonnes,
    required this.lignes,
    super.key,
    this.piedDePage,
    this.cle,
    this.onSelectionner,
    this.defileAvecLaPage = false,
    this.estSelectionnee,
    this.defileSeule = true,
    this.selection,
    this.actionsLigne,
    this.largeurActions,
    this.piedCollant,
    this.tete,
    this.prendTeteDePage = false,
    this.densiteTelephone = false,
  });

  /// LISTES-2 (directeur, 30/10/2026) : ce qui precede les lignes et
  /// **defile avec elles** (choix de vue, filtres, recherche, synthese), au
  /// lieu de rester fixe au-dessus de la liste. Au bureau, seule la rangee
  /// d'en-tetes de colonnes reste collee ; le pied ([piedCollant]) vient
  /// apres la derniere ligne. Opt-in, adopte liste par liste
  /// (`DECISION-LISTES-2026-10-23.md` §5 ter). `null` : le rendu d'avant.
  final Widget? tete;

  /// LISTES-2 : vrai, la collection **prend la tete de la page**
  /// (`PageShell(teteAvecLaListe: true)`, [TetePageConfiee]) et la pose en
  /// premier element de son defilement, avant [tete]. Implique le rendu de
  /// [tete] (defilement par tranches) meme sans elle.
  final bool prendTeteDePage;

  /// LISTES-2 : vrai, sous le seuil du tableau, une **ligne dense** par objet
  /// au lieu d'une carte : la colonne identifiante, puis les autres sur une
  /// ligne (« matricule · classe · tuteur »), 64 px au moins (la cible du mode
  /// en Interface guidee, plus 8 avec une case ou un menu), filets fins dans
  /// un seul cadre (K-55). Une colonne a pastille ne montre que sa valeur non
  /// vide. Ne vaut que dans le rendu par tranches ([tete] ou
  /// [prendTeteDePage]).
  final bool densiteTelephone;

  /// Vrai quand la collection se rend par tranches (LISTES-2).
  bool get _parTranches => tete != null || prendTeteDePage;

  /// Ce qui se pose **sous les lignes et ne defile pas** : le pied d'une liste
  /// paginee ([PiedDeListe]). En tableau, il ferme le cadre (un filet le separe
  /// des lignes) ; en cartes, il suit la derniere carte. Different de
  /// [piedDePage], qui defile avec les lignes. `null` : rien.
  final Widget? piedCollant;

  /// La selection multiple (colonne de cases, case d'en-tete), ou `null` :
  /// aucune case, comme avant l'ajout de ce parametre.
  final SelectionCollection<T>? selection;

  /// Ce qui se pose en fin de ligne, **hors de la cible de la ligne** : un
  /// `MenuActions`, eventuellement precede d'une action rapide. `null` : pas de
  /// colonne d'actions.
  ///
  /// Une ligne qui n'a **aucune** action rend `SizedBox.shrink()` : la colonne
  /// garde sa largeur, la ligne ne se decale pas.
  final Widget Function(BuildContext context, T ligne)? actionsLigne;

  /// La largeur de la colonne d'actions. Par defaut, une cible tactile du mode
  /// (un seul `MenuActions`) ; plus large quand une action rapide precede le
  /// menu.
  final double? largeurActions;

  /// Dit si une ligne est la ligne choisie (inspecteur, AD-X). Nul : aucune
  /// ligne n'est marquee, comme avant l'ajout de ce parametre. La ligne
  /// choisie se marque par le fond, un contour et `Semantics(selected)`,
  /// jamais par la couleur seule ; en cartes, par `AppCard.selectionnee`.
  final bool Function(T ligne)? estSelectionnee;

  /// Vrai quand la collection se rend en tableau (desktop), faux quand elle
  /// se replie en cartes. Le seul endroit qui compare le gabarit : une page
  /// qui choisit entre son propre defilement et celui de la collection lit
  /// cette regle-ci.
  static bool enTableau(BuildContext context) =>
      AppGabarit.de(context) == Gabarit.desktop;

  /// Vrai : la collection **ne defile pas elle-meme**, elle prend la hauteur
  /// de ses lignes et defile avec la page (`PageShell(defilante: true)`).
  ///
  /// Pourquoi (ONGLETS-COUPE-1) : en cartes, il n'y a pas d'en-tete de
  /// colonnes a garder colle. Une page qui pose une introduction, des actions
  /// et des filtres au-dessus d'une collection qui defile seule ne laissait,
  /// a 320 px et au texte agrandi, plus aucune hauteur a la liste : la
  /// colonne debordait de 52 a 480 px. En cartes, tout defile donc ensemble ;
  /// en tableau, l'en-tete reste colle et la collection defile seule.
  final bool defileAvecLaPage;

  /// Faux quand la collection est **une section** d'une liste qui defile
  /// deja (Pedagogie > Qualite : une collection par type d'anomalie, toutes
  /// dans le meme defilement) : elle pose alors toutes ses lignes a leur
  /// hauteur, sans defileur propre, et l'en-tete de colonnes ouvre la
  /// section. Une liste dans une liste qui defile n'a pas de hauteur
  /// (« Vertical viewport was given unbounded height », FILTRES-1b) ; vrai
  /// par defaut, le comportement d'avant.
  final bool defileSeule;

  /// La hauteur sous laquelle une collection ne se lit plus : un titre et
  /// quatre lignes de liste, a l'echelle du texte de [context] (L4-07). Une
  /// ligne de liste vaut au moins une cible tactile et ses deux marges
  /// (72) ; deux lignes de texte plus leurs marges si le texte, agrandi, les
  /// depasse. C'est le `minimumEtire` d'une `ColonneCorps` qui la porte
  /// (FILTRES-1b) : quand l'intro, les filtres et la tete ne laissent plus
  /// quatre lignes a la liste, la page defile au lieu de la reduire a une
  /// ligne et demie (1366 x 650 : 120 px de liste sous 506 px de tete).
  static double minimumLisible(BuildContext context) {
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    final TextTheme textes = Theme.of(context).textTheme;
    double ligne(TextStyle? style) =>
        echelle.scale(style?.fontSize ?? 14) * (style?.height ?? 1.2);
    final double uneLigneDeListe = math.max(
      AppTouchTarget.standard + AppSpacing.md * 2,
      ligne(textes.bodySmall) * 2 + AppSpacing.md * 2,
    );
    return ligne(textes.titleMedium) +
        AppSpacing.sm +
        uneLigneDeListe * _lignesLisibles;
  }

  /// Le nombre de lignes de liste visibles sous lequel la page defile.
  static const int _lignesLisibles = 4;

  /// Les colonnes, dans l'ordre d'affichage.
  final List<ColonneDonnees<T>> colonnes;

  /// Les donnees.
  final List<T> lignes;

  /// Ce qui suit la derniere ligne : un bouton « charger la suite », une phrase
  /// de fin. Il defile avec les lignes, il ne colle pas.
  final Widget? piedDePage;

  /// De quoi donner a chaque ligne une cle stable. Sans elle, une page ajoutee
  /// en fin de liste reconstruit tout.
  final Key Function(T ligne)? cle;

  /// Ce qui se passe quand une ligne ou une carte est choisie. `null` laisse
  /// la collection en pure lecture, comme avant l'ajout de ce parametre.
  final void Function(T ligne)? onSelectionner;

  /// Vrai quand chaque colonne du tableau tient, a [largeur] et a l'echelle
  /// du texte de [context] : le mot le plus long de son en-tete et de chacune
  /// de ses cellules entre dans sa colonne SANS reduction (COUPE-MOTS-FOND-1).
  ///
  /// Une date (« 23/09/2026 »), une heure (« 18:12:00 »), un identifiant
  /// (« TEACHER-AS-000001 ») sont chacun un mot : ils ne se coupent jamais,
  /// et un en-tete ne se tronque plus (« Entr... »). Quand le texte agrandi
  /// ne tient pas, la collection passe en cartes, meme sur un bureau.
  @visibleForTesting
  static bool tientEnTableau<T>(
    BuildContext context, {
    required List<ColonneDonnees<T>> colonnes,
    required List<T> lignes,
    required double largeur,
    double reserve = 2 * AppSpacing.lg,
  }) {
    if (!largeur.isFinite || colonnes.isEmpty) return true;
    final TextScaler echelle = MediaQuery.textScalerOf(context);
    // Seul le texte AGRANDI fait replier le tableau : a la taille du theme,
    // la colonne trop etroite pour un identifiant le reduit, borne
    // (COUPE-MOTS-4), comme avant.
    if (echelle.scale(1) <= 1) return true;
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle enTete = textes.labelMedium ?? const TextStyle();
    final TextStyle cellule = textes.bodySmall ?? const TextStyle();
    // Le cache : un meme jeu de lignes (meme objet), a la meme echelle et a
    // la meme largeur, n'est mesure qu'une fois. Chaque mise en page du
    // LayoutBuilder (defilement, animation) relisait sinon chaque cellule par
    // TextPainter. Tout ce qui change la mesure entre dans la cle : colonnes
    // (titre, flex, chiffres tabulaires, rendu riche), styles, langue, sens.
    final Object cleCache = (
      echelle,
      largeur,
      reserve,
      enTete,
      cellule,
      DefaultTextStyle.of(context).style,
      Directionality.of(context),
      Localizations.maybeLocaleOf(context),
      <String>[
        for (final ColonneDonnees<T> c in colonnes)
          '${c.titre}\u0000${c.flex}\u0000${c.tabulaire}\u0000'
              '${c.rendu != null}',
      ].join('\u0001'),
    );
    final Map<Object, bool> cache = _cacheTientEnTableau[lignes] ??=
        <Object, bool>{};
    final bool? connu = cache[cleCache];
    if (connu != null) return connu;
    // Quelques largeurs seulement (redimensionnement) : le cache reste borne.
    if (cache.length >= _tailleCacheTientEnTableau) cache.clear();
    mesuresTientEnTableau++;
    return cache[cleCache] = _mesurerTableau<T>(
      context,
      colonnes: colonnes,
      lignes: lignes,
      largeur: largeur,
      reserve: reserve,
      echelle: echelle,
      enTete: enTete,
      cellule: cellule,
    );
  }

  /// Le cache de [tientEnTableau], par identite du jeu de lignes : il
  /// disparait avec la liste.
  static final Expando<Map<Object, bool>> _cacheTientEnTableau =
      Expando<Map<Object, bool>>('tientEnTableau');

  /// Le nombre d'entrees gardees par jeu de lignes.
  static const int _tailleCacheTientEnTableau = 8;

  /// Le nombre de mesures reelles de [tientEnTableau] (cache manque) : un
  /// test prouve qu'une seconde mise en page des memes lignes ne remesure pas.
  @visibleForTesting
  static int mesuresTientEnTableau = 0;

  /// La mesure de [tientEnTableau], sans cache.
  static bool _mesurerTableau<T>(
    BuildContext context, {
    required List<ColonneDonnees<T>> colonnes,
    required List<T> lignes,
    required double largeur,
    required double reserve,
    required TextScaler echelle,
    required TextStyle enTete,
    required TextStyle cellule,
  }) {
    final int flexTotal = colonnes.fold<int>(
      0,
      (int somme, ColonneDonnees<T> c) => somme + c.flex,
    );
    final double utile = largeur - reserve;
    for (final ColonneDonnees<T> colonne in colonnes) {
      final double place = utile * colonne.flex / flexTotal - AppSpacing.md;
      // Un rendu riche (une pastille) entoure son texte d'une marge.
      final double marge = colonne.rendu == null ? 0 : 2 * AppSpacing.md;
      if (largeurMotLePlusLong(context, colonne.titre, enTete, echelle) >
          place) {
        return false;
      }
      final Set<String> valeurs = <String>{
        for (final T ligne in lignes)
          identifiantsInsecables(colonne.texte(ligne)),
      };
      final TextStyle style = colonne.tabulaire
          ? AppTypography.tabulaire(cellule)
          : cellule;
      // Chaque valeur mesuree seule : le mot le plus long de la colonne est
      // le plus long de ses valeurs (aucune chaine jointe, garde DUREE-FOND-1).
      for (final String valeur in valeurs) {
        if (largeurMotLePlusLong(context, valeur, style, echelle) + marge >
            place) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_parTranches) {
      return _CollectionParTranches<T>(collection: this);
    }
    final bool tableau = enTableau(context);
    // JONCTION-LIGNES-1 : deux lignes de travail ont pose le meme besoin sous
    // deux noms ([defileAvecLaPage], ONGLETS-COUPE-1 ; [defileSeule] a faux,
    // FILTRES-1b). Un seul comportement : toutes les lignes a leur hauteur,
    // sans defileur propre.
    final bool enBloc = defileAvecLaPage || !defileSeule;

    Widget cartes() {
      final Widget liste = _Defilement<T>(
        enBloc: enBloc,
        lignes: lignes,
        piedDePage: piedDePage,
        cle: cle,
        espacement: AppSpacing.md,
        constructeur: (BuildContext contexte, T ligne) => _Carte<T>(
          colonnes: colonnes,
          ligne: ligne,
          onSelectionner: onSelectionner,
          selectionnee: estSelectionnee?.call(ligne) ?? false,
          selection: selection,
          actionsLigne: actionsLigne,
        ),
      );
      final Widget? pied = piedCollant;
      if (pied == null) return liste;
      return Column(
        mainAxisSize: enBloc ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(fit: enBloc ? FlexFit.loose : FlexFit.tight, child: liste),
          Ecart.vMd,
          pied,
        ],
      );
    }

    if (!tableau) return cartes();

    // COUPE-MOTS-FOND-1 : un tableau ou une colonne coupe un mot (texte
    // agrandi) se replie en cartes, comme sur une tablette.
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final _MiseEnPage mise = _MiseEnPage.de(
          contexte,
          avecSelection: selection != null,
          avecActions: actionsLigne != null,
          largeurActions: largeurActions,
        );
        return tientEnTableau<T>(
              contexte,
              colonnes: colonnes,
              lignes: lignes,
              largeur: contraintes.maxWidth,
              reserve: mise.reserveDebut + mise.reserveFin,
            )
            ? _tableau(contexte, enBloc, mise)
            : cartes();
      },
    );
  }

  Widget _tableau(BuildContext context, bool enBloc, _MiseEnPage mise) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final Widget corps = _Defilement<T>(
      enBloc: enBloc,
      lignes: lignes,
      piedDePage: piedDePage,
      cle: cle,
      espacement: 0,
      constructeur: (BuildContext contexte, T ligne) => _LigneTableau<T>(
        colonnes: colonnes,
        ligne: ligne,
        onSelectionner: onSelectionner,
        // Nul sans [estSelectionnee] : un tableau sans selection
        // n'annonce aucun etat « non selectionne ».
        selectionnee: estSelectionnee?.call(ligne),
        selection: selection,
        actionsLigne: actionsLigne,
        mise: mise,
      ),
    );

    // Le filet et l'arrondi sont portes par le bloc entier, et le decoupage par
    // un seul `ClipRRect` : arrondir separement les deux coins hauts de
    // l'en-tete et les deux coins bas du corps demanderait deux arrondis
    // partiels, donc deux valeurs de rayon a tenir synchrones pour rien.
    return DecoratedBox(
      decoration: palette.surfaceRaised.decoration(
        borderRadius: metriques.arrondi,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Column(
          mainAxisSize: enBloc ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _EnTeteTableau<T>(
              colonnes: colonnes,
              selection: selection,
              lignes: lignes,
              mise: mise,
            ),
            Flexible(fit: enBloc ? FlexFit.loose : FlexFit.tight, child: corps),
            if (piedCollant != null) _PiedTable(child: piedCollant!),
          ],
        ),
      ),
    );
  }
}

/// Le pied du cadre d'un tableau : un filet, puis le pied de la liste. Ne
/// defile pas avec les lignes.
class _PiedTable extends StatelessWidget {
  const _PiedTable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(top: palette.borderHairline.asBorderSide()),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: child,
      ),
    );
  }
}

/// La mise en page commune de l'en-tete et des lignes d'une table : ce que la
/// case, le menu et la cible tactile du mode fixent, une seule fois.
@immutable
class _MiseEnPage {
  const _MiseEnPage({
    required this.cible,
    required this.avecSelection,
    required this.avecActions,
    required this.largeurActions,
  });

  factory _MiseEnPage.de(
    BuildContext context, {
    required bool avecSelection,
    required bool avecActions,
    double? largeurActions,
  }) {
    final double cible = AppMetriques.of(context).cibleTactile;
    return _MiseEnPage(
      cible: cible,
      avecSelection: avecSelection,
      avecActions: avecActions,
      largeurActions: largeurActions ?? cible,
    );
  }

  /// La cible tactile du mode (48, 72 en Interface guidee).
  final double cible;

  /// La table porte une colonne de cases.
  final bool avecSelection;

  /// La table porte une colonne d'actions.
  final bool avecActions;

  /// La largeur de la colonne d'actions.
  final double largeurActions;

  /// Vrai quand la ligne porte une cible qui n'est pas la ligne (case, menu).
  bool get commandes => avecSelection || avecActions;

  /// La place gardee avant les cellules : la case (sa cible plus la marge du
  /// bord) ou la marge de la ligne.
  double get reserveDebut =>
      avecSelection ? AppSpacing.sm + cible : AppSpacing.lg;

  /// La place gardee apres les cellules : la colonne d'actions ou la marge de
  /// la ligne.
  double get reserveFin =>
      avecActions ? AppSpacing.sm + largeurActions : AppSpacing.lg;

  /// La hauteur mini d'une ligne : une cible tactile du mode, plus 8 quand une
  /// case ou un menu y pose sa cible (4 de chaque cote : la place de l'anneau
  /// de focus de 2 points, qui deborde de 4).
  double get hauteurLigne => commandes ? cible + AppSpacing.sm : cible;
}

/// La zone defilante, commune aux deux rendus.
class _Defilement<T> extends StatelessWidget {
  const _Defilement({
    required this.lignes,
    required this.constructeur,
    required this.espacement,
    required this.enBloc,
    this.piedDePage,
    this.cle,
  });

  /// Vrai : toutes les lignes sont posees, sans defilement propre (voir
  /// [DataCollection.defileAvecLaPage]).
  final bool enBloc;

  final List<T> lignes;
  final Widget Function(BuildContext context, T ligne) constructeur;
  final double espacement;
  final Widget? piedDePage;
  final Key Function(T ligne)? cle;

  @override
  Widget build(BuildContext context) {
    final int total = lignes.length + (piedDePage == null ? 0 : 1);

    return ListView.builder(
      shrinkWrap: enBloc,
      primary: enBloc ? false : null,
      physics: enBloc ? const NeverScrollableScrollPhysics() : null,
      padding: enBloc ? EdgeInsets.zero : null,
      itemCount: total,
      itemBuilder: (BuildContext contexte, int index) {
        if (index >= lignes.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: piedDePage,
          );
        }
        final T ligne = lignes[index];
        return Padding(
          key: cle?.call(ligne),
          padding: EdgeInsets.only(
            bottom: index == lignes.length - 1 ? 0 : espacement,
          ),
          child: constructeur(contexte, ligne),
        );
      },
    );
  }
}

/// L'en-tete de colonnes : surface enfoncee, collee en haut du tableau.
///
/// Les titres ne sont pas lus (chaque cellule porte deja le titre de sa colonne
/// dans son libelle) ; seules les commandes le sont : la case « cocher la
/// page » et les titres triables.
class _EnTeteTableau<T> extends StatelessWidget {
  const _EnTeteTableau({
    required this.colonnes,
    required this.selection,
    required this.lignes,
    required this.mise,
  });

  final List<ColonneDonnees<T>> colonnes;
  final SelectionCollection<T>? selection;
  final List<T> lignes;
  final _MiseEnPage mise;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    final bool triable = colonnes.any((ColonneDonnees<T> c) => c.tri != null);
    // Une commande (case, titre triable) est une cible : l'en-tete en a au moins
    // la hauteur. Sans commande, il garde la hauteur de son texte.
    final double hauteurMini = selection != null || triable ? mise.cible : 0;

    final Widget cellules = Row(
      children: <Widget>[
        for (final ColonneDonnees<T> colonne in colonnes)
          Expanded(
            flex: colonne.flex,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: colonne.tri == null
                  // COUPE-MOTS-FOND-1 : l'en-tete passe a la ligne entre ses
                  // mots, jamais tronque (« Entr... ») ; la collection
                  // garantit que chacun de ses mots tient
                  // ([DataCollection.tientEnTableau]).
                  ? ExcludeSemantics(
                      child: TexteSansCoupure(colonne.titre, style: style),
                    )
                  : _TitreTriable(
                      titre: colonne.titre,
                      tri: colonne.tri!,
                      style: style,
                    ),
            ),
          ),
      ],
    );

    return DecoratedBox(
      // Aucun arrondi ici : le `ClipRRect` du bloc s'en charge, et l'en-tete se
      // contente d'etre le seul plan enfonce du tableau.
      decoration: BoxDecoration(
        color: palette.surfaceSunken.background,
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: hauteurMini),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: mise.reserveDebut,
                  end: mise.reserveFin,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                ),
                child: cellules,
              ),
            ),
          ),
          if (selection != null)
            PositionedDirectional(
              start: AppSpacing.sm,
              top: 0,
              bottom: 0,
              width: mise.cible,
              child: Center(
                child: Semantics(
                  container: true,
                  child: _CaseEnTete<T>(selection: selection!, lignes: lignes),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// La case d'en-tete : « cocher la page », a trois etats.
class _CaseEnTete<T> extends StatelessWidget {
  const _CaseEnTete({required this.selection, required this.lignes});

  final SelectionCollection<T> selection;
  final List<T> lignes;

  @override
  Widget build(BuildContext context) {
    // Page vide, ou aucune ligne qu'on puisse retenir : rien a cocher, donc pas
    // de case (jamais une case grisee).
    if (!lignes.any((T l) => selection.estCochable?.call(l) ?? true)) {
      return const SizedBox.shrink();
    }
    return CaseACocher(
      valeur: selection.etatPage(lignes),
      libelle: t.commun.listes.cocherPage,
      onChange: selection.onBasculerPage,
    );
  }
}

/// Le titre d'une colonne triable : un bouton, avec le sens du tri en cours.
class _TitreTriable extends StatelessWidget {
  const _TitreTriable({
    required this.titre,
    required this.tri,
    required this.style,
  });

  final String titre;
  final TriColonne tri;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final SensTri? sens = tri.sens;
    final String libelle = switch (sens) {
      null => t.commun.listes.trierPar(colonne: titre),
      SensTri.croissant => t.commun.listes.trierParCroissant(colonne: titre),
      SensTri.decroissant => t.commun.listes.trierParDecroissant(
        colonne: titre,
      ),
    };
    final AppIcon icone = switch (sens) {
      null => AppIcons.triNeutre,
      SensTri.croissant => AppIcons.triCroissant,
      SensTri.decroissant => AppIcons.triDecroissant,
    };
    return Pressable.selon(
      onPress: tri.onTrier,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiXs,
      constructeur: (BuildContext contexte, EtatPression etat) {
        // La colonne triee se dit par la fleche ET par l'encre (jamais la
        // couleur seule) ; une colonne triable au repos montre deux fleches
        // douces.
        final AppInkColor encre = sens != null || etat.survole
            ? palette.inkStrong
            : palette.inkMuted;
        return ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: TexteSansCoupure(titre, style: encre.applyTo(style)),
              ),
              Ecart.hXs,
              Icon(
                icone.repos,
                size: AppSpacing.lg,
                color: (sens == null ? palette.inkFaint : palette.inkAccent)
                    .asIconTheme()
                    .color,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Une ligne du tableau dense.
///
/// Trois couches, dans cet ordre : **la ligne** (sa cible tactile, qui ouvre),
/// puis **la case**, puis **le menu**. La case et le menu sont posees PAR-DESSUS
/// la ligne, pas dedans : un clic dessus ne touche pas la ligne, la ligne et le
/// menu sont deux arrets de tabulation, et l'arbre d'accessibilite ne contient
/// jamais un bouton dans un bouton.
class _LigneTableau<T> extends StatelessWidget {
  const _LigneTableau({
    required this.colonnes,
    required this.ligne,
    required this.mise,
    this.onSelectionner,
    this.selectionnee,
    this.selection,
    this.actionsLigne,
  });

  final List<ColonneDonnees<T>> colonnes;
  final T ligne;
  final _MiseEnPage mise;
  final void Function(T ligne)? onSelectionner;

  /// Nul quand le tableau n'a pas de selection : la ligne ne porte alors
  /// aucun etat `selected` (ni vrai ni faux) dans l'arbre semantique.
  final bool? selectionnee;

  final SelectionCollection<T>? selection;
  final Widget Function(BuildContext context, T ligne)? actionsLigne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base = textes.bodySmall ?? const TextStyle();
    final bool cochee = selection?.estCochee(ligne) ?? false;
    final bool cochable = selection?.estCochable?.call(ligne) ?? true;

    // Les cellules sont centrees dans la hauteur de la ligne : une ligne de
    // texte seule ne colle pas en haut d'une ligne de 56.
    final Widget cellules = Row(
      children: <Widget>[
        for (final ColonneDonnees<T> colonne in colonnes)
          Expanded(
            flex: colonne.flex,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: _Cellule<T>(
                colonne: colonne,
                ligne: ligne,
                style: colonne.tabulaire ? AppTypography.tabulaire(base) : base,
              ),
            ),
          ),
      ],
    );

    Widget contenu(Color? fond) {
      final Widget ligneCentree = ConstrainedBox(
        constraints: BoxConstraints(minHeight: mise.hauteurLigne),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: mise.reserveDebut,
              end: mise.reserveFin,
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: cellules,
          ),
        ),
      );
      return fond == null
          ? ligneCentree
          : ColoredBox(color: fond, child: ligneCentree);
    }

    // Au survol, au focus et sous le doigt : un calque doux de l'accent sur
    // toute la ligne (on voit quelle ligne va s'ouvrir). Jamais sans cible.
    final Widget laLigne = onSelectionner == null
        ? contenu(null)
        : Pressable.selon(
            onPress: () => onSelectionner!(ligne),
            respecterCibleTactile: false,
            constructeur: (BuildContext _, EtatPression etat) => contenu(
              etat.presse
                  ? palette.calqueInteraction(presse: true)
                  : etat.survole
                  ? palette.calqueInteraction()
                  : null,
            ),
          );

    final Widget? menu = actionsLigne?.call(context, ligne);

    // Au clavier : la case, puis la ligne, puis le menu (le sens de lecture, la
    // case avant ce qu'elle retient). Sans cet ordre, la ligne, qui couvre toute
    // la hauteur, passait avant sa propre case.
    Widget enOrdre(double rang, Widget enfant) => mise.commandes
        ? FocusTraversalOrder(order: NumericFocusOrder(rang), child: enfant)
        : enfant;

    final Widget empilee = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        // Un noeud a part quand la ligne porte des commandes : la case et le
        // menu restent deux noeuds distincts du lecteur d'ecran.
        enOrdre(
          2,
          Semantics(
            container: mise.commandes,
            selected: selectionnee,
            child: laLigne,
          ),
        ),
        if (selection != null && cochable)
          PositionedDirectional(
            start: AppSpacing.sm,
            top: 0,
            bottom: 0,
            width: mise.cible,
            child: Center(
              child: enOrdre(
                1,
                Semantics(
                  container: true,
                  child: CaseACocher(
                    valeur: cochee,
                    libelle: t.commun.listes.cocherLigne(
                      objet: selection!.libelleLigne(ligne),
                    ),
                    onChange: (bool _) => selection!.onBasculer(ligne),
                  ),
                ),
              ),
            ),
          ),
        if (menu != null)
          PositionedDirectional(
            end: AppSpacing.sm,
            top: 0,
            bottom: 0,
            width: mise.largeurActions,
            child: Center(
              child: enOrdre(3, Semantics(container: true, child: menu)),
            ),
          ),
      ],
    );
    // Le groupe n'ordonne que cette ligne : d'une ligne a l'autre, le sens de
    // lecture reste celui de la page.
    final Widget corps = mise.commandes
        ? FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: empilee)
        : empilee;

    return DecoratedBox(
      // La ligne choisie : fond doux et contour d'accent de 2, comme
      // `AppCard.selectionnee` (jamais la couleur seule). Une ligne cochee :
      // le fond doux seul, sa case dit le reste.
      decoration: selectionnee ?? false
          ? BoxDecoration(
              color: palette.washAccent.background,
              border: Border.fromBorderSide(
                palette.inkAccent.asBorderSide(width: Pressable.epaisseurFocus),
              ),
            )
          : BoxDecoration(
              color: cochee ? palette.washAccent.background : null,
              border: Border(bottom: palette.borderHairline.asBorderSide()),
            ),
      child: corps,
    );
  }
}

/// Une cellule, avec le titre de sa colonne dans son libelle parle.
///
/// Flutter ne sait pas associer un en-tete de tableau a ses cellules comme le
/// fait un `<th>` : sans ce libelle, un lecteur d'ecran enoncerait une suite de
/// valeurs sans dire de quoi elles sont les valeurs.
class _Cellule<T> extends StatelessWidget {
  const _Cellule({
    required this.colonne,
    required this.ligne,
    required this.style,
  });

  final ColonneDonnees<T> colonne;
  final T ligne;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget Function(BuildContext, T)? rendu = colonne.rendu;
    if (rendu != null) {
      // Au debut de la cellule, a sa largeur naturelle : une pastille posee sans
      // cet alignement s'etirait sur toute la colonne (138 a 164 points) et
      // devenait une barre (LISTES-1, relecture visuelle K-04).
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: rendu(context, ligne),
      );
    }
    // DUREE-INSECABLE-5 : la valeur suit le titre de la colonne dans le
    // libelle parle ; une valeur ancree pour s'afficher seule (« 12 jours »,
    // marque U+200E en tete) y perd son ancre ([sansAncre]), qui n'a pas a
    // se trouver au milieu d'un libelle. Le texte affiche, seul dans sa
    // cellule, la garde.
    return Semantics(
      label: '${colonne.titre} : ${sansAncre(colonne.texte(ligne))}',
      excludeSemantics: true,
      // COUPE-MOTS-4 : un mot plus long que sa colonne (un identifiant)
      // reduit son echelle au lieu d'etre coupe. COUPE-MOTS-FOND-1 : le
      // tableau n'est rendu que si chaque mot tient sans reduction
      // ([DataCollection.tientEnTableau]) ; la reduction reste un filet.
      child: _TexteCollection(colonne.texte(ligne), style: style),
    );
  }
}

/// Une ligne repliee en carte.
class _Carte<T> extends StatelessWidget {
  const _Carte({
    required this.colonnes,
    required this.ligne,
    this.onSelectionner,
    this.selectionnee = false,
    this.selection,
    this.actionsLigne,
  });

  final List<ColonneDonnees<T>> colonnes;
  final T ligne;
  final void Function(T ligne)? onSelectionner;
  final bool selectionnee;
  final SelectionCollection<T>? selection;
  final Widget Function(BuildContext context, T ligne)? actionsLigne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Une colonne a rendu riche (une pastille d'etat) garde sa pastille en
    // carte : un etat noye dans une ligne de texte ne se lit plus (LISTES-1,
    // relecture visuelle K-06). Un nombre seul (« 2 ») dit de quoi il est le
    // nombre : le resume ci-dessous lit des colonnes qui portent deja ce titre.
    final Iterable<ColonneDonnees<T>> pastilles = colonnes.where(
      (ColonneDonnees<T> c) =>
          c.role == RoleColonne.secondaire && c.rendu != null,
    );
    final Iterable<ColonneDonnees<T>> secondaires = colonnes
        .where(
          (ColonneDonnees<T> c) =>
              c.role == RoleColonne.secondaire && c.rendu == null,
        )
        .map(_avecTitreDuNombre<T>);
    final Iterable<ColonneDonnees<T>> aPart = colonnes.where(
      (ColonneDonnees<T> c) => c.role == RoleColonne.aPart,
    );
    // Ecrit a la main plutot qu'avec `firstOrNull` : cette extension vient de
    // `package:collection`, que ce fichier n'a aucune autre raison d'importer.
    ColonneDonnees<T>? titre;
    for (final ColonneDonnees<T> colonne in colonnes) {
      if (colonne.role == RoleColonne.identifiante) {
        titre = colonne;
        break;
      }
    }

    // Le point median, et non un tiret : le tiret cadratin est refuse par
    // `tool/verifier_jetons.dart`, et le tiret court se confond avec un
    // signe moins dans une colonne de chiffres. DUREE-INSECABLE-4 :
    // [enchainer] ne garde l'ancre de sens (U+200E) qu'en tete de la ligne.
    //
    // Relecture de COUPE-MOTS-FOND-1 : une valeur deja lue en tete de carte
    // (titre, ou sous-titre quand l'identifiant n'y tient pas : « Personne »
    // puis « TEACHER-AS-000002 ») ne se repete pas en tete du resume.
    final String? enTete = titre != null && titre.rendu == null
        ? identifiantsInsecables(titre.texte(ligne)).trim()
        : null;
    final String resume = enchainer(
      secondaires
          .map((ColonneDonnees<T> c) => c.texte(ligne))
          .where(
            (String v) =>
                enTete == null || identifiantsInsecables(v).trim() != enTete,
          ),
      ' · ',
    );

    final bool cochee = selection?.estCochee(ligne) ?? false;
    final bool cochable = selection?.estCochable?.call(ligne) ?? true;
    final Widget? menu = actionsLigne?.call(context, ligne);
    final double cible = AppMetriques.of(context).cibleTactile;
    final bool commandes = selection != null || menu != null;

    // La case et le menu sont **dans** la carte, en tete (ils pendaient a ses
    // bords et la reduisaient a 262 de large sur 390) : la rangee du titre leur
    // garde leur place, le reste de la carte garde toute sa largeur.
    final Widget? titreCarte = titre == null
        ? null
        : (titre.rendu?.call(context, ligne) ??
              _TitreCarte<T>(colonne: titre, ligne: ligne));
    final Widget? enTeteCarte = commandes
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: cible),
            child: Row(
              children: <Widget>[
                if (selection != null) SizedBox(width: cible),
                Expanded(child: titreCarte ?? const SizedBox.shrink()),
                if (menu != null) SizedBox(width: cible),
              ],
            ),
          )
        : titreCarte;

    // La carte entiere se lit comme un seul element : sans ce regroupement, un
    // lecteur d'ecran enoncerait quatre fragments sans lien entre eux.
    final Widget carte = MergeSemantics(
      child: AppCard(
        selectionnee: selectionnee || cochee,
        onPress: onSelectionner == null ? null : () => onSelectionner!(ligne),
        marge: commandes ? _margeCarteCommandes : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (enTeteCarte != null) ...<Widget>[enTeteCarte, Ecart.vSm],
            if (pastilles.isNotEmpty) ...<Widget>[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final ColonneDonnees<T> c in pastilles)
                    c.rendu!(context, ligne),
                ],
              ),
              if (resume.isNotEmpty) Ecart.vSm,
            ],
            if (resume.isNotEmpty)
              _TexteCollection(
                resume,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            for (final ColonneDonnees<T> colonne in aPart)
              if (colonne.rendreMemeSiTexteVide ||
                  colonne.texte(ligne).isNotEmpty) ...<Widget>[
                Ecart.vSm,
                colonne.rendu?.call(context, ligne) ??
                    _TexteCollection(
                      colonne.texte(ligne),
                      style: palette.inkMuted.applyTo(
                        AppTypography.tabulaire(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ),
              ],
          ],
        ),
      ),
    );

    if (!commandes) return carte;

    // Superposees a la carte, **hors de sa cible** (jamais un bouton dans un
    // bouton), dans l'ordre de lecture : la case, puis le menu.
    const double decalage = _margeCarteCommandes + 1;
    return Stack(
      children: <Widget>[
        carte,
        if (selection != null && cochable)
          PositionedDirectional(
            start: decalage,
            top: decalage,
            child: CaseACocher(
              valeur: cochee,
              libelle: t.commun.listes.cocherLigne(
                objet: selection!.libelleLigne(ligne),
              ),
              onChange: (bool _) => selection!.onBasculer(ligne),
            ),
          ),
        if (menu != null)
          PositionedDirectional(end: decalage, top: decalage, child: menu),
      ],
    );
  }

  /// La marge d'une carte qui porte une case ou un menu : serree, pour que la
  /// liste reste le contenu.
  static const double _margeCarteCommandes = AppSpacing.md;
}

/// [colonne], dont la valeur est precedee de son titre quand c'est un nombre
/// seul (« Contrats : 2 ») ; toute autre valeur est rendue telle quelle.
ColonneDonnees<T> _avecTitreDuNombre<T>(ColonneDonnees<T> colonne) =>
    ColonneDonnees<T>(
      titre: colonne.titre,
      role: colonne.role,
      flex: colonne.flex,
      tabulaire: colonne.tabulaire,
      rendu: colonne.rendu,
      tri: colonne.tri,
      texte: (T ligne) {
        final String v = colonne.texte(ligne);
        // [enchainer] : l'ancre de sens de la valeur n'a pas a se trouver
        // derriere le titre.
        return _nombreSeul.hasMatch(v)
            ? enchainer(<String>[colonne.titre, v], ' : ')
            : v;
      },
    );

/// Un nombre seul, avec l'ancre de sens eventuelle : « 2 », « ‎12 ».
final RegExp _nombreSeul = RegExp('^\\u200E?\\d+\$');

/// Un identifiant technique a traits d'union ordinaires, dans un texte :
/// des segments en capitales et chiffres, un chiffre au moins
/// (« TEACHER-RB-000001 »).
final RegExp _identifiantATraits = RegExp(
  r'(?<![A-Za-z0-9])(?=[A-Z0-9-]*[0-9])[A-Z0-9]+(?:-[A-Z0-9]+)+(?![A-Za-z0-9])',
);

/// [texte] tel que la collection l'affiche : chaque identifiant technique
/// qu'il contient (« Rachid · TEACHER-RB-000001 ») prend des traits d'union
/// insecables (U+2011), pour passer entier a la ligne au lieu de se couper
/// a son trait (COUPE-MOTS-FOND-1, comme `identifiantInsecable` de
/// COUPE-MOTS-4, mais pour tous les appelants). Les mots composes en
/// minuscules (« Al-Badr ») ne sont pas touches.
@visibleForTesting
String identifiantsInsecables(String texte) => texte.replaceAllMapped(
  _identifiantATraits,
  (Match m) => m.group(0)!.replaceAll('-', '\u2011'),
);

/// Le titre d'une carte (COUPE-MOTS-FOND-1, point 2).
///
/// Un titre qui tient a la taille des titres de carte (`titleMedium`, a
/// l'echelle de l'appareil) est rendu tel quel. Un titre fait d'un seul mot
/// qui n'y tient pas (un identifiant technique « GUARDIAN-FD-000014 » a
/// traits insecables, a 320 px texte x2) n'est ni coupe a ses traits ni
/// reduit sous la taille des autres titres : l'en-tete de sa colonne
/// (« Personne ») reste le titre, a la taille des titres, et l'identifiant
/// passe en sous-titre, entier, insecable, au style des valeurs tabulaires.
/// La hierarchie est gardee : chaque carte a un titre a la meme taille.
class _TitreCarte<T> extends StatelessWidget {
  const _TitreCarte({required this.colonne, required this.ligne});

  final ColonneDonnees<T> colonne;
  final T ligne;

  /// Vrai quand [texte] est un seul mot (aucune espace ou il puisse passer
  /// a la ligne) plus large que [largeur] a la taille de [style].
  static bool motSeulTropLong(
    BuildContext context,
    String texte,
    TextStyle style,
    double largeur,
  ) {
    if (!largeur.isFinite) return false;
    if (texte.trim().contains(RegExp(r'[\s\u200B]'))) return false;
    return largeurMotLePlusLong(
          context,
          texte,
          style,
          MediaQuery.textScalerOf(context),
        ) >
        largeur;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleTitre = textes.titleMedium ?? const TextStyle();
    final String texte = colonne.texte(ligne);
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) {
        if (!motSeulTropLong(contexte, texte, styleTitre, c.maxWidth)) {
          return _TexteCollection(texte, style: styleTitre);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // L'en-tete est lu dans la voix de la carte avec la valeur.
            TexteSansCoupure(colonne.titre, style: styleTitre),
            Ecart.vXs,
            _TexteCollection(
              texte,
              style: AppTypography.tabulaire(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Un texte de la collection (cellule, titre, ligne de carte) : un
/// [TexteSansCoupure] dont les identifiants techniques ne se coupent jamais
/// a leurs traits (COUPE-MOTS-FOND-1).
///
/// Le texte reste celui de la donnee tant que la ligne ne passe pas a un
/// trait d'identifiant ; seulement quand elle s'y couperait (« Rachid ·
/// TEACHER-RB- / 000001 »), les traits de l'identifiant deviennent
/// insecables ([identifiantsInsecables]) et il passe entier a la ligne. Le
/// lecteur d'ecran lit toujours le texte d'origine.
class _TexteCollection extends StatelessWidget {
  const _TexteCollection(this.texte, {required this.style});

  final String texte;
  final TextStyle style;

  /// Vrai quand, pose a [largeur], [texte] passe a la ligne au milieu d'un
  /// identifiant.
  static bool _coupeUnIdentifiant(
    BuildContext context,
    String texte,
    TextStyle style,
    double largeur,
  ) {
    if (!largeur.isFinite) return false;
    final List<RegExpMatch> ids = _identifiantATraits
        .allMatches(texte)
        .toList();
    if (ids.isEmpty) return false;
    final TextPainter peintre = TextPainter(
      text: TextSpan(
        text: texte,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: largeur);
    try {
      for (final RegExpMatch m in ids) {
        final int debut = peintre
            .getLineBoundary(TextPosition(offset: m.start))
            .end;
        if (debut < m.end) return true;
      }
      return false;
    } finally {
      peintre.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_identifiantATraits.hasMatch(texte)) {
      return TexteSansCoupure(texte, style: style);
    }
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) =>
          _coupeUnIdentifiant(contexte, texte, style, c.maxWidth)
          ? Semantics(
              label: texte,
              excludeSemantics: true,
              child: TexteSansCoupure(
                identifiantsInsecables(texte),
                style: style,
              ),
            )
          : TexteSansCoupure(texte, style: style),
    );
  }
}

/// La place d'une zone qui porte une [DataCollection] dans la colonne d'une
/// page : **etiree** (`Expanded`) quand la collection defile seule (tableau,
/// en-tete colle), **a sa hauteur** quand elle defile avec la page (cartes,
/// voir [DataCollection.defileAvecLaPage]).
///
/// A poser directement dans un `Column`, la ou la page posait un `Expanded`.
class PlaceCollection extends StatelessWidget {
  /// Cree la place.
  const PlaceCollection({required this.child, super.key});

  /// La zone : la collection, ou ce qui la contient.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      DataCollection.enTableau(context) ? Expanded(child: child) : child;
}

/// LISTES-2 : la collection rendue par tranches (`CustomScrollView`) : la tete
/// de la page quand elle est prise, la [DataCollection.tete], puis le tableau
/// (en-tete de colonnes colle) ou les lignes, puis le pied. Rien d'autre ne
/// reste fixe.
class _CollectionParTranches<T> extends StatefulWidget {
  const _CollectionParTranches({required this.collection});

  final DataCollection<T> collection;

  @override
  State<_CollectionParTranches<T>> createState() =>
      _CollectionParTranchesEtat<T>();
}

class _CollectionParTranchesEtat<T> extends State<_CollectionParTranches<T>> {
  /// Le relais de la page ou la collection s'est declaree preneuse.
  RelaisTetePage? _relais;
  Widget? _tetePage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TetePageConfiee? page = widget.collection.prendTeteDePage
        ? TetePageConfiee.de(context)
        : null;
    final RelaisTetePage? relais = page?.relais;
    if (!identical(relais, _relais)) {
      _relais?.rendre(this);
      _relais = relais?..prendre(this);
    }
    _tetePage = page != null && identical(page.titulaire, this)
        ? page.tete
        : null;
  }

  @override
  void dispose() {
    _relais?.rendre(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DataCollection<T> c = widget.collection;
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final _MiseEnPage mise = _MiseEnPage.de(
          contexte,
          avecSelection: c.selection != null,
          avecActions: c.actionsLigne != null,
          largeurActions: c.largeurActions,
        );
        final bool tableau =
            DataCollection.enTableau(contexte) &&
            DataCollection.tientEnTableau<T>(
              contexte,
              colonnes: c.colonnes,
              lignes: c.lignes,
              largeur: contraintes.maxWidth,
              reserve: mise.reserveDebut + mise.reserveFin,
            );
        final AppPalette palette = AppPalette.of(contexte);
        final AppMetriques metriques = AppMetriques.of(contexte);
        final BoxDecoration cadre = palette.surfaceRaised.decoration(
          borderRadius: metriques.arrondi,
          side: palette.borderHairline.asBorderSide(),
        );
        final List<Widget> tranches = <Widget>[
          if (_tetePage != null) SliverToBoxAdapter(child: _tetePage),
          if (c.tete != null) SliverToBoxAdapter(child: c.tete),
        ];
        Widget ligneDeTable(BuildContext ctx, int i) => KeyedSubtree(
          key: c.cle?.call(c.lignes[i]),
          child: _LigneTableau<T>(
            colonnes: c.colonnes,
            ligne: c.lignes[i],
            onSelectionner: c.onSelectionner,
            selectionnee: c.estSelectionnee?.call(c.lignes[i]),
            selection: c.selection,
            actionsLigne: c.actionsLigne,
            mise: mise,
          ),
        );
        if (tableau) {
          tranches.add(
            DecoratedSliver(
              decoration: cadre,
              sliver: SliverMainAxisGroup(
                slivers: <Widget>[
                  // La seule rangee collee : sans ses en-tetes, une colonne
                  // ne se lit plus.
                  PinnedHeaderSliver(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: metriques.arrondi.topLeft,
                        topRight: metriques.arrondi.topRight,
                      ),
                      child: _EnTeteTableau<T>(
                        colonnes: c.colonnes,
                        selection: c.selection,
                        lignes: c.lignes,
                        mise: mise,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: c.lignes.length,
                    itemBuilder: ligneDeTable,
                  ),
                  if (c.piedCollant != null)
                    SliverToBoxAdapter(
                      child: _PiedTable(child: c.piedCollant!),
                    ),
                ],
              ),
            ),
          );
        } else if (c.densiteTelephone) {
          tranches
            ..add(
              DecoratedSliver(
                decoration: cadre,
                sliver: SliverList.builder(
                  itemCount: c.lignes.length,
                  itemBuilder: (BuildContext ctx, int i) => KeyedSubtree(
                    key: c.cle?.call(c.lignes[i]),
                    child: _LigneDense<T>(
                      colonnes: c.colonnes,
                      ligne: c.lignes[i],
                      premiere: i == 0,
                      onSelectionner: c.onSelectionner,
                      selection: c.selection,
                      actionsLigne: c.actionsLigne,
                      mise: mise,
                    ),
                  ),
                ),
              ),
            )
            ..addAll(<Widget>[
              if (c.piedCollant != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: c.piedCollant,
                  ),
                ),
            ]);
        } else {
          tranches.addAll(<Widget>[
            SliverList.separated(
              itemCount: c.lignes.length,
              separatorBuilder: (BuildContext _, int _) => Ecart.vMd,
              itemBuilder: (BuildContext ctx, int i) => KeyedSubtree(
                key: c.cle?.call(c.lignes[i]),
                child: _Carte<T>(
                  colonnes: c.colonnes,
                  ligne: c.lignes[i],
                  onSelectionner: c.onSelectionner,
                  selectionnee: c.estSelectionnee?.call(c.lignes[i]) ?? false,
                  selection: c.selection,
                  actionsLigne: c.actionsLigne,
                ),
              ),
            ),
            if (c.piedCollant != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: c.piedCollant,
                ),
              ),
          ]);
        }
        if (c.piedDePage != null) {
          tranches.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xl),
                child: c.piedDePage,
              ),
            ),
          );
        }
        // La respiration de bas de liste.
        tranches.add(const SliverToBoxAdapter(child: Ecart.vXl));
        return CustomScrollView(slivers: tranches);
      },
    );
  }
}

/// LISTES-2 : une ligne dense de telephone ([DataCollection.densiteTelephone]).
class _LigneDense<T> extends StatelessWidget {
  const _LigneDense({
    required this.colonnes,
    required this.ligne,
    required this.premiere,
    required this.mise,
    this.onSelectionner,
    this.selection,
    this.actionsLigne,
  });

  final List<ColonneDonnees<T>> colonnes;
  final T ligne;
  final bool premiere;
  final _MiseEnPage mise;
  final void Function(T ligne)? onSelectionner;
  final SelectionCollection<T>? selection;
  final Widget Function(BuildContext context, T ligne)? actionsLigne;

  /// La hauteur mini d'une ligne dense en interface standard : deux lignes de
  /// texte et leurs marges.
  static const double _hauteurStandard = AppSpacing.respiration;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    ColonneDonnees<T>? titre;
    for (final ColonneDonnees<T> colonne in colonnes) {
      if (colonne.role == RoleColonne.identifiante) {
        titre = colonne;
        break;
      }
    }
    // Une pastille ne dit que l'exception : vide, elle n'est pas posee.
    final List<ColonneDonnees<T>> pastilles = <ColonneDonnees<T>>[
      for (final ColonneDonnees<T> c in colonnes)
        if (c != titre &&
            c.role == RoleColonne.secondaire &&
            c.rendu != null &&
            c.texte(ligne).isNotEmpty)
          c,
    ];
    // Une colonne a part a rendu riche (le pays et son drapeau, ENS-PAYS-1)
    // ouvre la ligne secondaire avec son rendu, jamais son seul texte.
    final List<ColonneDonnees<T>> riches = <ColonneDonnees<T>>[
      for (final ColonneDonnees<T> c in colonnes)
        if (c != titre &&
            c.ligneDense &&
            c.role == RoleColonne.aPart &&
            c.rendu != null &&
            c.texte(ligne).isNotEmpty)
          c,
    ];
    final String? enTete = titre == null
        ? null
        : identifiantsInsecables(titre.texte(ligne)).trim();
    final String resume = enchainer(
      colonnes
          .where(
            (ColonneDonnees<T> c) =>
                c != titre &&
                c.ligneDense &&
                !riches.contains(c) &&
                !(c.role == RoleColonne.secondaire && c.rendu != null),
          )
          .map(_avecTitreDuNombre<T>)
          .map((ColonneDonnees<T> c) => c.texte(ligne))
          .where(
            (String v) =>
                v.trim().isNotEmpty &&
                (enTete == null || identifiantsInsecables(v).trim() != enTete),
          ),
      ' · ',
    );
    final bool cochee = selection?.estCochee(ligne) ?? false;
    final bool cochable = selection?.estCochable?.call(ligne) ?? true;
    final Widget? menu = actionsLigne?.call(context, ligne);
    final double hauteur = math.max(_hauteurStandard, mise.hauteurLigne);
    // Texte agrandi (au-dela de 130 %) : la pastille passe sous le texte, elle
    // ne tiendrait plus a cote du nom (320 x2).
    final bool pastillesDessous =
        MediaQuery.textScalerOf(context).scale(1) > 1.3;

    final Widget texte = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (titre != null)
            titre.rendu?.call(context, ligne) ??
                _TexteCollection(
                  titre.texte(ligne),
                  style: textes.titleSmall ?? const TextStyle(),
                ),
          // Une seule ligne : le detail se lit en entier par le lecteur
          // d'ecran (le texte complet reste dans la semantique) et au bureau.
          // Texte agrandi : le rendu riche prend sa ligne, entier (un nom de
          // pays ne se coupe pas).
          if (pastillesDessous)
            for (final ColonneDonnees<T> c in riches) c.rendu!(context, ligne),
          if ((riches.isNotEmpty && !pastillesDessous) || resume.isNotEmpty)
            Row(
              children: <Widget>[
                if (!pastillesDessous)
                  for (final ColonneDonnees<T> c in riches) ...<Widget>[
                    Flexible(child: c.rendu!(context, ligne)),
                    Ecart.hSm,
                  ],
                if (resume.isNotEmpty)
                  Expanded(
                    child: Text(
                      resume,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.inkMuted.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ),
              ],
            ),
          if (pastillesDessous)
            for (final ColonneDonnees<T> c in pastilles) ...<Widget>[
              Ecart.vXs,
              c.rendu!(context, ligne),
            ],
        ],
      ),
    );

    Widget contenu(Color? fond) {
      final Widget rangee = ConstrainedBox(
        constraints: BoxConstraints(minHeight: hauteur),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: selection != null ? mise.reserveDebut : AppSpacing.lg,
            end: menu != null ? mise.reserveFin : AppSpacing.lg,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: texte),
              if (!pastillesDessous)
                for (final ColonneDonnees<T> c in pastilles) ...<Widget>[
                  Ecart.hSm,
                  c.rendu!(context, ligne),
                ],
            ],
          ),
        ),
      );
      return fond == null ? rangee : ColoredBox(color: fond, child: rangee);
    }

    final Widget laLigne = onSelectionner == null
        ? contenu(null)
        : Pressable.selon(
            onPress: () => onSelectionner!(ligne),
            respecterCibleTactile: false,
            constructeur: (BuildContext _, EtatPression etat) => contenu(
              etat.presse
                  ? palette.calqueInteraction(presse: true)
                  : etat.survole
                  ? palette.calqueInteraction()
                  : null,
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cochee ? palette.washAccent.background : null,
        border: premiere
            ? null
            : Border(top: palette.borderHairline.asBorderSide()),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          laLigne,
          if (selection != null && cochable)
            PositionedDirectional(
              start: AppSpacing.sm,
              top: 0,
              bottom: 0,
              width: mise.cible,
              child: Center(
                child: CaseACocher(
                  valeur: cochee,
                  libelle: t.commun.listes.cocherLigne(
                    objet: selection!.libelleLigne(ligne),
                  ),
                  onChange: (bool _) => selection!.onBasculer(ligne),
                ),
              ),
            ),
          if (menu != null)
            PositionedDirectional(
              end: AppSpacing.sm,
              top: 0,
              bottom: 0,
              width: mise.largeurActions,
              child: Center(child: menu),
            ),
        ],
      ),
    );
  }
}
