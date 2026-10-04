import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/service_admin.dart';
import '../../core/capacites/revue_dossiers_depuis_validation.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/matching/service_matching.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/signal_row.dart';
import '../../core/widgets/skeleton.dart';
import 'tuiles_compteur.dart';

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
    this.extra,
  });

  /// Ce qui attend, dit en clair.
  final String libelle;

  /// Depuis quand. C'est la cle du tri, jamais la nature de la ligne.
  final DateTime depuis;

  /// L'ecran d'action, atteint d'un seul tap.
  final String destination;

  /// L'icone de la nature de la ligne.
  final AppIcon icone;

  /// Ce que la destination doit ouvrir (le `profilId` d'un dossier), passe
  /// par `extra` de GoRouter, jamais par l'URL (spec l.1933).
  final Object? extra;
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
        // La ligne nomme une personne : elle ouvre son dossier, pas le
        // premier de la file (modification UX n°2).
        extra: dossier.profilId,
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
    // K-47 (HL-A-6) : les lignes « Dossier d'identite » ne portent que des
    // enseignants, comme la file ADM-02 qu'elles ouvrent. Meme cache, aucun
    // appel de plus ; le compteur serveur compte encore les tuteurs (BR-1.c).
    final List<ATraiter> lignes = aTraiter(
      dossiers: RevueDossiersDepuisValidation.enseignantsSeulement(
        dossiers.value ?? const <DossierAValider>[],
      ),
      demandes: demandes.value ?? const <Demande>[],
    );

    // A lire une seule fois pour toute la liste : l'anciennete de chaque ligne
    // se dit en jours par rapport au meme instant, sinon une ligne cramee par
    // la seconde changerait seule.
    final DateTime maintenant = horloge();

    // BENTO-1 : les trois plus anciens dossiers, en apercu dans la grande
    // tuile. Memes donnees que la file ci-dessous, aucun appel de plus.
    final List<DossierAValider> plusAnciens =
        RevueDossiersDepuisValidation.enseignantsSeulement(
          dossiers.value ?? const <DossierAValider>[],
        ).toList()..sort(
          (DossierAValider a, DossierAValider b) =>
              a.deposeLe.compareTo(b.deposeLe),
        );
    final List<String> apercu = <String>[
      for (final DossierAValider d in plusAnciens.take(3))
        '${d.libelleCourt} · ${_anciennete(maintenant, d.deposeLe)}',
    ];

    return PageShell(
      titre: t.admin.tableau.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. LES SIX COMPTEURS. Ils sont rendus des que la lecture aboutit,
          // zeros compris.
          if (indicateurs.hasValue)
            _Compteurs(
              indicateurs: indicateurs.requireValue,
              apercu: apercu,
              // m1 (AD-NETTOYAGE) : la tuile compte comme la liste « A
              // traiter » (enseignants seulement, meme cache). Tant que la
              // liste n'est pas lue, le compteur serveur reste la valeur
              // (il compte encore les tuteurs : BR-1.c).
              dossiersEnAttente: dossiers.hasValue
                  ? RevueDossiersDepuisValidation.enseignantsSeulement(
                      dossiers.requireValue,
                    ).length
                  : null,
            )
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
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: SignalRow(
                  phrase: ligne.libelle,
                  icone: ligne.icone,
                  // La nouveaute se dit en jours, jamais en heures : une ligne
                  // deposee ce matin et une deposee la veille se lisent d'un
                  // coup d'oeil, et le tri se verifie a l'oeil.
                  anciennete: _anciennete(maintenant, ligne.depuis),
                  onPress: () =>
                      GoRouter.of(context)
                          .go(ligne.destination, extra: ligne.extra),
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
          // niveau (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md, cartographie ADM-07
          // et ADM-08).
          //
          // `ADM-08` en premier, et pas par gout : c'est le seul ecran qui
          // montre une personne inscrite qui n'a pas encore depose sa piece.
          // Sans lui, trois enseignants ont attendu sept jours sans qu'aucun
          // ecran ne les nomme (defaut mesure le 18 septembre 2026).
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.admin.tableau.outilsComptes,
                description: t.admin.tableau.outilsComptesDetail,
                icon: AppIcons.profil,
                onPress: () =>
                    GoRouter.of(context).go(Routes.adminPersonnesComptes),
              ),
              SettingRow(
                title: t.admin.tableau.outilsAccesAgents,
                description: t.admin.tableau.outilsAccesAgentsDetail,
                icon: AppIcons.controleQualite,
                onPress: () =>
                    GoRouter.of(context)
                        .go(Routes.adminSecuriteAuditAccesAgents),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Les six compteurs, en grille Bento (BENTO-1).
///
/// **Jamais un damier.** La taille d'une tuile suit l'urgence de ce qu'elle
/// compte : « Dossiers a valider » est la grande tuile large, avec la phrase
/// d'action ; « Demandes a trancher » la tuile haute ; les deux suivants des
/// carres ; « Incidents (24 h) » et « Acces echus », quand ils valent zero
/// tous les deux, partagent une seule tuile large en bas, chaque chiffre
/// gardant son libelle.
///
/// Quatre portent vers un ecran d'action (dossiers, demandes, attribution,
/// rapports manquants) : un chiffre qui mene a sa file se charge d'un coup de
/// pouce. « Foyers sans enseignant » a rejoint les deux premiers le jour ou
/// `ADM-05` a existe ; « Rapports manquants » a rejoint le groupe le 19
/// septembre 2026, des que Pedagogie > Qualite (`ADM-14`) a existe pour
/// l'accueillir. Les deux restants (incidents, comptes echus) n'ont encore
/// aucune fonction Securite/Personnes reelle a filtrer : une tuile sans
/// [onPress] est un rapport, jamais un bouton grise.
class _Compteurs extends StatelessWidget {
  const _Compteurs({
    required this.indicateurs,
    this.apercu = const <String>[],
    this.dossiersEnAttente,
  });

  final IndicateursAdmin indicateurs;

  /// Le nombre de dossiers de la tuile, quand la liste est lue ; sinon le
  /// compteur du serveur.
  final int? dossiersEnAttente;

  /// Les plus anciens dossiers, nom et delai, pour la grande tuile.
  final List<String> apercu;

  @override
  Widget build(BuildContext context) {
    final bool calmes =
        indicateurs.incidents24h == 0 && indicateurs.comptesEchus == 0;
    return GrilleBento(
      tuiles: <TuileBento>[
        // Le plus urgent : la grande tuile, avec ce qu'un tap y fait.
        TuileBento(
          etendue: EtendueBento.large,
          etendueLarge: EtendueBento.grande,
          child: TuileCompteur(
            valeur: dossiersEnAttente ?? indicateurs.dossiersEnAttente,
            libelle: t.admin.tableau.dossiers,
            detail: t.admin.tableau.dossiersDetail,
            apercu: apercu,
            enLigne: true,
            onPress: () =>
                GoRouter.of(context).go(Routes.adminPersonnesDossiers),
          ),
        ),
        TuileBento(
          etendue: EtendueBento.haute,
          child: TuileCompteur(
            valeur: indicateurs.demandesEnAttente,
            libelle: t.admin.tableau.demandes,
            detail: t.admin.tableau.demandesDetail,
            onPress: () =>
                GoRouter.of(context).go(Routes.adminOperationsDemandes),
          ),
        ),
        TuileBento(
          etendue: EtendueBento.carree,
          child: TuileCompteur(
            valeur: indicateurs.foyersSansEnseignant,
            libelle: t.admin.tableau.foyers,
            onPress: () =>
                GoRouter.of(context).go(Routes.adminOperationsAttributions),
          ),
        ),
        TuileBento(
          etendue: EtendueBento.carree,
          child: TuileCompteur(
            valeur: indicateurs.rapportsManquants,
            libelle: t.admin.tableau.rapports,
            // Branche le 19 septembre 2026 : Pedagogie > Qualite (ADM-14)
            // affiche le groupe « Rapport manquant » ouvert par defaut.
            onPress: () =>
                GoRouter.of(context).go(Routes.adminPedagogieQualite),
          ),
        ),
        // Incidents et acces echus n'ont encore aucun ecran a filtrer : une
        // tuile sans appui est un rapport, jamais un bouton grise. A zero
        // tous les deux, ils partagent une seule tuile large.
        if (calmes)
          TuileBento(
            etendue: EtendueBento.large,
            etendueLarge: const EtendueBento(4, 1),
            child: TuileDouble(
              gauche: (indicateurs.incidents24h, t.admin.tableau.incidents),
              droite: (indicateurs.comptesEchus, t.admin.tableau.comptes),
            ),
          )
        else ...<TuileBento>[
          TuileBento(
            etendue: EtendueBento.carree,
            etendueLarge: EtendueBento.large,
            child: TuileCompteur(
              valeur: indicateurs.incidents24h,
              libelle: t.admin.tableau.incidents,
            ),
          ),
          TuileBento(
            etendue: EtendueBento.carree,
            etendueLarge: EtendueBento.large,
            child: TuileCompteur(
              valeur: indicateurs.comptesEchus,
              libelle: t.admin.tableau.comptes,
            ),
          ),
        ],
      ],
    );
  }
}

/// Depuis quand une ligne attend, dit en jours, jamais en heures : une ligne
/// deposee ce matin et une deposee la veille se lisent d'un coup d'oeil.
String _anciennete(DateTime maintenant, DateTime depuis) =>
    switch (maintenant.difference(depuis).inDays) {
      <= 0 => t.admin.tableau.attenteAujourdhui,
      1 => t.admin.tableau.attenteUnJour,
      final int jours => t.admin.tableau.attenteJours(jours: '$jours'),
    };
