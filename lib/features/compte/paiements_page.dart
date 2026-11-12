import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
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

/// Les paiements du foyer (`/tuteur/compte/paiements`), lus par
/// `paiements_foyer` (migration 20261017160100, DB-CPT-03) pour le titulaire
/// du foyer seulement : le serveur refuse les autres (42501), et la page le
/// dit en clair.
///
/// Chaque paiement : son jour au fuseau du profil, le montant rendu par le
/// serveur (unites mineures et devise, formate sans aucun calcul) et son
/// statut en mots (PAIEMENTS-TUTEUR, garde-cap 12/11/2026). Aucun recu n'est
/// promis : le serveur n'en produit pas encore (justificatifDisponible
/// toujours faux, lot REÇUS-FAMILLE au registre). Fonction absente du
/// serveur (PGRST202) : « indisponible », sans bouton.
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
    // Le jour de chaque paiement est au fuseau du profil : la page se
    // redessine quand il arrive (HEURES-PROFIL).
    ref.watch(monHorlogeProvider);
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
        // PAIEMENTS-TUTEUR : le serveur refuse (42501) a qui n'est pas le
        // titulaire du foyer (second adulte) ; un etat clair, jamais une
        // panne ni un « Reessayer ».
        : erreur is PostgrestException && erreur.code == '42501'
        ? EtatSysteme(
            nature: NatureEtat.accesRefuse,
            titre: t.compte.tuteur.pagePaiements.refusTitre,
            phrase: t.compte.tuteur.pagePaiements.refusPhrase,
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
                  // PAIEMENTS-TUTEUR (garde-cap, 12/11/2026) : le montant
                  // rendu par le serveur, formate sans aucun calcul ; le
                  // statut en mots ; le jour au fuseau du profil. Aucune
                  // mention de recu tant que le serveur n'en produit pas.
                  LigneRubrique(
                    cle: ValueKey<String>('paiement-${p.id}'),
                    icone: AppIcons.paiements,
                    libelle: t.compte.tuteur.pagePaiements.paiementDu(
                      date: dateLongue(jourChezMoi(p.date)),
                    ),
                    valeur: formaterMontant(Montant(p.montantMineur, p.devise)),
                    legende: legendePaiement(p),
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

/// Le statut d'un paiement en mots, tel que le serveur le nomme
/// (`paiements_foyer` : « confirme », « en_confirmation ») ; `null` pour un
/// statut inconnu, jamais affiche brut.
String? libelleStatutPaiement(String statut) => switch (statut) {
  'confirme' => t.compte.tuteur.pagePaiements.statutConfirme,
  'en_confirmation' => t.compte.tuteur.pagePaiements.statutEnConfirmation,
  _ => null,
};

/// La legende d'un paiement : son statut, et « Justificatif disponible »
/// seulement si le serveur le dit ; `null` quand il n'y a rien a dire.
String? legendePaiement(PaiementFoyer p) {
  final List<String> morceaux = <String>[
    ?libelleStatutPaiement(p.statutServeur),
    if (p.justificatifDisponible) t.compte.tuteur.pagePaiements.justificatif,
  ];
  return morceaux.isEmpty ? null : morceaux.join(' · ');
}
