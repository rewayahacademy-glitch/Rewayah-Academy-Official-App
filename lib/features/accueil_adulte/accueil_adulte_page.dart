// L'accueil de l'eleve adulte (EA-2, planches 1.1 et 5, UX_REVIEW_07
// lignes 2 et 3).
//
// Aucun composant neuf : l'en-tete (`EntetePage`, `ClocheNotifications`), la
// photo de l'eleve (`PhotoEleve`), l'identite de la Classe (`IdentiteGroupe`)
// et la carte de seance CL-4 (`CarteSession`, donc `EmplacementEntree`),
// « Avant le prochain cours » (`EmplacementAvantProchainCours`, R17), les
// seances passees (`TimelineRow`) et la Bibliotheque unique
// (`BlocBibliotheque`, trois au plus). La seance lit les memes providers que
// l'Espace Classe : la carte dit la meme chose ici et la-bas.
//
// Le seul provider propre a l'ecran, [accueilAdulteProvider], n'a aucune
// source serveur : il rend `CapaciteIndisponible` (EA-BR), la demonstration
// le surcharge (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/journee.dart';
import '../../core/planning/service_planning.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/port_horloge_seance.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/timeline_row.dart';
import '../foyer/photo_eleve.dart';
import '../tc_espace_groupe/carte_session.dart';
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_espace_groupe/espace_groupe_page.dart' show IdentiteGroupe;

/// Une seance passee, telle que le serveur la rendrait : la seance, sa date
/// deja rendue, et l'absence seule (une presence est l'etat normal et ne
/// porte aucune pastille, 00_MAQUETTES planche 5, C5).
@immutable
class SeancePasseeAdulte {
  /// Cree la seance passee.
  const SeancePasseeAdulte({
    required this.seance,
    required this.dateRendue,
    this.absence = false,
  });

  /// La seance (plage, Classe, enseignant).
  final Seance seance;

  /// La date, deja rendue par le serveur.
  final String dateRendue;

  /// Vrai quand l'eleve etait absent.
  final bool absence;
}

/// Ce que l'accueil de l'eleve adulte lit, en une fois.
@immutable
class AccueilAdulteVM {
  /// Cree la vue.
  const AccueilAdulteVM({
    required this.prenom,
    this.cleAvatar,
    this.groupeId,
    this.ligneParcours,
    this.dernieresSeances = const <SeancePasseeAdulte>[],
    this.notificationsNonLues,
  });

  /// Le prenom de l'eleve.
  final String prenom;

  /// La cle de sa photo, `null` sans photo (initiales).
  final String? cleAvatar;

  /// Sa Classe, `null` tant qu'il n'en a aucune.
  final String? groupeId;

  /// « Mon parcours », une ligne deja rendue ; `null` : pas de section.
  final String? ligneParcours;

  /// Les dernieres seances, les plus recentes d'abord (trois montrees).
  final List<SeancePasseeAdulte> dernieresSeances;

  /// Les notifications non lues, telles que le service les rend.
  final int? notificationsNonLues;
}

/// L'accueil de l'eleve adulte. **Aucune source serveur a ce jour** (ligne
/// EA-BR) : `CapaciteIndisponible`, que `BlocAsynchrone` dit comme tel, sans
/// « Reessayer ». La demonstration le surcharge.
final FutureProvider<AccueilAdulteVM> accueilAdulteProvider =
    FutureProvider<AccueilAdulteVM>(
      (Ref _) => Future<AccueilAdulteVM>.error(
        const CapaciteIndisponible('accueil_eleve_adulte'),
      ),
    );

/// L'accueil de l'eleve adulte : salutation et cloche, prochaine seance,
/// « Avant le prochain cours » (s'il y a quelque chose a faire), « Mon
/// parcours » en une ligne, dernieres seances (3) et ressources de la
/// Classe (3). Deux colonnes seulement a partir de 840 de largeur utile
/// divisee par le facteur de texte (contrat D), par rangees.
class AccueilAdultePage extends ConsumerWidget {
  /// Cree l'accueil.
  const AccueilAdultePage({
    super.key,
    this.onNotifications,
    this.onRejoindre,
    this.onVoirRessources,
  });

  /// Ouvre le centre de notifications.
  final VoidCallback? onNotifications;

  /// Ce que fait le bouton de l'emplacement d'entree.
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  /// Ouvre la Bibliotheque de la Classe.
  final void Function(String groupeId)? onVoirRessources;

  /// Le nombre de dernieres seances et de ressources montrees.
  static const int limite = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AccueilAdulteVM> lecture = ref.watch(
      accueilAdulteProvider,
    );
    final AccueilAdulteVM? vue = lecture.value;
    return PageShell(
      entete: vue == null
          ? null
          : _Salutation(vue: vue, onNotifications: onNotifications),
      child: BlocAsynchrone<AccueilAdulteVM>(
        valeur: lecture,
        squelette: const SqueletteCarteSession(),
        onReessayer: () => ref.invalidate(accueilAdulteProvider),
        construire: (AccueilAdulteVM vue) => _Corps(
          vue: vue,
          onRejoindre: onRejoindre,
          onVoirRessources: onVoirRessources,
        ),
      ),
    );
  }
}

/// La salutation en une ligne, la photo de l'eleve (K-44) et la cloche.
class _Salutation extends StatelessWidget {
  const _Salutation({required this.vue, required this.onNotifications});

  final AccueilAdulteVM vue;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        PhotoEleve(
          prenom: vue.prenom,
          cleAvatar: vue.cleAvatar,
          diametre: SelecteurProfils.diametreLarge,
        ),
        Ecart.hMd,
        Expanded(
          child: EntetePage(
            titre: t.adulte.accueil.salutation(prenom: vue.prenom),
            actions: <Widget>[
              ClocheNotifications(
                onPress: onNotifications,
                nonLues: vue.notificationsNonLues,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({required this.vue, this.onRejoindre, this.onVoirRessources});

  final AccueilAdulteVM vue;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(String groupeId)? onVoirRessources;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? groupeId = vue.groupeId;
    final List<SeancePasseeAdulte> passees = vue.dernieresSeances
        .take(AccueilAdultePage.limite)
        .toList();
    final String? parcours = vue.ligneParcours;

    // Sans Classe : un etat subi, rien a faire ici (l'inscription vit
    // ailleurs, doc section 3).
    if (groupeId == null) {
      return EmptyState(
        message: t.adulte.accueil.aucuneClasse,
        invitation: t.adulte.accueil.aucuneClasseDetail,
        icone: AppIcons.cours,
        registre: RegistreVide.subi,
      );
    }

    final List<Widget> seance = <Widget>[
      SectionHeader(titre: t.adulte.accueil.prochaineSeance),
      Ecart.vMd,
      _Seance(groupeId: groupeId, onRejoindre: onRejoindre),
    ];

    final List<SlotAction> actions =
        ref
            .watch(travailAVenirProvider((groupeId: groupeId, studentId: null)))
            .value ??
        const <SlotAction>[];
    final bool portBranche = ref.watch(portTravailAVenirProvider) != null;
    // Seulement ce que les donnees demandent : sans action, pas de section.
    final List<Widget> avant = portBranche && actions.isNotEmpty
        ? <Widget>[
            EmplacementAvantProchainCours(
              actions: actions.take(AccueilAdultePage.limite).toList(),
              portBranche: true,
            ),
          ]
        : const <Widget>[];

    final List<Widget> ligneParcours = parcours == null
        ? const <Widget>[]
        : <Widget>[
            SectionHeader(titre: t.adulte.accueil.parcours),
            Ecart.vMd,
            AppCard(
              child: Text(
                parcours,
                key: const ValueKey<String>('accueil-adulte-parcours'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ];

    final List<Widget> dernieres = passees.isEmpty
        ? const <Widget>[]
        : <Widget>[
            SectionHeader(titre: t.adulte.accueil.dernieresSeances),
            Ecart.vMd,
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final (int i, SeancePasseeAdulte s)
                      in passees.indexed) ...<Widget>[
                    if (i > 0) Ecart.vLg,
                    _SeancePassee(seance: s),
                  ],
                ],
              ),
            ),
          ];

    final Widget ressources = BlocBibliotheque(
      emplacement: SlotBibliotheque(groupeId: groupeId),
      titre: t.adulte.accueil.ressources,
      limite: AccueilAdultePage.limite,
      onVoirTout: onVoirRessources == null
          ? null
          : () => onVoirRessources!(groupeId),
    );

    List<Widget> bloc(List<List<Widget>> sections) => <Widget>[
      for (final (int i, List<Widget> s)
          in sections
              .where((List<Widget> s) => s.isNotEmpty)
              .indexed) ...<Widget>[if (i > 0) Ecart.vSection, ...s],
    ];

    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double facteur = MediaQuery.textScalerOf(contexte).scale(1);
        final bool deuxColonnes =
            contraintes.maxWidth / facteur >= AppGabarit.seuilEtendu;
        if (!deuxColonnes) {
          return FocusTraversalGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: bloc(<List<Widget>>[
                seance,
                avant,
                ligneParcours,
                dernieres,
                <Widget>[ressources],
              ]),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Rangee(
              principale: seance,
              laterale: bloc(<List<Widget>>[avant, ligneParcours]),
            ),
            Ecart.vSection,
            _Rangee(
              principale: dernieres.isEmpty ? <Widget>[ressources] : dernieres,
              laterale: dernieres.isEmpty
                  ? const <Widget>[]
                  : <Widget>[ressources],
            ),
          ],
        );
      },
    );
  }
}

/// La prochaine seance : l'identite de la Classe (photo publique de
/// l'enseignant, R18) puis la carte de seance CL-4, lues aux memes providers
/// que l'Espace Classe.
class _Seance extends ConsumerWidget {
  const _Seance({required this.groupeId, this.onRejoindre});

  final String groupeId;
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GroupSummaryVM?> lecture = ref.watch(
      groupeProvider(groupeId),
    );
    return BlocAsynchrone<GroupSummaryVM?>(
      valeur: lecture,
      squelette: const SqueletteCarteSession(),
      onReessayer: () => ref.invalidate(groupeProvider(groupeId)),
      vide: EmptyState(
        message: t.adulte.accueil.aucuneClasse,
        invitation: t.adulte.accueil.aucuneClasseDetail,
        icone: AppIcons.cours,
        registre: RegistreVide.subi,
      ),
      construire: (GroupSummaryVM? trouve) {
        final AsyncValue<SessionClockVM> flux = ref.watch(
          horlogeGroupeProvider(groupeId),
        );
        final SessionClockVM? tic = flux.value;
        final GroupSummaryVM identite = tic == null
            ? trouve!
            : trouve!.avecHorloge(tic);
        final GroupHomeVM espace = GroupHomeVM.pourRole(
          identite: identite,
          role: RoleEspaceGroupe.eleve,
        );
        final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
        final void Function(GroupSummaryVM groupe)? entrer = onRejoindre;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            IdentiteGroupe(groupe: identite, repliInitiales: true),
            Ecart.vXl,
            CarteSession(
              espace: espace,
              horsLigne: horsLigne,
              annulee: ref.watch(seanceAnnuleeProvider(groupeId)),
              lectureEchouee: flux.hasError && tic == null,
              onReessayer: () => ref
                ..invalidate(horsLigneProvider)
                ..invalidate(horlogeGroupeProvider(groupeId)),
              onRejoindre: horsLigne || entrer == null
                  ? null
                  : () => entrer(identite),
            ),
          ],
        );
      },
    );
  }
}

/// Une seance passee : sa date, puis la ligne de journee partagee ; une
/// pastille seulement pour une absence.
class _SeancePassee extends StatelessWidget {
  const _SeancePassee({required this.seance});

  final SeancePasseeAdulte seance;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            seance.dateRendue,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          TimelineRow(entree: EntreeJournee.cours(seance.seance)),
          if (seance.absence) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(
                libelle: t.adulte.accueil.absence,
                ton: TonEtat.avertissement,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une rangee de deux colonnes (deux tiers, un tiers), un groupe de focus.
class _Rangee extends StatelessWidget {
  const _Rangee({required this.principale, required this.laterale});

  final List<Widget> principale;
  final List<Widget> laterale;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: principale,
            ),
          ),
          Ecart.hXxl,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: laterale,
            ),
          ),
        ],
      ),
    );
  }
}
