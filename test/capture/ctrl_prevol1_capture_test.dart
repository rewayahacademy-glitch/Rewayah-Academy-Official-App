// CTRL-PREVOL-1 : la salle du controleur SANS micro (releve VERIF-CT-1). Il
// entre dans la vraie `SallePage`, zone de controle visible, sans l'impasse
// « Aucun micro utilisable sur cet appareil ». 320 x2, 390 x3 et 1440 x1,
// clair et sombre. Jamais sans `CAPTURE_DIR` (voir test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/features/demo/controleur_demo.dart';
import 'package:rewayah_academy/features/demo/demo_controleur_page.dart';
import 'package:rewayah_academy/features/demo/salle_controleur_demo.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';

import 'outil_capture.dart';

/// Un appareil sans aucune entree audio.
class _SansMicro implements ServicePreVol {
  const _SansMicro();

  @override
  Future<ResultatPreVol> verifier() async => const ResultatPreVol(
    microDisponible: false,
    cameraDisponible: false,
    sortieAudioDisponible: true,
    permissionRefusee: false,
  );
}

void main() {
  group(
    'Capture : CTRL-PREVOL-1, controleur sans micro',
    skip: sautSansCapture,
    () {
      setUpAll(chargerPolicesDuDepot);
      for (final (String l, Size taille, double densite)
          in <(String, Size, double)>[
            ('320', const Size(320, 700), 2),
            ('390', const Size(390, 844), 3),
            ('1440', const Size(1440, 900), 1),
          ]) {
        for (final (String m, ThemeMode mode) in <(String, ThemeMode)>[
          ('clair', ThemeMode.light),
          ('sombre', ThemeMode.dark),
        ]) {
          testWidgets('ctrl_prevol1_salle_${l}_$m', (
            WidgetTester tester,
          ) async {
            fixerVueCapture(tester, taille, densite);
            final GoRouter routeur = GoRouter(
              initialLocation: '/salle',
              routes: <RouteBase>[
                GoRoute(
                  path: '/salle',
                  builder: (BuildContext _, GoRouterState _) => ProviderScope(
                    overrides: <Override>[
                      ...surchargesCoquilleControleurDemo(
                        EtatDemoControleur.enDirect,
                      ),
                      moteurSalleProvider.overrideWith(
                        (Ref _) => MoteurSalleControleurDemo(),
                      ),
                      serviceVideoProvider.overrideWithValue(
                        const ServiceVideoControleurDemo(),
                      ),
                      servicePreVolProvider.overrideWithValue(
                        const _SansMicro(),
                      ),
                      preVolProvider.overrideWith(
                        (Ref _) => const _SansMicro().verifier(),
                      ),
                      presenceSeanceProvider.overrideWith(
                        (Ref _, String _) =>
                            Stream<List<PresenceParticipant>?>.value(null),
                      ),
                      servicePresenceProvider.overrideWithValue(
                        const PresenceControleurDemo(),
                      ),
                    ],
                    child: const SallePage(seanceId: 'demo-controle'),
                  ),
                ),
              ],
            );
            await tester.pumpWidget(
              ProviderScope(
                child: TranslationProvider(
                  child: RepaintBoundary(
                    key: cadreCapture,
                    child: Builder(
                      builder: (BuildContext contexte) => MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.pour(
                          InterfaceMode.standard,
                          Brightness.light,
                        ),
                        darkTheme: AppTheme.pour(
                          InterfaceMode.standard,
                          Brightness.dark,
                        ),
                        themeMode: mode,
                        locale: TranslationProvider.of(contexte).flutterLocale,
                        supportedLocales: AppLocaleUtils.supportedLocales,
                        localizationsDelegates:
                            GlobalMaterialLocalizations.delegates,
                        routerConfig: routeur,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await stabiliser(tester);
            expect(find.text(t.salle.refusMateriel), findsNothing);
            expect(find.text(t.salle.bandeauControle), findsOneWidget);
            debugPrint(
              'PNG ${await capturer(tester, 'ctrl_prevol1_salle_${l}_$m')}',
            );
          });
        }
      }
    },
  );
}
