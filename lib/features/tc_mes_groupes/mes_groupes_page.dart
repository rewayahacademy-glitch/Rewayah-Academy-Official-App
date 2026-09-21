import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../classes/domaine/conformite.dart';
import '../classes/domaine/providers.dart';
import '../classes/porte_salle.dart';
import 'carte_groupe.dart';
import 'chemins_tc_a.dart';

/// « Mes groupes » : la liste des groupes de l'appelant.
///
/// Le Groupe est l'espace pedagogique **permanent** : cet ecran existe donc
/// quand aucun cours n'est en vue, et il ne se vide jamais parce qu'une seance
/// vient de finir.
///
/// Quatre etats, et aucun d'eux n'est un ecran blanc : le chargement prend la
/// forme de ce qui arrive, l'echec propose de reessayer, l'absence de groupe
/// explique de quoi elle depend, et le hors ligne laisse lire les cartes tout
/// en fermant la porte de la salle.
class MesGroupesPage extends ConsumerWidget {
  /// Cree l'ecran.
  const MesGroupesPage({super.key, this.onRejoindre, this.onAjouterPhoto});

  /// Ce que fait « Rejoindre ».
  ///
  /// **L'entree en Classe Live n'appartient pas a Agent A.** Elle passe par
  /// `BilletSalle` et par le shell d'Agent E, qu'Agent Z branche ici. Tant que
  /// ce rappel est nul, le bouton s'affiche quand la fenetre est ouverte, mais
  /// reste inactif : on ne fait pas semblant d'ouvrir une porte.
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  /// Ce que fait « Ajouter la photo », quand un membre mineur n'en a pas.
  ///
  /// Nul quand ce n'est pas cet appelant qui peut l'ajouter (un eleve sur son
  /// appareil) : la porte dit alors ou cela se fait, au lieu de proposer un
  /// geste qui echouerait.
  final VoidCallback? onAjouterPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: LibellesGroupe.mesGroupesTitre,
      child: _Corps(onRejoindre: onRejoindre, onAjouterPhoto: onAjouterPhoto),
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({this.onRejoindre, this.onAjouterPhoto});

  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final VoidCallback? onAjouterPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GroupSummaryVM>> groupes = ref.watch(
      mesGroupesProvider,
    );

    if (groupes.hasError) {
      return EmptyState(
        message: LibellesGroupe.erreur,
        icone: AppIcons.avertissement,
        libelleAction: LibellesGroupe.reessayer,
        onAction: () => ref.invalidate(mesGroupesProvider),
      );
    }

    if (!groupes.hasValue) {
      // Le squelette prend la forme de ce qui arrive : deux cartes de groupe.
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Skeleton.tuileBento(hauteur: 220),
          Ecart.vLg,
          Skeleton.tuileBento(hauteur: 220),
        ],
      );
    }

    final List<GroupSummaryVM> liste = groupes.requireValue;
    if (liste.isEmpty) {
      // Un etat subi : ce n'est pas l'eleve qui se place dans un groupe.
      return EmptyState(
        message: LibellesGroupe.aucunGroupe,
        invitation: LibellesGroupe.aucunGroupeDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    // Le hors ligne se lit d'une seule source, `horsLigneProvider` : ouvrir un
    // second abonnement `Connectivity` ferait diverger le bandeau de la page.
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return _Grille(
      groupes: liste,
      horsLigne: horsLigne,
      onRejoindre: onRejoindre,
      onAjouterPhoto: onAjouterPhoto,
    );
  }
}

/// La disposition des cartes selon la largeur.
///
/// Mobile une colonne, tablette et desktop deux : au dela, la carte s'etirerait
/// sans rien apprendre de plus. La largeur de page est deja bornee a 1200 et
/// centree par `PageShell`, donc rien ne s'etale a l'infini sur un grand ecran.
class _Grille extends StatelessWidget {
  const _Grille({
    required this.groupes,
    required this.horsLigne,
    this.onRejoindre,
    this.onAjouterPhoto,
  });

  final List<GroupSummaryVM> groupes;
  final bool horsLigne;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final VoidCallback? onAjouterPhoto;

  @override
  Widget build(BuildContext context) {
    final bool deuxColonnes = AppGabarit.de(context).estLarge;
    final List<Widget> cartes = <Widget>[
      for (final GroupSummaryVM groupe in groupes)
        _CarteRoutee(
          groupe: groupe,
          horsLigne: horsLigne,
          onRejoindre: onRejoindre,
          onAjouterPhoto: onAjouterPhoto,
        ),
    ];

    if (!deuxColonnes) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget carte in cartes) ...<Widget>[carte, Ecart.vLg],
        ],
      );
    }

    final List<Widget> lignes = <Widget>[];
    for (int i = 0; i < cartes.length; i += 2) {
      lignes.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: cartes[i]),
            Ecart.hLg,
            Expanded(
              child: i + 1 < cartes.length
                  ? cartes[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      lignes.add(Ecart.vLg);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lignes,
    );
  }
}

/// Une carte, et ce que ses deux gestes declenchent.
///
/// **Le bouton « Rejoindre » passe par la porte d'entree** : pour un membre
/// mineur sans photo d'identification, elle explique la condition avant le
/// clic au lieu de laisser le jeton echouer apres. La precondition vient du
/// serveur ; inconnue, le bouton reste et le serveur tranche seul.
class _CarteRoutee extends ConsumerWidget {
  const _CarteRoutee({
    required this.groupe,
    required this.horsLigne,
    this.onRejoindre,
    this.onAjouterPhoto,
  });

  final GroupSummaryVM groupe;
  final bool horsLigne;
  final void Function(GroupSummaryVM groupe)? onRejoindre;
  final VoidCallback? onAjouterPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final void Function(GroupSummaryVM groupe)? rappel = onRejoindre;
    // Hors ligne, la carte reste lisible mais la porte de la salle est
    // fermee : proposer une entree que le reseau ne peut pas honorer serait
    // une promesse en l'air.
    final VoidCallback? rejoindre = horsLigne || rappel == null
        ? null
        : () => rappel(groupe);
    final PreconditionSalle? precondition = ref
        .watch(preconditionSalleProvider(null))
        .value;
    return CarteGroupe(
      groupe: groupe,
      onOuvrir: () =>
          GoRouter.of(context).go(CheminsTcA.espaceGroupe(groupe.groupeId)),
      onRejoindre: rejoindre,
      porte: PorteSalle(
        precondition: precondition,
        onRejoindre: rejoindre,
        onAjouterPhoto: onAjouterPhoto,
        libelle: LibellesGroupe.rejoindre,
      ),
    );
  }
}
