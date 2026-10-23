// L4-06 : les pages de la Pedagogie disent l'attente (DESIGN-GOV 4 bis.6).
//
// Pour chaque page, la lecture ne repond jamais. Le temps est simule
// (`tester.pump(Duration)`, jamais d'attente reelle) :
//
// - juste avant [AppDelais.chargementProlonge] : le squelette seul ;
// - juste apres : la phrase « plus de temps que prevu », toujours sans
//   « Reessayer » en rouge ni echec ;
// - juste apres [AppDelais.requeteMax] : la lecture est tenue pour perdue,
//   « Reessayer » relance la lecture (compteur d'appels du double).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/service_diagnostics.dart';
import 'package:rewayah_academy/core/admin/service_evaluations.dart';
import 'package:rewayah_academy/core/admin/service_programme.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_pedagogie_diagnostics/diagnostics_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_evaluations/evaluations_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_programmes/programmes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_progression/progression_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_qualite/qualite_page.dart';
import 'package:rewayah_academy/features/demo/bibliotheque_admin_demo.dart';
import 'package:rewayah_academy/features/demo/services_admin_demo.dart';

import '../../support/harnais.dart' show FauxServiceReseau;
import '../../support/monter_admin_demo.dart';

/// Un peu moins / un peu plus qu'un seuil, pour ne pas dependre de l'egalite.
const Duration _marge = Duration(milliseconds: 100);

final Finder _squelette = find.byType(Skeleton);
final Finder _prolonge = find.text(t.commun.etats.chargementProlonge.titre);
final Finder _reessayer = find.text(t.commun.etats.actions.reessayer);

/// Le compteur d'appels d'un faux port dont la lecture ne repond jamais.
class _Lectures {
  int appels = 0;

  Future<T> sansReponse<T>() {
    appels++;
    return Completer<T>().future;
  }
}

/// Une bibliotheque dont le catalogue et les fiches ne repondent jamais.
class _BibliothequeSansReponse extends BibliothequeAdminDemo {
  final _Lectures lectures = _Lectures();

  @override
  Future<PageSupports> lister({
    FiltreCatalogue filtre = const FiltreCatalogue(),
    String? curseur,
    int limite = 25,
  }) => lectures.sansReponse<PageSupports>();

  @override
  Future<FicheSupport> fiche(String supportId) =>
      lectures.sansReponse<FicheSupport>();
}

/// Une bibliotheque dont les capacites ne repondent jamais (la porte).
class _CapacitesSansReponse extends BibliothequeAdminDemo {
  final _Lectures lectures = _Lectures();

  @override
  Future<CapacitesBibliotheque> capacites() =>
      lectures.sansReponse<CapacitesBibliotheque>();
}

Future<void> _monterPage(
  WidgetTester tester,
  Widget page,
  List<Override> surcharges,
) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: page,
        ),
      ),
    ),
  );
}

/// Le scenario commun : squelette, phrase a 8 s, echec recuperable a 20 s.
Future<void> _parcourir(WidgetTester tester, int Function() appels) async {
  await tester.pump(const Duration(milliseconds: 500));
  expect(_squelette, findsWidgets, reason: 'squelette au depart');
  expect(_prolonge, findsNothing);
  expect(appels(), 1);

  // A 7 s : toujours le squelette seul.
  await tester.pump(
    const Duration(seconds: 7) - const Duration(milliseconds: 500),
  );
  expect(_squelette, findsWidgets);
  expect(_prolonge, findsNothing);

  // A 9 s : la phrase, le squelette reste, ce n'est pas un echec.
  await tester.pump(
    AppDelais.chargementProlonge - const Duration(seconds: 7) + _marge,
  );
  expect(_prolonge, findsOneWidget);
  expect(_squelette, findsWidgets);
  expect(find.text(t.commun.etats.reessaisEpuises), findsNothing);

  // A 21 s : tenu pour perdu, « Reessayer » relance la lecture.
  await tester.pump(AppDelais.requeteMax - AppDelais.chargementProlonge);
  await tester.pump(const Duration(seconds: 1));
  expect(_prolonge, findsNothing);
  expect(_squelette, findsNothing);
  expect(_reessayer, findsOneWidget);
  expect(appels(), 1);
  await tester.tap(_reessayer);
  await tester.pump(const Duration(milliseconds: 500));
  expect(appels(), 2, reason: 'Reessayer relance la lecture');
  expect(_squelette, findsWidgets, reason: 'le squelette revient');
  expect(tester.takeException(), isNull);

  // Quitter la page annule les minuteries (aucun « Timer still pending »).
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  testWidgets('programmes : 8 s expliquee, 20 s recuperable', (tester) async {
    final _Lectures l = _Lectures();
    await _monterPage(tester, const ProgrammesPage(), <Override>[
      versionsProgrammeProvider.overrideWith(
        (Ref _) => l.sansReponse<List<VersionProgramme>>(),
      ),
    ]);
    await _parcourir(tester, () => l.appels);
  });

  testWidgets('diagnostics : 8 s expliquee, 20 s recuperable', (tester) async {
    final _Lectures l = _Lectures();
    await _monterPage(tester, const DiagnosticsPage(), <Override>[
      versionActiveProgrammeProvider.overrideWith(
        (Ref _) => l.sansReponse<VersionProgramme?>(),
      ),
      diagnosticsATraiterProvider.overrideWith(
        (Ref _) => l.sansReponse<List<EleveADiagnostiquer>>(),
      ),
    ]);
    await _parcourir(tester, () => l.appels);
  });

  testWidgets('evaluations : 8 s expliquee, 20 s recuperable', (tester) async {
    final _Lectures l = _Lectures();
    await _monterPage(tester, const EvaluationsPage(), <Override>[
      evaluationsProvider.overrideWith(
        (Ref _) => l.sansReponse<List<EvaluationAdmin>>(),
      ),
    ]);
    await _parcourir(tester, () => l.appels);
  });

  testWidgets('progression : 8 s expliquee, 20 s recuperable', (tester) async {
    final _Lectures l = _Lectures();
    await _monterPage(tester, const ProgressionPage(), <Override>[
      progressionProvider.overrideWith(
        (Ref _) => l.sansReponse<List<EleveProgression>>(),
      ),
    ]);
    await _parcourir(tester, () => l.appels);
  });

  testWidgets('qualite : 8 s expliquee, 20 s recuperable', (tester) async {
    final _Lectures l = _Lectures();
    await _monterPage(tester, const QualitePage(), <Override>[
      anomaliesQualiteProvider.overrideWith(
        (Ref _) => l.sansReponse<List<AnomalieQualite>>(),
      ),
    ]);
    await _parcourir(tester, () => l.appels);
  });

  testWidgets('bibliotheque, porte : 8 s expliquee, 20 s recuperable', (
    tester,
  ) async {
    final _CapacitesSansReponse port = _CapacitesSansReponse();
    await monterAdminDemo(
      tester,
      route: Routes.adminPedagogieBibliotheque,
      bibliotheque: port,
    );
    await _parcourirApresMontage(tester, () => port.lectures.appels);
  });

  testWidgets('bibliotheque, catalogue : 8 s expliquee, 20 s recuperable', (
    tester,
  ) async {
    final _BibliothequeSansReponse port = _BibliothequeSansReponse();
    await monterAdminDemo(
      tester,
      route: Routes.adminPedagogieBibliotheque,
      bibliotheque: port,
    );
    await _parcourirApresMontage(tester, () => port.lectures.appels);
  });

  testWidgets('bibliotheque, fiche : 8 s expliquee, 20 s recuperable', (
    tester,
  ) async {
    final _BibliothequeSansReponse port = _BibliothequeSansReponse();
    await monterAdminDemo(
      tester,
      route: Routes.adminPedagogieSupport('demo-support-001'),
      bibliotheque: port,
    );
    await _parcourirApresMontage(tester, () => port.lectures.appels);
  });

  testWidgets('bibliotheque, publication : 8 s expliquee, 20 s recuperable', (
    tester,
  ) async {
    final _BibliothequeSansReponse port = _BibliothequeSansReponse();
    await monterAdminDemo(
      tester,
      route: Routes.adminPedagogieSupportPublication('demo-support-001'),
      bibliotheque: port,
    );
    await _parcourirApresMontage(tester, () => port.lectures.appels);
  });

  testWidgets('bibliotheque, attribution : 8 s expliquee, 20 s recuperable', (
    tester,
  ) async {
    final _BibliothequeSansReponse port = _BibliothequeSansReponse();
    await monterAdminDemo(
      tester,
      route: Routes.adminPedagogieSupportAttribution('demo-support-001'),
      bibliotheque: port,
    );
    await _parcourirApresMontage(tester, () => port.lectures.appels);
  });

  testWidgets('demonstration : Diagnostics montre l\'erreur avant 8 s', (
    tester,
  ) async {
    await _monterPage(tester, const DiagnosticsPage(), <Override>[
      serviceProgrammeProvider.overrideWithValue(const ServiceProgrammeDemo()),
      serviceDiagnosticsProvider.overrideWithValue(
        const ServiceDiagnosticsDemo(),
      ),
    ]);
    await tester.pump(const Duration(seconds: 3));
    // Service indisponible : l'etat « pas encore disponible » (sans nouvelle
    // tentative), pas le squelette jusqu'a 40 s.
    expect(_prolonge, findsNothing);
    expect(find.text(t.commun.etats.indisponible.titre), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('le chargement qui aboutit ne dit jamais rien', (tester) async {
    final Completer<List<AnomalieQualite>> c =
        Completer<List<AnomalieQualite>>();
    await _monterPage(tester, const QualitePage(), <Override>[
      anomaliesQualiteProvider.overrideWith((Ref _) => c.future),
    ]);
    await tester.pump(const Duration(seconds: 5));
    c.complete(<AnomalieQualite>[]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 30));
    expect(_prolonge, findsNothing);
    expect(find.byType(EtatSysteme), findsNothing);
    expect(_squelette, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Comme [_parcourir], pour une page deja montee par l'application : le
/// temps ecoule depuis le montage compte deja `stabiliser` (800 ms).
Future<void> _parcourirApresMontage(
  WidgetTester tester,
  int Function() appels,
) async {
  expect(_squelette, findsWidgets, reason: 'squelette au depart');
  expect(appels(), greaterThanOrEqualTo(1));
  final int avant = appels();
  await tester.pump(const Duration(seconds: 6));
  expect(_prolonge, findsNothing);
  await tester.pump(const Duration(seconds: 3));
  expect(_prolonge, findsOneWidget);
  await tester.pump(const Duration(seconds: 12));
  expect(_prolonge, findsNothing);
  expect(_squelette, findsNothing);
  expect(_reessayer, findsOneWidget);
  expect(appels(), avant);
  await tester.tap(_reessayer);
  await tester.pump(const Duration(milliseconds: 500));
  expect(appels(), greaterThan(avant), reason: 'Reessayer relance la lecture');
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
}
