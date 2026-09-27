import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// Les paiements et recus du foyer (`/tuteur/compte/paiements`).
///
/// **Aucune source n'existe** (DB-CPT-03) : l'ecran le dit en clair, sans
/// bouton, sans prestataire, sans tarif, sans « paiement reussi » simule
/// (mandat section 5). « Gerer les paiements », « Historique et recus » et
/// « Moyen de paiement » de la maquette aboutissent tous ici, une seule fois.
///
/// Le jour ou la source existera, chaque paiement se lira par sa date et son
/// justificatif ; le montant (unites mineures, devise) et les statuts seront
/// mis en mots avec DB-CPT-03, jamais recalcules ici. La page est prevue pour
/// accueillir un groupe par profil eleve (futur solde par enfant, section
/// 1 ter-9) sans refonte : rien n'est construit.
class PaiementsComptePage extends ConsumerWidget {
  /// Cree la page.
  const PaiementsComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PaiementFoyer>> paiements = ref.watch(
      paiementsFoyerProvider,
    );
    final Object? erreur = paiements.hasError ? paiements.error : null;

    return PageShell(
      titre: t.compte.tuteur.pagePaiements.titre,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: erreur is CapaciteIndisponible
            ? EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.compte.tuteur.pagePaiements.indisponibleTitre,
                phrase: t.compte.tuteur.pagePaiements.indisponiblePhrase,
                dependance: erreur.dependance,
              )
            : BlocAsynchrone<List<PaiementFoyer>>(
                valeur: paiements,
                squelette: const Skeleton.liste(lignes: 2),
                onReessayer: () => ref.invalidate(paiementsFoyerProvider),
                vide: EtatSysteme(
                  nature: NatureEtat.aucunResultat,
                  titre: t.compte.tuteur.pagePaiements.aucunTitre,
                  phrase: t.compte.tuteur.pagePaiements.aucunePhrase,
                ),
                construire: (List<PaiementFoyer> liste) => GroupeReglages(
                  lignes: <LigneRubrique>[
                    for (final PaiementFoyer p in liste)
                      LigneRubrique(
                        icone: AppIcons.fichierPdf,
                        libelle: t.compte.tuteur.pagePaiements.paiementDu(
                          date: dateLongue(p.date),
                        ),
                        legende: p.justificatifDisponible
                            ? t.compte.tuteur.pagePaiements.justificatif
                            : null,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
