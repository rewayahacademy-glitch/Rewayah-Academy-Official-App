// COM-F-Q5 : captures de recette des cloches des coquilles (reponse Q5 du
// directeur : une cloche pour l'enseignant, le controleur et l'admin, aucune
// pour l'eleve mineur). Sur le VRAI routeur, clair et sombre, 320, 390,
// 600, 768 et 1440, plus le compte a plusieurs espaces (raccourci Espaces
// puis cloche, une seule rangee d'actions) et la page des notifications
// ouverte.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien. Mode
// d'emploi : `test/capture/LISEZ-MOI.md`.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/appairage/profils_locaux.dart';
import 'package:rewayah_academy/core/cache/db/app_database.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/compte/espaces_compte.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../router/support_routeur.dart' hide stabiliser;
import '../support/harnais.dart';
import 'outil_capture.dart';

/// Un enseignant qui est aussi controleur : deux espaces, donc le raccourci
/// Espaces de CT-9 dans l'en-tete, a cote de la cloche.
class _DeuxEspaces extends EspacesCompteControleur {
  @override
  EspacesCompte build() => const EspacesCompte(
    disponibles: <EspaceTravail>[
      EspaceTravail.enseignement,
      EspaceTravail.controle,
    ],
    actif: EspaceTravail.enseignement,
  );
}

Future<void> _monterRole(
  WidgetTester tester,
  String depart,
  AppRole role, {
  required ThemeMode mode,
  List<Override> plus = const <Override>[],
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
        ...plus,
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                darkTheme: AppTheme.pour(
                  InterfaceMode.standard,
                  Brightness.dark,
                ),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
}

/// La coquille admin reelle, en demonstration admin, aucun serveur.
Future<void> _monterAdmin(
  WidgetTester tester,
  String depart, {
  required ThemeMode mode,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        // Une base en memoire : l'ecriture du PNG laisse courir le vrai temps,
        // et la base de l'appareil chercherait un dossier que le test n'a pas.
        baseLocaleProvider.overrideWith((Ref ref) {
          final AppDatabase base = AppDatabase.surExecuteur(
            NativeDatabase.memory(),
          );
          ref.onDispose(base.close);
          return base;
        }),
      ],
      child: TranslationProvider(
        child: RepaintBoundary(
          key: cadreCapture,
          child: RewayahApp(themeMode: mode),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(depart);
  await stabiliser(tester);
}

const List<(String, Size, double, EdgeInsets)> _tailles =
    <(String, Size, double, EdgeInsets)>[
      ('320', Size(320, 640), 2, EdgeInsets.zero),
      ('390', Size(390, 844), 3, EdgeInsets.only(top: 47, bottom: 34)),
      ('600', Size(600, 960), 2, EdgeInsets.zero),
      ('768', Size(768, 1024), 2, EdgeInsets.zero),
      ('1440', Size(1440, 900), 1, EdgeInsets.zero),
    ];

void main() {
  group('Capture : cloches des coquilles (COM-F-Q5)', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('garde-fou : les vraies polices sont actives', (
      WidgetTester tester,
    ) async {
      expect(
        largeurSonde('PlusJakartaSans'),
        lessThan(largeurSonde('FamilleInexistante') * 0.6),
      );
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final (String nom, Size logique, double densite, EdgeInsets zone)
          in _tailles) {
        final String suffixe = '${nom}_${mode.name}';
        for (final (String ecran, String chemin, AppRole role)
            in <(String, String, AppRole)>[
              ('enseignant_journee', Routes.enseignantJournee, AppRole.teacher),
              (
                'enseignant_creneaux',
                Routes.enseignantCreneaux,
                AppRole.teacher,
              ),
              (
                'enseignant_notifications',
                Routes.enseignantNotifications,
                AppRole.teacher,
              ),
              ('controleur_controle', Routes.controleur, AppRole.controller),
              (
                'controleur_notifications',
                Routes.controleurNotifications,
                AppRole.controller,
              ),
              ('eleve_accueil', Routes.eleve, AppRole.student),
              (
                'tuteur_notifications',
                Routes.tuteurNotifications,
                AppRole.guardian,
              ),
            ]) {
          testWidgets('$ecran $suffixe', (WidgetTester tester) async {
            fixerVueCapture(tester, logique, densite, zoneSure: zone);
            await _monterRole(tester, chemin, role, mode: mode);
            debugPrint(
              'PNG ${await capturer(tester, 'cloche_${ecran}_$suffixe')}',
            );
          });
        }

        testWidgets('enseignant_deux_espaces $suffixe', (
          WidgetTester tester,
        ) async {
          fixerVueCapture(tester, logique, densite, zoneSure: zone);
          await _monterRole(
            tester,
            Routes.enseignantJournee,
            AppRole.teacher,
            mode: mode,
            plus: <Override>[
              espacesCompteProvider.overrideWith(_DeuxEspaces.new),
            ],
          );
          debugPrint(
            'PNG ${await capturer(tester, 'cloche_enseignant_deux_espaces_$suffixe')}',
          );
        });

        for (final (String ecran, String chemin) in <(String, String)>[
          ('admin_accueil', Routes.admin),
          ('admin_notifications', Routes.adminNotifications),
        ]) {
          testWidgets('$ecran $suffixe', (WidgetTester tester) async {
            fixerVueCapture(tester, logique, densite, zoneSure: zone);
            await _monterAdmin(tester, chemin, mode: mode);
            debugPrint(
              'PNG ${await capturer(tester, 'cloche_${ecran}_$suffixe')}',
            );
          });
        }
      }
    }
  });
}
