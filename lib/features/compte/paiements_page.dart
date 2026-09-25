import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/chemin_retour.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
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
/// montant, et mene a son detail (LT-12). Le montant (unites mineures, devise)
/// est rendu par le serveur, jamais recalcule ici. La page est prevue pour
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
            ? _indisponible(erreur)
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
                        valeur: formaterMontant(p.montantMineur, p.devise),
                        legende: p.justificatifDisponible
                            ? t.compte.tuteur.pagePaiements.justificatif
                            : null,
                        onPress: () => GoRouter.of(context).go(
                          Uri(
                            path: Routes.paiementPour(p.id),
                            queryParameters: <String, String>{
                              'retour': Routes.tuteurComptePaiements,
                            },
                          ).toString(),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

EtatSysteme _indisponible(CapaciteIndisponible erreur) => EtatSysteme(
  nature: NatureEtat.indisponible,
  titre: t.compte.tuteur.pagePaiements.indisponibleTitre,
  phrase: t.compte.tuteur.pagePaiements.indisponiblePhrase,
  dependance: erreur.dependance,
);

/// Le statut d'un paiement en mots, depuis une liste **fermee** de codes
/// connus. Un code inconnu se dit « Statut non précisé », jamais brut.
///
/// ponytail: seuls les codes de demonstration sont connus ; la liste reelle
/// sera fixee avec DB-CPT-03.
String libelleStatutPaiement(String code) => switch (code) {
  'demo_regle' => t.compte.tuteur.pagePaiements.statuts.regle,
  'demo_en_attente' => t.compte.tuteur.pagePaiements.statuts.enAttente,
  _ => t.compte.tuteur.pagePaiements.statuts.inconnu,
};

/// Le detail d'un paiement (`/tuteur/compte/paiements/:paiementId`, LT-12).
///
/// En production (DB-CPT-03) la liste est indisponible : aucun bouton ne mene
/// ici, et une adresse directe dit la meme indisponibilite. Le justificatif
/// n'a aucun bouton : le port ne sait pas encore le telecharger.
class DetailPaiementPage extends ConsumerWidget {
  /// Cree la page.
  const DetailPaiementPage({required this.paiementId, super.key});

  /// L'identifiant du paiement, tel que rendu par le serveur.
  final String paiementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter? routeur = GoRouter.maybeOf(context);
    String? retour;
    try {
      retour = cheminRetourValide(
        GoRouterState.of(context).uri.queryParameters['retour'],
      );
    } on Object {
      retour = null;
    }
    final AsyncValue<PaiementFoyer?> paiement = ref.watch(
      paiementFoyerProvider(paiementId),
    );
    final Object? erreur = paiement.hasError ? paiement.error : null;

    return PageShell(
      titre: t.compte.tuteur.pagePaiements.detail.titre,
      onRetour: () => routeur?.go(retour ?? Routes.tuteurComptePaiements),
      child: ColonneSousPage(
        child: erreur is CapaciteIndisponible
            ? _indisponible(erreur)
            : BlocAsynchrone<PaiementFoyer?>(
                valeur: paiement,
                squelette: const Skeleton.liste(lignes: 3),
                onReessayer: () =>
                    ref.invalidate(paiementFoyerProvider(paiementId)),
                estVide: (PaiementFoyer? p) => p == null,
                vide: EtatSysteme(
                  nature: NatureEtat.introuvable,
                  titre: t.compte.tuteur.pagePaiements.detail.introuvable,
                  phrase:
                      t.compte.tuteur.pagePaiements.detail.introuvablePhrase,
                ),
                construire: (PaiementFoyer? lu) {
                  final PaiementFoyer p = lu!;
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        LigneCleValeur(
                          cle: t.compte.tuteur.pagePaiements.detail.montant,
                          valeur: formaterMontant(p.montantMineur, p.devise),
                          chiffres: true,
                        ),
                        LigneCleValeur(
                          cle: t.compte.tuteur.pagePaiements.detail.date,
                          valeur: dateLongue(p.date),
                        ),
                        LigneCleValeur(
                          cle: t.compte.tuteur.pagePaiements.detail.statut,
                          valeur: libelleStatutPaiement(p.statutServeur),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
