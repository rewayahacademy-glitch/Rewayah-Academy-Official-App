// Tresorerie et coffres (FIN-CPT-W04, M02 ecran 1 ; spec §8, §9, §10, §11,
// §32 ; CPT-TRES-1 et CPT-TRES-2). Constructeur pose par CPT-F, inchange.
//
// Repondre a « Ou est affecte l'argent ? » : la synthese (Tresorerie libre
// au centre, jamais le solde brut comme argent depensable, §11), la Reserve
// strategique (titre fixe, objectif selon le mode, R-FIN-05 a 07) et sa
// politique en lecture (aucune plage codee, R-FIN-08, 09), les mouvements
// permis (Alimenter = l'action cle ; retrait = demande de validation,
// bloque sans capacite, R-FIN-10), les sept coffres dans l'ordre §8.1, la
// prevision en lignes datees et l'historique des allocations (aucun
// graphique dans l'historique ; aucune allocation modifiable, §10.4). Les
// graphiques de la repartition et de l'evolution viennent de COMPTA-GRAPH-1
// (decision du directeur du 11/10, qui leve DR-09).
//
// Cinq etats par bloc (chargement, contenu, vide, erreur, hors ligne) ; une
// source absente (`CapaciteIndisponible`, production) rend la page « en
// preparation », sans aucun chiffre. Aucun widget ne lit un role : les gestes
// viennent des mouvements que la politique rend (`MouvementsCoffres`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:go_router/go_router.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/permission_insuffisante.dart';
import '../../../core/capacites/port_politique_reserve.dart';
import '../../../core/capacites/port_tresorerie.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/navigation_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bascule_montants.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/comptable/carte_reserve_strategique.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/comptable/resume_tresorerie.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../graphiques/blocs_graphiques.dart';
import 'carte_coffre.dart';
import 'carte_politique_reserve.dart';
import 'transfert/transfert_interne.dart';
import 'tresorerie_donnees.dart';

/// La tresorerie et ses sept coffres, onglet « Coffres » de Tresorerie.
class TresoreriePage extends ConsumerWidget {
  /// La cle du lien vers « Paiements des familles ».
  static const Key clePaiementsFamilles = ValueKey<String>(
    'tresorerie-paiements-familles',
  );

  /// Cree la page. [action] vient de `?action=` : `alimenter` ouvre
  /// « Alimenter la Reserve strategique » a l'arrivee (depuis Aujourd'hui).
  const TresoreriePage({super.key, this.action});

  /// L'action demandee par l'adresse, brute.
  final String? action;

  /// La largeur de contenu a partir de laquelle la page se compose en
  /// colonnes (bureau, H08 W04).
  static const double seuilColonnes = 960;

  /// La cle du bouton « Alimenter la Reserve strategique ».
  static const Key cleAlimenter = ValueKey<String>('tresorerie-alimenter');

  /// La cle du bouton « Retirer de la Reserve strategique ».
  static const Key cleRetirer = ValueKey<String>('tresorerie-retirer');

  /// La cle du bouton « Preparer un mouvement ».
  static const Key clePreparer = ValueKey<String>('tresorerie-preparer');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = t.comptable.tresorerie;
    final AsyncValue<SyntheseTresorerie> synthese = ref.watch(
      syntheseTresorerieProvider,
    );
    // Aucune source serveur (CPT-BR-04) : la page le dit, sans un chiffre.
    final bool sansSource =
        synthese.hasError && synthese.error is CapaciteIndisponible;
    return PageShell(
      titre: tr.titre,
      sousTitre: tr.sousTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsTresorerieComptable(),
        indexActif: 0,
      ),
      actionsEntete: const <Widget>[BasculeMontants(avecEtat: true)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Passation du 17/10, point 3 : les paiements recus des familles
          // et les factures du mois, atteints aussi sur telephone.
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LienFleche(
              key: TresoreriePage.clePaiementsFamilles,
              libelle: t.comptable.paiementsFamilles.entree,
              onPress: () => context.go(Routes.comptablePaiementsFamilles),
            ),
          ),
          Ecart.vLg,
          if (sansSource)
            EmptyState(
              message: t.comptable.commun.enPreparationTitre,
              invitation: t.comptable.commun.enPreparationPhrase,
              registre: RegistreVide.subi,
            )
          else
            _Contenu(
              ouvrirAlimentation: action == Routes.actionAlimenterReserve,
            ),
        ],
      ),
    );
  }
}

/// §49, « erreur partielle » : une partie de la page a ete lue, une autre
/// non. Les blocs lus restent affiches (jamais un ecran vide pour un seul
/// bloc en echec) ; une bande le dit et propose de relire. Elle ne parle pas
/// d'une capacite absente (la page le dit deja) ni d'une permission refusee.
class _BandeauErreurPartielle extends ConsumerWidget {
  const _BandeauErreurPartielle();

  static bool _echec(AsyncValue<Object?> v) =>
      v.hasError &&
      v.error is! CapaciteIndisponible &&
      v.error is! PermissionInsuffisante;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AsyncValue<Object?>> blocs = <AsyncValue<Object?>>[
      ref.watch(syntheseTresorerieProvider),
      ref.watch(coffresTresorerieProvider),
      ref.watch(previsionTresorerieProvider),
      ref.watch(historiqueTresorerieProvider),
      ref.watch(indicateursReserveProvider),
      ref.watch(politiqueReserveProvider),
    ];
    final bool unEchec = blocs.any(_echec);
    final bool unSucces = blocs.any((AsyncValue<Object?> v) => v.hasValue);
    if (!unEchec || !unSucces) return const SizedBox.shrink();
    final tr = t.comptable.tresorerie;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: AppCard(
        key: const ValueKey<String>('tresorerie-erreur-partielle'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              tr.erreurPartielle,
              style: AppPalette.of(context).inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            LienFleche(
              libelle: tr.erreurPartielleAction,
              alignerEnDebut: true,
              onPress: () => relireTresorerie(ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.ouvrirAlimentation});

  final bool ouvrirAlimentation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const _BandeauErreurPartielle(),
      _CorpsTresorerie(ouvrirAlimentation: ouvrirAlimentation),
    ],
  );
}

class _CorpsTresorerie extends StatelessWidget {
  const _CorpsTresorerie({required this.ouvrirAlimentation});

  final bool ouvrirAlimentation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) {
      final bool colonnes =
          contraintes.maxWidth >= TresoreriePage.seuilColonnes &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.5;
      final Widget mouvements = _ZoneMouvements(
        ouvrirAlimentation: ouvrirAlimentation,
      );
      if (!colonnes) {
        // Mobile (M02 ecran 1) : une tache dominante, Alimenter, tout de
        // suite sous la Reserve ; puis les coffres en liste.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _BlocSynthese(),
            Ecart.vXxl,
            const _BlocReserve(),
            Ecart.vLg,
            mouvements,
            Ecart.vSection,
            const _BlocCoffres(),
            Ecart.vSection,
            // COMPTA-GRAPH-1 : la repartition des coffres et l'evolution.
            const BlocRepartitionCoffres(),
            Ecart.vXxl,
            const BlocEvolution6Mois(),
            Ecart.vSection,
            const _BlocPrevision(),
            Ecart.vSection,
            const _BlocHistorique(),
            Ecart.vSection,
            const _BlocPolitique(),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _BlocSynthese(),
          Ecart.vXxl,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Expanded(flex: 3, child: _BlocCoffres()),
              Ecart.hXxl,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _BlocReserve(),
                    Ecart.vLg,
                    mouvements,
                    Ecart.vXxl,
                    const _BlocPolitique(),
                  ],
                ),
              ),
            ],
          ),
          Ecart.vSection,
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: BlocRepartitionCoffres()),
              Ecart.hXxl,
              Expanded(child: BlocEvolution6Mois()),
            ],
          ),
          Ecart.vSection,
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _BlocPrevision()),
              Ecart.hXxl,
              Expanded(child: _BlocHistorique()),
            ],
          ),
        ],
      );
    },
  );
}

/// Un bloc asynchrone de la page : sans reseau, un echec se dit « hors
/// ligne » (comme la Vue globale) ; une capacite absente reste dite
/// indisponible, sans « Reessayer ».
class _Bloc<T> extends ConsumerWidget {
  const _Bloc({
    required this.provider,
    required this.squelette,
    required this.construire,
    this.vide,
  });

  final ProviderListenable<AsyncValue<T>> provider;
  final Widget squelette;
  final Widget Function(T valeur) construire;
  final Widget? vide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return BlocAsynchrone<T>(
      valeur: ref.watch(provider),
      squelette: squelette,
      vide: vide,
      onReessayer: () => relireTresorerie(ref),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
        // §49 : une permission refusee n'est ni un echec reseau ni une
        // capacite absente ; recommencer ne change rien, pas de « Reessayer ».
        if (erreur is PermissionInsuffisante) {
          return const EtatSysteme(nature: NatureEtat.permissionRefusee);
        }
        return horsLigne && erreur is! CapaciteIndisponible
            ? EtatSysteme.sansDonnees(
                quoi: t.sansDonnees.tresorerie,
                onAction: reessayer,
              )
            : null;
      },
      construire: construire,
    );
  }
}

/// Une section : son titre, sa phrase, son contenu.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.child, this.phrase});

  final String titre;
  final String? phrase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String? p = phrase;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: titre),
        if (p != null) ...<Widget>[
          Ecart.vXs,
          Text(
            p,
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vLg,
        child,
      ],
    );
  }
}

class _BlocSynthese extends StatelessWidget {
  const _BlocSynthese();

  @override
  Widget build(BuildContext context) => _Bloc<SyntheseTresorerie>(
    provider: syntheseTresorerieProvider,
    squelette: const Skeleton.texte(lignes: 3),
    // Toute la largeur de la colonne (CPT-RC, revue CPT-R m4) : la carte
    // ne s'arrete plus a la moitie gauche au bureau.
    construire: (SyntheseTresorerie s) =>
        SizedBox(width: double.infinity, child: ResumeTresorerie(s)),
  );
}

class _BlocReserve extends StatelessWidget {
  const _BlocReserve();

  @override
  Widget build(BuildContext context) => _Bloc<IndicateursReserve>(
    provider: indicateursReserveProvider,
    squelette: const Skeleton.texte(lignes: 4),
    construire: CarteReserveStrategique.new,
  );
}

class _BlocPolitique extends StatelessWidget {
  const _BlocPolitique();

  @override
  Widget build(BuildContext context) => _Bloc<PolitiqueReserve>(
    provider: politiqueReserveProvider,
    squelette: const Skeleton.texte(lignes: 4),
    construire: CartePolitiqueReserve.new,
  );
}

class _BlocCoffres extends StatelessWidget {
  const _BlocCoffres();

  /// La largeur minimale d'une carte de coffre au texte normal.
  static const double largeurMinCarte = 260;

  @override
  Widget build(BuildContext context) {
    final tr = t.comptable.tresorerie;
    return _Section(
      titre: tr.coffresTitre,
      phrase: tr.coffresPhrase,
      child: _Bloc<List<SoldeCoffre>>(
        provider: coffresTresorerieProvider,
        squelette: const Skeleton.liste(lignes: 4),
        vide: EmptyState(
          message: tr.coffresVide,
          invitation: tr.coffresVidePhrase,
          registre: RegistreVide.subi,
        ),
        construire: (List<SoldeCoffre> soldes) {
          // L'ordre de la spec §8.1, quel que soit l'ordre rendu.
          final List<SoldeCoffre> ordonnes = <SoldeCoffre>[...soldes]
            ..sort(
              (SoldeCoffre a, SoldeCoffre b) =>
                  a.coffre.index.compareTo(b.coffre.index),
            );
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final bool deux =
                  c.maxWidth >= 2 * largeurMinCarte + AppSpacing.lg &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.5;
              final double largeur = deux
                  ? (c.maxWidth - AppSpacing.lg) / 2
                  : c.maxWidth;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: <Widget>[
                  for (final SoldeCoffre s in ordonnes)
                    SizedBox(width: largeur, child: CarteCoffre(s)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BlocPrevision extends StatelessWidget {
  const _BlocPrevision();

  @override
  Widget build(BuildContext context) {
    final tr = t.comptable.tresorerie;
    return _Section(
      titre: tr.previsionTitre,
      phrase: tr.previsionPhrase,
      child: _Bloc<List<LignePrevision>>(
        provider: previsionTresorerieProvider,
        squelette: const Skeleton.liste(lignes: 3),
        vide: EmptyState(
          message: tr.previsionVide,
          registre: RegistreVide.subi,
        ),
        construire: (List<LignePrevision> lignes) {
          final List<LignePrevision> datees = <LignePrevision>[...lignes]
            ..sort(
              (LignePrevision a, LignePrevision b) => a.date.compareTo(b.date),
            );
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < datees.length; i++) ...<Widget>[
                  if (i > 0) Ecart.vLg,
                  _LignePrevisionVue(datees[i]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LignePrevisionVue extends StatelessWidget {
  const _LignePrevisionVue(this.ligne);

  final LignePrevision ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final tr = t.comptable.tresorerie;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            ligne.libelle,
            style: palette.inkStrong.applyTo(
              textes.bodyLarge ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                t.comptable.commun.activiteInitiateurDate(
                  initiateur: ligne.entree ? tr.entree : tr.sortie,
                  date: dateComptable(ligne.date),
                ),
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              MontantSensible(ligne.montant),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlocHistorique extends StatelessWidget {
  const _BlocHistorique();

  @override
  Widget build(BuildContext context) {
    final tr = t.comptable.tresorerie;
    return _Section(
      titre: tr.historiqueTitre,
      phrase: tr.historiquePhrase,
      child: _Bloc<List<EntreeJournal>>(
        provider: historiqueTresorerieProvider,
        squelette: const Skeleton.liste(lignes: 3),
        vide: EmptyState(
          message: tr.historiqueVide,
          registre: RegistreVide.subi,
        ),
        construire: (List<EntreeJournal> entrees) => AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final EntreeJournal e in entrees) LigneActivite(e),
            ],
          ),
        ),
      ),
    );
  }
}

/// Les mouvements entre coffres (CPT-TRES-2) : « Alimenter la Reserve
/// strategique », l'action cle de l'ecran (§32) ; « Preparer un mouvement » ;
/// le retrait de la Reserve, toujours une demande de validation (§9.5) et
/// remplace par sa raison quand la politique le refuse (R-FIN-10). Un geste
/// impossible n'est jamais un bouton grise : une phrase dit pourquoi.
class _ZoneMouvements extends ConsumerStatefulWidget {
  const _ZoneMouvements({required this.ouvrirAlimentation});

  final bool ouvrirAlimentation;

  @override
  ConsumerState<_ZoneMouvements> createState() => _ZoneMouvementsState();
}

class _ZoneMouvementsState extends ConsumerState<_ZoneMouvements> {
  bool _arriveeTraitee = false;

  void _ouvrir({
    required String titre,
    required List<MouvementPermis> offerts,
    required String devise,
    List<MouvementBloque> bloques = const <MouvementBloque>[],
  }) {
    final Montant? manque = ref.read(indicateursReserveProvider).value?.manque;
    ouvrirTransfertInterne(
      context,
      titre: titre,
      offerts: offerts,
      bloques: bloques,
      devise: devise,
      manqueReserve: manque != null && manque.devise == devise ? manque : null,
      onMouvement: () => relireTresorerie(ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle phrase = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final tr = t.comptable.tresorerie;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? devise = ref
        .watch(syntheseTresorerieProvider)
        .value
        ?.libre
        .devise;
    if (horsLigne) {
      return AppCard(child: Text(tr.mouvementsHorsLigne, style: phrase));
    }
    return _Bloc<MouvementsCoffres>(
      provider: mouvementsTresorerieProvider,
      squelette: const Skeleton.texte(lignes: 2),
      construire: (MouvementsCoffres m) {
        final MouvementPermis? alimentation = m.alimentation;
        final MouvementPermis? retrait = m.retrait;
        final MouvementBloque? alimentationBloquee = m.alimentationBloquee;
        final MouvementBloque? retraitBloque = m.retraitBloque;
        final String? d = devise;
        final List<MouvementPermis> versReserve = <MouvementPermis>[
          for (final MouvementPermis o in m.offerts)
            if (o.destination == Coffre.reserveStrategique) o,
        ];
        final List<MouvementPermis> depuisReserve = <MouvementPermis>[
          for (final MouvementPermis o in m.offerts)
            if (o.origine == Coffre.reserveStrategique) o,
        ];
        if (widget.ouvrirAlimentation &&
            !_arriveeTraitee &&
            alimentation != null &&
            d != null) {
          _arriveeTraitee = true;
          WidgetsBinding.instance.addPostFrameCallback((Duration _) {
            if (!mounted) return;
            _ouvrir(titre: tr.alimenter, offerts: versReserve, devise: d);
          });
        }
        final List<Widget> lignes = <Widget>[
          Semantics(
            header: true,
            child: Text(
              tr.mouvementsTitre,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          Text(tr.mouvementsPhrase, style: phrase),
          Ecart.vLg,
        ];
        if (d == null) {
          lignes.add(const Skeleton.texte(lignes: 1));
        } else {
          if (alimentation != null) {
            lignes.add(
              ActionPrincipale(
                key: TresoreriePage.cleAlimenter,
                libelle: tr.alimenter,
                onPress: () => _ouvrir(
                  titre: tr.alimenter,
                  offerts: versReserve,
                  devise: d,
                ),
              ),
            );
          } else if (alimentationBloquee != null) {
            lignes.add(
              Text(
                tr.alimenterBloque(
                  raison: libelleRaisonBlocage(alimentationBloquee.raison),
                ),
                style: phrase,
              ),
            );
          }
          if (m.offerts.isNotEmpty) {
            lignes
              ..add(Ecart.vSm)
              ..add(
                ActionPrincipale(
                  key: TresoreriePage.clePreparer,
                  libelle: tr.preparerMouvement,
                  niveau: NiveauAction.secondaire,
                  onPress: () => _ouvrir(
                    titre: tr.transfert.titre,
                    offerts: m.offerts,
                    bloques: m.bloques,
                    devise: d,
                  ),
                ),
              );
          }
          if (retrait != null) {
            lignes
              ..add(Ecart.vSm)
              ..add(
                ActionPrincipale(
                  key: TresoreriePage.cleRetirer,
                  libelle: tr.retirer,
                  niveau: NiveauAction.secondaire,
                  onPress: () => _ouvrir(
                    titre: tr.retirer,
                    offerts: depuisReserve,
                    devise: d,
                  ),
                ),
              );
          } else if (retraitBloque != null) {
            lignes
              ..add(Ecart.vMd)
              ..add(
                Text(
                  tr.retraitBloque(
                    raison: libelleRaisonBlocage(retraitBloque.raison),
                  ),
                  style: phrase,
                ),
              );
          }
          if (m.offerts.isEmpty &&
              alimentationBloquee == null &&
              retraitBloque == null) {
            lignes.add(Text(tr.aucunMouvement, style: phrase));
          }
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: lignes,
          ),
        );
      },
    );
  }
}
