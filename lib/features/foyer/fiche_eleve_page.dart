import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/domain/enums.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'foyer_page.dart';
import 'ligne_membre.dart';
import 'photo_eleve.dart';

/// Une page de la fiche d'un eleve : la fiche elle-meme et ses sous-pages.
///
/// Elle tient ce que toutes partagent : retrouver l'eleve dans le foyer
/// (`profils_du_foyer_v`, lue par K1), les etats chargement, erreur, hors
/// ligne et **introuvable** (un identifiant de chemin inconnu du foyer, jamais
/// « aucun profil »), le disque retour de niveau 2 et le titre. L'identifiant
/// du chemin est une demande, jamais une autorisation : la RLS decide de ce
/// que la lecture rend.
class PageFiche extends ConsumerWidget {
  /// Cree la page.
  const PageFiche({
    required this.eleveId,
    required this.onRetour,
    required this.construire,
    super.key,
    this.titre,
  });

  /// L'eleve demande par le chemin.
  final String eleveId;

  /// Le titre de la page ; `null` : le prenom de l'eleve.
  final String? titre;

  /// Le retour visible (niveau 2) : la fiche pour une sous-page, le Foyer
  /// pour la fiche.
  final VoidCallback onRetour;

  /// Le corps, une fois l'eleve retrouve.
  final Widget Function(BuildContext context, ProfilEleveFoyer profil)
  construire;

  void _relire(WidgetRef ref) => ref.invalidate(elevesDuFoyerProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La source d'abord, comme le Foyer : K1 attend `elevesDuFoyerProvider`
    // et resterait en chargement pendant les nouvelles tentatives de
    // Riverpod sans exposer l'echec.
    final AsyncValue<List<EleveDuFoyer>> source = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<List<ProfilEleveFoyer>> profils = source.hasError
        ? AsyncValue<List<ProfilEleveFoyer>>.error(
            source.error!,
            source.stackTrace ?? StackTrace.empty,
          )
        : ref.watch(profilsElevesFoyerProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;

    ProfilEleveFoyer? profil;
    if (profils.hasValue && !profils.hasError) {
      for (final ProfilEleveFoyer p in profils.requireValue) {
        if (p.eleveId == eleveId) {
          profil = p;
        }
      }
    }

    final Widget corps;
    if (horsLigne &&
        profils.hasError &&
        profils.error is! CapaciteIndisponible) {
      corps = EtatSysteme(
        nature: NatureEtat.horsLigne,
        onAction: () => _relire(ref),
      );
    } else {
      corps = BlocAsynchrone<List<ProfilEleveFoyer>>(
        valeur: profils,
        squelette: const Skeleton.liste(),
        onReessayer: () => _relire(ref),
        construire: (List<ProfilEleveFoyer> _) {
          final ProfilEleveFoyer? trouve = profil;
          if (trouve == null) {
            return EtatSysteme(
              nature: NatureEtat.introuvable,
              portee: PorteeEtat.page,
              titre: t.ficheEleve.introuvable.titre,
              phrase: t.ficheEleve.introuvable.phrase,
              libelleAction: t.ficheEleve.introuvable.retour,
              onAction: () => GoRouter.of(context).go(Routes.tuteurFoyer),
            );
          }
          return construire(context, trouve);
        },
      );
    }

    final String? prenom = profil?.prenom;
    return PageShell(
      titre:
          titre ??
          (prenom == null || prenom.isEmpty ? t.ficheEleve.titreRepli : prenom),
      sousTitre: titre == null ? null : prenom,
      onRetour: onRetour,
      child: corps,
    );
  }
}

/// Le retour d'une sous-page : toujours vers la fiche de son eleve, par son
/// adresse (un `pop` perdrait l'onglet actif apres un lien profond).
VoidCallback retourVersFiche(BuildContext context, String eleveId) =>
    () => GoRouter.of(context).go(Routes.ficheElevePour(eleveId));

/// Deux colonnes sur bureau (a partir de 1200), une pile en dessous.
///
/// La composition des pages de la fiche derive du Compte haute fidelite :
/// le sujet principal a gauche, ce qui l'accompagne a droite. Jamais une
/// colonne mobile etiree.
class ColonnesFiche extends StatelessWidget {
  /// Cree la composition.
  const ColonnesFiche({required this.principal, super.key, this.annexe});

  /// Le sujet de la page.
  final Widget principal;

  /// Ce qui l'accompagne : notes, liens.
  final Widget? annexe;

  @override
  Widget build(BuildContext context) {
    final Widget? droite = annexe;
    if (droite == null) {
      return principal;
    }
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: principal),
          Ecart.hXxl,
          Expanded(flex: 2, child: droite),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[principal, Ecart.vXxl, droite],
    );
  }
}

/// Une note attenuee : ce qui manque, ce qui s'applique et quand.
class NoteFiche extends StatelessWidget {
  /// Cree la note.
  const NoteFiche(this.texte, {super.key});

  /// Le texte.
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        texte,
        style: palette.inkMuted.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Une surface a filet, celle des groupes du Compte, pour un bloc libre
/// (carte d'identite, photo).
class SurfaceFiche extends StatelessWidget {
  /// Cree la surface.
  const SurfaceFiche({required this.child, super.key});

  /// Le contenu.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}

/// Le libelle de l'interface d'un eleve.
String libelleInterface(InterfaceMode mode) => switch (mode) {
  InterfaceMode.enfant => t.ficheEleve.interface.guidee,
  InterfaceMode.standard => t.ficheEleve.interface.standard,
};

/// La fiche d'un profil eleve du foyer (`/tuteur/foyer/:eleveId`).
///
/// Aucune maquette haute fidelite : contenu de l'ancienne capture « Profil »
/// (fiche de l'eleve), rendu derive du Compte (manifeste visuel, section 2) :
/// une carte d'identite (photo, prenom, classe quand elle est connue), puis
/// les parametres de l'eleve en UN groupe a filets (informations, parcours et
/// inscription, interface, camera en cours, acces), puis ses appareils en une
/// ligne vers l'ecran du lot D (aucun import de D). Sur bureau, deux colonnes.
/// Onglet actif : Foyer. Aucun age affiche : il n'est pas enregistre
/// (DB-ADM-05).
///
/// Place reservee, rien de construit : le futur solde par eleve (decision du
/// directeur, section 1 ter point 9) prendra une ligne de ce groupe ou un
/// groupe sous les appareils, sans refonte.
class FicheElevePage extends ConsumerWidget {
  /// Cree la page.
  const FicheElevePage({
    required this.eleveId,
    super.key,
    this.onAller,
    this.onRetour,
  });

  /// L'eleve affiche. Un identifiant de chemin, jamais une autorisation : la
  /// RLS decide.
  final String eleveId;

  /// Ouvre un chemin de la fiche (sous-pages) ; par defaut, le routeur. La
  /// demonstration adulte y garde la personne dans sa coquille (EA-5).
  final void Function(String chemin)? onAller;

  /// Le retour ; par defaut, le Foyer par le routeur.
  final VoidCallback? onRetour;

  /// La carte d'identite.
  static const Key enteteKey = Key('ficheEleve.entete');

  /// Le groupe des parametres.
  static const Key parametresKey = Key('ficheEleve.parametres');

  /// Le groupe des appareils.
  static const Key appareilsKey = Key('ficheEleve.appareils');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageFiche(
      eleveId: eleveId,
      onRetour: onRetour ?? () => GoRouter.of(context).go(Routes.tuteurFoyer),
      construire: (BuildContext context, ProfilEleveFoyer profil) =>
          _ContenuFiche(profil: profil, onAller: onAller),
    );
  }
}

class _ContenuFiche extends ConsumerWidget {
  const _ContenuFiche({required this.profil, this.onAller});

  final ProfilEleveFoyer profil;

  final void Function(String chemin)? onAller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final void Function(String chemin) aller =
        onAller ?? GoRouter.of(context).go;
    final DateTime maintenant = ref.watch(horlogeFoyerProvider)();
    final ClasseMembre classe = classeMembreLue(
      ref.watch(classesMembreProvider(profil.eleveId)),
    );
    String sousPage(String segment) =>
        Routes.ficheEleveSousPage(profil.eleveId, segment);

    final Widget parametres = KeyedSubtree(
      key: FicheElevePage.parametresKey,
      child: GroupeReglages(
        titre: t.ficheEleve.parametres,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.ficheEleve.lignes.informations,
            legende: t.ficheEleve.lignes.informationsLegende,
            onPress: () => aller(sousPage('informations')),
          ),
          LigneRubrique(
            icone: AppIcons.lecon,
            libelle: t.ficheEleve.lignes.inscription,
            legende: t.ficheEleve.lignes.inscriptionLegende,
            onPress: () => aller(sousPage('inscription')),
          ),
          LigneRubrique(
            icone: AppIcons.tabletteOuOrdinateur,
            libelle: t.ficheEleve.lignes.interface,
            legende: libelleInterface(profil.mode),
            onPress: () => aller(sousPage('interface')),
          ),
          LigneRubrique(
            icone: AppIcons.camera,
            libelle: t.ficheEleve.lignes.camera,
            legende: profil.camera == CameraPolicy.allowed
                ? t.ficheEleve.lignes.cameraAutorisee
                : t.ficheEleve.lignes.cameraNonAutorisee,
            onPress: () => aller(sousPage('camera')),
          ),
          LigneRubrique(
            icone: AppIcons.verrou,
            libelle: t.ficheEleve.lignes.acces,
            legende: statutAcces(profil, maintenant),
            onPress: () => aller(sousPage('acces')),
          ),
        ],
      ),
    );

    final Widget appareils = KeyedSubtree(
      key: FicheElevePage.appareilsKey,
      child: GroupeReglages(
        titre: t.ficheEleve.appareilsGroupe,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.appareil,
            libelle: t.ficheEleve.lignes.appareils(prenom: profil.prenom),
            legende: t.ficheEleve.lignes.appareilsLegende,
            // Le retour des appareils ramene a cette fiche (`?retour=`), pas
            // aux appareils du foyer d'ou l'on ne vient pas (B-5).
            onPress: () => aller(
              Uri(
                path: sousPage('appareils'),
                queryParameters: <String, String>{
                  'retour': Routes.ficheElevePour(profil.eleveId),
                },
              ).toString(),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        KeyedSubtree(
          key: FicheElevePage.enteteKey,
          child: _Entete(profil: profil, classe: texteClasse(classe)),
        ),
        Ecart.vXxl,
        ColonnesFiche(principal: parametres, annexe: appareils),
      ],
    );
  }
}

/// La carte d'identite : photo, prenom, classe quand elle est connue.
class _Entete extends StatelessWidget {
  const _Entete({required this.profil, required this.classe});

  final ProfilEleveFoyer profil;
  final String? classe;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? ligneClasse = classe;
    return SurfaceFiche(
      child: Row(
        children: <Widget>[
          PhotoEleve(
            prenom: profil.prenom,
            cleAvatar: profil.cleAvatar,
            diametre: AppSpacing.respiration + AppSpacing.sm,
          ),
          Ecart.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  profil.prenom,
                  style: palette.inkStrong.applyTo(
                    textes.titleLarge ?? const TextStyle(),
                  ),
                ),
                if (ligneClasse != null) ...<Widget>[
                  Ecart.vXs,
                  Text(
                    ligneClasse,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
