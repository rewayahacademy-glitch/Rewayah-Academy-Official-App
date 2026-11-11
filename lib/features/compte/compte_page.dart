import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/domain/enums.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/selecteur_langue.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/identite/port_matricule.dart';
import '../../core/photos/photo_personne.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_compte.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entete_compte.dart';
import '../../core/widgets/groupe_preferences.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_compte.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_theme.dart';
import '../../core/widgets/setting_row.dart';
import '../../core/widgets/skeleton.dart';
import '../foyer/photo_eleve.dart';
import '../paiements_recus/rubrique_recevoir_paiements.dart';
import '../salle_seance/libelles_salle_b.dart';
import 'espaces_compte.dart';
import 'lignes_compte.dart';
import 'ma_photo.dart';
import 'mes_donnees_page.dart';

// NAV-REFONTE : le prenom du Compte vit dans le core (cercle Compte de la
// barre) ; reexporte pour les ecrans et tests qui le lisaient ici.
export '../../core/widgets/avatar_compte.dart' show prenomDuCompteProvider;

/// Le portail commun du compte (eleve standard, controleur, comptable,
/// administration), compose dans le gabarit unique [PageCompte] (PROFILS P4,
/// pilote du 11/11/2026).
///
/// Les donnees personnelles absentes du serveur restent inconnues : cet ecran
/// ne fabrique ni nom, ni courriel, ni autorisation. Chaque ligne se lit sur
/// une capacite servie, jamais sur le role, et une ligne qui ne marche pas
/// n'est pas fournie (« 100 % operationnel », directeur, 11/11/2026).
class ComptePage extends ConsumerStatefulWidget {
  /// Cree le portail du compte.
  const ComptePage({super.key});

  @override
  ConsumerState<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends ConsumerState<ComptePage> {
  /// Le choix et l'envoi de sa photo, par la photo de l'en-tete.
  final EnvoiMaPhoto _envoiPhoto = EnvoiMaPhoto();

  @override
  void dispose() {
    _envoiPhoto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SessionState session = ref.watch(sessionProvider);
    final _CompteProjection projection = _CompteProjection.depuis(session);
    final String? id = projection.profileId;
    final bool plusieursEspaces = ref.watch(
      espacesCompteProvider.select((EspacesCompte e) => e.plusieurs),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool peutPoserPhoto =
        ref.watch(peutPoserMaPhotoProvider).value ?? false;
    final bool pushAutorise =
        ref.watch(notificationsAutoriseesProvider).value ?? false;

    // L'identite, tout de suite : le role tient lieu de nom tant que le
    // prenom (`profiles` par soi) n'est pas lu, ou s'il est vide, et n'est
    // alors pas repete dessous ; le prenom le remplace des qu'il arrive. Sa
    // lecture n'a pas d'etat d'erreur (`prenomDuCompteProvider`) : l'en-tete
    // n'attend rien. Le matricule, quand il est servi (IMM-FRONT-1).
    final String? matricule = id == null
        ? null
        : ref.watch(matriculeProvider(id)).value?.valeur;
    final String prenom = ref.watch(prenomDuCompteProvider).value?.trim() ?? '';
    final AsyncValue<IdentiteCompte?> identite =
        AsyncValue<IdentiteCompte?>.data(
          id == null
              ? null
              : IdentiteCompte(
                  nom: prenom.isEmpty ? projection.libelleRole : prenom,
                  role: prenom.isEmpty ? null : projection.libelleRole,
                  matricule: matricule,
                  statut: projection.statutConnu,
                ),
        );

    final LigneRubrique? recevoir = ligneRecevoirPaiements(context, ref);
    final Widget? avisRecevoir = avisRecevoirPaiements(context, ref);
    final LigneRubrique? aide = ligneAideCompte(ref);

    return ValueListenableBuilder<EtatMaPhoto>(
      valueListenable: _envoiPhoto,
      builder: (BuildContext _, EtatMaPhoto etatPhoto, Widget? _) => PageCompte(
        identite: identite,
        onDeconnecter: () async {
          await seDeconnecter(context, ref);
        },
        photo: id == null
            ? null
            : PhotoEleve(
                prenom: identite.value?.nom ?? projection.libelleRole,
                cleAvatar: null,
                personneId: id,
                diametre: AppAvatar.grand,
              ),
        // PHOTO-CAPACITE : la photo se touche pour la changer quand le serveur
        // le permet (`photo_adulte_moi()`), en ligne, hors envoi en cours.
        onChangerPhoto:
            id != null &&
                peutPoserPhoto &&
                !horsLigne &&
                etatPhoto.etape != EtapeMaPhoto.envoi
            ? () => unawaited(_envoiPhoto.choisir(ref, id))
            : null,
        piedEntete: peutPoserPhoto
            ? RetourMaPhoto(etat: etatPhoto, horsLigne: horsLigne)
            : null,
        preferences: GroupePreferences(
          langue: ligneLangueCompte(context),
          notifications: pushAutorise
              ? ligneNotificationsCompte(context)
              : null,
          accessibilite: ligneAccessibiliteCompte(context),
        ),
        avantLignes: <SectionCompte, List<Widget>>{
          // Plusieurs espaces (Enseignant ou Admin, et Controle) : le
          // selecteur, le meme que celui du raccourci d'en-tete (C6). Un seul
          // espace : rien, l'en-tete dit deja le role.
          if (plusieursEspaces)
            SectionCompte.monEspace: <Widget>[const SelecteurEspaces()],
          if (avisRecevoir != null)
            SectionCompte.paiements: <Widget>[avisRecevoir],
        },
        sections: <SectionCompte, List<LigneRubrique>>{
          SectionCompte.monEspace: <LigneRubrique>[
            // BIBLIO-LECTURE : pour qui peut ouvrir la Bibliotheque.
            if (projection.afficheBibliotheque)
              LigneRubrique(
                icone: AppIcons.bibliotheque,
                libelle: t.tc.bibliotheque.titre,
                legende: t.tc.bibliotheque.detail.entreeDetail,
                onPress: () => unawaited(context.push(Routes.tcBibliotheque)),
              ),
            // Le Foyer se rejoint par `go`, pour que la barre allume le
            // Foyer (revue phase 0, routes D7) ; seulement pour qui tient un
            // foyer (`aUnFoyer`, FOYER-ELEVE).
            if (projection.afficheFoyer)
              LigneRubrique(
                icone: AppIcons.foyer,
                libelle: t.compte.profils,
                legende: t.compte.profilsDetail,
                onPress: () => context.go(Routes.tuteurFoyer),
              ),
            if (projection.afficheAppareils && projection.afficheFoyer)
              LigneRubrique(
                icone: AppIcons.appareil,
                libelle: t.compte.appareils,
                legende: t.compte.appareilsDetail,
                onPress: () => unawaited(context.push(Routes.tuteurFoyer)),
              ),
          ],
          // CPT-BEN-2 : « Recevoir mes paiements », selon la capacite du port.
          SectionCompte.paiements: <LigneRubrique>[?recevoir],
          SectionCompte.compteSecurite: <LigneRubrique>[
            // MFA-DIRECTION : la double verification (capacite de la session).
            if (session.peutActiverDoubleVerification)
              LigneRubrique(
                cle: const ValueKey<String>('compte-securite'),
                icone: AppIcons.verrou,
                libelle: t.compte.securite,
                legende: t.compte.doubleVerification.rubriqueDetail,
                onPress: () => unawaited(context.push(Routes.compteSecurite)),
              ),
            // CPT-SUPPR-EXPORT : copie des donnees et suppression du compte,
            // selon la capacite du port.
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
          ],
        },
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
                valeur: nomLangueAffichee(),
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
    final bool foyerDisponible = ref.watch(
      sessionProvider.select((SessionState session) => session.aUnFoyer),
    );
    final bool notificationsAutorisees =
        ref.watch(notificationsAutoriseesProvider).value ?? false;
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
              // « Reduire les effets » coupe les lumieres (EffetsReduits,
              // garde-cap, 11/11/2026) : il agit, il est donc montre partout.
              SettingRow(
                key: const ValueKey<String>('reglage-effets'),
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
          // PROFILS P4 (garde-cap, 11/11/2026) : une seule langue, celle du
          // compte, pour l'interface ET les e-mails (`choisirLangueCompte`) ;
          // plus de ligne « Langue des e-mails » ni de fuseau « Non
          // disponible » (« 100 % operationnel », directeur, 11/11/2026).
          GroupeReglages(
            key: const ValueKey<String>('reglage-langue-compte'),
            lignes: <LigneRubrique>[ligneLangueCompte(context)],
          ),
          // Garde-cap (11/11/2026) : les vrais reglages push (PUSH-1), la meme
          // ligne que sur le Compte, a la place des interrupteurs locaux que
          // rien ne lisait ; seulement si le serveur les autorise.
          if (notificationsAutorisees) ...<Widget>[
            Ecart.vSection,
            GroupeReglages(
              key: const ValueKey<String>('reglage-notifications-push'),
              lignes: <LigneRubrique>[ligneNotificationsCompte(context)],
            ),
          ],
          // « Economie de donnees », que rien ne lisait, est retire
          // (garde-cap, 11/11/2026) ; la lecture en grand texte agit dans le
          // Coran de l'Interface guidee.
          Ecart.vSection,
          SectionHeader(titre: t.compte.coursDonnees),
          CarteLignes(
            lignes: <Widget>[
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
          // FOYER-ELEVE : seulement pour qui tient un foyer (`aUnFoyer`) ; la
          // confidentialite grisee (« Bientot disponible ») n'est plus montree
          // (« 100 % operationnel », directeur, 11/11/2026).
          if (foyerDisponible) ...<Widget>[
            Ecart.vSection,
            CarteLignes(
              lignes: <Widget>[
                SettingRow(
                  title: t.compte.appareils,
                  description: t.compte.appareilsDetail,
                  icon: AppIcons.appareil,
                  onPress: () => context.push(Routes.tuteurFoyer),
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

class _EnteteCompte extends ConsumerWidget {
  const _EnteteCompte({required this.projection});

  final _CompteProjection projection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AVATAR-1 : couple avatar + nom du composant partage, nom et une ligne de
    // role (le statut). L'identifiant du profil a sa propre ligne plus bas.
    final String? id = projection.profileId;
    // PHOTOS-2b (defaut R3 de PHOTOS-2a) : le prenom de la personne
    // (`profiles` par soi), jamais « Eleve » a sa place ; le libelle du role
    // reste seulement tant que le prenom n'est pas lu, ou s'il est vide.
    final String? prenomLu = ref.watch(prenomDuCompteProvider).value?.trim();
    final bool prenomConnu = prenomLu != null && prenomLu.isNotEmpty;
    final String prenom = prenomConnu ? prenomLu : projection.libelleRole;
    // Garde-cap (04/11/2026) : la ligne du dessous dit « {role} · {statut} »,
    // un repere pour un adulte a plusieurs roles et pour la direction ; le
    // role n'est pas repete quand il tient deja lieu de nom.
    final String ligneRole = prenomConnu
        ? LibellesGroupe.joindre(projection.libelleRole, projection.statut)
        : projection.statut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AvatarNom.enLigne(
          prenom: prenom,
          role: ligneRole,
          diametre: AppAvatar.grand,
          // PHOTOS-2a : sa photo, la meme partout ; « Choisir une photo »
          // dessous pour la poser ou la changer.
          avatar: id == null
              ? null
              : PhotoEleve(
                  prenom: prenom,
                  cleAvatar: null,
                  personneId: id,
                  diametre: AppAvatar.grand,
                ),
          ecart: AppSpacing.xl,
          styleNom: Theme.of(context).textTheme.headlineSmall,
          styleRole: Theme.of(context).textTheme.bodyMedium,
        ),
        if (id != null) ...<Widget>[Ecart.vMd, const LienMaPhoto()],
      ],
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
      // PHOTOS-2a : la photo de l'enfant, la meme partout.
      avatar: PhotoEleve(
        prenom: enfant.prenom,
        cleAvatar: null,
        personneId: enfant.id,
      ),
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
          avatar: PhotoEleve(
            prenom: enfant.prenom,
            cleAvatar: null,
            personneId: enfant.id,
            diametre: AppAvatar.grand,
          ),
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

  /// Le statut, seulement quand il est connu : jamais « Non disponible »
  /// dans l'en-tete du Compte (« 100 % operationnel »).
  String? get statutConnu => statut == t.compte.nonDisponible ? null : statut;
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

/// Le libelle d'un role, tel que l'en-tete du Compte le dit quand le prenom
/// n'est pas lu (reutilise par « Mon espace » du Mode Accessibilite).
String libelleRoleCompte(AppRole role) => _libelleRole(role);

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
