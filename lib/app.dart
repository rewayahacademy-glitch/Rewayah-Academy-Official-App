import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/i18n/strings.g.dart';
import 'core/preferences/preferences_locales.dart';
import 'core/router/app_router.dart';
import 'core/session/session_controleur.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_theme.dart';
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
    final ThemeMode mode = themeMode ?? ref.watch(modeThemeProvider);

    return MaterialApp.router(
      title: 'Rewayah Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(session.interfaceMode, Brightness.light),
      darkTheme: AppTheme.pour(session.interfaceMode, Brightness.dark),
      themeMode: mode,
      // Le bandeau d'observation coiffe TOUS les ecrans, et il est pose ici
      // plutot que dans `PageShell` pour deux raisons : il doit survivre aux
      // ecrans qui n'emploient pas la coquille (la salle est immersive), et il
      // ne doit exister qu'une fois a l'ecran, quel que soit l'empilement.
      // Le passe-vole du Playground reste compose, jamais remplace.
      builder: (BuildContext context, Widget? child) {
        final Widget? rendu = builder == null ? child : builder!(context, child);
        final Observation? observation = session.observation;
        if (observation == null) {
          return rendu ?? const SizedBox.shrink();
        }
        return Column(
          children: <Widget>[
            BandeauObservation(observation: observation),
            Expanded(child: rendu ?? const SizedBox.shrink()),
          ],
        );
      },
      routerConfig: routeur,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
