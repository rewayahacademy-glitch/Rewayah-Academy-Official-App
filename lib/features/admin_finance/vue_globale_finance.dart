// La Vue globale de la Finance, cote direction (`/admin/finance`, FI-11a ;
// guide Finance V4 §1.5, §5.6, §8 LOT F7 ; maquette 09).
//
// Sept indicateurs SEPARES (FI21) : encaissement, revenu, charge, marge,
// impayes, essais, soldes des familles ; chacun dans sa carte, avec son nombre
// exact et une phrase qui dit ce qu'il est et ce qu'il n'est pas. Puis les
// alertes, redigees ici depuis leur nature (K-41). Aucun graphique : la source
// ne rend pas d'historique, et un graphique ne remplace jamais un nombre
// (§8 F7).
//
// Tout vient du port (`PortFinanceDirection`) : cet ecran n'additionne, ne
// soustrait et ne compare aucun montant (FI6). La marge est celle du port,
// calculee sur la seule paie des enseignants : elle n'est jamais rapprochee
// des references nettes de la politique (environ 30 %, §1.5), ni presentee
// comme un objectif ou une sanction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/montant_argent.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';

/// La vue globale du mois, lue sur le port de la direction.
///
/// `retry` nul : pas de retentative silencieuse de Riverpod 3 derriere le
/// bouton « Reessayer » de l'ecran (meme reglage que
/// `dossiersEnAttenteProvider`).
final FutureProvider<VueGlobaleFinance> vueGlobaleFinanceProvider =
    FutureProvider<VueGlobaleFinance>(
      (Ref ref) => ref.watch(portFinanceDirectionProvider).vueGlobale(),
      retry: (int retryCount, Object error) => null,
    );

/// Le contenu de l'onglet Vue globale : chargement, contenu, mois sans
/// activite, erreur, hors ligne, et « Pas encore disponible » tant que le
/// port rend `CapaciteIndisponible` (production, FI-BR-12).
class VueGlobaleFinanceBloc extends ConsumerWidget {
  /// Cree le bloc.
  const VueGlobaleFinanceBloc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VueGlobaleFinance> vue = ref.watch(
      vueGlobaleFinanceProvider,
    );
    void relire() => ref.invalidate(vueGlobaleFinanceProvider);
    // Sans reseau, un echec se dit « hors ligne » (comme Ma classe) ; une
    // capacite absente reste dite indisponible.
    final Object? erreur = vue.hasError ? vue.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    if (echecHorsLigne) {
      return EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
    }
    return BlocAsynchrone<VueGlobaleFinance>(
      valeur: vue,
      squelette: const _Squelette(),
      onReessayer: relire,
      construire: (VueGlobaleFinance v) => VueGlobaleFinanceContenu(vue: v),
    );
  }
}

/// La vue globale rendue (sans lecture) : les indicateurs, puis les alertes.
class VueGlobaleFinanceContenu extends StatelessWidget {
  /// Cree le contenu.
  const VueGlobaleFinanceContenu({required this.vue, super.key});

  /// La vue rendue par le port.
  final VueGlobaleFinance vue;

  /// La cle de la grille des indicateurs.
  static const Key indicateursKey = ValueKey<String>('fi-vue-indicateurs');

  /// La cle de la liste des alertes.
  static const Key alertesKey = ValueKey<String>('fi-vue-alertes');

  /// Le nombre de colonnes de la grille pour une largeur de contenu : quatre
  /// sur un bureau, deux sur une tablette, une sur un telephone ; une de moins
  /// par palier quand le texte est agrandi (aucun mot coupe).
  static int colonnesPour(double largeur, TextScaler texte) {
    final bool agrandi =
        texte.scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;
    if (largeur >= AppGabarit.seuilEtendu) return agrandi ? 2 : 4;
    if (largeur >= AppGabarit.seuilChoixDouble) return agrandi ? 1 : 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final vueT = t.admin.finance.vue;
    final String mois = vueT.moisAnnee(
      mois: t.commun.dates.mois[vue.mois.month - 1],
      annee: '${vue.mois.year}',
    );
    final int? marge = vue.margeProjeteePourMille;
    final List<Widget> indicateurs = <Widget>[
      _CarteIndicateur(
        libelle: vueT.encaisse,
        valeur: formaterMontant(vue.encaisse),
        detail: vueT.encaisseDetail,
        montant: vue.encaisse,
      ),
      _CarteIndicateur(
        libelle: vueT.revenu,
        valeur: formaterMontant(vue.revenuAcademique),
        detail: vueT.revenuDetail,
        montant: vue.revenuAcademique,
      ),
      _CarteIndicateur(
        libelle: vueT.paie,
        valeur: formaterMontant(vue.paieEnseignants),
        detail: vueT.paieDetail,
        montant: vue.paieEnseignants,
      ),
      _CarteIndicateur(
        libelle: vueT.marge,
        valeur: marge == null
            ? vueT.margeSansActivite
            : vueT.margeValeur(valeur: pourMilleEnTexte(marge)),
        detail: vueT.margeDetail,
      ),
      _CarteIndicateur(
        libelle: vueT.impayes,
        valeur: formaterMontant(vue.impayes),
        detail: vueT.impayesDetail,
        montant: vue.impayes,
      ),
      _CarteIndicateur(
        libelle: vueT.essais,
        valeur: '${vue.essaisEnCours}',
        detail: vueT.essaisDetail,
      ),
      _CarteIndicateur(
        libelle: vueT.soldes,
        valeur: formaterMontant(vue.soldesCrediteurs),
        detail: vueT.soldesDetail,
        montant: vue.soldesCrediteurs,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          vueT.contexte(mois: mois),
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        // Mois sans activite : les zeros restent affiches (un compteur qui
        // disparait fait douter qu'il ait ete charge), la phrase le dit.
        if (marge == null) ...<Widget>[
          Ecart.vMd,
          Text(vueT.sansActivite(mois: mois), style: textes.bodyLarge),
        ],
        Ecart.vXxl,
        SectionHeader(titre: vueT.indicateurs),
        Ecart.vMd,
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) =>
              _Grille(
                key: indicateursKey,
                colonnes: colonnesPour(
                  contraintes.maxWidth,
                  MediaQuery.textScalerOf(contexte),
                ),
                children: indicateurs,
              ),
        ),
        Ecart.vXxl,
        SectionHeader(titre: vueT.alertes),
        Ecart.vMd,
        if (vue.alertes.isEmpty)
          Text(
            vueT.aucuneAlerte,
            key: alertesKey,
            style: palette.inkMuted.applyTo(
              textes.bodyLarge ?? const TextStyle(),
            ),
          )
        else
          PileCartes(
            key: alertesKey,
            children: <Widget>[
              for (final AlerteFinance a in vue.alertes) _bandeau(a),
            ],
          ),
      ],
    );
  }

  /// L'alerte redigee depuis sa nature et ses donnees, en une phrase entiere
  /// par cas (K-41).
  static Widget _bandeau(AlerteFinance a) {
    final alerteT = t.admin.finance.vue.alerte;
    final String qui = switch ((a.prenom, a.classe)) {
      (final String p, final String c) => alerteT.quiPrenomClasse(
        prenom: p,
        classe: c,
      ),
      (final String p, null) => p,
      (null, final String c) => alerteT.quiClasse(classe: c),
      (null, null) => alerteT.quiInconnu,
    };
    final String? montant = a.montant == null
        ? null
        : formaterMontant(a.montant!);
    return switch (a.nature) {
      NatureAlerteFinance.aRegulariser => BandeauAttention(
        key: ValueKey<String>(a.id),
        titre: alerteT.aRegulariser,
        message: montant == null
            ? alerteT.aRegulariserSansMontant(qui: qui)
            : alerteT.aRegulariserMontant(qui: qui, montant: montant),
      ),
      NatureAlerteFinance.confirmationEnAttente => BandeauAttention(
        key: ValueKey<String>(a.id),
        ton: TonEtat.accent,
        titre: alerteT.confirmation,
        message: montant == null
            ? alerteT.confirmationSansMontant(qui: qui)
            : alerteT.confirmationMontant(qui: qui, montant: montant),
      ),
      NatureAlerteFinance.classeSousMinimum => BandeauAttention(
        key: ValueKey<String>(a.id),
        titre: alerteT.sousMinimum,
        message: alerteT.sousMinimumDetail(qui: qui),
      ),
    };
  }
}

/// Un taux en pour mille, mis en mots a la francaise : 792 donne « 79,2 »,
/// 300 donne « 30 ». Une mise en forme, jamais un calcul : la valeur vient
/// du port.
String pourMilleEnTexte(int pourMille) {
  final int absolu = pourMille.abs();
  final String signe = pourMille < 0 ? signeMoins : '';
  final int dixieme = absolu % 10;
  return dixieme == 0
      ? '$signe${absolu ~/ 10}'
      : '$signe${absolu ~/ 10},$dixieme';
}

/// Un indicateur : son libelle, son nombre exact, ce qu'il est.
class _CarteIndicateur extends StatelessWidget {
  const _CarteIndicateur({
    required this.libelle,
    required this.valeur,
    required this.detail,
    this.montant,
  });

  final String libelle;

  /// Le nombre deja mis en mots (lu tel quel par le lecteur d'ecran).
  final String valeur;
  final String detail;

  /// Le montant, quand l'indicateur en est un : rendu par `MontantArgent`.
  final Montant? montant;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              libelle,
              style: palette.inkMuted.applyTo(
                textes.titleSmall ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            if (montant case final Montant m)
              MontantArgent(m, taille: TailleMontant.titre)
            else
              Text(
                valeur,
                style: palette.inkStrong.applyTo(
                  AppTypography.tabulaire(
                    textes.titleLarge ?? const TextStyle(),
                  ),
                ),
              ),
            Ecart.vSm,
            Text(
              detail,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les cartes en rangees de [colonnes], 16 entre deux cartes dans les deux
/// sens (K-55), chaque rangee a la hauteur de sa plus haute carte.
class _Grille extends StatelessWidget {
  const _Grille({required this.colonnes, required this.children, super.key});

  final int colonnes;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (colonnes <= 1) return PileCartes(children: children);
    return PileCartes(
      children: <Widget>[
        for (int i = 0; i < children.length; i += colonnes)
          IntrinsicHeight(
            child: PileCartes(
              axe: Axis.horizontal,
              children: <Widget>[
                for (int j = i; j < i + colonnes; j++)
                  Expanded(
                    child: j < children.length
                        ? children[j]
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// La forme de la vue pendant la lecture : la phrase, puis des cartes.
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Skeleton.texte(lignes: 2),
      Ecart.vXxl,
      Skeleton.liste(lignes: 4),
    ],
  );
}
