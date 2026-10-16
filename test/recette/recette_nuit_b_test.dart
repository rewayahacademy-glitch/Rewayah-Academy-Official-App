// RECETTE-NUIT-B : balayage des ecrans admin, controleur, comptable et
// /compte sur le VRAI routeur. Chaque ecran est monte a 360 px, en francais
// et en arabe (RTL), texte x1 et x2 : aucune exception ni debordement, aucun
// mot coupe, cibles tactiles >= 48 (androidTapTargetGuideline).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../router/support_routeur.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart' show FausseSourceSession;

const Map<AppRole, List<String>> _routes = <AppRole, List<String>>{
  AppRole.admin: <String>[
    Routes.admin,
    Routes.adminAlertes,
    Routes.adminCommunicationsAnnonces,
    Routes.adminCommunicationsMessages,
    Routes.adminCommunicationsModeration,
    Routes.adminConfiguration,
    Routes.adminConfigurationConservationDonnees,
    Routes.adminConfigurationFonctionnalites,
    Routes.adminConfigurationPolitiqueRevueKyc,
    Routes.adminConfigurationRegles,
    Routes.adminFinance,
    Routes.adminFinanceAValider,
    Routes.adminFinancePolitiques,
    Routes.adminFinanceReserveDelegation,
    Routes.adminNotifications,
    Routes.adminOperations,
    Routes.adminOperationsAttributions,
    Routes.adminOperationsCommunications,
    Routes.adminOperationsDemandes,
    Routes.adminOperationsGroupes,
    Routes.adminOperationsPilotage,
    Routes.adminOperationsRegroupements,
    Routes.adminOperationsOffres,
    Routes.adminOperationsTraitement,
    Routes.adminPedagogie,
    Routes.adminPedagogieDiagnostics,
    Routes.adminPedagogieEvaluations,
    Routes.adminPedagogieProgrammes,
    Routes.adminPedagogieProgression,
    Routes.adminPedagogieQualite,
    Routes.adminPersonnes,
    Routes.adminPersonnesComptes,
    Routes.adminPersonnesDossiers,
    Routes.adminPersonnesInvitations,
    Routes.adminPersonnesReprises,
    Routes.adminSecuriteAudit,
    Routes.adminSecuriteAuditAccesAgents,
    Routes.adminSecuriteAuditJournal,
    Routes.adminSecuriteAuditObservations,
    Routes.adminSecuriteAuditTirages,
    Routes.adminStudio,
    Routes.adminStudioCanaux,
  ],
  AppRole.controller: <String>[
    Routes.controleur,
    Routes.controleurCompteRendu,
    Routes.controleurEchanges,
    Routes.controleurHistorique,
    Routes.controleurNotifications,
    Routes.controleurObservation,
  ],
  AppRole.accountant: <String>[
    Routes.comptable,
    Routes.comptablePaiements,
    Routes.comptableTresorerie,
  ],
  AppRole.guardian: <String>[
    Routes.compte,
    Routes.comptePaiementsRecus,
    Routes.compteProfil,
    Routes.compteProfils,
    Routes.compteReglages,
  ],
};

Future<void> _monter(
  WidgetTester tester,
  AppRole role,
  String depart,
  double echelle,
) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: TranslationProvider.of(context).flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (BuildContext contexte, Widget? app) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: app!,
              ),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    // L'arabe est une bibliotheque differee : on la charge ici, hors du
    // temps simule des tests.
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _routes.forEach((AppRole role, List<String> chemins) {
    for (final String chemin in chemins) {
      for (final (AppLocale langue, double echelle) cas
          in <(AppLocale, double)>[
            (AppLocale.fr, 1),
            (AppLocale.fr, 2),
            (AppLocale.ar, 1),
          ]) {
        testWidgets('$chemin ${cas.$1.name} x${cas.$2.toInt()}', (
          WidgetTester tester,
        ) async {
          await LocaleSettings.setLocale(cas.$1);
          final SemanticsHandle sem = tester.ensureSemantics();
          await _monter(tester, role, chemin, cas.$2);
          expect(tester.takeException(), isNull);
          final List<String> coupes = motsCoupes(tester, find.byType(Scaffold));
          expect(coupes, isEmpty, reason: 'mots coupes');
          if (cas.$2 == 1) {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
          }
          sem.dispose();
        });
      }
    }
  });
}
