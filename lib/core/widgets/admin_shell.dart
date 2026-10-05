import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../admin/admin_domaine.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_bottom_sheet.dart';
import 'avatar_nom.dart';
import 'bascule_theme.dart';
import 'page_shell.dart';
import 'pressable.dart';

/// La coquille de navigation du panneau admin : huit domaines, jamais plus
/// granulaire (gel d'architecture, `docs/archive/2026-09-pre-remise-a-plat/architecture/ADMIN_IA_AUDIT.md`).
///
/// **Distincte de `NavShell`**, qui plafonne a quatre destinations pour les
/// autres roles (`03-architecture-information.md` section 5) -- une limite
/// pensee pour le MVP. L'operateur a tranche que le panneau admin grandira
/// avec un RBAC a plusieurs roles, et qu'une barre a quatre entrees n'y
/// suffit plus. La regle qui reste absolue n'est plus « quatre » mais
/// « jamais plus granulaire que les huit domaines eux-memes » -- voir
/// [maxDomaines], qui la tient par un `assert` vivant, pas par une relecture.
///
/// **Un domaine sans fonction livree reste visible mais inerte** : l'audit
/// interdit explicitement de construire un ecran vide pour remplir le
/// chrome (`AdminDomaine.chemin` est alors nul). Le libelle et l'icone sont
/// rendus attenues, et un tap n'y declenche aucune navigation -- le meme
/// traitement qu'un compteur d'`ADM-01` sans destination, jamais un bouton
/// grise qui mentirait sur ce que la personne peut obtenir.
///
/// Trois formes, une seule liste de domaines : tiroir sous 600, rail replie
/// de 600 a 1199, barre laterale permanente a partir de 1200. **Jamais de
/// barre basse ici** : la mission l'interdit explicitement pour l'admin,
/// huit domaines n'y tiendraient pas.
///
/// **En-tete (AD-S, maquette 02A)** : a partir de 600, aucune barre
/// superieure. Les actions de la coquille (Recherche, bascule de theme,
/// compte) se posent a droite de l'en-tete de chaque page par
/// [ActionsEnteteCoquille], a cote du titre et du sous-titre de la page.
/// Sous 600, une barre mobile garde Menu, le champ de recherche et le
/// compte. Pas de cloche tant qu'aucun service de notifications n'existe
/// (Q5) : [cloche] n'est fournie que lorsque la capacite « alertes » rend
/// quelque chose (ALERTE-1), et se pose alors avant le compte, sur toutes
/// les formes. Chaque page recoit aussi le retour vers l'Accueil
/// ([onRetour]).
class AdminShell extends StatelessWidget {
  /// Cree la coquille admin.
  ///
  /// **Volontairement non `const`**, meme raison que `NavShell` : l'assertion
  /// porte sur la longueur d'une liste, qui n'est pas une expression
  /// constante.
  // ignore: prefer_const_constructors_in_immutables
  AdminShell({
    required this.domaines,
    required this.domaineActif,
    required this.onAller,
    required this.onCompte,
    required this.child,
    super.key,
    this.onRetour,
    this.cloche,
    this.bandeau,
  }) : assert(
         domaines.length <= maxDomaines,
         'La sidebar admin ne contient jamais plus de $maxDomaines domaines '
         '(gel d\'architecture, regle absolue).',
       );

  /// Les domaines visibles, dans l'ordre impose.
  final List<AdminDomaine> domaines;

  /// Le domaine actif, pour le surligner.
  final AdminDomaine? domaineActif;

  /// Ce qui se passe quand un domaine actif ou un resultat de recherche est
  /// choisi. Recoit une route, jamais un domaine : la recherche peut mener a
  /// un ecran qu'aucun libelle de domaine ne nomme.
  final void Function(String chemin) onAller;

  /// Ouvre « Mon compte », partage par tous les roles.
  final VoidCallback onCompte;

  /// Le retour pose sur chaque page de la coquille (spec section 26 ter,
  /// Q14) : vers l'Accueil, nul sur l'Accueil lui-meme.
  final VoidCallback? onRetour;

  /// La cloche des alertes, ou `null` sans capacite « alertes » (Q5).
  final Widget? cloche;

  /// Le bandeau pose tout en haut de chaque page : l'alerte urgente
  /// (ALERTE-1). Nul : aucun.
  ///
  /// **Fige au-dessus de la page, jamais dans sa tete** (ALERTE-1b) : la
  /// coquille le pose au-dessus de la page ouverte, hors de la zone qui
  /// defile. Il reste en vue tant que l'alerte est ouverte, et pousse la page
  /// vers le bas sans jamais la recouvrir (« tout en haut de l'ecran,
  /// jusqu'a ce qu'elle soit traitee », decision du 05/10). Sa hauteur est
  /// bornee a la moitie de la vue : au-dela (vue tres basse, texte a 400 %),
  /// il defile dans sa propre zone et la page garde l'autre moitie
  /// (WCAG 1.4.10).
  final Widget? bandeau;

  /// L'ecran affiche.
  final Widget child;

  /// Le nombre maximal de domaines. **Huit, pas quatre** : la regle du gel
  /// d'architecture, distincte de `NavShell.maxDestinations`.
  static const int maxDomaines = 8;

  /// Cles stables pour verifier les trois presentations adaptatives.
  static const Key tiroirKey = ValueKey<String>('admin-shell-tiroir');
  static const Key railKey = ValueKey<String>('admin-shell-rail');
  static const Key barreLateraleKey = ValueKey<String>(
    'admin-shell-barre-laterale',
  );

  /// Largeur de la barre laterale permanente.
  ///
  /// **Plus large que `AppGabarit.largeurBarreLaterale` (256)**, et
  /// volontairement independante de ce jeton partage par les quatre autres
  /// roles : leurs libelles tiennent en un mot (« Journee », « Profil »), les
  /// huit domaines admin comptent plusieurs libelles a deux ou trois mots
  /// (« Sécurité et audit », « Configuration »), qui debordent a 256. Poser
  /// ici une largeur propre a `AdminShell` evite d'elargir la barre des
  /// quatre autres roles pour un besoin qui n'est que le sien.
  static const double largeurBarreLaterale = 288;

  @override
  Widget build(BuildContext context) {
    final int trouve = domaineActif == null
        ? -1
        : domaines.indexOf(domaineActif!);
    final int? actif = trouve == -1 ? null : trouve;

    final ChromeNavigation chrome = AppGabarit.de(context).chrome;

    void choisir(int index) {
      final String? chemin = domaines[index].chemin;
      // Un domaine inerte ne navigue nulle part : construire un ecran vide
      // pour l'occasion est exactement ce que l'audit interdit.
      if (chemin != null) {
        onAller(chemin);
      }
    }

    // Les actions de l'en-tete de page, a partir de 600 : Recherche, theme,
    // compte, dans cet ordre (maquette 02A).
    //
    // ALERTE-1b : le bandeau n'est plus confie a `PageShell` (sa tete defile
    // avec le corps des que le bandeau y est, et le bandeau sortait de la
    // vue) ; il est pose ici, au-dessus de la page, par [_ZoneBandeau].
    Widget contenu({required bool avecActions}) {
      final Widget page = ActionsEnteteCoquille(
        actions: <Widget>[
          if (avecActions) ...<Widget>[
            _BoutonRecherche(onRecherche: onAller),
            const BasculeTheme(),
            ?cloche,
            _BoutonCompte(onCompte: onCompte),
          ],
        ],
        onRetour: onRetour,
        child: child,
      );
      return switch (bandeau) {
        null => page,
        final Widget b => _ZoneBandeau(
          bandeau: b,
          // Sous 600, la barre mobile tient deja le haut de l'ecran (et sa
          // marge de securite) : le bandeau se pose sous elle.
          sousBarre: chrome == ChromeNavigation.barreBasse,
          child: page,
        ),
      };
    }

    // **Un seul `Scaffold`, quel que soit le gabarit.** La barre mobile porte
    // un `TextField`, qui exige un ancetre `Material` ; le mobile a de toute
    // facon besoin d'un `Scaffold` pour son tiroir ouvrable.
    return Scaffold(
      drawer: chrome == ChromeNavigation.barreBasse
          ? _Tiroir(
              domaines: domaines,
              indexActif: actif,
              onChoisir: choisir,
              onCompte: onCompte,
            )
          : null,
      body: switch (chrome) {
        ChromeNavigation.barreBasse => Column(
          children: <Widget>[
            _BarreMobile(
              onRecherche: onAller,
              onCompte: onCompte,
              cloche: cloche,
            ),
            Expanded(child: contenu(avecActions: false)),
          ],
        ),
        ChromeNavigation.rail => Row(
          children: <Widget>[
            _Rail(domaines: domaines, indexActif: actif, onChoisir: choisir),
            Expanded(child: contenu(avecActions: true)),
          ],
        ),
        ChromeNavigation.barreLaterale => Row(
          children: <Widget>[
            _Sidebar(
              domaines: domaines,
              indexActif: actif,
              onChoisir: choisir,
              onCompte: onCompte,
            ),
            // Un panneau contextuel pourra prendre place a droite du contenu
            // le jour ou un ecran en aura besoin. Rien n'en a besoin
            // aujourd'hui : ce commentaire tient la place, pas un widget vide.
            Expanded(child: contenu(avecActions: true)),
          ],
        ),
      },
    );
  }
}

/// La zone du bandeau d'alerte urgente (ALERTE-1b) : le bandeau fige en
/// haut, la page dessous, dans la hauteur qui reste.
///
/// Le bandeau prend la gouttiere et la largeur bornee de la colonne de page
/// (`PageShell`), pour s'aligner sur le titre. Sa hauteur ne depasse jamais
/// la moitie de la vue : au-dela, il defile dans sa zone.
class _ZoneBandeau extends StatelessWidget {
  const _ZoneBandeau({
    required this.bandeau,
    required this.sousBarre,
    required this.child,
  });

  final Widget bandeau;
  final bool sousBarre;
  final Widget child;

  /// La part maximale de la hauteur que le bandeau occupe.
  static const double partMaximale = 0.5;

  @override
  Widget build(BuildContext context) {
    final double gouttiere = AppGabarit.de(context).gouttiere;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SafeArea(
            top: !sousBarre,
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: contraintes.maxHeight * partMaximale,
              ),
              child: SingleChildScrollView(
                child: Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppPage.largeurMaxContenu,
                    ),
                    child: Padding(
                      // Directionnel : en arabe, la gouttiere de debut est a
                      // droite. 8 sous le bandeau, avant la tete de la page.
                      padding: EdgeInsetsDirectional.only(
                        start: gouttiere,
                        end: gouttiere,
                        bottom: AppSpacing.sm,
                      ),
                      child: bandeau,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            // La marge de securite du haut est deja prise au-dessus du
            // bandeau : la page ne la reprend pas.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: !sousBarre,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// La route que vise une saisie de recherche, ou nulle.
///
/// Une recherche de navigation, pas une recherche metier.
///
/// ponytail : correspondance simple, premiere sous-chaine trouvee dans une
/// liste fixe de moins de dix libelles. Pas de classement ni de tolerance aux
/// fautes de frappe -- une liste de cette taille n'en a pas besoin, et aucune
/// donnee n'est interrogee, seulement des libelles et leurs routes.
String? _cheminRecherche(String saisie) {
  final String requete = saisie.trim().toLowerCase();
  if (requete.isEmpty) {
    return null;
  }
  for (final ({String libelle, String chemin}) cible in ciblesRechercheAdmin(
    voitDirection: false,
  )) {
    if (cible.libelle.toLowerCase().contains(requete)) {
      return cible.chemin;
    }
  }
  return null;
}

/// Une entree de navigation, libelle sur une seule ligne, jamais debordant.
///
/// Attenuee quand le domaine est inerte (aucune fonction livree) : ni gris de
/// bouton desactive, ni ecran vide derriere -- juste une encre plus discrete
/// pour dire « pas encore », comme un compteur d'`ADM-01` sans destination.
/// Retrait horizontal par defaut d'une tuile de NavigationDrawer.
const double _retraitTuileNav = 12;

/// Hauteur d'une ligne de labelMedium a 100 % (M3 : 16).
const double _hauteurLibelleNav = 16;

Widget _libelleEntree(
  AppPalette palette,
  AdminDomaine domaine, {
  int lignes = 1,
}) => Text(
  domaine.libelle,
  overflow: TextOverflow.ellipsis,
  maxLines: lignes,
  softWrap: lignes > 1,
  style: domaine.actif
      ? null
      : TextStyle(color: palette.inkFaint.asBorderSide().color),
);

Widget _iconeEntree(
  AppPalette palette,
  AdminDomaine domaine, {
  required bool selectionnee,
}) {
  final Color? couleur = domaine.actif
      ? null
      : palette.inkFaint.asBorderSide().color;
  return Icon(
    selectionnee ? domaine.icone.actif : domaine.icone.repos,
    color: couleur,
  );
}

/// L'info-bulle du rail : le libelle complet, au survol ou a l'appui long.
/// Hors semantique : le libelle de la destination l'annonce deja.
Widget _infoBulle(AdminDomaine domaine, Widget icone) =>
    Tooltip(message: domaine.libelle, excludeFromSemantics: true, child: icone);

/// La tete du tiroir et de la barre laterale : le mot-symbole.
class _TeteNavigation extends StatelessWidget {
  const _TeteNavigation();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Text(
        t.nav.motSymbole,
        style: AppPalette.of(context).inkStrong.applyTo(
          Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Le pied du tiroir et de la barre laterale : qui est connecte, et le
/// chemin vers « Mon compte ». La session ne porte pas de nom : le texte est
/// celui du role, cle existante (« Administrateur », initiale « A »). La
/// maquette 02A montre « AD · Admin » : ecart soumis au directeur (question
/// Q-S4 du concepteur), aucune cle creee sans son accord.
class _PiedUtilisateur extends StatelessWidget {
  const _PiedUtilisateur({required this.onCompte});

  final VoidCallback onCompte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String nom = t.compte.roles.admin;
    final String role = t.admin.comptes.roleAdmin;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: palette.borderHairline.asBorderSide()),
      ),
      child: Pressable(
        onPress: onCompte,
        libelleSemantique: '$nom, $role',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // AD-11 (1.4.4) : nom et role jamais coupes a 200 %, ils passent
            // a la ligne. AVATAR-1 : couple avatar + nom du composant partage.
            child: AvatarNom.enLigne(
              prenom: nom,
              role: role,
              styleNom: textes.titleSmall,
              styleRole: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le tiroir mobile : les huit domaines, dans une vraie modale ouvrable.
class _Tiroir extends StatelessWidget {
  const _Tiroir({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
    required this.onCompte,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;
  final VoidCallback onCompte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // AD-11 (1.4.10) : l'indicateur M3 mesure 336 de large (tiroir de 360) ;
    // a 320 de large (1280 a 400 %), il deborderait de 40. Il suit donc la
    // largeur de la vue, retrait de tuile compris.
    final double largeurIndicateur =
        (MediaQuery.sizeOf(context).width - 2 * _retraitTuileNav)
            .clamp(0, 336)
            .toDouble();
    // AD-11 (1.4.4) : a 200 %, un libelle ne tient plus sur une ligne dans la
    // rangee M3 (non flexible) et la faisait deborder. Il passe a deux lignes
    // flexibles, et la tuile grandit d'autant : 2 lignes de 20 + 16 = 56 a
    // 100 %, soit la hauteur M3 inchangee.
    final double hauteurTuile = math.max(
      56,
      2 * MediaQuery.textScalerOf(context).scale(20) + 16,
    );

    return NavigationDrawerTheme(
      data: NavigationDrawerThemeData(
        tileHeight: hauteurTuile,
        indicatorSize: Size(largeurIndicateur, hauteurTuile),
        labelTextStyle: _stylesLibelleNav(context, palette),
        iconTheme: _stylesIconeNav(palette),
      ),
      child: NavigationDrawer(
        key: AdminShell.tiroirKey,
        selectedIndex: indexActif,
        backgroundColor: palette.surfaceRaised.background,
        indicatorColor: palette.washAccent.background,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.arrondiSm,
        ),
        onDestinationSelected: (int index) {
          Navigator.of(context).pop();
          onChoisir(index);
        },
        children: <Widget>[
          const _TeteNavigation(),
          for (final AdminDomaine domaine in domaines)
            NavigationDrawerDestination(
              icon: _iconeEntree(palette, domaine, selectionnee: false),
              selectedIcon: _iconeEntree(palette, domaine, selectionnee: true),
              // Flexible : enfant direct de la rangee M3 (DefaultTextStyle
              // n'a pas d'objet de rendu).
              label: Flexible(
                child: _libelleEntree(palette, domaine, lignes: 2),
              ),
            ),
          Ecart.vLg,
          _PiedUtilisateur(
            onCompte: () {
              Navigator.of(context).pop();
              onCompte();
            },
          ),
        ],
      ),
    );
  }
}

/// Le rail replie, de 600 a 1199 : icone seule, libelle en info-bulle et en
/// semantique. Ni tete ni pied : 80 est trop etroit.
///
/// Les libelles complets (« Opérations », « Configuration ») ne tiennent pas
/// en 80 sans points de suspension, et aucun libelle court n'existe dans les
/// traductions : plutot que d'en inventer un, le rail n'affiche que l'icone
/// (revue AD-S, ecart soumis au directeur). Le libelle reste dans l'arbre
/// semantique (`NavigationRailLabelType.none` le garde, invisible).
class _Rail extends StatelessWidget {
  const _Rail({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle();

    return SizedBox(
      key: AdminShell.railKey,
      width: AppGabarit.largeurRail,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          border: BorderDirectional(end: palette.borderHairline.asBorderSide()),
        ),
        child: SafeArea(
          child: NavigationRail(
            selectedIndex: indexActif,
            onDestinationSelected: onChoisir,
            backgroundColor: palette.surfaceRaised.background,
            minWidth: AppGabarit.largeurRail,
            labelType: NavigationRailLabelType.none,
            scrollable: true,
            groupAlignment: -1,
            useIndicator: true,
            indicatorColor: palette.washAccent.background,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: AppRadius.arrondiSm,
            ),
            // L'etat actif ne passe pas par la couleur seule (spec section
            // 20) : la graisse le porte aussi.
            selectedLabelTextStyle: base.copyWith(
              color: palette.inkAccent.asBorderSide().color,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: base.copyWith(
              color: palette.inkMuted.asBorderSide().color,
            ),
            selectedIconTheme: palette.inkAccent.asIconTheme(
              size: AppSpacing.xxl,
            ),
            unselectedIconTheme: palette.inkMuted.asIconTheme(
              size: AppSpacing.xxl,
            ),
            destinations: <NavigationRailDestination>[
              for (final AdminDomaine domaine in domaines)
                NavigationRailDestination(
                  icon: _infoBulle(
                    domaine,
                    _iconeEntree(palette, domaine, selectionnee: false),
                  ),
                  selectedIcon: _infoBulle(
                    domaine,
                    _iconeEntree(palette, domaine, selectionnee: true),
                  ),
                  label: _libelleEntree(palette, domaine),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La barre laterale permanente, a partir de 1200 : mot-symbole, libelles
/// complets, pied utilisateur.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.domaines,
    required this.indexActif,
    required this.onChoisir,
    required this.onCompte,
  });

  final List<AdminDomaine> domaines;
  final int? indexActif;
  final void Function(int index) onChoisir;
  final VoidCallback onCompte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double cible = AppMetriques.of(context).cibleTactile;
    // Deux lignes de libelle a l'echelle courante, jamais moins que la cible.
    final double hauteurTuile = math.max(
      cible,
      MediaQuery.textScalerOf(context).scale(_hauteurLibelleNav) * 2 +
          AppSpacing.md,
    );
    // Retraits du tiroir (12 de chaque cote), puis 16, icone, 12 (Flutter).
    const double largeurTuile =
        AdminShell.largeurBarreLaterale - _retraitTuileNav * 2;
    const double largeurLibelle =
        largeurTuile -
        AppSpacing.lg -
        AppSpacing.xxl -
        AppSpacing.md -
        AppSpacing.lg;

    return SizedBox(
      key: AdminShell.barreLateraleKey,
      width: AdminShell.largeurBarreLaterale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          border: BorderDirectional(end: palette.borderHairline.asBorderSide()),
        ),
        child: SafeArea(
          child: Material(
            color: palette.surfaceRaised.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: NavigationDrawerTheme(
                    data: NavigationDrawerThemeData(
                      // La tuile grandit avec le texte (200 %) : le libelle
                      // passe sur deux lignes au lieu de deborder.
                      tileHeight: hauteurTuile,
                      indicatorSize: Size(largeurTuile, hauteurTuile),
                      labelTextStyle: _stylesLibelleNav(context, palette),
                      iconTheme: _stylesIconeNav(palette),
                    ),
                    child: NavigationDrawer(
                      selectedIndex: indexActif,
                      backgroundColor: palette.surfaceRaised.background,
                      indicatorColor: palette.washAccent.background,
                      indicatorShape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.arrondiSm,
                      ),
                      onDestinationSelected: onChoisir,
                      children: <Widget>[
                        const _TeteNavigation(),
                        for (final AdminDomaine domaine in domaines)
                          NavigationDrawerDestination(
                            icon: _iconeEntree(
                              palette,
                              domaine,
                              selectionnee: false,
                            ),
                            selectedIcon: _iconeEntree(
                              palette,
                              domaine,
                              selectionnee: true,
                            ),
                            // La rangee du tiroir ne borne pas son libelle :
                            // largeur explicite, sinon il deborde a 200 %.
                            label: SizedBox(
                              width: largeurLibelle,
                              child: _libelleEntree(
                                palette,
                                domaine,
                                lignes: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _PiedUtilisateur(onCompte: onCompte),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

WidgetStateProperty<TextStyle?> _stylesLibelleNav(
  BuildContext context,
  AppPalette palette,
) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  // L'etat actif ne passe pas par la couleur seule (spec section 20) : la
  // graisse le porte aussi, sur le fond discret `washAccent`.
  return WidgetStateProperty.resolveWith<TextStyle?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? base.copyWith(
            color: palette.inkAccent.asBorderSide().color,
            fontWeight: FontWeight.w600,
          )
        : base.copyWith(color: palette.inkMuted.asBorderSide().color),
  );
}

WidgetStateProperty<IconThemeData?> _stylesIconeNav(AppPalette palette) {
  return WidgetStateProperty.resolveWith<IconThemeData?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
        : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
  );
}

/// Un bouton icone de l'en-tete : cible de 48, meme anatomie que
/// `ClocheNotifications`.
class _BoutonIcone extends StatelessWidget {
  const _BoutonIcone({
    required this.icone,
    required this.libelle,
    required this.onPress,
  });

  final IconData icone;
  final String libelle;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Center(
            child: IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
              child: Icon(icone),
            ),
          ),
        ),
      ),
    );
  }
}

/// « Mon compte » : la deconnexion y est, donc atteignable partout.
class _BoutonCompte extends StatelessWidget {
  const _BoutonCompte({required this.onCompte});

  final VoidCallback onCompte;

  @override
  Widget build(BuildContext context) => _BoutonIcone(
    icone: AppIcons.profil.repos,
    libelle: t.nav.compte,
    onPress: onCompte,
  );
}

/// La recherche a partir de 600 : un bouton qui ouvre le champ existant dans
/// une feuille (Q-S2). Aucune largeur inventee dans l'en-tete.
class _BoutonRecherche extends StatelessWidget {
  const _BoutonRecherche({required this.onRecherche});

  final void Function(String chemin) onRecherche;

  Future<void> _ouvrir(BuildContext context) async {
    final String? chemin = await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.nav.admin.recherche,
      constructeur: (BuildContext contexte) => TextField(
        autofocus: true,
        onSubmitted: (String saisie) {
          final String? cible = _cheminRecherche(saisie);
          if (cible != null) {
            Navigator.of(contexte).pop(cible);
          }
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: t.nav.admin.rechercheIndication,
          hintMaxLines: 2,
          prefixIcon: Icon(AppIcons.recherche.repos),
        ),
      ),
    );
    if (chemin != null) {
      onRecherche(chemin);
    }
  }

  @override
  Widget build(BuildContext context) => _BoutonIcone(
    icone: AppIcons.recherche.repos,
    libelle: t.nav.admin.recherche,
    onPress: () => unawaited(_ouvrir(context)),
  );
}

/// La barre mobile, sous 600 : menu, recherche, compte.
///
/// **Rien d'autre n'y vit** : ni reglage, ni eleve, ni groupe, ni bouton
/// metier isole.
class _BarreMobile extends StatefulWidget {
  const _BarreMobile({
    required this.onRecherche,
    required this.onCompte,
    this.cloche,
  });

  final void Function(String chemin) onRecherche;
  final VoidCallback onCompte;
  final Widget? cloche;

  @override
  State<_BarreMobile> createState() => _BarreMobileState();
}

class _BarreMobileState extends State<_BarreMobile> {
  final TextEditingController _recherche = TextEditingController();

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _lancer(String saisie) {
    final String? chemin = _cheminRecherche(saisie);
    if (chemin != null) {
      widget.onRecherche(chemin);
      _recherche.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    // AD-11 (1.4.4) : au-dela de 150 % de texte, le champ en ligne n'a plus
    // la place de montrer son indication entiere entre menu et compte ; la
    // barre prend alors le bouton qui ouvre le meme champ en feuille (motif
    // deja servi a partir de 600). Rendu inchange a 100 %.
    final bool texteAgrandi = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Builder(
                builder: (BuildContext contexte) => _BoutonIcone(
                  icone: AppIcons.menu.repos,
                  libelle: t.nav.admin.menu,
                  onPress: () => Scaffold.of(contexte).openDrawer(),
                ),
              ),
              Ecart.hSm,
              if (texteAgrandi) ...<Widget>[
                const Spacer(),
                _BoutonRecherche(onRecherche: widget.onRecherche),
              ] else
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppPage.largeurFormulaire,
                    ),
                    child: TextField(
                      controller: _recherche,
                      onSubmitted: _lancer,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: t.nav.admin.rechercheIndication,
                        // AD-11 (1.4.4) : a 200 %, l'indication passe a la
                        // ligne au lieu d'etre coupee.
                        hintMaxLines: 2,
                        prefixIcon: Icon(AppIcons.recherche.repos),
                      ),
                    ),
                  ),
                ),
              Ecart.hSm,
              if (widget.cloche case final Widget cloche) ...<Widget>[
                cloche,
                Ecart.hSm,
              ],
              _BoutonCompte(onCompte: widget.onCompte),
            ],
          ),
        ),
      ),
    );
  }
}
