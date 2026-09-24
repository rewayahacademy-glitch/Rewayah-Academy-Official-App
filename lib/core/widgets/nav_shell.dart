import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../preferences/preferences_locales.dart';
import '../router/routes.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// Une destination de premier niveau.
@immutable
class Destination {
  /// Cree une destination.
  const Destination({
    required this.libelle,
    required this.icone,
    required this.chemin,
    this.enPied = false,
  });

  /// Le libelle affiche et lu.
  final String libelle;

  /// L'icone, dans ses deux graisses : `regular` au repos, `fill` a l'etat
  /// actif.
  final AppIcon icone;

  /// Le chemin de la route. C'est ce que [NavShell] rend a l'appelant.
  final String chemin;

  /// Vrai quand la destination est **epinglee en bas** du rail et de la barre
  /// laterale (le Compte du tuteur, manifeste visuel Tuteur V1 section 4.2).
  ///
  /// L'ordre de la barre basse ne change pas : elle y reste a sa place dans la
  /// liste. Seule la colonne laterale la separe des autres.
  final bool enPied;
}

/// Les destinations de premier niveau d'un role, dans l'ordre de la barre.
///
/// Fonction pure, a part du cablage : la regle des quatre destinations se
/// verifie sans monter de routeur.
///
/// **Le role seul ne suffit pas, le mode d'interface compte.** Un eleve en
/// mode enfant n'a aucune destination : sans decision a lui laisser, aucune
/// navigation n'est offerte, et `NavShell` rend alors son enfant sans le
/// moindre chrome. Le controleur et le comptable, de meme, n'ont pas de
/// coquille : une destination unique ne monte pas une barre.
///
/// **Le mode change le nombre de destinations, jamais l'arborescence**
/// (ADR-009) : les branches du routeur sont les memes pour les deux modes,
/// seule la liste rendue a la barre change ici.
List<Destination> destinationsPour({
  required AppRole role,
  required InterfaceMode mode,
}) {
  final List<Destination> destinations = switch (role) {
    AppRole.student =>
      mode == InterfaceMode.enfant
          ? const <Destination>[]
          : <Destination>[
              Destination(
                libelle: t.nav.eleve.accueil,
                icone: AppIcons.accueil,
                chemin: Routes.eleve,
              ),
              Destination(
                libelle: t.nav.eleve.coran,
                icone: AppIcons.coran,
                chemin: Routes.eleveCoran,
              ),
              Destination(
                libelle: t.nav.eleve.suivi,
                icone: AppIcons.suivi,
                chemin: Routes.eleveSuivi,
              ),
              Destination(
                libelle: t.nav.eleve.compte,
                icone: AppIcons.profil,
                chemin: Routes.compte,
              ),
            ],
    // **Accueil, Foyer, Historique, Compte**, dans cet ordre et sur tous les
    // formats (mandat Tuteur V1 section 4 ; decisions du coordinateur du
    // 24/09/2026, section 3 point 6). Chacune est une branche de la coquille
    // tuteur, Compte compris : c'est ce qui donne enfin au tuteur une
    // deconnexion sur telephone. Disponibilites et Reglages quittent la
    // barre : le matching individuel est remplace, les reglages par eleve
    // rejoignent la fiche du Foyer.
    AppRole.guardian => <Destination>[
      Destination(
        libelle: t.nav.tuteur.accueil,
        icone: AppIcons.accueil,
        chemin: Routes.tuteurAccueil,
      ),
      Destination(
        libelle: t.nav.tuteur.foyer,
        icone: AppIcons.foyer,
        chemin: Routes.tuteurFoyer,
      ),
      Destination(
        libelle: t.nav.tuteur.historique,
        icone: AppIcons.historique,
        chemin: Routes.tuteurSuivi,
      ),
      Destination(
        libelle: t.nav.tuteur.compte,
        icone: AppIcons.profil,
        chemin: Routes.tuteurCompte,
        enPied: true,
      ),
    ],
    // **Exactement trois destinations**, et pas quatre : le gel d'architecture
    // du role Enseignant l'impose (`TEACHER_PARALLEL_BASELINE.md` §3.1). La
    // quatrieme etait « Compte », et c'etait un doublon : « Compte » et
    // « Profil » repondaient a la meme question, *moi*. `ENS-05` porte
    // desormais l'identite professionnelle, le contrat, le statut **et**
    // l'acces aux parametres reellement personnels, deconnexion comprise ; il
    // n'y a donc plus rien a atteindre par une destination de plus.
    AppRole.teacher => <Destination>[
      Destination(
        libelle: t.nav.enseignant.journee,
        icone: AppIcons.journee,
        chemin: Routes.enseignantJournee,
      ),
      Destination(
        libelle: t.nav.enseignant.creneaux,
        icone: AppIcons.creneaux,
        chemin: Routes.enseignantCreneaux,
      ),
      Destination(
        libelle: t.nav.enseignant.profil,
        icone: AppIcons.profil,
        chemin: Routes.enseignantProfil,
      ),
    ],
    // Le controleur observe et signale : une seule destination, qui ne monte
    // pas de barre. Le comptable est hors de l'arborescence en MVP-0 (ADR-003).
    //
    // **L'admin n'en tient plus aucune ici depuis le lot IA-01** (19 septembre
    // 2026) : l'operateur a impose une architecture a huit domaines, au dela
    // de ce que `maxDestinations` peut rendre en barre physique. L'admin a
    // desormais sa propre coquille, `AdminShell`
    // (`lib/core/widgets/admin_shell.dart`, `lib/core/admin/admin_domaine.dart`),
    // qui ne partage pas cette limite de quatre : elle est nee pour un role a
    // barre courte, et huit domaines en feraient un menu si on les y forcait.
    AppRole.controller ||
    AppRole.accountant ||
    AppRole.admin => const <Destination>[],
  };

  assert(
    destinations.length <= NavShell.maxDestinations,
    'Aucun role n a plus de ${NavShell.maxDestinations} destinations de '
    'premier niveau (03-architecture-information.md section 5).',
  );
  return destinations;
}

/// Les entrees secondaires d'un role : les ecrans hors barre qu'un pied de
/// coquille doit encore exposer.
///
/// **Vide pour tous les roles depuis le 24/09/2026.** Le tuteur y portait
/// « Mon compte », seule sortie vers la deconnexion, et invisible sous 600 :
/// Compte est desormais sa quatrieme destination, et le laisser ici le
/// ferait apparaitre deux fois (mandat Tuteur V1 section 4). L'eleve et
/// l'enseignant portent deja leur compte dans leurs destinations ; le
/// controleur et le comptable n'ont pas de coquille ; l'admin a la sienne.
List<Destination> secondairesPour({required AppRole role}) =>
    const <Destination>[];

/// La navigation de premier niveau, dans ses trois formes.
///
/// **Une seule liste de destinations alimente les trois formes** : barre basse
/// flottante sous 600, colonne laterale a partir de 600, repliee en rail de
/// 80 ou depliee en barre laterale de 256 avec le mot-symbole
/// (`docs/archive/2026-09-pre-remise-a-plat/design/03-architecture-information.md`
/// section 5 ; manifeste visuel Tuteur V1 sections 3.4 et 4). Trois listes
/// finiraient par diverger.
///
/// Deux regles portees par l'API :
///
/// - **quatre destinations au maximum**, pour tous les roles. C'est la seule
///   chose qui empeche la barre basse de devenir un menu. Une cinquieme est
///   refusee par une assertion, pas par la relecture ;
/// - **zero destination est un cas legitime**, et meme deux : l'eleve en mode
///   enfant n'a aucune navigation, le controleur n'en a qu'une. Aucun chrome
///   n'est alors rendu, et l'ecran occupe toute la place.
///
/// **Zone sure** : la barre basse consomme l'encart bas, le contenu ne le
/// recoit donc plus ; la barre ne recoit pas l'encart haut, qui appartient au
/// contenu. Avant le 24/09/2026, la barre posee dans une `Column` sous un
/// contenu en `SafeArea` complet appliquait l'encart bas deux fois et
/// consommait aussi l'encart haut (recette C11, section 5.6). Meme regle
/// pour la colonne laterale et l'encart de son cote.
class NavShell extends StatelessWidget {
  /// Cles stables pour verifier les trois presentations adaptatives du shell.
  static const Key barreBasseKey = ValueKey<String>('nav-shell-barre-basse');
  static const Key railKey = ValueKey<String>('nav-shell-rail');
  static const Key barreLateraleKey = ValueKey<String>(
    'nav-shell-barre-laterale',
  );

  /// Cle du bouton de repli ou de depli de la colonne laterale.
  static const Key boutonRepliKey = ValueKey<String>('nav-shell-bouton-repli');

  /// Cree la coquille de navigation.
  ///
  /// **Volontairement non `const`** : les deux assertions portent sur la
  /// longueur d'une liste, et la longueur d'une liste n'est pas une expression
  /// constante. Rendre le constructeur `const` obligerait a les retirer, or
  /// c'est par elles que la regle des quatre destinations tient.
  // ignore: prefer_const_constructors_in_immutables
  NavShell({
    required this.destinations,
    required this.indexActif,
    required this.onAller,
    required this.child,
    this.secondaires = const <Destination>[],
    this.onAllerSecondaire,
    this.masquerBarreBasse = false,
    this.libellesDansLeRail = false,
    super.key,
  }) : assert(
         destinations.length <= maxDestinations,
         'Aucun role n a plus de $maxDestinations destinations de premier '
         'niveau : au dela, la barre devient un menu '
         '(03-architecture-information.md section 5).',
       ),
       assert(
         indexActif == null ||
             indexActif >= 0 && indexActif < destinations.length ||
             destinations.isEmpty,
         'La destination active doit exister dans la liste, ou etre nulle '
         'sur un ecran secondaire qui n en est pas une.',
       );

  /// Les destinations du role courant.
  final List<Destination> destinations;

  /// L'index de la destination courante.
  ///
  /// **Nul sur un ecran secondaire** : aucune destination n'est alors
  /// surlignee, mais le chrome reste la pour qu'on puisse en sortir.
  final int? indexActif;

  /// Ce qui se passe quand une destination est choisie. Recoit son chemin.
  final void Function(String chemin) onAller;

  /// L'ecran affiche.
  final Widget child;

  /// Les entrees secondaires, sous les destinations de la colonne laterale.
  ///
  /// **Elles ne comptent pas dans les quatre destinations**, et ne sont
  /// jamais rendues dans la barre basse. Aucun role n'en a plus depuis que
  /// Compte est une destination du tuteur ([secondairesPour]) ; le parametre
  /// reste pour un ecran hors barre qui en aurait besoin.
  final List<Destination> secondaires;

  /// Ce qui se passe quand une entree secondaire est choisie.
  ///
  /// Volontairement distinct de `onAller` : une destination est une branche de
  /// la coquille `go_router` et se rejoint par son index, alors qu'une entree
  /// secondaire est une route de premier niveau **hors** de la coquille.
  final void Function(String chemin)? onAllerSecondaire;

  /// Vrai sur une **tache focalisee** (ajout de profil, questionnaire,
  /// emetteur QR, sous-pages de preferences, consentement) : sur telephone,
  /// la barre basse disparait et l'ecran porte son propre disque retour
  /// (manifeste visuel Tuteur V1 section 4.2 point 5). La colonne laterale
  /// reste visible sur tablette et bureau.
  final bool masquerBarreBasse;

  /// Vrai quand le rail replie garde le **nom visible** de chaque
  /// destination, sous son icone, au lieu de l'infobulle seule.
  ///
  /// C'est la forme d'avant le chantier Tuteur V1 (rail Material a libelles),
  /// gardee pour l'eleve et l'enseignant : le rail a icones seules est une
  /// decision de la maquette du tuteur, et la navigation des autres roles ne
  /// change pas sans decision du directeur (revue phase 0, jetons D2 et
  /// routes D3).
  final bool libellesDansLeRail;

  /// Le nombre maximal de destinations de premier niveau.
  static const int maxDestinations = 4;

  /// Hauteur minimale de la barre basse flottante, hors zone sure.
  static const double hauteurBarre = 64;

  /// Epaisseur du soulignement de la destination active de la barre basse.
  static const double epaisseurSoulignement = 3;

  /// Echelle de texte maximale des libelles de la barre basse : au-dela, un
  /// libelle de quatre onglets ne tient plus dans sa colonne. Le libelle
  /// reste lu en entier par le lecteur d'ecran.
  static const double echelleTexteMaxBarre = 1.5;

  @override
  Widget build(BuildContext context) {
    // Moins de deux destinations : il n'y a rien a choisir, donc rien a
    // afficher. Une barre a une seule entree n'est pas une navigation, c'est
    // un titre.
    if (destinations.length < 2) {
      return child;
    }

    final Gabarit gabarit = AppGabarit.de(context);
    if (gabarit.chrome == ChromeNavigation.barreBasse) {
      if (masquerBarreBasse) {
        return child;
      }
      final AppPalette palette = AppPalette.of(context);
      return ColoredBox(
        // Le fond de page passe sous la barre flottante et autour d'elle.
        color: palette.surfaceCanvas.background,
        child: Column(
          children: <Widget>[
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: child,
              ),
            ),
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _BarreFlottante(
                destinations: destinations,
                indexActif: indexActif,
                onAller: onAller,
              ),
            ),
          ],
        ),
      );
    }

    return _AvecColonne(
      gabarit: gabarit,
      destinations: destinations,
      indexActif: indexActif,
      onAller: onAller,
      secondaires: secondaires,
      onAllerSecondaire: onAllerSecondaire,
      libellesDansLeRail: libellesDansLeRail,
      child: child,
    );
  }
}

/// La barre basse flottante : une pilule arrondie posee au-dessus de la zone
/// sure (manifeste visuel Tuteur V1 section 3.4, maquette V3).
///
/// Destination active : icone pleine, libelle en accent et soulignement de
/// trois points. Inactive : icone au trait et encre attenuee. Jamais la
/// couleur seule : l'etat « selectionne » est aussi annonce.
class _BarreFlottante extends StatelessWidget {
  const _BarreFlottante({
    required this.destinations,
    required this.indexActif,
    required this.onAller,
  });

  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return KeyedSubtree(
      key: NavShell.barreBasseKey,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: t.nav.principale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surfaceRaised.background,
                borderRadius: AppRadius.arrondiMd,
                border: Border.fromBorderSide(
                  palette.contourCarte.asBorderSide(),
                ),
                boxShadow: AppElevation.niveau1(palette.ombre),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: NavShell.hauteurBarre,
                ),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: NavShell.echelleTexteMaxBarre,
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _OngletBarre(
                            destination: destinations[i],
                            actif: i == indexActif,
                            onAller: onAller,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OngletBarre extends StatelessWidget {
  const _OngletBarre({
    required this.destination,
    required this.actif,
    required this.onAller,
  });

  final Destination destination;
  final bool actif;
  final void Function(String chemin) onAller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppInkColor encre = actif ? palette.inkAccent : palette.inkMuted;
    final TextStyle base = textes.labelMedium ?? const TextStyle();

    // Un seul noeud par onglet : bouton, libelle, etat selectionne. Le dessin
    // (icone, texte, soulignement) ne se relit pas une seconde fois.
    return Semantics(
      container: true,
      selected: actif,
      child: Pressable(
        onPress: () => onAller(destination.chemin),
        libelleSemantique: destination.libelle,
        arrondiFocus: AppRadius.arrondiSm,
        child: ExcludeSemantics(
          // Le soulignement pose sur le bord bas de la pilule, comme la
          // maquette de Mon compte mobile (planche 0c2 contre maquette).
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconTheme(
                  data: encre.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(destination.icone.resoudre(selectionne: actif)),
                ),
                Ecart.vXs,
                Text(
                  destination.libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: encre.applyTo(
                    AppTypography.graisse(
                      base,
                      actif ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Ecart.vSm,
                SizedBox(
                  width: AppSpacing.section,
                  height: NavShell.epaisseurSoulignement,
                  child: actif
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.inkAccent.asBorderSide().color,
                            borderRadius: AppRadius.arrondiFull,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La colonne laterale et le contenu, cote a cote.
///
/// Repliee (rail de 80, icones seules, infobulles) ou depliee (barre laterale
/// de 256, mot-symbole, libelles) : par defaut selon la largeur, repliee sur
/// tablette et depliee sur bureau ; le bouton de repli en fait un **choix de
/// cet appareil** (`navigationReplieeProvider`, persiste par `RewayahApp`).
class _AvecColonne extends ConsumerWidget {
  const _AvecColonne({
    required this.gabarit,
    required this.destinations,
    required this.indexActif,
    required this.onAller,
    required this.secondaires,
    required this.onAllerSecondaire,
    required this.libellesDansLeRail,
    required this.child,
  });

  final Gabarit gabarit;
  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;
  final List<Destination> secondaires;
  final void Function(String chemin)? onAllerSecondaire;
  final bool libellesDansLeRail;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool? choix = ref.watch(navigationReplieeProvider);
    final bool repliee = choix ?? gabarit == Gabarit.tablette;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      children: <Widget>[
        _Colonne(
          repliee: repliee,
          libellesDansLeRail: libellesDansLeRail,
          destinations: destinations,
          indexActif: indexActif,
          onAller: onAller,
          secondaires: secondaires,
          onAllerSecondaire: onAllerSecondaire,
          onBasculer: () => ref
              .read(navigationReplieeProvider.notifier)
              .choisir(repliee: !repliee),
        ),
        Expanded(
          // La colonne consomme l'encart de son cote (debut de lecture) : le
          // contenu ne le recoit plus.
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: !rtl,
            removeRight: rtl,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.repliee,
    required this.libellesDansLeRail,
    required this.destinations,
    required this.indexActif,
    required this.onAller,
    required this.secondaires,
    required this.onAllerSecondaire,
    required this.onBasculer,
  });

  final bool repliee;
  final bool libellesDansLeRail;
  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;
  final List<Destination> secondaires;
  final void Function(String chemin)? onAllerSecondaire;
  final VoidCallback onBasculer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    Widget item(Destination d, {required bool actif, required bool entree}) =>
        _ItemColonne(
          destination: d,
          actif: actif,
          repliee: repliee,
          libelleSousIcone: libellesDansLeRail,
          onPress: () =>
              entree ? onAllerSecondaire?.call(d.chemin) : onAller(d.chemin),
        );

    final List<Widget> haut = <Widget>[
      for (int i = 0; i < destinations.length; i++)
        if (!destinations[i].enPied)
          item(destinations[i], actif: i == indexActif, entree: false),
      if (secondaires.isNotEmpty) ...<Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Divider(height: 1),
        ),
        for (final Destination entree in secondaires)
          item(entree, actif: false, entree: true),
      ],
    ];
    final List<Widget> pied = <Widget>[
      for (int i = 0; i < destinations.length; i++)
        if (destinations[i].enPied)
          item(destinations[i], actif: i == indexActif, entree: false),
    ];

    return SizedBox(
      key: repliee ? NavShell.railKey : NavShell.barreLateraleKey,
      width: repliee ? AppGabarit.largeurRail : AppGabarit.largeurBarreLaterale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          // Directionnel : en arabe, la colonne passe a droite et son filet
          // avec elle.
          border: BorderDirectional(end: palette.contourCarte.asBorderSide()),
        ),
        child: SafeArea(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: t.nav.principale,
            child: LayoutBuilder(
              builder: (BuildContext _, BoxConstraints contraintes) =>
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: contraintes.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _EnteteColonne(
                              repliee: repliee,
                              onBasculer: onBasculer,
                            ),
                            Ecart.vLg,
                            ...haut,
                            const Spacer(),
                            ...pied,
                            Ecart.vLg,
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La tete de la colonne : mot-symbole et bouton de repli quand elle est
/// depliee, bouton de depli seul quand elle est repliee.
class _EnteteColonne extends StatelessWidget {
  const _EnteteColonne({required this.repliee, required this.onBasculer});

  final bool repliee;
  final VoidCallback onBasculer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String libelle = repliee ? t.nav.deplier : t.nav.replier;

    final Widget bouton = Tooltip(
      message: libelle,
      child: Pressable(
        key: NavShell.boutonRepliKey,
        onPress: onBasculer,
        libelleSemantique: libelle,
        arrondiFocus: AppRadius.arrondiFull,
        // Un disque de 40 dans une cible de 48 (maquette V2 : bouton rond
        // cercle, manifeste 3.4 : cible jamais sous 48).
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Center(
            child: SizedBox.square(
              dimension: AppSpacing.section,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surfaceOverlay.background,
                  border: Border.fromBorderSide(
                    palette.contourCarte.asBorderSide(),
                  ),
                ),
                child: Center(
                  child: IconTheme(
                    data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                    child: Icon(
                      repliee
                          ? AppIcons.deplierNavigation.repos
                          : AppIcons.replierNavigation.repos,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (repliee) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Center(child: bouton),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                t.nav.motSymbole,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: palette.inkStrong.applyTo(
                  AppTypography.graisse(
                    textes.titleLarge ?? const TextStyle(),
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          bouton,
        ],
      ),
    );
  }
}

/// Une destination de la colonne laterale.
///
/// Active : pastille `washAccent`, icone pleine et libelle d'accent en
/// clair ; aplat `surfacePrimary` et encre posee dessus en sombre (manifeste
/// visuel section 3.4, maquettes V2 A et C). Inactive : icone au trait en
/// encre attenuee, libelle en encre forte. Repliee, l'item n'est qu'une icone
/// de 48 : son nom passe par l'infobulle et le lecteur d'ecran.
class _ItemColonne extends StatelessWidget {
  const _ItemColonne({
    required this.destination,
    required this.actif,
    required this.repliee,
    required this.libelleSousIcone,
    required this.onPress,
  });

  final Destination destination;
  final bool actif;
  final bool repliee;

  /// Replie, le nom reste visible sous l'icone (eleve, enseignant), au lieu
  /// de l'infobulle seule (tuteur). Sans effet quand la colonne est depliee.
  final bool libelleSousIcone;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool sombre = palette.estSombre;

    final Color? fond = !actif
        ? null
        : sombre
        ? palette.surfacePrimary.background
        : palette.washAccent.background;
    final Color couleurIcone = !actif
        ? palette.inkMuted.asBorderSide().color
        : sombre
        ? palette.surfacePrimary.onBackground
        : palette.inkAccent.asBorderSide().color;
    final Color couleurLibelle = !actif
        ? palette.inkStrong.asBorderSide().color
        : sombre
        ? palette.surfacePrimary.onBackground
        : palette.inkAccent.asBorderSide().color;

    final Widget icone = IconTheme(
      data: IconThemeData(color: couleurIcone, size: AppSpacing.xxl),
      child: Icon(destination.icone.resoudre(selectionne: actif)),
    );

    final Widget pastille = DecoratedBox(
      decoration: BoxDecoration(color: fond, borderRadius: AppRadius.arrondiSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppTouchTarget.standard,
          minWidth: AppTouchTarget.standard,
        ),
        child: repliee
            ? Center(child: icone)
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    icone,
                    Ecart.hMd,
                    Expanded(
                      child: Text(
                        destination.libelle,
                        style: AppTypography.graisse(
                          textes.bodyLarge ?? const TextStyle(),
                          actif ? FontWeight.w600 : FontWeight.w500,
                        ).copyWith(color: couleurLibelle),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

    if (repliee && libelleSousIcone) {
      // Le rail a libelles : pastille d'icone, puis le nom en dessous, dans
      // toute la largeur du rail. Le nom reste lu en entier par le lecteur
      // d'ecran ; a l'ecran il est borne comme celui de la barre basse.
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Semantics(
          container: true,
          selected: actif,
          child: Pressable(
            onPress: onPress,
            libelleSemantique: destination.libelle,
            arrondiFocus: AppRadius.arrondiSm,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: fond,
                      borderRadius: AppRadius.arrondiSm,
                    ),
                    child: SizedBox(
                      width: AppTouchTarget.standard,
                      height: AppSpacing.xxxl,
                      child: Center(child: icone),
                    ),
                  ),
                  Ecart.vXs,
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: NavShell.echelleTexteMaxBarre,
                    child: Text(
                      destination.libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: (textes.labelMedium ?? const TextStyle()).copyWith(
                        color: !actif
                            ? palette.inkMuted.asBorderSide().color
                            : palette.inkAccent.asBorderSide().color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final Widget pressable = Semantics(
      container: true,
      selected: actif,
      child: Pressable(
        onPress: onPress,
        libelleSemantique: destination.libelle,
        arrondiFocus: AppRadius.arrondiSm,
        child: ExcludeSemantics(child: pastille),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: repliee ? AppSpacing.lg : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: repliee
          ? Tooltip(message: destination.libelle, child: pressable)
          : pressable,
    );
  }
}
