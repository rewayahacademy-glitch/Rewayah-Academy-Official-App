import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/port_accord_publication.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_revenus_enseignant.dart';
import '../../core/communications/libelles_communication_slang.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/offre_horaire.dart';
import '../../core/offres/service_offres.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/profil/service_declaration.dart';
import '../../core/profil/service_profil_enseignant.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entete_compte.dart';
import '../../core/widgets/groupe_preferences.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_compte.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../code_conduite/code_conduite.dart';
import '../compte/lignes_compte.dart';
import '../compte/mes_donnees_page.dart';
import '../dossier/politique_controle.dart';
import '../paiements_recus/rubrique_recevoir_paiements.dart';
import '../revenus_enseignant/revenus_enseignant_page.dart'
    show heuresDuMoisPourProfil, revenusMoisEnCoursProvider;
import 'accord_publication_profil.dart';
import 'declaration_choix.dart';
import 'feuille_fuseau.dart';
import 'photo_publique.dart';

/// Le nom public de l'enseignant, avec son titre Sayyid ou Sayyida (R18, E16).
///
/// Tri du 31/10/2026 : le titre est lu par le profil (`teacher_profiles.titre`,
/// 0030) ; le nom se compose avec les libelles deja traduits des
/// Communications. Sans titre, `null` : l'en-tete garde le prenom.
final Provider<String?> nomPublicEnseignantProvider = Provider<String?>((
  Ref ref,
) {
  final ProfilEnseignant? profil = ref.watch(profilEnseignantProvider).value;
  if (profil == null || profil.titre == null) return null;
  return const LibellesCommunicationSlang().enseignant(
    prenom: profil.prenom,
    titre: profil.titre,
  );
});

/// FUSEAU-IDENTITE-PRO : la cle de la ligne « Fuseau horaire » de la feuille
/// « Identite professionnelle ».
const ValueKey<String> cleLigneFuseau = ValueKey<String>('profil-fuseau');

/// `ENS-05` : le Compte de l'enseignant, compose dans le gabarit unique
/// [PageCompte] (PROFILS P3, pilote et garde-cap du 11/11/2026).
///
/// Ordre fixe des sections : Mon espace (identite professionnelle,
/// publication sur le site, disponibilites), Paiements (revenus, versements),
/// Preferences, Compte et securite (statut, verification, contrats, double
/// verification, Mes donnees), Aide et informations (aide, informations
/// legales, politique de controle, code de conduite) ; puis la ligne rouge
/// « Se déconnecter » et la version. Des lignes sobres : aucune carte ni
/// medaillon, le detail s'ouvre par la ligne.
///
/// **C'est elle qui porte la deconnexion de l'enseignant** : la barre n'a pas
/// d'autre chemin vers elle. La ligne rouge reste rendue dans tous les etats
/// de la lecture du profil (chargement, vide, echec, hors ligne), et passe par
/// [seDeconnecter], qui demande avant de perdre un cahier non envoye.
class ProfilEnseignantPage extends ConsumerWidget {
  /// Cree le Compte de l'enseignant.
  const ProfilEnseignantPage({super.key, this.onOuvrirRevenus});

  /// Ouvre Mes revenus (FI-10). Nul : la route `/enseignant/revenus`, la
  /// demonstration y met sa propre adresse.
  final void Function(BuildContext context)? onOuvrirRevenus;

  /// La ligne « Identité professionnelle ».
  static const Key identiteKey = ValueKey<String>('compte-ens-identite');

  /// La ligne « Publication sur le site ».
  static const Key publicationKey = ValueKey<String>('compte-ens-publication');

  /// La ligne « Mes disponibilités ».
  static const Key disponibilitesKey = ValueKey<String>('compte-ens-dispo');

  /// La ligne « Mes revenus ».
  static const Key revenusKey = ValueKey<String>('compte-ens-revenus');

  /// La ligne du statut du compte.
  static const Key statutKey = ValueKey<String>('compte-ens-statut');

  /// La ligne « Contrat et accusés ».
  static const Key contratsKey = ValueKey<String>('compte-ens-contrats');

  /// La ligne de la politique de controle.
  static const Key politiqueKey = ValueKey<String>('compte-ens-politique');

  /// La ligne du code de conduite.
  static const Key codeConduiteKey = ValueKey<String>('compte-ens-conduite');

  /// L'ouverture par defaut : la pose de la branche Profil.
  static void ouvrirRevenus(BuildContext context) =>
      unawaited(context.push(Routes.enseignantRevenus));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProfilEnseignant?> lecture = ref.watch(
      profilEnseignantProvider,
    );
    final ProfilEnseignant? profil = lecture.value;
    final SessionState session = ref.watch(sessionProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool pushAutorise =
        ref.watch(notificationsAutoriseesProvider).value ?? false;
    final String? clePhoto = ref.watch(photoPubliqueProvider);
    final String? nomPublic = ref.watch(nomPublicEnseignantProvider)?.trim();
    final AsyncValue<List<Acceptation>> acceptations = ref.watch(
      acceptationsProvider,
    );
    final AsyncValue<RevenusEnseignant> mois = ref.watch(
      revenusMoisEnCoursProvider,
    );

    // Le statut qui GOUVERNE l'acces vient de la session, celui qui s'AFFICHE
    // vient du profil : deux lectures qui ne sont pas du meme instant. On
    // affiche la plus fraiche, et on dit qu'elle diverge quand c'est le cas.
    final AccountStatus? statut = profil?.statutCompte;
    final (String statutCourt, String statutDetail, TonEtat ton) = _direStatut(
      statut,
    );
    final bool divergent =
        statut != null &&
        session.accountStatus != null &&
        statut != session.accountStatus;

    final String prenom = profil?.prenom.trim() ?? '';
    final AsyncValue<IdentiteCompte?> identite = switch (lecture) {
      AsyncValue<ProfilEnseignant?>(hasValue: true) =>
        AsyncValue<IdentiteCompte?>.data(
          profil == null
              ? null
              : IdentiteCompte(
                  nom: nomPublic != null && nomPublic.isNotEmpty
                      ? nomPublic
                      : prenom.isEmpty
                      ? t.compte.roles.teacher
                      : prenom,
                  role: nomPublic == null && prenom.isEmpty
                      ? null
                      : t.compte.roles.teacher,
                  matricule: profil.identifiant.isEmpty
                      ? null
                      : profil.identifiant,
                  statut: statutCourt,
                ),
        ),
      AsyncValue<ProfilEnseignant?>(hasError: true) =>
        AsyncValue<IdentiteCompte?>.error(
          lecture.error!,
          lecture.stackTrace ?? StackTrace.empty,
        ),
      _ => const AsyncValue<IdentiteCompte?>.loading(),
    };

    final LigneRubrique? recevoir = ligneRecevoirPaiements(context, ref);
    final Widget? avisRecevoir = avisRecevoirPaiements(context, ref);
    final LigneRubrique? aide = ligneAideCompte(ref);
    final LigneRubrique? publication = _lignePublication(context, ref);
    final bool codeAAccepter =
        acceptations.hasValue &&
        acceptationCodeConduite(acceptations.requireValue) == null;

    return PageCompte(
      identite: identite,
      onReessayer: () => ref.invalidate(profilEnseignantProvider),
      onDeconnecter: () async {
        await seDeconnecter(context, ref);
      },
      photo: profil == null
          ? null
          : PortraitPublic(
              prenom: profil.prenom,
              cle: clePhoto,
              diametre: AppAvatar.grand,
            ),
      // La photo publique se touche pour la changer (plus de lien separe).
      onChangerPhoto: profil == null || horsLigne
          ? null
          : () =>
                unawaited(ouvrirPhotoPublique(context, prenom: profil.prenom)),
      preferences: GroupePreferences(
        langue: ligneLangueCompte(context),
        notifications: pushAutorise ? ligneNotificationsCompte(context) : null,
        accessibilite: ligneAccessibiliteCompte(context),
      ),
      avantLignes: <SectionCompte, List<Widget>>{
        if (avisRecevoir != null)
          SectionCompte.paiements: <Widget>[avisRecevoir],
        if (divergent)
          SectionCompte.compteSecurite: <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                t.enseignant.profil.statutDivergent,
                style: AppPalette.of(context).inkWarning.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ],
      },
      sections: <SectionCompte, List<LigneRubrique>>{
        SectionCompte.monEspace: <LigneRubrique>[
          if (profil != null)
            LigneRubrique(
              cle: identiteKey,
              icone: AppIcons.profil,
              libelle: t.enseignant.profil.identite,
              legende: _resumeIdentite(profil),
              onPress: () => _ouvrirSousPage(
                context,
                titre: t.enseignant.profil.identite,
                corps: const _IdentiteProfessionnelle(),
              ),
            ),
          ?publication,
          // NAV-REFONTE (09/11/2026) : les disponibilites s'ouvrent ici ;
          // `push` : le retour ramene au Compte.
          LigneRubrique(
            cle: disponibilitesKey,
            icone: AppIcons.creneaux,
            libelle: t.enseignant.creneaux.mesDisponibilites,
            legende: t.enseignant.profil.disponibilitesDetail,
            onPress: () => unawaited(context.push(Routes.enseignantCreneaux)),
          ),
        ],
        SectionCompte.paiements: <LigneRubrique>[
          // REVENUS-VERITE : les heures du mois lues au serveur, sinon la
          // phrase generale, jamais un chiffre invente.
          LigneRubrique(
            cle: revenusKey,
            icone: AppIcons.finance,
            libelle: t.enseignant.profil.revenus,
            legende: mois.hasValue && !mois.hasError
                ? heuresDuMoisPourProfil(mois.requireValue)
                : t.enseignant.profil.revenusDetail,
            onPress: () => (onOuvrirRevenus ?? ouvrirRevenus)(context),
          ),
          ?recevoir,
        ],
        SectionCompte.compteSecurite: <LigneRubrique>[
          if (profil != null) ...<LigneRubrique>[
            LigneRubrique(
              cle: statutKey,
              icone: AppIcons.profil,
              libelle: t.enseignant.profil.statutSection,
              legende: statutDetail,
              marque: StatusPill(libelle: statutCourt, ton: ton),
            ),
            LigneRubrique(
              icone: AppIcons.controleQualite,
              libelle: t.enseignant.profil.verification,
              valeur: switch (profil.verification) {
                VerificationEnseignant.enAttente =>
                  t.enseignant.profil.verificationEnAttente,
                VerificationEnseignant.validee =>
                  t.enseignant.profil.verificationValidee,
                VerificationEnseignant.refusee =>
                  t.enseignant.profil.verificationRefusee,
                null => t.enseignant.profil.nonRenseigne,
              },
            ),
          ],
          // Le contrat et les accuses, en lecture seule et pour toujours :
          // `/attente/*` se ferme des que le compte devient actif.
          LigneRubrique(
            cle: contratsKey,
            icone: AppIcons.dossiers,
            libelle: t.enseignant.profil.contratSection,
            legende: t.enseignant.profil.contratLectureSeule,
            onPress: () => _ouvrirSousPage(
              context,
              titre: t.enseignant.profil.contratSection,
              corps: const _Contrats(),
            ),
          ),
          // MFA-DIRECTION : la double verification (capacite de la session).
          if (session.peutActiverDoubleVerification)
            LigneRubrique(
              cle: const ValueKey<String>('compte-securite'),
              icone: AppIcons.verrou,
              libelle: t.compte.securite,
              legende: t.compte.doubleVerification.rubriqueDetail,
              onPress: () => unawaited(context.push(Routes.compteSecurite)),
            ),
          // CPT-SUPPR-EXPORT : selon la capacite du port.
          if (ref.watch(mesDonneesDisponiblesProvider))
            LigneRubrique(
              cle: RubriqueMesDonnees.ligneKey,
              icone: AppIcons.dossiers,
              libelle: t.compte.donnees.ligne,
              legende: t.compte.donnees.ligneDetail,
              onPress: () => unawaited(context.push(Routes.compteMesDonnees)),
            ),
        ],
        SectionCompte.aide: <LigneRubrique>[
          ?aide,
          ligneInformationsLegales(context),
          // La politique que le contrat fait « confirmer avoir recue »,
          // « disponible dans votre espace » (clause du contrat).
          LigneRubrique(
            cle: politiqueKey,
            icone: AppIcons.controleQualite,
            libelle: t.contrat.politique.lien,
            onPress: () => unawaited(ouvrirPolitiqueControle(context)),
          ),
          // PE : le code de conduite se lit et s'accepte ici ; tant qu'il
          // n'est pas accepte, la legende le dit.
          LigneRubrique(
            cle: codeConduiteKey,
            icone: AppIcons.lecon,
            libelle: t.codeConduite.lien,
            legende: codeAAccepter ? t.codeConduite.aAccepter : null,
            onPress: () => unawaited(ouvrirCodeConduite(context)),
          ),
        ],
      },
    );
  }

  /// La ligne « Publication sur le site » (CAND-PHOTO, 06/11/2026) : la
  /// valeur actuelle a droite, le detail (et le retrait) dans sa page.
  /// Capacite absente : pas de ligne.
  LigneRubrique? _lignePublication(BuildContext context, WidgetRef ref) {
    final AsyncValue<AccordPublication> accord = ref.watch(
      accordPublicationProvider,
    );
    if (accord.hasError && accord.error is CapaciteIndisponible) return null;
    final AccordPublication? lu = accord.hasError ? null : accord.value;
    return LigneRubrique(
      cle: publicationKey,
      icone: AppIcons.image,
      libelle: t.candidatsFlux.publication.titre,
      valeur: lu == null
          ? null
          : lu.enCours
          ? t.enseignant.profil.publicationDonnee
          : t.enseignant.profil.publicationNonDonnee,
      legende: accord.hasError
          ? t.candidatsFlux.publication.lectureEchec
          : null,
      onPress: () => _ouvrirSousPage(
        context,
        titre: t.candidatsFlux.publication.titre,
        corps: const CarteAccordPublication(retirable: true),
      ),
    );
  }

  /// Le resume de l'identite professionnelle : le pays, sinon rien.
  static String? _resumeIdentite(ProfilEnseignant profil) {
    final String? pays = profil.pays?.trim();
    return pays == null || pays.isEmpty ? null : pays;
  }
}

/// Les quatre valeurs d'`AccountStatus`, plus le cas illisible.
///
/// **Aucun repli sur « actif ».** Un statut absent se dit absent.
(String, String, TonEtat) _direStatut(AccountStatus? statut) =>
    switch (statut) {
      AccountStatus.active => (
        t.enseignant.profil.compteValide,
        t.enseignant.profil.statutValideDetail,
        TonEtat.succes,
      ),
      AccountStatus.provisionalActive => (
        t.enseignant.profil.statutProvisoire,
        t.enseignant.profil.statutProvisoireDetail,
        TonEtat.avertissement,
      ),
      AccountStatus.pendingKyc => (
        t.enseignant.profil.statutEnAttente,
        t.enseignant.profil.statutEnAttenteDetail,
        TonEtat.neutre,
      ),
      AccountStatus.disabled => (
        t.enseignant.profil.statutSuspendu,
        t.enseignant.profil.statutSuspenduDetail,
        TonEtat.alerte,
      ),
      null => (
        t.enseignant.profil.statutInconnu,
        t.enseignant.profil.statutInconnuDetail,
        TonEtat.neutre,
      ),
    };

/// Ouvre le detail d'une ligne dans sa propre page. La page vit dans la route
/// du navigateur, au-dessus d'un eventuel ProviderScope imbrique (la
/// demonstration) : on lui passe le conteneur de l'ecran.
void _ouvrirSousPage(
  BuildContext context, {
  required String titre,
  required Widget corps,
}) {
  final ProviderContainer conteneur = ProviderScope.containerOf(context);
  unawaited(
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext contexte) => UncontrolledProviderScope(
          container: conteneur,
          child: PageShell(
            titre: titre,
            onRetour: () => Navigator.of(contexte).pop(),
            child: corps,
          ),
        ),
      ),
    ),
  );
}

/// La page « Identité professionnelle » : pays, langues, fuseau, plafond.
class _IdentiteProfessionnelle extends ConsumerWidget {
  const _IdentiteProfessionnelle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProfilEnseignant?> lecture = ref.watch(
      profilEnseignantProvider,
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return switch (lecture) {
      AsyncValue<ProfilEnseignant?>(
        hasValue: true,
        value: final ProfilEnseignant lu,
      ) =>
        _Declaration(profil: lu, horsLigne: horsLigne),
      AsyncValue<ProfilEnseignant?>(hasValue: true) => EmptyState(
        message: t.enseignant.profil.vide,
        invitation: t.enseignant.profil.videDetail,
        icone: AppIcons.profil,
        registre: RegistreVide.subi,
      ),
      AsyncValue<ProfilEnseignant?>(hasError: true) => EmptyState(
        message: t.enseignant.profil.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(profilEnseignantProvider),
      ),
      _ => const Skeleton.liste(lignes: 4),
    };
  }
}

/// Ce que l'enseignant declare, et qu'il peut corriger.
///
/// Deux lignes editables, pas trois. `country` est du texte libre en base et
/// `languages` porte des codes de `langues_cours` (CAND-Q15, lot langue), mais
/// l'ecran les fait **choisir** (K-57, FORM-L8) : le pays dans une liste
/// preselectionnee d'apres le fuseau, les langues parmi celles que l'academie
/// propose (`referentielLanguesProvider`), le clavier seulement en dernier
/// recours (« Autre »). Les langues s'affichent par leur nom, jamais par leur
/// code. `timezone_iana`, lui, demande un libelle IANA valide -- la fonction SQL le
/// verifie et refuse le reste -- et aucun inventaire de fuseaux n'est tranche
/// dans le produit : il reste donc en lecture, et la demande est ecrite dans
/// `CONTRACT_REQUEST_E.md`. Un champ qui refuserait une saisie que l'enseignant
/// ne peut pas deviner serait pire qu'une lecture assumee.
class _Declaration extends ConsumerStatefulWidget {
  const _Declaration({required this.profil, required this.horsLigne});

  final ProfilEnseignant profil;
  final bool horsLigne;

  @override
  ConsumerState<_Declaration> createState() => _DeclarationState();
}

class _DeclarationState extends ConsumerState<_Declaration> {
  String? _message;

  /// Ouvre une feuille de choix, puis ecrit la reponse et relit le profil.
  ///
  /// Pays et langues se **choisissent** (K-57, FORM-L8) : la feuille rend la
  /// valeur retenue, ou `null` si l'enseignant la referme sans enregistrer.
  Future<void> _editer<T extends Object>({
    required String titre,
    required Widget Function() feuille,
    required Future<void> Function(T choix) ecrire,
  }) async {
    // La feuille vit dans la route du navigateur, au-dessus d'un eventuel
    // ProviderScope imbrique (la demonstration) : on lui passe le conteneur
    // de l'ecran, comme pour la photo publique.
    final ProviderContainer conteneur = ProviderScope.containerOf(context);
    final T? choix = await AppBottomSheet.ouvrir<T>(
      context,
      titre: titre,
      constructeur: (BuildContext _) =>
          UncontrolledProviderScope(container: conteneur, child: feuille()),
    );
    if (choix == null || !mounted) {
      return;
    }
    try {
      await ecrire(choix);
      if (!mounted) {
        return;
      }
      // Le faux comme la base relisent ce qui a ete ecrit : l'ecran n'a aucun
      // etat local de profil, il reaffiche ce que la lecture rend.
      ref.invalidate(profilEnseignantProvider);
      setState(() => _message = t.enseignant.profil.enregistre);
    } on Object {
      if (mounted) {
        setState(() => _message = t.enseignant.profil.editionErreur);
      }
    }
  }

  /// Le service se lit au moment du geste, jamais pendant `build` : le lire au
  /// montage construirait le client Supabase pour un ecran qu'on ne fait que
  /// consulter.
  ServiceDeclarationEnseignant get _service =>
      ref.read(serviceDeclarationProvider);

  /// FUSEAU-IDENTITE-PRO : la feuille du fuseau ecrit elle-meme (le refus du
  /// serveur s'y dit) ; ici, seulement la confirmation.
  Future<void> _reglerFuseau(String? pays) async {
    final bool fait = await ouvrirFeuilleFuseau(context, ref, pays: pays);
    if (fait && mounted) {
      setState(() => _message = t.enseignant.profil.enregistre);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final ProfilEnseignant profil = widget.profil;
    // FUSEAU-IDENTITE-PRO (garde-cap, 12/11/2026) : le fuseau du profil, lu
    // par `mon_horloge` (sans repli sur Paris), jamais par `mon_fuseau`.
    final AsyncValue<MonHorloge?> horloge = ref.watch(monHorlogeProvider);
    final String? fuseauProfil = horloge.value?.moi?.fuseau;
    final _LanguesLues langues = _LanguesLues.depuis(
      profil.langues,
      ref.watch(referentielLanguesProvider),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.horsLigne) ...<Widget>[
          Text(t.enseignant.profil.horsLigne, style: textes.bodySmall),
          Ecart.vSm,
        ],
        // Lignes groupees, chaque ligne entiere cliquable quand elle s'edite
        // (UX_REVIEW_04 ligne ENS-05, cible d'au moins 48).
        GroupeReglages(
          titre: t.enseignant.profil.identite,
          lignes: <LigneRubrique>[
            LigneRubrique(
              libelle: t.enseignant.profil.pays,
              valeur: profil.pays ?? t.enseignant.profil.nonRenseigne,
              icone: AppIcons.foyer,
              // Un bouton qui ne peut pas aboutir n'est pas rendu : hors
              // ligne, la ligne redevient une lecture et la phrase l'explique.
              onPress: widget.horsLigne
                  ? null
                  : () => unawaited(
                      _editer<String>(
                        titre: t.enseignant.profil.modifierPays,
                        // Le fuseau deja lu preselectionne le pays ; tant
                        // qu'il n'est pas la, la liste reste dans son ordre.
                        feuille: () => FeuillePays(
                          paysDeclare: profil.pays,
                          fuseau: fuseauProfil,
                        ),
                        ecrire: (String pays) => _service.declarer(pays: pays),
                      ),
                    ),
            ),
            LigneRubrique(
              libelle: t.enseignant.profil.langues,
              valeur: langues.valeur,
              // Le referentiel n'est pas encore lu : la ligne montre sa forme
              // de chargement, jamais les codes bruts.
              marque: langues.enChargement
                  ? const SizedBox(
                      width: AppSpacing.respiration * 2,
                      child: Skeleton(hauteur: AppSpacing.md),
                    )
                  : null,
              icone: AppIcons.cours,
              onPress: widget.horsLigne
                  ? null
                  : () => unawaited(
                      _editer<List<String>>(
                        titre: t.enseignant.profil.modifierLangues,
                        feuille: () =>
                            FeuilleLangues(declarees: profil.langues),
                        ecrire: (List<String> choisies) =>
                            _service.declarer(langues: choisies),
                      ),
                    ),
            ),
            // FUSEAU-IDENTITE-PRO : l'enseignant regle lui-meme son fuseau
            // (`maj_profil_enseignant`, p_timezone). La valeur est celle du
            // serveur, « Riyad · UTC+3 » ; sans fuseau, « Non renseigne » ; lecture
            // en echec, « Heure de cet appareil » (les heures retombent sur lui).
            LigneRubrique(
              cle: cleLigneFuseau,
              libelle: t.enseignant.profil.fuseau,
              legende: t.enseignant.profil.fuseauDetail,
              valeur: switch (horloge) {
                AsyncValue<MonHorloge?>(hasValue: true, :final value) =>
                  fuseauDuProfilAffiche(value) ??
                      t.enseignant.profil.nonRenseigne,
                AsyncValue<MonHorloge?>(hasError: true) =>
                  t.enseignant.profil.fuseauAppareil,
                _ => t.enseignant.profil.nonRenseigne,
              },
              icone: AppIcons.horloge,
              onPress: widget.horsLigne
                  ? null
                  : () => unawaited(_reglerFuseau(profil.pays)),
            ),
            LigneRubrique(
              libelle: t.enseignant.profil.plafond,
              legende: t.enseignant.profil.plafondDetail,
              valeur: profil.plafondHeures == null
                  ? t.enseignant.profil.nonRenseigne
                  : LibellesGroupe.valeurSeule(
                      t.enseignant.profil.plafondValeur(
                        nombre: profil.plafondHeures!,
                      ),
                    ),
              icone: AppIcons.journee,
            ),
          ],
        ),
        LocalFeedback(message: _message),
      ],
    );
  }
}

/// Ce que la ligne « Langues » affiche, d'apres le profil et le referentiel.
///
/// Le profil porte des codes (`francais`) ; seul le referentiel des langues,
/// retirees comprises, les nomme (`nomLangueCours`). Tant qu'il n'est pas lu,
/// la ligne montre sa forme de chargement ; s'il est illisible (panne, hors
/// ligne sans lecture precedente), elle le dit. Dans aucun cas elle n'affiche
/// un code. Une lecture precedente reste affichee pendant qu'une nouvelle
/// echoue ou se fait.
@immutable
class _LanguesLues {
  const _LanguesLues({required this.valeur, required this.enChargement});

  factory _LanguesLues.depuis(
    List<String> declarees,
    AsyncValue<List<LangueCours>> referentiel,
  ) {
    final List<String> valeurs = <String>[
      for (final String v in declarees)
        if (v.trim().isNotEmpty) v,
    ];
    if (valeurs.isEmpty) {
      return _LanguesLues(
        valeur: t.enseignant.profil.nonRenseigne,
        enChargement: false,
      );
    }
    final List<LangueCours>? lues = referentiel.value;
    if (lues != null) {
      return _LanguesLues(
        valeur: <String>{
          for (final String v in valeurs) nomLangueCours(v, lues),
        }.join(', '),
        enChargement: false,
      );
    }
    if (referentiel.hasError) {
      return _LanguesLues(
        valeur: t.enseignant.profil.languesErreur,
        enChargement: false,
      );
    }
    return const _LanguesLues(valeur: null, enChargement: true);
  }

  /// Le texte de fin de ligne, ou `null` pendant le chargement.
  final String? valeur;

  /// Vrai tant que le referentiel n'est pas lu.
  final bool enChargement;
}

/// Le contrat et les accuses, en lecture seule et pour toujours.
class _Contrats extends ConsumerWidget {
  const _Contrats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Acceptation>> acceptations = ref.watch(
      acceptationsProvider,
    );
    return switch (acceptations) {
      AsyncValue<List<Acceptation>>(hasValue: true) =>
        acceptations.requireValue.isEmpty
            ? EmptyState(
                message: t.enseignant.profil.contratAucun,
                invitation: t.enseignant.profil.contratAucunDetail,
                icone: AppIcons.dossiers,
                registre: RegistreVide.subi,
              )
            : GroupeReglages(
                lignes: <LigneRubrique>[
                  for (final Acceptation lue in acceptations.requireValue)
                    LigneRubrique(
                      libelle: _libelle(lue.sorte),
                      legende: t.enseignant.profil.contratDetail(
                        version: lue.version,
                        date: _date(lue.accepteeLe),
                      ),
                      icone: AppIcons.dossiers,
                    ),
                ],
              ),
      AsyncValue<List<Acceptation>>(hasError: true) => EmptyState(
        message: t.enseignant.profil.contratErreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () => ref.invalidate(acceptationsProvider),
      ),
      _ => const Skeleton.liste(lignes: 2),
    };
  }

  String _libelle(SorteContrat sorte) => switch (sorte) {
    SorteContrat.contratEnseignant => t.enseignant.profil.contratEnseignant,
    SorteContrat.conditionsTuteur => t.enseignant.profil.contratConditions,
    SorteContrat.accuseEnregistrementControle =>
      t.enseignant.profil.contratAccuse,
    SorteContrat.codeConduiteEnseignant =>
      t.enseignant.profil.contratCodeConduite,
    SorteContrat.cadreReligieuxEnseignant => t.recrutement.portail.elementCadre,
  };

  String _date(DateTime quand) =>
      '${quand.day.toString().padLeft(2, '0')}/'
      '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
}
