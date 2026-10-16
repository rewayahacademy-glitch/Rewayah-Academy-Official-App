import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_accents_profils.dart';
import '../../core/domain/enums.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/accent_profil.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/identite_profil.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_financiere.dart';
import '../../core/widgets/selecteur_couleur_profil.dart';
import '../../core/widgets/skeleton.dart';
import '../compte/ligne_matricule.dart';
import 'finances_foyer.dart';
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
    this.titreBureau,
    this.sousTitreBureau,
  });

  /// L'eleve demande par le chemin.
  final String eleveId;

  /// Le titre de la page ; `null` : le prenom de l'eleve.
  final String? titre;

  /// A 1200 et plus, une fois l'eleve retrouve : le titre de la page tire
  /// de son prenom (« Mariam · Finances », maquette 06) ; `null` : [titre].
  final String Function(String prenom)? titreBureau;

  /// A 1200 et plus, avec [titreBureau] : la ligne sous le titre, un fil
  /// d'Ariane dont « Foyer » mene au Foyer ([FilArianeFiche], maquette 06) ;
  /// `null` : le prenom.
  final Widget Function(String prenom)? sousTitreBureau;

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
    if (sansDonneesHorsLigne(profils, horsLigne: horsLigne)) {
      // Le bandeau de `PageShell` dit le reseau, le bloc dit ce qui manque
      // (EA-HL-DOUBLE-1).
      corps = EtatSansDonnees(
        quoi: t.ficheEleve.sansDonnees,
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
    final String Function(String prenom)? titreLarge =
        AppGabarit.de(context) == Gabarit.desktop &&
            prenom != null &&
            prenom.isNotEmpty
        ? titreBureau
        : null;
    if (titreLarge != null && prenom != null) {
      return PageShell(
        titre: titreLarge(prenom),
        sousTitre: sousTitreBureau == null ? prenom : null,
        ligneSousTitre: sousTitreBureau?.call(prenom),
        onRetour: onRetour,
        child: corps,
      );
    }
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

/// Le fil d'Ariane d'une sous-page de la fiche, sur bureau (maquette 06,
/// revue 4 a) : « Foyer », un lien vers le Foyer, puis « › {prenom} », la
/// page courante, en encre attenuee. Le disque retour, lui, mene a la fiche.
class FilArianeFiche extends StatelessWidget {
  /// Cree le fil.
  const FilArianeFiche({required this.prenom, super.key});

  /// Le lien « Foyer ».
  static const Key foyerKey = Key('ficheEleve.filAriane.foyer');

  /// Le prenom de l'eleve.
  final String prenom;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: <Widget>[
        LienFleche(
          key: foyerKey,
          libelle: t.ficheEleve.filAriane.foyer,
          fleche: false,
          onPress: () => GoRouter.of(context).go(Routes.tuteurFoyer),
        ),
        Text(
          t.ficheEleve.filAriane.suite(prenom: prenom),
          style: palette.inkMuted.applyTo(
            Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
          ),
        ),
      ],
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

  /// La marge interne de la surface.
  static const double marge = AppSpacing.xl;

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
      child: Padding(padding: const EdgeInsets.all(marge), child: child),
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
/// Le solde par eleve (decision du directeur, section 1 ter point 9) prend
/// la ligne « Finances » de ce groupe (FI-6a), seulement quand une source
/// rend les finances du foyer.
class FicheElevePage extends ConsumerWidget {
  /// Cree la page.
  const FicheElevePage({
    required this.eleveId,
    super.key,
    this.onAller,
    this.onRetour,
    this.avecPageFinances = true,
  });

  /// L'eleve affiche. Un identifiant de chemin, jamais une autorisation : la
  /// RLS decide.
  final String eleveId;

  /// Ouvre un chemin de la fiche (sous-pages) ; par defaut, le routeur. La
  /// demonstration adulte y garde la personne dans sa coquille (EA-5).
  final void Function(String chemin)? onAller;

  /// Le retour ; par defaut, le Foyer par le routeur.
  final VoidCallback? onRetour;

  /// Vrai quand la page Finances de l'eleve existe derriere `onAller`. La
  /// demonstration adulte n'en a pas (ses sous-pages ramenent a la fiche) :
  /// sans elle, aucun onglet Général / Finances, un segment qui ne mene
  /// nulle part n'est pas pose.
  final bool avecPageFinances;

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
          _ContenuFiche(
            profil: profil,
            onAller: onAller,
            avecPageFinances: avecPageFinances,
          ),
    );
  }
}

class _ContenuFiche extends ConsumerWidget {
  const _ContenuFiche({
    required this.profil,
    required this.avecPageFinances,
    this.onAller,
  });

  final ProfilEleveFoyer profil;

  final void Function(String chemin)? onAller;

  final bool avecPageFinances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final void Function(String chemin) aller =
        onAller ?? GoRouter.of(context).go;
    final ClasseMembre classe = classeMembreLue(
      ref.watch(classesMembreProvider(profil.eleveId)),
    );
    String sousPage(String segment) =>
        Routes.ficheEleveSousPage(profil.eleveId, segment);
    // Sous 1200, les finances s'ouvrent par le segment « Finances » (Q-FI-1,
    // revue 3 a) ; a 1200 et plus, sans segmente (revue 4 b), par la ligne.
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;
    final bool avecFinances =
        avecPageFinances &&
        legendeFinances(ref.watch(financesFoyerProvider), profil.eleveId) !=
            null;

    final Widget parametres = ParametresEleve(
      profil: profil,
      onAller: aller,
      avecFinances: bureau,
    );

    final Widget appareils = KeyedSubtree(
      key: FicheElevePage.appareilsKey,
      child: GroupeReglages(
        titre: t.ficheEleve.appareilsGroupe,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.appareil,
            libelle: t.ficheEleve.lignes.appareils(
              dePrenom: deDevant(profil.prenom),
            ),
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
        if (avecFinances && !bureau) ...<Widget>[
          OngletsFiche(
            eleveId: profil.eleveId,
            actif: OngletFiche.general,
            onAller: aller,
          ),
          Ecart.vXxl,
        ],
        KeyedSubtree(
          key: FicheElevePage.enteteKey,
          child: _Entete(
            profil: profil,
            classe: texteClasse(classe),
            accent: accentLu(ref.watch(accentsProfilsProvider), profil.eleveId),
          ),
        ),
        Ecart.vXxl,
        ColonnesFiche(principal: parametres, annexe: appareils),
      ],
    );
  }
}

/// Les onglets de la fiche d'un eleve (Q-FI-1, revue 3 a ;
/// `02_DECOUPAGE` FI-6a) : « Général » et « Finances », chacun une route.
/// Sous 1200 seulement : a 1200 et plus, la page Finances porte les
/// parametres dans sa colonne d'identite, sans segmente (revue 4 b).
enum OngletFiche {
  /// La fiche elle-meme (`/tuteur/foyer/:eleveId`).
  general,

  /// Ses finances (`/tuteur/foyer/:eleveId/finances`).
  finances,
}

/// Le controle segmente des onglets de la fiche. Ce n'est pas une
/// navigation propre : chaque segment ouvre sa route.
class OngletsFiche extends StatelessWidget {
  /// Cree les onglets.
  const OngletsFiche({
    required this.eleveId,
    required this.actif,
    super.key,
    this.onAller,
  });

  /// La cle du controle.
  static const Key cle = Key('ficheEleve.onglets');

  /// L'eleve de la fiche.
  final String eleveId;

  /// L'onglet de la page courante.
  final OngletFiche actif;

  /// Ouvre un chemin ; par defaut, le routeur.
  final void Function(String chemin)? onAller;

  @override
  Widget build(BuildContext context) {
    final void Function(String chemin) aller =
        onAller ?? GoRouter.of(context).go;
    return ControleSegmente<OngletFiche>(
      key: cle,
      segments: <Segment<OngletFiche>>[
        Segment<OngletFiche>(
          valeur: OngletFiche.general,
          libelle: t.ficheEleve.onglets.general,
        ),
        Segment<OngletFiche>(
          valeur: OngletFiche.finances,
          libelle: t.ficheEleve.onglets.finances,
        ),
      ],
      valeur: actif,
      onChange: (OngletFiche onglet) => aller(switch (onglet) {
        OngletFiche.general => Routes.ficheElevePour(eleveId),
        OngletFiche.finances => Routes.ficheEleveSousPage(eleveId, 'finances'),
      }),
    );
  }
}

/// Le groupe « Paramètres de l'élève » : informations, parcours et
/// inscription, interface, couleur, camera, acces et, quand une source rend
/// les finances, la ligne « Finances ». Un seul groupe, pose par la fiche et
/// repris tel quel dans la colonne d'identite de la page Finances sur bureau
/// (revue 4 b, K-51) : jamais recopie.
class ParametresEleve extends ConsumerWidget {
  /// Cree le groupe.
  const ParametresEleve({
    required this.profil,
    required this.onAller,
    super.key,
    this.avecFinances = true,
  });

  /// L'eleve.
  final ProfilEleveFoyer profil;

  /// Ouvre une sous-page.
  final void Function(String chemin) onAller;

  /// Faux : aucune ligne « Finances » (la page Finances elle-meme, ou les
  /// onglets qui la portent sous 1200).
  final bool avecFinances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime maintenant = ref.watch(horlogeFoyerProvider)();
    String sousPage(String segment) =>
        Routes.ficheEleveSousPage(profil.eleveId, segment);
    return KeyedSubtree(
      key: FicheElevePage.parametresKey,
      child: GroupeReglages(
        titre: t.ficheEleve.parametres,
        lignes: <LigneRubrique>[
          LigneRubrique(
            icone: AppIcons.profil,
            libelle: t.ficheEleve.lignes.informations,
            legende: t.ficheEleve.lignes.informationsLegende,
            onPress: () => onAller(sousPage('informations')),
          ),
          LigneRubrique(
            icone: AppIcons.lecon,
            libelle: t.ficheEleve.lignes.inscription,
            legende: t.ficheEleve.lignes.inscriptionLegende,
            onPress: () => onAller(sousPage('inscription')),
          ),
          LigneRubrique(
            icone: AppIcons.tabletteOuOrdinateur,
            libelle: t.ficheEleve.lignes.interface,
            legende: libelleInterface(profil.mode),
            onPress: () => onAller(sousPage('interface')),
          ),
          LigneRubrique(
            icone: AppIcons.palette,
            libelle: t.ficheEleve.lignes.couleur,
            legende: legendeCouleur(
              ref.watch(accentsProfilsProvider),
              profil.eleveId,
            ),
            onPress: () => onAller(sousPage('couleur')),
          ),
          LigneRubrique(
            icone: AppIcons.camera,
            libelle: t.ficheEleve.lignes.camera,
            legende: profil.camera == CameraPolicy.allowed
                ? t.ficheEleve.lignes.cameraAutorisee
                : t.ficheEleve.lignes.cameraNonAutorisee,
            onPress: () => onAller(sousPage('camera')),
          ),
          LigneRubrique(
            icone: AppIcons.verrou,
            libelle: t.ficheEleve.lignes.acces,
            legende: statutAcces(profil, maintenant),
            onPress: () => onAller(sousPage('acces')),
          ),
          // FI-6a : la finance du profil, seulement quand une source la
          // rend (jamais en production ni au second adulte, lecon 15).
          if (avecFinances)
            if (legendeFinances(
                  ref.watch(financesFoyerProvider),
                  profil.eleveId,
                )
                case final ({String? legende}) finances)
              LigneRubrique(
                icone: AppIcons.finance,
                libelle: t.ficheEleve.lignes.finances,
                legende: finances.legende,
                onPress: () => onAller(sousPage('finances')),
              ),
        ],
      ),
    );
  }
}

/// La carte d'identite : photo, prenom, classe quand elle est connue.
class _Entete extends StatelessWidget {
  const _Entete({
    required this.profil,
    required this.classe,
    required this.accent,
  });

  final ProfilEleveFoyer profil;
  final String? classe;

  /// La couleur choisie par le tuteur (K-62), `null` sans bandeau.
  final AccentProfil? accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? ligneClasse = classe;
    return SurfaceFiche(
      // AVATAR-1 : couple avatar + nom du composant partage, nom et une
      // ligne de role (la classe).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarNom.enLigne(
            prenom: profil.prenom,
            role: ligneClasse,
            diametre: AppAvatar.grand,
            ecart: AppSpacing.lg,
            // Le bandeau part du bord haut de la surface (marge
            // `SurfaceFiche.marge`, K-62) ; le cercle reste donc en haut.
            cercleEnHaut: true,
            enveloppeAvatar: BandeauProfil.enveloppe(
              diametre: AppAvatar.grand,
              accent: accent,
              remontee: SurfaceFiche.marge,
            ),
            avatar: PhotoEleve(
              prenom: profil.prenom,
              cleAvatar: profil.cleAvatar,
              diametre: AppAvatar.grand,
            ),
            styleNom: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
            styleRole: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          // IMM-FRONT-1 : le matricule de l'enfant, sous son prenom.
          LigneMatricule(profileId: profil.eleveId),
        ],
      ),
    );
  }
}

/// La legende de la ligne « Couleur du profil » : le nom de la couleur, « Sans
/// couleur », ou, sans source (production, FI-BR-19), « Pas encore
/// disponible » plutot qu'un choix vide qui n'a jamais ete fait (revue FI-2-R
/// m1). Tant que rien n'est lu, `null` (aucune legende, comme la classe) ;
/// une lecture en echec dit « Couleur non lue », jamais « Sans couleur »
/// faute de savoir (revue FI-2-CORR-R).
String? legendeCouleur(
  AsyncValue<Map<String, AccentProfil>> accents,
  String profilId,
) {
  if (accents.hasError) {
    return accents.error is CapaciteIndisponible
        ? t.ficheEleve.lignes.couleurIndisponible
        : t.ficheEleve.lignes.couleurEchec;
  }
  if (!accents.hasValue) return null;
  return switch (accentLu(accents, profilId)) {
    final AccentProfil a => libelleAccent(a),
    null => t.ficheEleve.lignes.couleurAucune,
  };
}

/// La ligne « Finances » de la fiche : `null` (aucune ligne) tant que rien
/// n'est lu et quand la source n'existe pas (`CapaciteIndisponible` :
/// production, second adulte) ; sinon sa legende, l'etat financier lu, ou
/// `null` quand la lecture a echoue ou ne rend pas ce profil (la sous-page
/// dit pourquoi).
({String? legende})? legendeFinances(
  AsyncValue<FinancesFoyer> lecture,
  String profilId,
) {
  if (lecture.hasError) {
    return lecture.error is CapaciteIndisponible ? null : (legende: null);
  }
  if (!lecture.hasValue) return null;
  final FinancesProfil? finance = financesParProfil(lecture)[profilId];
  return (
    legende: finance == null
        ? null
        : PastilleFinanciere.libelleDe(finance.etat),
  );
}
