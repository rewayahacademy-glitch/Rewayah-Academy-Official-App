/// SUIVI-ATTENTE (arbitrage du 13/11/2026) : « Mes demandes » du tuteur mene au
/// suivi quand il n'y a qu'un suivi en cours.
///
/// Les notifications et les courriels d'une demande (classe prete, enseignant
/// affecte, tout est pret, creneau change...) pointent vers `/tuteur/demandes`,
/// destination figee par une contrainte du serveur. Quand le foyer n'a qu'**un**
/// suivi en cours, visible et non clos, cette adresse ouvre directement l'ecran
/// du suivi (un seul ecran de suivi ; celui de l'adulte pour une demande
/// d'adulte, celui du tuteur sinon) ; avec plusieurs, ou aucun, la liste des
/// demandes reste la liste de raccourcis. Sans port (production avant
/// branchement), la liste ancienne, inchangee.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/attente_classe/modele_attente.dart';
import '../../core/router/routes.dart';
import '../suivi_famille/suivi_famille_page.dart' show SuiviDemandesEntree;
import 'carte_suivi_attente.dart' show suivisPourAccueil;

/// Le seul suivi en cours, visible et non clos de [suivis], ou `null` s'il y en
/// a zero ou plusieurs. Pure.
SuiviAttente? seulSuiviEnCours(List<SuiviAttente> suivis) {
  final List<SuiviAttente> enCours = <SuiviAttente>[
    for (final SuiviAttente s in suivisPourAccueil(suivis))
      if (!s.close) s,
  ];
  return enCours.length == 1 ? enCours.first : null;
}

/// L'entree de `/tuteur/demandes`.
class EntreeDemandesAttente extends ConsumerWidget {
  /// Cree l'entree. [redirige] : faux quand la page n'est que le dessous d'une
  /// page plus haute (le detail d'une demande), qui ne doit jamais etre
  /// quittee.
  const EntreeDemandesAttente({this.redirige = true, super.key});

  /// Vrai quand l'adresse est celle de la liste elle-meme.
  final bool redirige;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!redirige || ref.watch(portSuiviAttenteProvider) == null) {
      return const SuiviDemandesEntree();
    }
    final AsyncValue<List<SuiviAttente>> lues = ref.watch(
      suivisAttenteProvider,
    );
    final SuiviAttente? seul = lues.hasValue
        ? seulSuiviEnCours(lues.value ?? const <SuiviAttente>[])
        : null;
    if (seul != null) {
      // Un seul suivi : on y va, sans empiler l'adresse de la liste.
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (!context.mounted) return;
        // Une demande d'eleve ADULTE : son propre ecran de suivi (l'adulte est un
        // compte tuteur qui suit sa propre demande) ; sinon, l'ecran du tuteur.
        final String chemin = seul.typePublic == 'adulte'
            ? Routes.eleveAdulteAttenteDemande(seul.demandeId)
            : Routes.tuteurAttenteDemande(seul.demandeId);
        GoRouter.maybeOf(context)?.go(chemin);
      });
      return const SizedBox.shrink();
    }
    return const SuiviDemandesEntree();
  }
}
