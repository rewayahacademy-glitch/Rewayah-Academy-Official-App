// La Vue globale de la Finance, cote direction (`/admin/finance`, FI-11a ;
// guide Finance V4 §1.5, §5.6, §8 LOT F7 ; maquette 09).
//
// Sept indicateurs SEPARES (FI21) : encaissement, revenu, charge, marge,
// impayes, essais, soldes des familles ; chacun dans sa carte, avec son nombre
// exact et une phrase qui dit ce qu'il est et ce qu'il n'est pas. Puis
// l'evolution (revue FI-VAGUE-R R6-01 ; revue 12 d, e, f) : UN graphique par
// notion (encaisse, paie, marge, repartition du revenu par type d'eleve),
// jamais deux notions dans un meme graphique (ECARTS C5), chaque barre avec
// son nombre exact a cote (§8 F7 : un graphique ne remplace jamais un
// nombre). Les barres prennent les jetons existants (`surfacePrimary` sur
// `washAccent`, ECARTS A5 : l'accent seul, aucune couleur decorative). La
// marge par mois n'affiche AUCUNE reference de la politique : elle est
// calculee sur la seule paie, les ~30 % sont nets (voir plus bas). Puis les
// alertes, redigees ici depuis leur nature (K-41), chacune avec un seul lien
// vers sa cible (R6-04, revue 12 i).
//
// La longueur d'une barre est une mise a l'echelle de dessin
// (`longueursDeBarres` du port pour les montants, une marge sur 100 %),
// jamais un chiffre affiche : les nombres lus sont ceux du port.
//
// Tout vient du port (`PortFinanceDirection`) : cet ecran n'additionne, ne
// soustrait et ne compare aucun montant (FI6). La marge est celle du port,
// calculee sur la seule paie des enseignants : elle n'est jamais rapprochee
// des references nettes de la politique (environ 30 %, §1.5), ni presentee
// comme un objectif ou une sanction.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_finance_direction.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
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

  /// La cle de la grille des graphiques.
  static const Key graphiquesKey = ValueKey<String>('fi-vue-graphiques');

  /// La cle du graphique de l'encaisse par mois.
  static const Key graphiqueEncaisseKey = ValueKey<String>(
    'fi-vue-graphique-encaisse',
  );

  /// La cle du graphique de la paie par mois.
  static const Key graphiquePaieKey = ValueKey<String>('fi-vue-graphique-paie');

  /// La cle du graphique de la marge par mois.
  static const Key graphiqueMargeKey = ValueKey<String>(
    'fi-vue-graphique-marge',
  );

  /// La cle du graphique de repartition du revenu.
  static const Key graphiqueRepartitionKey = ValueKey<String>(
    'fi-vue-graphique-repartition',
  );

  /// La route qu'ouvre une alerte de cible [cible] : une page existante du
  /// routeur de la direction.
  static String routeDe(CibleAlerteFinance cible) => switch (cible) {
    CibleAlerteFinance.comptes => Routes.adminPersonnesComptes,
    CibleAlerteFinance.classes => Routes.adminOperationsGroupes,
  };

  /// La largeur minimale d'une carte au texte normal : celle qui loge quatre
  /// cartes a partir du seuil etendu (840), ecarts de 16 compris.
  static const double largeurMinCarte =
      (AppGabarit.seuilEtendu - 3 * AppSpacing.lg) / 4;

  /// Le nombre de colonnes de la grille pour une largeur de contenu : autant
  /// de cartes que la largeur en loge, chacune au moins [largeurMinCarte]
  /// multipliee par l'echelle du texte (aucun montant ni mot coupe), entre
  /// une et quatre.
  static int colonnesPour(double largeur, TextScaler texte) {
    final double echelle = texte.scale(AppSpacing.lg) / AppSpacing.lg;
    final double carte = largeurMinCarte * (echelle < 1 ? 1 : echelle);
    final int loge = ((largeur + AppSpacing.lg) / (carte + AppSpacing.lg))
        .floor();
    return loge.clamp(1, 4);
  }

  /// Vrai quand tous les indicateurs rendus sont nuls (montants a zero, aucun
  /// essai, marge absente) : une lecture de valeurs, jamais un calcul.
  static bool toutEstNul(VueGlobaleFinance v) =>
      v.margeProjeteePourMille == null &&
      v.essaisEnCours == 0 &&
      v.encaisse.estNul &&
      v.revenuAcademique.estNul &&
      v.paieEnseignants.estNul &&
      v.impayes.estNul &&
      v.soldesCrediteurs.estNul;

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
    final bool sansActivite = toutEstNul(vue);
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
        valeur: switch (marge) {
          final int m => vueT.margeValeur(valeur: pourMilleEnTexte(m)),
          null when sansActivite => vueT.margeSansActivite,
          null => vueT.margeNonCalculable,
        },
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
          vueT.contexte(deMois: deDevant(mois)),
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        // Mois sans activite : les zeros restent affiches (un compteur qui
        // disparait fait douter qu'il ait ete charge), la phrase le dit. Sans
        // revenu mais avec d'autres chiffres, seule la marge manque : la
        // phrase dit cela, et rien de plus.
        if (sansActivite) ...<Widget>[
          Ecart.vMd,
          Text(vueT.sansActivite(mois: mois), style: textes.bodyLarge),
        ] else if (marge == null) ...<Widget>[
          Ecart.vMd,
          Text(vueT.sansRevenu(mois: mois), style: textes.bodyLarge),
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
        SectionHeader(titre: vueT.evolution),
        Ecart.vXs,
        Text(
          vueT.evolutionDetail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vMd,
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) =>
              _Grille(
                key: graphiquesKey,
                colonnes: colonnesPour(
                  contraintes.maxWidth,
                  MediaQuery.textScalerOf(contexte),
                ).clamp(1, 2),
                children: _graphiques(vue, mois),
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
              for (final AlerteFinance a in vue.alertes) _bandeau(context, a),
            ],
          ),
      ],
    );
  }

  /// L'alerte redigee depuis sa nature et ses donnees, en une phrase entiere
  /// par cas (K-41).
  static Widget _bandeau(BuildContext context, AlerteFinance a) {
    final alerteT = t.admin.finance.vue.alerte;
    // Une seule action secondaire par alerte : le lien vers sa cible.
    final Widget action = LienFleche(
      key: ValueKey<String>('${a.id}-cible'),
      libelle: switch (a.cible) {
        CibleAlerteFinance.comptes => alerteT.ouvrirComptes,
        CibleAlerteFinance.classes => alerteT.ouvrirClasses,
      },
      onPress: () => GoRouter.of(context).go(routeDe(a.cible)),
    );
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
        action: action,
        titre: alerteT.aRegulariser,
        message: montant == null
            ? alerteT.aRegulariserSansMontant(qui: qui)
            : alerteT.aRegulariserMontant(qui: qui, montant: montant),
      ),
      NatureAlerteFinance.confirmationEnAttente => BandeauAttention(
        key: ValueKey<String>(a.id),
        ton: TonEtat.accent,
        action: action,
        titre: alerteT.confirmation,
        message: montant == null
            ? alerteT.confirmationSansMontant(qui: qui)
            : alerteT.confirmationMontant(qui: qui, montant: montant),
      ),
      NatureAlerteFinance.classeSousMinimum => BandeauAttention(
        key: ValueKey<String>(a.id),
        action: action,
        titre: alerteT.sousMinimum,
        message: alerteT.sousMinimumDetail(qui: qui),
      ),
    };
  }
}

/// Les quatre graphiques, un par notion, dans l'ordre des indicateurs.
List<Widget> _graphiques(VueGlobaleFinance vue, String mois) {
  final vueT = t.admin.finance.vue;
  String moisDe(DateTime d) => vueT.moisAnnee(
    mois: t.commun.dates.mois[d.month - 1],
    annee: '${d.year}',
  );
  List<_Barre> montants(List<MontantMensuel> serie) {
    final List<double> longueurs = longueursDeBarres(<int>[
      for (final MontantMensuel p in serie) p.montant.mineur,
    ]);
    return <_Barre>[
      for (int i = 0; i < serie.length; i++)
        _Barre(
          libelle: moisDe(serie[i].mois),
          montant: serie[i].montant,
          echelle: longueurs[i],
        ),
    ];
  }

  final List<double> parts = longueursDeBarres(<int>[
    for (final PartRevenu p in vue.revenuParType) p.montant.mineur,
  ]);
  return <Widget>[
    _Graphique(
      key: VueGlobaleFinanceContenu.graphiqueEncaisseKey,
      titre: vueT.graphiqueEncaisse,
      barres: montants(vue.encaisseParMois),
    ),
    _Graphique(
      key: VueGlobaleFinanceContenu.graphiquePaieKey,
      titre: vueT.graphiquePaie,
      barres: montants(vue.paieParMois),
    ),
    _Graphique(
      key: VueGlobaleFinanceContenu.graphiqueMargeKey,
      titre: vueT.graphiqueMarge,
      barres: <_Barre>[
        for (final MargeMensuelle p in vue.margeParMois)
          _Barre(
            libelle: moisDe(p.mois),
            texte: switch (p.pourMille) {
              final int m => vueT.margeValeur(valeur: pourMilleEnTexte(m)),
              null => vueT.margeNonCalculable,
            },
            echelle: switch (p.pourMille) {
              final int m => m.clamp(0, 1000) / 1000,
              null => 0,
            },
          ),
      ],
    ),
    _Graphique(
      key: VueGlobaleFinanceContenu.graphiqueRepartitionKey,
      titre: vueT.graphiqueRepartition,
      detail: vueT.graphiqueRepartitionDetail(deMois: deDevant(mois)),
      barres: <_Barre>[
        for (int i = 0; i < vue.revenuParType.length; i++)
          _Barre(
            libelle: switch (vue.revenuParType[i].type) {
              TypeEleveRevenu.enfant => vueT.repartitionEnfants,
              TypeEleveRevenu.adulte => vueT.repartitionAdultes,
            },
            montant: vue.revenuParType[i].montant,
            echelle: parts[i],
          ),
      ],
    ),
  ];
}

/// Une barre d'un graphique : son libelle, son nombre exact (un montant ou
/// un texte deja mis en mots) et sa longueur de dessin, entre 0 et 1.
class _Barre {
  const _Barre({
    required this.libelle,
    required this.echelle,
    this.montant,
    this.texte,
  });

  final String libelle;
  final Montant? montant;
  final String? texte;
  final double echelle;
}

/// Un graphique d'une seule notion : un titre, puis une ligne par barre,
/// chacune avec son nombre exact au-dessus de sa barre (§8 F7). Sans barre,
/// une phrase le dit (etat vide).
class _Graphique extends StatelessWidget {
  const _Graphique({
    required this.titre,
    required this.barres,
    super.key,
    this.detail,
  });

  final String titre;
  final String? detail;
  final List<_Barre> barres;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle chiffre = palette.inkStrong.applyTo(
      AppTypography.tabulaire(textes.bodyMedium ?? const TextStyle()),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(header: true, child: Text(titre, style: textes.titleSmall)),
          if (detail case final String d) ...<Widget>[
            Ecart.vXs,
            Text(
              d,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vMd,
          if (barres.isEmpty)
            Text(
              t.admin.finance.vue.sansHistorique,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
          else
            for (int i = 0; i < barres.length; i++) ...<Widget>[
              if (i > 0) Ecart.vMd,
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Wrap(
                      spacing: AppSpacing.sm,
                      alignment: WrapAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          barres[i].libelle,
                          style: palette.inkMuted.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
                        ),
                        if (barres[i].montant case final Montant m)
                          MontantArgent(m)
                        else
                          Text(barres[i].texte ?? '', style: chiffre),
                      ],
                    ),
                    Ecart.vXs,
                    ExcludeSemantics(child: _Trace(echelle: barres[i].echelle)),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Le trace d'une barre : un fond `washAccent`, la part `surfacePrimary`.
class _Trace extends StatelessWidget {
  const _Trace({required this.echelle});

  final double echelle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: palette.washAccent.decoration(
        borderRadius: AppRadius.arrondiFull,
      ),
      child: SizedBox(
        height: AppSpacing.sm,
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: echelle.clamp(0, 1),
          child: DecoratedBox(
            decoration: palette.surfacePrimary.decoration(
              borderRadius: AppRadius.arrondiFull,
            ),
          ),
        ),
      ),
    );
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
