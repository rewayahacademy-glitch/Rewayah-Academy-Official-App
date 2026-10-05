import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';
import 'soldes_foyer.dart';

/// Les paiements et recus du foyer (`/tuteur/compte/paiements`).
///
/// **Aucune source n'existe** (DB-CPT-03) : l'ecran le dit en clair, sans
/// bouton, sans prestataire, sans tarif, sans « paiement reussi » simule
/// (mandat section 5). « Gerer les paiements », « Historique et recus » et
/// « Moyen de paiement » de la maquette aboutissent tous ici, une seule fois.
///
/// Le jour ou la source existera, chaque paiement se lira par sa date et son
/// justificatif ; le montant (unites mineures, devise) et les statuts seront
/// mis en mots avec DB-CPT-03, jamais recalcules ici.
///
/// **Paiements du foyer du titulaire** (EA-9, planche 4.1) : avec [soldes],
/// la page pose d'abord le groupe par profil eleve prevu ici (section 1
/// ter-9), `SoldesFoyerSection` : une ligne par beneficiaire autorise, son
/// solde tel que rendu, le seul bouton « Recharger », le recapitulatif ;
/// puis l'historique sous son titre. Le second adulte rattache n'a que
/// l'historique, en lecture seule (E3, EA-BR-16) : jamais [soldes].
class PaiementsComptePage extends ConsumerWidget {
  /// Cree la page.
  const PaiementsComptePage({
    super.key,
    this.onRetour,
    this.titre,
    this.soldes = false,
    this.onRecharger,
  });

  /// Le retour de l'en-tete ; par defaut, le Compte du tuteur. « Mon
  /// espace » de l'eleve adulte (EA-4) y passe son propre retour.
  final VoidCallback? onRetour;

  /// Le titre de l'en-tete ; par defaut « Paiements et recus ». La ligne
  /// « Paiements du foyer » (EA-4c, EA-5) y passe son propre libelle, pour
  /// que la page d'arrivee porte le nom de la ligne tapee.
  final String? titre;

  /// Vrai pour le titulaire d'un foyer : les soldes des beneficiaires avant
  /// l'historique (EA-9).
  final bool soldes;

  /// Ouvre la recharge (EA-10), avec [soldes].
  final VoidCallback? onRecharger;

  /// Le titre « Historique des paiements », avec [soldes].
  static const Key historiqueKey = Key('paiements.historique');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PaiementFoyer>> paiements = ref.watch(
      paiementsFoyerProvider,
    );
    final Object? erreur = paiements.hasError ? paiements.error : null;

    final Widget historique = erreur is CapaciteIndisponible
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
          );

    return PageShell(
      titre: titre ?? t.compte.tuteur.pagePaiements.titre,
      onRetour: onRetour ?? () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: !soldes
            ? historique
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SoldesFoyerSection(onRecharger: onRecharger),
                  Ecart.vSection,
                  Semantics(
                    header: true,
                    child: Text(
                      key: historiqueKey,
                      t.adulte.paiements.historique,
                      style: AppPalette.of(context).inkStrong.applyTo(
                        Theme.of(context).textTheme.titleMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                  Ecart.vSm,
                  historique,
                ],
              ),
      ),
    );
  }
}
