// Revue independante (jetons, a11y, non-regression des autres roles).
// Fichier TEMPORAIRE, copie dans un worktree jetable (base 3cf3544 et HEAD),
// jamais commite. Meme source pour les deux arbres : tout ce qu'il importe
// existe a l'identique a la base et a HEAD (harnais inchange).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/priere/service_priere.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';

import '../support/harnais.dart';

final String _dossier = Platform.environment['REVUE_DIR'] ?? '';
final String _prefixe = Platform.environment['REVUE_PREFIXE'] ?? 'x';
const Key _cadre = ValueKey<String>('revue-cadre');

Future<void> _polices() async {
  final List<Object?> familles =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<Object?>;
  for (final Object? entree in familles) {
    final Map<String, Object?> f = entree! as Map<String, Object?>;
    final FontLoader c = FontLoader(f['family']! as String);
    for (final Object? a in f['fonts']! as List<Object?>) {
      c.addFont(rootBundle.load((a! as Map<String, Object?>)['asset']! as String));
    }
    await c.load();
  }
}

void _vue(WidgetTester tester, Size logique, double densite, {bool tel = true}) {
  tester.view.physicalSize = logique * densite;
  tester.view.devicePixelRatio = densite;
  final FakeViewPadding zone = FakeViewPadding(
    top: tel ? 47 * densite : 0,
    bottom: tel ? 34 * densite : 0,
  );
  tester.view.padding = zone;
  tester.view.viewPadding = zone;
  addTearDown(tester.view.reset);
}

Future<void> _capturer(WidgetTester tester, String nom) async {
  final RenderRepaintBoundary boite = tester.renderObject(find.byKey(_cadre));
  final double densite = tester.view.devicePixelRatio;
  await tester.runAsync(() async {
    final ui.Image image = await boite.toImage(pixelRatio: densite);
    final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final File fichier = File('$_dossier${Platform.pathSeparator}${_prefixe}_$nom.png');
    await fichier.parent.create(recursive: true);
    await fichier.writeAsBytes(png!.buffer.asUint8List());
  });
}

Future<void> _stabiliser(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

SessionState _session(AppRole role, String id, InterfaceMode mode) => SessionState(
  resolue: true,
  role: role,
  profileId: id,
  householdId: 'h1',
  accountStatus: AccountStatus.active,
  lectureProfil: LectureProfil.presente,
  interfaceMode: mode,
);

List<Override> _surcharges(
  AppRole role,
  String id, {
  bool enDirect = false,
  InterfaceMode interface = InterfaceMode.standard,
}) {
  final DateTime maintenant = DateTime.now();
  final FauxServicePlanning planning = FauxServicePlanning()
    ..seancesRendues = <Seance>[
      Seance(
        id: 's1',
        debut: enDirect
            ? maintenant.subtract(const Duration(minutes: 5))
            : maintenant.add(const Duration(minutes: 25)),
        fin: maintenant.add(const Duration(minutes: 85)),
        statut: enDirect ? StatutSeance.enCours : StatutSeance.planifiee,
        eleveId: 'e1',
        elevePrenom: 'Khadija',
        eleveIdentifiant: 'STUD-KB-000003',
        enseignantId: 't1',
        enseignantPrenom: 'Aminata',
        enseignantIdentifiant: 'TEACH-AD-000001',
      ),
    ];
  final FauxServiceEnseignant enseignant = FauxServiceEnseignant()
    ..seancesRendues = <SeanceEnseignant>[
      SeanceEnseignant(
        id: 'se1',
        debut: maintenant.add(const Duration(hours: 2)),
        fin: maintenant.add(const Duration(hours: 3)),
        statut: StatutSeance.planifiee,
        nbParticipants: 4,
        cahierDepose: false,
        groupeId: 'g1',
        groupeLibelle: 'Groupe Al-Fatiha',
      ),
    ];
  return <Override>[
    sourceSessionProvider.overrideWithValue(
      FausseSourceSession(_session(role, id, interface)),
    ),
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
    servicePlanningProvider.overrideWithValue(planning),
    serviceEnseignantProvider.overrideWithValue(enseignant),
    serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
    serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
    servicePriereProvider.overrideWithValue(FauxServicePriere()),
    servicePreVolProvider.overrideWithValue(FauxServicePreVol()),
    servicePresenceProvider.overrideWithValue(FauxServicePresence()),
  ];
}

Future<void> _monter(
  WidgetTester tester, {
  required AppRole role,
  required String id,
  required String depart,
  ThemeMode mode = ThemeMode.light,
  double echelle = 1,
  bool enDirect = false,
  InterfaceMode interface = InterfaceMode.standard,
}) async {
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _surcharges(role, id, enDirect: enDirect, interface: interface),
      child: TranslationProvider(
        child: RepaintBoundary(
          key: _cadre,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.pour(interface, Brightness.light),
                darkTheme: AppTheme.pour(interface, Brightness.dark),
                themeMode: mode,
                locale: TranslationProvider.of(context).flutterLocale,
                supportedLocales: AppLocaleUtils.supportedLocales,
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (BuildContext c, Widget? app) => MediaQuery(
                  data: MediaQuery.of(c).copyWith(
                    textScaler: TextScaler.linear(echelle),
                    disableAnimations: true,
                  ),
                  child: app!,
                ),
                routerConfig: routeur,
              );
            },
          ),
        ),
      ),
    ),
  );
  await _stabiliser(tester);
  routeur.go(depart);
  await _stabiliser(tester);
}

Future<void> _demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(_polices);

  const Size tel = Size(390, 844);

  for (final (String, ThemeMode, double) cas in <(String, ThemeMode, double)>[
    ('clair', ThemeMode.light, 1),
    ('sombre', ThemeMode.dark, 1),
    ('clair_texte200', ThemeMode.light, 2),
  ]) {
    testWidgets('eleve accueil 390 ${cas.$1}', (WidgetTester tester) async {
      _vue(tester, tel, 2);
      await _monter(
        tester,
        role: AppRole.student,
        id: 'e1',
        depart: Routes.eleve,
        mode: cas.$2,
        echelle: cas.$3,
      );
      await _capturer(tester, 'eleve_accueil_390_${cas.$1}');
      await _demonter(tester);
    });

    testWidgets('enseignant journee 390 ${cas.$1}', (WidgetTester tester) async {
      _vue(tester, tel, 2);
      await _monter(
        tester,
        role: AppRole.teacher,
        id: 't1',
        depart: Routes.enseignantJournee,
        mode: cas.$2,
        echelle: cas.$3,
      );
      await _capturer(tester, 'enseignant_journee_390_${cas.$1}');
      await _demonter(tester);
    });
  }

  testWidgets('enseignant journee 1024 clair (tablette)', (WidgetTester tester) async {
    _vue(tester, const Size(1024, 768), 1, tel: false);
    await _monter(tester, role: AppRole.teacher, id: 't1', depart: Routes.enseignantJournee);
    await _capturer(tester, 'enseignant_journee_1024_clair');
    await _demonter(tester);
  });

  testWidgets('enseignant creneaux 390 clair (onglets)', (WidgetTester tester) async {
    _vue(tester, tel, 2);
    await _monter(tester, role: AppRole.teacher, id: 't1', depart: Routes.enseignantCreneaux);
    await _capturer(tester, 'enseignant_creneaux_390_clair');
    await _demonter(tester);
  });

  for (final (String, InterfaceMode, ThemeMode) cas in <(String, InterfaceMode, ThemeMode)>[
    ('standard_clair', InterfaceMode.standard, ThemeMode.light),
    ('guidee_clair', InterfaceMode.enfant, ThemeMode.light),
    ('guidee_sombre', InterfaceMode.enfant, ThemeMode.dark),
  ]) {
    testWidgets('eleve direct 390 ${cas.$1}', (WidgetTester tester) async {
      _vue(tester, tel, 2);
      await _monter(
        tester,
        role: AppRole.student,
        id: 'e1',
        depart: Routes.eleve,
        mode: cas.$3,
        enDirect: true,
        interface: cas.$2,
      );
      await _capturer(tester, 'eleve_direct_390_${cas.$1}');
      await _demonter(tester);
    });
  }

  testWidgets('eleve accueil 1440 sombre (bureau)', (WidgetTester tester) async {
    _vue(tester, const Size(1440, 900), 1, tel: false);
    await _monter(
      tester,
      role: AppRole.student,
      id: 'e1',
      depart: Routes.eleve,
      mode: ThemeMode.dark,
    );
    await _capturer(tester, 'eleve_accueil_1440_sombre');
    await _demonter(tester);
  });
}
