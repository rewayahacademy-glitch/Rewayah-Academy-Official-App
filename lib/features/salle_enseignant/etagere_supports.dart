// Lot SUPPORTS-ETAGERE (directeur, 11/11/2026 ; CAHIER-SALLE §7) :
// l'etagere des supports de la salle, leur fiche, « Afficher » et
// « Partager ».
//
// Le support est generique : le Coran n'est qu'un support parmi d'autres. Ce
// fichier ne connait aucun support en particulier ; chacun arrive avec sa
// couverture, ce qu'il sait faire (se lire seul : [LecteurSupport] ; se
// partager : `onPresenter`) et sa reprise. Un support qui ne sait pas encore
// se partager n'a pas de bouton « Partager » : une phrase le dit.
//
// Trois vues dans le meme panneau, rien ne s'ouvre au milieu de la salle
// (composition du 26/10/2026) :
// 1. l'etagere : les couvertures sur des planches, la recherche et les
//    filtres en retrait (LISTES-1 : le contenu d'abord) ;
// 2. la fiche d'un support : couverture, titre, reprise, « Partager »
//    (le seul bouton plein) et « Afficher » ;
// 3. la lecture seule (« Afficher ») : la page, ses fleches, et « Partager
//    page N » ; la classe ne voit rien tant qu'on ne partage pas.
//
// Reutilisable tel quel dans « Ma classe » : aucune dependance a la seance.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/brand_logo.dart' show FondLogo;
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/couverture_support.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ornement_marque.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';

/// La lecture seule d'un support pagine (« Afficher ») : le Coran, demain le
/// livre des lettres. La classe ne voit rien de ce qui s'y lit.
@immutable
class LecteurSupport {
  const LecteurSupport({
    required this.pages,
    required this.pageDepart,
    required this.page,
    this.partagerPage,
  });

  /// Le nombre de pages du support.
  final int pages;

  /// La page ouverte d'abord (la reprise de la classe, sinon 1).
  final int pageDepart;

  /// Rend la page [numero], pour l'enseignant seul.
  final Widget Function(BuildContext context, int numero) page;

  /// Partage la page lue a la classe ; `null` quand ce support ne se
  /// partage pas encore, ou sans le droit de presenter.
  final void Function(int numero)? partagerPage;
}

/// Un support de la Bibliotheque de la salle.
@immutable
class SupportBibliotheque {
  const SupportBibliotheque({
    required this.id,
    required this.titre,
    required this.detail,
    required this.couverture,
    this.onPresenter,
    this.pageReprise,
    this.onReprendre,
    this.presenterSecondaire = false,
    this.lecteur,
    this.aValider = false,
  });

  /// K-56 (pilote, 26/10/2026) : la page presentee est en erreur et son
  /// « Reessayer » est le seul bouton plein ; « Partager » passe en
  /// secondaire (contour) tant que l'erreur est affichee.
  final bool presenterSecondaire;

  final String id;
  final String titre;

  /// La ligne sous le titre (« On reprend page 24 »).
  final String detail;
  final CouvertureRessource couverture;

  /// « Partager » : le support s'ouvre pour toute la classe (le Coran : le
  /// choix de la sourate). `null` : ce support ne se partage pas, ou
  /// l'enseignant n'a pas le droit de presenter (droit du jeton, verifie au
  /// point d'insertion) ; le bouton n'est pas rendu.
  final VoidCallback? onPresenter;

  /// La page retenue pour cette Classe, ou `null`.
  final int? pageReprise;

  /// Partage a la page retenue, ou `null`.
  final VoidCallback? onReprendre;

  /// « Afficher » : la lecture seule ; `null` quand le support ne s'ouvre
  /// pas encore dans la salle.
  final LecteurSupport? lecteur;

  /// Support de demonstration a valider par la direction (CAHIER-SALLE §7) :
  /// jamais presente comme officiel.
  final bool aValider;

  /// Presente dans cette Classe (une page est retenue).
  bool get recent => pageReprise != null;
}

/// Les filtres de la Bibliotheque.
enum FiltreBibliotheque { classe, tous }

/// L'etat de la lecture de la Bibliotheque.
enum EtatEtagere { pret, chargement, erreur, horsLigne }

/// L'etagere, la fiche et la lecture seule, dans un panneau qui defile d'un
/// seul tenant.
class EtagereSupports extends StatefulWidget {
  const EtagereSupports({
    required this.supports,
    this.etat = EtatEtagere.pret,
    this.onReessayer,
    this.onFermer,
    this.entete = const <Widget>[],
    this.cle,
    super.key,
  });

  final List<SupportBibliotheque> supports;
  final EtatEtagere etat;

  /// Relit la Bibliotheque apres une erreur.
  final VoidCallback? onReessayer;

  /// La croix « Fermer » et la languette du titre ; `null` : ni l'une ni
  /// l'autre (le tiroir du telephone porte deja son titre et « Reduire »).
  final VoidCallback? onFermer;

  /// Ce qui se pose en tete et defile avec l'etagere (le tiroir du
  /// telephone : le Tableau et « Ranger le support »).
  final List<Widget> entete;

  /// La cle de la liste qui defile (tests, captures).
  final Key? cle;

  /// Au-dela de ce nombre de supports, la recherche s'ouvre d'office.
  static const int seuilRecherche = 8;

  @override
  State<EtagereSupports> createState() => _EtatEtagere();
}

class _EtatEtagere extends State<EtagereSupports> {
  final TextEditingController _recherche = TextEditingController();
  FiltreBibliotheque _filtre = FiltreBibliotheque.tous;
  bool _rechercheOuverte = false;
  String? _choisi;
  int? _pageLue;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  SupportBibliotheque? get _support {
    for (final SupportBibliotheque s in widget.supports) {
      if (s.id == _choisi) return s;
    }
    return null;
  }

  List<SupportBibliotheque> get _visibles {
    final String cherche = _recherche.text.trim().toLowerCase();
    return <SupportBibliotheque>[
      for (final SupportBibliotheque s in widget.supports)
        if ((_filtre == FiltreBibliotheque.tous || s.recent) &&
            (cherche.isEmpty || s.titre.toLowerCase().contains(cherche)))
          s,
    ];
  }

  void _ouvrir(String id) => setState(() {
    _choisi = id;
    _pageLue = null;
  });

  void _revenir() => setState(() {
    _choisi = null;
    _pageLue = null;
  });

  @override
  Widget build(BuildContext context) {
    final SupportBibliotheque? support = _support;
    final int? page = _pageLue;
    final LecteurSupport? lecteur = support?.lecteur;
    final List<Widget> vue = support == null
        ? _etagere(context)
        : lecteur != null && page != null
        ? <Widget>[
            _Lecture(
              support: support,
              lecteur: lecteur,
              page: page,
              onPage: (int p) => setState(() => _pageLue = p),
              onRevenir: () => setState(() => _pageLue = null),
            ),
          ]
        : <Widget>[
            _Fiche(
              support: support,
              onRevenir: _revenir,
              onAfficher: lecteur == null
                  ? null
                  : () => setState(
                      () =>
                          _pageLue = support.pageReprise ?? lecteur.pageDepart,
                    ),
            ),
          ];
    return ListView(
      // Une vue neuve repart du haut : la fiche ne s'ouvre pas au milieu de
      // l'etagere.
      key: widget.cle,
      children: <Widget>[
        ...widget.entete,
        if (widget.onFermer case final VoidCallback fermer) ...<Widget>[
          _Languette(onFermer: fermer),
          Ecart.vLg,
        ],
        KeyedSubtree(
          key: ValueKey<String>('etagere-vue-${support?.id}-${page != null}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: vue,
          ),
        ),
      ],
    );
  }

  List<Widget> _etagere(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? reessayer = widget.onReessayer;
    switch (widget.etat) {
      case EtatEtagere.chargement:
        return <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) =>
                _Planches(largeur: c.maxWidth, livres: null),
          ),
        ];
      case EtatEtagere.erreur:
        return <Widget>[
          EmptyState(
            message: t.salle.etagere.erreurTitre,
            invitation: t.salle.etagere.erreurDetail,
            icone: AppIcons.horsLigne,
            libelleAction: reessayer == null ? null : t.commun.reessayer,
            onAction: reessayer,
            registre: reessayer == null
                ? RegistreVide.subi
                : RegistreVide.actionnable,
          ),
        ];
      case EtatEtagere.horsLigne:
        return <Widget>[
          EmptyState(
            message: t.salle.etagere.horsLigne,
            invitation: t.salle.etagere.horsLigneDetail,
            icone: AppIcons.horsLigne,
            registre: RegistreVide.subi,
          ),
        ];
      case EtatEtagere.pret:
        break;
    }
    if (widget.supports.isEmpty) {
      return <Widget>[
        EmptyState(
          message: t.salle.etagere.vide,
          invitation: t.salle.etagere.videDetail,
          icone: AppIcons.bibliotheque,
          registre: RegistreVide.subi,
        ),
      ];
    }
    final bool recherche =
        _rechercheOuverte ||
        widget.supports.length > EtagereSupports.seuilRecherche;
    final List<SupportBibliotheque> visibles = _visibles;
    Widget filtre(FiltreBibliotheque f, String libelle) => FilterPill(
      key: ValueKey<String>('bibliotheque-filtre-${f.name}'),
      libelle: libelle,
      retenue: _filtre == f,
      onPress: () => setState(() => _filtre = f),
    );
    return <Widget>[
      Text(
        t.salle.etagere.intro,
        style: palette.inkMuted.applyTo(textes.bodySmall ?? const TextStyle()),
      ),
      Ecart.vMd,
      // LISTES-1 : les filtres et la loupe tiennent sur une rangee discrete ;
      // la recherche ne s'ouvre qu'a la demande (ou d'office au-dela de huit
      // supports).
      Row(
        children: <Widget>[
          Expanded(
            child: RangeeFiltres(
              replier: false,
              filtres: <Widget>[
                filtre(
                  FiltreBibliotheque.classe,
                  t.salle.seance.bibliotheque.cetteClasse,
                ),
                filtre(
                  FiltreBibliotheque.tous,
                  t.salle.seance.bibliotheque.tous,
                ),
              ],
            ),
          ),
          if (widget.supports.length <= EtagereSupports.seuilRecherche)
            BoutonIcone(
              key: const ValueKey<String>('bibliotheque-loupe'),
              icone: _rechercheOuverte ? AppIcons.fermer : AppIcons.recherche,
              libelle: _rechercheOuverte
                  ? t.salle.etagere.fermerRecherche
                  : t.salle.etagere.rechercher,
              infobulle: _rechercheOuverte
                  ? t.salle.etagere.fermerRecherche
                  : t.salle.etagere.rechercher,
              forme: FormeBoutonIcone.nue,
              onPress: () => setState(() {
                _rechercheOuverte = !_rechercheOuverte;
                if (!_rechercheOuverte) _recherche.clear();
              }),
            ),
        ],
      ),
      if (recherche) ...<Widget>[
        Ecart.vSm,
        ChampRecherche(
          controleur: _recherche,
          libelle: t.tc.bibliotheque.rechercheLibelle,
          aide: t.tc.bibliotheque.rechercheIndication,
          cleChamp: const ValueKey<String>('bibliotheque-recherche'),
          onChange: (String _) => setState(() {}),
        ),
      ],
      Ecart.vLg,
      if (visibles.isEmpty)
        Text(
          t.tc.bibliotheque.aucunResultat.message,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        )
      else
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => _Planches(
            largeur: c.maxWidth,
            livres: <Widget>[
              for (final SupportBibliotheque s in visibles)
                _Livre(support: s, onOuvrir: () => _ouvrir(s.id)),
            ],
            legendes: <Widget>[
              for (final SupportBibliotheque s in visibles)
                Text(
                  switch (s.pageReprise) {
                    final int page => t.salle.etagere.reprise(page: page),
                    null => s.detail,
                  },
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
            ],
          ),
        ),
    ];
  }
}

/// La languette du panneau, aux couleurs de la marque : le titre, l'ornement
/// en blanc sur le violet, et la croix qui referme le panneau.
class _Languette extends StatelessWidget {
  const _Languette({required this.onFermer});

  final VoidCallback onFermer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              key: const ValueKey<String>('bibliotheque-languette'),
              decoration: palette.surfacePrimary.decoration(
                borderRadius: AppRadius.arrondiFull,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const OrnementMarque(fond: FondLogo.violet),
                    Ecart.hSm,
                    Flexible(
                      child: Text(
                        t.tc.bibliotheque.titre,
                        style: palette.surfacePrimary.applyTo(
                          textes.titleMedium ?? const TextStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        BoutonIcone(
          key: const ValueKey<String>('bibliotheque-fermer'),
          icone: AppIcons.fermer,
          libelle: t.commun.fermer,
          infobulle: t.commun.fermer,
          forme: FormeBoutonIcone.nue,
          onPress: onFermer,
        ),
      ],
    );
  }
}

/// Les planches de l'etagere : les livres par rangees, chaque rangee posee
/// sur sa planche, la legende de chaque livre sous la planche. [livres]
/// `null` : la forme de l'etagere qui se charge.
class _Planches extends StatelessWidget {
  const _Planches({
    required this.largeur,
    required this.livres,
    this.legendes = const <Widget>[],
  });

  final double largeur;
  final List<Widget>? livres;

  /// Une legende par livre, dans le meme ordre (la reprise, le detail).
  final List<Widget> legendes;

  /// La largeur visee d'un livre, a 100 % de texte.
  static const double largeurLivre = AppSpacing.respiration * 2 - AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Texte agrandi : les livres grandissent, jusqu'a une fois et demie.
    final double echelle = MediaQuery.textScalerOf(context)
        .scale(AppSpacing.lg)
        .clamp(AppSpacing.lg, AppSpacing.lg * 1.5);
    final double vise = largeurLivre * echelle / AppSpacing.lg;
    const double ecart = AppSpacing.lg;
    final int parRangee = math.max(
      1,
      ((largeur + ecart) / (vise + ecart)).floor(),
    );
    final double livre = (largeur - ecart * (parRangee - 1)) / parRangee;
    final List<Widget> tous =
        livres ??
        <Widget>[
          for (int i = 0; i < parRangee; i++)
            Skeleton(hauteur: livre / CouvertureSupport.rapport),
        ];
    final List<Widget> rangees = <Widget>[];
    for (int i = 0; i < tous.length; i += parRangee) {
      final List<Widget> rangee = tous.sublist(
        i,
        math.min(i + parRangee, tous.length),
      );
      rangees.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: ecart,
              children: <Widget>[
                for (final Widget l in rangee) SizedBox(width: livre, child: l),
              ],
            ),
            // La planche : un filet epais et sa tranche, dans les jetons.
            DecoratedBox(
              decoration: palette.surfaceSunken.decoration(
                borderRadius: AppRadius.arrondiXs,
                side: palette.borderHairline.asBorderSide(),
              ),
              child: const SizedBox(height: AppSpacing.sm),
            ),
            if (legendes.length == tous.length) ...<Widget>[
              Ecart.vSm,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: ecart,
                children: <Widget>[
                  for (final Widget l in legendes.sublist(
                    i,
                    math.min(i + parRangee, legendes.length),
                  ))
                    SizedBox(width: livre, child: l),
                ],
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxl,
      children: rangees,
    );
  }
}

/// Un livre de l'etagere : sa couverture, qui se touche tout entiere et
/// ouvre la fiche.
class _Livre extends StatelessWidget {
  const _Livre({required this.support, required this.onOuvrir});

  final SupportBibliotheque support;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: ValueKey<String>('bibliotheque-deplier-${support.id}'),
      onPress: onOuvrir,
      libelleSemantique:
          '${t.salle.etagere.ouvrirFiche(titre: support.titre)}, '
          '${support.detail}',
      arrondiFocus: AppRadius.arrondiXs,
      child: ExcludeSemantics(
        child: CouvertureSupport(
          key: ValueKey<String>('bibliotheque-support-${support.id}'),
          titre: support.titre,
          couverture: support.couverture,
          mention: support.aValider ? t.salle.etagere.aValider : null,
        ),
      ),
    );
  }
}

/// La fiche courte d'un support : couverture, titre, reprise, puis
/// « Partager » (le seul bouton plein, K-56 : le geste le plus courant en
/// cours) et « Afficher », chacun avec sa consequence (K-58).
class _Fiche extends StatelessWidget {
  const _Fiche({
    required this.support,
    required this.onRevenir,
    required this.onAfficher,
  });

  final SupportBibliotheque support;
  final VoidCallback onRevenir;
  final VoidCallback? onAfficher;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final int? page = support.pageReprise;
    final VoidCallback? reprendre = support.onReprendre;
    final VoidCallback? presenter = support.onPresenter;
    final VoidCallback? afficher = onAfficher;
    // Avec une reprise, « Partager » reprend la ou la classe s'est arretee ;
    // choisir un autre endroit devient un lien.
    final bool aLaReprise = reprendre != null && page != null;
    final VoidCallback? partager = aLaReprise ? reprendre : presenter;
    final NiveauAction plein = support.presenterSecondaire
        ? NiveauAction.secondaire
        : NiveauAction.principale;
    TextStyle style(TextStyle? base) =>
        palette.inkMuted.applyTo(base ?? const TextStyle());

    return Column(
      key: ValueKey<String>('bibliotheque-fiche-${support.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: const ValueKey<String>('bibliotheque-revenir-etagere'),
            libelle: t.salle.etagere.revenir,
            icone: AppIcons.retour,
            fleche: false,
            alignerEnDebut: true,
            onPress: onRevenir,
          ),
        ),
        Ecart.vMd,
        // La couverture et ce qu'il faut savoir, cote a cote : les deux
        // actions restent dans la vue, au telephone comme dans le panneau.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: _Planches.largeurLivre,
              child: CouvertureSupport(
                titre: support.titre,
                couverture: support.couverture,
                mention: support.aValider ? t.salle.etagere.aValider : null,
              ),
            ),
            Ecart.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    support.titre,
                    style: palette.inkStrong.applyTo(
                      textes.titleMedium ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vXs,
                  Text(
                    page == null
                        ? support.detail
                        : t.salle.etagere.reprise(page: page),
                    style: style(textes.bodySmall),
                  ),
                  if (support.aValider) ...<Widget>[
                    Ecart.vSm,
                    Text(
                      t.salle.etagere.aValiderDetail,
                      style: palette.inkWarning.applyTo(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        Ecart.vLg,
        if (partager != null) ...<Widget>[
          Text(
            aLaReprise
                ? t.salle.etagere.partagerPageDetail
                : t.salle.etagere.partagerDetail,
            style: style(textes.bodySmall),
          ),
          Ecart.vSm,
          ActionPrincipale(
            key: ValueKey<String>(
              aLaReprise
                  ? 'bibliotheque-reprendre-${support.id}'
                  : 'bibliotheque-presenter-${support.id}',
            ),
            libelle: aLaReprise
                ? t.salle.etagere.partagerPage(page: page)
                : t.salle.etagere.partager,
            libelleSemantique: aLaReprise
                ? t.salle.etagere.partagerPageSemantique(page: page)
                : t.salle.etagere.partagerSemantique(titre: support.titre),
            onPress: partager,
            pleineLargeur: true,
            niveau: plein,
          ),
          if (aLaReprise && presenter != null) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              key: ValueKey<String>('bibliotheque-presenter-${support.id}'),
              libelle: t.salle.etagere.choisirDebut,
              onPress: presenter,
            ),
          ],
        ] else if (afficher != null)
          Text(t.salle.etagere.nonPartageable, style: style(textes.bodySmall)),
        if (afficher != null) ...<Widget>[
          Ecart.vLg,
          Text(t.salle.etagere.afficherDetail, style: style(textes.bodySmall)),
          Ecart.vSm,
          ActionPrincipale(
            key: ValueKey<String>('bibliotheque-afficher-${support.id}'),
            libelle: t.salle.etagere.afficher,
            libelleSemantique: t.salle.etagere.afficherSemantique(
              titre: support.titre,
            ),
            onPress: afficher,
            pleineLargeur: true,
            niveau: NiveauAction.secondaire,
          ),
        ],
        if (partager == null && afficher == null)
          Text(t.salle.etagere.nonOuvrable, style: style(textes.bodySmall)),
      ],
    );
  }
}

/// « Afficher » : la page, pour l'enseignant seul, ses fleches, et
/// « Partager page N » quand le support se partage.
class _Lecture extends StatelessWidget {
  const _Lecture({
    required this.support,
    required this.lecteur,
    required this.page,
    required this.onPage,
    required this.onRevenir,
  });

  final SupportBibliotheque support;
  final LecteurSupport lecteur;
  final int page;
  final ValueChanged<int> onPage;
  final VoidCallback onRevenir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final void Function(int)? partager = lecteur.partagerPage;
    return Column(
      key: ValueKey<String>('bibliotheque-lecture-${support.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: const ValueKey<String>('bibliotheque-revenir-fiche'),
            libelle: t.salle.etagere.revenirFiche,
            icone: AppIcons.retour,
            fleche: false,
            alignerEnDebut: true,
            onPress: onRevenir,
          ),
        ),
        Ecart.vSm,
        Text(
          support.titre,
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          t.salle.etagere.seulVous,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        BarrePrecedentSuivant(
          position: t.salle.seance.page(page: page, pages: lecteur.pages),
          positionSemantique: t.salle.seance.pageSemantique(
            page: page,
            pages: lecteur.pages,
          ),
          libellePrecedent: t.salle.etagere.pagePrecedente,
          libelleSuivant: t.salle.etagere.pageSuivante,
          onPrecedent: page > 1 ? () => onPage(page - 1) : null,
          onSuivant: page < lecteur.pages ? () => onPage(page + 1) : null,
        ),
        Ecart.vSm,
        lecteur.page(context, page),
        if (partager != null) ...<Widget>[
          Ecart.vLg,
          ActionPrincipale(
            key: ValueKey<String>('bibliotheque-partager-page-${support.id}'),
            libelle: t.salle.etagere.partagerPage(page: page),
            libelleSemantique: t.salle.etagere.partagerPageSemantique(
              page: page,
            ),
            onPress: () => partager(page),
            pleineLargeur: true,
            niveau: support.presenterSecondaire
                ? NiveauAction.secondaire
                : NiveauAction.principale,
          ),
        ],
      ],
    );
  }
}
