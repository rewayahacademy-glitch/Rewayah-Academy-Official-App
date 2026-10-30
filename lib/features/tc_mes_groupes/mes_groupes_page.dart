import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_acces_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/concierge_seance.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/horloge_vivante.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
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
    // bouton reste present, jamais grise : l'appui dit d'attendre
    // (BOUTONS-GRISES-1). Une lecture absente ou en echec (port neutre en
    // production) ne change rien, et jamais selon un solde.
    final AsyncValue<AccesBeneficiaire?> acces = ref.watch(
      accesAppelantProvider,
    );
    final bool accesFerme =
        ouvertureSeances(acces.value) == OuvertureSeances.fermees;
    // Hors ligne ou acces en lecture : l'entree ne peut pas encore aboutir.
    // « Rejoindre » reste present et actif ; l'appui dit quand entrer, sans
    // redire « hors ligne » (K-59 : seul le bandeau le dit).
    final String? attente = horsLigne
        ? t.tc.groupe.carte.entreeAttendReseau
        : accesEnAttente(acces)
        ? t.tc.groupe.carte.entreeSePrepare
        : null;
    final Widget grille = _Grille(
      groupes: liste,
      attente: attente,
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
class _Grille extends ConsumerWidget {
  const _Grille({
    required this.groupes,
    required this.attente,
    required this.accesFerme,
    this.onRejoindre,
  });

  final List<GroupSummaryVM> groupes;

  /// Hors ligne, ou acces encore en lecture : ce que dit l'appui sur
  /// « Rejoindre », qui n'entre pas encore (jamais grise).
  final String? attente;

  /// Seances fermees (FI-9a) : Rejoindre est retire de chaque carte.
  final bool accesFerme;
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool deuxColonnes = AppGabarit.de(context).estLarge;
    // Mes classes (30/10/2026) : chaque carte porte l'horloge vivante de sa
    // Classe (lue a l'affichage, a chaque bascule, sur la veille temps reel) ;
    // la liste suit la prochaine seance et la plus proche, en cours ou a
    // venir, passe en tete, seule mise en avant.
    final List<GroupSummaryVM> horodates = classesParProchaineSeance(
      <GroupSummaryVM>[
        for (final GroupSummaryVM groupe in groupes)
          groupe.horloge != null
              ? groupe
              : groupe.avecHorloge(
                  ref
                      .watch(horlogeClasseVivanteProvider(groupe.groupeId))
                      .value,
                ),
      ],
    );
    final List<Widget> cartes = <Widget>[
      for (final (int i, GroupSummaryVM groupe) in horodates.indexed)
        _CarteRoutee(
          key: ValueKey<String>(groupe.groupeId),
          groupe: groupe,
          attente: attente,
          accesFerme: accesFerme,
          onRejoindre: onRejoindre,
          aLaUne: i == 0 && groupe.horloge != null,
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
class _CarteRoutee extends ConsumerWidget {
  const _CarteRoutee({
    required this.groupe,
    required this.attente,
    required this.accesFerme,
    this.onRejoindre,
    this.aLaUne = false,
    super.key,
  });

  /// La Classe en cours ou la plus proche : la seule carte mise en avant.
  final bool aLaUne;

  final GroupSummaryVM groupe;
  final String? attente;
  final bool accesFerme;
  final void Function(GroupSummaryVM groupe)? onRejoindre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final void Function(GroupSummaryVM groupe)? rappel = onRejoindre;
    return CarteGroupe(
      groupe: groupe,
      onOuvrir: () =>
          GoRouter.of(context).go(CheminsTcA.espaceGroupe(groupe.groupeId)),
      // Hors ligne, la carte reste lisible et « Rejoindre » reste present :
      // l'appui dit quand entrer au lieu d'ouvrir une salle que le reseau ne
      // peut pas honorer (jamais grise, BOUTONS-GRISES-1).
      onRejoindre: rappel == null ? null : () => rappel(groupe),
      attenteEntree: attente,
      refusEntree: ref.watch(refusEntreeProvider)[groupe.groupeId],
      rejoindreRetire: accesFerme,
      dominante: aLaUne,
    );
  }
}

/// Les Classes dans l'ordre de leur prochaine seance : la seance en cours ou
/// la plus proche d'abord, puis les suivantes ; celles sans seance prevue a la
/// fin, dans l'ordre recu. Pure.
List<GroupSummaryVM> classesParProchaineSeance(List<GroupSummaryVM> groupes) {
  final List<(int, GroupSummaryVM)> rangs = groupes.indexed.toList();
  int cle((int, GroupSummaryVM) r) => r.$1;
  rangs.sort(((int, GroupSummaryVM) a, (int, GroupSummaryVM) b) {
    final SessionClockVM? ha = a.$2.horloge;
    final SessionClockVM? hb = b.$2.horloge;
    if (ha == null || hb == null) {
      if (ha != null) return -1;
      if (hb != null) return 1;
      return cle(a).compareTo(cle(b));
    }
    final int parDebut = ha.debutUtc.compareTo(hb.debutUtc);
    return parDebut != 0 ? parDebut : cle(a).compareTo(cle(b));
  });
  return <GroupSummaryVM>[for (final (int, GroupSummaryVM) r in rangs) r.$2];
}
