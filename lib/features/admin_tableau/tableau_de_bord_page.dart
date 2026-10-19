import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/service_admin.dart';
import '../../core/alertes/alerte.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/capacites/revue_dossiers_depuis_validation.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/grille_bento.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../alertes/section_alertes.dart';
import 'activite_recente.dart';
import 'tuiles_compteur.dart';

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

  /// Largeur de la colonne « Activite recente » sur bureau : celle de la file
  /// du contrat D (DESIGN-GOV §4 bis.4).
  static const double largeurActivite = 336;

  /// En dessous, la grille Bento n'aurait plus ses quatre colonnes
  /// (`GrilleBento`, 600) : l'activite passe sous les tuiles.
  static const double largeurPrincipaleMin = GrilleBento.seuilQuatreColonnes;

  /// La date du jour, au bord de fin de l'en-tete (bureau seulement).
  static const Key cleDate = ValueKey<String>('adm01-date');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final AsyncValue<IndicateursAdmin> indicateurs = ref.watch(
      indicateursProvider,
    );
    final AsyncValue<List<DossierAValider>> dossiers = ref.watch(
      dossiersEnAttenteProvider,
    );

    // A lire une seule fois pour tout l'apercu : l'anciennete de chaque ligne
    // se dit en jours par rapport au meme instant, sinon une ligne cramee par
    // la seconde changerait seule.
    final DateTime maintenant = horloge();

    // Les trois plus anciens dossiers, en apercu dans la grande tuile
    // (DASH_STRATEGIE §3.1, D6). K-47 (HL-A-6) : seulement des enseignants,
    // comme la file ADM-02 qu'ils ouvrent ; le compteur serveur compte encore
    // les tuteurs (BR-1.c). Chaque nom ouvre SON dossier par `extra`, jamais
    // par l'URL (spec l.1933), et jamais le premier de la file (modification
    // UX n°2, D4 (a)).
    final List<DossierAValider> plusAnciens =
        RevueDossiersDepuisValidation.enseignantsSeulement(
          dossiers.value ?? const <DossierAValider>[],
        ).toList()..sort(
          (DossierAValider a, DossierAValider b) =>
              a.deposeLe.compareTo(b.deposeLe),
        );
    final List<LigneApercu> apercu = <LigneApercu>[
      for (final DossierAValider d in plusAnciens.take(3))
        LigneApercu(
          '${d.libelleCourt} · ${_anciennete(maintenant, d.deposeLe)}',
          onPress: () =>
              GoRouter.of(context)
                  .go(Routes.adminPersonnesDossiers, extra: d.profilId),
        ),
    ];

    // ALERTE-1 : une alerte urgente va en tete de la page, au-dessus de tout
    // autre contenu, jusqu'a son traitement. Sans alerte urgente, la section
    // suit les compteurs (D2 : agir, savoir, aller). Lit la capacite (le flux
    // des alertes), jamais un role.
    final List<Alerte>? alertes = ref.watch(alertesProvider).value;
    final bool urgence = (ref.watch(alertesUrgentesProvider) ?? 0) > 0;
    final Widget sectionAlertes = SectionAlertes(
      onOuvrir: (String chemin) => GoRouter.of(context).go(chemin),
      onVoirTout: () => GoRouter.of(context).go(Routes.adminAlertes),
    );

    final IndicateursAdmin? valeurs = indicateurs.value;
    // La phrase calme n'est vraie que si les quatre files d'action sont
    // vides, et qu'aucune alerte urgente ou importante n'est ouverte.
    // Incidents et acces echus, rapports sans action, n'y comptent pas.
    final bool calme =
        indicateurs.hasValue &&
        valeurs!.dossiersEnAttente == 0 &&
        valeurs.demandesEnAttente == 0 &&
        valeurs.foyersSansEnseignant == 0 &&
        valeurs.rapportsManquants == 0 &&
        !(alertes ?? const <Alerte>[]).any(
          (Alerte a) => a.gravite != GraviteAlerte.info,
        );

    // 1. AGIR ET SAVOIR : les compteurs, rendus des que la lecture aboutit,
    // zeros compris (D8). Les getters, jamais le type d'execution : Riverpod 3
    // relance un provider en echec tout seul, et l'etat repasse par
    // `AsyncLoading` en conservant `hasError`.
    final Widget compteurs = indicateurs.hasValue
        ? _Compteurs(
            indicateurs: indicateurs.requireValue,
            apercu: apercu,
            // La file passe par `read_kyc_documents()`, qui refuse la lecture
            // quand le genre du lecteur est inconnu. Ce refus n'emporte que
            // les noms : le chiffre vient d'une autre fonction et reste juste
            // (D11, erreur par source).
            apercuErreur: dossiers.hasError
                ? t.admin.tableau.apercuErreur
                : null,
            // m1 (AD-NETTOYAGE) : la tuile compte comme la liste « A traiter »
            // (enseignants seulement, meme cache). Tant que la liste n'est pas
            // lue, le compteur serveur reste la valeur (il compte encore les
            // tuteurs : BR-1.c).
            dossiersEnAttente: dossiers.hasValue
                ? RevueDossiersDepuisValidation.enseignantsSeulement(
                    dossiers.requireValue,
                  ).length
                : null,
          )
        : indicateurs.hasError
        // Une seule source pour les six chiffres : une phrase a la place de
        // toute la grille, jamais des tuiles a 0 (D10). L'encre d'alerte,
        // jamais la paire : `surfaceAlert` ecrit en blanc, illisible sur la
        // page.
        ? Text(
            t.admin.tableau.compteursErreur,
            style: palette.inkAlert.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          )
        : const _SqueletteCompteurs();

    // 3. ALLER : les raccourcis vers Operations, Personnes et Securite.
    //
    // **Ni un menu, ni un ecran vide.** Le gel d'architecture retire le
    // regroupement autonome « Outils » (un deuxieme menu, doublon de la
    // sidebar a huit domaines) mais garde les raccourcis : Groupes, Comptes et
    // Acces des agents restent atteints depuis l'Accueil
    // (docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md,
    // cartographie ADM-07 et ADM-08 ; DASH_STRATEGIE §3.1, Q2 : aucun lien
    // Planning tant que la page n'existe pas).
    //
    // `ADM-08` avant les agents, et pas par gout : c'est le seul ecran qui
    // montre une personne inscrite qui n'a pas encore depose sa piece. Sans
    // lui, trois enseignants ont attendu sept jours sans qu'aucun ecran ne les
    // nomme (defaut mesure le 18 septembre 2026).
    final Widget raccourcis = CarteLignes(
      lignes: <Widget>[
        // AD-X : la file reunie des dossiers et des demandes (ADM-18), la
        // liste « Elements a traiter » de l'image ADMIN-SHELL-01 sur sa page.
        SettingRow(
          title: t.admin.tableau.outilsTraitement,
          description: t.admin.tableau.outilsTraitementDetail,
          icon: AppIcons.attribution,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminOperationsTraitement),
        ),
        // OFFRES-ADM-1 : les demandes des familles reunies quand elles se
        // ressemblent, et la creation de leur classe.
        SettingRow(
          title: t.admin.tableau.outilsRegroupements,
          description: t.admin.tableau.outilsRegroupementsDetail,
          icon: AppIcons.classes,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminOperationsRegroupements),
        ),
        // L2-05 : les creneaux de la vitrine, crees et publies par
        // l'administration seule.
        SettingRow(
          key: const ValueKey<String>('tableau-offres'),
          title: t.admin.tableau.outilsOffres,
          description: t.admin.tableau.outilsOffresDetail,
          icon: AppIcons.creneaux,
          onPress: () => GoRouter.of(context).go(Routes.adminOperationsOffres),
        ),
        // AVIS-PUBLICS : les liens de collecte des avis des familles, et leur
        // moderation (publier, refuser, retirer).
        SettingRow(
          key: const ValueKey<String>('tableau-avis'),
          title: t.avis.admin.outil,
          description: t.avis.admin.outilDetail,
          icon: AppIcons.etoile,
          onPress: () => GoRouter.of(context).go(Routes.adminOperationsAvis),
        ),
        // ECHELLE-ADM-PILOTAGE-1 : la demande et l'offre d'enseignants par
        // horaire, R7 et R19.
        SettingRow(
          key: const ValueKey<String>('tableau-pilotage'),
          title: t.admin.tableau.outilsPilotage,
          description: t.admin.tableau.outilsPilotageDetail,
          icon: AppIcons.tableauDeBord,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminOperationsPilotage),
        ),
        // DASH-ADM-PLANNING : les seances de la semaine, toutes classes.
        SettingRow(
          key: const ValueKey<String>('tableau-planning'),
          title: t.admin.tableau.outilsPlanning,
          description: t.admin.tableau.outilsPlanningDetail,
          icon: AppIcons.planningGlobal,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminOperationsPlanning),
        ),
        SettingRow(
          title: t.admin.groupes.titre,
          description: t.admin.tableau.outilsGroupesDetail,
          icon: AppIcons.classes,
          onPress: () => GoRouter.of(context).go(Routes.adminOperationsGroupes),
        ),
        // COM-F-b (UX_REV-03, QUESTIONS Q4) : la racine Operations redirige
        // vers Groupes et n'a pas de sous-navigation ; sans cette ligne, les
        // Communications ne s'atteignent que par la recherche. Le domaine
        // Operations reste surligne.
        SettingRow(
          key: const ValueKey<String>('tableau-communications'),
          title: t.com.socle.navigation.communications,
          description: t.com.socle.navigation.communicationsDetail,
          icon: AppIcons.annonce,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminOperationsCommunications),
        ),
        SettingRow(
          title: t.admin.tableau.outilsComptes,
          description: t.admin.tableau.outilsComptesDetail,
          icon: AppIcons.profil,
          onPress: () => GoRouter.of(context).go(Routes.adminPersonnesComptes),
        ),
        SettingRow(
          title: t.admin.tableau.outilsAccesAgents,
          description: t.admin.tableau.outilsAccesAgentsDetail,
          icon: AppIcons.controleQualite,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminSecuriteAuditAccesAgents),
        ),
      ],
    );

    final Widget principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ALERTE-1 : une alerte urgente va en tete, avant les compteurs ;
        // sans urgence, la section suit les compteurs.
        if (urgence) ...<Widget>[sectionAlertes, Ecart.vXxl],
        compteurs,
        if (calme) ...<Widget>[
          Ecart.vLg,
          Text(t.admin.tableau.calme, style: textes.bodyMedium),
        ],
        if (!urgence) ...<Widget>[Ecart.vXxl, sectionAlertes],
      ],
    );

    return PageShell(
      titre: t.admin.tableau.titre,
      // AD-X (ADMIN-SHELL-01) : le sous-titre de l'image du directeur, et la
      // date du jour au bord de fin sur bureau. La salutation de l'image
      // n'est pas reprise : un titre d'ecran ne se souhaite pas la bienvenue.
      sousTitre: t.admin.tableau.sousTitre,
      actionsEntete: <Widget>[
        if (DataCollection.enTableau(context))
          Text(
            _dateDuJour(maintenant),
            key: TableauDeBordPage.cleDate,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
      ],
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          // 2. SAVOIR CE QUI S'EST PASSE : l'activite recente. Colonne de fin
          // de 336 (la file du contrat D) quand la place le permet, sous les
          // tuiles sinon ; jamais deux colonnes a 200 % de texte.
          final bool deuxColonnes =
              MediaQuery.textScalerOf(context).scale(1) < 2 &&
              contraintes.maxWidth >=
                  TableauDeBordPage.largeurActivite +
                      AppSpacing.xxl +
                      TableauDeBordPage.largeurPrincipaleMin;
          if (deuxColonnes) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: principal),
                    Ecart.hXxl,
                    const SizedBox(
                      width: TableauDeBordPage.largeurActivite,
                      child: ActiviteRecente(),
                    ),
                  ],
                ),
                Ecart.vXxxl,
                raccourcis,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              principal,
              Ecart.vXxl,
              const ActiviteRecente(),
              Ecart.vXxl,
              raccourcis,
            ],
          );
        },
      ),
    );
  }
}

/// « lundi 5 octobre 2026 » : la date du jour de l'en-tete (ADMIN-SHELL-01).
String _dateDuJour(DateTime jour) => t.historique.dateLongue(
  jourSemaine: t.commun.dates.jours[jour.weekday - 1].toLowerCase(),
  jour: jour.day,
  mois: t.commun.dates.mois[jour.month - 1],
  annee: jour.year,
);

/// Les memes tuiles que [_Compteurs], vides, le temps de la premiere lecture
/// (D11, DESIGN-GOV §4 bis.6 regle 3) : la page ne saute pas quand les
/// chiffres arrivent.
class _SqueletteCompteurs extends StatelessWidget {
  const _SqueletteCompteurs();

  @override
  Widget build(BuildContext context) {
    Widget bloc() => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) => Skeleton.tuileBento(
        hauteur: c.hasBoundedHeight
            ? c.maxHeight
            : GrilleBento.hauteurLignePour(
                MediaQuery.textScalerOf(context).scale(1),
              ),
      ),
    );
    return GrilleBento(
      tuiles: <TuileBento>[
        for (final (EtendueBento etendue, EtendueBento? large) in _etendues)
          TuileBento(etendue: etendue, etendueLarge: large, child: bloc()),
      ],
    );
  }
}

/// L'etendue des cinq tuiles, sur deux colonnes puis sur quatre : une seule
/// source pour la grille et son squelette.
const List<(EtendueBento, EtendueBento?)> _etendues =
    <(EtendueBento, EtendueBento?)>[
      (EtendueBento.grande, null),
      (EtendueBento.haute, null),
      (EtendueBento.carree, null),
      (EtendueBento.carree, null),
      (EtendueBento.large, EtendueBento(4, 1)),
    ];

/// Les six compteurs en cinq tuiles Bento (BENTO-1, DASH_STRATEGIE §3.1).
///
/// **Jamais un damier.** La taille d'une tuile suit l'urgence de ce qu'elle
/// compte : « Dossiers a valider » est la grande tuile, avec les trois plus
/// anciens ; « Demandes a trancher » la tuile haute ; les deux suivants des
/// carres ; « Incidents et acces » une seule tuile large en bas, qui garde ses
/// deux chiffres quelles que soient leurs valeurs (D3 : cinq indicateurs dans
/// tous les cas).
///
/// Quatre portent vers un ecran d'action (dossiers, demandes, regroupements,
/// rapports manquants). Incidents et acces echus n'ont encore aucune page qui
/// s'ouvre filtree sur ce qu'ils comptent (DASH-ADM-INC, DASH-ADM-ECHUS) : une
/// tuile sans appui est un rapport, jamais un bouton grise (D9).
class _Compteurs extends StatelessWidget {
  const _Compteurs({
    required this.indicateurs,
    this.apercu = const <LigneApercu>[],
    this.apercuErreur,
    this.dossiersEnAttente,
  });

  final IndicateursAdmin indicateurs;

  /// Le nombre de dossiers de la tuile, quand la liste est lue (enseignants
  /// seulement, comme la liste « A traiter », m1 d'AD-NETTOYAGE) ; sinon le
  /// compteur du serveur.
  final int? dossiersEnAttente;

  /// Les plus anciens dossiers, nom et delai, chacun vers son dossier.
  final List<LigneApercu> apercu;

  /// La phrase a la place des noms quand la file n'a pas pu etre lue.
  final String? apercuErreur;

  @override
  Widget build(BuildContext context) {
    final List<Widget> contenus = <Widget>[
      // Le plus urgent : la grande tuile. Le chiffre mene a la file, chaque
      // nom a son dossier.
      TuileCompteur(
        valeur: dossiersEnAttente ?? indicateurs.dossiersEnAttente,
        libelle: t.admin.tableau.dossiers,
        detail: t.admin.tableau.dossiersDetail,
        apercu: apercu,
        apercuErreur: apercuErreur,
        enLigne: true,
        onPress: () => GoRouter.of(context).go(Routes.adminPersonnesDossiers),
      ),
      TuileCompteur(
        valeur: indicateurs.demandesEnAttente,
        libelle: t.admin.tableau.demandes,
        detail: t.admin.tableau.demandesDetail,
        onPress: () => GoRouter.of(context).go(Routes.adminOperationsDemandes),
      ),
      TuileCompteur(
        valeur: indicateurs.foyersSansEnseignant,
        libelle: t.admin.tableau.foyers,
        onPress: () =>
            GoRouter.of(context).go(Routes.adminOperationsRegroupements),
      ),
      TuileCompteur(
        valeur: indicateurs.rapportsManquants,
        libelle: t.admin.tableau.rapports,
        // Branche le 19 septembre 2026 : Pedagogie > Qualite (ADM-14)
        // affiche le groupe « Rapport manquant » ouvert par defaut.
        onPress: () => GoRouter.of(context).go(Routes.adminPedagogieQualite),
      ),
      TuileDouble(
        titre: t.admin.tableau.incidentsEtAcces,
        gauche: (indicateurs.incidents24h, t.admin.tableau.incidents),
        droite: (indicateurs.comptesEchus, t.admin.tableau.comptes),
        // DASH-ADM-ECHUS : Comptes s'ouvre filtre sur les acces echus.
        // DASH-ADM-INC : la page des incidents liste les seances que compte
        // le chiffre (D9).
        onPressGauche: () =>
            GoRouter.of(context).go(Routes.adminSecuriteAuditIncidents),
        onPressDroite: () =>
            GoRouter.of(context).go(Routes.adminPersonnesComptesEchus),
      ),
    ];
    return GrilleBento(
      tuiles: <TuileBento>[
        for (int i = 0; i < _etendues.length; i++)
          TuileBento(
            etendue: _etendues[i].$1,
            etendueLarge: _etendues[i].$2,
            child: contenus[i],
          ),
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
      final int jours => LibellesGroupe.insecable(
        t.admin.tableau.attenteJours(jours: jours),
      ),
    };
