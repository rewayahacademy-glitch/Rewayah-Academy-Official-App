import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_accents_profils.dart';
import '../../../core/finance/finances_profil.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/periode_a_financer.dart';
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

  /// La ligne du debit : « Prochain débit », ou « Période à financer »
  /// quand la periode en cours n'est pas financee.
  static const Key debitKey = Key('ficheEleve.finances.debit');

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
    // L'echec d'abord : pendant les nouvelles tentatives de Riverpod, la
    // valeur reste en chargement avec son erreur, que l'ecran doit dire.
    final AsyncValue<FinancesFoyer> foyer = ref.watch(financesFoyerProvider);
    final AsyncValue<FinancesProfil?> lecture = foyer.hasError
        ? AsyncValue<FinancesProfil?>.error(
            foyer.error!,
            foyer.stackTrace ?? StackTrace.empty,
          )
        : foyer.hasValue
        ? AsyncValue<FinancesProfil?>.data(
            financesParProfil(foyer)[profil.eleveId],
          )
        : const AsyncValue<FinancesProfil?>.loading();
    return EtatsFinancesProfil(
      lecture: lecture,
      onRelire: () => ref.invalidate(financesFoyerProvider),
      textes: (
        indisponibleTitre: t.ficheEleve.finances.indisponibleTitre,
        indisponiblePhrase: t.ficheEleve.finances.indisponiblePhrase(
          prenom: profil.prenom,
        ),
        erreurTitre: t.ficheEleve.finances.erreurTitre(prenom: profil.prenom),
        videTitre: t.ficheEleve.finances.videTitre(prenom: profil.prenom),
        videPhrase: t.ficheEleve.finances.videPhrase,
      ),
      construire: (FinancesProfil finance) => VueFinancesProfil(
        finance: finance,
        avatar: PhotoEleve(
          prenom: profil.prenom,
          cleAvatar: profil.cleAvatar,
          diametre: TailleIdentite.entete.diametre,
        ),
        libelleRecharger: t.foyer.finances.rechargerPour(
          prenom: finance.prenom,
        ),
        onRecharger: () =>
            GoRouter.of(context)
                .go(Routes.rechargePour(<String>[finance.profilId])),
        semantiqueMouvements: t.ficheEleve.finances.voirMouvementsSemantique(
          prenom: finance.prenom,
        ),
        onMouvements: () =>
            GoRouter.of(context)
                .go(Routes.ficheEleveSousPage(finance.profilId, 'mouvements')),
      ),
    );
  }
}

/// Les textes des etats des finances d'un profil, selon qui les lit : le
/// tuteur (le prenom du profil) ou l'eleve adulte (FI-9b, « vos »).
typedef TextesEtatsFinances = ({
  String indisponibleTitre,
  String indisponiblePhrase,
  String erreurTitre,
  String videTitre,
  String videPhrase,
});

/// Les etats des finances d'un profil (FI-6a, repris par FI-9b) :
/// chargement, contenu, vide (aucune finance rendue), erreur, hors ligne, et
/// production (`CapaciteIndisponible`), qui n'est ni un echec ni un vide.
class EtatsFinancesProfil extends ConsumerWidget {
  /// Cree les etats.
  const EtatsFinancesProfil({
    required this.lecture,
    required this.onRelire,
    required this.textes,
    required this.construire,
    super.key,
  });

  /// La finance lue ; une valeur `null` : aucune finance rendue.
  final AsyncValue<FinancesProfil?> lecture;

  /// Relit la source.
  final VoidCallback onRelire;

  /// Les textes des etats.
  final TextesEtatsFinances textes;

  /// Le contenu, une fois la finance lue.
  final Widget Function(FinancesProfil finance) construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Object? erreur = lecture.hasError ? lecture.error : null;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        portee: PorteeEtat.page,
        titre: textes.indisponibleTitre,
        phrase: textes.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    }
    if (erreur != null) {
      return (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSysteme(nature: NatureEtat.horsLigne, onAction: onRelire)
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: textes.erreurTitre,
              onAction: onRelire,
            );
    }
    if (!lecture.hasValue) return const Skeleton.liste(lignes: 4);
    final FinancesProfil? finance = lecture.requireValue;
    if (finance == null) {
      return EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: textes.videTitre,
        phrase: textes.videPhrase,
      );
    }
    return construire(finance);
  }
}

/// Le titre et la phrase du bandeau d'attention, `null` sans attention.
({String titre, String message, TonEtat ton})? _attention(FinancesProfil f) {
  final String? manque = switch (f.manque) {
    final m? => formaterMontant(m),
    null => null,
  };
  final DateTime? conservation = f.finConservation;
  final String? mois = moisAFinancer(f);
  // Le mois a financer est nomme des que la source rend le debit attendu ;
  // « la prochaine periode » ne reste qu'en repli, sans debit rendu.
  final String message = switch ((manque, conservation, mois)) {
    (final String m, final DateTime d, final String mo) =>
      t.ficheEleve.finances.manquePourMoisEtConservation(
        montant: m,
        mois: mo,
        date: dateEcheance(d),
      ),
    (final String m, null, final String mo) =>
      t.ficheEleve.finances.manquePourMois(montant: m, mois: mo),
    (final String m, final DateTime d, null) =>
      t.ficheEleve.finances.manqueEtConservation(
        montant: m,
        date: dateEcheance(d),
      ),
    (final String m, null, null) => t.foyer.finances.manque(montant: m),
    (null, _, final String mo) => t.ficheEleve.finances.moisNonFinance(
      mois: mo,
    ),
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

/// La vue financiere d'un profil (FI-6a, repris par FI-9b pour l'eleve
/// adulte) : identite, etat et periode, bandeau d'attention, solde, prochain
/// debit, mensualite et ses lignes rendues ; le lien vers les mouvements et
/// le seul bouton plein, la recharge. Rien n'est calcule : chaque valeur est
/// rendue par la source. Les destinations sont passees par l'appelant.
class VueFinancesProfil extends ConsumerWidget {
  /// Cree la vue.
  const VueFinancesProfil({
    required this.finance,
    required this.avatar,
    required this.libelleRecharger,
    required this.onRecharger,
    required this.semantiqueMouvements,
    required this.onMouvements,
    super.key,
  });

  /// La finance rendue du profil.
  final FinancesProfil finance;

  /// La photo du profil (initiales en repli).
  final Widget avatar;

  /// Le libelle du bouton de recharge.
  final String libelleRecharger;

  /// Ouvre LA recharge, ce profil coche (un seul moteur, guide §4).
  final VoidCallback onRecharger;

  /// Ce que le lecteur d'ecran dit du lien « Mouvements ».
  final String semantiqueMouvements;

  /// Ouvre les mouvements du profil.
  final VoidCallback onMouvements;

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
            avatar: avatar,
          ),
          Ecart.vLg,
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
              // Periode en cours non financee : le debit attendu est celui
              // du mois a financer, jamais un « prochain débit » a une date
              // passee (guide §1.7).
              if (debit != null && periodeNonFinancee(finance))
                LigneCleValeur(
                  key: FinancesElevePage.debitKey,
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
                  key: FinancesElevePage.debitKey,
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
      libelle: libelleRecharger,
      // Sur bureau, jamais un bouton pleine largeur (contrat B) : au bord
      // de fin, largeur du contenu.
      pleineLargeur: !bureau,
      onPress: onRecharger,
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
            libelleSemantique: semantiqueMouvements,
            onPress: onMouvements,
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
