import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/i18n/strings.g.dart';
import 'core/router/app_router.dart';
import 'core/session/session_controleur.dart';
import 'core/session/session_state.dart';
import 'core/theme/app_theme.dart';

/// Racine de l'application.
///
/// Le mode d'interface porte par le profil eleve change le theme, jamais
/// l'arborescence de navigation (ADR-009) : c'est pour cela que le mode est lu
/// ici, une seule fois, et non dans chaque ecran.
///
/// Le theme sombre (lot T3, Bible V2 section 7.3, ADR-019, ecart 23 de
/// `decisions.md`) suit `ThemeMode.system` : l'application respecte le
/// reglage clair/sombre du systeme d'exploitation. Aucune bascule manuelle
/// n'existe encore dans un ecran du produit, faute d'entree au catalogue
/// (`docs/design/08-catalogue-ecrans.md`) -- ce lot ferme le mecanisme du
/// theme, pas une preference utilisateur dediee.
class RewayahApp extends ConsumerWidget {
  /// Cree la racine.
  const RewayahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter routeur = ref.watch(routeurProvider);
    final SessionState session = ref.watch(sessionProvider);

    return MaterialApp.router(
      title: 'Rewayah Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pour(session.interfaceMode, Brightness.light),
      darkTheme: AppTheme.pour(session.interfaceMode, Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: routeur,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
