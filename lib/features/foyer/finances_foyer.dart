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
import '../../core/capacites/port_politique_famille.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/periode_a_financer.dart';
import '../../core/finance/politique_famille.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge_periode_financee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/pastille_financiere.dart';
import '../../core/widgets/resume_soldes.dart';
import '../../core/widgets/skeleton.dart';
import 'ligne_membre.dart' show dateEcheance;

/// Les finances du foyer, lues une fois puis gardees : la recharge les
/// invalide avant de revenir au Foyer (route `recharge`), pour qu'il les
/// relise.
final FutureProvider<FinancesFoyer> financesFoyerProvider =
    FutureProvider<FinancesFoyer>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portPaiementsFoyerProvider).finances();
    });

/// La politique commerciale en vigueur, vue d'une famille : le nombre de
/// seances d'essai, les moyens de paiement, la repartition du paiement. Une
/// valeur commerciale n'est jamais ecrite dans un ecran (guide §8 F1). Lue par
/// `politique_commerciale_famille` (TRANSPARENCE, 30/10/2026), jamais par la
/// fonction de la direction, qui la refuse au foyer. Liee a la personne
/// connectee (R7-04), comme les finances du foyer.
final FutureProvider<PolitiqueFamille> politiqueActiveProvider =
    FutureProvider<PolitiqueFamille>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return ref.watch(portPolitiqueFamilleProvider).lire();
    });

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

/// Vrai quand la source des finances du foyer existe : faux seulement en
/// production (`CapaciteIndisponible`), ou le Foyer reste celui d'avant.
bool financesDisponibles(AsyncValue<FinancesFoyer> lecture) =>
    !(lecture.hasError && lecture.error is CapaciteIndisponible);

/// Vrai quand « Recharger plusieurs profils » est pose : les finances sont
/// rendues. C'est alors lui le seul bouton plein du Foyer (Q-FI-2, E-17) ;
/// sinon (production, chargement, erreur), « Ajouter un profil eleve » est
/// le bouton plein (FI-Q1 (a), decide par delegation le 05/10).
bool rechargePosee(AsyncValue<FinancesFoyer> lecture) =>
    lecture.hasValue && !lecture.hasError;

/// La synthese « Soldes et paiements » en tete du Foyer : chargement,
/// contenu, erreur et hors ligne ; rien du tout quand la source n'existe pas
/// (production). Son titre est le sous-titre de la page (maquettes 03 et
/// 05, revue FI-VAGUE-R R1-09) : aucun titre repete ici.
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
    final Widget corps;
    if (erreur != null) {
      void relire() => ref.invalidate(financesFoyerProvider);
      corps = (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSansDonnees(
              quoi: t.foyer.finances.sansDonnees,
              onAction: relire,
            )
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.foyer.finances.indisponibleTitre,
              onAction: relire,
            );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 2);
    } else {
      final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
      // Le seul bouton plein du Foyer (K-56, Q-FI-2, E-17) : « Ajouter un
      // profil eleve » passe en secondaire tant qu'il est pose. Pleine
      // largeur sur telephone ; compact ailleurs, en tete du 4e bloc de la
      // rangee (FI-5), jamais un bouton etire sur 650 px (K-42.6).
      final Widget bouton = ActionPrincipale(
        key: rechargerKey,
        libelle: t.foyer.finances.rechargerPlusieurs,
        pleineLargeur: mobile,
        onPress: onRechargerPlusieurs,
      );
      corps = ResumeSoldes(
        synthese: lecture.requireValue.synthese,
        action: mobile
            ? bouton
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: IntrinsicWidth(child: bouton),
              ),
        note: t.foyer.finances.noteSoldes,
      );
    }
    return KeyedSubtree(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[corps, Ecart.vSection],
      ),
    );
  }
}

/// « Vue financiere du foyer » (FI-5, maquette 05, guide §5.1 « Desktop ») :
/// le mois courant seul.
///
/// **FI-Q2 (a), decide par delegation le 05/10** : le panneau est garde, sur
/// le mois courant (« Ce mois-ci »), sans selecteur de mois, memes libelles
/// que la rangee de tete. Il porte aussi « Paiements du mois », que la
/// rangee cede a son 4e bloc (Q-FI-7).
///
/// Meme source que la synthese : le chargement montre un squelette ; une
/// erreur se dit une seule fois, dans la synthese (avec « Reessayer » ou
/// « hors ligne »), ce panneau se retire alors ; sans source (production),
/// rien.
class VueFinanciereFoyer extends ConsumerWidget {
  /// Cree le panneau.
  const VueFinanciereFoyer({super.key, this.onNosPrix});

  /// Ouvre « Nos prix, en toute transparence » (TRANSPARENCE, 30/10/2026) ;
  /// sans lui, aucun lien.
  final VoidCallback? onNosPrix;

  /// Le panneau.
  static const Key cle = Key('foyer.finances.vueFinanciere');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinancesFoyer> lecture = ref.watch(financesFoyerProvider);
    if (lecture.hasError) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget corps;
    if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: 3);
    } else {
      final SyntheseFoyer s = lecture.requireValue.synthese;
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            cle: t.argent.soldes.total,
            valeur: formaterMontant(s.totalSoldes),
            chiffres: true,
            valeurEnFin: true,
          ),
          LigneCleValeur(
            cle: t.argent.soldes.aPayer,
            valeur: formaterMontant(s.aPayerCeMois),
            chiffres: true,
            valeurEnFin: true,
          ),
          LigneCleValeur(
            cle: t.argent.soldes.paiements,
            valeur: '${s.paiementsDuMois}',
            chiffres: true,
            valeurEnFin: true,
          ),
        ],
      );
    }
    return KeyedSubtree(
      key: cle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              t.foyer.finances.vueFinanciere,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Text(
            t.foyer.finances.vueFinancierePeriode,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          AppCard(child: corps),
          if (onNosPrix case final VoidCallback ouvrir) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              alignerEnDebut: true,
              libelle: t.argent.transparence.lien,
              onPress: ouvrir,
            ),
          ],
        ],
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
    final AsyncValue<PolitiqueFamille> politique = ref.watch(
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
    // Le mois que le debit attendu finance : la carte dit la meme chose que
    // la fiche Finances du meme enfant (guide §1.7, revue FI-VAGUE-R R1-05).
    final String? mois = moisAFinancer(finance);
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
          Text(
            mois == null
                ? t.foyer.finances.manque(montant: manque)
                : t.ficheEleve.finances.manquePourMois(
                    montant: manque,
                    mois: mois,
                  ),
            style: note,
          ),
        ],
        LigneCleValeur(
          cle: t.foyer.finances.soldeActuel,
          valeur: formaterMontant(finance.solde),
          chiffres: true,
        ),
        // Periode en cours non financee : le debit attendu est celui du mois
        // a financer, jamais un « prochain débit » a une date deja passee.
        if (debit != null && periodeNonFinancee(finance))
          LigneCleValeur(
            cle: t.ficheEleve.finances.periodeAFinancer,
            valeur: t.ficheEleve.finances.periodeAFinancerValeur(
              mois: t.commun.dates.mois[debit.date.month - 1],
              annee: debit.date.year.toString(),
              montant: formaterMontant(debit.montant),
            ),
            chiffres: true,
          )
        else
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
