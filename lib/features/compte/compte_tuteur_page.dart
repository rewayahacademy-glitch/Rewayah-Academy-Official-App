import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/identite/port_matricule.dart';
import '../../core/photos/photo_personne.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/session/deconnexion.dart';
import '../../core/session/session_controleur.dart';
import '../../core/session/session_state.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/entete_compte.dart';
import '../../core/widgets/groupe_preferences.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_compte.dart';
import '../../core/widgets/status_pill.dart';
import '../foyer/photo_eleve.dart';
import 'carte_rubriques.dart' show SurfaceCarte;
import 'donnees_compte.dart';
import 'ligne_matricule.dart';
import 'lignes_compte.dart';
import 'ma_photo.dart';
import 'mes_donnees_page.dart';

/// « Mon compte » du tuteur (`/tuteur/compte`), sur le gabarit unique du
/// Compte (PROFILS P2, garde-cap, 11/11/2026) : [PageCompte].
///
/// Dans l'ordre fixe : l'en-tete d'identite (photo qu'on touche pour la
/// changer, nom, role, matricule avec « Copier », statut) ; Mon espace (Mon
/// foyer, Creer mon profil eleve) ; Paiements (Acces des profils eleves,
/// Paiements et recus) ; Preferences **dans la page** (theme en ligne,
/// langue, notifications, accessibilite : plus d'engrenage) ; Compte et
/// securite (Informations personnelles, Methode de connexion, Visites des
/// parents, Mes donnees et suppression) ; Aide et informations ; puis
/// « Se deconnecter » (confirmation avant tout) et la version. Aucun medaillon.
///
/// Chaque ligne se lit sur une capacite servie, jamais sur un role.
class CompteTuteurPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CompteTuteurPage({super.key});

  /// La ligne « Paiements » de la section Paiements (PAIEMENTS-TUTEUR).
  static const Key paiementsKey = ValueKey<String>('compte-paiements');

  @override
  ConsumerState<CompteTuteurPage> createState() => _CompteTuteurPageState();
}

class _CompteTuteurPageState extends ConsumerState<CompteTuteurPage> {
  /// Le choix et l'envoi de sa photo, par la photo de l'en-tete.
  final EnvoiMaPhoto _envoiPhoto = EnvoiMaPhoto();

  /// Vrai quand la derniere deconnexion n'a pas abouti.
  bool _echecDeconnexion = false;

  @override
  void dispose() {
    _envoiPhoto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);
    final String? moi = ref.watch(
      sessionProvider.select((SessionState e) => e.profileId),
    );
    final AsyncValue<IdentiteTitulaire> lecture = ref.watch(
      identiteTitulaireProvider,
    );
    final IdentiteTitulaire? lue = lecture.hasValue && !lecture.hasError
        ? lecture.requireValue
        : null;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool peutPoserPhoto =
        ref.watch(peutPoserMaPhotoProvider).value ?? false;
    final bool pushAutorise =
        ref.watch(notificationsAutoriseesProvider).value ?? false;
    final String? matricule = moi == null
        ? null
        : ref.watch(matriculeProvider(moi)).value?.valeur;
    final AsyncValue<bool> profilPropre = ref.watch(
      profilEleveTitulaireExisteProvider,
    );
    final bool aSonProfil =
        profilPropre.hasValue &&
        !profilPropre.hasError &&
        profilPropre.requireValue;
    final AsyncValue<List<AccesBeneficiaire>> acces = ref.watch(
      accesFoyerProvider,
    );
    final LigneRubrique? aide = ligneAideCompte(ref);

    // Une lecture en echec se dit en echec (meme pendant une relance
    // automatique) : l'erreur passe avant le chargement.
    final AsyncValue<IdentiteCompte?> identite = lecture.hasError
        ? AsyncValue<IdentiteCompte?>.error(
            lecture.error!,
            lecture.stackTrace ?? StackTrace.empty,
          )
        : lue == null
        ? const AsyncValue<IdentiteCompte?>.loading()
        : AsyncValue<IdentiteCompte?>.data(
            IdentiteCompte(
              nom: nomComplet(lue) ?? t.compte.roles.guardian,
              role: nomComplet(lue) == null ? null : t.compte.roles.guardian,
              matricule: matricule,
              statut: statutAffiche(lue.statut)?.libelle,
            ),
          );

    return ValueListenableBuilder<EtatMaPhoto>(
      valueListenable: _envoiPhoto,
      builder: (BuildContext _, EtatMaPhoto etatPhoto, Widget? _) => PageCompte(
        identite: identite,
        onReessayer: () => ref.invalidate(identiteTitulaireProvider),
        onDeconnecter: _deconnecter,
        sousDeconnexion: _echecDeconnexion
            ? Semantics(
                liveRegion: true,
                child: Text(
                  t.compte.tuteur.deconnexion.echec,
                  textAlign: TextAlign.center,
                  style: AppPalette.of(context).inkAlert.applyTo(
                    Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                  ),
                ),
              )
            : null,
        photo: moi == null
            ? null
            : PhotoEleve(
                prenom: lue == null ? '' : (nomComplet(lue) ?? ''),
                cleAvatar: null,
                personneId: moi,
                diametre: AppAvatar.grand,
              ),
        onChangerPhoto:
            moi != null &&
                peutPoserPhoto &&
                !horsLigne &&
                etatPhoto.etape != EtapeMaPhoto.envoi
            ? () => unawaited(_envoiPhoto.choisir(ref, moi))
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
        sections: <SectionCompte, List<LigneRubrique>>{
          SectionCompte.monEspace: <LigneRubrique>[
            // Le Foyer est une destination : `go`, pour que la barre l'allume.
            LigneRubrique(
              icone: AppIcons.foyer,
              libelle: t.compte.profils,
              legende: t.compte.profilsDetail,
              onPress: () => aller(Routes.tuteurFoyer),
            ),
            // Le meme flux que le Foyer (`?pour=moi`), jamais une copie ;
            // masque quand le profil existe deja.
            if (!aSonProfil)
              LigneRubrique(
                icone: AppIcons.ajouter,
                libelle: t.compte.tuteur.foyer.creerMonProfil,
                onPress: () => aller(Routes.tuteurAjouterPourMoi),
              ),
          ],
          SectionCompte.paiements: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.attente,
              libelle: t.compte.tuteur.acces.ligne,
              valeur: _valeurAcces(acces),
              onPress: () => aller(Routes.compteTuteurSousPage('acces')),
            ),
            // PAIEMENTS-TUTEUR (garde-cap, 12/11/2026) : l'historique des
            // paiements du foyer ; « Paiements », jamais « et recus ». Une
            // capacite, pas un role : absente sans source.
            if (ref.watch(paiementsFoyerOuvertsProvider))
              LigneRubrique(
                cle: CompteTuteurPage.paiementsKey,
                icone: AppIcons.paiements,
                libelle: t.compte.tuteur.pagePaiements.titre,
                onPress: () => aller(Routes.compteTuteurSousPage('paiements')),
              ),
          ],
          SectionCompte.compteSecurite: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.profil,
              libelle: t.compte.tuteur.informations.titre,
              onPress: () => aller(Routes.compteTuteurSousPage('informations')),
            ),
            LigneRubrique(
              icone: AppIcons.verrou,
              libelle: t.compte.tuteur.securite.methode,
              valeur: lue == null
                  ? null
                  : valeurConnexion(lue.methodeConnexion),
              onPress: () => aller(Routes.compteTuteurSousPage('securite')),
            ),
            LigneRubrique(
              icone: AppIcons.controleQualite,
              libelle: t.compte.tuteur.securite.consentements,
              onPress: () => aller(Routes.tuteurCompteConsentements),
            ),
            if (ref.watch(mesDonneesDisponiblesProvider))
              LigneRubrique(
                cle: RubriqueMesDonnees.ligneKey,
                icone: AppIcons.dossiers,
                libelle: t.compte.donnees.ligne,
                legende: t.compte.donnees.ligneDetail,
                onPress: () =>
                    aller(Routes.compteTuteurSousPage('mes-donnees')),
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

  /// La deconnexion, apres la confirmation de la page. Une session de
  /// demonstration se ferme localement ; un echec est dit, jamais tu.
  Future<void> _deconnecter() async {
    if (ref.read(sessionProvider.notifier).fermerDemo()) return;
    setState(() => _echecDeconnexion = false);
    try {
      await seDeconnecter(context, ref);
    } on Object {
      if (mounted) setState(() => _echecDeconnexion = true);
    }
  }

  /// La valeur de la ligne des acces : « Expire » des qu'un acces a expire,
  /// « Actif » sinon ; rien tant que les acces ne sont pas lus.
  String? _valeurAcces(AsyncValue<List<AccesBeneficiaire>> acces) {
    if (!acces.hasValue || acces.hasError || acces.requireValue.isEmpty) {
      return null;
    }
    final bool unExpire = acces.requireValue.any(
      (AccesBeneficiaire a) => a.etatAffiche == EtatAccesAffiche.expire,
    );
    return unExpire
        ? t.compte.tuteur.acces.pastilleExpire
        : t.compte.tuteur.acces.pastilleActif;
  }
}

/// La carte d'identite du titulaire : initiales, nom, role, statut reel,
/// adresse de connexion et methode. Aucun telephone, aucune ville : le
/// tuteur n'en a pas en base (C08 section 3).
///
/// Publique pour que « Mon espace » de l'eleve adulte (EA-4) la reprenne
/// telle quelle (K-51) : il y passe son role (« Eleve adulte ») et sa photo
/// (`PhotoEleve`, K-44) ; sans eux, la carte du tuteur ne change pas.
class CarteIdentiteCompte extends StatelessWidget {
  /// Cree la carte.
  const CarteIdentiteCompte({
    required this.identite,
    required this.large,
    this.role,
    this.photo,
    this.pastilleEtatNormal = true,
    this.profileId,
    super.key,
  });

  /// Le profil dont le matricule se lit sous le nom ; `null` : aucune ligne.
  final String? profileId;

  /// Vrai (defaut, Compte du tuteur) : la pastille dit aussi l'etat normal
  /// (« Compte valide »). Faux (Mon espace de l'eleve adulte, E12) : la
  /// pastille n'apparait que pour une exception (« Profil a completer »).
  final bool pastilleEtatNormal;

  /// L'identite lue.
  final IdentiteTitulaire identite;

  /// Vrai sur une fenetre large : un portrait plus grand.
  final bool large;

  /// Le role affiche sous le nom ; « Tuteur » par defaut.
  final String? role;

  /// Le portrait, construit a son diametre ; les initiales par defaut.
  final Widget Function(double diametre)? photo;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? nom = nomComplet(identite);
    final double diametre = large ? AppAvatar.grand : AppAvatar.moyen;
    final ({String libelle, bool valide})? lu = statutAffiche(identite.statut);
    final ({String libelle, bool valide})? statut =
        lu != null && lu.valide && !pastilleEtatNormal ? null : lu;

    return SurfaceCarte(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // AVATAR-1 : couple avatar + nom du composant partage, nom et une
            // ligne de role ; la pastille d'etat se lit dessous.
            Semantics(
              header: true,
              child: AvatarNom.enLigne(
                prenom: nom ?? '',
                nom: nom ?? t.compte.tuteur.identite.nomInconnu,
                role: role ?? t.compte.roles.guardian,
                diametre: diametre,
                avatar: photo?.call(diametre),
                ecart: AppSpacing.lg,
                styleNom: palette.inkStrong.applyTo(
                  textes.titleLarge ?? const TextStyle(),
                ),
                styleRole: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            // IMM-FRONT-1 : le matricule sous le nom (le Compte le passe).
            if (profileId case final String id) LigneMatricule(profileId: id),
            if (statut != null) ...<Widget>[
              Ecart.vSm,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusPill(
                  libelle: statut.libelle,
                  ton: statut.valide ? TonEtat.succes : TonEtat.avertissement,
                ),
              ),
            ],
            Ecart.vLg,
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ExcludeSemantics(
                    child: IconTheme(
                      data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                      child: Icon(AppIcons.dossiers.repos),
                    ),
                  ),
                  Ecart.hMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Une adresse est un seul « mot » : elle se reduit
                        // au lieu d'etre coupee (Interface guidee, 390 ;
                        // capture EA-HL-DOUBLE-1).
                        TexteSansCoupure(
                          identite.courriel ??
                              t.compte.tuteur.identite.courrielAbsent,
                          style: palette.inkStrong.applyTo(
                            textes.bodyLarge ?? const TextStyle(),
                          ),
                        ),
                        Ecart.vXs,
                        Text(
                          phraseConnexion(identite.methodeConnexion),
                          style: palette.inkMuted.applyTo(
                            textes.bodySmall ?? const TextStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Se deconnecter » : une carte a part, en bas, rouge et centree
/// (maquettes V3), toujours precedee d'une confirmation. Une session de
/// demonstration se ferme localement (`fermerDemo`), sans appel reseau.
///
/// Publique pour que « Mon espace » de l'eleve adulte (EA-4) la reprenne
/// telle quelle, sans copie (K-51).
class CarteDeconnexion extends ConsumerStatefulWidget {
  /// Cree la carte.
  const CarteDeconnexion({super.key});

  @override
  ConsumerState<CarteDeconnexion> createState() => _CarteDeconnexionState();
}

class _CarteDeconnexionState extends ConsumerState<CarteDeconnexion> {
  bool _enCours = false;
  bool _echec = false;

  Future<void> _seDeconnecter() async {
    if (_enCours) {
      return;
    }
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.compte.tuteur.deconnexion.question,
      consequence: t.compte.tuteur.deconnexion.consequence,
      libelleConfirmer: t.compte.tuteur.deconnexion.confirmer,
    );
    if (!confirme || !mounted) {
      return;
    }
    if (ref.read(sessionProvider.notifier).fermerDemo()) {
      return;
    }
    setState(() {
      _enCours = true;
      _echec = false;
    });
    try {
      await seDeconnecter(context, ref);
    } on Object {
      if (mounted) {
        setState(() => _echec = true);
      }
    } finally {
      if (mounted) {
        setState(() => _enCours = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Une sortie n'est pas l'action principale : niveau destructif du core,
        // texte a l'encre d'alerte, centre (K-54, K-56).
        ActionPrincipale(
          libelle: t.compte.deconnexion,
          niveau: NiveauAction.destructive,
          enCours: _enCours,
          onPress: _enCours ? null : _seDeconnecter,
        ),
        if (_echec) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              t.compte.tuteur.deconnexion.echec,
              textAlign: TextAlign.center,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
