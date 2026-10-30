import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/accessibilite/mode_accessibilite.dart';
import 'core/domain/enums.dart';
import 'core/fraicheur/avis_ephemere.dart';
import 'core/fraicheur/relecture_page.dart';
import 'core/fraicheur/veille_fraicheur.dart';
import 'core/i18n/strings.g.dart';
import 'core/preferences/preferences_locales.dart';
import 'core/router/app_router.dart';
import 'core/session/session_controleur.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/version/bandeau_nouvelle_version.dart';
import 'core/widgets/bandeau_observation.dart';

/// Racine de l'application.
///
/// Le mode d'interface porte par le profil eleve change le theme, jamais
/// l'arborescence de navigation (ADR-009) : c'est pour cela que le mode est lu
/// ici, une seule fois, et non dans chaque ecran.
///
/// Le theme clair/sombre suit **la preference Apparence** de l'appareil
/// (`preferencesLocalesProvider`, Systeme par defaut) : la page Compte >
/// Reglages > Apparence et la bascule soleil / lune de l'en-tete ecrivent la
/// meme preference, et elle est lue ici, une seule fois pour toute
/// l'application (decisions du coordinateur du 24/09/2026, section 3,
/// point 5). Avant ce branchement, la page Reglages ecrivait une preference
/// que rien ne lisait. Le choix est persiste sur l'appareil par
/// [persistanceApparenceProvider].
class RewayahApp extends ConsumerWidget {
  /// Cree la racine.
  ///
  /// [themeMode] force le mode clair/sombre, au-dessus de la preference :
  /// reserve au Playground et aux tests ; `null` (defaut) laisse la preference
  /// decider. [builder] est le passe-vole du meme nom de `MaterialApp` : le
  /// Playground force par la un gabarit d'apercu, la production n'en a aucun
  /// usage.
  const RewayahApp({super.key, this.themeMode, this.builder});

  /// Mode clair/sombre force, ou `null` pour suivre la preference Apparence.
  final ThemeMode? themeMode;

  /// Coupe le rendu sous la navigation, s'il y en a une.
  final Widget Function(BuildContext context, Widget? child)? builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter routeur = ref.watch(routeurProvider);
    final SessionState session = ref.watch(sessionProvider);
    // Lecture du theme persiste au montage, ecriture a chaque changement.
    ref.watch(persistanceApparenceProvider);
    // Meme regle pour le repli de la navigation laterale (bouton de repli).
    ref.watch(persistanceNavigationProvider);
    // Meme regle pour les raccourcis clavier de la salle (EN-KB).
    ref.watch(persistanceRaccourcisProvider);
    // Fraicheur (27/10/2026) : une seule veille des classes et des seances,
    // ouverte avec la session, fermee avec elle.
    ref.watch(veilleFraicheurProvider);
    final ThemeMode mode = themeMode ?? ref.watch(modeThemeProvider);
    // MA-2 (question 2 de MA-1b) : la presentation vient du fournisseur
    // unique du Mode Accessibilite, et le theme reste celui d'`AppTheme.pour`
    // existant, sans aucune couleur nouvelle (K-37).
    final InterfaceMode presentation = ref.watch(modeAccessibiliteActifProvider)
        ? InterfaceMode.enfant
        : InterfaceMode.standard;

    return MaterialApp.router(
      title: 'Rewayah Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(presentation, Brightness.light),
      darkTheme: AppTheme.pour(presentation, Brightness.dark),
      themeMode: mode,
      // Le bandeau d'observation coiffe TOUS les ecrans, et il est pose ici
      // plutot que dans `PageShell` pour deux raisons : il doit survivre aux
      // ecrans qui n'emploient pas la coquille (la salle est immersive), et il
      // ne doit exister qu'une fois a l'ecran, quel que soit l'empilement.
      // Le passe-vole du Playground reste compose, jamais remplace.
      builder: (BuildContext context, Widget? child) {
        // MA-1b : le mouvement reduit (preference locale, reglage systeme,
        // reduceMotion iOS) est pose ici, une fois, pour tous les ecrans.
        final Widget? rendu = builder == null
            ? child
            : builder!(context, child);
        final Observation? observation = session.observation;
        // LG-FLASH : un fond opaque, celui du theme, sous TOUTES les routes.
        // Sans lui, une frame ou le contenu n'est pas encore opaque (fondu
        // d'onglet, page qui entre) laissait la toile transparente, et le
        // navigateur montrait le fond creme de `web/index.html` : un flash
        // clair a chaque changement d'ecran en mode sombre.
        final Color fond = AppPalette.of(context).surfaceCanvas.background;
        // Lot demarrage (25/10/2026) : « nouvelle version prete » coiffe
        // l'ecran courant, quel qu'il soit, comme le bandeau d'observation ;
        // il ne prend aucune place tant qu'il n'a rien a dire.
        return ReglageMouvement(
          child: ColoredBox(
            color: fond,
            child: Column(
              children: <Widget>[
                const BandeauNouvelleVersion(),
                // Un avis court (« Cette classe n'existe plus. »), meme place,
                // meme registre, retire de lui-meme.
                const BandeauAvisEphemere(),
                if (observation != null)
                  BandeauObservation(observation: observation),
                // R3 (30/10/2026) : tirer pour rafraichir (`PageShell`) et
                // relire au retour sur un onglet ou dans l'application.
                Expanded(
                  child: RelectureGenerale(
                    child: rendu ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      routerConfig: routeur,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
