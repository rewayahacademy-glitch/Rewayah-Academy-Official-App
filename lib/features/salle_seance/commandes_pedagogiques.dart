// TB-4 (CMD-01, plan V2 §4.2, §6, §18.3, §20) : le declencheur « Commandes »
// et le panneau pedagogique de l'enseignant.
//
// Decision du directeur (TB-Q1, 05/10) : deux onglets, « Support » et
// « Outils ». La Bibliotheque est en tete de « Support », suivie du support
// montre, des trois affichages, de la page, de la Lecture et de l'Affichage
// (Focus) ; le Pointeur est en tete de « Outils ». Sans outil possible, pas
// d'onglet : un onglet qui ne mene a rien serait un bouton sans destination
// (UX_REVIEW_TB §9).
//
// Le panneau est pose par la salle dans [PanneauSeance] : feuille du bas au
// telephone (au-dessus de la barre de l'appel, UX-07), panneau a droite
// ailleurs. Il n'est rendu que pour l'enseignant ([VueSeance.voitCommandes]) ;
// chaque entree n'existe que si son rappel existe (lib/CLAUDE.md). Les outils
// d'ecriture eux-memes (Stylo, Surligner, Gomme, Annuler, palette courte et
// « Terminer ») viennent avec TB-7b : ils ne sont pas rendus ici.

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/controle_segmente.dart';
import 'actions_seance.dart';
import 'barre_support.dart';
import 'outils_enseignement.dart';
import 'salle_seance.dart' show BoutonPanneau;
import 'vue_seance.dart';

/// Les deux onglets du panneau (TB-Q1 = a).
enum OngletCommandes {
  /// Bibliotheque, support, affichages, page, Lecture, Affichage.
  support,

  /// Pointeur en tete, puis les autres outils.
  outils,
}

/// Le declencheur « Commandes » : discret, une seule place stable (bas du
/// support ; bord droit hors telephone). Il ouvre et reduit le panneau.
class DeclencheurCommandes extends StatelessWidget {
  /// Cree le declencheur.
  const DeclencheurCommandes({
    required this.onPress,
    this.ouvert = false,
    this.focusNode,
    super.key = cle,
  });

  /// La cle du declencheur.
  static const Key cle = ValueKey<String>('declencheur-commandes');

  final VoidCallback onPress;

  /// Le panneau est ouvert : le bouton se dit selectionne.
  final bool ouvert;

  /// Le noeud ou revient le focus a la fermeture du panneau.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // La carte pressable du core (K-54), comme le bouton Eleves ; le mot
    // passe a la ligne a 200 % et a 320 au lieu de deborder ou d'etre coupe.
    return Semantics(
      selected: ouvert,
      child: AppCard(
        onPress: onPress,
        // Le nom lu contient le mot visible (W-253) : « Ouvrir les commandes
        // du support et du tableau » (plan V2 §20).
        libelleSemantique: t.salle.seance.commandes.declencheurSemantique,
        focusNode: focusNode,
        marge: AppSpacing.md,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Planche 1 : un chevron vers le haut, le panneau monte.
              IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.replier.repos),
              ),
              Ecart.hSm,
              Flexible(
                child: TexteSansCoupure(
                  t.salle.seance.commandes.declencheur,
                  style: palette.inkStrong.applyTo(
                    Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le contenu du panneau « Commandes ».
class CommandesPedagogiques extends StatefulWidget {
  /// Cree le contenu.
  const CommandesPedagogiques({
    required this.vue,
    required this.actions,
    this.zoom = 1,
    this.agrandi = false,
    super.key = cle,
  });

  /// La cle du contenu.
  static const Key cle = ValueKey<String>('commandes-pedagogiques');

  /// Les onglets « Support » et « Outils ».
  static const Key cleOnglets = ValueKey<String>('commandes-onglets');

  /// L'entree Bibliotheque, premiere du panneau.
  static const Key cleBibliotheque = ValueKey<String>('commandes-bibliotheque');

  /// Le support montre (repere, pas un bouton).
  static const Key cleSupport = ValueKey<String>('commandes-support-montre');

  /// « Support », « Avec notes », « Tableau ».
  static const Key cleAffichages = ValueKey<String>('commandes-affichages');

  /// La section Lecture.
  static const Key cleLecture = ValueKey<String>('commandes-lecture');

  /// « Ajuster a l'ecran ».
  static const Key cleAjuster = ValueKey<String>('commandes-ajuster');

  /// « Focus » ou « Quitter le focus ».
  static const Key cleFocus = ValueKey<String>('commandes-focus');

  final VueSeance vue;
  final ActionsSeance actions;

  /// Le zoom local courant (1 = 100 %).
  final double zoom;

  /// Le focus local est actif : l'entree devient « Quitter le focus ».
  final bool agrandi;

  /// La Bibliotheque de la salle : le panneau des supports, sinon le
  /// selecteur de ressources ; `null` : pas d'entree.
  static VoidCallback? bibliotheque(ActionsSeance actions) =>
      // TB-8 : avec « Presenter », la Bibliotheque unique (apercu
      // personnel) ; sinon le panneau Supports d'avant.
      actions.onPresenter != null
      ? actions.onBibliotheque ?? actions.onSupports
      : actions.onSupports ?? actions.onBibliotheque;

  /// Le panneau a-t-il un onglet « Outils » ?
  static bool voitOutils(VueSeance vue, ActionsSeance actions) =>
      vue.voitOutils && actions.onOutil != null;

  /// Le declencheur n'est rendu que si une entree du panneau a un rappel
  /// (UX_REVIEW_TB §3 bis) : jamais un panneau vide.
  static bool aDesEntrees(VueSeance vue, ActionsSeance actions) {
    if (!vue.voitCommandes || actions.onCommandes == null) return false;
    final bool lecture =
        vue.voitLectureCommandes &&
        (actions.onZoomMoins != null ||
            actions.onZoomPlus != null ||
            actions.onAjusterEcran != null ||
            actions.onAgrandir != null);
    final bool pages =
        vue.voitPaginationCommandes &&
        (actions.onPagePrecedente != null || actions.onPageSuivante != null);
    return bibliotheque(actions) != null ||
        (vue.voitAffichagesPartages && actions.onAffichage != null) ||
        pages ||
        lecture ||
        voitOutils(vue, actions);
  }

  @override
  State<CommandesPedagogiques> createState() => _CommandesPedagogiquesState();
}

class _CommandesPedagogiquesState extends State<CommandesPedagogiques> {
  OngletCommandes _onglet = OngletCommandes.support;

  @override
  Widget build(BuildContext context) {
    final bool outils = CommandesPedagogiques.voitOutils(
      widget.vue,
      widget.actions,
    );
    final OngletCommandes onglet = outils ? _onglet : OngletCommandes.support;
    final List<Widget> lignes = <Widget>[
      if (outils)
        KeyedSubtree(
          key: CommandesPedagogiques.cleOnglets,
          child: ControleSegmente<OngletCommandes>(
            segments: <Segment<OngletCommandes>>[
              Segment<OngletCommandes>(
                valeur: OngletCommandes.support,
                libelle: t.salle.seance.commandes.ongletSupport,
              ),
              Segment<OngletCommandes>(
                valeur: OngletCommandes.outils,
                libelle: t.salle.seance.commandes.ongletOutils,
              ),
            ],
            valeur: onglet,
            onChange: (OngletCommandes o) => setState(() => _onglet = o),
          ),
        ),
      ...switch (onglet) {
        OngletCommandes.support => _support(context),
        OngletCommandes.outils => <Widget>[
          // Le Pointeur en tete (ordre de `OutilEnseignement`), puis les
          // capacites existantes ; l'outil choisi reste local (CLV-06).
          OutilsEnseignement(
            onOutil: widget.actions.onOutil,
            forme: FormeOutils.rangee,
          ),
        ],
      },
    ];
    // Une seule colonne qui defile : a 200 % et a 320, rien n'est coupe
    // (UX_REVIEW_TB n. 27 a).
    // Le contenu est court : tout est construit (lecteur d'ecran, ordre du
    // focus), et la colonne defile si la place manque.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < lignes.length; i++) ...<Widget>[
            if (i > 0) Ecart.vMd,
            lignes[i],
          ],
        ],
      ),
    );
  }

  List<Widget> _support(BuildContext context) {
    final VueSeance vue = widget.vue;
    final ActionsSeance actions = widget.actions;
    final VoidCallback? bibliotheque = CommandesPedagogiques.bibliotheque(
      actions,
    );
    final String? titre = vue.supportPresente?.titre ?? vue.support?.titre;
    final ValueChanged<AffichagePartage>? affichage = actions.onAffichage;
    final ({int page, int total})? page = vue.pageCommandes;
    final bool zoom = actions.onZoomMoins != null || actions.onZoomPlus != null;
    final VoidCallback? ajuster = actions.onAjusterEcran;
    final VoidCallback? focus = actions.onAgrandir;
    return <Widget>[
      // Plan V2 §4.2 : la Bibliotheque est la premiere action du panneau.
      if (bibliotheque != null)
        BoutonPanneau(
          key: CommandesPedagogiques.cleBibliotheque,
          icone: AppIcons.bibliotheque,
          libelle: t.salle.seance.commandes.bibliotheque,
          onPress: bibliotheque,
          etire: true,
        ),
      if (titre != null) _SupportMontre(titre: titre),
      // Un clic par affichage (TB3) ; invisibles sans support presente.
      if (vue.voitAffichagesPartages && affichage != null)
        KeyedSubtree(
          key: CommandesPedagogiques.cleAffichages,
          child: ControleSegmente<AffichagePartage>(
            rectangle: true,
            segments: <Segment<AffichagePartage>>[
              Segment<AffichagePartage>(
                valeur: AffichagePartage.support,
                libelle: t.salle.seance.commandes.affichageSupport,
                icone: AppIcons.fichierPdf,
              ),
              Segment<AffichagePartage>(
                valeur: AffichagePartage.avecNotes,
                libelle: t.salle.seance.commandes.affichageAvecNotes,
                icone: AppIcons.annoter,
              ),
              Segment<AffichagePartage>(
                valeur: AffichagePartage.tableau,
                libelle: t.salle.seance.commandes.affichageTableau,
                icone: AppIcons.tabletteOuOrdinateur,
              ),
            ],
            valeur: vue.affichage,
            onChange: affichage,
          ),
        ),
      // « Page {numero} sur {total} » entre ses fleches (plan V2 §20) ; sans
      // rappel, le texte seul, en lecture.
      if (vue.voitPaginationCommandes && page != null)
        PaginationSupport(
          page: page.page,
          pages: page.total,
          onPrecedente: actions.onPagePrecedente,
          onSuivante: actions.onPageSuivante,
          longue: true,
        ),
      if (vue.voitLectureCommandes && (zoom || ajuster != null))
        Column(
          key: CommandesPedagogiques.cleLecture,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _TitreSection(texte: t.salle.seance.commandes.lecture),
            Ecart.vSm,
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (zoom)
                  ZoomLocal(
                    zoom: widget.zoom,
                    onMoins: actions.onZoomMoins,
                    onPlus: actions.onZoomPlus,
                    avecLibelle: false,
                  ),
                if (ajuster != null)
                  ActionPrincipale(
                    key: CommandesPedagogiques.cleAjuster,
                    libelle: t.salle.seance.commandes.ajuster,
                    onPress: ajuster,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                  ),
              ],
            ),
          ],
        ),
      if (vue.voitLectureCommandes && focus != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _TitreSection(texte: t.salle.seance.commandes.affichage),
            Ecart.vSm,
            ActionPrincipale(
              key: CommandesPedagogiques.cleFocus,
              libelle: widget.agrandi
                  ? t.salle.seance.commandes.quitterFocus
                  : t.salle.seance.commandes.focus,
              libelleSemantique: widget.agrandi
                  ? null
                  : t.salle.seance.commandes.focusSemantique,
              onPress: focus,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
            ),
          ],
        ),
    ];
  }
}

/// Le support montre : un repere (miniature et titre court), pas un bouton
/// (plan V2 §3). Le menu du titre (« Ranger dans la bibliotheque ») vient
/// avec TB-9.
class _SupportMontre extends StatelessWidget {
  const _SupportMontre({required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Row(
      key: CommandesPedagogiques.cleSupport,
      children: <Widget>[
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: palette.surfaceSunken.decoration(
              borderRadius: AppRadius.arrondiMd,
            ),
            child: SizedBox.square(
              dimension: AppSpacing.titreEcran,
              child: Center(
                child: IconTheme(
                  data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                  child: Icon(AppIcons.fichierPdf.repos),
                ),
              ),
            ),
          ),
        ),
        Ecart.hMd,
        Expanded(
          child: TexteSansCoupure(
            titre,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texte,
      style: AppPalette.of(context).inkMuted
          .applyTo(Theme.of(context).textTheme.labelLarge ?? const TextStyle()),
    ),
  );
}
