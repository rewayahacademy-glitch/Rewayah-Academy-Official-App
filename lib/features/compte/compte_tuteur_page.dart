import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/service_auth.dart';
import '../../core/capacites/port_acces_foyer.dart';
import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/mouvement/apparition_douce.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/routes.dart';
import '../../core/session/session_controleur.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// « Mon compte » du tuteur, quatrieme destination de sa coquille
/// (`/tuteur/compte`, mandat Tuteur V1 sections 4 et 5, maquettes V3).
///
/// Le compte concerne le **titulaire** ; la fiche eleve concerne
/// l'apprentissage. Composition des maquettes : identite, puis sur bureau deux
/// colonnes (Acces et paiements, Connexion et securite | Informations
/// personnelles, Mon foyer, Aide et support), enfin la deconnexion, a part.
/// Sur telephone, la meme suite en une colonne. L'ordre de lecture et de
/// tabulation suit celui du mandat (colonne gauche, puis droite).
///
/// Chaque fonction a une seule place (carte des fonctions du lot E) :
/// l'engrenage ouvre les Preferences ; « Modifier » n'est pas rendu (aucune
/// ecriture pour le tuteur, DB-CPT-01) ; « Gerer les paiements », « Historique
/// et recus » et « Moyen de paiement » se fondent en une rubrique Paiements,
/// indisponible proprement (DB-CPT-03) ; « Appareils connectes » n'est pas
/// rendu (aucune liste de sessions, DB-CPT-02).
class CompteTuteurPage extends StatelessWidget {
  /// Cree la page.
  const CompteTuteurPage({super.key});

  @override
  Widget build(BuildContext context) => PageShell(
    titre: t.compte.titre,
    actionsEntete: <Widget>[
      BoutonEntete(
        icone: AppIcons.reglages,
        libelle: t.compte.tuteur.preferences,
        onPress: () => GoRouter.of(context).go(Routes.tuteurComptePreferences),
      ),
    ],
    child: const _Hub(),
  );
}

class _Hub extends ConsumerWidget {
  const _Hub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void aller(String chemin) => GoRouter.of(context).go(chemin);
    final bool large = AppGabarit.de(context).estLarge;
    final double ecart = large ? AppSpacing.lg : AppSpacing.md;
    final AsyncValue<IdentiteTitulaire> identite = ref.watch(
      identiteTitulaireProvider,
    );
    final IdentiteTitulaire? lue = identite.hasValue && !identite.hasError
        ? identite.requireValue
        : null;
    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);
    final String? ville = fuseau.hasValue && !fuseau.hasError
        ? villeDuFuseau(fuseau.requireValue)
        : null;
    final AsyncValue<bool> profilPropre = ref.watch(
      profilEleveTitulaireExisteProvider,
    );
    final bool aSonProfil =
        profilPropre.hasValue &&
        !profilPropre.hasError &&
        profilPropre.requireValue;

    final Widget carteIdentite = BlocAsynchrone<IdentiteTitulaire>(
      valeur: identite,
      squelette: const Skeleton(hauteur: AppSpacing.respiration * 2),
      onReessayer: () => ref.invalidate(identiteTitulaireProvider),
      construire: (IdentiteTitulaire valeur) =>
          CarteIdentiteCompte(identite: valeur, large: large),
    );

    final Widget acces = CarteRubriques(
      icone: AppIcons.finance,
      titre: t.compte.tuteur.acces.titre,
      resume: <String>[t.compte.tuteur.acces.resume],
      fin: _PastilleAcces(acces: ref.watch(accesFoyerProvider)),
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.attente,
          libelle: t.compte.tuteur.acces.ligne,
          onPress: () => aller(Routes.compteTuteurSousPage('acces')),
        ),
        // Une seule entree pour « Gerer les paiements », « Historique et
        // recus » et « Moyen de paiement » ; la valeur dit tout de suite
        // qu'aucun service n'existe (DB-CPT-03), la page l'explique.
        LigneRubrique(
          icone: AppIcons.fichierPdf,
          libelle: t.compte.tuteur.acces.paiements,
          valeur: t.compte.nonDisponible,
          onPress: () => aller(Routes.compteTuteurSousPage('paiements')),
        ),
      ],
    );

    final Widget securite = CarteRubriques(
      icone: AppIcons.controleQualite,
      titre: t.compte.tuteur.securite.titre,
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.verrou,
          libelle: t.compte.tuteur.securite.methode,
          valeur: lue == null ? null : valeurConnexion(lue.methodeConnexion),
          onPress: () => aller(Routes.compteTuteurSousPage('securite')),
        ),
        // Le consentement aux visites d'observation, revu a tout moment
        // depuis le Compte (A-3) : meme page que l'invite, route dediee.
        LigneRubrique(
          icone: AppIcons.controleQualite,
          libelle: t.consentement.titre,
          onPress: () => aller(Routes.tuteurCompteConsentements),
        ),
      ],
    );

    // Le nom et l'adresse sont deja sur la carte d'identite : le resume ne
    // les repete pas (une information, une place ; V3 section 8, point 11).
    final Widget informations = CarteRubriques(
      icone: AppIcons.profil,
      titre: t.compte.tuteur.informations.titre,
      resume: <String>[
        t.compte.tuteur.informations.resume,
        if (ville == null)
          t.compte.francais
        else
          t.compte.tuteur.informations.langueFuseau(ville: ville),
      ],
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.dossiers,
          libelle: t.compte.tuteur.informations.consulter,
          onPress: () => aller(Routes.compteTuteurSousPage('informations')),
        ),
      ],
    );

    final Widget foyer = CarteRubriques(
      icone: AppIcons.foyer,
      titre: t.compte.tuteur.foyer.titre,
      corps: _ResumeFoyer(profils: ref.watch(profilsElevesFoyerProvider)),
      lignes: <LigneRubrique>[
        // Le Foyer est une destination : on le rejoint par `go`, pour que la
        // barre allume le Foyer (revue phase 0, routes D7). Le libelle porte
        // la cle `compte.profils`, celle que lit le test du routeur.
        LigneRubrique(
          icone: AppIcons.foyer,
          libelle: t.compte.profils,
          onPress: () => aller(Routes.tuteurFoyer),
        ),
        // Le raccourci que le mandat prevoit aussi depuis le Compte : il ouvre
        // LE MEME flux que le Foyer (`?pour=moi`, ecran du lot B), jamais une
        // copie. Masque seulement quand le profil existe deja.
        if (!aSonProfil)
          LigneRubrique(
            icone: AppIcons.ajouter,
            libelle: t.compte.tuteur.foyer.creerMonProfil,
            onPress: () => aller(Routes.tuteurAjouterPourMoi),
          ),
      ],
    );

    final Widget aide = CarteRubriques(
      icone: AppIcons.lecon,
      titre: t.compte.tuteur.aide.titre,
      lignes: <LigneRubrique>[
        LigneRubrique(
          icone: AppIcons.lecon,
          libelle: t.compte.tuteur.aide.ligne,
          valeur: t.compte.nonDisponible,
          onPress: () => aller(Routes.compteTuteurSousPage('aide')),
        ),
        LigneRubrique(
          icone: AppIcons.journal,
          libelle: t.compte.tuteur.aide.legal,
          onPress: () =>
              aller(Routes.compteTuteurSousPage('informations-legales')),
        ),
      ],
    );

    Widget pile(List<Widget> cartes) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < cartes.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: ecart),
          ElementEchelonne(index: i, child: cartes[i]),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        // Deux colonnes des que la place le permet (maquette bureau), une
        // seule sinon : jamais la colonne mobile etiree.
        final bool deuxColonnes =
            contraintes.maxWidth >= AppGabarit.seuilEtendu;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            carteIdentite,
            SizedBox(height: ecart),
            if (deuxColonnes)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Proportions de la maquette bureau : la colonne gauche est
                  // un peu plus large (658 contre 598 px).
                  Expanded(flex: 11, child: pile(<Widget>[acces, securite])),
                  SizedBox(width: ecart),
                  Expanded(
                    flex: 10,
                    child: pile(<Widget>[informations, foyer, aide]),
                  ),
                ],
              )
            else
              pile(<Widget>[acces, securite, informations, foyer, aide]),
            SizedBox(height: ecart),
            const CarteDeconnexion(),
          ],
        );
      },
    );
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
    super.key,
  });

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
    final double diametre = large
        ? AppSpacing.section * 2
        : AppSpacing.respiration;
    final ({String libelle, bool valide})? statut = statutAffiche(
      identite.statut,
    );

    return SurfaceCarte(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                ExcludeSemantics(
                  child:
                      photo?.call(diametre) ??
                      AvatarTile(prenom: nom ?? '', diametre: diametre),
                ),
                Ecart.hLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          nom ?? t.compte.tuteur.identite.nomInconnu,
                          style: palette.inkStrong.applyTo(
                            textes.titleLarge ?? const TextStyle(),
                          ),
                        ),
                      ),
                      Ecart.vXs,
                      Text(
                        role ?? t.compte.roles.guardian,
                        style: palette.inkMuted.applyTo(
                          textes.bodyMedium ?? const TextStyle(),
                        ),
                      ),
                      if (statut != null) ...<Widget>[
                        Ecart.vSm,
                        StatusPill(
                          libelle: statut.libelle,
                          ton: statut.valide
                              ? TonEtat.succes
                              : TonEtat.avertissement,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
                        Text(
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

/// La pastille de la carte Acces : rendue seulement quand l'acces des profils
/// est lu. Un seul acces termine suffit a le dire ; aucune pastille pour un
/// foyer sans profil, en chargement ou en echec (la sous-page le dit).
class _PastilleAcces extends StatelessWidget {
  const _PastilleAcces({required this.acces});

  final AsyncValue<List<AccesBeneficiaire>> acces;

  @override
  Widget build(BuildContext context) {
    if (!acces.hasValue || acces.hasError || acces.requireValue.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool unExpire = acces.requireValue.any(
      (AccesBeneficiaire a) => a.etatAffiche == EtatAccesAffiche.expire,
    );
    return StatusPill(
      libelle: unExpire
          ? t.compte.tuteur.acces.pastilleExpire
          : t.compte.tuteur.acces.pastilleActif,
      ton: unExpire ? TonEtat.alerte : TonEtat.succes,
    );
  }
}

/// Le resume du foyer : initiales des profils eleves (quatre au plus), leur
/// nombre, la legende. **Le titulaire n'y figure pas** tant qu'il n'a pas de
/// profil eleve : il est titulaire, pas eleve.
class _ResumeFoyer extends StatelessWidget {
  const _ResumeFoyer({required this.profils});

  final AsyncValue<List<ProfilEleveFoyer>> profils;

  static const int _avatarsMax = 4;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle styleCompte = palette.inkStrong.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );
    final List<ProfilEleveFoyer>? liste = profils.hasValue && !profils.hasError
        ? profils.requireValue
        : null;
    final String? compte = switch (liste?.length) {
      null => null,
      0 => t.compte.tuteur.foyer.aucun,
      1 => t.compte.tuteur.foyer.un,
      final int n => t.compte.tuteur.foyer.plusieurs(nombre: n),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (liste != null && liste.isNotEmpty && compte != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final ProfilEleveFoyer p in liste.take(_avatarsMax))
                      Align(
                        widthFactor: 0.8,
                        child: AvatarTile(
                          prenom: p.prenom,
                          diametre: AppSpacing.section,
                        ),
                      ),
                  ],
                ),
              ),
              Text(compte, style: styleCompte),
            ],
          )
        else if (compte != null)
          Text(compte, style: styleCompte)
        else if (profils.isLoading)
          const Skeleton.texte(lignes: 1),
        Ecart.vXs,
        Text(
          t.compte.tuteur.foyer.legende,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
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
      await ref.read(serviceAuthProvider).deconnexion();
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
    final TextStyle style = palette.inkAlert.applyTo(
      textes.labelLarge ?? const TextStyle(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Pressable.selon(
          onPress: _enCours ? null : _seDeconnecter,
          libelleSemantique: t.compte.deconnexion,
          arrondiFocus: AppRadius.arrondiMd,
          constructeur: (BuildContext _, EtatPression etat) => DecoratedBox(
            decoration: AppElevation.avecFilet(
              surface: palette.surfaceRaised,
              filet: palette.contourCarte,
              ombre: palette.ombre,
              arrondi: AppRadius.arrondiMd,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppTouchTarget.standard,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconTheme(
                        data: palette.inkAlert.asIconTheme(size: AppSpacing.xl),
                        child: Icon(AppIcons.sortie.repos),
                      ),
                      Ecart.hSm,
                      Flexible(
                        child: Text(
                          t.compte.deconnexion,
                          style: etat.survole || etat.focus
                              ? style.copyWith(
                                  decoration: TextDecoration.underline,
                                )
                              : style,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
