/// SUIVI-ATTENTE (S5) : l'entree « Me presenter aux familles » dans Mes
/// classes, pour les classes nees depuis moins de 30 jours.
///
/// Une ligne par classe recente, qui ouvre l'ecran « Me presenter ». Rien
/// n'est rendu sans classe recente, ni tant que les Messages ne sont pas
/// branches (pas de bouton qui ne peut pas aboutir). L'ecart avec ce qui
/// precede ne se pose que si une ligne est rendue.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../com_messages/port_messages_metier.dart';

/// Les jours pendant lesquels une classe est « recente » pour se presenter.
const int joursClasseRecente = 30;

/// Les classes de [groupes] nees depuis moins de [joursClasseRecente] jours a
/// [maintenant], les plus recentes d'abord.
List<GroupeEnseignant> classesRecentes(
  List<GroupeEnseignant> groupes,
  DateTime maintenant,
) {
  final DateTime limite = maintenant.subtract(
    const Duration(minutes: joursClasseRecente * Duration.minutesPerDay),
  );
  return <GroupeEnseignant>[
    for (final GroupeEnseignant g in groupes)
      if (g.creeLe.isAfter(limite)) g,
  ]..sort(
    (GroupeEnseignant a, GroupeEnseignant b) => b.creeLe.compareTo(a.creeLe),
  );
}

/// L'entree des presentations dans Mes classes.
class EntreePresentationClasses extends ConsumerWidget {
  /// Cree l'entree. [ecartAvant] : l'ecart pose avant elle, seulement si elle
  /// rend quelque chose.
  const EntreePresentationClasses({this.ecartAvant, super.key});

  /// L'ecart avec ce qui precede.
  final Widget? ecartAvant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portMessagesMetierProvider) is MessagesMetierIndisponibles) {
      return const SizedBox.shrink();
    }
    final List<GroupeEnseignant> recentes = classesRecentes(
      ref.watch(groupesEnseignantProvider).value ?? const <GroupeEnseignant>[],
      DateTime.now(),
    );
    if (recentes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ?ecartAvant,
        GroupeReglages(
          lignes: <LigneRubrique>[
            for (final GroupeEnseignant g in recentes)
              LigneRubrique(
                cle: ValueKey<String>('presenter-ligne-${g.id}'),
                icone: AppIcons.discussion,
                libelle: t.suiviAttente.mePresenter.lien,
                legende: g.libelle,
                onPress: () =>
                    GoRouter.maybeOf(context)
                        ?.push(Routes.enseignantPresentationClasse(g.id)),
              ),
          ],
        ),
      ],
    );
  }
}
