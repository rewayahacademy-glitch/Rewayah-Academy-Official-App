import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_acces_foyer.dart';
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
import '../acces_finance/acces_finance.dart';
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
  const MesGroupesPage({super.key, this.onRejoindre});

  /// Ce que fait « Rejoindre ».
  ///
  /// **L'entree en Classe Live n'appartient pas a Agent A.** Elle passe par
  /// `BilletSalle` et par le shell d'Agent E, qu'Agent Z branche ici. Tant que
  /// ce rappel est nul, le bouton s'affiche quand la fenetre est ouverte, mais
  /// reste inactif : on ne fait pas semblant d'ouvrir une porte.
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: LibellesGroupe.mesGroupesTitre,
      child: _Corps(onRejoindre: onRejoindre),
    );
  }
}

class _Corps extends ConsumerWidget {
  const _Corps({this.onRejoindre});

  final void Function(GroupSummaryVM groupe)? onRejoindre;

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
    // L'acces de l'eleve connecte (FI-9a), la meme regle que son accueil :
    // seances fermees, Rejoindre est retire et la copie neutre le dit, sans
    // cause ni montant (guide §1.7, lecon 15) ; tant que l'acces se lit, le
    // bouton reste present et inerte. Une lecture absente ou en echec (port
    // neutre en production) ne change rien, et jamais selon un solde.
    final AsyncValue<AccesBeneficiaire?> acces = ref.watch(
      accesAppelantProvider,
    );
    final bool accesFerme =
        ouvertureSeances(acces.value) == OuvertureSeances.fermees;
    final Widget grille = _Grille(
      groupes: liste,
      horsLigne: horsLigne || accesEnAttente(acces),
      accesFerme: accesFerme,
      onRejoindre: onRejoindre,
    );
    if (!accesFerme) return grille;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BandeauAccesFerme(acces: acces.value),
        Ecart.vLg,
        grille,
      ],
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
    required this.accesFerme,
    this.onRejoindre,
  });

  final List<GroupSummaryVM> groupes;

  /// Hors ligne, ou acces encore en lecture : la porte reste inerte.
  final bool horsLigne;

  /// Seances fermees (FI-9a) : Rejoindre est retire de chaque carte.
  final bool accesFerme;
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  @override
  Widget build(BuildContext context) {
    final bool deuxColonnes = AppGabarit.de(context).estLarge;
    final List<Widget> cartes = <Widget>[
      for (final GroupSummaryVM groupe in groupes)
        _CarteRoutee(
          groupe: groupe,
          horsLigne: horsLigne,
          accesFerme: accesFerme,
          onRejoindre: onRejoindre,
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
class _CarteRoutee extends StatelessWidget {
  const _CarteRoutee({
    required this.groupe,
    required this.horsLigne,
    required this.accesFerme,
    this.onRejoindre,
  });

  final GroupSummaryVM groupe;
  final bool horsLigne;
  final bool accesFerme;
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  @override
  Widget build(BuildContext context) {
    final void Function(GroupSummaryVM groupe)? rappel = onRejoindre;
    return CarteGroupe(
      groupe: groupe,
      onOuvrir: () =>
          GoRouter.of(context).go(CheminsTcA.espaceGroupe(groupe.groupeId)),
      // Hors ligne, la carte reste lisible mais la porte de la salle est
      // fermee : proposer une entree que le reseau ne peut pas honorer serait
      // une promesse en l'air.
      onRejoindre: horsLigne || rappel == null ? null : () => rappel(groupe),
      rejoindreRetire: accesFerme,
    );
  }
}
