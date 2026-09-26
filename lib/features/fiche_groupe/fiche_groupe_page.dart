import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/port_horloge_seance.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../foyer/photo_eleve.dart' show PhotoEleve;
import '../tc_espace_groupe/carte_session.dart';
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_espace_groupe/espace_groupe_page.dart' show IdentiteGroupe;
import 'fiche_eleve_enseignant.dart';
import 'preparation_seance.dart';

/// `ENS-07` : la fiche d'un groupe, telle que son enseignant la lit.
///
/// **Une pose, jamais une destination.** Elle s'ouvre depuis la Journee, par la
/// carte de seance, et vit donc hors de la coquille de navigation : elle porte
/// pour cela un chemin de sortie visible, en tete de page. L'enseignant a trois
/// destinations, et il atteint un groupe par le cours qu'il donne, pas par un
/// annuaire.
///
/// **Une fiche se lit, elle ne s'edite pas.** Aucune action principale : c'est
/// l'administration qui compose les groupes (`ADM-09`), et un bouton
/// « ajouter » ici serait une promesse que la base refuserait --
/// `groupe_membre_ajouter` est bornee a `app_role() = 'admin'`.
///
/// **Aucun nom de famille, aucun courriel, aucun telephone.** La garantie n'est
/// pas dans cet ecran mais dans le modele qu'il lit : [MembreSeance] n'a aucun
/// champ de nom de famille, il n'y a donc rien a oublier de masquer.
/// `MembreGroupe` (`core/admin/service_groupes.dart`) en porte un, parce que
/// l'administration en a le droit : il n'est pas employe ici (ADR-008).
///
/// Le `niveau` affiche vient de `student_profiles.level`, **un texte libre**.
/// Ce n'est pas le niveau institutionnel du programme, qui vit dans
/// `progression_historique` : le libelle dit « niveau indique », et jamais
/// « niveau du programme » (en-tete de `0021`).
///
/// **CL-4.4 : l'Espace Classe enseignant (CLS-ENS-01 et 02).** La fiche porte
/// desormais, dans cet ordre : l'identite de la Classe, la carte de seance
/// (`CarteSession` partagee avec l'eleve, « Preparer l'entree »), la
/// preparation de la prochaine seance, les eleves, les supports recents. Sans
/// onglets. Le seul bouton principal est celui de la carte de seance.
class FicheGroupePage extends ConsumerWidget {
  /// Cree la fiche d'un groupe.
  const FicheGroupePage({
    required this.groupeId,
    super.key,
    this.onPreparer,
    this.onOuvrirEleve,
  });

  /// Le groupe a montrer.
  final String groupeId;

  /// **Le point d'entree unique vers la fiche eleve (`ENS-11`, etape EN-4).**
  /// Avec lui, toute la ligne d'un eleve se presse et le transmet avec son
  /// `studentId`. Sans lui, la ligne ne se presse pas et ne porte aucun
  /// chevron : rien ne promet un ecran qui n'existe pas encore.
  final void Function(String studentId)? onOuvrirEleve;

  /// Le point d'entree du routeur et de la demonstration (EN-4) : avec lui,
  /// toute la ligne d'un eleve ouvre sa fiche (ENS-11), que l'Espace Classe
  /// ouvre lui-meme parce qu'il detient la projection de l'eleve. Il n'a rien
  /// d'autre a faire.
  static void ficheEleve(String studentId) {}

  /// Ce que fait « Preparer l'entree ». Par defaut, le chemin existant vers la
  /// preparation : `/salle` avec son billet, qui ouvre d'abord le pre-vol
  /// complet de l'enseignant. La demonstration le remplace.
  final void Function(String sessionId)? onPreparer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pas de titre d'ecran (CL-4.4b) : comme chez l'eleve, le nom de la
    // Classe EST le titre, porte par `IdentiteGroupe`. Le chemin de sortie,
    // visible et en haut, au bord de debut : cet ecran n'a pas de barre de
    // navigation pour le porter.
    return PageShell(
      entete: const _Sortie(),
      child: _Corps(
        groupeId: groupeId,
        onPreparer: onPreparer,
        onOuvrirEleve: onOuvrirEleve,
      ),
    );
  }
}

/// Le retour vers la Journee, au bord de debut (contrat B).
class _Sortie extends StatelessWidget {
  const _Sortie();

  @override
  Widget build(BuildContext context) {
    return _EnDebut(
      child: ActionPrincipale(
        libelle: t.enseignant.ficheGroupe.retour,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        // `go` et non `pop` : la fiche peut avoir ete ouverte par une adresse,
        // et une sortie qui ne fonctionne que sur une pile existante laisserait
        // l'enseignant enferme.
        onPress: () => GoRouter.of(context).go(Routes.enseignantJournee),
      ),
    );
  }
}

/// Les cinq etats de la fiche, plus « ce groupe n'est pas le votre ».
class _Corps extends ConsumerStatefulWidget {
  const _Corps({required this.groupeId, this.onPreparer, this.onOuvrirEleve});

  final String groupeId;
  final void Function(String sessionId)? onPreparer;
  final void Function(String studentId)? onOuvrirEleve;

  @override
  ConsumerState<_Corps> createState() => _CorpsState();
}

class _CorpsState extends ConsumerState<_Corps> {
  /// L'eleve dont la fiche occupe la colonne des eleves, sur bureau (EN-4).
  String? _ouvert;

  /// Vrai quand l'Espace Classe tient sur deux colonnes : la fiche s'ouvre
  /// alors en panneau, a la place du roster ; sinon, en feuille.
  bool _large = false;

  /// ENS-11 : toute la ligne d'un eleve ouvre sa fiche, feuille sous 840,
  /// panneau au-dessus. Le rappel `onOuvrirEleve` est ensuite prevenu.
  void _ouvrir(EleveFiche eleve) {
    if (_large) {
      setState(() => _ouvert = eleve.membre.studentId);
    } else {
      ouvrirFicheEleve(context, eleve);
    }
    widget.onOuvrirEleve?.call(eleve.membre.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final String groupeId = widget.groupeId;
    final void Function(String sessionId)? onPreparer = widget.onPreparer;
    final void Function(String studentId)? onOuvrirEleve = widget.onOuvrirEleve;
    final AsyncValue<List<GroupeEnseignant>> groupes = ref.watch(
      groupesEnseignantProvider,
    );
    final AsyncValue<List<MembreSeance>> membres = ref.watch(
      membresGroupeEnseignantProvider(groupeId),
    );

    if (groupes.hasError || membres.hasError) {
      return EmptyState(
        message: t.enseignant.ficheGroupe.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () {
          ref.invalidate(groupesEnseignantProvider);
          ref.invalidate(membresGroupeEnseignantProvider(groupeId));
        },
      );
    }

    if (!groupes.hasValue || !membres.hasValue) {
      // Le squelette prend la forme de ce qui arrive : l'identite de la
      // Classe, la carte de seance, puis trois lignes d'eleve. Un seul noeud
      // lu, les os exclus (revue UX n° 10).
      return Semantics(
        label: t.enseignant.ficheGroupe.chargementClasse,
        child: const ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Skeleton.tuileBento(hauteur: 140),
              Ecart.vXl,
              SqueletteCarteSession(),
              Ecart.vXl,
              Skeleton.liste(lignes: 3),
            ],
          ),
        ),
      );
    }

    GroupeEnseignant? trouve;
    for (final GroupeEnseignant groupe in groupes.requireValue) {
      if (groupe.id == groupeId) {
        trouve = groupe;
      }
    }
    final GroupeEnseignant? groupe = trouve;

    if (groupe == null) {
      // `mes_groupes_v` ne rend que les groupes actifs de l'appelant : une
      // absence ici n'est pas une erreur de lecture, c'est un groupe cloture ou
      // celui d'un collegue. Un etat subi : l'enseignant ne peut rien y faire.
      return EmptyState(
        message: t.enseignant.ficheGroupe.introuvable,
        invitation: t.enseignant.ficheGroupe.introuvableDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    final Widget entete = _EnteteGroupe(groupe: groupe);
    final Widget seance = _Seance(groupeId: groupe.id, onPreparer: onPreparer);
    final Widget preparation = _Preparation(groupeId: groupe.id);
    final Widget eleves = _Membres(
      membres: membres.requireValue,
      projections: ref.watch(projectionElevesProvider(groupe.id)),
      onOuvrirEleve: onOuvrirEleve == null
          ? null
          : (String id) {
              final EleveFiche? fiche = _fiche(
                membres.requireValue,
                groupe,
                id,
              );
              if (fiche != null) _ouvrir(fiche);
            },
      revue: IntrinsicWidth(
        child: ActionPrincipale(
          libelle: t.enseignant.ficheGroupe.revue,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: () => GoRouter.of(context).go(Routes.revuePour(groupe.id)),
        ),
      ),
    );
    // EN-3 : « Ressources recentes », trois au plus (planche 2). « Voir tout »
    // n'est pas pose : aucune destination enseignant ne liste encore les
    // ressources d'une Classe.
    final Widget ressources = BlocBibliotheque(
      emplacement: SlotBibliotheque(groupeId: groupe.id),
      titre: t.enseignant.ficheGroupe.ressourcesTitre,
      limite: 3,
    );
    // Rendue seulement quand le serveur (ou la demonstration) la fournit.
    final ProgressionCompacte? avancement = ref.watch(
      progressionGroupeProvider(groupe.id),
    );

    // La Classe, dans l'ordre de lecture : seance, preparation, progression,
    // ressources.
    final List<Widget> classe = <Widget>[
      seance,
      Ecart.vSection,
      preparation,
      if (avancement != null) ...<Widget>[
        Ecart.vSection,
        _ProgressionClasse(valeur: avancement),
      ],
      Ecart.vSection,
      ressources,
    ];

    // [RESPONSIVE] EN-3 (planche 2, rectification 5) : sur bureau, deux
    // colonnes, la Classe au debut et les eleves a la fin. Deux colonnes
    // seulement quand la largeur utile divisee par le facteur de texte
    // atteint 840 ; en dessous, une colonne : la Classe puis les eleves.
    // Chaque colonne est un `FocusTraversalGroup`, le focus suit l'ordre de
    // lecture. Pas d'onglets, pas de troisieme zone.
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double facteur = MediaQuery.textScalerOf(contexte).scale(1);
        final bool deuxColonnes =
            contraintes.maxWidth / facteur >= AppGabarit.seuilEtendu;
        _large = deuxColonnes;
        final EleveFiche? ouverte = deuxColonnes
            ? _fiche(membres.requireValue, groupe, _ouvert)
            : null;

        final Widget colonneClasse = FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: classe,
          ),
        );
        final Widget colonneEleves = FocusTraversalGroup(child: eleves);

        if (!deuxColonnes) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              entete,
              Ecart.vSection,
              colonneClasse,
              Ecart.vSection,
              colonneEleves,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            entete,
            Ecart.vSection,
            _Rangee(
              debut: colonneClasse,
              fin: switch (ouverte) {
                null => colonneEleves,
                final EleveFiche e => FocusTraversalGroup(
                  child: PanneauFicheEleve(
                    key: ValueKey<String>('panneau-${e.membre.studentId}'),
                    eleve: e,
                    onFermer: () => setState(() => _ouvert = null),
                  ),
                ),
              },
            ),
          ],
        );
      },
    );
  }

  /// La vue de fiche d'un eleve de la Classe, ou nul s'il n'y est plus.
  EleveFiche? _fiche(
    List<MembreSeance> membres,
    GroupeEnseignant groupe,
    String? id,
  ) {
    if (id == null) return null;
    for (final MembreSeance m in membres) {
      if (m.studentId == id) {
        return EleveFiche(
          membre: m,
          classe: groupe.libelle,
          projection: ref.read(projectionElevesProvider(groupe.id))[id],
        );
      }
    }
    return null;
  }
}

/// Une rangee de deux colonnes egales, separees de 24. Un groupe de focus.
class _Rangee extends StatelessWidget {
  const _Rangee({required this.debut, required this.fin});

  final Widget debut;
  final Widget fin;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: debut),
          Ecart.hXxl,
          Expanded(child: fin),
        ],
      ),
    );
  }
}

/// Pose une action au bord de debut, a sa largeur naturelle.
///
/// `IntrinsicWidth` : sans lui, `ActionPrincipale` s'etirerait sur toute la
/// largeur et centrerait son libelle. Borne par la largeur disponible, le
/// libelle passe a la ligne a 200 % au lieu de deborder.
class _EnDebut extends StatelessWidget {
  const _EnDebut({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IntrinsicWidth(child: child),
    );
  }
}

/// La carte de la prochaine seance, vue par l'enseignant (CLS-ENS-01, 02).
///
/// La **meme** `CarteSession` que l'eleve, avec `RoleEntree.enseignant` : a
/// l'ouverture, l'emplacement devient « Preparer l'entree », qui mene a la
/// preparation (le pre-vol de la salle), jamais directement dans la salle.
class _Seance extends ConsumerWidget {
  const _Seance({required this.groupeId, this.onPreparer});

  final String groupeId;
  final void Function(String sessionId)? onPreparer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GroupSummaryVM?> lecture = ref.watch(
      groupeProvider(groupeId),
    );

    if (!lecture.hasValue && !lecture.hasError) {
      return const SqueletteCarteSession();
    }

    final GroupSummaryVM? classe = lecture.value;
    if (lecture.hasError || classe == null) {
      // La seance n'a pas pu etre lue : la carte le dit, et n'offre qu'une
      // relecture. Le reste de la fiche reste lisible.
      return AppCard(
        dominante: true,
        child: EmptyState(
          message: lecture.hasError
              ? t.classe.entree.indisponible
              : t.classe.entree.aucune,
          icone: AppIcons.cours,
          registre: RegistreVide.subi,
          libelleAction: lecture.hasError ? t.classe.entree.reessayer : null,
          onAction: lecture.hasError
              ? () => ref.invalidate(groupeProvider(groupeId))
              : null,
        ),
      );
    }

    final AsyncValue<SessionClockVM> flux = ref.watch(
      horlogeGroupeProvider(groupeId),
    );
    final SessionClockVM? tic = flux.value;
    final GroupSummaryVM identite = tic == null
        ? classe
        : classe.avecHorloge(tic);
    final GroupHomeVM espace = GroupHomeVM.pourRole(
      identite: identite,
      role: RoleEspaceGroupe.enseignant,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? sessionId =
        identite.horloge?.sessionId ?? identite.prochaineSeance?.sessionId;
    final void Function(String sessionId) preparer =
        onPreparer ?? _versPreparation(context, groupeId);

    return CarteSession(
      espace: espace,
      horsLigne: horsLigne,
      annulee: ref.watch(seanceAnnuleeProvider(groupeId)),
      lectureEchouee: flux.hasError && tic == null,
      onReessayer: () => ref
        ..invalidate(horsLigneProvider)
        ..invalidate(horlogeGroupeProvider(groupeId)),
      onRejoindre: horsLigne || sessionId == null
          ? null
          : () => preparer(sessionId),
    );
  }

  /// Le chemin existant vers la preparation : la salle canonique, qui montre
  /// d'abord le pre-vol complet de l'enseignant (`PreCours`) et n'entre
  /// qu'apres. Le billet passe par `extra`, jamais par l'URL (ADR-005).
  static void Function(String) _versPreparation(
    BuildContext context,
    String groupeId,
  ) =>
      (String sessionId) => GoRouter.of(context).go(
        Routes.salle,
        extra: BilletSalle(
          sessionId: sessionId,
          emisA: DateTime.now(),
          preparation: true,
          groupeId: groupeId,
        ),
      );
}

/// La preparation de la prochaine seance : support prevu, position de
/// reprise, objectif. Aucun lien « Modifier » : aucune destination d'edition
/// n'existe encore.
class _Preparation extends ConsumerWidget {
  const _Preparation({required this.groupeId});

  final String groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PreparationSeance? preparation = ref.watch(
      preparationSeanceProvider(groupeId),
    );
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    final List<(String, String?)> candidates = <(String, String?)>[
      (t.enseignant.ficheGroupe.supportPrevu, preparation?.supportPrevu),
      (t.enseignant.ficheGroupe.positionReprise, preparation?.positionReprise),
      (t.enseignant.ficheGroupe.objectif, preparation?.objectif),
    ];
    final List<(String, String)> lignes = <(String, String)>[
      for (final (String libelle, String? valeur) in candidates)
        if (valeur != null && valeur.trim().isNotEmpty)
          (libelle, valeur.trim()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.ficheGroupe.preparationTitre),
        Ecart.vSm,
        AppCard(
          child: lignes.isEmpty
              ? Text(
                  t.enseignant.ficheGroupe.preparationVide,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final (int i, (String, String) ligne)
                        in lignes.indexed) ...<Widget>[
                      if (i > 0) Ecart.vLg,
                      MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              ligne.$1,
                              style: palette.inkMuted.applyTo(
                                textes.bodySmall ?? const TextStyle(),
                              ),
                            ),
                            Ecart.vXs,
                            Text(
                              ligne.$2,
                              style: textes.titleSmall ?? const TextStyle(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// L'identite de la Classe, la **meme** que chez l'eleve (CL-4.4b).
///
/// `IdentiteGroupe` partage : le nom de la Classe en titre, le cours et le
/// niveau, l'enseignant, puis la capacite en petite `StatusPill`
/// (« 3 eleves sur 6 places »). Le rendez-vous hebdomadaire tient sur une
/// ligne discrete. Aucune tuile « places libres » pleine largeur.
///
/// Tant que le resume de la Classe n'est pas lu, ou s'il ne peut pas l'etre,
/// le nom, l'horaire et la capacite se lisent sur `mes_groupes_v`, dans le
/// meme ordre et la meme forme.
class _EnteteGroupe extends ConsumerWidget {
  const _EnteteGroupe({required this.groupe});

  final GroupeEnseignant groupe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Une seule visio commune par semaine depuis le pivot : le creneau du
    // groupe EST l'heure du cours.
    final String horaire = t.enseignant.ficheGroupe.creneauHebdo(
      jour: _jour(groupe.creneau),
      heure: _heure(groupe.creneau),
    );
    // Enfants ou Adultes : une information pedagogique, sur la ligne de
    // contexte discrete (revue CL-4.R, m7). Cles existantes, aucune jumelle.
    final String typePublic = switch (groupe.type) {
      TypePublicGroupe.enfant => t.admin.groupes.typeEnfant,
      TypePublicGroupe.adulte => t.admin.groupes.typeAdulte,
    };
    final GroupSummaryVM? resume = ref.watch(groupeProvider(groupe.id)).value;
    if (resume != null) {
      // Initiales en repli, jamais de pastille « Photo a fournir » ici :
      // l'enseignant lit sa Classe, pas son dossier (CL-4.4).
      return IdentiteGroupe(
        groupe: resume,
        repliInitiales: true,
        ligneDiscrete: horaire,
        typePublic: typePublic,
      );
    }

    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            groupe.libelle,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
          Ecart.vXs,
          Text(
            typePublic,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            horaire,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          // Le seuil affiche est celui du groupe, jamais un chiffre calcule
          // ici : cinq enfants, six adultes, et c'est la base qui le tient.
          StatusPill(
            libelle: LibellesGroupe.capacitePhrase(
              membres: groupe.nbMembres,
              seuil: groupe.seuilMax,
            ),
            ton: groupe.complet ? TonEtat.avertissement : TonEtat.neutre,
          ),
        ],
      ),
    );
  }
}

/// La section « Eleves », ou le fait qu'il n'y en ait aucun.
class _Membres extends StatelessWidget {
  const _Membres({
    required this.membres,
    required this.projections,
    required this.revue,
    this.onOuvrirEleve,
  });

  final List<MembreSeance> membres;
  final Map<String, ProjectionEleve> projections;
  final Widget revue;
  final void Function(String studentId)? onOuvrirEleve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: t.enseignant.ficheGroupe.elevesTitre,
          compteur: membres.length,
        ),
        Ecart.vSm,
        if (membres.isEmpty)
          EmptyState(
            message: t.enseignant.ficheGroupe.aucunMembre,
            invitation: t.enseignant.ficheGroupe.aucunMembreDetail,
            icone: AppIcons.rienAAfficher,
            // Un etat subi : c'est l'administration qui compose les groupes,
            // l'enseignant ne peut pas y remedier. Aucun bouton, donc.
            registre: RegistreVide.subi,
          )
        else
          // Une seule surface groupee, une ligne par eleve (CL-4.4b), jamais
          // une carte par eleve.
          GroupeReglages(
            lignes: <LigneRubrique>[
              for (final MembreSeance membre in membres)
                _ligneMembre(
                  membre,
                  projections[membre.studentId],
                  onOuvrirEleve,
                ),
            ],
          ),
        Ecart.vSm,
        // Au bord de fin, sous la carte : un lien, pas une action principale.
        Align(alignment: AlignmentDirectional.centerEnd, child: revue),
      ],
    );
  }
}

/// Un eleve, une ligne : sa photo (`PhotoEleve`, initiales en repli ; E5,
/// K-44), son prenom en titre, puis une seule ligne secondaire « niveau ·
/// reprise » et, dessous, son dernier point. En fin de ligne, son indicateur :
/// un point **et** un mot (`StatusPill`), jamais la couleur seule. En texte
/// neutre : rien de ce que R15 interdit, le modele n'en porte pas.
///
/// L'identifiant immuable reste lisible, discret, avant l'indicateur.
///
/// Avec [onOuvrirEleve], **toute la ligne** est une seule cible, lue d'un bloc,
/// sans icone d'action concurrente (UX_REVIEW_04 n° 9 d). Sans lui, la ligne
/// ne se presse pas (`MergeSemantics`).
LigneRubrique _ligneMembre(
  MembreSeance membre,
  ProjectionEleve? projection,
  void Function(String studentId)? onOuvrirEleve,
) {
  final String? niveau = membre.niveau?.trim();
  final String? page = projection?.pageReprise?.trim();
  final String? point = projection?.dernierPoint?.trim();
  final String resume = <String>[
    if (niveau != null && niveau.isNotEmpty) niveau,
    if (page != null && page.isNotEmpty)
      t.enseignant.ficheGroupe.repriseEleve(page: page),
  ].join(' · ');
  final String legende = <String>[
    if (resume.isNotEmpty) resume,
    if (point != null && point.isNotEmpty)
      t.enseignant.ficheGroupe.dernierPoint(texte: point),
  ].join('\n');

  return LigneRubrique(
    // `libelle` rend le prenom, ou l'identifiant immuable quand la base l'a
    // masque en observation.
    libelle: membre.libelle,
    // La photo de l'eleve, visible de son enseignant (E5, decision du
    // directeur du 26/09/2026, K-44). La ligne est lue par le prenom.
    meneur: ExcludeSemantics(
      child: PhotoEleve(
        prenom: membre.libelle,
        cleAvatar: projection?.cleAvatar,
        diametre: 40,
      ),
    ),
    // L'identifiant immuable reste lisible, discret, en fin de ligne. [A11Y]
    valeur: membre.identifiantImmuable == membre.libelle
        ? null
        : membre.identifiantImmuable,
    legende: legende.isEmpty ? null : legende,
    marque: switch (projection?.indicateur) {
      null => null,
      IndicateurEleve.regulier => StatusPill(
        libelle: t.enseignant.ficheGroupe.indicateurRegulier,
        ton: TonEtat.succes,
      ),
      IndicateurEleve.aRenforcer => StatusPill(
        libelle: t.enseignant.ficheGroupe.indicateurARenforcer,
        ton: TonEtat.avertissement,
      ),
      IndicateurEleve.absence => StatusPill(
        libelle: t.enseignant.ficheGroupe.indicateurAbsence,
        ton: TonEtat.neutre,
      ),
    },
    onPress: onOuvrirEleve == null
        ? null
        : () => onOuvrirEleve(membre.studentId),
  );
}

/// « Progression de la classe » en une ligne : l'etape commune et sa valeur
/// ecrites, puis la barre, en un seul noeud (UX_REVIEW_04 n° 9 b). Une
/// barre, jamais un anneau.
class _ProgressionClasse extends StatelessWidget {
  const _ProgressionClasse({required this.valeur});

  final ProgressionCompacte valeur;

  @override
  Widget build(BuildContext context) {
    final String texte = t.classe.entree.progressionValeur(
      chapitre: valeur.chapitre,
      pourcentage: (valeur.fraction * 100).round(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: t.enseignant.ficheGroupe.progressionTitre),
        Ecart.vSm,
        Semantics(
          label: texte,
          child: ExcludeSemantics(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    texte,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Ecart.hLg,
                Expanded(
                  child: LinearProgressIndicator(value: valeur.fraction),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Le jour du creneau, en clair. `t.disponibilites.joursLongs` est lu par sept
/// ecrans : c'est la seule liste de jours du produit.
String _jour(Creneau creneau) => t.disponibilites.joursLongs[creneau.jour - 1];

/// L'heure pleine du creneau, sur deux chiffres.
///
/// Un entier, pas un instant : ce n'est donc pas le formatage `HH:MM` d'une
/// `DateTime` qui existe deja deux fois dans le depot, et il n'y a rien a
/// reutiliser ici.
String _heure(Creneau creneau) =>
    '${creneau.heure.toString().padLeft(2, '0')}:00';
