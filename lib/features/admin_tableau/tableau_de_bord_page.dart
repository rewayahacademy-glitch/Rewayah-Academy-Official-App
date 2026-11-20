import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accueil/signaux_accueils.dart';
import '../../core/admin/service_admin.dart';
import '../../core/admin/sous_liens_coquille.dart';
import '../../core/alertes/alerte.dart';
import '../../core/alertes/port_alertes.dart';
import '../../core/candidature/attentes_recrutement.dart';
import '../../core/candidature/creneaux_direction.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_prevenir_candidats.dart';
import '../../core/capacites/revue_dossiers_depuis_validation.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/isolat_bidi.dart' show enTeteArabe;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/halo_lumiere.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../alertes/section_alertes.dart';
import '../com_messages/non_lus_messages.dart';
import 'activite_recente.dart';
import 'bento_vivant.dart';
import 'dernier_non_lu.dart';
import 'phrase_praxis.dart';

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

  /// La date du jour, dans la case de Praxis (tablette et ordinateur).
  static const Key cleDate = BentoVivant.cleDate;

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
    // ALERTE-1 : une alerte urgente va en tete de la page, au-dessus de tout
    // autre contenu, jusqu'a son traitement. Sans alerte urgente, la section
    // suit les compteurs (D2 : agir, savoir, aller). Lit la capacite (le flux
    // des alertes), jamais un role.
    final List<Alerte>? alertes = ref.watch(alertesProvider).value;
    final bool urgence = (ref.watch(alertesUrgentesProvider) ?? 0) > 0;
    // LUMIERE-ACCUEILS 4 : les lumieres, depuis les seuls etats du serveur
    // (signalements, indicateurs) ; l'arbitre de `NavShell` fait tourner la
    // plus urgente, les autres restent en lueur fixe.
    final List<SignalAccueil<MotifDirection>> signaux = signauxDirection(
      alertes: alertes,
      indicateurs: indicateurs.value,
      // Le chiffre de la tuile (enseignants seulement), quand la file est
      // lue : la lumiere suit ce qui est affiche.
      dossiersAffiches: dossiers.hasValue
          ? RevueDossiersDepuisValidation.enseignantsSeulement(
              dossiers.requireValue,
            ).length
          : null,
    );
    NatureHalo? lumiere(MotifDirection motif) {
      for (final SignalAccueil<MotifDirection> x in signaux) {
        if (x.motif == motif) return x.nature;
      }
      return null;
    }

    final Widget sectionAlertes = SectionAlertes(
      lumiere: lumiere(MotifDirection.signalement),
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

    // VIVANT (20/11/2026) : une seule page, une seule grammaire. Chaque case
    // lit une lecture qui existe deja ; une lecture absente (capacite
    // indisponible : `hasValue` faux) n'affiche pas sa case. Praxis dit le
    // blocage du moment, calcule sur ces seuls compteurs (`phrase_praxis`).
    final AttentesRecrutement? attentes = ref
        .watch(attentesRecrutementProvider)
        .value;
    final EtatFileCourriels? courriels = ref
        .watch(etatFileCourrielsProvider)
        .value;
    final int? messagesNonLus = ref.watch(nonLusMessagesProvider).value;
    final (String, String)? dernierMessage = (messagesNonLus ?? 0) > 0
        ? ref.watch(dernierNonLuProvider).value
        : null;
    // Les creneaux ne se lisent que la ou le recrutement se lit.
    final List<CreneauDirection>? creneaux = attentes == null
        ? null
        : ref.watch(creneauxDirectionProvider).value;
    // La premiere personne de la file des pieces : lue seulement quand une
    // piece attend (chaque lecture de la file est journalisee au serveur).
    final LigneCandidature? piece = (attentes?.pieceAValider.nombre ?? 0) > 0
        ? ref
              .watch(pageCandidaturesProvider(requetePieces))
              .value
              ?.lignes
              .firstOrNull
        : null;
    final int? dossiersAffiches = dossiers.hasValue
        ? RevueDossiersDepuisValidation.enseignantsSeulement(
            dossiers.requireValue,
          ).length
        : valeurs?.dossiersEnAttente;
    final DossierAValider? plusAncien = plusAnciens.firstOrNull;
    final Widget vivant = indicateurs.hasValue
        ? BentoVivant(
            maintenant: maintenant,
            indicateurs: indicateurs.requireValue,
            dossiers: dossiersAffiches ?? 0,
            // K-47 : un nom d'enseignant, comme la file qu'ouvre la case. La
            // file illisible (genre du lecteur inconnu) n'emporte que le nom.
            dossierDetail: dossiers.hasError
                ? t.admin.tableau.apercuErreur
                : plusAncien == null
                ? null
                : '${plusAncien.libelleCourt} · '
                      '${_anciennete(maintenant, plusAncien.deposeLe)}',
            activite: const ActiviteRecente(),
            attentes: attentes,
            courriels: courriels,
            creneaux: creneaux,
            piece: piece,
            messagesNonLus: messagesNonLus,
            dernierMessage: dernierMessage,
            date: _dateDuJour(maintenant),
            lumieres: <MotifDirection, NatureHalo?>{
              for (final MotifDirection m in MotifDirection.values)
                m: lumiere(m),
            },
            phrase: PhrasePraxis.depuis(
              calme: calme,
              entretiensAPlanifier: attentes
                  ?.etat(EtatCandidature.entretienAPlanifier)
                  .nombre,
              creneauxOuverts: attentes?.creneauxOuverts,
              pieces: attentes?.pieceAValider.nombre,
              dossiers: dossiersAffiches,
              demandes: valeurs?.demandesEnAttente,
              messages: messagesNonLus,
            ),
          )
        : indicateurs.hasError
        // Une seule source pour les six chiffres : une phrase a la place de
        // toute la grille, jamais des cases a 0 (D10). L'encre d'alerte,
        // jamais la paire : `surfaceAlert` ecrit en blanc.
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: <Widget>[
              Text(
                t.admin.tableau.compteursErreur,
                style: palette.inkAlert.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              const ActiviteRecente(),
            ],
          )
        // La forme de la grille, pour que la page ne saute pas (D11).
        : const _SqueletteBento();

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
        // COURRIELS-1 : ecrire un e-mail, suivre la file d'envoi et voir les
        // adresses d'envoi.
        SettingRow(
          key: const ValueKey<String>('tableau-courriels'),
          title: t.courriels.admin.outil,
          description: t.courriels.admin.outilDetail,
          icon: AppIcons.envoyerMessage,
          onPress: () =>
              GoRouter.of(context).go(Routes.adminOperationsCourriels),
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

    // NAV-SOUS-LIENS (14/11/2026, point 2 de la revue) : sur tablette et
    // ordinateur, quand le panneau montre deja chacun de ces raccourcis en
    // sous-lien, l'Accueil ne les repete pas. Au telephone, ils restent : le
    // tiroir n'a pas de sous-liens.
    final bool raccourcisDansPanneau = SousLiensCoquille.couvre(
      context,
      const <String>[
        Routes.adminOperationsTraitement,
        Routes.adminOperationsRegroupements,
        Routes.adminOperationsOffres,
        Routes.adminOperationsAvis,
        Routes.adminOperationsCourriels,
        Routes.adminOperationsPilotage,
        Routes.adminOperationsPlanning,
        Routes.adminOperationsGroupes,
        Routes.adminOperationsCommunications,
        Routes.adminPersonnesComptes,
        Routes.adminSecuriteAuditAccesAgents,
      ],
    );

    // La liste de raccourcis ne reste qu'au telephone, ou le tiroir n'a pas
    // de sous-liens ; sur tablette et ordinateur, le panneau de navigation
    // les porte (NAV-SOUS-LIENS, puis VIVANT : « une seule page »).
    final bool raccourcisVisibles =
        !raccourcisDansPanneau &&
        MediaQuery.sizeOf(context).width < BentoVivant.seuilDeux;

    return PageShell(
      // VIVANT : plus de titre ni de sous-titre, la case de Praxis est
      // l'en-tete de la page (« Bonjour. » y est le titre lu en premier).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ALERTE-1 : une alerte urgente va en tete, avant tout.
          if (urgence) ...<Widget>[sectionAlertes, Ecart.vXxl],
          vivant,
          if (!urgence) ...<Widget>[Ecart.vXxl, sectionAlertes],
          if (raccourcisVisibles) ...<Widget>[Ecart.vXxl, raccourcis],
        ],
      ),
    );
  }
}

/// « lundi 5 octobre 2026 » : la date du jour de l'en-tete (ADMIN-SHELL-01).
String _dateDuJour(DateTime jour) => enTeteArabe(
  t.historique.dateLongue(
    jourSemaine: t.commun.dates.jours[jour.weekday - 1].toLowerCase(),
    jour: jour.day,
    mois: t.commun.dates.mois[jour.month - 1],
    annee: jour.year,
  ),
);

/// La forme de la grille le temps de la premiere lecture : la grande case,
/// puis deux rangs de cases (D11, DESIGN-GOV §4 bis.6 regle 3).
class _SqueletteBento extends StatelessWidget {
  const _SqueletteBento();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.lg,
    children: <Widget>[
      Skeleton.tuileBento(hauteur: 240),
      Row(
        spacing: AppSpacing.lg,
        children: <Widget>[
          Expanded(child: Skeleton.tuileBento()),
          Expanded(child: Skeleton.tuileBento()),
        ],
      ),
      Row(
        spacing: AppSpacing.lg,
        children: <Widget>[
          Expanded(child: Skeleton.tuileBento()),
          Expanded(child: Skeleton.tuileBento()),
        ],
      ),
    ],
  );
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
