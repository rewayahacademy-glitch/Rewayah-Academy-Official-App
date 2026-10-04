// DUREE-INSECABLE-1 : durees a 320 px et texte x2, en LTR et en RTL.
//
// Avant : « Cours dans 3 h / 28 » scinde sur deux lignes (carte de seance
// `CarteSession` de l'Accueil Mode Accessibilite, bloc de seance de l'Accueil
// famille) ; « Aucune séan » rogne sous l'avatar du selecteur de profils.
// Apres : la duree reste sur une ligne (espaces insecables du formatage
// partage), le sous-titre du selecteur passe a la ligne entre ses mots.
//
// Prefixe des PNG : variable `CAPTURE_PREFIXE` (avant / apres).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../fixtures/tuteur/faux_classes_foyer.dart';
import '../fixtures/tuteur/faux_seances_famille.dart';
import '../fixtures/tuteur/foyers.dart';
import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

final String _prefixe = Platform.environment['CAPTURE_PREFIXE'] ?? 'apres';

Widget _cadre({
  required GoRouter Function(WidgetRef ref) routeur,
  required TextDirection sens,
  List<Override> surcharges = const <Override>[],
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: RepaintBoundary(
      key: cadreCapture,
      child: Consumer(
        builder: (BuildContext _, WidgetRef ref, Widget? _) =>
            MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext c, Widget? app) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Directionality(textDirection: sens, child: app!),
              ),
              routerConfig: routeur(ref),
            ),
      ),
    ),
  ),
);

void main() {
  group('Capture : DUREE-INSECABLE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('accessibilite ${sens.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 2200), 1);
        final GoRouter r = GoRouter(
          initialLocation: adresseDemoAccessibilite(
            EleveDemoAccessibilite.mariam,
          ),
          routes: routesDemoAccessibilite('local'),
        );
        addTearDown(r.dispose);
        await tester.pumpWidget(_cadre(routeur: (_) => r, sens: sens));
        await stabiliser(tester);
        await tester.tap(
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.eleve.accueil),
          ),
        );
        await stabiliser(tester);
        final String nom = '${_prefixe}_accessibilite_320x2_${sens.name}';
        debugPrint('PNG ${await capturer(tester, nom)}');
      });

      testWidgets('famille ${sens.name}', (WidgetTester tester) async {
        fixerVueCapture(tester, const Size(320, 2200), 1);
        final FauxServiceAppairage appairage = FauxServiceAppairage()
          ..elevesRendus = FoyersFictifs.foyerA
          ..appareilsRendus = <AppareilAppaire>[
            AppareilAppaire(
              id: 'app-1',
              profilId: 'foyer-a-eleve-1',
              prenom: 'Eleve A1',
              plateforme: 'Android',
              appaireA: DateTime.utc(2026, 9, 1),
            ),
          ];
        // Eleve A1 : cours dans 3 h 28. Eleve A2 : aucune seance.
        final FauxSeancesFamille seances = FauxSeancesFamille(
          seances: <SeanceFamille>[
            seanceFictive(
              debutUtc: instantServeurFige.add(
                const Duration(hours: 3, minutes: 28, seconds: 30),
              ),
              heureFoyer: heureRendue('Europe/Paris', 'Paris', '21:28'),
            ),
          ],
        );
        late GoRouter r;
        await tester.pumpWidget(
          _cadre(
            sens: sens,
            surcharges: <Override>[
              ...surchargesRouteur(
                FausseSourceSession(sessionActive(AppRole.guardian)),
                appairage: appairage,
              ),
              portSeancesFamilleProvider.overrideWithValue(seances),
              portClassesFoyerProvider.overrideWithValue(
                FauxClassesFoyer(
                  classes: <ClasseFoyer>[
                    ClasseFoyer(
                      eleveId: 'foyer-a-eleve-1',
                      classe: classeFictive(),
                    ),
                  ],
                ),
              ),
            ],
            routeur: (WidgetRef ref) => r = ref.read(routeurProvider),
          ),
        );
        await stabiliser(tester);
        r.go(Routes.tuteurAccueil);
        await stabiliser(tester);
        final String nom = '${_prefixe}_famille_320x2_${sens.name}';
        debugPrint('PNG ${await capturer(tester, nom)}');
      });
    }
  });
}
