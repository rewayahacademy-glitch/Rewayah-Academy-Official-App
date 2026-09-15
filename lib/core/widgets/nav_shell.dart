import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../router/routes.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Une destination de premier niveau.
@immutable
class Destination {
  /// Cree une destination.
  const Destination({
    required this.libelle,
    required this.icone,
    required this.chemin,
  });

  /// Le libelle affiche et lu.
  final String libelle;

  /// L'icone, dans ses deux graisses : `regular` au repos, `fill` a l'etat
  /// actif.
  final AppIcon icone;

  /// Le chemin de la route. C'est ce que [NavShell] rend a l'appelant.
  final String chemin;
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
    AppRole.guardian => <Destination>[
      Destination(
        libelle: t.nav.tuteur.accueil,
        icone: AppIcons.foyer,
        chemin: Routes.tuteurAccueil,
      ),
      Destination(
        libelle: t.nav.tuteur.disponibilites,
        icone: AppIcons.disponibilites,
        chemin: Routes.tuteurDisponibilites,
      ),
      Destination(
        libelle: t.nav.tuteur.reglages,
        icone: AppIcons.reglages,
        chemin: Routes.tuteurReglages,
      ),
      Destination(
        libelle: t.nav.tuteur.suivi,
        icone: AppIcons.suivi,
        chemin: Routes.tuteurSuivi,
      ),
    ],
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
      Destination(
        libelle: t.nav.enseignant.compte,
        icone: AppIcons.reglages,
        chemin: Routes.compte,
      ),
    ],
    // L'admin tient quatre destinations : les demandes (ADM-06) restent
    // atteintes depuis leur compteur et la liste a traiter, jamais depuis la
    // barre, ou cinq entrees feraient un menu (section 5).
    AppRole.admin => <Destination>[
      Destination(
        libelle: t.nav.admin.tableauDeBord,
        icone: AppIcons.tableauDeBord,
        chemin: Routes.adminTableauDeBord,
      ),
      Destination(
        libelle: t.nav.admin.dossiers,
        icone: AppIcons.dossiers,
        chemin: Routes.adminDossiers,
      ),
      Destination(
        libelle: t.nav.admin.attribution,
        icone: AppIcons.attribution,
        chemin: Routes.adminAttribution,
      ),
      Destination(
        libelle: t.nav.admin.journal,
        icone: AppIcons.journal,
        chemin: Routes.adminJournal,
      ),
    ],
    // Le controleur observe et signale : une seule destination, qui ne monte
    // pas de barre. Le comptable est hors de l'arborescence en MVP-0 (ADR-003).
    AppRole.controller || AppRole.accountant => const <Destination>[],
  };

  assert(
    destinations.length <= NavShell.maxDestinations,
    'Aucun role n a plus de ${NavShell.maxDestinations} destinations de '
    'premier niveau (03-architecture-information.md section 5).',
  );
  return destinations;
}

/// La navigation de premier niveau, dans ses trois formes.
///
/// **Une seule liste de destinations alimente les trois formes** : barre basse
/// sous 600, rail de 600 a 1199, barre laterale a partir de 1200
/// (`docs/design/03-architecture-information.md` section 5). Trois listes
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
class NavShell extends StatelessWidget {
  /// Cles stables pour verifier les trois presentations adaptatives du shell.
  static const Key barreBasseKey = ValueKey<String>('nav-shell-barre-basse');
  static const Key railKey = ValueKey<String>('nav-shell-rail');
  static const Key barreLateraleKey = ValueKey<String>(
    'nav-shell-barre-laterale',
  );

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
    super.key,
  }) : assert(
         destinations.length <= maxDestinations,
         'Aucun role n a plus de $maxDestinations destinations de premier '
         'niveau : au dela, la barre devient un menu '
         '(03-architecture-information.md section 5).',
       ),
       assert(
         indexActif >= 0 && indexActif < destinations.length ||
             destinations.isEmpty,
         'La destination active doit exister dans la liste.',
       );

  /// Les destinations du role courant.
  final List<Destination> destinations;

  /// L'index de la destination courante.
  final int indexActif;

  /// Ce qui se passe quand une destination est choisie. Recoit son chemin.
  final void Function(String chemin) onAller;

  /// L'ecran affiche.
  final Widget child;

  /// Le nombre maximal de destinations de premier niveau.
  static const int maxDestinations = 4;

  @override
  Widget build(BuildContext context) {
    // Moins de deux destinations : il n'y a rien a choisir, donc rien a
    // afficher. Une barre a une seule entree n'est pas une navigation, c'est
    // un titre.
    if (destinations.length < 2) {
      return child;
    }

    return switch (AppGabarit.de(context).chrome) {
      ChromeNavigation.barreBasse => Column(
        children: <Widget>[
          Expanded(child: child),
          _Barre(
            destinations: destinations,
            indexActif: indexActif,
            onAller: onAller,
          ),
        ],
      ),
      ChromeNavigation.rail => Row(
        children: <Widget>[
          _Cote(
            destinations: destinations,
            indexActif: indexActif,
            onAller: onAller,
            largeur: AppGabarit.largeurRail,
            enColonne: true,
          ),
          Expanded(child: child),
        ],
      ),
      ChromeNavigation.barreLaterale => Row(
        children: <Widget>[
          _Cote(
            destinations: destinations,
            indexActif: indexActif,
            onAller: onAller,
            largeur: AppGabarit.largeurBarreLaterale,
            enColonne: false,
          ),
          Expanded(child: child),
        ],
      ),
    };
  }
}

/// La barre basse Material 3 : une surface elevee, collee sous le contenu.
class _Barre extends StatelessWidget {
  const _Barre({
    required this.destinations,
    required this.indexActif,
    required this.onAller,
  });

  final List<Destination> destinations;
  final int indexActif;
  final void Function(String chemin) onAller;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return KeyedSubtree(
      key: NavShell.barreBasseKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          border: Border(top: palette.borderHairline.asBorderSide()),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: _stylesLibelleNavigation(context, palette),
            iconTheme: _stylesIconeNavigation(palette),
          ),
          child: NavigationBar(
            selectedIndex: indexActif,
            onDestinationSelected: (int index) {
              onAller(destinations[index].chemin);
            },
            backgroundColor: palette.surfaceRaised.background,
            indicatorColor: palette.washAccent.background,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: AppRadius.arrondiSm,
            ),
            labelPadding: const EdgeInsets.only(top: AppSpacing.xs),
            destinations: <Widget>[
              for (final Destination destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icone.repos),
                  selectedIcon: Icon(destination.icone.actif),
                  label: destination.libelle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le rail Material 3 : la meme liste de destinations que la barre basse.
class _Cote extends StatelessWidget {
  const _Cote({
    required this.destinations,
    required this.indexActif,
    required this.onAller,
    required this.largeur,
    required this.enColonne,
  });

  final List<Destination> destinations;
  final int indexActif;
  final void Function(String chemin) onAller;
  final double largeur;
  final bool enColonne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    final Widget chrome = enColonne
        ? NavigationRail(
            selectedIndex: indexActif,
            onDestinationSelected: (int index) {
              onAller(destinations[index].chemin);
            },
            backgroundColor: palette.surfaceRaised.background,
            minWidth: AppGabarit.largeurRail,
            labelType: NavigationRailLabelType.all,
            scrollable: true,
            groupAlignment: -1,
            useIndicator: true,
            indicatorColor: palette.washAccent.background,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: AppRadius.arrondiSm,
            ),
            selectedLabelTextStyle: _styleLibelleSelectionne(context, palette),
            unselectedLabelTextStyle: _styleLibelleNonSelectionne(
              context,
              palette,
            ),
            selectedIconTheme: palette.inkAccent.asIconTheme(
              size: AppSpacing.xxl,
            ),
            unselectedIconTheme: palette.inkMuted.asIconTheme(
              size: AppSpacing.xxl,
            ),
            destinations: <NavigationRailDestination>[
              for (final Destination destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icone.repos),
                  selectedIcon: Icon(destination.icone.actif),
                  label: Text(destination.libelle),
                ),
            ],
          )
        : NavigationDrawer(
            selectedIndex: indexActif,
            onDestinationSelected: (int index) {
              onAller(destinations[index].chemin);
            },
            backgroundColor: palette.surfaceRaised.background,
            indicatorColor: palette.washAccent.background,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: AppRadius.arrondiSm,
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: <Widget>[
              for (final Destination destination in destinations)
                NavigationDrawerDestination(
                  icon: Icon(destination.icone.repos),
                  selectedIcon: Icon(destination.icone.actif),
                  label: Text(destination.libelle),
                ),
            ],
          );

    return SizedBox(
      key: enColonne ? NavShell.railKey : NavShell.barreLateraleKey,
      width: largeur,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          // Directionnel : en arabe, le rail passe a droite et son filet
          // avec lui.
          border: BorderDirectional(end: palette.borderHairline.asBorderSide()),
        ),
        child: enColonne
            ? SafeArea(child: chrome)
            : DrawerTheme(
                data: const DrawerThemeData(
                  width: AppGabarit.largeurBarreLaterale,
                ),
                child: NavigationDrawerTheme(
                  data: NavigationDrawerThemeData(
                    tileHeight: AppMetriques.of(context).cibleTactile,
                    labelTextStyle: _stylesLibelleNavigation(context, palette),
                    iconTheme: _stylesIconeNavigation(palette),
                  ),
                  child: chrome,
                ),
              ),
      ),
    );
  }
}

WidgetStateProperty<TextStyle?> _stylesLibelleNavigation(
  BuildContext context,
  AppPalette palette,
) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  return WidgetStateProperty.resolveWith<TextStyle?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? _styleLibelleSelectionne(context, palette)
        : base.copyWith(color: palette.inkMuted.asBorderSide().color),
  );
}

TextStyle _styleLibelleSelectionne(BuildContext context, AppPalette palette) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  return base.copyWith(color: palette.inkAccent.asBorderSide().color);
}

TextStyle _styleLibelleNonSelectionne(
  BuildContext context,
  AppPalette palette,
) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  return base.copyWith(color: palette.inkMuted.asBorderSide().color);
}

WidgetStateProperty<IconThemeData?> _stylesIconeNavigation(AppPalette palette) {
  return WidgetStateProperty.resolveWith<IconThemeData?>(
    (Set<WidgetState> states) => states.contains(WidgetState.selected)
        ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
        : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
  );
}
