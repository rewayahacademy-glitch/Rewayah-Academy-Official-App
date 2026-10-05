import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../foyer/finances_foyer.dart' show financesFoyerProvider;
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
/// mis en mots avec DB-CPT-03, jamais recalcules ici.
///
/// **Paiements du foyer du titulaire** (EA-9) : l'historique, precede du
/// raccourci « Recharger » ci-dessous. Ses soldes ne sont plus poses ici :
/// la synthese et les cartes de Ma famille les portent, comme sur le Foyer
/// du tuteur (E-11, revue FI-VAGUE-R R1-06). Le second adulte rattache n'a
/// que l'historique, en lecture seule (E3, EA-BR-16) : jamais [onRecharger].
///
/// **Raccourci vers la recharge du foyer** (FI-7, guide Finance V4 §4) :
/// [onRecharger] pose « Recharger » au-dessus de l'historique, qui
/// ouvre LA recharge du Foyer (`/tuteur/foyer/recharge`), jamais un second
/// centre de paiement. Il n'apparait que si les finances du foyer sont
/// rendues (capacite lue dans les donnees, comme sur le Foyer) : ni en
/// production, ni pour le second adulte.
class PaiementsComptePage extends ConsumerWidget {
  /// Cree la page.
  const PaiementsComptePage({
    super.key,
    this.onRetour,
    this.titre,
    this.onRecharger,
  });

  /// Le retour de l'en-tete ; par defaut, le Compte du tuteur. « Mon
  /// espace » de l'eleve adulte (EA-4) y passe son propre retour.
  final VoidCallback? onRetour;

  /// Le titre de l'en-tete ; par defaut « Paiements et recus ». La ligne
  /// « Paiements du foyer » (EA-4c, EA-5) y passe son propre libelle, pour
  /// que la page d'arrivee porte le nom de la ligne tapee.
  final String? titre;

  /// Ouvre la recharge (EA-10, FI-7).
  final VoidCallback? onRecharger;

  /// « Recharger », raccourci vers la recharge du foyer (FI-7).
  static const Key rechargerKey = Key('paiements.raccourciRecharge');

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
      child: ColonneSousPage(child: _avecRaccourci(ref, historique)),
    );
  }

  /// L'historique, precede de « Recharger » quand la recharge est ouverte.
  Widget _avecRaccourci(WidgetRef ref, Widget historique) {
    final VoidCallback? recharger = onRecharger;
    // Sans recharge (second adulte rattache), les finances du foyer ne sont
    // jamais lues, meme pour etre ignorees (lecon 15, FI-BR-18).
    if (recharger == null) return historique;
    final AsyncValue<Object> finances = ref.watch(financesFoyerProvider);
    if (!finances.hasValue || finances.hasError) {
      return historique;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ActionPrincipale(
            key: rechargerKey,
            libelle: t.adulte.paiements.recharger,
            onPress: recharger,
            pleineLargeur: false,
          ),
        ),
        Ecart.vSection,
        historique,
      ],
    );
  }
}
