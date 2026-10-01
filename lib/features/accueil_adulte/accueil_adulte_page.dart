// L'accueil de l'eleve adulte (EA-2, planches 1.1 et 5, UX_REVIEW_07
// lignes 2 et 3).
//
// Aucun composant neuf (K-51) : l'en-tete (`EntetePage`,
// `ClocheNotifications`), la lecture du groupe et sa carte de seance CL-4
// (`LecteurGroupe`, `LectureGroupe.identiteEtCarte`, donc `IdentiteGroupe`,
// `CarteSession` et `EmplacementEntree`) et la disposition par rangees
// (`ColonnesParRangees`) sont ceux de l'Espace Classe, extraits de
// `tc_espace_groupe/espace_groupe_page.dart` et employes par les deux
// pages ; « Avant le prochain cours » (`EmplacementAvantProchainCours`, R17),
// les seances passees (`GroupeReglages` : la date, puis une seule ligne, la
// plage ; une pastille pour une absence) et la Bibliotheque unique
// (`BlocBibliotheque`, trois au plus).
//
// Pas de photo de l'eleve dans l'en-tete : K-44 porte sur les ecrans ou
// l'enseignant voit l'eleve (outils/yaaden/YAADEN_RULES.md, ligne 44, « SI
// enseignant ALORS ... photo de l'eleve visible (K-44) » ; REVUE_EN-R m4),
// et ni la planche 1.1 ni 00_MAQUETTES ne la placent ici. La salutation
// tient ainsi sur une ligne a 390 (rectification C6), et passe a la ligne
// entre les mots a 200 %.
//
// Reportes, dits ici : « Voir mon historique » de « Mon parcours »
// (00_MAQUETTES 1.1, P) attend l'historique d'EA-3. La cloche ouvre ce que
// la coquille lui donne : en demonstration, le `NotificationsPage` existant,
// ou se trouve l'invitation recue par le second adulte (EA-7) ; le centre de
// notifications de l'eleve adulte reste a EA-8.
//
// Le seul provider propre a l'ecran, [accueilAdulteProvider], n'a aucune
// source serveur : il rend `CapaciteIndisponible` (EA-BR-04), la
// demonstration le surcharge (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../tc_espace_groupe/emplacements_groupe.dart';
import '../tc_espace_groupe/espace_groupe_page.dart'
    show ColonnesParRangees, LecteurGroupe, LectureGroupe, SqueletteGroupe;

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
    this.groupeId,
    this.ligneParcours,
    this.dernieresSeances = const <SeancePasseeAdulte>[],
    this.notificationsNonLues,
  });

  /// Le prenom de l'eleve.
  final String prenom;

  /// Sa Classe, `null` tant qu'il n'en a aucune.
  final String? groupeId;

  /// « Mon parcours », une ligne deja rendue ; `null` : pas de section.
  final String? ligneParcours;

  /// Les dernieres seances, les plus recentes d'abord (trois montrees).
  final List<SeancePasseeAdulte> dernieresSeances;

  /// Les notifications non lues, telles que le service les rend.
  final int? notificationsNonLues;
}

/// L'accueil de l'eleve adulte. **Aucune source serveur a ce jour**
/// (EA-BR-04) : `CapaciteIndisponible`, que `BlocAsynchrone` dit comme tel,
/// sans « Reessayer ». La demonstration le surcharge.
final FutureProvider<AccueilAdulteVM> accueilAdulteProvider =
    FutureProvider<AccueilAdulteVM>(
      (Ref _) => Future<AccueilAdulteVM>.error(
        const CapaciteIndisponible('accueil_eleve_adulte'),
      ),
    );

/// L'accueil de l'eleve adulte : salutation et cloche, prochaine seance,
/// « Avant le prochain cours » (s'il y a quelque chose a faire), « Mon
/// parcours » en une ligne, dernieres seances (3) et ressources de la
/// Classe (3). Deux colonnes par rangees, comme l'Espace Classe.
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
    // Pendant le chargement, l'en-tete garde sa place : une ligne de
    // squelette pour la salutation, et la cloche deja posee.
    final Widget? entete = vue != null || lecture.isLoading
        ? _Salutation(
            prenom: vue?.prenom,
            nonLues: vue?.notificationsNonLues,
            onNotifications: onNotifications,
          )
        : null;
    return PageShell(
      entete: entete,
      // Sans lecture de l'accueil (indisponible, echec), la cloche reste :
      // le centre de notifications ne depend pas de cette lecture (EA-7,
      // l'invitation recue s'y trouve).
      actionsEntete: entete == null && onNotifications != null
          ? <Widget>[ClocheNotifications(onPress: onNotifications)]
          : const <Widget>[],
      child: BlocAsynchrone<AccueilAdulteVM>(
        valeur: lecture,
        squelette: const SqueletteGroupe(),
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

/// La salutation en une ligne et la cloche ; [prenom] `null` pendant le
/// chargement.
class _Salutation extends StatelessWidget {
  const _Salutation({
    required this.prenom,
    required this.nonLues,
    required this.onNotifications,
  });

  final String? prenom;
  final int? nonLues;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final Widget cloche = ClocheNotifications(
      onPress: onNotifications,
      nonLues: nonLues,
    );
    final String? p = prenom;
    if (p == null) {
      return Row(
        children: <Widget>[
          const Expanded(
            child: ExcludeSemantics(child: Skeleton(hauteur: AppSpacing.xxxl)),
          ),
          Ecart.hXs,
          cloche,
        ],
      );
    }
    return EntetePage(
      titre: t.adulte.accueil.salutation(prenom: p),
      actions: <Widget>[cloche],
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({required this.vue, this.onRejoindre, this.onVoirRessources});

  final AccueilAdulteVM vue;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(String groupeId)? onVoirRessources;

  @override
  Widget build(BuildContext context) {
    final String? groupeId = vue.groupeId;

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

    return LecteurGroupe(
      groupeId: groupeId,
      construire: (BuildContext contexte, LectureGroupe lecture) => _Sections(
        vue: vue,
        groupeId: groupeId,
        lecture: lecture,
        onRejoindre: onRejoindre,
        onVoirRessources: onVoirRessources,
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({
    required this.vue,
    required this.groupeId,
    required this.lecture,
    this.onRejoindre,
    this.onVoirRessources,
  });

  final AccueilAdulteVM vue;
  final String groupeId;
  final LectureGroupe lecture;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(String groupeId)? onVoirRessources;

  @override
  Widget build(BuildContext context) {
    final GroupHomeVM espace = lecture.espace;
    final List<SeancePasseeAdulte> passees = vue.dernieresSeances
        .take(AccueilAdultePage.limite)
        .toList();
    final String? parcours = vue.ligneParcours;

    final List<Widget> seance = <Widget>[
      SectionHeader(
        key: const ValueKey<String>('accueil-adulte-prochaine-seance'),
        titre: t.adulte.accueil.prochaineSeance,
      ),
      Ecart.vMd,
      ...lecture.identiteEtCarte(onRejoindre: onRejoindre),
    ];

    // Seulement ce que les donnees demandent : sans action, pas de section.
    final List<Widget> avant =
        lecture.portTravailBranche && espace.avantProchainCours.isNotEmpty
        ? <Widget>[
            EmplacementAvantProchainCours(
              actions: espace.avantProchainCours,
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

    final MaterialLocalizations l10n = MaterialLocalizations.of(context);
    String heure(DateTime quand) => l10n.formatTimeOfDay(
      TimeOfDay.fromDateTime(quand),
      alwaysUse24HourFormat: true,
    );
    // K-42 point 4 : la date, puis une seule ligne, la plage ; la Classe et
    // l'enseignant sont deja nommes par la carte au-dessus.
    final List<Widget> dernieres = passees.isEmpty
        ? const <Widget>[]
        : <Widget>[
            SectionHeader(titre: t.adulte.accueil.dernieresSeances),
            Ecart.vMd,
            GroupeReglages(
              key: const ValueKey<String>('accueil-adulte-dernieres'),
              lignes: <LigneRubrique>[
                for (final SeancePasseeAdulte s in passees)
                  LigneRubrique(
                    icone: AppIcons.cours,
                    libelle: s.dateRendue,
                    legende: t.enseignant.journee.plage(
                      debut: heure(s.seance.debut),
                      fin: heure(s.seance.fin),
                    ),
                    marque: s.absence
                        ? StatusPill(
                            libelle: t.adulte.accueil.absence,
                            ton: TonEtat.avertissement,
                          )
                        : null,
                  ),
              ],
            ),
          ];

    final void Function(String groupeId)? voir = onVoirRessources;
    final Widget ressources = BlocBibliotheque(
      emplacement: espace.bibliotheque,
      titre: t.adulte.accueil.ressources,
      limite: AccueilAdultePage.limite,
      onVoirTout: voir == null ? null : () => voir(groupeId),
    );

    List<Widget> bloc(List<List<Widget>> sections) => <Widget>[
      for (final (int i, List<Widget> s)
          in sections
              .where((List<Widget> s) => s.isNotEmpty)
              .indexed) ...<Widget>[if (i > 0) Ecart.vSection, ...s],
    ];

    return ColonnesParRangees(
      rangees: <(List<Widget>, List<Widget>)>[
        (seance, bloc(<List<Widget>>[avant, ligneParcours])),
        if (dernieres.isEmpty)
          (<Widget>[ressources], const <Widget>[])
        else
          (dernieres, <Widget>[ressources]),
      ],
    );
  }
}
