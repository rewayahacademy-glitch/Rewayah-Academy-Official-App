import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/i18n/strings.g.dart';

/// Point d'entree unique de l'application.
///
/// Une seule cible, toutes les plateformes : Windows, Android, iOS et Web. Le
/// Web est ouvert a tous les roles (ADR-008), il n'y a donc aucune branche de
/// demarrage par plateforme.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocaleSettings.useDeviceLocale();

  // La configuration est injectee a la compilation, jamais versionnee.
  // Sans elle, on echoue tot et en clair plutot que sur un appel reseau obscur.
  assert(Env.configuree, Env.aideConfiguration);

  if (Env.configuree) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  }

  runApp(ProviderScope(child: TranslationProvider(child: const RewayahApp())));
}
