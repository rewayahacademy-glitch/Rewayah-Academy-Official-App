// Ma classe, cote eleve adulte (EA-3, planche 1.2, UX_REVIEW_07 ligne 4).
//
// Aucun composant neuf (K-51) : la lecture du groupe et sa carte de seance
// CL-4 (`LecteurGroupe`, `LectureGroupe.identiteEtCarte`, donc
// `IdentiteGroupe`, `CarteSession` et `EmplacementEntree`), la disposition
// par rangees (`ColonnesParRangees`) et la Bibliotheque unique
// (`BlocBibliotheque`, trois au plus) sont ceux de l'Espace Classe
// (`tc_espace_groupe/`) et de l'accueil adulte (EA-2) ; les participants sont
// un `GroupeReglages`, une ligne par personne, sa photo en tete
// (`PhotoEleve`, initiales en repli ; E5, K-44), comme les eleves de la fiche
// du groupe (`fiche_groupe_page.dart`).
//
// Des sections, jamais d'onglets (R3, E13) : identite, carte de seance,
// « A propos » en une ligne, participants, ressources, progression en une
// ligne. L'effectif est celui que le groupe rend (pastille de
// `IdentiteGroupe`), jamais une constante (E6). La progression est une ligne
// rendue par le serveur, sans pourcentage ni appreciation (E8). Rien du
// foyer, du conjoint ni du forfait ici (F8).
//
// Le seul provider propre a l'ecran, [maClasseAdulteProvider], n'a aucune
// source serveur : il rend `CapaciteIndisponible` (EA-BR), la demonstration
// le surcharge (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart' show AppAvatar;
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../acces_finance/acces_finance.dart';
import '../foyer/photo_eleve.dart' show PhotoEleve;
import '../tc_catalogue/routes_tc_b.dart' show RoutesTcB;
import '../tc_espace_groupe/emplacements_groupe.dart' show BlocBibliotheque;
import '../tc_espace_groupe/espace_groupe_page.dart'
    show ColonnesParRangees, LecteurGroupe, LectureGroupe, SqueletteGroupe;

/// Un participant de la Classe, tel que le serveur le rendrait : son prenom
/// et sa photo, rien d'autre sur un camarade (UX_REVIEW_07 ligne 4 b).
@immutable
class ParticipantClasseAdulte {
  /// Cree le participant.
  const ParticipantClasseAdulte({
    required this.id,
    required this.prenom,
    this.cleAvatar,
    this.estMoi = false,
  });

  /// L'identifiant du participant.
  final String id;

  /// Son prenom.
  final String prenom;

  /// La cle de sa photo, `null` sans photo : les initiales en repli.
  final String? cleAvatar;

  /// Vrai pour la personne qui regarde.
  final bool estMoi;
}

/// Ce que Ma classe lit, en une fois.
@immutable
class MaClasseAdulteVM {
  /// Cree la vue.
  const MaClasseAdulteVM({
    this.groupeId,
    this.aPropos,
    this.ligneProgression,
    this.participants = const <ParticipantClasseAdulte>[],
  });

  /// La Classe, `null` tant que l'eleve n'en a aucune.
  final String? groupeId;

  /// « A propos de cette classe », une ligne deja rendue ; `null` : pas de
  /// section.
  final String? aPropos;

  /// La progression dans la Classe, une ligne deja rendue ; `null` : pas de
  /// section.
  final String? ligneProgression;

  /// Les participants, dans l'ordre rendu.
  final List<ParticipantClasseAdulte> participants;
}

/// Ma classe de l'eleve adulte. **Aucune source serveur a ce jour** :
/// `CapaciteIndisponible`, que `BlocAsynchrone` dit comme tel, sans
/// « Reessayer ». La demonstration le surcharge.
final FutureProvider<MaClasseAdulteVM> maClasseAdulteProvider =
    FutureProvider<MaClasseAdulteVM>(
      (Ref _) => Future<MaClasseAdulteVM>.error(
        const CapaciteIndisponible('ma_classe_eleve_adulte'),
      ),
    );

/// Ma classe : identite et carte de seance, a propos, participants,
/// ressources (3) et progression. Deux colonnes par rangees, comme l'Espace
/// Classe.
class MaClasseAdultePage extends ConsumerWidget {
  /// Cree la page.
  const MaClasseAdultePage({
    super.key,
    this.onRejoindre,
    this.onVoirRessources,
  });

  /// Ce que fait le bouton de l'emplacement d'entree.
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  /// Ouvre la Bibliotheque de la Classe. Par defaut, comme l'Espace Classe :
  /// la Bibliotheque sur ce groupe (`RoutesTcB.avecGroupe`), qui montre
  /// toutes ses ressources.
  final void Function(String groupeId)? onVoirRessources;

  /// Le nombre de ressources montrees.
  static const int limite = 3;

  /// Le diametre des photos des participants : la valeur des eleves de la
  /// fiche du groupe (`fiche_groupe_page.dart`, `diametre: 40`), que cet
  /// ecran ne modifie pas (K-51).
  static const double diametrePhoto = AppAvatar.petit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MaClasseAdulteVM> classe = ref.watch(
      maClasseAdulteProvider,
    );
    void relire() => ref.invalidate(maClasseAdulteProvider);
    // Son acces, borne a sa session, la meme regle que son Accueil (FI-9a,
    // revue FI-VAGUE-R R4-01).
    final ({bool ferme, bool enLecture}) acces = rejoindreSelonAcces(
      ref.watch(accesAppelantProvider),
    );
    // Sans reseau, un echec se dit « hors ligne », comme les soldes du foyer
    // et Mon espace ; une capacite absente reste dite indisponible.
    final Object? erreur = classe.hasError ? classe.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    return PageShell(
      titre: t.adulte.nav.maClasse,
      child: echecHorsLigne
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire)
          : BlocAsynchrone<MaClasseAdulteVM>(
              valeur: classe,
              squelette: const SqueletteGroupe(),
              onReessayer: relire,
              construire: (MaClasseAdulteVM vue) {
                final String? groupeId = vue.groupeId;
                // Sans Classe : un etat subi, rien a faire ici.
                if (groupeId == null) {
                  return EmptyState(
                    message: t.adulte.accueil.aucuneClasse,
                    invitation: t.adulte.maClasse.aucuneClasseDetail,
                    icone: AppIcons.cours,
                    registre: RegistreVide.subi,
                  );
                }
                final Widget lecteur = LecteurGroupe(
                  groupeId: groupeId,
                  construire: (BuildContext _, LectureGroupe lecture) =>
                      _Sections(
                        vue: vue,
                        groupeId: groupeId,
                        lecture: lecture,
                        acces: acces,
                        onRejoindre: onRejoindre,
                        onVoirRessources: onVoirRessources,
                      ),
                );
                if (!acces.ferme) return lecteur;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const BandeauAccesAdulte(),
                    Ecart.vLg,
                    lecteur,
                  ],
                );
              },
            ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({
    required this.vue,
    required this.groupeId,
    required this.lecture,
    required this.acces,
    this.onRejoindre,
    this.onVoirRessources,
  });

  final MaClasseAdulteVM vue;
  final String groupeId;
  final LectureGroupe lecture;
  final ({bool ferme, bool enLecture}) acces;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final void Function(String groupeId)? onVoirRessources;

  /// Une section d'une seule ligne rendue : son titre, puis la ligne.
  static List<Widget> _ligne(
    BuildContext context,
    String titre,
    String? texte,
    String cle,
  ) => texte == null
      ? const <Widget>[]
      : <Widget>[
          SectionHeader(titre: titre),
          Ecart.vMd,
          AppCard(
            child: Text(
              texte,
              key: ValueKey<String>(cle),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ];

  @override
  Widget build(BuildContext context) {
    final GroupHomeVM espace = lecture.espace;

    final List<Widget> aPropos = _ligne(
      context,
      t.adulte.maClasse.aPropos,
      vue.aPropos,
      'ma-classe-a-propos',
    );
    final List<Widget> progression = _ligne(
      context,
      t.adulte.maClasse.progression,
      vue.ligneProgression,
      'ma-classe-progression',
    );

    // Une ligne par personne : sa photo, puis son prenom, qui porte la
    // lecture de la ligne. Aucune legende : rien d'autre sur un camarade.
    final List<Widget> participants = vue.participants.isEmpty
        ? const <Widget>[]
        : <Widget>[
            SectionHeader(titre: t.adulte.maClasse.participants),
            Ecart.vMd,
            GroupeReglages(
              key: const ValueKey<String>('ma-classe-participants'),
              lignes: <LigneRubrique>[
                for (final ParticipantClasseAdulte p in vue.participants)
                  LigneRubrique(
                    libelle: p.estMoi
                        ? t.adulte.maClasse.vous(prenom: p.prenom)
                        : p.prenom,
                    meneur: ExcludeSemantics(
                      child: PhotoEleve(
                        prenom: p.prenom,
                        cleAvatar: p.cleAvatar,
                        diametre: MaClasseAdultePage.diametrePhoto,
                      ),
                    ),
                  ),
              ],
            ),
          ];

    final void Function(String groupeId)? voir = onVoirRessources;
    final List<Widget> ressources = <Widget>[
      BlocBibliotheque(
        emplacement: espace.bibliotheque,
        titre: t.adulte.accueil.ressources,
        limite: MaClasseAdultePage.limite,
        // Trois ici, toutes dans la Bibliotheque de la Classe : l'identifiant
        // voyage dans l'adresse, comme depuis l'Espace Classe.
        onVoirTout: () => voir == null
            ? GoRouter.of(context).go(RoutesTcB.avecGroupe(groupeId))
            : voir(groupeId),
      ),
    ];

    List<Widget> bloc(List<List<Widget>> sections) => <Widget>[
      for (final (int i, List<Widget> s)
          in sections
              .where((List<Widget> s) => s.isNotEmpty)
              .indexed) ...<Widget>[if (i > 0) Ecart.vSection, ...s],
    ];

    // Sur telephone, l'ordre de lecture de la revue : identite, seance, a
    // propos, participants, ressources, progression. Sur bureau, les memes
    // sections en deux rangees.
    return ColonnesParRangees(
      rangees: <(List<Widget>, List<Widget>)>[
        (
          lecture.identiteEtCarte(
            onRejoindre: onRejoindre,
            accesFerme: acces.ferme,
            accesEnLecture: acces.enLecture,
          ),
          aPropos,
        ),
        if (participants.isEmpty)
          (bloc(<List<Widget>>[ressources, progression]), const <Widget>[])
        else
          (participants, bloc(<List<Widget>>[ressources, progression])),
      ],
    );
  }
}
