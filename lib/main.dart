import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/ecran_configuration_absente.dart';
import 'core/config/env.dart';
import 'core/i18n/strings.g.dart';
import 'core/observabilite/supervision.dart';
import 'features/_dev/playground/playground_racine.dart';

/// Point d'entree unique de l'application.
///
/// Une seule cible, toutes les plateformes : Windows, Android, iOS et Web. Le
/// Web est ouvert a tous les roles (ADR-008), il n'y a donc aucune branche de
/// demarrage par plateforme.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La supervision avant tout le reste : une erreur du demarrage lui-meme doit
  // remonter comme les autres, y compris l'ecran de configuration absente.
  // Sans DSN, cet appel ne fait rien. Il ne passe pas par `appRunner` : sur
  // Flutter 3.47, `PlatformDispatcher.onError` existe, donc Sentry n'ouvre
  // aucune zone gardee et `appRunner` ne capterait pas une erreur de plus.
  await Supervision.demarrer();

  await LocaleSettings.useDeviceLocale();

  // La configuration est injectee a la compilation, jamais versionnee.
  // Sans elle, on echoue tot, en clair, et EN RELEASE AUSSI : un `assert` seul
  // ne tient pas cette promesse, il disparait de la version compilee et laisse
  // l'application demarrer pour mourir plus loin sur un ecran gris.
  if (!Env.configuree) {
    runApp(const EcranConfigurationAbsente());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  if (Env.playgroundActif) {
    runApp(
      ProviderScope(
        child: TranslationProvider(child: const PlaygroundRacine()),
      ),
    );
    return;
  }

  runApp(ProviderScope(child: TranslationProvider(child: const RewayahApp())));
}
