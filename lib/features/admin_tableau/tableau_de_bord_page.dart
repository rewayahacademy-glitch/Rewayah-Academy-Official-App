import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/service_admin.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/offline_banner.dart';

/// Une ligne de la liste « a traiter en premier ».
///
/// Deux sources y arrivent, et une seule grandeur les ordonne : depuis quand
/// elles attendent. Un dossier depose hier passe donc devant une demande
/// deposee ce matin, quelle que soit sa nature.
@immutable
class ATraiter {
  /// Cree une ligne.
  const ATraiter({
    required this.libelle,
    required this.depuis,
    required this.destination,
    required this.icone,
  });

  /// Ce qui attend, dit en clair.
  final String libelle;

  /// Depuis quand. C'est la cle du tri, jamais la nature de la ligne.
  final DateTime depuis;

  /// L'ecran d'action, atteint d'un seul tap.
  final String destination;

  /// L'icone de la nature de la ligne.
  final AppIcon icone;
}

/// Assemble la liste a traiter, la plus ancienne en premier.
///
/// Fonction pure, comme `etatEnfant` et `etatAccueilEleve` : l'ordre se verifie
/// sans monter d'ecran.
///
/// **Les quatre autres compteurs n'y figurent pas, et ce n'est pas un oubli.**
/// Un foyer sans enseignant, un cahier manquant, un incident ou un acces echu se
/// comptent en base, mais aucune fonction ne rend la ligne correspondante :
/// `ADM-05` et le journal sont hors de l'etape 4. Une ligne qui ne menerait
/// nulle part vaut moins qu'un compteur qui dit combien.
List<ATraiter> aTraiter({
  required List<DossierAValider> dossiers,
  required List<Demande> demandes,
}) {
  final List<ATraiter> lignes = <ATraiter>[
    for (final DossierAValider dossier in dossiers)
      ATraiter(
        libelle: t.admin.tableau.ligneDossier(prenom: dossier.prenom),
        depuis: dossier.deposeLe,
        destination: Routes.adminDossiers,
        icone: AppIcons.dossiers,
      ),
    for (final Demande demande in demandes)
      ATraiter(
        libelle: switch (demande.sorte) {
          SorteDemande.reaffectation => t.admin.tableau.ligneReaffectation(
            prenom: demande.sujetPrenom,
          ),
          SorteDemande.plafond => t.admin.tableau.lignePlafond(
            prenom: demande.sujetPrenom,
          ),
          // Une sorte que ce code ne connait pas encore reste une demande a
          // trancher : elle se dit dans les termes les plus generaux plutot que
          // de disparaitre de la liste.
          _ => t.admin.tableau.ligneRegle(prenom: demande.sujetPrenom),
        },
        depuis: demande.creeeLe,
        destination: Routes.adminDemandes,
        icone: AppIcons.attribution,
      ),
  ]..sort((ATraiter a, ATraiter b) => a.depuis.compareTo(b.depuis));
  return lignes;
}

/// `ADM-01` : le centre de commande.
///
/// **Le zero s'affiche comme les autres valeurs** (invariant I9). Un compteur
/// qui disparait a zero laisse douter s'il a ete charge ou s'il est reellement
/// nul, et cette hesitation coute plus cher que la place qu'elle economise.
class TableauDeBordPage extends ConsumerWidget {
  /// Cree le centre de commande.
  const TableauDeBordPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant.
  ///
  /// Injectable pour la meme raison que sur `ELV-02` et `TUT-01` : l'anciennete
  /// des lignes se dit en jours, et un test cale sur l'horloge de la machine
  /// changerait de resultat selon l'heure a laquelle la CI le lance.
  final DateTime Function() horloge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final AsyncValue<IndicateursAdmin> indicateurs = ref.watch(
      indicateursProvider,
    );
    final AsyncValue<List<Demande>> demandes = ref.watch(demandesProvider);
    final AsyncValue<List<DossierAValider>> dossiers = ref.watch(
      dossiersEnAttenteProvider,
    );

    // Les getters, jamais le type d'execution : Riverpod 3 relance un provider
    // en echec tout seul, et l'etat repasse par `AsyncLoading` en conservant
    // `hasError` (piege de l'etape 3).
    final List<ATraiter> lignes = aTraiter(
      dossiers: dossiers.value ?? const <DossierAValider>[],
      demandes: demandes.value ?? const <Demande>[],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref
                    ..invalidate(indicateursProvider)
                    ..invalidate(demandesProvider)
                    ..invalidate(dossiersEnAttenteProvider);
                },
                child: ListView(
                  padding: EdgeInsets.all(metriques.marge),
                  children: <Widget>[
                    Text(t.admin.tableau.titre, style: textes.headlineSmall),
                    Ecart.vLg,

                    // 1. LES SIX COMPTEURS. Ils sont rendus des que la lecture
                    // aboutit, zeros compris.
                    if (indicateurs.hasValue)
                      _Compteurs(indicateurs: indicateurs.requireValue)
                    else if (indicateurs.hasError)
                      Text(
                        t.admin.tableau.compteursErreur,
                        // L'encre d'alerte, jamais la paire : `surfaceAlert`
                        // ecrit en blanc, illisible sur la page.
                        style: palette.inkAlert.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      )
                    else
                      Text(t.commun.chargement, style: textes.bodySmall),
                    Ecart.vXxl,

                    // 2. CE QUI SE TRAITE D'UN TAP.
                    Text(t.admin.tableau.aTraiter, style: textes.titleMedium),
                    Ecart.vMd,
                    if (lignes.isEmpty &&
                        dossiers.hasValue &&
                        demandes.hasValue)
                      EmptyState(
                        message: t.admin.tableau.aTraiterAucun,
                        invitation: t.admin.tableau.aTraiterAucunDetail,
                        icone: AppIcons.tableauDeBord,
                      )
                    else
                      for (final ATraiter ligne in lignes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _Ligne(ligne: ligne, maintenant: horloge()),
                        ),
                    // La file des dossiers passe par `read_kyc_documents()`, qui
                    // refuse la lecture quand le genre du lecteur est inconnu.
                    // Ce refus ne doit pas emporter la page : les compteurs, eux,
                    // viennent d'une autre fonction et restent exacts.
                    if (dossiers.hasError || demandes.hasError) ...<Widget>[
                      Ecart.vSm,
                      Text(
                        t.admin.tableau.listeErreur,
                        style: palette.inkAlert.applyTo(
                          textes.bodySmall ?? const TextStyle(),
                        ),
                      ),
                    ],
                    Ecart.vMd,
                    Text(
                      t.admin.tableau.aTraiterPortee,
                      style: textes.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les six compteurs, en deux colonnes.
class _Compteurs extends StatelessWidget {
  const _Compteurs({required this.indicateurs});

  final IndicateursAdmin indicateurs;

  @override
  Widget build(BuildContext context) {
    final List<({String libelle, int valeur, AppIcon icone})> compteurs =
        <({String libelle, int valeur, AppIcon icone})>[
          (
            libelle: t.admin.tableau.dossiers,
            valeur: indicateurs.dossiersEnAttente,
            icone: AppIcons.dossiers,
          ),
          (
            libelle: t.admin.tableau.demandes,
            valeur: indicateurs.demandesEnAttente,
            icone: AppIcons.attribution,
          ),
          (
            libelle: t.admin.tableau.foyers,
            valeur: indicateurs.foyersSansEnseignant,
            icone: AppIcons.foyer,
          ),
          (
            libelle: t.admin.tableau.rapports,
            valeur: indicateurs.rapportsManquants,
            icone: AppIcons.cahier,
          ),
          (
            libelle: t.admin.tableau.incidents,
            valeur: indicateurs.incidents24h,
            icone: AppIcons.avertissement,
          ),
          (
            libelle: t.admin.tableau.comptes,
            valeur: indicateurs.comptesEchus,
            icone: AppIcons.journee,
          ),
        ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // Deux colonnes a 390 px de large, la mesure de reference du projet.
        // La largeur derive de l'echelle, elle n'est pas posee telle quelle.
        final double colonne = (contraintes.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (final ({String libelle, int valeur, AppIcon icone}) compteur
                in compteurs)
              SizedBox(
                width: colonne,
                child: _Compteur(
                  libelle: compteur.libelle,
                  valeur: compteur.valeur,
                  icone: compteur.icone,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Un compteur. **Zero s'affiche**, c'est tout l'invariant I9.
class _Compteur extends StatelessWidget {
  const _Compteur({
    required this.libelle,
    required this.valeur,
    required this.icone,
  });

  final String libelle;
  final int valeur;
  final AppIcon icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    // Une valeur non nulle appelle l'oeil, une valeur nulle ne s'efface pas
    // pour autant : elle change de paire, jamais de presence. La couleur ne
    // porte donc rien seule, le chiffre le dit deja.
    final bool aTraiter = valeur > 0;

    return BentoTile(
      surface: aTraiter ? palette.surfaceWarning : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // `merge` et non `IconTheme` : la couleur vient de la paire posee par
          // `BentoTile`, et seule la taille est dite ici. Un `IconTheme` nu
          // l'effacerait, et l'icone serait noire sur la tuile d'avertissement
          // comme sur le fond general, quelle que soit la paire.
          IconTheme.merge(
            data: const IconThemeData(size: AppSpacing.xxl),
            child: Icon(icone.resoudre(selectionne: aTraiter)),
          ),
          Ecart.vSm,
          Text('$valeur', style: textes.headlineMedium),
          Text(libelle, style: textes.bodySmall),
        ],
      ),
    );
  }
}

/// Une ligne a traiter, qui mene d'un tap a l'ecran d'action.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.ligne, required this.maintenant});

  final ATraiter ligne;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final AppMetriques metriques = AppMetriques.of(context);
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final int jours = maintenant.difference(ligne.depuis).inDays;

    return BentoTile(
      libelleSemantique: ligne.libelle,
      onPress: () => GoRouter.of(context).go(ligne.destination),
      child: Row(
        children: <Widget>[
          IconTheme(
            data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
            child: Icon(ligne.icone.repos),
          ),
          SizedBox(width: metriques.marge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(ligne.libelle, style: textes.titleMedium),
                Text(switch (jours) {
                  <= 0 => t.admin.tableau.attenteAujourdhui,
                  1 => t.admin.tableau.attenteUnJour,
                  _ => t.admin.tableau.attenteJours(jours: '$jours'),
                }, style: textes.bodySmall),
              ],
            ),
          ),
          Icon(AppIcons.suivant.repos),
        ],
      ),
    );
  }
}
