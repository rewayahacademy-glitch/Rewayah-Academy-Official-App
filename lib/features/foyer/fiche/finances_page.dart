import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_accents_profils.dart';
import '../../../core/finance/finances_profil.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/politique_commerciale.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/badge_periode_financee.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/carte_groupee.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/identite_profil.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/ligne_finance.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/pastille_financiere.dart';
import '../../../core/widgets/pile_cartes.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import '../fiche_eleve_page.dart';
import '../finances_foyer.dart';
import '../ligne_membre.dart' show dateEcheance;
import '../photo_eleve.dart';

/// Les finances d'un profil eleve (`/tuteur/foyer/:eleveId/finances`, FI-6a ;
/// guide Finance V4 §5.2, §8 F3 ; maquettes 02 et 06).
///
/// Tout vient de `financesFoyerProvider` (FI-BR-03) : l'identite, l'etat, la
/// periode financee, le solde, le prochain debit, la mensualite et ses lignes
/// **rendues** (jamais une remise absente, jamais un total recalcule : FI6).
/// Les montants des maquettes sont faux ; seules les valeurs du port
/// comptent.
///
/// Etats : chargement, contenu, vide (aucune finance rendue pour ce profil),
/// erreur, hors ligne, et production (`CapaciteIndisponible`), qui n'est ni
/// un echec ni un vide. Un seul bouton plein, « Recharger {prenom} », qui
/// ouvre la recharge avec ce profil coche ; le lien « Mouvements » mene a
/// l'historique du profil (FI-6b).
class FinancesElevePage extends ConsumerWidget {
  /// Cree la page.
  const FinancesElevePage({required this.eleveId, super.key});

  /// L'eleve concerne : un identifiant de chemin, jamais une autorisation.
  final String eleveId;

  /// La carte d'identite.
  static const Key identiteKey = Key('ficheEleve.finances.identite');

  /// La vue financiere (solde, prochain debit, mensualite).
  static const Key vueKey = Key('ficheEleve.finances.vue');

  /// Le detail de la mensualite.
  static const Key detailKey = Key('ficheEleve.finances.detail');

  /// Le bandeau d'attention.
  static const Key bandeauKey = Key('ficheEleve.finances.bandeau');

  /// « Recharger {prenom} ».
  static const Key rechargerKey = Key('ficheEleve.finances.recharger');

  /// Le lien « Mouvements » (FI-6b).
  static const Key mouvementsKey = Key('ficheEleve.finances.mouvements');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.finances.titre,
      onRetour: retourVersFiche(context, eleveId),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _CorpsFinances(profil: profil),
    );
  }
}

class _CorpsFinances extends ConsumerWidget {
  const _CorpsFinances({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinancesFoyer> lecture = ref.watch(financesFoyerProvider);
    void relire() => ref.invalidate(financesFoyerProvider);
    final Object? erreur = lecture.hasError ? lecture.error : null;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        portee: PorteeEtat.page,
        titre: t.ficheEleve.finances.indisponibleTitre,
        phrase: t.ficheEleve.finances.indisponiblePhrase(prenom: profil.prenom),
        dependance: erreur.dependance,
      );
    }
    if (erreur != null) {
      return (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire)
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.ficheEleve.finances.erreurTitre(prenom: profil.prenom),
              onAction: relire,
            );
    }
    if (!lecture.hasValue) return const Skeleton.liste(lignes: 4);
    final FinancesProfil? finance = financesParProfil(lecture)[profil.eleveId];
    if (finance == null) {
      return EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.ficheEleve.finances.videTitre(prenom: profil.prenom),
        phrase: t.ficheEleve.finances.videPhrase,
      );
    }
    return _ContenuFinances(profil: profil, finance: finance);
  }
}

/// Le titre et la phrase du bandeau d'attention, `null` sans attention.
({String titre, String message, TonEtat ton})? _attention(FinancesProfil f) {
  final String? manque = switch (f.manque) {
    final m? => formaterMontant(m),
    null => null,
  };
  final DateTime? conservation = f.finConservation;
  final String message = switch ((manque, conservation)) {
    (final String m, final DateTime d) =>
      t.ficheEleve.finances.manqueEtConservation(
        montant: m,
        date: dateEcheance(d),
      ),
    (final String m, null) => t.foyer.finances.manque(montant: m),
    _ => t.ficheEleve.finances.sansManque,
  };
  return switch (f.etat) {
    EtatFinancier.aRegulariser => (
      titre: t.ficheEleve.finances.regulariserTitre,
      message: message,
      ton: TonEtat.avertissement,
    ),
    EtatFinancier.manque => (
      titre: t.ficheEleve.finances.aFinancerTitre,
      message: message,
      ton: TonEtat.avertissement,
    ),
    EtatFinancier.expire => (
      titre: t.ficheEleve.finances.expireTitre,
      message: message,
      ton: TonEtat.avertissement,
    ),
    EtatFinancier.enConfirmation => (
      titre: t.ficheEleve.finances.confirmationTitre,
      message: t.ficheEleve.finances.confirmationPhrase,
      ton: TonEtat.accent,
    ),
    _ => null,
  };
}

/// Le libelle d'une ligne de mensualite, selon sa nature rendue.
String _libelleLigne(NatureLigneMensualite nature, {required bool adulte}) =>
    switch (nature) {
      NatureLigneMensualite.tarif =>
        adulte
            ? t.ficheEleve.finances.tarifAdulte
            : t.ficheEleve.finances.tarifEnfant,
      NatureLigneMensualite.remiseRang => t.ficheEleve.finances.remiseRang,
      NatureLigneMensualite.prorata => t.ficheEleve.finances.prorata,
      NatureLigneMensualite.avoir => t.ficheEleve.finances.avoir,
      NatureLigneMensualite.taxe => t.ficheEleve.finances.taxe,
    };

class _ContenuFinances extends ConsumerWidget {
  const _ContenuFinances({required this.profil, required this.finance});

  final ProfilEleveFoyer profil;
  final FinancesProfil finance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle titreCarte = palette.inkStrong.applyTo(
      textes.titleMedium ?? const TextStyle(),
    );
    final TextStyle note = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final AsyncValue<PolitiqueCommerciale> politique = ref.watch(
      politiqueActiveProvider,
    );
    final int? essaisMax = politique.hasValue && !politique.hasError
        ? politique.requireValue.essaisMax
        : null;
    final int? essais = finance.essaisUtilises;
    final ProchainDebit? debit = finance.prochainDebit;
    final ({String titre, String message, TonEtat ton})? attention = _attention(
      finance,
    );
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    final Widget identite = SurfaceFiche(
      key: FinancesElevePage.identiteKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IdentiteProfil(
            prenom: finance.prenom,
            accent: accentLu(
              ref.watch(accentsProfilsProvider),
              finance.profilId,
            ),
            estAdulte: finance.estAdulte,
            age: finance.age,
            classe: finance.classe,
            taille: TailleIdentite.entete,
            remontee: SurfaceFiche.marge,
            avatar: PhotoEleve(
              prenom: profil.prenom,
              cleAvatar: profil.cleAvatar,
              diametre: TailleIdentite.entete.diametre,
            ),
          ),
          Ecart.vLg,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              PastilleFinanciere(etat: finance.etat),
              BadgePeriodeFinancee(periode: finance.periode),
            ],
          ),
          if (essais != null) ...<Widget>[
            Ecart.vXs,
            Text(
              essaisMax == null
                  ? t.foyer.finances.essaiSansMax(n: essais)
                  : t.foyer.finances.essai(n: essais, max: essaisMax),
              style: note,
            ),
          ],
        ],
      ),
    );

    // Une mensualite ne se lit qu'avec ses lignes rendues : un essai n'en a
    // aucune, et un « 0 $ / mois » serait faux (aucun debit en essai).
    final bool avecMensualite = finance.lignesMensualite.isNotEmpty;
    final Widget vue = KeyedSubtree(
      key: FinancesElevePage.vueKey,
      child: CarteGroupee(
        sections: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(t.ficheEleve.finances.vueTitre, style: titreCarte),
              ),
              Ecart.vMd,
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      t.foyer.finances.soldeActuel,
                      style: palette.inkMuted.applyTo(
                        textes.bodyMedium ?? const TextStyle(),
                      ),
                    ),
                    MontantArgent(finance.solde, taille: TailleMontant.grand),
                  ],
                ),
              ),
              Ecart.vMd,
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
              if (avecMensualite)
                LigneCleValeur(
                  cle: t.ficheEleve.finances.mensualite,
                  valeur: t.ficheEleve.finances.mensualiteValeur(
                    montant: formaterMontant(finance.mensualite),
                  ),
                  chiffres: true,
                ),
            ],
          ),
          if (avecMensualite)
            Column(
              key: FinancesElevePage.detailKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    t.ficheEleve.finances.detailTitre,
                    style: titreCarte,
                  ),
                ),
                Ecart.vSm,
                // Seules les lignes RENDUES, dans leur ordre (guide §5.2).
                for (final LigneMensualite l in finance.lignesMensualite)
                  LigneFinance(
                    libelle: _libelleLigne(l.nature, adulte: finance.estAdulte),
                    montant: l.montant,
                    signe: l.nature == NatureLigneMensualite.taxe,
                  ),
                LigneFinance(
                  libelle: t.ficheEleve.finances.total,
                  montant: finance.mensualite,
                  total: true,
                ),
              ],
            ),
        ],
      ),
    );

    final Widget recharger = ActionPrincipale(
      key: FinancesElevePage.rechargerKey,
      libelle: t.foyer.finances.rechargerPour(prenom: finance.prenom),
      // Sur bureau, jamais un bouton pleine largeur (contrat B) : au bord
      // de fin, largeur du contenu.
      pleineLargeur: !bureau,
      onPress: () =>
          GoRouter.of(context)
              .go(Routes.rechargePour(<String>[finance.profilId])),
    );

    final List<Widget> finances = <Widget>[
      if (attention != null)
        BandeauAttention(
          key: FinancesElevePage.bandeauKey,
          titre: attention.titre,
          message: attention.message,
          ton: attention.ton,
        ),
      vue,
    ];

    // Maquettes 02 et 06 : l'identite d'abord (en tete sur telephone, a
    // gauche sur bureau), puis la vue financiere. Jamais une colonne mobile
    // etiree.
    final Widget composition = bureau
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 2, child: identite),
              Ecart.hXxl,
              Expanded(flex: 3, child: PileCartes(children: finances)),
            ],
          )
        : PileCartes(children: <Widget>[identite, ...finances]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        composition,
        Ecart.vLg,
        // L'historique du profil (FI-6b) : un lien, jamais un second bouton
        // plein (K-56).
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LienFleche(
            key: FinancesElevePage.mouvementsKey,
            libelle: t.ficheEleve.finances.voirMouvements,
            libelleSemantique: t.ficheEleve.finances.voirMouvementsSemantique(
              prenom: finance.prenom,
            ),
            onPress: () => GoRouter.of(context)
                .go(Routes.ficheEleveSousPage(finance.profilId, 'mouvements')),
          ),
        ),
        // Pendant une confirmation, payer encore serait payer deux fois
        // (guide §5.4) : aucune recharge proposee.
        if (finance.etat != EtatFinancier.enConfirmation) ...<Widget>[
          Ecart.vXxl,
          Align(alignment: AlignmentDirectional.centerEnd, child: recharger),
        ],
      ],
    );
  }
}
