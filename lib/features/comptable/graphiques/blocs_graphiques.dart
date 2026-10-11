// Les blocs de graphiques du Comptable (COMPTA-GRAPH-1) : anneau de
// repartition des coffres, entrees et sorties sur 6 mois, flux sur 30 jours,
// evolution sur 6 mois, et la carte des indicateurs Entrees et Sorties
// (mini-courbes, variations).
//
// Chaque bloc lit `seriesTresorerieProvider` (CPT-BR-18) et a ses cinq
// etats : chargement (`Skeleton`), contenu, vide, erreur (`EtatSysteme`,
// « Reessayer »), hors ligne (`EtatSansDonnees` quand rien n'a pu etre lu),
// plus « disponible au branchement serveur » quand la source n'existe pas
// encore. Les montants masques masquent le dessin et les variations
// (`GraphiqueSensible`, `PourcentageSensible`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/capacites/capacite_indisponible.dart';
import '../../../core/capacites/permission_insuffisante.dart';
import '../../../core/capacites/port_series_tresorerie.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/comptable/visibilite_montants.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bloc_asynchrone.dart';
import '../../../core/widgets/comptable/graphiques/graphiques_comptable.dart';
import '../../../core/widgets/comptable/pourcentage_sensible.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/montant_argent.dart' show TailleMontant;
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/skeleton.dart';

/// Les libelles des coffres, dans l'ordre §8.1.
String libelleCoffreGraphique(Coffre coffre) => switch (coffre) {
  Coffre.fondsClientsEngages => t.comptable.coffres.fondsClientsEngages,
  Coffre.paieADecaisser => t.comptable.coffres.paieADecaisser,
  Coffre.chargesEssentielles => t.comptable.coffres.chargesEssentielles,
  Coffre.taxesObligations => t.comptable.coffres.taxesObligations,
  Coffre.reserveStrategique => t.comptable.coffres.reserveStrategique,
  Coffre.enTransit => t.comptable.coffres.enTransit,
  Coffre.tresorerieLibre => t.comptable.coffres.tresorerieLibre,
};

String _mois(DateTime d) => t.commun.dates.mois[d.month - 1];

String _jour(DateTime d) => '${d.day} ${t.historique.moisCourts[d.month - 1]}';

/// « +12 » ou « -4 » : la variation ecrite, sans le signe de pourcentage.
String variationEcrite(int pourMille) {
  final double pourcent = pourMille / 10;
  final String nombre = pourcent == pourcent.roundToDouble()
      ? '${pourcent.round()}'
      : pourcent.toStringAsFixed(1).replaceAll('.', ',');
  return pourMille > 0 ? '+$nombre' : nombre;
}

/// Le squelette commun des blocs : les cinq etats autour d'un contenu.
class BlocSerie extends ConsumerWidget {
  /// Cree le bloc. [construire] recoit les series lues.
  const BlocSerie({
    required this.cle,
    required this.vide,
    required this.construire,
    super.key,
    this.silencieuxSiAbsent = false,
  });

  /// Vrai pour un bloc pose dans une autre page (Tresorerie, Aujourd'hui) :
  /// sans source de series, il ne rend rien (la page ne parle que de ce
  /// qu'elle lit). Faux sur la page « Rapports », qui dit « en preparation ».
  final bool silencieuxSiAbsent;

  /// La cle de base du bloc (« bloc-repartition »).
  final String cle;

  /// Vrai quand ces series n'ont rien a dessiner.
  final bool Function(SeriesTresorerie s) vide;

  /// Le contenu.
  final Widget Function(SeriesTresorerie s) construire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = t.comptable.graphiques;
    final AsyncValue<SeriesTresorerie> lecture = ref.watch(
      seriesTresorerieProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return BlocAsynchrone<SeriesTresorerie>(
      key: ValueKey<String>(cle),
      valeur: lecture,
      squelette: const Skeleton.liste(lignes: 3),
      onReessayer: () => ref.invalidate(seriesTresorerieProvider),
      estVide: vide,
      vide: EmptyState(
        key: ValueKey<String>('$cle-vide'),
        message: g.vide,
        invitation: g.videDetail,
        registre: RegistreVide.subi,
      ),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
        // §49 : une permission refusee n'est pas un echec reseau.
        if (erreur is PermissionInsuffisante) {
          return EtatSysteme(
            key: ValueKey<String>('$cle-permission'),
            nature: NatureEtat.permissionRefusee,
          );
        }
        // Source absente : ni un echec, ni un vide. Rien ne se reessaie.
        if (erreur is CapaciteIndisponible) {
          if (silencieuxSiAbsent) return const SizedBox.shrink();
          return EtatSysteme(
            key: ValueKey<String>('$cle-indisponible'),
            nature: NatureEtat.indisponible,
            titre: t.comptable.commun.enPreparationTitre,
            phrase: t.comptable.commun.enPreparationPhrase,
            dependance: erreur.dependance,
          );
        }
        return horsLigne
            ? EtatSansDonnees(
                key: ValueKey<String>('$cle-sans-donnees'),
                quoi: g.sansDonnees,
                onAction: reessayer,
              )
            : EtatSysteme(
                key: ValueKey<String>('$cle-erreur'),
                nature: NatureEtat.echecServeur,
                phrase: g.erreur,
                onAction: reessayer,
              );
      },
      construire: construire,
    );
  }
}

/// L'anneau de repartition des coffres.
class BlocRepartitionCoffres extends StatelessWidget {
  /// Cree le bloc.
  const BlocRepartitionCoffres({super.key});

  @override
  Widget build(BuildContext context) => BlocSerie(
    cle: 'bloc-repartition',
    silencieuxSiAbsent: true,
    vide: (SeriesTresorerie s) => s.repartition.isEmpty,
    construire: (SeriesTresorerie s) {
      final g = t.comptable.graphiques;
      final CouleursGraphiques c = CouleursGraphiques.de(context);
      final List<PartCoffre> parts = s.repartition;
      return GraphiqueSensible(
        titre: g.repartitionTitre,
        resume: g.repartitionResume(n: parts.length),
        hauteur: 200,
        dessin: Center(
          child: AnneauRepartition(
            valeurs: <double>[
              for (final PartCoffre p in parts) p.montant.mineur.toDouble(),
            ],
            couleurs: c.categories,
          ),
        ),
        legende: LegendeGraphique(
          entrees: <(Color, String)>[
            for (int i = 0; i < parts.length; i++)
              (
                c.categories[i % c.categories.length],
                libelleCoffreGraphique(parts[i].coffre),
              ),
          ],
        ),
        tableau: TableauValeurs(
          lignes: <LigneValeurs>[
            for (final PartCoffre p in parts)
              LigneValeurs(
                libelleCoffreGraphique(p.coffre),
                <(String, Montant)>[(g.legendeDetenue, p.montant)],
              ),
          ],
        ),
      );
    },
  );
}

/// Les entrees et les sorties des six derniers mois, en barres.
class BlocEntreesSorties6Mois extends StatelessWidget {
  /// Cree le bloc.
  const BlocEntreesSorties6Mois({super.key});

  @override
  Widget build(BuildContext context) => BlocSerie(
    cle: 'bloc-mensuel',
    vide: (SeriesTresorerie s) => s.mensuel.isEmpty,
    construire: (SeriesTresorerie s) {
      final g = t.comptable.graphiques;
      final CouleursGraphiques c = CouleursGraphiques.de(context);
      final List<PointMensuel> p = s.mensuel;
      return GraphiqueSensible(
        titre: g.mensuelTitre,
        resume: g.mensuelResume(
          debut: _mois(p.first.mois),
          fin: _mois(p.last.mois),
        ),
        dessin: BarresPeriodes(
          entrees: <double>[
            for (final PointMensuel m in p) m.entrees.mineur.toDouble(),
          ],
          sorties: <double>[
            for (final PointMensuel m in p) m.sorties.mineur.toDouble(),
          ],
          debut: _mois(p.first.mois),
          fin: _mois(p.last.mois),
        ),
        legende: LegendeGraphique(
          entrees: <(Color, String)>[
            (c.entrees, g.legendeEntrees),
            (c.sorties, g.legendeSorties),
          ],
        ),
        tableau: TableauValeurs(
          lignes: <LigneValeurs>[
            for (final PointMensuel m in p)
              LigneValeurs(_mois(m.mois), <(String, Montant)>[
                (g.legendeEntrees, m.entrees),
                (g.legendeSorties, m.sorties),
              ]),
          ],
        ),
      );
    },
  );
}

/// Le flux de tresorerie des trente derniers jours.
class BlocFlux30Jours extends StatelessWidget {
  /// Cree le bloc.
  const BlocFlux30Jours({super.key});

  @override
  Widget build(BuildContext context) => BlocSerie(
    cle: 'bloc-flux',
    vide: (SeriesTresorerie s) => s.flux30Jours.isEmpty,
    construire: (SeriesTresorerie s) {
      final g = t.comptable.graphiques;
      final CouleursGraphiques c = CouleursGraphiques.de(context);
      final List<PointJour> p = s.flux30Jours;
      return GraphiqueSensible(
        titre: g.fluxTitre,
        resume: g.fluxResume(
          debut: _jour(p.first.jour),
          fin: _jour(p.last.jour),
        ),
        dessin: CourbesTemporelles(
          series: <List<double>>[
            <double>[
              for (final PointJour j in p) j.encaissements.mineur.toDouble(),
            ],
            <double>[
              for (final PointJour j in p) j.decaissements.mineur.toDouble(),
            ],
          ],
          couleurs: <Color>[c.entrees, c.sorties],
          debut: _jour(p.first.jour),
          fin: _jour(p.last.jour),
        ),
        legende: LegendeGraphique(
          entrees: <(Color, String)>[
            (c.entrees, g.legendeEncaissements),
            (c.sorties, g.legendeDecaissements),
          ],
        ),
        tableau: TableauValeurs(
          lignes: <LigneValeurs>[
            for (final PointJour j in p)
              LigneValeurs(_jour(j.jour), <(String, Montant)>[
                (g.legendeEncaissements, j.encaissements),
                (g.legendeDecaissements, j.decaissements),
              ]),
          ],
        ),
      );
    },
  );
}

/// L'evolution de la tresorerie detenue sur six mois.
class BlocEvolution6Mois extends StatelessWidget {
  /// Cree le bloc.
  const BlocEvolution6Mois({super.key});

  @override
  Widget build(BuildContext context) => BlocSerie(
    cle: 'bloc-evolution',
    silencieuxSiAbsent: true,
    vide: (SeriesTresorerie s) => s.evolution.isEmpty,
    construire: (SeriesTresorerie s) {
      final g = t.comptable.graphiques;
      final CouleursGraphiques c = CouleursGraphiques.de(context);
      final List<PointEvolution> p = s.evolution;
      return GraphiqueSensible(
        titre: g.evolutionTitre,
        resume: g.evolutionResume(
          debut: _mois(p.first.mois),
          fin: _mois(p.last.mois),
        ),
        dessin: CourbesTemporelles(
          series: <List<double>>[
            <double>[
              for (final PointEvolution e in p) e.detenue.mineur.toDouble(),
            ],
          ],
          couleurs: <Color>[c.categories.first],
          debut: _mois(p.first.mois),
          fin: _mois(p.last.mois),
        ),
        legende: LegendeGraphique(
          entrees: <(Color, String)>[(c.categories.first, g.legendeDetenue)],
        ),
        tableau: TableauValeurs(
          lignes: <LigneValeurs>[
            for (final PointEvolution e in p)
              LigneValeurs(_mois(e.mois), <(String, Montant)>[
                (g.legendeDetenue, e.detenue),
              ]),
          ],
        ),
      );
    },
  );
}

/// Les indicateurs Entrees et Sorties (30 jours) : le total rendu par la
/// source, sa variation et une mini-courbe. Variation et courbe suivent les
/// montants : masques, ils disparaissent (Q-9).
class CarteIndicateursFlux extends StatelessWidget {
  /// Cree la carte.
  const CarteIndicateursFlux({super.key});

  @override
  Widget build(BuildContext context) => BlocSerie(
    cle: 'bloc-kpi',
    silencieuxSiAbsent: true,
    vide: (SeriesTresorerie s) => s.flux30Jours.isEmpty,
    construire: (SeriesTresorerie s) {
      final g = t.comptable.graphiques;
      final CouleursGraphiques c = CouleursGraphiques.de(context);
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                '${g.kpiTitre} · ${g.kpiPeriode}',
                style: AppPalette.of(context).inkStrong.applyTo(
                  Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
            _Indicateur(
              cle: 'kpi-entrees',
              libelle: g.kpiEntrees,
              total: s.entrees30Jours,
              variation: s.variationEntreesPourMille,
              valeurs: <double>[
                for (final PointJour j in s.flux30Jours)
                  j.encaissements.mineur.toDouble(),
              ],
              couleur: c.entrees,
            ),
            Ecart.vLg,
            _Indicateur(
              cle: 'kpi-sorties',
              libelle: g.kpiSorties,
              total: s.sorties30Jours,
              variation: s.variationSortiesPourMille,
              valeurs: <double>[
                for (final PointJour j in s.flux30Jours)
                  j.decaissements.mineur.toDouble(),
              ],
              couleur: c.sorties,
            ),
          ],
        ),
      );
    },
  );
}

class _Indicateur extends ConsumerWidget {
  const _Indicateur({
    required this.cle,
    required this.libelle,
    required this.total,
    required this.variation,
    required this.valeurs,
    required this.couleur,
  });

  final String cle;
  final String libelle;
  final Montant? total;
  final int? variation;
  final List<double> valeurs;
  final Color couleur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool affiche = ref.watch(visibiliteMontantsProvider);
    return MergeSemantics(
      child: Column(
        key: ValueKey<String>(cle),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            libelle,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          if (total != null)
            MontantSensible(total!, taille: TailleMontant.titre),
          if (variation != null) ...<Widget>[
            Ecart.vXs,
            PourcentageSensible(
              valeur: variationEcrite(variation!),
              gabarit: (String v) =>
                  t.comptable.graphiques.variation(pourcent: v),
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
          if (affiche) ...<Widget>[
            Ecart.vSm,
            MiniCourbe(valeurs: valeurs, couleur: couleur),
          ],
        ],
      ),
    );
  }
}
