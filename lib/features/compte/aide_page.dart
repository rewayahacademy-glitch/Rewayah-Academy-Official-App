import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_support.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// L'aide et le contact de l'academie (`/tuteur/compte/aide`).
///
/// Aucun canal n'est encore decide (DB-CPT-07 : courriel ou page d'aide a
/// fournir par le directeur) : l'ecran le dit, sans bouton « Contacter » qui
/// ne menerait nulle part, sans FAQ inventee. Le jour ou le port rend un
/// canal, son adresse s'affiche telle que l'academie la publie.
class AideComptePage extends ConsumerWidget {
  /// Cree la page.
  const AideComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CanalSupport?> canal = ref.watch(canalSupportProvider);
    final Object? erreur = canal.hasError ? canal.error : null;
    // `?retour=` (filtre par `cheminRetourValide`) : l'aide ouverte depuis un
    // detail de mouvement y ramene ; le Compte a defaut.
    String? retour;
    try {
      retour = cheminRetourValide(
        GoRouterState.of(context).uri.queryParameters['retour'],
      );
    } on Object {
      retour = null;
    }
    final String sortie = retour ?? Routes.tuteurCompte;

    return PageShell(
      titre: t.compte.tuteur.pageAide.titre,
      onRetour: () => GoRouter.of(context).go(sortie),
      child: ColonneSousPage(
        child: erreur is CapaciteIndisponible
            ? EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.compte.tuteur.pageAide.indisponibleTitre,
                phrase: t.compte.tuteur.pageAide.indisponiblePhrase,
                dependance: erreur.dependance,
              )
            : BlocAsynchrone<CanalSupport?>(
                valeur: canal,
                squelette: const Skeleton.liste(lignes: 1),
                onReessayer: () => ref.invalidate(canalSupportProvider),
                vide: EtatSysteme(
                  nature: NatureEtat.aucunResultat,
                  titre: t.compte.tuteur.pageAide.indisponibleTitre,
                  phrase: t.compte.tuteur.pageAide.aucunCanal,
                ),
                construire: (CanalSupport? valeur) => GroupeReglages(
                  lignes: <LigneRubrique>[
                    LigneRubrique(
                      icone: AppIcons.lecon,
                      libelle: valeur!.nature == NatureCanalSupport.courriel
                          ? t.compte.tuteur.pageAide.canalCourriel
                          : t.compte.tuteur.pageAide.canalLien,
                      legende: valeur.adresse,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
