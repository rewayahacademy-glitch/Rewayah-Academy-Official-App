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
// ailleurs. Il est rendu pour l'enseignant ([VueSeance.voitCommandes]) et,
// depuis TB-10, pour l'eleve et la guidee (contenu reduit, plus bas) ;
// chaque entree n'existe que si son rappel existe (lib/CLAUDE.md).
//
// TB-7b (CMD-02, CMD-03) : l'onglet « Outils » porte la ligne d'outils
// primaires (Pointeur, Ecrire, puis Marquer et Masquer), la phrase qui
// explique l'outil retenu, et sous « Ecrire » la barre d'ecriture et ses
// options (ecriture_seance.dart). Le panneau s'ouvre sur « Outils » tant
// qu'un outil est retenu.
//
// TB-10 (plan V2 §5, §19.3 point 4) : l'eleve et la guidee ont leurs
// Commandes, sans onglets : « Ecrire » seulement si l'enseignant l'a
// autorise (l'information courte, puis l'outil, choisi par l'eleve), la
// Lecture (zoom local, « Ajuster a l'ecran ») et l'Affichage (Focus). Ni
// Bibliotheque, ni affichages partages, ni page, ni rangement, ni
// effacement global.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_outils/etat_outils.dart';
import '../../core/tc_outils/operations_personnelles.dart';
import '../../core/tc_outils/port_dock_hote.dart' show OutilDock;
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/bouton_outil.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/menu_actions.dart';
import 'actions_seance.dart';
import 'barre_support.dart';
import 'ecriture_seance.dart';
import 'outils_enseignement.dart';
import 'panneau_seance.dart' show DefilementAFondu;
import 'rangement_support.dart';
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
    this.iconeSeule = false,
    this.surface,
    super.key = cle,
  });

  /// La surface de la carte (la couche sombre du telephone, pilote C2) ;
  /// `null` : celle du theme.
  final AppColorPair? surface;

  /// La cle du declencheur.
  static const Key cle = ValueKey<String>('declencheur-commandes');

  /// TB-10 : l'icone seule, comme en Mode Accessibilite, a cote de
  /// l'information courte de l'eleve quand le texte est agrandi (la page
  /// garde sa hauteur) ; le nom lu et l'infobulle gardent le mot.
  final bool iconeSeule;

  final VoidCallback onPress;

  /// Le panneau est ouvert. Revue TB-R m13 : le declencheur n'est rendu
  /// que panneau ferme ; il ne se dit plus « selectionne » ni « non
  /// selectionne » (il ouvre un panneau, ce n'est pas un choix).
  final bool ouvert;

  /// Le noeud ou revient le focus a la fermeture du panneau.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // TB-10 (MA-CMD-1, directeur 02/10) : en Mode Accessibilite, l'icone
    // seule, compacte ; le nom lu et l'infobulle gardent le mot.
    if (iconeSeule || AppMetriques.of(context).mode == InterfaceMode.enfant) {
      return BoutonIcone(
        icone: AppIcons.replier,
        libelle: t.salle.seance.commandes.declencheurSemantique,
        infobulle: t.salle.seance.commandes.declencheur,
        forme: FormeBoutonIcone.carre,
        focusNode: focusNode,
        onPress: onPress,
      );
    }
    // La carte pressable du core (K-54), comme le bouton Eleves ; le mot
    // passe a la ligne a 200 % et a 320 au lieu de deborder ou d'etre coupe.
    return AppCard(
      onPress: onPress,
      // Le nom lu contient le mot visible (W-253) : « Ouvrir les commandes
      // du support et du tableau » (plan V2 §20).
      libelleSemantique: t.salle.seance.commandes.declencheurSemantique,
      focusNode: focusNode,
      marge: AppSpacing.md,
      surface: surface,
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
    );
  }
}

/// Le contenu du panneau « Commandes ».
class CommandesPedagogiques extends ConsumerStatefulWidget {
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

  /// TB-9 : le menu du titre du support (ou du tableau libre).
  static const Key cleMenu = ValueKey<String>('commandes-menu-support');

  /// TB-9 : le retour discret « Support range ».
  static const Key cleRange = ValueKey<String>('commandes-support-range');

  /// TB-11b (tour 2) : « L'ecriture reprend des le retour du tableau. », a
  /// la place de la tuile « Ecrire » pendant la suspension.
  static const Key cleEcritureSuspendue = ValueKey<String>(
    'commandes-ecriture-suspendue',
  );

  /// TB-11b : la conservation des notes (« dans cette seance uniquement »).
  static const Key cleConservation = ValueKey<String>(
    'commandes-conservation-notes',
  );

  /// TB-10 : la section « Ecrire » de l'eleve autorise.
  static const Key cleEcritureEleve = ValueKey<String>(
    'commandes-ecriture-eleve',
  );

  /// Le defilement de la colonne des Commandes.
  static const Key cleDefilement = ValueKey<String>('commandes-defilement');

  /// Le fondu du bas : il reste a lire sous le bord du panneau.
  static const Key cleFonduBas = ValueKey<String>('commandes-fondu-bas');

  /// Le fondu du haut : la colonne a defile.
  static const Key cleFonduHaut = ValueKey<String>('commandes-fondu-haut');

  /// Revue TB-R M7 (K-58) : ce que voit la classe pour l'affichage choisi.
  static const Key cleClasseVoit = ValueKey<String>('commandes-classe-voit');

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

  /// TB-10 : la section « Ecrire » de l'eleve (autorisation accordee, la
  /// salle sait ecrire).
  static bool voitEcritureEleve(VueSeance vue, ActionsSeance actions) =>
      !vue.commandesCompletes && vue.voitEcriture && actions.onOutil != null;

  /// Le declencheur n'est rendu que si une entree du panneau a un rappel
  /// (UX_REVIEW_TB §3 bis) : jamais un panneau vide.
  static bool aDesEntrees(VueSeance vue, ActionsSeance actions) {
    if (!vue.voitCommandes || actions.onCommandes == null) return false;
    final bool lecture =
        vue.voitLectureCommandes &&
        ((vue.voitZoomCommandes &&
                (actions.onZoomMoins != null || actions.onZoomPlus != null)) ||
            actions.onAjusterEcran != null ||
            actions.onAgrandir != null);
    final bool pages =
        vue.voitPaginationCommandes &&
        (actions.onPagePrecedente != null || actions.onPageSuivante != null);
    return bibliotheque(actions) != null ||
        (vue.voitAffichagesPartages && actions.onAffichage != null) ||
        pages ||
        lecture ||
        voitOutils(vue, actions) ||
        voitEcritureEleve(vue, actions);
  }

  @override
  ConsumerState<CommandesPedagogiques> createState() =>
      _CommandesPedagogiquesState();
}

class _CommandesPedagogiquesState extends ConsumerState<CommandesPedagogiques> {
  /// TB-7b : un outil retenu (Pointeur, Ecrire) rouvre le panneau sur
  /// « Outils », la ou il se change (palette courte, plan V2 §4.2).
  late OngletCommandes _onglet = ref.read(etatOutilsProvider).outilActif == null
      ? OngletCommandes.support
      : OngletCommandes.outils;

  /// TB-7b : choisir « Ecrire » alors que la classe voit le support seul
  /// (notes cachees) passe a « Avec notes » : une note ecrite se voit.
  void _outil(OutilEnseignement outil) {
    if (outil == OutilEnseignement.ecrire &&
        ref.read(etatOutilsProvider).outilActif == OutilDock.stylet &&
        widget.vue.vueSurface == VueSurface.supportSeul) {
      widget.actions.onAffichage?.call(AffichagePartage.avecNotes);
    }
    widget.actions.onOutil?.call(outil);
  }

  /// TB-9 : un support vient d'etre range depuis ce panneau ; le retour
  /// discret « Support range » se montre tant qu'aucun support n'est
  /// presente (enseignant seulement, aucun toast aux eleves, plan V2 §3).
  bool _range = false;

  /// Le retour « Support range » : ramene dans la vue du panneau apres le
  /// rangement (au telephone, le panneau defile ; le retour ne reste pas
  /// au-dessus du bord).
  final GlobalKey _retour = GlobalKey(debugLabel: 'commandes-retour-range');

  /// Revue TB-R m9 : le noeud de l'entree Bibliotheque, ou revient le focus
  /// apres « Ranger dans la bibliotheque » ou « Effacer les notes » (le menu
  /// qui l'avait a disparu).
  final FocusNode _focusBibliotheque = FocusNode(
    debugLabel: 'commandes-bibliotheque',
  );

  @override
  void dispose() {
    _focusBibliotheque.dispose();
    super.dispose();
  }

  /// Au cadre suivant, le focus sur l'entree Bibliotheque, si elle est
  /// rendue.
  void _focusSurBibliotheque() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _focusBibliotheque.context != null) {
        _focusBibliotheque.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(CommandesPedagogiques ancien) {
    super.didUpdateWidget(ancien);
    if (widget.vue.supportPresente != null) _range = false;
  }

  /// TB-9 (plan V2 §3 « Ranger reellement », §19.2 point 4) : la copie part
  /// de la feuille vers la Bibliotheque (rien sous mouvement reduit), puis
  /// l'etat change aussitot, sans attendre la copie ni demander de
  /// confirmation (action reversible).
  void _ranger() {
    final VoidCallback? ranger = widget.actions.onRanger;
    if (ranger == null) return;
    PorteeRangement.maybeOf(context)?.envoler(context);
    setState(() => _range = true);
    ranger();
    _focusSurBibliotheque();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      final BuildContext? retour = _retour.currentContext;
      if (mounted && retour != null) {
        unawaited(Scrollable.ensureVisible(retour));
      }
    });
  }

  /// TB-9 (plan V2 §12) : effacer les notes de la page, ou du tableau libre,
  /// apres `ConfirmDestructive` (l'irreversible se dit avant le choix).
  Future<void> _effacer() async {
    final VoidCallback? rappel = widget.actions.onEffacerNotes;
    if (rappel == null) return;
    // TB-RC (revue TB-R, m31) : l'historique et la surface sont lus avant
    // la confirmation. Si le panneau est demonte pendant qu'elle s'affiche,
    // l'effacement vide quand meme l'historique de la surface : Annuler ne
    // remet jamais une note effacee.
    final ControleurHistorique historique = ref.read(
      historiquePersonnelProvider.notifier,
    );
    final surface = surLaSurface(widget.vue.ancrageSurface);
    void effacer() {
      rappel();
      historique.oublierSurface(surface);
    }

    final bool tableau = widget.vue.effacementDuTableau;
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: tableau
          ? t.salle.seance.rangement.questionTableau
          : t.salle.seance.rangement.questionPage,
      consequence: tableau
          ? t.salle.seance.rangement.consequenceTableau
          : t.salle.seance.rangement.consequencePage,
      libelleConfirmer: t.salle.seance.rangement.effacer,
      irreversible: true,
    );
    if (!confirme) return;
    effacer();
    if (!mounted) return;
    _focusSurBibliotheque();
    // TB-7b : « Annuler » ne rajoute jamais une note que l'effacement a
    // retiree ; les operations personnelles de la surface s'en vont.
    ref
        .read(historiquePersonnelProvider.notifier)
        .oublierSurface(surLaSurface(widget.vue.ancrageSurface));
  }

  /// Les actions rares du support ou du tableau, chacune seulement si la
  /// vue la permet ET que son rappel existe.
  List<EntreeAction> _entreesMenu() => <EntreeAction>[
    if (widget.vue.voitRanger && widget.actions.onRanger != null)
      EntreeAction(libelle: t.salle.seance.rangement.ranger, onChoix: _ranger),
    if (widget.vue.voitEffacerNotes && widget.actions.onEffacerNotes != null)
      EntreeAction(
        libelle: t.salle.seance.rangement.effacer,
        onChoix: () => unawaited(_effacer()),
        destructif: true,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.vue.commandesCompletes) return _colonne(_eleve(context));
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
          // Le Pointeur en tete (ordre de `OutilEnseignement`), puis Ecrire
          // et les capacites existantes ; l'outil choisi reste local.
          OutilsEnseignement(
            onOutil: widget.actions.onOutil == null ? null : _outil,
            forme: FormeOutils.rangee,
            avecEcrire: widget.vue.ecritureProposee,
          ),
          AideOutil(
            ecritureSuspendue: widget.vue.texteEcritureSuspendue != null,
          ),
          // TB-11b (tour 2) : « Ecrire » n'est pas rendu pendant la reprise
          // du tableau ; la phrase dit pourquoi et quand il revient.
          if (widget.vue.texteEcritureSuspendue case final String suspendue)
            _EcritureSuspendue(texte: suspendue),
          if (ecritSurLaSurface(ref, widget.vue))
            EcritureSeance(vue: widget.vue),
        ],
      },
    ];
    return _colonne(lignes);
  }

  /// Une seule colonne qui defile : a 200 % et a 320, rien n'est coupe
  /// (UX_REVIEW_TB n. 27 a). Le contenu est court : tout est construit
  /// (lecteur d'ecran, ordre du focus), et la colonne defile si la place
  /// manque.
  ///
  /// Verification TB-10 et TB-11b : a 320 x2, la colonne ne montre qu'une
  /// ou deux lignes ; ce qui reste dessous (Stylo, Gomme, Terminer, la
  /// phrase de conservation) ne s'atteignait qu'en defilant, sans signe, et
  /// une ligne restait coupee a mi-hauteur au bord. L'indice maison, comme
  /// `TeteSalleBornee` : un fondu au bord bas tant qu'il reste a lire, au
  /// bord haut des que la colonne a defile.
  Widget _colonne(List<Widget> lignes) {
    return DefilementAFondu(
      cleDefilement: CommandesPedagogiques.cleDefilement,
      cleFonduBas: CommandesPedagogiques.cleFonduBas,
      cleFonduHaut: CommandesPedagogiques.cleFonduHaut,
      margeBas: AppSpacing.md,
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
    return <Widget>[
      // Plan V2 §4.2 : la Bibliotheque est la premiere action du panneau.
      if (bibliotheque != null)
        // TB-9 : l'arrivee de la copie du rangement.
        KeyedSubtree(
          key: PorteeRangement.maybeOf(context)?.bibliotheque,
          child: BoutonPanneau(
            key: CommandesPedagogiques.cleBibliotheque,
            icone: AppIcons.bibliotheque,
            libelle: t.salle.seance.commandes.bibliotheque,
            onPress: bibliotheque,
            focusNode: _focusBibliotheque,
            etire: true,
          ),
        ),
      if (_range && vue.supportPresente == null)
        KeyedSubtree(key: _retour, child: const _RetourRange()),
      if (titre != null)
        _SupportMontre(
          titre: titre,
          icone: AppIcons.fichierPdf,
          menu: _entreesMenu(),
          semantiqueMenu: t.salle.seance.rangement.menuSupport,
        )
      // TB-9 : sans support, le tableau libre et son menu, s'il a des notes.
      else if (vue.voitEffacerNotes && actions.onEffacerNotes != null)
        _SupportMontre(
          titre: t.salle.seance.rangement.tableauLibre,
          icone: AppIcons.tabletteOuOrdinateur,
          menu: _entreesMenu(),
          semantiqueMenu: t.salle.seance.rangement.menuTableau,
        ),
      // TB-11b (plan V2 §11, §20 « Sauvegarde absente ») : ce que deviennent
      // les notes, sous ce qui les porte ; jamais « Sauvegarde ».
      if (vue.texteConservation case final String conservation)
        Text(
          conservation,
          key: CommandesPedagogiques.cleConservation,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
      // Un clic par affichage (TB3) ; invisibles sans support presente.
      if (vue.voitAffichagesPartages && affichage != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
            // Revue TB-R M7 (K-58) : la consequence du choix, sous lui ; la
            // ligne suit l'affichage retenu.
            Ecart.vXs,
            Text(
              switch (vue.affichage) {
                AffichagePartage.support =>
                  t.salle.seance.commandes.classeVoitSupport,
                AffichagePartage.avecNotes =>
                  t.salle.seance.commandes.classeVoitAvecNotes,
                AffichagePartage.tableau =>
                  t.salle.seance.commandes.classeVoitTableau,
              },
              key: CommandesPedagogiques.cleClasseVoit,
              style: AppPalette.of(context).inkMuted.applyTo(
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
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
      ..._lectureEtFocus(),
    ];
  }

  /// TB-10 (plan V2 §19.3 point 4) : les Commandes de l'eleve. « Ecrire »
  /// d'abord quand l'enseignant l'a autorise (c'est la raison d'ouvrir le
  /// panneau), puis la Lecture et l'Affichage.
  List<Widget> _eleve(BuildContext context) {
    final VueSeance vue = widget.vue;
    final ActionsSeance actions = widget.actions;
    final ValueChanged<OutilEnseignement>? rappel = actions.onOutil;
    final bool ecrit = ecritSurLaSurface(ref, vue);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? avis = vue.avisEcriture;
    return <Widget>[
      if (CommandesPedagogiques.voitEcritureEleve(vue, actions) &&
          rappel != null)
        Column(
          key: CommandesPedagogiques.cleEcritureEleve,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (avis != null) ...<Widget>[
              Text(
                avis,
                style: palette.inkStrong.applyTo(
                  textes.titleSmall ?? const TextStyle(),
                ),
              ),
              Ecart.vSm,
            ],
            // TB-11b (tour 2) : le tableau suspend l'ecriture ; ni tuile, ni
            // aide qui dit d'ecrire, ni barre : la phrase de la suspension.
            if (vue.texteEcritureSuspendue case final String suspendue)
              _EcritureSuspendue(texte: suspendue)
            else ...<Widget>[
              // La tuile « Ecrire » des outils de la salle, seule : l'eleve
              // entre dans Ecrire volontairement (§19.3 point 5).
              OutilsEnseignement(
                onOutil: (OutilEnseignement outil) {
                  garderOutilPropose(ref, vue);
                  rappel(outil);
                },
                forme: FormeOutils.rangee,
                outils: const <OutilEnseignement>[OutilEnseignement.ecrire],
              ),
              Ecart.vSm,
              Text(
                ecrit ? vue.aideOutilsEleve : vue.aideChoisirEcrire,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              if (ecrit) ...<Widget>[Ecart.vMd, EcritureSeance(vue: vue)],
            ],
          ],
        ),
      ..._lectureEtFocus(),
    ];
  }

  /// La Lecture (zoom local, « Ajuster a l'ecran ») et l'Affichage (Focus).
  List<Widget> _lectureEtFocus() {
    final VueSeance vue = widget.vue;
    final ActionsSeance actions = widget.actions;
    // Verification TB-10 : chez l'eleve au bureau, la barre basse porte
    // deja le zoom local ; une seule commande de zoom visible a la fois.
    final bool zoomEnBarre =
        !vue.commandesCompletes && vue.voitZoomLocal(AppGabarit.de(context));
    final bool zoom =
        !zoomEnBarre &&
        vue.voitZoomCommandes &&
        (actions.onZoomMoins != null || actions.onZoomPlus != null);
    final VoidCallback? ajuster = actions.onAjusterEcran;
    final VoidCallback? focus = actions.onAgrandir;
    // Revue TB-R m1 et m2 : un seul nom du focus, le meme dans la barre de
    // l'appel et la barre du support ([nomsFocus]).
    final NomsFocus noms = nomsFocus(context, agrandi: widget.agrandi);
    final bool guidee = AppMetriques.of(context).mode == InterfaceMode.enfant;
    return <Widget>[
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
                  if (guidee)
                    // Revue TB-R m2 (plan V2 §5) : en Interface guidee,
                    // « Voir toute la page », pictogramme et mot.
                    BoutonOutil(
                      key: CommandesPedagogiques.cleAjuster,
                      icone: AppIcons.ajusterEcran,
                      libelle: t.salle.seance.commandes.ajusterGuide,
                      avecLibelle: true,
                      lignesLibelle: 2,
                      forme: FormeBoutonOutil.tuile,
                      onPress: ajuster,
                    )
                  else
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
            if (guidee)
              // Revue TB-R m2 : « Agrandir », pictogramme et mot.
              BoutonOutil(
                key: CommandesPedagogiques.cleFocus,
                icone: noms.icone,
                libelle: noms.libelle,
                avecLibelle: true,
                lignesLibelle: 2,
                forme: FormeBoutonOutil.tuile,
                onPress: focus,
              )
            else
              ActionPrincipale(
                key: CommandesPedagogiques.cleFocus,
                libelle: noms.libelle,
                libelleSemantique: noms.semantique,
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
/// (plan V2 §3). TB-9 : le menu du titre porte « Ranger dans la
/// bibliotheque » et « Effacer les notes » ; sans entree, pas de menu.
class _SupportMontre extends StatelessWidget {
  const _SupportMontre({
    required this.titre,
    required this.icone,
    required this.menu,
    required this.semantiqueMenu,
  });

  final String titre;
  final AppIcon icone;
  final List<EntreeAction> menu;
  final String semantiqueMenu;

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
                  child: Icon(icone.repos),
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
        if (menu.isNotEmpty) ...<Widget>[
          Ecart.hSm,
          MenuActions(
            key: CommandesPedagogiques.cleMenu,
            actions: menu,
            libelle: semantiqueMenu,
            points: true,
            // TB-RC (n.17) : la copie du rangement ne vole pas sous un menu
            // qui s'efface encore.
            fermetureNette: true,
          ),
        ],
      ],
    );
  }
}

/// TB-9 : « Support range », retour discret de l'enseignant (plan V2 §3,
/// §20), et ce qui suit (K-58) ; annonce une fois au lecteur d'ecran.
class _RetourRange extends StatelessWidget {
  const _RetourRange();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Semantics(
      key: CommandesPedagogiques.cleRange,
      liveRegion: true,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.salle.seance.rangement.range,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            t.salle.seance.rangement.rangeDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
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

/// TB-11b (tour 2) : la phrase qui remplace « Ecrire » pendant la reprise
/// du tableau (K-58 : la limite et sa suite).
class _EcritureSuspendue extends StatelessWidget {
  const _EcritureSuspendue({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) => Text(
    texte,
    key: CommandesPedagogiques.cleEcritureSuspendue,
    style: AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle()),
  );
}
