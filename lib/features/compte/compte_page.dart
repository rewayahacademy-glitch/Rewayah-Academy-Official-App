import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/identite/port_matricule.dart';
import '../../core/journal_sorties/port_journal_sorties.dart';
import '../../core/photos/photo_personne.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_compte.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/entete_compte.dart';
import '../../core/widgets/groupe_preferences.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_compte.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/selecteur_theme.dart';
import '../../core/widgets/setting_row.dart';
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

  /// La ligne « Aide et contact » de l'eleve.
  static const Key aideEleveKey = ValueKey<String>('compte-aide-eleve');

  /// HORS-SALLE-2 : la ligne de l'accord du journal des sorties.
  static const Key accordSortiesKey = ValueKey<String>('compte-accord-sorties');

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
            // HORS-SALLE-2 : l'eleve adulte autonome decide pour lui-meme du
            // journal des sorties ; seulement quand la direction l'a allume
            // (capacite servie par `accords_sorties`, jamais un role).
            if (ref.watch(accordSortiesProposeProvider))
              LigneRubrique(
                cle: ComptePage.accordSortiesKey,
                icone: AppIcons.attente,
                libelle: t.journalSorties.accord.ligne,
                legende: t.journalSorties.accord.ligneDetailAdulte,
                onPress: () => unawaited(context.push(Routes.compteSorties)),
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
            // L'eleve : « Aide et contact » ouvre sa page d'aide (garde-cap,
            // 11/11/2026) ; le canal s'y lit, il n'est pas repete ici.
            if (session.aUneAideEleve)
              LigneRubrique(
                cle: ComptePage.aideEleveKey,
                icone: AppIcons.lecon,
                libelle: t.compte.tuteur.aide.ligne,
                onPress: () => unawaited(context.push(Routes.eleveAide)),
              )
            else
              ?aide,
            ligneInformationsLegales(context),
          ],
        },
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
      // Hors du Compte quand « Ma classe » la porte (garde-cap, 11/11/2026).
      afficheBibliotheque:
          session.peutOuvrirBibliotheque && !session.bibliothequeDansMaClasse,
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
