import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/coran/service_coran.dart';
import '../../core/coran/vue_lecteur.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/video/video_session_provider.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rosace_verset.dart';
import '../../core/widgets/skeleton.dart';
import 'presentation_coran.dart';
import 'vue_presentation.dart';

/// `ENS-03` : la surface de l'enseignant dans la salle, le contenu presente.
///
/// **Ce panneau n'est pas un second ecran de salle.** La salle est un seul ecran
/// pour quatre roles (`lib/features/salle/salle_page.dart`) : la scene video, la
/// vignette locale, la liste de presence, le micro, la camera, la sortie et le
/// bandeau permanent y vivent deja, pour l'eleve comme pour l'enseignant. Ce
/// panneau ajoute la seule chose que l'enseignant a en plus : **le document
/// presente au groupe, et les gestes qui le tournent.** Il est insere par
/// l'integration en un seul point, et il ne reproduit aucune commande de
/// `salle_page` -- un second micro ou une seconde sortie sur le meme ecran
/// finirait par ne plus dire la meme chose que le premier.
///
/// Ce qu'il tient, dans l'ordre de la hierarchie de la salle :
///
/// 1. **le contenu pedagogique actif** : la page du mushaf presentee, rendue
///    ici comme le lecteur de l'eleve la rend chez lui -- a partir des versets,
///    jamais d'un PDF, d'une image ni d'une video (invariant J6) ;
/// 2. **les controles pedagogiques** : ouvrir le Coran, presenter la page
///    precedente ou suivante. Ils sont de premier niveau, dans le flux, et **ne
///    recouvrent jamais le texte** ;
/// 3. **l'etat du lien**, en mots, et seulement quand il change ce que
///    l'enseignant peut faire de sa page.
///
/// [QURAN-STAGE] Ce qui voyage est un **pointeur** -- page, sourate, verset --
/// et chaque client rend le Coran avec son propre lecteur. La position de
/// lecture personnelle d'un eleve n'est jamais ecrite d'ici (invariant J2) : le
/// contenu presente est ephemere, il vit le temps de la seance dans le moteur.
///
/// **Contrat de placement.** Le panneau se pose dans une region de **hauteur
/// bornee** -- le `child` de `PageImmersive`, une colonne laterale dimensionnee,
/// un `Expanded` : son texte defile a l'interieur, et rien n'y suppose autre
/// chose du parent qu'une largeur contrainte. Il se rend aux trois gabarits.
class PanneauEnseignantSalle extends ConsumerWidget {
  /// Cree le panneau pour une seance.
  const PanneauEnseignantSalle({required this.seanceId, super.key});

  /// La seance en cours.
  ///
  /// Elle n'ouvre aucune lecture ici : le contenu presente ne vit pas en base,
  /// il vit dans le moteur temps reel. Elle sert a deux choses -- **identifier
  /// l'etat local du panneau**, pour qu'un cours ne reprenne pas l'ecran du
  /// precedent, et nommer la salle dans laquelle ce panneau parle, ce qu'il
  /// faudra pour journaliser un tour de page le jour ou le protocole le
  /// demandera.
  final String seanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatSalle> lien = ref.watch(etatLienSalleProvider);
    final AsyncValue<ContenuPresente> contenu = ref.watch(
      contenuPresenteProvider,
    );

    return _Corps(
      // La seance identifie l'etat local du panneau : changer de cours repart
      // d'un panneau neuf, sans qu'un echec de la seance precedente reste
      // affiche sous les commandes de la suivante.
      key: ValueKey<String>(seanceId),
      vue: VuePresentation.depuis(
        // `.value` et non un filtrage par le type de l'AsyncValue : Riverpod 3
        // relance un provider en echec et repasse par AsyncLoading en gardant
        // hasError. Avant le premier evenement, on n'est pas en salle.
        etatMoteur: lien.value ?? EtatSalle.absent,
        contenu: contenu.value,
        // **Le droit de presenter est celui du jeton**, `can_publish_data`, et il
        // est verifie au point d'insertion : `salle_page` connait l'`AccesSalle`,
        // ce panneau non -- le moteur ne l'expose pas, et son etat est prive.
        // `CONTRACT_REQUEST_B` demande le getter qui le rendra lisible ici ; tant
        // qu'il n'existe pas, l'integration n'insere ce panneau que pour un
        // enseignant dont le jeton porte ce droit, et le parametre reste porte
        // par la vue pure pour qu'une seule ligne suffise a le brancher.
        peutPresenter: true,
      ),
    );
  }
}

/// Le corps du panneau, et le seul endroit qui porte un etat local.
///
/// Deux faits seulement y vivent : une demande en cours, et le dernier echec a
/// dire. **La page presentee, elle, n'y est pas** : elle vient du flux du
/// moteur, ce qui interdit a cet ecran d'afficher une page qu'il aurait demandee
/// sans que le groupe la recoive.
class _Corps extends ConsumerStatefulWidget {
  const _Corps({required this.vue, super.key});

  final VuePresentation vue;

  @override
  ConsumerState<_Corps> createState() => _CorpsEtat();
}

class _CorpsEtat extends ConsumerState<_Corps> {
  bool _enCours = false;
  String? _echec;

  /// Presente une page, et dit ce qui s'est passe si rien n'est parti.
  Future<void> _presenterPage(int page) =>
      _demander(() => ref.read(presentateurCoranProvider).presenterPage(page));

  /// Ouvre la bibliotheque, puis presente ce qui y a ete choisi.
  Future<void> _ouvrirBibliotheque() async {
    final ({int sourate, int verset})? choix = await AppBottomSheet.ouvrir<
      ({int sourate, int verset})
    >(
      context,
      titre: t.enseignant.salle.bibliotheque,
      constructeur: (BuildContext _) => const _Bibliotheque(),
    );
    if (choix == null || !mounted) {
      return;
    }
    await _demander(
      () => ref
          .read(presentateurCoranProvider)
          .presenterVerset(sourate: choix.sourate, verset: choix.verset),
    );
  }

  Future<void> _demander(Future<SortPresentation> Function() geste) async {
    // Un seul geste a la fois : deux tours de page qui se croisent feraient
    // reculer la classe d'une page, et le moteur ne peut pas les remettre en
    // ordre a notre place.
    if (_enCours) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = null;
    });
    final SortPresentation sort = await geste();
    if (!mounted) {
      return;
    }
    setState(() {
      _enCours = false;
      _echec = sort == SortPresentation.introuvable
          ? t.enseignant.salle.echecPresentation
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final VuePresentation vue = widget.vue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Reference(vue: vue),
        Ecart.vSm,
        // Le contenu prend toute la place qui reste : c'est le premier niveau de
        // la hierarchie de la salle, et rien ne se pose par-dessus.
        Expanded(
          child: switch (vue.contenu) {
            final ContenuPresente pointeur => _PagePresentee(contenu: pointeur),
            null => _Vide(
              onOuvrir: vue.commandesActives
                  ? () => unawaited(_ouvrirBibliotheque())
                  : null,
            ),
          },
        ),
        if (_echec case final String message) ...<Widget>[
          Ecart.vSm,
          LocalFeedback(message: message),
        ],
        // Les commandes sont dans le flux, sous le texte : une barre d'outils
        // posee par-dessus couvrirait le Coran, ce que la fiche interdit.
        if (vue.presente && vue.peutPresenter) ...<Widget>[
          Ecart.vSm,
          _Commandes(
            vue: vue,
            actives: vue.commandesActives && !_enCours,
            onPresenter: (int page) => unawaited(_presenterPage(page)),
            onBibliotheque: () => unawaited(_ouvrirBibliotheque()),
          ),
        ],
        // Un droit que le jeton refuse ne se grise pas : le bouton n'existe pas,
        // et une phrase prend sa place -- sans quoi l'enseignant chercherait la
        // commande manquante.
        if (!vue.peutPresenter) ...<Widget>[
          Ecart.vSm,
          Text(
            t.enseignant.salle.sansDroitPresentation,
            style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ],
      ],
    );
  }
}

/// La page presentee, toujours identifiable, et l'etat du lien en mots.
///
/// **Chaque etat porte son mot** (invariant J7) : aucune couleur ne porte seule
/// une information ici, et aucune pastille ne double celle de l'en-tete de la
/// salle -- ce qui se dit ici n'est pas l'etat du lien pour lui-meme, c'est ce
/// qu'il change pour la page presentee.
class _Reference extends StatelessWidget {
  const _Reference({required this.vue});

  final VuePresentation vue;

  /// Le mot de l'etat, ou `null` quand il n'y a rien a dire.
  ///
  /// Rien a dire en phase active : « En direct » est deja dans l'en-tete de la
  /// salle, et le repeter ici prendrait la place du texte.
  static String? _mot(VuePresentation vue) => switch (vue.phase) {
    PhasePresentation.active => null,
    PhasePresentation.instable =>
      '${t.salle.lienMediocre} - ${t.enseignant.salle.lienFaibleDetail}',
    PhasePresentation.reconnexion =>
      '${t.salle.reconnexionCourt} - ${t.enseignant.salle.presentationConservee}',
    PhasePresentation.retabli => t.reseau.retabli,
    PhasePresentation.echec =>
      '${t.salle.lienPerdu} - ${t.enseignant.salle.presentationSuspendue}',
    PhasePresentation.horsSalle => t.enseignant.salle.attenteSalle,
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (vue.contenu case final ContenuPresente pointeur)
          Text(
            t.enseignant.salle.reference(
              page: '${pointeur.page}',
              total: '$pagesMushafMedine',
              reference: pointeur.reference,
            ),
            style: AppTypography.tabulaire(
              textes.labelLarge ?? const TextStyle(),
            ),
          ),
        if (_mot(vue) case final String mot) ...<Widget>[
          Ecart.vXs,
          Text(mot, style: textes.bodySmall ?? const TextStyle()),
        ],
      ],
    );
  }
}

/// Le contenu presente : la page du mushaf, dans ses quatre etats de lecture.
class _PagePresentee extends ConsumerWidget {
  const _PagePresentee({required this.contenu});

  final ContenuPresente contenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PageCoran?> page = ref.watch(
      pageCoranProvider(contenu.page),
    );
    final AsyncValue<List<Sourate>?> sourates = ref.watch(souratesProvider);

    final VueLecteur lecteur = VueLecteur.depuis(
      pageDemandee: contenu.page,
      page: page.value,
      chargementEnCours: page.isLoading,
      sourates: sourates.value,
      // [QURAN-STAGE] Aucune position personnelle : l'etat presente est
      // ephemere, il n'a rien a voir avec le marque-page de qui que ce soit, et
      // l'enseignant n'a donc aucune reprise a se voir proposer.
      position: null,
    );

    return switch (lecteur.etat) {
      EtatLecteur.chargement => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Skeleton.texte(lignes: 6),
      ),
      EtatLecteur.indisponible => EmptyState(
        message: t.enseignant.salle.pageIndisponible,
        invitation: t.enseignant.salle.pageIndisponibleDetail,
        icone: AppIcons.horsLigne,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(pageCoranProvider(contenu.page)),
      ),
      EtatLecteur.corpusAbsent => EmptyState(
        message: t.enseignant.salle.corpusAbsent,
        invitation: t.enseignant.salle.corpusAbsentDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      ),
      EtatLecteur.lecture => _Texte(lecteur: lecteur),
    };
  }
}

/// Le texte de la page, decoupe par sourate.
///
/// **En registre de lecture, pas en registre de salle.** La salle est sombre ;
/// un texte coranique ne se lit pas sur un fond de scene video. La surface
/// reprend donc le parchemin du lecteur (`surfaceQuran`) plutot que d'inventer un
/// troisieme registre, et la taille est celle du rendu de document, jamais une
/// taille posee pour cette surface.
///
/// La composition -- flux continu, rosace de verset dessinee, sens de lecture du
/// document -- est celle du lecteur de l'eleve. `ponytail:` duplication assumee
/// de trois lignes de composition, faute d'un widget partage de page de mushaf.
/// Plafond : la troisieme surface qui rendra du Coran. Chemin de reprise :
/// extraire un composant de texte de page a ce moment-la, pas avant.
class _Texte extends StatelessWidget {
  const _Texte({required this.lecteur});

  final VueLecteur lecteur;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextStyle base = palette.surfaceQuran.applyTo(
      AppTypography.document(),
    );

    return DecoratedBox(
      decoration: palette.surfaceQuran.decoration(
        borderRadius: metriques.arrondi,
      ),
      child: ClipRRect(
        borderRadius: metriques.arrondi,
        child: Directionality(
          // Le sens de lecture appartient au document, pas a l'application : on
          // tourne les pages d'un mushaf de la droite vers la gauche, meme quand
          // l'interface autour est en francais.
          textDirection: TextDirection.rtl,
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                for (final SectionSourate section in lecteur.sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          for (final VersetCoran verset in section.versets)
                            ...<InlineSpan>[
                              TextSpan(text: '${verset.texte} '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                // Un numero de verset est un repere de mise en
                                // page, pas du texte revele : un lecteur d'ecran
                                // doit lire le verset, pas epeler son numero au
                                // milieu de la phrase.
                                child: ExcludeSemantics(
                                  child: RosaceVerset(numero: verset.numero),
                                ),
                              ),
                              const TextSpan(text: ' '),
                            ],
                        ],
                      ),
                      textAlign: TextAlign.justify,
                      style: base,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rien n'est presente au groupe.
///
/// Le seul chemin d'entree du Coran est ici quand la salle n'a pas encore de
/// page : un second bouton « Ouvrir le Coran » sous l'etat vide serait deux
/// fois la meme action sur le meme ecran.
class _Vide extends StatelessWidget {
  const _Vide({required this.onOuvrir});

  /// Ouvre la bibliotheque. `null` quand le lien ne porterait rien.
  final VoidCallback? onOuvrir;

  @override
  Widget build(BuildContext context) {
    final bool possible = onOuvrir != null;

    return EmptyState(
      message: t.enseignant.salle.rien,
      invitation: possible
          ? t.enseignant.salle.rienInvitation
          : t.enseignant.salle.attenteSalleDetail,
      icone: AppIcons.coran,
      libelleAction: t.salle.ouvrirCoran,
      onAction: onOuvrir,
      // Un vide qu'on ne peut pas combler ne propose rien : tant que la salle
      // n'est pas connectee, ouvrir le Coran n'atteindrait personne.
      registre: possible ? RegistreVide.actionnable : RegistreVide.subi,
    );
  }
}

/// Les controles pedagogiques : tourner la page pour tout le groupe.
///
/// **De premier niveau, jamais dans un menu.** Tourner la page est le geste de
/// l'enseignant pendant un cours de Coran ; le cacher derriere trois points
/// couterait un geste a chaque verset.
///
/// `[RESPONSIVE]` NAV-FLECHES-1 : deux fleches rondes de part et d'autre de la
/// page presentee ([BarrePrecedentSuivant]), a toutes les largeurs. Les verbes
/// complets (« Presenter la page precedente ») sont lus par le lecteur
/// d'ecran ; a l'ecran, une fleche ne se tronque pas, a 320 points ni a 200 %.
class _Commandes extends StatelessWidget {
  const _Commandes({
    required this.vue,
    required this.actives,
    required this.onPresenter,
    required this.onBibliotheque,
  });

  final VuePresentation vue;
  final bool actives;

  /// Presente la page demandee. Appele avec une page deja bornee a l'edition.
  final void Function(int page) onPresenter;

  final VoidCallback onBibliotheque;

  @override
  Widget build(BuildContext context) {
    final int? avant = vue.pagePrecedente;
    final int? apres = vue.pageSuivante;

    // NAV-FLECHES-1 : fleche, page presentee, fleche, a toutes les largeurs.
    // Une fleche qui ne peut pas aboutir (premiere ou derniere page, lien qui
    // ne porte plus) n'est pas rendue.
    final int page = vue.contenu?.page ?? 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BarrePrecedentSuivant(
          position: t.salle.seance.page(page: page, pages: pagesMushafMedine),
          positionSemantique: t.salle.seance.pageSemantique(
            page: page,
            pages: pagesMushafMedine,
          ),
          libellePrecedent: t.enseignant.salle.precedente,
          libelleSuivant: t.enseignant.salle.suivante,
          onPrecedent: actives && avant != null
              ? () => onPresenter(avant)
              : null,
          onSuivant: actives && apres != null
              ? () => onPresenter(apres)
              : null,
        ),
        Ecart.vSm,
        ActionPrincipale(
          libelle: t.salle.ouvrirCoran,
          niveau: NiveauAction.tertiaire,
          onPress: actives ? onBibliotheque : null,
        ),
      ],
    );
  }
}

/// La bibliotheque : les sourates, pour presenter un debut de sourate.
///
/// Elle rend une reference, pas une page : c'est le presentateur qui situe
/// « 2:1 » dans le mushaf, et lui seul, parce qu'une page ne se devine pas d'un
/// numero de sourate.
class _Bibliotheque extends ConsumerWidget {
  const _Bibliotheque();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Sourate>?> sourates = ref.watch(souratesProvider);
    final List<Sourate>? liste = sourates.value;

    if (liste == null) {
      return sourates.isLoading
          ? const Skeleton.liste(lignes: 6)
          : EmptyState(
              message: t.enseignant.salle.souratesIndisponibles,
              invitation: t.enseignant.salle.souratesIndisponiblesDetail,
              icone: AppIcons.horsLigne,
              libelleAction: t.commun.reessayer,
              onAction: () => ref.invalidate(souratesProvider),
            );
    }
    if (liste.isEmpty) {
      return EmptyState(
        message: t.enseignant.salle.corpusAbsent,
        invitation: t.enseignant.salle.corpusAbsentDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Sourate sourate in liste) _LigneSourate(sourate: sourate),
      ],
    );
  }
}

/// Une sourate de la bibliotheque.
class _LigneSourate extends StatelessWidget {
  const _LigneSourate({required this.sourate});

  final Sourate sourate;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Pressable(
      // Le libelle parle dit l'ACTE, parce qu'un element se lit par ce qu'il
      // declenche : ici, presenter le debut de cette sourate a tout le groupe.
      libelleSemantique: t.enseignant.salle.presenterSourate(
        sourate: sourate.nomTranslittere,
      ),
      onPress: () => Navigator.of(context).pop((
        sourate: sourate.numero,
        verset: 1,
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    sourate.nomTranslittere,
                    style: palette.surfaceRaised.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                  Text(
                    t.enseignant.salle.sourateDetail(
                      numero: '${sourate.numero}',
                      versets: '${sourate.nombreVersets}',
                    ),
                    style: palette.inkMuted.applyTo(
                      AppTypography.tabulaire(
                        textes.bodySmall ?? const TextStyle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Ecart.hSm,
            Icon(AppIcons.chevron.repos, size: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
