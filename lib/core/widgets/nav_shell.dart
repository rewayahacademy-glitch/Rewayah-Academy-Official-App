import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibilite/effacement_barre_basse.dart';
import '../accessibilite/texte_sans_coupure.dart';
import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../mouvement/mouvement.dart';
import '../preferences/preferences_locales.dart';
import '../router/routes.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
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
    this.essentielle = true,
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

  /// Faux quand la destination n'est **pas essentielle** : le Mode
  /// Accessibilite (`InterfaceMode.enfant`) ne la met pas dans la barre
  /// (MA-NAV-1). Elle reste une route de la meme arborescence, atteinte par
  /// un autre chemin de l'ecran (l'Accueil de l'eleve porte un bloc Coran
  /// permanent). Vrai par defaut : seule une destination qui a un autre acces
  /// peut passer a faux, sinon un ecran n'aurait plus d'entree.
  final bool essentielle;
}

/// Les destinations de premier niveau d'un role, dans l'ordre de la barre.
///
/// Fonction pure, a part du cablage : la regle des quatre destinations se
/// verifie sans monter de routeur.
///
/// **MA-2 (27/09/2026) : l'eleve a les memes quatre destinations dans les
/// deux presentations**, standard et Mode Accessibilite (`InterfaceMode
/// .enfant`) : Accueil, Ma classe, Coran, Mon espace (doc 06 §3, MA17 ; choix
/// provisoire du directeur Q1). Le mode ne cree pas une seconde application :
/// fin du « aucune destination » de l'ancien mode enfant. Les routes ne
/// changent pas : Ma classe mene a `/eleve/suivi` (le Suivi s'atteint donc
/// depuis Ma classe), Mon espace a `/compte`. Le parametre [mode] reste pour
/// les autres roles et la signature ; il ne change plus rien a l'eleve.
///
/// **MA-NAV-1 (02/10/2026)** : en Mode Accessibilite la barre ne garde que
/// les destinations [Destination.essentielle] ; pour l'eleve les quatre le
/// sont (MA-CMD-1 : le Coran reste dans la barre, decision deleguee du
/// 02/10). L'arborescence et les routes ne changent pas :
/// seule la liste montree est plus courte. Pour retrouver la branche du
/// routeur d'une destination, on lit la liste **complete**
/// (`destinationsPour(mode: InterfaceMode.standard)`), jamais l'index de la
/// liste courte ([indexDansBarre]).
///
/// Le comptable n'a pas de coquille : une destination unique ne monte pas une
/// barre. Le controleur en a une a quatre destinations depuis le 27/09/2026
/// (C13).
List<Destination> destinationsPour({
  required AppRole role,
  required InterfaceMode mode,
}) {
  final List<Destination> completes = switch (role) {
    // L'ordre est celui des branches de la coquille eleve dans
    // `app_router.dart` (Accueil, Ma classe, Coran) : les deux doivent rester
    // d'accord. Mon espace n'a pas de branche, il se rejoint par `go`.
    AppRole.student => <Destination>[
      Destination(
        libelle: t.nav.eleve.accueil,
        icone: AppIcons.accueil,
        chemin: Routes.eleve,
      ),
      Destination(
        libelle: t.nav.eleve.maClasse,
        icone: AppIcons.classes,
        chemin: Routes.eleveSuivi,
      ),
      Destination(
        libelle: t.nav.eleve.coran,
        icone: AppIcons.coran,
        chemin: Routes.eleveCoran,
        // MA-CMD-1 (02/10/2026) : le Coran RESTE dans la barre du Mode
        // Accessibilite (4 destinations ; DECISIONS_DELEGUEES_2026-10-02,
        // MA-NAV-1) ; de MA-NAV-1 seule la presentation est reportee.
      ),
      Destination(
        libelle: t.nav.eleve.monEspace,
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
    // **Aujourd'hui, Classes, Disponibilites, Profil**, dans cet ordre et sur
    // tous les formats (regle E10). ADR-027 et ses trois destinations sont
    // remplaces par la decision du directeur du 26/09/2026 : Classes devient
    // une destination de premier niveau. « Compte » ne revient pas : `ENS-05`
    // (Profil) porte toujours l'acces aux parametres, deconnexion comprise.
    // L'ordre de cette liste est celui des branches de la coquille enseignant
    // dans `app_router.dart` : les deux doivent rester d'accord.
    AppRole.teacher => <Destination>[
      Destination(
        libelle: t.nav.enseignant.journee,
        icone: AppIcons.journee,
        chemin: Routes.enseignantJournee,
      ),
      Destination(
        libelle: t.nav.enseignant.classes,
        icone: AppIcons.classes,
        chemin: Routes.enseignantClasses,
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
    // **Controle, Historique, Echanges, Compte**, dans cet ordre et sur tous
    // les formats (C13, document 08 du 27/09/2026 §4.1). Le choix precedent,
    // « une seule destination, qui ne monte pas de barre », est remplace par
    // ce document, plus recent (DESIGN-GOV §1). Les trois premieres sont les
    // branches de la coquille controleur dans `app_router.dart`, dans le meme
    // ordre ; Compte est `/compte`, partage, rejoint par `go`.
    AppRole.controller => <Destination>[
      Destination(
        libelle: t.nav.controleur.controle,
        icone: AppIcons.controleQualite,
        chemin: Routes.controleur,
      ),
      Destination(
        libelle: t.nav.controleur.historique,
        icone: AppIcons.historique,
        chemin: Routes.controleurHistorique,
      ),
      Destination(
        libelle: t.nav.controleur.echanges,
        icone: AppIcons.discussion,
        chemin: Routes.controleurEchanges,
      ),
      Destination(
        libelle: t.nav.controleur.compte,
        icone: AppIcons.profil,
        chemin: Routes.compte,
      ),
    ],
    // **Aujourd'hui, Paiements, Tresorerie, Compte**, dans cet ordre et sur
    // tous les formats (Comptable V1, CPT-F ; spec Finance operationnelle
    // §45 « bottom navigation reelle » ; `UX_REVIEW_FINANCE_COMPTABLE_L0.md`
    // §3, DR-01). Les planches montraient une barre de 7 a 10 entrees : le
    // depot n'en admet que quatre, le second niveau (A effectuer,
    // Contractuels, Beneficiaires ; Coffres, Encaissements, Rapprochement)
    // vit en onglets dans la page (`navigation_comptable.dart`). Les trois
    // premieres sont les branches de la coquille comptable dans
    // `app_router.dart`, dans le meme ordre ; Compte est `/compte`, partage,
    // rejoint par `go`. ADR-003 (« hors de l'arborescence en MVP-0 ») est
    // remplace par la spec du 04/10/2026.
    AppRole.accountant => <Destination>[
      Destination(
        libelle: t.comptable.nav.aujourdhui,
        icone: AppIcons.journee,
        chemin: Routes.comptable,
      ),
      Destination(
        libelle: t.comptable.nav.paiements,
        icone: AppIcons.paiements,
        chemin: Routes.comptablePaiements,
      ),
      Destination(
        libelle: t.comptable.nav.tresorerie,
        icone: AppIcons.coffre,
        chemin: Routes.comptableTresorerie,
      ),
      Destination(
        libelle: t.comptable.nav.compte,
        icone: AppIcons.profil,
        chemin: Routes.compte,
      ),
    ],
    // **L'admin n'en tient plus aucune ici depuis le lot IA-01** (19 septembre
    // 2026) : l'operateur a impose une architecture a huit domaines, au dela
    // de ce que `maxDestinations` peut rendre en barre physique. L'admin a
    // desormais sa propre coquille, `AdminShell`
    // (`lib/core/widgets/admin_shell.dart`, `lib/core/admin/admin_domaine.dart`),
    // qui ne partage pas cette limite de quatre : elle est nee pour un role a
    // barre courte, et huit domaines en feraient un menu si on les y forcait.
    AppRole.admin => const <Destination>[],
  };

  final List<Destination> destinations = mode == InterfaceMode.enfant
      ? completes.where((Destination d) => d.essentielle).toList()
      : completes;

  assert(
    destinations.length <= NavShell.maxDestinations,
    'Aucun role n a plus de ${NavShell.maxDestinations} destinations de '
    'premier niveau (03-architecture-information.md section 5).',
  );
  return destinations;
}

/// L'index, dans la liste montree [visibles], de la destination qui porte
/// l'index [indexComplet] de la liste [completes] (celle des branches du
/// routeur).
///
/// Nul quand cette destination n'est pas dans la barre (Coran en Mode
/// Accessibilite) : aucune destination n'est alors surlignee, comme sur un
/// ecran secondaire. En presentation standard les deux listes sont
/// identiques et l'index ne change pas.
int? indexDansBarre({
  required List<Destination> visibles,
  required List<Destination> completes,
  required int? indexComplet,
}) {
  if (indexComplet == null ||
      indexComplet < 0 ||
      indexComplet >= completes.length) {
    return null;
  }
  final int index = visibles.indexWhere(
    (Destination d) => d.chemin == completes[indexComplet].chemin,
  );
  return index == -1 ? null : index;
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
/// - **zero destination est un cas legitime**, et meme une : le controleur
///   n'en a qu'une (l'eleve en a quatre dans les deux presentations depuis
///   MA-2). Aucun chrome
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

  /// La rangee d'onglets de la barre basse quand elle defile (libelles qui
  /// ne tiennent pas ensemble, meme a [echelleMinimaleLisible]).
  static const Key barreBasseDefileKey = ValueKey<String>(
    'nav-shell-barre-basse-defile',
  );
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

  /// Vrai quand la presentation courante est le Mode Accessibilite (guide) :
  /// lu dans le theme (`AppMetriques`), jamais passe en parametre d'ecran
  /// (MA-NAV-1).
  static bool guide(BuildContext context) =>
      Theme.of(context).extension<AppMetriques>()?.estEnfant ?? false;

  /// Echelle de texte maximale des libelles de la barre basse : au-dela, un
  /// libelle de quatre onglets ne tient plus dans sa colonne. Le libelle
  /// reste lu en entier par le lecteur d'ecran.
  static const double echelleTexteMaxBarre = 1.5;

  /// Echelle de texte maximale des libelles de la barre du Mode Accessibilite.
  ///
  /// Plafond de 1,3 : le theme du guide part deja de 20 pt, et a 1,5 un mot de
  /// sept lettres se coupe dans un onglet de 320. Un texte regle a x2 par
  /// l'utilisateur grandit bien dans la barre. Le libelle passe a la ligne
  /// sans ellipse (la barre grandit avec lui) et le lecteur d'ecran le lit
  /// toujours en entier.
  static const double echelleTexteMaxGuide = 1.3;

  /// Epaisseur du contour franc de la barre du Mode Accessibilite (le filet de
  /// carte standard fait 1) : le seul trait plus epais du composant, nomme ici
  /// pour ne pas etre un chiffre litteral au milieu du dessin.
  static const double epaisseurContourGuide = 2;

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
      return _CoquilleBarreBasse(
        guide: guide(context),
        destinations: destinations,
        indexActif: indexActif,
        onAller: onAller,
        child: child,
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
      guide: guide(context),
      child: child,
    );
  }
}

/// Le contenu et la barre basse flottante, sur telephone.
///
/// MA-CMD-1 (finition, 02/10/2026) : la coquille pose un
/// [ControleurBarreBasse] ; pendant la lecture du Coran en Mode
/// Accessibilite, `CommandesMasquables(effacerBarreBasse: true)` y signale
/// que ses commandes se sont masquees, et la barre s'efface avec elles pour
/// rendre sa hauteur au Coran. Elle revient a la meme touche, et des que le
/// lecteur se ferme. Aucun autre ecran ne la pilote : partout ailleurs elle
/// reste ou elle est.
class _CoquilleBarreBasse extends StatefulWidget {
  const _CoquilleBarreBasse({
    required this.guide,
    required this.destinations,
    required this.indexActif,
    required this.onAller,
    required this.child,
  });

  final bool guide;
  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;
  final Widget child;

  @override
  State<_CoquilleBarreBasse> createState() => _CoquilleBarreBasseEtat();
}

class _CoquilleBarreBasseEtat extends State<_CoquilleBarreBasse> {
  final ControleurBarreBasse _controleur = ControleurBarreBasse();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // Le contenu garde son identite quand la barre s'efface : seul son
    // encart bas change.
    final Widget contenu = EffacementBarreBasse(
      controleur: _controleur,
      child: widget.child,
    );
    return ColoredBox(
      // Le fond de page passe sous la barre flottante et autour d'elle.
      color: palette.surfaceCanvas.background,
      child: ValueListenableBuilder<bool>(
        valueListenable: _controleur,
        child: contenu,
        builder: (BuildContext context, bool effacee, Widget? contenu) {
          return Column(
            children: <Widget>[
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: !effacee,
                  child: contenu!,
                ),
              ),
              if (!effacee)
                MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: _BarreFlottante(
                    guide: widget.guide,
                    destinations: widget.destinations,
                    indexActif: widget.indexActif,
                    onAller: widget.onAller,
                  ),
                ),
            ],
          );
        },
      ),
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
    required this.guide,
    required this.destinations,
    required this.indexActif,
    required this.onAller,
  });

  /// Mode Accessibilite : barre plus haute, onglets plus larges et espaces,
  /// libelles toujours visibles, contraste renforce (MA-NAV-1).
  final bool guide;
  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = _metriques(context);

    // MA-CMD-1 : quatre onglets de 72 doivent tenir a 320 ; marges et ecarts
    // se resserrent alors (le Coran reste dans la barre).
    final bool serre = destinations.length >= 4;
    final double ecart = serre ? AppSpacing.xs : AppSpacing.sm;

    return KeyedSubtree(
      key: NavShell.barreBasseKey,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        // INTEG-MINEURS-1 : la marge laterale ne tombe jamais a zero (la barre
        // touchait les deux bords a 320). Quand les minimums des onglets ne
        // tiennent plus dans ce qui reste, ce sont les onglets qui prennent des
        // parts egales (`_largeursOnglets` rend nul), pas la marge qui cede.
        child: Builder(
          builder: (BuildContext contexte) => _cadre(
            contexte,
            palette,
            metriques,
            serre ? AppSpacing.xs : AppSpacing.sm,
            ecart,
          ),
        ),
      ),
    );
  }

  Widget _cadre(
    BuildContext context,
    AppPalette palette,
    AppMetriques metriques,
    double margeGuide,
    double ecart,
  ) {
    final bool serre = destinations.length >= 4;
    return Padding(
      // Guide : marges laterales de 8 au lieu de 12, pour que les libelles
      // agrandis gardent leur largeur.
      padding: EdgeInsetsDirectional.fromSTEB(
        guide ? margeGuide : AppSpacing.md,
        AppSpacing.sm,
        guide ? margeGuide : AppSpacing.md,
        0,
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: t.nav.principale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surfaceRaised.background,
            borderRadius: guide ? metriques.arrondi : AppRadius.arrondiMd,
            // Guide : contour franc (`borderStrong`) a la place du filet
            // de carte, pour que la barre se detache du fond.
            border: Border.fromBorderSide(
              guide
                  ? palette.borderStrong.asBorderSide(
                      width: NavShell.epaisseurContourGuide,
                    )
                  : palette.contourCarte.asBorderSide(),
            ),
            boxShadow: AppElevation.niveau1(palette.ombre),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: guide
                  ? metriques.cibleTactile + AppSpacing.xl
                  : NavShell.hauteurBarre,
            ),
            // Guide : la hauteur de la barre suit le libelle, qui passe a la
            // ligne sans ellipse, plafonne par `echelleTexteMaxGuide`.
            child: guide
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: serre ? 0 : AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: NavShell.echelleTexteMaxGuide,
                      child: LayoutBuilder(
                        builder: (BuildContext contexte, BoxConstraints c) =>
                            _rangeesGuide(contexte, metriques, c, ecart),
                      ),
                    ),
                  )
                : MediaQuery.withClampedTextScaling(
                    maxScaleFactor: NavShell.echelleTexteMaxBarre,
                    // COUPE-MOTS-1 : chaque onglet recoit son mot le plus long
                    // (« Disponibilites ») puis une part egale du reste, au
                    // lieu de parts egales qui coupaient le mot long des 100 % ;
                    // les quatre libelles partagent une seule echelle.
                    child: LayoutBuilder(
                      builder: (BuildContext contexte, BoxConstraints c) {
                        final ({TextScaler echelle, List<double> largeurs}) r =
                            repartitionSansCoupure(
                              contexte,
                              textes: <String>[
                                for (final Destination d in destinations)
                                  d.libelle,
                              ],
                              largeur: c.maxWidth,
                              style: AppTypography.graisse(
                                Theme.of(contexte).textTheme.labelMedium ??
                                    const TextStyle(),
                                FontWeight.w600,
                              ),
                              marge: 2 * AppSpacing.xs,
                              // Reduction bornee : jamais sous 85 % du theme.
                              plancher: echelleMinimaleLisible,
                            );
                        final double total = r.largeurs.fold<double>(
                          0,
                          (double a, double b) => a + b,
                        );
                        // Au plancher, des libelles qui ne tiennent toujours
                        // pas ensemble (cinq onglets, langue longue) gardent
                        // chacun sa largeur et la rangee defile.
                        final bool defile =
                            c.maxWidth.isFinite && total > c.maxWidth + 0.5;
                        final Widget rangee = Row(
                          mainAxisSize: defile
                              ? MainAxisSize.min
                              : MainAxisSize.max,
                          children: <Widget>[
                            for (int i = 0; i < destinations.length; i++)
                              defile
                                  ? SizedBox(
                                      width: r.largeurs[i],
                                      child: _OngletBarre(
                                        destination: destinations[i],
                                        actif: i == indexActif,
                                        onAller: onAller,
                                      ),
                                    )
                                  : _part(
                                      r.largeurs.isEmpty ||
                                              i == destinations.length - 1
                                          ? null
                                          : r.largeurs[i],
                                      _OngletBarre(
                                        destination: destinations[i],
                                        actif: i == indexActif,
                                        onAller: onAller,
                                      ),
                                    ),
                          ],
                        );
                        return MediaQuery(
                          data: MediaQuery.of(contexte)
                              .copyWith(textScaler: r.echelle),
                          child: defile
                              ? SingleChildScrollView(
                                  key: NavShell.barreBasseDefileKey,
                                  scrollDirection: Axis.horizontal,
                                  child: rangee,
                                )
                              : rangee,
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Les onglets du Mode Accessibilite dans [c] (ecart [ecart]).
  ///
  /// COUPE-MOTS-4 (decide par delegation le 09/10) : a 320 en texte x2,
  /// l'echelle commune des libelles ne descendait jamais sous 1, et quatre
  /// onglets ne laissaient pas a « Historique » ou « Disponibilités » leur
  /// largeur : « Historiq / ue », « Contrôl / e », « Échang / es ». Dans
  /// l'ordre, et seulement si le cas precedent ne suffit pas :
  ///
  /// 1. une rangee, chaque onglet recevant son mot le plus long a l'echelle
  ///    de l'appareil (au plus 1) ;
  /// 2. une rangee, l'echelle reduite jusqu'a [echelleMinimaleLisible]
  ///    (reduction bornee, comme la barre standard) ;
  /// 3. deux rangees de deux onglets : la barre grandit, chaque onglet a la
  ///    moitie de la largeur. Toutes les destinations restent visibles
  ///    (pas de defilement, qui en cacherait une a l'utilisateur guide).
  Widget _rangeesGuide(
    BuildContext contexte,
    AppMetriques metriques,
    BoxConstraints c,
    double ecart,
  ) {
    final int n = destinations.length;
    final double disponible = c.maxWidth - ecart * (n - 1);
    final double facteur = MediaQuery.textScalerOf(contexte).scale(1);
    double somme(List<double> l) =>
        l.fold<double>(0, (double a, double b) => a + b);
    List<double>? largeurs = _largeursOnglets(
      _minimumsOnglets(contexte, metriques),
      disponible,
    );
    if (largeurs == null && facteur > echelleMinimaleLisible) {
      final List<double> reduits = _minimumsOnglets(
        contexte,
        metriques,
        echelle: echelleMinimaleLisible,
      );
      if (somme(reduits) <= disponible) {
        largeurs = _largeursOnglets(reduits, disponible);
      }
    }
    // Parts egales (minimums de cible tactile trop larges ensemble) : la
    // rangee unique reste, tant que chaque mot y tient a l'echelle reduite.
    final TextStyle styleMot = DefaultTextStyle.of(contexte).style.merge(
      AppTypography.graisse(
        Theme.of(contexte).textTheme.labelLarge ?? const TextStyle(),
        FontWeight.w700,
      ),
    );
    final bool motsTiennentEnParts = destinations.every(
      (Destination d) =>
          _motLePlusLong(
            contexte,
            d.libelle,
            styleMot,
            const TextScaler.linear(echelleMinimaleLisible),
          ) <=
          disponible / n - 2 * AppSpacing.xs,
    );
    final bool deuxRangees =
        largeurs == null &&
        !motsTiennentEnParts &&
        n > 2 &&
        disponible.isFinite;
    final int parRangee = deuxRangees ? (n + 1) ~/ 2 : n;
    final double largeurDeux =
        (c.maxWidth - ecart * (parRangee - 1)) / parRangee;
    // COUPE-MOTS-1 point 6 : une seule echelle pour les libelles, celle du
    // plus contraint ; plus un onglet reduit et son voisin non.
    final TextScaler commune = echelleCommuneSansCoupure(
      contexte,
      textes: <String>[for (final Destination d in destinations) d.libelle],
      largeurs: <double>[
        for (int i = 0; i < n; i++)
          (deuxRangees
                  ? largeurDeux
                  : largeurs == null
                  ? disponible / n
                  : largeurs[i]) -
              2 * AppSpacing.xs,
      ],
      style: AppTypography.graisse(
        Theme.of(contexte).textTheme.labelLarge ?? const TextStyle(),
        FontWeight.w700,
      ),
      plancher: echelleMinimaleLisible,
    );
    Widget onglet(int i) => _OngletBarreGuide(
      destination: destinations[i],
      actif: i == indexActif,
      onAller: onAller,
    );
    Widget rangee(int debut, int fin, List<double>? parts) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = debut; i < fin; i++) ...<Widget>[
            if (i > debut) SizedBox(width: ecart),
            _part(parts == null || i == fin - 1 ? null : parts[i], onglet(i)),
          ],
        ],
      ),
    );
    return MediaQuery(
      data: MediaQuery.of(contexte).copyWith(textScaler: commune),
      child: deuxRangees
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                rangee(0, parRangee, null),
                SizedBox(height: ecart),
                rangee(parRangee, n, null),
              ],
            )
          : rangee(0, n, largeurs),
    );
  }

  /// Un onglet de largeur fixe [largeur], ou qui prend le reste (nulle).
  static Widget _part(double? largeur, Widget onglet) => largeur == null
      ? Expanded(child: onglet)
      : SizedBox(width: largeur, child: onglet);

  /// Les largeurs des onglets du Mode Accessibilite dans [disponible] (ecarts
  /// deja retires), ou nul pour des parts egales.
  ///
  /// INTEG-RC-1 : avec quatre onglets a 320 (Coran garde dans la barre,
  /// MA-CMD-1), des parts egales ne laissaient pas a « Accueil » ses 4 de
  /// chaque cote (MA-NAV-1). Chaque onglet recoit donc son minimum
  /// ([_minimumsOnglets]), puis une part egale du reste. Si ces minimums ne
  /// tiennent pas, parts egales.
  List<double>? _largeursOnglets(List<double> minimums, double disponible) {
    if (!disponible.isFinite) return null;
    final double somme = minimums.fold<double>(
      0,
      (double a, double b) => a + b,
    );
    if (somme > disponible) return null;
    final double reste = (disponible - somme) / minimums.length;
    return <double>[for (final double m in minimums) m + reste];
  }

  /// La largeur minimale de chaque onglet du Mode Accessibilite : la cible
  /// tactile, ou son mot le plus long a l'echelle 1 plus 4 de chaque cote
  /// ([TexteSansCoupure] ne descend jamais sous 1).
  ///
  /// [echelle] : l'echelle de la mesure, a la place de celle de l'appareil
  /// (au plus 1).
  List<double> _minimumsOnglets(
    BuildContext context,
    AppMetriques metriques, {
    double? echelle,
  }) {
    final double facteur = echelle ?? MediaQuery.textScalerOf(context).scale(1);
    final TextStyle style = DefaultTextStyle.of(context).style.merge(
      AppTypography.graisse(
        Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
        FontWeight.w700,
      ),
    );
    return <double>[
      for (final Destination d in destinations)
        math.max(
          metriques.cibleTactile,
          _motLePlusLong(
                context,
                d.libelle,
                style,
                TextScaler.linear(math.min(facteur, 1)),
              ) +
              2 * AppSpacing.xs,
        ),
    ];
  }

  static double _motLePlusLong(
    BuildContext context,
    String texte,
    TextStyle style,
    TextScaler echelle,
  ) {
    double max = 0;
    for (final String mot in texte.split(RegExp(r'\s+'))) {
      if (mot.isEmpty) continue;
      final TextPainter p = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: Directionality.of(context),
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      if (p.width > max) max = p.width;
      p.dispose();
    }
    return max;
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
                // MA-2 : a 200 %, le nom passe a la ligne au lieu d'etre
                // tronque (UX_REVIEW_06, ligne 1 c) ; COUPE-MOTS-1 : entre
                // ses mots, jamais dans un mot, a l'echelle commune de la
                // barre.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: TexteSansCoupure(
                    destination.libelle,
                    textAlign: TextAlign.center,
                    style: encre.applyTo(
                      AppTypography.graisse(
                        base,
                        actif ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Ecart.vSm,
                SizedBox(
                  width: AppSpacing.section,
                  height: NavShell.epaisseurSoulignement,
                  child: actif
                      ? _SoulignementAnime(
                          couleur: palette.inkAccent.asBorderSide().color,
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

/// Un onglet de la barre basse du Mode Accessibilite (MA-NAV-1).
///
/// Memes destinations et memes routes que [_OngletBarre] ; seule la
/// presentation change : cible de `cibleTactile` (72) au moins, icone de 32,
/// libelle de corps toujours visible sous l'icone (jusqu'a trois lignes, sans
/// plafond de texte), encre forte au repos.
///
/// **Destination active, trois signaux** (jamais la couleur seule) : fond plein
/// `surfacePrimary`, icone pleine, libelle en gras sur l'encre posee sur ce
/// fond.
class _OngletBarreGuide extends StatelessWidget {
  const _OngletBarreGuide({
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
    final AppMetriques metriques = _metriques(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Color encre = actif
        ? palette.surfacePrimary.onBackground
        : palette.inkStrong.asBorderSide().color;

    return Semantics(
      container: true,
      selected: actif,
      child: Pressable(
        onPress: () => onAller(destination.chemin),
        libelleSemantique: destination.libelle,
        arrondiFocus: metriques.arrondiInterieur,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: actif ? palette.surfacePrimary.background : null,
              borderRadius: metriques.arrondiInterieur,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: metriques.cibleTactile),
              child: Padding(
                // MA-NAV-1 : 4 au moins de chaque cote du libelle, qui ne
                // touche jamais le bord de sa pastille ; il reduit au besoin
                // son echelle (jamais sous 1) au lieu de couper un mot.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconTheme(
                      data: IconThemeData(color: encre, size: AppSpacing.xxxl),
                      child: Icon(
                        destination.icone.resoudre(selectionne: actif),
                      ),
                    ),
                    Ecart.vXs,
                    TexteSansCoupure(
                      destination.libelle,
                      textAlign: TextAlign.center,
                      style: AppTypography.graisse(
                        textes.labelLarge ?? const TextStyle(),
                        actif ? FontWeight.w700 : FontWeight.w600,
                      ).copyWith(color: encre),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le soulignement de l'onglet actif : il s'etire depuis son centre quand
/// l'onglet devient actif (P2-16), une seule fois. Plein d'emblee quand les
/// animations sont reduites.
class _SoulignementAnime extends StatelessWidget {
  const _SoulignementAnime({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final Widget trait = DecoratedBox(
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: AppRadius.arrondiFull,
      ),
    );
    if (Mouvement.reduit(context)) {
      return trait;
    }
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Mouvement.moyen,
        curve: Mouvement.accentuee,
        child: trait,
        builder: (BuildContext _, double f, Widget? enfant) =>
            FractionallySizedBox(widthFactor: f, child: enfant),
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
    required this.guide,
    required this.child,
  });

  final Gabarit gabarit;
  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;
  final List<Destination> secondaires;
  final void Function(String chemin)? onAllerSecondaire;
  final bool libellesDansLeRail;
  final bool guide;
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
          // Guide : le nom reste toujours visible, meme sur le rail replie.
          libellesDansLeRail: libellesDansLeRail || guide,
          guide: guide,
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
    required this.guide,
    required this.destinations,
    required this.indexActif,
    required this.onAller,
    required this.secondaires,
    required this.onAllerSecondaire,
    required this.onBasculer,
  });

  final bool repliee;
  final bool libellesDansLeRail;
  final bool guide;
  final List<Destination> destinations;
  final int? indexActif;
  final void Function(String chemin) onAller;
  final List<Destination> secondaires;
  final void Function(String chemin)? onAllerSecondaire;
  final VoidCallback onBasculer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextScaler? commune = _echelleLibelles(context);

    Widget item(Destination d, {required bool actif, required bool entree}) {
      final Widget rendu = _ItemColonne(
        destination: d,
        actif: actif,
        repliee: repliee,
        libelleSousIcone: libellesDansLeRail,
        guide: guide,
        onPress: () =>
            entree ? onAllerSecondaire?.call(d.chemin) : onAller(d.chemin),
      );
      return commune == null
          ? rendu
          : MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: commune),
              child: rendu,
            );
    }

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
      // Guide : le rail est plus large (96) pour que le libelle, toujours
      // visible, tienne sous l'icone ; elargi si un mot n'y tient pas.
      width: _largeur(context, commune),
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

extension on _Colonne {
  /// La largeur du rail replie avant tout elargissement.
  double get _largeurRailDeBase =>
      guide ? AppGabarit.largeurRail + AppSpacing.lg : AppGabarit.largeurRail;

  /// Ce que le rail retire autour d'un libelle : 4 de chaque cote de l'item
  /// (et 4 dans l'item en guide).
  double get _retraitLibelleRail =>
      guide ? 4 * AppSpacing.xs : 2 * AppSpacing.xs;

  TextStyle _styleLibelleRail(TextTheme textes) => guide
      ? AppTypography.graisse(
          textes.labelLarge ?? const TextStyle(),
          FontWeight.w700,
        )
      : textes.labelMedium ?? const TextStyle();

  /// La largeur de la colonne. Rail replie a libelles : sa largeur de base,
  /// elargie quand le mot le plus long, a l'[commune] (jamais sous 0,85 ;
  /// jamais sous 1 quand le texte est agrandi), n'y tient pas : le
  /// conteneur s'elargit au lieu de reduire le texte davantage ou de le
  /// couper. En vraies polices, francais, a 100 %, le rail garde sa largeur
  /// de base (80, 96 en guide) ; texte agrandi, il s'elargit.
  double _largeur(BuildContext context, TextScaler? commune) {
    if (!repliee) return AppGabarit.largeurBarreLaterale;
    final double base = _largeurRailDeBase;
    if (commune == null) return base;
    double mot = 0;
    for (final Destination d in <Destination>[
      ...destinations,
      ...secondaires,
    ]) {
      final double m = largeurMotLePlusLong(
        context,
        d.libelle,
        _styleLibelleRail(Theme.of(context).textTheme),
        commune,
      );
      if (m > mot) mot = m;
    }
    // La marge d'arrondi (2) est deja comptee dans l'echelle commune : on
    // ne s'elargit que si le mot depasse vraiment la place de base.
    final double besoin = mot + _retraitLibelleRail + 2;
    return besoin > base + 1 ? besoin.ceilToDouble() : base;
  }

  /// L'echelle commune des libelles visibles de la colonne (COUPE-MOTS-1
  /// points 5 et 6), ou nulle quand le rail n'a que des icones.
  ///
  /// - Rail a libelles (80, ou 96 en guide) : le plafond de la barre basse
  ///   (1,5 ; 1,3 en guide), puis l'echelle qui fait tenir le mot le plus
  ///   long de tous (« Disponibilites », « Historique »), jamais sous
  ///   [echelleMinimaleLisible] (0,85) a 100 %, ni sous 1 quand le texte
  ///   est agrandi ; au-dela, le rail s'elargit ([_largeur]) plutot que de
  ///   tronquer « Contr... Histori... » ou de couper « Disponibilit / es ».
  /// - Barre laterale depliee : l'echelle de l'appareil, reduite au besoin
  ///   pour tous les libelles a la fois, jamais sous 1.
  TextScaler? _echelleLibelles(BuildContext context) {
    if (repliee && !libellesDansLeRail) return null;
    final TextTheme textes = Theme.of(context).textTheme;
    final List<String> libelles = <String>[
      for (final Destination d in <Destination>[
        ...destinations,
        ...secondaires,
      ])
        d.libelle,
    ];
    if (repliee) {
      final double plafond = guide
          ? NavShell.echelleTexteMaxGuide
          : NavShell.echelleTexteMaxBarre;
      return _commune(
        context,
        libelles,
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: plafond),
        _largeurRailDeBase - _retraitLibelleRail,
        _styleLibelleRail(textes),
        // Reduction bornee : jamais sous 85 % du theme a 100 % ; quand
        // l'utilisateur agrandit le texte (facteur > 1), jamais sous la
        // taille du theme (WCAG 1.4.4, revue COUPE-MOTS-1-R M1). Au-dela,
        // le rail s'elargit ([_largeur]).
        plancher: MediaQuery.textScalerOf(context).scale(1) > 1
            ? 1
            : echelleMinimaleLisible,
      );
    }
    // Depliee : 12 (ou 8) de chaque cote de l'item, 12 dans la pastille,
    // l'icone et l'ecart de 12.
    final double largeur =
        AppGabarit.largeurBarreLaterale -
        2 * AppSpacing.md -
        2 * AppSpacing.md -
        (guide ? AppSpacing.xxxl : AppSpacing.xxl) -
        AppSpacing.md;
    return _commune(
      context,
      libelles,
      MediaQuery.textScalerOf(context),
      largeur,
      AppTypography.graisse(
        textes.bodyLarge ?? const TextStyle(),
        guide ? FontWeight.w700 : FontWeight.w600,
      ),
      plancher: 1,
    );
  }
}

/// [echelleCommuneSansCoupure] a partir de l'echelle [depart] (deja
/// plafonnee) plutot que de celle du contexte.
TextScaler _commune(
  BuildContext context,
  List<String> libelles,
  TextScaler depart,
  double largeur,
  TextStyle style, {
  required double plancher,
}) {
  final TextScaler commune = echelleCommuneSansCoupure(
    context,
    textes: libelles,
    largeurs: <double>[largeur],
    style: style,
    plancher: plancher,
  );
  final double f = commune.scale(1);
  final double d = depart.scale(1);
  return f < d ? TextScaler.linear(f) : depart;
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
            // COUPE-MOTS-1 : plus de « Reway... » a 1440 px et 200 % ; le
            // nom de l'application reduit son echelle pour tenir en entier.
            child: Semantics(
              header: true,
              child: TexteSansCoupure(
                t.nav.motSymbole,
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
    required this.guide,
    required this.onPress,
  });

  final Destination destination;
  final bool actif;
  final bool repliee;

  /// Replie, le nom reste visible sous l'icone (eleve, enseignant), au lieu
  /// de l'infobulle seule (tuteur). Sans effet quand la colonne est depliee.
  final bool libelleSousIcone;

  /// Mode Accessibilite : cible de 72, icone de 32, fond plein a l'etat actif
  /// dans les deux themes, encre forte au repos (MA-NAV-1).
  final bool guide;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool sombre = palette.estSombre;

    final AppMetriques metriques = _metriques(context);
    // Guide : fond plein et encre posee dessus dans les deux themes ; au repos
    // l'icone prend l'encre forte comme le libelle (contraste renforce).
    final Color? fond = !actif
        ? null
        : guide
        ? palette.surfacePrimary.background
        : sombre
        ? palette.surfacePrimary.background
        : palette.washAccent.background;
    final Color couleurIcone = !actif
        ? (guide ? palette.inkStrong : palette.inkMuted).asBorderSide().color
        : guide || sombre
        ? palette.surfacePrimary.onBackground
        : palette.inkAccent.asBorderSide().color;
    final Color couleurLibelle = !actif
        ? palette.inkStrong.asBorderSide().color
        : guide || sombre
        ? palette.surfacePrimary.onBackground
        : palette.inkAccent.asBorderSide().color;

    final Widget icone = IconTheme(
      data: IconThemeData(
        color: couleurIcone,
        size: guide ? AppSpacing.xxxl : AppSpacing.xxl,
      ),
      child: Icon(destination.icone.resoudre(selectionne: actif)),
    );

    final Widget pastille = DecoratedBox(
      decoration: BoxDecoration(
        color: fond,
        borderRadius: guide ? metriques.arrondiInterieur : AppRadius.arrondiSm,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: metriques.cibleTactile,
          minWidth: metriques.cibleTactile,
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
                      child: TexteSansCoupure(
                        destination.libelle,
                        style: AppTypography.graisse(
                          textes.bodyLarge ?? const TextStyle(),
                          actif
                              ? (guide ? FontWeight.w700 : FontWeight.w600)
                              : (guide ? FontWeight.w600 : FontWeight.w500),
                        ).copyWith(color: couleurLibelle),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

    if (repliee && libelleSousIcone && guide) {
      // Rail du Mode Accessibilite : l'item entier est le bloc plein de l'etat
      // actif (icone, libelle), cible de 72 au moins, libelle jusqu'a trois
      // lignes et sans plafond de texte.
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
            arrondiFocus: metriques.arrondiInterieur,
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fond,
                  borderRadius: metriques.arrondiInterieur,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: metriques.cibleTactile,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        icone,
                        Ecart.vXs,
                        // Echelle commune du rail, deja plafonnee a 1,3
                        // (`_Colonne`) : entre les mots, jamais dans un mot.
                        TexteSansCoupure(
                          destination.libelle,
                          textAlign: TextAlign.center,
                          style: AppTypography.graisse(
                            textes.labelLarge ?? const TextStyle(),
                            actif ? FontWeight.w700 : FontWeight.w600,
                          ).copyWith(color: couleurLibelle),
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
                  // COUPE-MOTS-1 (VERIF-CT-2) : plus de « Contr... Histori... »
                  // a 768 px et 200 % : l'echelle commune du rail
                  // (`_Colonne`, plafonnee a 1,5) fait tenir chaque mot.
                  TexteSansCoupure(
                    destination.libelle,
                    textAlign: TextAlign.center,
                    style: (textes.labelMedium ?? const TextStyle()).copyWith(
                      color: !actif
                          ? palette.inkMuted.asBorderSide().color
                          : palette.inkAccent.asBorderSide().color,
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
        arrondiFocus: guide ? metriques.arrondiInterieur : AppRadius.arrondiSm,
        child: ExcludeSemantics(child: pastille),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: repliee ? AppSpacing.lg : AppSpacing.md,
        vertical: guide ? AppSpacing.sm : AppSpacing.xs,
      ),
      child: repliee
          ? Tooltip(message: destination.libelle, child: pressable)
          : pressable,
    );
  }
}

/// Les mesures du theme, ou celles du mode standard quand le theme n'en porte
/// pas (un test qui monte la coquille sans `AppTheme`).
AppMetriques _metriques(BuildContext context) =>
    Theme.of(context).extension<AppMetriques>() ??
    AppMetriques.pour(InterfaceMode.standard);
