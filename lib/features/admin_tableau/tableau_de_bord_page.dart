import 'dart:async';

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
import '../../core/widgets/halo_lumiere.dart';
import '../../core/widgets/page_shell.dart';
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
    // La file des pieces : lue seulement quand une piece attend (chaque
    // lecture de la file est journalisee au serveur). La liste ne sait trier
    // que par activite recente : « la plus ancienne en premier » n'est vrai
    // que si toute la file tient dans la page lue ; alors elle est rangee
    // ici, la plus ancienne devant. Sinon l'ordre du serveur est garde et
    // rien ne pretend a l'anciennete.
    final PageCandidatures? pagePieces =
        (attentes?.pieceAValider.nombre ?? 0) > 0
        ? ref.watch(pageCandidaturesProvider(requetePieces)).value
        : null;
    final bool piecesCompletes =
        pagePieces != null && pagePieces.total <= pagePieces.lignes.length;
    final List<LigneCandidature>? pieces = pagePieces == null
        ? null
        : (piecesCompletes
              ? _plusAnciennesDabord(pagePieces.lignes)
              : pagePieces.lignes);
    // Les visages des plus anciens d'un etat : seulement quand toute sa file
    // tient dans une page (sinon les plus anciens ne sont pas ceux qui sont
    // lus). Un etat de plus de cinquante personnes n'a donc pas de visages
    // tant que le serveur ne sait pas trier par anciennete.
    final Map<EtatCandidature, List<String>> visages =
        <EtatCandidature, List<String>>{};
    if (attentes != null) {
      for (final EtatCandidature etat in ParcoursCandidats.chemin) {
        final int n = attentes.etat(etat).nombre;
        if (n <= 0 || n > _taillePageListe) continue;
        final PageCandidatures? page = ref
            .watch(pageCandidaturesProvider(requeteEtat(etat)))
            .value;
        if (page == null || page.total > page.lignes.length) continue;
        visages[etat] = <String>[
          for (final LigneCandidature l in _plusAnciennesDabord(
            page.lignes,
          ).take(3))
            l.nomComplet,
        ];
      }
    }
    final int? dossiersAffiches = dossiers.hasValue
        ? RevueDossiersDepuisValidation.enseignantsSeulement(
            dossiers.requireValue,
          ).length
        : valeurs?.dossiersEnAttente;

    // 3. ALLER : au telephone, le menu ne montre pas les pages d'un domaine ;
    // les destinations qui n'ont que l'Accueil pour entree restent, dans une
    // case d'outils (jamais une liste a part). Sur tablette et ordinateur,
    // le panneau de navigation les porte toutes (NAV-SOUS-LIENS) : la case
    // ne s'affiche pas. Les E-mails n'y sont pas repetes quand leur case est
    // lue.
    final List<OutilAccueil> tousLesOutils = <OutilAccueil>[
      // AD-X : la file reunie des dossiers et des demandes (ADM-18).
      (
        cle: null,
        icone: AppIcons.attribution,
        libelle: t.admin.tableau.outilsTraitement,
        adresse: Routes.adminOperationsTraitement,
      ),
      // OFFRES-ADM-1 : les demandes des familles reunies, et la creation
      // de leur classe.
      (
        cle: null,
        icone: AppIcons.classes,
        libelle: t.admin.tableau.outilsRegroupements,
        adresse: Routes.adminOperationsRegroupements,
      ),
      // L2-05 : les creneaux de la vitrine.
      (
        cle: const ValueKey<String>('tableau-offres'),
        icone: AppIcons.creneaux,
        libelle: t.admin.tableau.outilsOffres,
        adresse: Routes.adminOperationsOffres,
      ),
      // AVIS-PUBLICS : les liens de collecte des avis, et leur moderation.
      (
        cle: const ValueKey<String>('tableau-avis'),
        icone: AppIcons.etoile,
        libelle: t.avis.admin.outil,
        adresse: Routes.adminOperationsAvis,
      ),
      // COURRIELS-1 : seulement si la case des courriels n'est pas la.
      if (courriels == null)
        (
          cle: const ValueKey<String>('tableau-courriels'),
          icone: AppIcons.envoyerMessage,
          libelle: t.courriels.admin.outil,
          adresse: Routes.adminOperationsCourriels,
        ),
      // ECHELLE-ADM-PILOTAGE-1 : la demande et l'offre par horaire.
      (
        cle: const ValueKey<String>('tableau-pilotage'),
        icone: AppIcons.tableauDeBord,
        libelle: t.admin.tableau.outilsPilotage,
        adresse: Routes.adminOperationsPilotage,
      ),
      // DASH-ADM-PLANNING : les seances de la semaine, toutes classes.
      (
        cle: const ValueKey<String>('tableau-planning'),
        icone: AppIcons.planningGlobal,
        libelle: t.admin.tableau.outilsPlanning,
        adresse: Routes.adminOperationsPlanning,
      ),
      (
        cle: null,
        icone: AppIcons.classes,
        libelle: t.admin.groupes.titre,
        adresse: Routes.adminOperationsGroupes,
      ),
      // COM-F-b (UX_REV-03, QUESTIONS Q4) : sans cette entree, au telephone,
      // les Communications ne s'atteignent que par la recherche.
      (
        cle: const ValueKey<String>('tableau-communications'),
        icone: AppIcons.annonce,
        libelle: t.com.socle.navigation.communications,
        adresse: Routes.adminOperationsCommunications,
      ),
      (
        cle: null,
        icone: AppIcons.profil,
        libelle: t.admin.tableau.outilsComptes,
        adresse: Routes.adminPersonnesComptes,
      ),
      (
        cle: null,
        icone: AppIcons.controleQualite,
        libelle: t.admin.tableau.outilsAccesAgents,
        adresse: Routes.adminSecuriteAuditAccesAgents,
      ),
    ];
    final bool outilsDansPanneau = SousLiensCoquille.couvre(context, <String>[
      for (final OutilAccueil o in tousLesOutils) o.adresse,
    ]);
    final bool outilsVisibles =
        !outilsDansPanneau &&
        MediaQuery.sizeOf(context).width < BentoVivant.seuilDeux;

    final Widget vivant = indicateurs.hasValue
        ? BentoVivant(
            maintenant: maintenant,
            indicateurs: indicateurs.requireValue,
            dossiers: dossiersAffiches ?? 0,
            // K-47 : des noms d'enseignants, comme la file qu'ouvre la case.
            // Chaque nom ouvre SON dossier par `extra`, jamais par l'URL
            // (spec l.1933), et jamais le premier de la file (modification
            // UX n°2, D4 (a)). La file illisible (genre du lecteur inconnu)
            // n'emporte que les noms.
            nomsDossiers: <NomDossier>[
              for (final DossierAValider d in plusAnciens.take(3))
                (
                  libelle:
                      '${d.libelleCourt} · '
                      '${_anciennete(maintenant, d.deposeLe)}',
                  onOuvrir: () => unawaited(
                    GoRouter.of(context).push<void>(
                      Routes.adminPersonnesDossiers,
                      extra: d.profilId,
                    ),
                  ),
                ),
            ],
            dossiersErreur: dossiers.hasError
                ? t.admin.tableau.apercuErreur
                : null,
            activite: ({required bool deuxColonnes}) =>
                ActiviteRecente(deuxColonnes: deuxColonnes),
            attentes: attentes,
            courriels: courriels,
            creneaux: creneaux,
            pieces: pieces,
            piecesPlusAncienneDabord: piecesCompletes,
            visages: visages,
            messagesNonLus: messagesNonLus,
            dernierMessage: dernierMessage,
            date: _dateDuJour(maintenant),
            lumieres: <MotifDirection, NatureHalo?>{
              for (final MotifDirection m in MotifDirection.values)
                m: lumiere(m),
            },
            // Sans alerte urgente, les alertes ouvertes suivent les cases.
            // Une source absente ou une liste vide ne montre rien ici : la
            // page des alertes (icone de l'en-tete) dit ces etats.
            alertes: !urgence && (alertes?.isNotEmpty ?? false)
                ? sectionAlertes
                : null,
            outils: outilsVisibles ? tousLesOutils : const <OutilAccueil>[],
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

    return PageShell(
      // VIVANT : plus de titre ni de sous-titre, la case de Praxis est
      // l'en-tete de la page (« Bonjour. » y est le titre lu en premier).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ALERTE-1 : une alerte urgente va en tete, avant tout.
          if (urgence) ...<Widget>[sectionAlertes, Ecart.vXxl],
          vivant,
        ],
      ),
    );
  }
}

/// La taille d'une page de `lister_candidatures` : au-dela, la file n'est pas
/// lue en entier.
const int _taillePageListe = 50;

/// Les lignes, de la plus ancienne activite a la plus recente.
List<LigneCandidature> _plusAnciennesDabord(List<LigneCandidature> lignes) =>
    <LigneCandidature>[...lignes]..sort(
      (LigneCandidature a, LigneCandidature b) =>
          a.derniereActivite.compareTo(b.derniereActivite),
    );

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
