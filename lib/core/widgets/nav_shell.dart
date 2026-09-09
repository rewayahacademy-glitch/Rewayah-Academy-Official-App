import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../router/routes.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_elevation.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

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
/// Fonction pure, a part du cأ¢blage : la regle des quatre destinations se
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
/// sous 600, rail de 600 a 1024, barre laterale au dela
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

/// La barre basse : une surface elevee, collee sous le contenu.
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceRaised.background,
        border: Border(top: palette.borderHairline.asBorderSide()),
        // Une barre collee flotte au dessus du contenu : niveau 2.
        boxShadow: AppElevation.niveau2,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < destinations.length; i++)
                Expanded(
                  child: _Entree(
                    destination: destinations[i],
                    active: i == indexActif,
                    enColonne: true,
                    onPress: () => onAller(destinations[i].chemin),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le rail et la barre laterale : la meme colonne, deux largeurs.
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

    return SizedBox(
      width: largeur,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surfaceRaised.background,
          // Directionnel : en arabe, le rail passe a droite et son filet
          // avec lui.
          border: BorderDirectional(end: palette.borderHairline.asBorderSide()),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _Entree(
                      destination: destinations[i],
                      active: i == indexActif,
                      enColonne: enColonne,
                      onPress: () => onAller(destinations[i].chemin),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une entree, quelle que soit la forme du chrome.
///
/// L'etat actif se dit **trois fois** : la graisse `fill` de l'icone, le fond
/// doux, et l'encre d'accent. Une seule des trois ne suffirait pas
/// (`01-systeme-visuel.md` section 8).
class _Entree extends StatelessWidget {
  const _Entree({
    required this.destination,
    required this.active,
    required this.enColonne,
    required this.onPress,
  });

  final Destination destination;
  final bool active;
  final bool enColonne;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final TextStyle base =
        Theme.of(context).textTheme.labelMedium ?? const TextStyle();

    return Pressable.selon(
      onPress: onPress,
      libelleSemantique: destination.libelle,
      respecterCibleTactile: false,
      arrondiFocus: AppRadius.arrondiSm,
      constructeur: (BuildContext _, EtatPression etat) {
        // L'aplat sature reste reserve a l'action principale : une destination
        // active prend la teinte douce de l'accent, jamais le violet plein.
        final AppColorPair? fond = active
            ? palette.washAccent
            : (etat.survole ? palette.surfaceSunken : null);
        final TextStyle style = active
            ? palette.inkAccent.applyTo(base)
            : palette.inkMuted.applyTo(base);
        final Widget icone = IconTheme(
          data: active
              ? palette.inkAccent.asIconTheme(size: AppSpacing.xxl)
              : palette.inkMuted.asIconTheme(size: AppSpacing.xxl),
          child: Icon(destination.icone.resoudre(selectionne: active)),
        );
        // Ni `maxLines` ni ellipse : un libelle de navigation porte du sens, et
        // `06-accessibilite.md` section 3 interdit de le rogner. A 200 pour
        // cent de taille de texte, la barre grandit ; elle ne coupe pas.
        final Widget libelle = Text(
          destination.libelle,
          style: style,
          textAlign: TextAlign.center,
        );

        return Container(
          constraints: BoxConstraints(minHeight: metriques.cibleTactile),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: fond?.decoration(borderRadius: AppRadius.arrondiSm),
          child: enColonne
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[icone, Ecart.vXs, libelle],
                )
              : Row(
                  children: <Widget>[
                    icone,
                    Ecart.hMd,
                    Expanded(child: libelle),
                  ],
                ),
        );
      },
    );
  }
}
