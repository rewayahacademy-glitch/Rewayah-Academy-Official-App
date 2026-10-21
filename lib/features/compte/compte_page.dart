import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/mode_accessibilite.dart';
import '../../core/appairage/service_appairage.dart';
import '../../core/auth/service_auth.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_theme.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../paiements_recus/rubrique_recevoir_paiements.dart';
import '../salle_seance/libelles_salle_b.dart';
import 'espaces_compte.dart';
import 'ligne_matricule.dart';
import 'mes_donnees_page.dart';

/// Le portail commun du compte, accessible depuis tous les roles actifs.
///
/// Les donnees personnelles absentes de [SessionState] restent explicitement
/// inconnues : cet ecran ne fabrique ni nom, ni courriel, ni autorisation.
class ComptePage extends ConsumerWidget {
  /// Cree le portail du compte.
  const ComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionProvider);
    final _CompteProjection projection = _CompteProjection.depuis(session);
    // Le cumul d'espaces vient d'une projection explicite (CT-9, BR-1) ; par
    // defaut, un seul espace et la liste de lecture ci-dessous.
    final bool plusieursEspaces = ref.watch(
      espacesCompteProvider.select((EspacesCompte e) => e.plusieurs),
    );

    return PageShell(
      titre: t.compte.titre,
      entete: Text(t.compte.intro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppCard(
            dominante: true,
            entete: _EnteteCompte(projection: projection),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  projection.resume,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                // IMM-FRONT-1 : le matricule, pour tout role, sous le nom.
                if (projection.profileId case final String profileId)
                  LigneMatricule(profileId: profileId),
              ],
            ),
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.informations),
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.compte.profil,
                description: t.compte.profilDetail,
                icon: AppIcons.profil,
                onPress: () => context.push(Routes.compteProfil),
              ),
              SettingRow(
                title: t.compte.reglages,
                description: t.compte.reglagesDetail,
                icon: AppIcons.reglages,
                onPress: () => context.push(Routes.compteReglages),
              ),
              // BIBLIO-LECTURE : la Bibliotheque se rejoint depuis la navigation,
              // pas seulement par une adresse (eleve, tuteur, adulte eleve
              // autonome ; capacite de la session, jamais le role).
              if (projection.afficheBibliotheque)
                SettingRow(
                  title: t.tc.bibliotheque.titre,
                  description: t.tc.bibliotheque.detail.entreeDetail,
                  icon: AppIcons.bibliotheque,
                  onPress: () => context.push(Routes.tcBibliotheque),
                ),
              // Le Foyer est une destination du tuteur (seul role a qui la ligne
              // s'affiche) : on la rejoint par `go`, pour que la barre allume le
              // Foyer. Un `push` de `/compte/profils`, redirige vers le Foyer,
              // l'empilait dans la branche Compte (revue phase 0, routes D7).
              if (projection.afficheFoyer)
                SettingRow(
                  title: t.compte.profils,
                  description: t.compte.profilsDetail,
                  icon: AppIcons.foyer,
                  onPress: () => context.go(Routes.tuteurFoyer),
                ),
              // Minimisation (C8, CT-9) : le controle ne montre ni appareils ni
              // foyer, pas meme une ligne inerte.
              if (projection.afficheAppareils)
                SettingRow(
                  title: t.compte.appareils,
                  description: t.compte.appareilsDetail,
                  icon: AppIcons.appareil,
                  onPress: projection.afficheFoyer
                      ? () => context.push(Routes.tuteurFoyer)
                      : null,
                  enabled: projection.afficheFoyer,
                ),
              SettingRow(
                title: t.compte.confidentialite,
                description: t.compte.confidentialiteDetail,
                icon: AppIcons.controleQualite,
                enabled: false,
              ),
            ],
          ),
          // CPT-BEN-2 : « Recevoir mes paiements », selon la capacite du port.
          const RubriqueRecevoirPaiements(),
          // CPT-SUPPR-EXPORT : copie des donnees et suppression du compte,
          // selon la capacite du port.
          RubriqueMesDonnees(
            onOuvrir: () => context.push(Routes.compteMesDonnees),
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.espaces),
          Text(t.compte.espacesDetail),
          Ecart.vSm,
          // Plusieurs espaces (Enseignant ou Admin, et Controle) : le
          // selecteur, le meme que celui du raccourci d'en-tete (C6).
          if (plusieursEspaces)
            const SelecteurEspaces()
          else
            CarteLignes(
              lignes: <Widget>[
                for (final _EspaceCompte espace in projection.espaces)
                  SettingRow(
                    key: ValueKey<String>(espace.code),
                    title: espace.libelle,
                    description: espace.detail,
                    value: t.compte.habilitation,
                    icon: espace.icone,
                    enabled: false,
                  ),
              ],
            ),
          Ecart.vSection,
          SettingRow(
            title: t.compte.deconnexion,
            description: t.compte.deconnexionDetail,
            icon: AppIcons.sortie,
            onPress: () =>
                unawaited(ref.read(serviceAuthProvider).deconnexion()),
          ),
        ],
      ),
    );
  }
}

/// Profil de la personne connectee, sans edition locale trompeuse.
class ProfilPersonnelPage extends ConsumerWidget {
  /// Cree la page de profil.
  const ProfilPersonnelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _CompteProjection projection = _CompteProjection.depuis(
      ref.watch(sessionProvider),
    );

    return PageShell(
      titre: t.compte.profil,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppCard(
            dominante: true,
            child: _EnteteCompte(projection: projection),
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.informations),
          CarteLignes(
            lignes: <Widget>[
              _LigneLecture(
                titre: t.compte.identifiant,
                valeur: projection.profileId ?? t.compte.nonDisponible,
                icon: AppIcons.profil,
              ),
              _LigneLecture(
                titre: t.compte.contact,
                valeur: t.compte.nonDisponible,
                detail: t.compte.contactDetail,
                icon: AppIcons.profil,
              ),
              _LigneLecture(
                titre: t.compte.langue,
                valeur: t.compte.francais,
                icon: AppIcons.reglages,
              ),
              _LigneLecture(
                titre: t.compte.fuseau,
                valeur: t.compte.nonDisponible,
                icon: AppIcons.reglages,
              ),
            ],
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.academie),
          CarteLignes(
            lignes: <Widget>[
              for (final _EspaceCompte espace in projection.espaces)
                _LigneLecture(
                  key: ValueKey<String>('profile-${espace.code}'),
                  titre: espace.libelle,
                  valeur: t.compte.habilitation,
                  detail: espace.detail,
                  icon: espace.icone,
                ),
            ],
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.securite),
          CarteLignes(
            lignes: <Widget>[
              _LigneLecture(
                titre: t.compte.statut,
                valeur: projection.statut,
                icon: AppIcons.controleQualite,
              ),
              if (projection.afficheFoyer)
                SettingRow(
                  title: t.compte.profils,
                  description: t.compte.profilsDetail,
                  icon: AppIcons.foyer,
                  onPress: () => context.go(Routes.tuteurFoyer),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preferences qui restent dans l'appareil et prennent effet immediatement.
class ReglagesComptePage extends ConsumerWidget {
  /// Cree les reglages locaux.
  const ReglagesComptePage({
    super.key,
    this.onRetour,
    this.titre,
    this.avant,
    this.apres,
  });

  /// Le disque retour de l'en-tete, pour une **tache focalisee** : sur
  /// telephone, la barre basse du tuteur s'efface sur ses preferences, et ce
  /// disque est alors sa sortie (manifeste visuel Tuteur V1 section 4.2
  /// point 5). Nul pour les autres roles, qui gardent leur barre.
  final VoidCallback? onRetour;

  /// MA-8 : le titre de la destination « Mon espace » du Mode
  /// Accessibilite ; nul (defaut) pour le titre commun des reglages.
  final String? titre;

  /// MA-8 : les blocs propres au Mode Accessibilite poses AVANT les
  /// reglages communs (identite, ligne « Mode Accessibilite ») ; nul partout
  /// ailleurs.
  final Widget? avant;

  /// MA-8 : le bloc pose APRES les reglages communs (aide) ; nul ailleurs.
  final Widget? apres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PreferencesLocales preferences = ref.watch(
      preferencesLocalesProvider,
    );
    // MA-8 : en Mode Accessibilite seulement, « Reduire les effets », qui
    // n'agit sur aucun ecran, n'est pas affiche (un interrupteur sans effet
    // n'est pas montre). Les autres roles et la presentation standard gardent
    // la page telle quelle.
    final bool modeAccessibilite = ref.watch(modeAccessibiliteActifProvider);
    final bool foyerDisponible = ref.watch(
      sessionProvider.select((SessionState session) => session.aUnFoyer),
    );
    final PreferencesLocalesControleur controleur = ref.read(
      preferencesLocalesProvider.notifier,
    );

    return PageShell(
      titre: titre ?? t.compte.reglagesTitre,
      onRetour: onRetour,
      entete: Text(t.compte.reglagesIntro),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (avant case final Widget bloc) ...<Widget>[bloc, Ecart.vSection],
          SectionHeader(titre: t.compte.apparence),
          const SelecteurTheme(),
          Ecart.vSection,
          SectionHeader(titre: t.compte.accessibilite),
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.compte.animations,
                description: t.compte.animationsDetail,
                icon: AppIcons.journee,
                controle: Switch.adaptive(
                  value: preferences.animationsReduites,
                  onChanged: controleur.animations,
                ),
              ),
              if (!modeAccessibilite)
                SettingRow(
                  title: t.compte.effets,
                  description: t.compte.effetsDetail,
                  icon: AppIcons.reglages,
                  controle: Switch.adaptive(
                    value: preferences.effetsReduits,
                    onChanged: controleur.effets,
                  ),
                ),
              // EN-KB (E19) : les raccourcis d'une seule lettre sont
              // desactivables (WCAG 2.1.4). Preference locale, sans serveur.
              SettingRow(
                key: const ValueKey<String>('reglage-raccourcis-salle'),
                title: LibellesSalleB.raccourcisTitre,
                description: LibellesSalleB.raccourcisDetail,
                icon: AppIcons.reglages,
                controle: Switch.adaptive(
                  value: preferences.raccourcisSalle,
                  onChanged: controleur.raccourcisSalle,
                ),
              ),
            ],
          ),
          Ecart.vLg,
          AppCard(
            surface: AppPalette.of(context).washAccent,
            child: Text(
              t.compte.lisibiliteDetail,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.langueRegion),
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.compte.francais,
                description: t.compte.francaisDetail,
                value: t.compte.actif,
                icon: AppIcons.reglages,
                enabled: false,
              ),
              // MA-RC (MA7, K-42) : en Mode Accessibilite, les lignes
              // inactives (sans effet pour l'eleve) ne sont pas affichees ;
              // les rubriques et les droits restent les memes.
              if (!modeAccessibilite) ...<Widget>[
                SettingRow(
                  title: t.compte.arabe,
                  description: t.compte.arabeDetail,
                  value: t.compte.nonDisponible,
                  icon: AppIcons.reglages,
                  enabled: false,
                ),
                SettingRow(
                  title: t.compte.fuseau,
                  description: t.compte.fuseauDetail,
                  value: t.compte.nonDisponible,
                  icon: AppIcons.reglages,
                  enabled: false,
                ),
              ],
            ],
          ),
          Ecart.vSection,
          SectionHeader(titre: t.compte.notifications),
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.compte.notificationsCours,
                description: t.compte.notificationsCoursDetail,
                icon: AppIcons.cours,
                controle: Switch.adaptive(
                  value: preferences.notificationsCours,
                  onChanged: controleur.notificationsCours,
                ),
              ),
              if (!modeAccessibilite)
                SettingRow(
                  title: t.compte.notificationsFoyer,
                  description: t.compte.notificationsFoyerDetail,
                  icon: AppIcons.foyer,
                  controle: Switch.adaptive(
                    value: preferences.notificationsFoyer,
                    onChanged: controleur.notificationsFoyer,
                  ),
                ),
            ],
          ),
          Text(t.compte.notificationsEtat),
          Ecart.vSection,
          SectionHeader(titre: t.compte.coursDonnees),
          CarteLignes(
            lignes: <Widget>[
              SettingRow(
                title: t.compte.economieDonnees,
                description: t.compte.economieDonneesDetail,
                icon: AppIcons.horsLigne,
                controle: Switch.adaptive(
                  value: preferences.economieDonnees,
                  onChanged: controleur.economieDonnees,
                ),
              ),
              SettingRow(
                title: t.compte.lectureGrande,
                description: t.compte.lectureGrandeDetail,
                icon: AppIcons.coran,
                controle: Switch.adaptive(
                  value: preferences.lectureGrande,
                  onChanged: controleur.lectureGrande,
                ),
              ),
            ],
          ),
          // MA-GR-1 : l'ecart de section n'accompagne le bloc appareils et
          // confidentialite que s'il est affiche ; masque (Mode
          // Accessibilite), un seul ecart reste avant l'aide.
          if (!modeAccessibilite || foyerDisponible) ...<Widget>[
            Ecart.vSection,
            CarteLignes(
              lignes: <Widget>[
                SettingRow(
                  title: t.compte.appareils,
                  description: t.compte.appareilsDetail,
                  icon: AppIcons.appareil,
                  onPress: foyerDisponible
                      ? () => context.push(Routes.tuteurFoyer)
                      : null,
                  enabled: foyerDisponible,
                ),
                if (!modeAccessibilite)
                  SettingRow(
                    title: t.compte.confidentialite,
                    description: t.compte.confidentialiteDetail,
                    icon: AppIcons.controleQualite,
                    enabled: false,
                  ),
              ],
            ),
          ],
          if (apres case final Widget bloc) ...<Widget>[Ecart.vSection, bloc],
        ],
      ),
    );
  }
}

/// Profils enfants visibles par un tuteur ou un adulte autonome.
class ProfilsComptePage extends ConsumerWidget {
  /// Cree la liste des profils du foyer.
  const ProfilsComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EleveDuFoyer>> profils = ref.watch(
      elevesDuFoyerProvider,
    );

    return PageShell(
      titre: t.compte.profilsTitre,
      entete: Text(t.compte.profilsIntro),
      child: profils.when(
        loading: () => const Skeleton.liste(differe: false),
        error: (Object _, StackTrace _) => EmptyState(
          message: t.compte.erreurProfils,
          invitation: t.compte.reessayer,
          icone: AppIcons.avertissement,
          libelleAction: t.compte.reessayer,
          onAction: () => ref.invalidate(elevesDuFoyerProvider),
        ),
        data: (List<EleveDuFoyer> enfants) => enfants.isEmpty
            ? EmptyState(
                message: t.compte.aucunProfil,
                invitation: t.compte.aucunProfilDetail,
                icone: AppIcons.foyer,
                libelleAction: t.compte.ajouterEnfant,
                onAction: () => context.push(Routes.tuteurAjouterEnfant),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final EleveDuFoyer enfant in enfants)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: AppCard(
                        key: ValueKey<String>(enfant.id),
                        onPress: () => context.push(
                          Routes.compteProfilEnfantPour(enfant.id),
                        ),
                        libelleSemantique: t.compte.ouvrirProfil,
                        child: _EnfantResume(enfant: enfant),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Detail d'un profil enfant, dans le perimetre de gestion du tuteur.
class ProfilEnfantPage extends ConsumerWidget {
  /// Cree le detail d'enfant.
  const ProfilEnfantPage({required this.profilId, super.key});

  /// Identifiant immuable de la route.
  final String profilId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<EleveDuFoyer>> profils = ref.watch(
      elevesDuFoyerProvider,
    );

    return PageShell(
      titre: t.compte.profilEnfant(dePrenom: deDevant(t.compte.nonDisponible)),
      child: profils.when(
        loading: () => const Skeleton.liste(differe: false),
        error: (Object _, StackTrace _) => EmptyState(
          message: t.compte.erreurProfils,
          invitation: t.compte.reessayer,
          icone: AppIcons.avertissement,
          libelleAction: t.compte.reessayer,
          onAction: () => ref.invalidate(elevesDuFoyerProvider),
        ),
        data: (List<EleveDuFoyer> enfants) {
          EleveDuFoyer? enfant;
          for (final EleveDuFoyer profil in enfants) {
            if (profil.id == profilId) {
              enfant = profil;
              break;
            }
          }
          if (enfant == null) {
            return EmptyState(
              message: t.compte.aucunProfil,
              invitation: t.compte.aucunProfilDetail,
              icone: AppIcons.foyer,
              registre: RegistreVide.subi,
            );
          }
          return _DetailEnfant(enfant: enfant);
        },
      ),
    );
  }
}

class _EnteteCompte extends StatelessWidget {
  const _EnteteCompte({required this.projection});

  final _CompteProjection projection;

  @override
  Widget build(BuildContext context) {
    // AVATAR-1 : couple avatar + nom du composant partage, nom et une ligne de
    // role (le statut). L'identifiant du profil a sa propre ligne plus bas.
    return AvatarNom.enLigne(
      prenom: projection.libelleRole,
      role: projection.statut,
      diametre: AppAvatar.grand,
      ecart: AppSpacing.xl,
      styleNom: Theme.of(context).textTheme.headlineSmall,
      styleRole: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _LigneLecture extends StatelessWidget {
  const _LigneLecture({
    required this.titre,
    required this.valeur,
    required this.icon,
    this.detail,
    super.key,
  });

  final String titre;
  final String valeur;
  final String? detail;
  final AppIcon icon;

  @override
  Widget build(BuildContext context) => SettingRow(
    title: titre,
    description: detail,
    value: valeur,
    icon: icon,
    enabled: false,
  );
}

class _EnfantResume extends StatelessWidget {
  const _EnfantResume({required this.enfant});

  final EleveDuFoyer enfant;

  @override
  // AVATAR-1 : couple du composant partage, nom centre sur le cercle. Les deux
  // lignes d'origine sont gardees (identifiant immuable, mode) : l'identifiant
  // est une donnee que le tuteur lit ici, la fiche AVATAR-1 ne l'a pas retiree.
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return AvatarNom.enLigne(
      prenom: enfant.prenom,
      ecart: AppSpacing.xl,
      styleNom: textes.titleLarge,
      roleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.compte.identifiantEnfant(identifiant: enfant.identifiantImmuable),
            style: textes.bodyMedium,
          ),
          Ecart.vXs,
          Text(
            enfant.mode == InterfaceMode.enfant
                ? t.compte.modeEnfant
                : t.compte.modeStandard,
            style: textes.bodyMedium,
          ),
        ],
      ),
      fin: Icon(AppIcons.chevron.repos),
    );
  }
}

class _DetailEnfant extends StatelessWidget {
  const _DetailEnfant({required this.enfant});

  final EleveDuFoyer enfant;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppCard(
        dominante: true,
        child: AvatarNom.enLigne(
          prenom: enfant.prenom,
          diametre: AppAvatar.grand,
          ecart: AppSpacing.xl,
          styleNom: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      Ecart.vSection,
      SectionHeader(titre: t.compte.informations),
      CarteLignes(
        lignes: <Widget>[
          _LigneLecture(
            titre: t.compte.identifiant,
            valeur: enfant.identifiantImmuable,
            icon: AppIcons.profil,
          ),
          _LigneLecture(
            titre: t.compte.modeEnfant,
            valeur: enfant.mode == InterfaceMode.enfant
                ? t.compte.modeEnfant
                : t.compte.modeStandard,
            icon: AppIcons.coran,
          ),
          _LigneLecture(
            titre: t.compte.cameraLabel,
            valeur: enfant.camera == CameraPolicy.allowed
                ? t.compte.cameraAutorisee
                : t.compte.cameraInterdite,
            icon: AppIcons.camera,
          ),
          _LigneLecture(
            titre: t.compte.statut,
            valeur: enfant.finAcces == null
                ? t.compte.accesSansFin
                : t.compte.accesJusqua(date: _dateCourte(enfant.finAcces!)),
            icon: AppIcons.controleQualite,
          ),
        ],
      ),
      Ecart.vSection,
      SettingRow(
        title: t.compte.reglages,
        description: t.compte.reglagesDetail,
        icon: AppIcons.reglages,
        onPress: () => context.push(Routes.ficheElevePour(enfant.id)),
      ),
    ],
  );

  String _dateCourte(DateTime date) =>
      date.toLocal().toIso8601String().split('T').first;
}

class _CompteProjection {
  const _CompteProjection({
    required this.libelleRole,
    required this.resume,
    required this.statut,
    required this.espaces,
    required this.afficheFoyer,
    required this.afficheAppareils,
    required this.afficheBibliotheque,
    this.profileId,
  });

  factory _CompteProjection.depuis(SessionState session) {
    final AppRole role = session.role ?? AppRole.student;
    final String libelleRole = _libelleRole(role);
    return _CompteProjection(
      libelleRole: libelleRole,
      resume: _detailRole(role),
      statut: switch (session.accountStatus) {
        AccountStatus.active => t.compte.statutActif,
        AccountStatus.provisionalActive => t.compte.statutProvisoire,
        _ => t.compte.nonDisponible,
      },
      espaces: _espacesPour(role),
      afficheFoyer: session.aUnFoyer,
      afficheAppareils: session.peutGererAppareils,
      afficheBibliotheque: session.peutOuvrirBibliotheque,
      profileId: session.profileId,
    );
  }

  final String libelleRole;
  final String resume;
  final String statut;
  final List<_EspaceCompte> espaces;
  final bool afficheFoyer;
  final bool afficheAppareils;

  /// BIBLIO-LECTURE : l'entree de la Bibliotheque, pour qui peut l'ouvrir.
  final bool afficheBibliotheque;
  final String? profileId;
}

class _EspaceCompte {
  const _EspaceCompte({
    required this.code,
    required this.libelle,
    required this.detail,
    required this.icone,
  });

  final String code;
  final String libelle;
  final String detail;
  final AppIcon icone;
}

String _libelleRole(AppRole role) => switch (role) {
  AppRole.admin => t.compte.roles.admin,
  AppRole.accountant => t.compte.roles.accountant,
  AppRole.controller => t.compte.roles.controller,
  AppRole.teacher => t.compte.roles.teacher,
  AppRole.guardian => t.compte.roles.guardian,
  AppRole.student => t.compte.roles.student,
};

String _detailRole(AppRole role) => switch (role) {
  AppRole.admin => t.compte.roleDetail.admin,
  AppRole.accountant => t.compte.roleDetail.accountant,
  AppRole.controller => t.compte.roleDetail.controller,
  AppRole.teacher => t.compte.roleDetail.teacher,
  AppRole.guardian => t.compte.roleDetail.guardian,
  AppRole.student => t.compte.roleDetail.student,
};

List<_EspaceCompte> _espacesPour(AppRole role) {
  _EspaceCompte espace(
    String code,
    String libelle,
    String detail,
    AppIcon icon,
  ) => _EspaceCompte(code: code, libelle: libelle, detail: detail, icone: icon);

  return switch (role) {
    // SessionState porte un seul role effectif. Ne pas deduire un cumul de
    // roles depuis le mot « administration » : une capacite supplementaire
    // vient d'une projection serveur explicite, `espacesCompteProvider`
    // (CT-9), qui remplace alors cette liste par `SelecteurEspaces`.
    AppRole.admin => <_EspaceCompte>[
      espace(
        'admin',
        t.compte.roles.admin,
        t.compte.roleDetail.admin,
        AppIcons.tableauDeBord,
      ),
    ],
    AppRole.accountant => <_EspaceCompte>[
      espace(
        'comptable',
        t.compte.roles.accountant,
        t.compte.roleDetail.accountant,
        AppIcons.dossiers,
      ),
    ],
    AppRole.controller => <_EspaceCompte>[
      espace(
        'controleur',
        t.compte.roles.controller,
        t.compte.roleDetail.controller,
        AppIcons.controleQualite,
      ),
    ],
    AppRole.teacher => <_EspaceCompte>[
      espace(
        'enseignant',
        t.compte.roles.teacher,
        t.compte.roleDetail.teacher,
        AppIcons.journee,
      ),
    ],
    AppRole.guardian => <_EspaceCompte>[
      espace(
        'tuteur',
        t.compte.roles.guardian,
        t.compte.roleDetail.guardian,
        AppIcons.foyer,
      ),
    ],
    AppRole.student => <_EspaceCompte>[
      espace(
        'eleve',
        t.compte.roles.student,
        t.compte.roleDetail.student,
        AppIcons.coran,
      ),
    ],
  };
}
