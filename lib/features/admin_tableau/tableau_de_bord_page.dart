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
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/signal_row.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stat_tile.dart';

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
        libelle: t.admin.tableau.ligneDossier(prenom: dossier.libelleCourt),
        depuis: dossier.deposeLe,
        destination: Routes.adminPersonnesDossiers,
        icone: AppIcons.dossiers,
      ),
    for (final Demande demande in demandes)
      ATraiter(
        libelle: switch (demande.sorte) {
          SorteDemande.reaffectation => t.admin.tableau.ligneReaffectation(
            prenom: demande.sujetLibelle,
          ),
          SorteDemande.plafond => t.admin.tableau.lignePlafond(
            prenom: demande.sujetLibelle,
          ),
          // Une sorte que ce code ne connait pas encore reste une demande a
          // trancher : elle se dit dans les termes les plus generaux plutot que
          // de disparaitre de la liste.
          _ => t.admin.tableau.ligneRegle(prenom: demande.sujetLibelle),
        },
        depuis: demande.creeeLe,
        destination: Routes.adminOperationsDemandes,
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

    // A lire une seule fois pour toute la liste : l'anciennete de chaque ligne
    // se dit en jours par rapport au meme instant, sinon une ligne cramee par
    // la seconde changerait seule.
    final DateTime maintenant = horloge();

    return PageShell(
      titre: t.admin.tableau.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. LES SIX COMPTEURS. Ils sont rendus des que la lecture aboutit,
          // zeros compris.
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
            const Skeleton.liste(lignes: 2),
          Ecart.vXxl,

          // 2. CE QUI SE TRAITE D'UN TAP.
          Text(t.admin.tableau.aTraiter, style: textes.titleMedium),
          Ecart.vMd,
          if (lignes.isEmpty && dossiers.hasValue && demandes.hasValue)
            EmptyState(
              message: t.admin.tableau.aTraiterAucun,
              invitation: t.admin.tableau.aTraiterAucunDetail,
              icone: AppIcons.tableauDeBord,
            )
          else
            for (final ATraiter ligne in lignes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SignalRow(
                  phrase: ligne.libelle,
                  icone: ligne.icone,
                  // La nouveaute se dit en jours, jamais en heures : une ligne
                  // deposee ce matin et une deposee la veille se lisent d'un
                  // coup d'oeil, et le tri se verifie a l'oeil.
                  anciennete: switch (maintenant
                      .difference(ligne.depuis)
                      .inDays) {
                    <= 0 => t.admin.tableau.attenteAujourdhui,
                    1 => t.admin.tableau.attenteUnJour,
                    _ => t.admin.tableau.attenteJours(
                      jours: '${maintenant.difference(ligne.depuis).inDays}',
                    ),
                  },
                  onPress: () => GoRouter.of(context).go(ligne.destination),
                ),
              ),
          // La file des dossiers passe par `read_kyc_documents()`, qui refuse
          // la lecture quand le genre du lecteur est inconnu. Ce refus ne doit
          // pas emporter la page : les compteurs, eux, viennent d'une autre
          // fonction et restent exacts.
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
          Text(t.admin.tableau.aTraiterPortee, style: textes.bodySmall),
          Ecart.vXxl,

          // 3. LES RACCOURCIS CONTEXTUELS VERS PERSONNES ET SECURITE.
          //
          // **Ni un menu, ni un ecran vide.** Le gel d'architecture retire le
          // regroupement autonome « Outils » (un deuxieme menu, doublon de la
          // sidebar a huit domaines) mais garde les deux raccourcis : Comptes
          // et Acces des agents restent atteints depuis l'Accueil, puisque
          // Personnes et Securite et audit ne portent que leur fonction
          // primaire dans la sidebar (dossiers, journal), jamais un second
          // niveau (docs/architecture/ADMIN_IA_AUDIT.md, cartographie ADM-07
          // et ADM-08).
          //
          // `ADM-08` en premier, et pas par gout : c'est le seul ecran qui
          // montre une personne inscrite qui n'a pas encore depose sa piece.
          // Sans lui, trois enseignants ont attendu sept jours sans qu'aucun
          // ecran ne les nomme (defaut mesure le 18 septembre 2026).
          SettingRow(
            title: t.admin.tableau.outilsComptes,
            description: t.admin.tableau.outilsComptesDetail,
            icon: AppIcons.profil,
            onPress: () => GoRouter.of(context).go(Routes.adminPersonnesComptes),
          ),
          Ecart.vSm,
          SettingRow(
            title: t.admin.tableau.outilsAccesAgents,
            description: t.admin.tableau.outilsAccesAgentsDetail,
            icon: AppIcons.controleQualite,
            onPress: () =>
                GoRouter.of(context).go(Routes.adminSecuriteAuditAccesAgents),
          ),
        ],
      ),
    );
  }
}

/// Les six compteurs, en deux colonnes.
///
/// Trois portent vers un ecran d'action (dossiers, demandes, attribution) : un
/// chiffre qui mene a sa file se charge d'un coup de pouce. « Foyers sans
/// enseignant » a rejoint les deux autres le jour ou `ADM-05` a existe : c'est
/// tout l'interet d'un compteur que de mener a son geste. Les trois restants
/// sont des rapports, et ne menent nulle part tant que le journal et le cahier
/// de transmission ne suivent pas : une tuile sans [onPress] est un rapport,
/// jamais un bouton grise.
class _Compteurs extends StatelessWidget {
  const _Compteurs({required this.indicateurs});

  final IndicateursAdmin indicateurs;

  @override
  Widget build(BuildContext context) {
    final List<StatTile> tuiles = <StatTile>[
      StatTile(
        valeur: indicateurs.dossiersEnAttente,
        libelle: t.admin.tableau.dossiers,
        onPress: () => GoRouter.of(context).go(Routes.adminPersonnesDossiers),
      ),
      StatTile(
        valeur: indicateurs.demandesEnAttente,
        libelle: t.admin.tableau.demandes,
        onPress: () => GoRouter.of(context).go(Routes.adminOperationsDemandes),
      ),
      StatTile(
        valeur: indicateurs.foyersSansEnseignant,
        libelle: t.admin.tableau.foyers,
        onPress: () => GoRouter.of(context).go(Routes.adminOperationsAttributions),
      ),
      StatTile(
        valeur: indicateurs.rapportsManquants,
        libelle: t.admin.tableau.rapports,
      ),
      StatTile(
        valeur: indicateurs.incidents24h,
        libelle: t.admin.tableau.incidents,
      ),
      StatTile(
        valeur: indicateurs.comptesEchus,
        libelle: t.admin.tableau.comptes,
      ),
    ];

    // Le nombre de colonnes vient du gabarit, jamais d'une largeur comparee
    // ici : `05-regles-responsive.md` section 3 demande « grille de deux » en
    // tablette et « grille de quatre chiffres » en desktop.
    //
    // Avant ce correctif, le diviseur etait **2 a toutes les largeurs**. A
    // 1366 px, les six compteurs devenaient donc six rectangles etires sur une
    // demi-page, ce que la section 2 du meme document interdit en une phrase :
    // « Ne pas agrandir l'application mobile. Reorganiser. »
    final int colonnes = switch (AppGabarit.de(context)) {
      Gabarit.mobile || Gabarit.tablette => 2,
      Gabarit.desktop => 4,
    };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // La largeur derive de l'echelle et du nombre de colonnes, elle n'est
        // jamais posee telle quelle.
        final double colonne =
            (contraintes.maxWidth - AppSpacing.md * (colonnes - 1)) / colonnes;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (final StatTile tuile in tuiles)
              SizedBox(width: colonne, child: tuile),
          ],
        );
      },
    );
  }
}
