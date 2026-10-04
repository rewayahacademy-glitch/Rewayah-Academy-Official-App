// Les finances du Foyer du tuteur (FI-4, guide Finance V4 §5.1, maquette 03) :
// la synthese du foyer en tete des profils, et, dans la carte de chaque
// enfant, son etat, son solde et son prochain debit.
//
// Tout vient du port (`PortPaiementsFoyer.finances`, FI-BR-03) : aucun total,
// aucune remise, aucun debit calcule ici (FI6). En production le port rend
// `CapaciteIndisponible` : le Foyer reste celui d'avant, sans bloc d'argent
// ni bouton de recharge, jamais un solde invente. Le second adulte ne recoit
// jamais ces finances (lecon 15) : il ne voit donc aucun bouton de recharge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/politique_commerciale.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/badge_periode_financee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/pastille_financiere.dart';
import '../../core/widgets/resume_soldes.dart';
import '../../core/widgets/skeleton.dart';
import 'ligne_membre.dart' show dateEcheance;

/// Les finances du foyer, lues une fois puis gardees : la recharge les
/// invalide avant de revenir au Foyer (route `recharge`), pour qu'il les
/// relise.
final FutureProvider<FinancesFoyer> financesFoyerProvider =
    FutureProvider<FinancesFoyer>(
      (Ref ref) => ref.watch(portPaiementsFoyerProvider).finances(),
    );

/// La politique commerciale active, pour le nombre de seances d'essai : une
/// valeur commerciale n'est jamais ecrite dans un ecran (guide §8 F1).
final FutureProvider<PolitiqueCommerciale> politiqueActiveProvider =
    FutureProvider<PolitiqueCommerciale>(
      (Ref ref) => ref.watch(portPolitiquesCommercialesProvider).active(),
    );

/// La finance de chaque profil rendu, par identifiant ; vide tant que la
/// lecture n'a pas abouti (aucun bloc d'argent plutot qu'un bloc faux).
Map<String, FinancesProfil> financesParProfil(
  AsyncValue<FinancesFoyer> lecture,
) => <String, FinancesProfil>{
  if (lecture.hasValue && !lecture.hasError)
    for (final FinancesProfil p in lecture.requireValue.profils) p.profilId: p,
};

/// Vrai quand le profil a besoin d'une recharge : un manque, une periode a
/// regulariser, un acces expire. Lu sur l'etat rendu, jamais sur le solde.
bool aRecharger(FinancesProfil p) => switch (p.etat) {
  EtatFinancier.manque ||
  EtatFinancier.aRegulariser ||
  EtatFinancier.expire => true,
  _ => false,
};

/// La synthese « Soldes et paiements » en tete du Foyer : chargement,
/// contenu, erreur et hors ligne ; rien du tout quand la source n'existe pas
/// (production).
class SyntheseSoldesFoyer extends ConsumerWidget {
  /// Cree la synthese.
  const SyntheseSoldesFoyer({required this.onRechargerPlusieurs, super.key});

  /// Ouvre la recharge, aucun profil coche d'avance. La synthese porte son
  /// propre ecart sous elle : absente (production), elle ne laisse aucun
  /// vide.
  final VoidCallback onRechargerPlusieurs;

  /// La synthese.
  static const Key cle = Key('foyer.finances.synthese');

  /// « Recharger plusieurs profils ».
  static const Key rechargerKey = Key('foyer.finances.rechargerPlusieurs');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinancesFoyer> lecture = ref.watch(financesFoyerProvider);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    if (erreur is CapaciteIndisponible) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final Widget titre = Semantics(
      header: true,
      child: Text(
        t.foyer.finances.titre,
        style: palette.inkStrong.applyTo(
          Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    final Widget corps;
    if (erreur != null) {
      void relire() => ref.invalidate(financesFoyerProvider);
      corps = (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire)
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.foyer.finances.indisponibleTitre,
              onAction: relire,
            );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 2);
    } else {
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ResumeSoldes(synthese: lecture.requireValue.synthese),
          Ecart.vLg,
          // Secondaire : le seul bouton plein du Foyer reste « Ajouter un
          // profil eleve » (un bouton dominant par ecran, D5).
          // FI-5 : pleine largeur sur telephone ; compacte au bord de fin
          // ailleurs, jamais un bouton etire sur 650 px (K-42.6).
          if (AppGabarit.de(context) == Gabarit.mobile)
            ActionPrincipale(
              key: rechargerKey,
              libelle: t.foyer.finances.rechargerPlusieurs,
              niveau: NiveauAction.secondaire,
              onPress: onRechargerPlusieurs,
            )
          else
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IntrinsicWidth(
                child: ActionPrincipale(
                  key: rechargerKey,
                  libelle: t.foyer.finances.rechargerPlusieurs,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                  onPress: onRechargerPlusieurs,
                ),
              ),
            ),
        ],
      );
    }
    return KeyedSubtree(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[titre, Ecart.vSm, corps, Ecart.vSection],
      ),
    );
  }
}

/// Le bloc d'argent d'un enfant, dans sa carte du Foyer : son etat (et
/// l'essai « n sur 2 », ou le manque exact), sa periode, son solde, son
/// prochain debit. Rien n'est calcule : chaque valeur est rendue.
class BlocFinanceMembre extends ConsumerWidget {
  /// Cree le bloc.
  const BlocFinanceMembre({required this.finance, super.key});

  /// La finance rendue du profil.
  final FinancesProfil finance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<PolitiqueCommerciale> politique = ref.watch(
      politiqueActiveProvider,
    );
    final int? essaisMax = politique.hasValue && !politique.hasError
        ? politique.requireValue.essaisMax
        : null;
    final TextStyle note = palette.inkStrong.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    final ProchainDebit? debit = finance.prochainDebit;
    final int? essais = finance.essaisUtilises;
    final String? manque = switch (finance.manque) {
      final m? when aRecharger(finance) => formaterMontant(m),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            PastilleFinanciere(
              etat: finance.etat,
              essaisUtilises: essais,
              essaisMax: essaisMax,
            ),
            BadgePeriodeFinancee(periode: finance.periode),
          ],
        ),
        // Le maximum lu, la pastille dit « Essai : n/max » ; sans politique
        // lue, le compteur seul, jamais un maximum suppose.
        if (essais != null && essaisMax == null) ...<Widget>[
          Ecart.vXs,
          Text(t.foyer.finances.essaiSansMax(n: essais), style: note),
        ],
        if (manque != null) ...<Widget>[
          Ecart.vXs,
          Text(t.foyer.finances.manque(montant: manque), style: note),
        ],
        LigneCleValeur(
          cle: t.foyer.finances.soldeActuel,
          valeur: formaterMontant(finance.solde),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: t.foyer.finances.prochainDebit,
          valeur: debit == null
              ? t.foyer.finances.aucunDebit
              : t.foyer.finances.prochainDebitValeur(
                  date: dateEcheance(debit.date),
                  montant: formaterMontant(debit.montant),
                ),
          chiffres: debit != null,
        ),
      ],
    );
  }
}
