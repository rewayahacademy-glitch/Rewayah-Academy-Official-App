import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/port_accents_profils.dart';
import '../../../core/capacites/port_recus.dart';
import '../../../core/finance/finances_profil.dart';
import '../../../core/finance/format_montant.dart';
import '../../../core/finance/mouvements_profil.dart';
import '../../../core/finance/periode_a_financer.dart';
import '../../../core/finance/politique_famille.dart';
import '../../../core/foyer/selection_eleve.dart';
import '../../../core/i18n/elision.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
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
import '../../../core/widgets/ligne_transaction.dart';
import '../../../core/widgets/montant_argent.dart';
import '../../../core/widgets/pastille_financiere.dart';
import '../../../core/widgets/pile_cartes.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/status_pill.dart';
import '../fiche_eleve_page.dart';
import '../finances_foyer.dart';
import '../ligne_membre.dart' show dateEcheance;
import '../photo_eleve.dart';
import '../transactions_foyer.dart' show nombreDernieresTransactions;
import 'mouvements_page.dart';

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
/// ouvre la recharge avec ce profil coche ; le lien « Voir les mouvements »
/// (ou, sur bureau, « Voir tout » de l'historique) mene a l'historique du
/// profil (FI-6b). Sans source, ni onglets ni actions : l'etat de production.
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

  /// Le lien « Voir les mouvements » (FI-6b).
  static const Key mouvementsKey = Key('ficheEleve.finances.mouvements');

  /// La periode financee, dans la vue financiere (une seule fois, revue 3 d).
  static const Key periodeKey = Key('ficheEleve.finances.periode');

  /// La note sur les absences (FIN4-04).
  static const Key noteAbsencesKey = Key('ficheEleve.finances.noteAbsences');

  /// « Télécharger le reçu » (FI-Q7 (a), FI-BR-05).
  static const Key recuKey = Key('ficheEleve.finances.recu');

  /// L'etat honnete du recu, apres un appui (pas encore disponible, echec).
  static const Key recuEtatKey = Key('ficheEleve.finances.recuEtat');

  /// La colonne d'identite sur bureau (identite et parametres).
  static const Key colonneIdentiteKey = Key(
    'ficheEleve.finances.colonneIdentite',
  );

  /// L'historique des transactions, troisieme colonne sur bureau.
  static const Key historiqueKey = Key('ficheEleve.finances.historique');

  /// « Voir tout » de l'historique des transactions.
  static const Key voirToutKey = Key('ficheEleve.finances.voirTout');

  /// Le bandeau du bas, sur bureau : trois faits.
  static const Key bandeauBasKey = Key('ficheEleve.finances.bandeauBas');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageFiche(
      eleveId: eleveId,
      titre: t.ficheEleve.finances.titre,
      // Maquette 06 : « Mariam · Finances », le chemin « Foyer › Mariam ».
      titreBureau: (String prenom) =>
          t.ficheEleve.finances.titreBureau(prenom: prenom),
      sousTitreBureau: (String prenom) => FilArianeFiche(prenom: prenom),
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
    final Widget etats = EtatsFinancesProfil(
      lecture: lecture,
      onRelire: () => ref.invalidate(financesFoyerProvider),
      textes: (
        indisponibleTitre: t.ficheEleve.finances.indisponibleTitre,
        indisponiblePhrase: t.ficheEleve.finances.indisponiblePhrase(
          dePrenom: deDevant(
            profil.prenom,
            cle: 'ficheEleve.finances.indisponiblePhrase',
          ),
        ),
        erreurTitre: t.ficheEleve.finances.erreurTitre(
          dePrenom: deDevant(
            profil.prenom,
            cle: 'ficheEleve.finances.erreurTitre',
          ),
        ),
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
          dePrenom: deDevant(
            finance.prenom,
            cle: 'ficheEleve.finances.voirMouvementsSemantique',
          ),
        ),
        onMouvements: () =>
            GoRouter.of(context)
                .go(Routes.ficheEleveSousPage(finance.profilId, 'mouvements')),
        noteAbsences: t.ficheEleve.finances.noteAbsences,
        // Maquette 06, revue 4 e : les trois faits du bas, sans la phrase de
        // la recharge (fausse sur la fiche d'un seul enfant).
        faitsBureau: <({AppIcon icone, String texte})>[
          (icone: AppIcons.creneaux, texte: t.ficheEleve.finances.faitSeance),
          (icone: AppIcons.horloge, texte: t.ficheEleve.finances.faitPeriode),
          (
            icone: AppIcons.historique,
            texte: t.ficheEleve.finances.noteAbsences,
          ),
        ],
        // Revue 4 b : le groupe existant, repris tel quel, sans la ligne
        // « Finances » (la page elle-meme).
        parametres: ParametresEleve(
          profil: profil,
          onAller: GoRouter.of(context).go,
          avecFinances: false,
        ),
        historique: _HistoriqueProfil(profil: profil),
      ),
    );
    // Sous 1200, les onglets Général / Finances (Q-FI-1, revue 3 a) ; a 1200
    // et plus, aucun segmente (revue 4 b). La regle de la fiche, la meme
    // fonction (`legendeFinances`) : aucun onglet pendant la lecture ni sans
    // source (production) ; des onglets des que les finances sont lues, ou
    // que leur lecture a echoue.
    final bool avecOnglets =
        AppGabarit.de(context) != Gabarit.desktop &&
        legendeFinances(foyer, profil.eleveId) != null;
    if (!avecOnglets) return etats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OngletsFiche(eleveId: profil.eleveId, actif: OngletFiche.finances),
        Ecart.vXxl,
        etats,
      ],
    );
  }
}

/// L'historique des transactions du profil, troisieme colonne sur bureau
/// (maquette 06, revue 4 a) : les derniers mouvements rendus, puis « Voir
/// tout » vers la page des mouvements (FI-6b). Rien n'est trie ni filtre
/// dans Flutter : les premiers de la liste rendue.
class _HistoriqueProfil extends ConsumerWidget {
  const _HistoriqueProfil({required this.profil});

  final ProfilEleveFoyer profil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final AsyncValue<List<MouvementProfil>> lecture = ref.watch(
      mouvementsProfilProvider(profil.eleveId),
    );
    void relire() => ref.invalidate(mouvementsProfilProvider(profil.eleveId));
    final Object? erreur = lecture.hasError ? lecture.error : null;
    final Widget corps;
    if (erreur is CapaciteIndisponible) {
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.ficheEleve.mouvements.indisponibleTitre,
        phrase: t.ficheEleve.mouvements.indisponiblePhrase(
          dePrenom: deDevant(
            profil.prenom,
            cle: 'ficheEleve.mouvements.indisponiblePhrase',
          ),
        ),
        dependance: erreur.dependance,
      );
    } else if (erreur != null) {
      corps = (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSansDonnees(
              quoi: t.ficheEleve.mouvements.sansDonnees,
              onAction: relire,
            )
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.ficheEleve.mouvements.erreurTitre(
                dePrenom: deDevant(
                  profil.prenom,
                  cle: 'ficheEleve.mouvements.erreurTitre',
                ),
              ),
              onAction: relire,
            );
    } else if (!lecture.hasValue) {
      corps = const Skeleton.liste(lignes: nombreDernieresTransactions);
    } else if (lecture.requireValue.isEmpty) {
      corps = EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.ficheEleve.mouvements.videTitre,
        phrase: t.ficheEleve.mouvements.videPhrase(prenom: profil.prenom),
      );
    } else {
      // Une seule carte a lignes fines : des contenus lies (K-55).
      corps = CarteGroupee(
        sections: <Widget>[
          for (final MouvementProfil m in lecture.requireValue.take(
            nombreDernieresTransactions,
          ))
            LigneTransaction(
              icone: iconeMouvement(m.nature),
              libelle: libelleMouvement(m),
              date: dateHeureMouvement(m.date),
              montant: m.montant,
            ),
        ],
      );
    }
    return KeyedSubtree(
      key: FinancesElevePage.historiqueKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Le titre au debut, « Voir tout » au bord de fin ; a texte
          // agrandi, le lien passe sous le titre plutot que de le couper.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  t.ficheEleve.finances.historiqueTitre,
                  style: palette.inkStrong.applyTo(
                    Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(),
                  ),
                ),
              ),
              LienFleche(
                key: FinancesElevePage.voirToutKey,
                libelle: t.ficheEleve.finances.voirTout,
                libelleSemantique: t.ficheEleve.finances.voirToutSemantique(
                  dePrenom: deDevant(
                    profil.prenom,
                    cle: 'ficheEleve.finances.voirToutSemantique',
                  ),
                ),
                onPress: () => GoRouter.of(
                  context,
                ).go(Routes.ficheEleveSousPage(profil.eleveId, 'mouvements')),
              ),
            ],
          ),
          Ecart.vMd,
          corps,
        ],
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
          ? EtatSansDonnees(
              quoi: t.ficheEleve.finances.sansDonnees,
              onAction: onRelire,
            )
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
      deMois: deDevant(mo, cle: 'ficheEleve.finances.moisNonFinance'),
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
/// Une remise de rang porte son rang quand la source le rend (« Remise
/// familiale 3e membre », guide §5.2), jamais un rang suppose.
String libelleLigneMensualite(LigneMensualite ligne, {required bool adulte}) =>
    switch (ligne.nature) {
      NatureLigneMensualite.tarif =>
        adulte
            ? t.ficheEleve.finances.tarifAdulte
            : t.ficheEleve.finances.tarifEnfant,
      NatureLigneMensualite.remiseRang => switch (ligne.rang) {
        final int rang => t.ficheEleve.finances.remiseRangDe(
          rang: rang.toString(),
        ),
        null => t.ficheEleve.finances.remiseRang,
      },
      NatureLigneMensualite.prorata => t.ficheEleve.finances.prorata,
      NatureLigneMensualite.bourse => t.ficheEleve.finances.bourse,
      NatureLigneMensualite.remisePrepaiement =>
        t.ficheEleve.finances.remisePrepaiement,
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
    this.noteAbsences,
    this.faitsBureau = const <({AppIcon icone, String texte})>[],
    this.parametres,
    this.historique,
  });

  /// La finance rendue du profil.
  final FinancesProfil finance;

  /// La photo du profil (initiales en repli).
  final Widget avatar;

  /// Le libelle du bouton de recharge.
  final String libelleRecharger;

  /// Ouvre LA recharge, ce profil coche (un seul moteur, guide §4).
  final VoidCallback onRecharger;

  /// Ce que le lecteur d'ecran dit du lien « Voir les mouvements ».
  final String semantiqueMouvements;

  /// Ouvre les mouvements du profil.
  final VoidCallback onMouvements;

  /// La note sur les absences (FIN4-04), sous la vue financiere ; `null` :
  /// aucune. Sur bureau, avec [faitsBureau], elle passe dans le bandeau du
  /// bas.
  final String? noteAbsences;

  /// Les faits du bandeau du bas, sur bureau (maquette 06, revue 4 e) ;
  /// vide : aucun bandeau.
  final List<({AppIcon icone, String texte})> faitsBureau;

  /// Sur bureau, sous l'identite : le groupe des parametres de l'eleve
  /// (revue 4 b) ; `null` : aucun.
  final Widget? parametres;

  /// Sur bureau, la troisieme colonne : l'historique des transactions
  /// (revue 4 a), qui porte alors l'acces aux mouvements ; `null` : deux
  /// colonnes et le lien « Voir les mouvements ».
  final Widget? historique;

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
    final AsyncValue<PolitiqueFamille> politique = ref.watch(
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
              // La periode financee, une seule fois a l'ecran : ici, dans la
              // vue financiere (revue 3 c, 3 d, 4 c), jamais sous l'identite.
              Ecart.vSm,
              BadgePeriodeFinancee(
                key: FinancesElevePage.periodeKey,
                periode: finance.periode,
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
                    libelle: libelleLigneMensualite(
                      l,
                      adulte: finance.estAdulte,
                    ),
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

    final Widget? colonneHistorique = bureau ? historique : null;
    final bool bandeauBas = bureau && faitsBureau.isNotEmpty;
    final String? noteSousVue = bandeauBas ? null : noteAbsences;

    // Revue 3 g : « Recharger {prenom} » d'abord, 16 sous la note, puis
    // « Voir les mouvements » 8 dessous. Sur bureau a trois colonnes,
    // l'historique porte « Voir tout » : pas de second lien.
    final Widget actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Pendant une confirmation, payer encore serait payer deux fois
        // (guide §5.4) : aucune recharge proposee.
        if (finance.etat != EtatFinancier.enConfirmation)
          Align(alignment: AlignmentDirectional.centerEnd, child: recharger),
        if (colonneHistorique == null) ...<Widget>[
          if (finance.etat != EtatFinancier.enConfirmation) Ecart.vSm,
          // L'historique du profil (FI-6b) : un lien, jamais un second
          // bouton plein (K-56).
          Align(
            alignment: bureau
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: LienFleche(
              key: FinancesElevePage.mouvementsKey,
              libelle: t.ficheEleve.finances.voirMouvements,
              libelleSemantique: semantiqueMouvements,
              onPress: onMouvements,
            ),
          ),
        ],
        // Le recu du dernier paiement (maquette 06, revue 3 g) : une action
        // secondaire, seulement quand une periode a ete financee (un
        // paiement existe). Montre avant que le serveur produise les recus,
        // sur un etat honnete (FI-Q7 (a), decide par delegation le 05/10).
        if (finance.periode != null) ...<Widget>[
          Ecart.vLg,
          BoutonRecu(profilId: finance.profilId, bureau: bureau),
        ],
      ],
    );

    final Widget principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PileCartes(
          children: <Widget>[
            if (!bureau) identite,
            if (attention != null)
              BandeauAttention(
                key: FinancesElevePage.bandeauKey,
                titre: attention.titre,
                message: attention.message,
                ton: attention.ton,
              ),
            vue,
          ],
        ),
        if (noteSousVue != null) ...<Widget>[
          Ecart.vLg,
          KeyedSubtree(
            key: FinancesElevePage.noteAbsencesKey,
            child: NoteFiche(noteSousVue),
          ),
        ],
        Ecart.vLg,
        actions,
      ],
    );

    if (!bureau) return principal;

    // Maquette 06 : l'identite (et les parametres) a gauche, la vue
    // financiere et ses actions au milieu, l'historique a droite. Jamais
    // une colonne mobile etiree.
    final Widget? reglages = parametres;
    final Widget gauche = KeyedSubtree(
      key: FinancesElevePage.colonneIdentiteKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          identite,
          if (reglages != null) ...<Widget>[Ecart.vXxl, reglages],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 2, child: gauche),
            Ecart.hXxl,
            Expanded(flex: 3, child: principal),
            if (colonneHistorique != null) ...<Widget>[
              Ecart.hXxl,
              Expanded(flex: 3, child: colonneHistorique),
            ],
          ],
        ),
        if (bandeauBas) ...<Widget>[
          Ecart.vXxl,
          _BandeauFaits(faits: faitsBureau),
        ],
      ],
    );
  }
}

/// Le bandeau du bas, sur bureau (maquette 06, revue 4 e) : des faits cote a
/// cote, une icone decorative et une phrase chacun.
class _BandeauFaits extends StatelessWidget {
  const _BandeauFaits({required this.faits});

  final List<({AppIcon icone, String texte})> faits;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle style = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );
    return SurfaceFiche(
      key: FinancesElevePage.bandeauBasKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (int i, ({AppIcon icone, String texte}) f)
              in faits.indexed) ...<Widget>[
            if (i > 0) Ecart.hXxl,
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ExcludeSemantics(
                    child: IconTheme(
                      data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                      child: Icon(f.icone.repos),
                    ),
                  ),
                  Ecart.hSm,
                  Expanded(child: Text(f.texte, style: style)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// « Télécharger le reçu » (FI-6a, maquette 06 ; FI-BR-05) : une action
/// secondaire qui appelle le port des recus. Tant qu'il rend
/// `CapaciteIndisponible` (production et demonstration), l'appui le dit sous
/// le bouton, en une note honnete : rien n'est telecharge, rien n'est
/// invente (K-28, K-59). Un echec d'une autre nature se dit avec son geste.
class BoutonRecu extends ConsumerStatefulWidget {
  /// Cree le bouton.
  const BoutonRecu({required this.profilId, required this.bureau, super.key});

  /// Le profil dont on demande le dernier recu.
  final String profilId;

  /// Sur bureau : au bord de fin, largeur du contenu (contrat B).
  final bool bureau;

  @override
  ConsumerState<BoutonRecu> createState() => _BoutonRecuState();
}

enum _EtatRecu { repos, enCours, indisponible, echec }

class _BoutonRecuState extends ConsumerState<BoutonRecu> {
  _EtatRecu _etat = _EtatRecu.repos;

  Future<void> _telecharger() async {
    setState(() => _etat = _EtatRecu.enCours);
    _EtatRecu resultat;
    try {
      await ref.read(portRecusProvider).telechargerDernierRecu(widget.profilId);
      resultat = _EtatRecu.repos;
    } on CapaciteIndisponible {
      resultat = _EtatRecu.indisponible;
    } on Object {
      resultat = _EtatRecu.echec;
    }
    if (!mounted) return;
    setState(() => _etat = resultat);
  }

  @override
  Widget build(BuildContext context) {
    final finances = t.ficheEleve.finances;
    final Widget bouton = ActionPrincipale(
      key: FinancesElevePage.recuKey,
      libelle: finances.telechargerRecu,
      niveau: NiveauAction.secondaire,
      pleineLargeur: !widget.bureau,
      enCours: _etat == _EtatRecu.enCours,
      onPress: _telecharger,
    );
    final (String, String, TonEtat)? etat = switch (_etat) {
      _EtatRecu.indisponible => (
        finances.recuIndisponibleTitre,
        finances.recuIndisponiblePhrase,
        TonEtat.accent,
      ),
      _EtatRecu.echec => (
        finances.recuEchecTitre,
        finances.recuEchecPhrase,
        TonEtat.alerte,
      ),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(alignment: AlignmentDirectional.centerEnd, child: bouton),
        if (etat != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: BandeauAttention(
              key: FinancesElevePage.recuEtatKey,
              titre: etat.$1,
              message: etat.$2,
              ton: etat.$3,
            ),
          ),
        ],
      ],
    );
  }
}
