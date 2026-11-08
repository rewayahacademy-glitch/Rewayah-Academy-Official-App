// MA-8 : la destination « Mon espace » du Mode Accessibilite.
//
// Consigne K-51 : la page commune des reglages (`ReglagesComptePage`) est
// REPRISE telle quelle ; seul ce qui est propre au mode s'ajoute autour :
// - en tete, la carte d'identite (prenom seul, jamais l'age : MA23) et la
//   ligne « Mode Accessibilite » avec sa description (A9) ;
// - l'adulte a une bascule (demonstration, MA24) ; le mineur lit l'etat et
//   peut DEMANDER la presentation standard a son tuteur (S7 = b), par un
//   port (`PortDemandePresentation`) : en cours, envoyee, ou envoi non
//   confirme avec « Reessayer » (D5) ;
// - en dernier, l'aide honnete : aucun canal publie, aucune promesse (MA14).
// « Aide audio » est absente : aucune preference ne pilote un audio (A9).
// Ni la bascule ni la demande ne touchent camera, micro ou droit (MA5).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/demande_presentation_supabase.dart'
    show portDemandePresentationProvider;
import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/accessibilite/port_demande_presentation.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../compte/compte_page.dart';
import '../compte/mes_donnees_page.dart' show RubriqueMesDonnees;
import '../foyer/photo_eleve.dart' show PhotoEleve;

/// L'etat de la demande de presentation standard du mineur.
enum EtatDemandePresentation {
  /// Aucune demande.
  aucune,

  /// Envoi en cours.
  enCours,

  /// Demande envoyee au tuteur.
  envoyee,

  /// Envoi non confirme.
  nonConfirmee,

  /// Rien n'est parti : le reseau est absent. La demande reste a refaire,
  /// « Reessayer » la renvoie.
  horsLigne,
}

/// Mon espace, en Mode Accessibilite, autour des reglages communs.
class MonEspaceAccessibilite extends StatefulWidget {
  /// Cree la destination.
  const MonEspaceAccessibilite({
    required this.prenom,
    required this.modeActif,
    required this.onAide,
    this.onBasculer,
    this.portDemande,
    this.personneId,
    this.estHorsLigne,
    this.onMesDonnees,
    this.onDeconnecter,
    super.key,
  });

  /// Se deconnecter, la meme ligne que le Compte, en dernier ; nul : la
  /// ligne n'est pas montree. Au telephone, le menu d'en-tete n'existe pas :
  /// c'est le seul moyen de se deconnecter (garde-cap, 08/11/2026).
  final VoidCallback? onDeconnecter;

  /// La cle de la ligne « Se deconnecter ».
  static const Key deconnexionKey = ValueKey<String>('mon-espace-deconnexion');

  /// Ouvre « Mes donnees », comme le Compte ; nul : la rubrique n'est pas
  /// montree. La rubrique suit sa propre capacite (`mesDonneesDisponibles`).
  final VoidCallback? onMesDonnees;

  /// Dit si le reseau est absent au moment d'envoyer ; nul : jamais.
  final bool Function()? estHorsLigne;

  /// Le prenom de l'eleve (jamais l'age).
  final String prenom;

  /// PHOTOS-B : le profil de l'eleve. Connu, sa photo vient de
  /// `photoPersonneProvider` ; nul, les initiales.
  final String? personneId;

  /// L'etat du Mode Accessibilite.
  final bool modeActif;

  /// Ouvre la page d'aide honnete, comme la ligne d'aide des autres ecrans
  /// du Mode Accessibilite (MA14, MA9).
  final VoidCallback onAide;

  /// La bascule de l'adulte ; nulle pour le mineur.
  final ValueChanged<bool>? onBasculer;

  /// Le port de la demande du mineur ; nul pour l'adulte.
  final PortDemandePresentation? portDemande;

  @override
  State<MonEspaceAccessibilite> createState() => _MonEspaceAccessibiliteEtat();
}

class _MonEspaceAccessibiliteEtat extends State<MonEspaceAccessibilite> {
  /// Le portrait de l'en-tete : la photo de l'eleve, ou ses initiales.
  Widget _photo() => PhotoEleve(
    prenom: widget.prenom,
    cleAvatar: null,
    personneId: widget.personneId,
    diametre: AppAvatar.moyen,
  );

  EtatDemandePresentation _demande = EtatDemandePresentation.aucune;

  Future<void> _demander(PortDemandePresentation port) async {
    if (widget.estHorsLigne?.call() ?? false) {
      setState(() => _demande = EtatDemandePresentation.horsLigne);
      return;
    }
    setState(() => _demande = EtatDemandePresentation.enCours);
    EtatDemandePresentation resultat;
    try {
      await port.demanderPresentationStandard();
      resultat = EtatDemandePresentation.envoyee;
    } on Object {
      resultat = EtatDemandePresentation.nonConfirmee;
    }
    if (mounted) setState(() => _demande = resultat);
  }

  LigneRubrique _ligneDemande(PortDemandePresentation port) {
    final bool pressable =
        _demande == EtatDemandePresentation.aucune ||
        _demande == EtatDemandePresentation.nonConfirmee ||
        _demande == EtatDemandePresentation.horsLigne;
    return LigneRubrique(
      libelle: t.accessibilite.monEspace.presentationStandard,
      legende: switch (_demande) {
        EtatDemandePresentation.aucune =>
          t.accessibilite.monEspace.demanderDetail,
        EtatDemandePresentation.enCours =>
          t.accessibilite.monEspace.demandeEnCours,
        EtatDemandePresentation.envoyee =>
          t.accessibilite.monEspace.demandeEnvoyee,
        EtatDemandePresentation.nonConfirmee =>
          t.accessibilite.monEspace.demandeNonConfirmee,
        EtatDemandePresentation.horsLigne =>
          t.accessibilite.monEspace.demandeHorsLigne,
      },
      valeur:
          _demande == EtatDemandePresentation.nonConfirmee ||
              _demande == EtatDemandePresentation.horsLigne
          ? t.compte.reessayer
          : null,
      icone: AppIcons.reglages,
      onPress: pressable ? () => unawaited(_demander(port)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? basculer = widget.onBasculer;
    final PortDemandePresentation? port = widget.portDemande;
    return ReglagesComptePage(
      titre: t.accessibilite.monEspace.titre,
      avant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCard(
            key: const ValueKey<String>('mon-espace-identite'),
            dominante: true,
            // MA15 : a texte agrandi, l'avatar passe au-dessus du prenom, qui
            // prend toute la largeur (aucun mot coupe).
            child: MediaQuery.textScalerOf(context).scale(1) > seuilTexteEmpile
                ? AvatarNom.vertical(
                    prenom: widget.prenom,
                    avatar: _photo(),
                    styleNom: Theme.of(context).textTheme.headlineSmall,
                  )
                : AvatarNom.enLigne(
                    prenom: widget.prenom,
                    avatar: _photo(),
                    ecart: AppSpacing.xl,
                    styleNom: Theme.of(context).textTheme.headlineSmall,
                  ),
          ),
          Ecart.vSection,
          // L'etat de la demande est annonce quand il change (region vive).
          Semantics(
            liveRegion: true,
            child: GroupeReglages(
              key: const ValueKey<String>('mon-espace-mode'),
              lignes: <LigneRubrique>[
                LigneRubrique(
                  libelle: t.accessibilite.monEspace.mode,
                  legende: t.accessibilite.monEspace.modeDetail,
                  icone: AppIcons.reglages,
                  // L'adulte : la bascule, sans chevron ; le mineur : l'etat,
                  // dit une seule fois, sans pastille.
                  valeur: basculer == null && widget.modeActif
                      ? t.accessibilite.monEspace.modeActif
                      : null,
                  controle: basculer == null
                      ? null
                      : Switch.adaptive(
                          key: const ValueKey<String>('bascule-mode'),
                          value: widget.modeActif,
                          onChanged: basculer,
                        ),
                ),
                if (basculer == null && port != null && widget.modeActif)
                  _ligneDemande(port),
              ],
            ),
          ),
        ],
      ),
      apres: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GroupeReglages(
            key: const ValueKey<String>('mon-espace-aide'),
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.accueil.aide,
                onPress: widget.onAide,
                icone: AppIcons.info,
              ),
            ],
          ),
          // Le Compte montre « Mes donnees » au mineur (selon sa capacite) :
          // « Mon espace » le garde (garde-cap, 08/11/2026).
          if (widget.onMesDonnees case final VoidCallback ouvrir)
            RubriqueMesDonnees(onOuvrir: ouvrir),
          if (widget.onDeconnecter case final VoidCallback sortir) ...<Widget>[
            Ecart.vSection,
            SettingRow(
              key: MonEspaceAccessibilite.deconnexionKey,
              title: t.compte.deconnexion,
              description: t.compte.deconnexionDetail,
              icon: AppIcons.sortie,
              onPress: sortir,
            ),
          ],
        ],
      ),
    );
  }
}

/// « Mon espace » du Mode Accessibilite, branche sur la vraie application
/// (tolere n° 18 et n° 1, 08/11/2026) : `/compte` le montre quand le Mode
/// Accessibilite est actif.
///
/// - Le prenom vient de `prenomDuCompteProvider` (`profiles` par soi) :
///   pendant la lecture, la page dit qu'elle charge ; sans prenom (lecture
///   refusee, impossible ou vide), le libelle du role, comme le Compte.
/// - La demande de presentation standard suit une capacite de la session
///   (`peutDemanderPresentationStandard`), jamais le role ; elle part par
///   `portDemandePresentationProvider` (RPC `demander_presentation_standard`).
///   Sans serveur, la ligne ne s'affiche pas.
/// - Hors ligne : le bandeau de la page, et la demande ne part pas ; elle
///   reste a refaire avec « Reessayer ».
class MonEspaceAccessibiliteBranche extends ConsumerWidget {
  /// Cree la destination branchee.
  const MonEspaceAccessibiliteBranche({super.key});

  /// La cle de la page pendant la lecture du prenom.
  static const Key chargementKey = ValueKey<String>('mon-espace-chargement');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionProvider);
    final AsyncValue<String?> prenomLu = ref.watch(prenomDuCompteProvider);
    // Ecoute du reseau, pour que l'etat soit lu au moment d'envoyer.
    ref.watch(horsLigneProvider);
    if (prenomLu.isLoading && !prenomLu.hasValue) {
      return PageShell(
        key: chargementKey,
        titre: t.accessibilite.monEspace.titre,
        child: const Skeleton.liste(lignes: 4),
      );
    }
    final String? lu = prenomLu.value?.trim();
    final String prenom = lu != null && lu.isNotEmpty
        ? lu
        : libelleRoleCompte(session.role ?? AppRole.student);
    final PortDemandePresentation? port =
        session.peutDemanderPresentationStandard
        ? ref.watch(portDemandePresentationProvider)
        : null;
    return MonEspaceAccessibilite(
      prenom: prenom,
      personneId: session.profileId,
      modeActif: ref.watch(modeAccessibiliteActifProvider),
      onAide: () => GoRouter.of(context).push(Routes.eleveAide),
      portDemande: port,
      estHorsLigne: () => ref.read(horsLigneProvider).value ?? false,
      onMesDonnees: () => GoRouter.of(context).push(Routes.compteMesDonnees),
      onDeconnecter: () => unawaited(seDeconnecter(context, ref)),
    );
  }
}
