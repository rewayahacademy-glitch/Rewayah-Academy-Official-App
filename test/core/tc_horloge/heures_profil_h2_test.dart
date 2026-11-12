// HEURES-PROFIL H2 (garde-cap, 12/11/2026) : les heures des ecrans de la
// direction, du comptable et du controleur se lisent au fuseau du PROFIL.
// Un fuseau de profil a +05:30 (Asia/Kolkata), different de l'appareil de
// test : 12:00 UTC doit se dire 17:30.
//
// Et la preuve du principe de l'ecoute : une page (les incidents des 24
// dernieres heures) peinte AVANT l'arrivee du fuseau se redessine quand il
// arrive (ref.watch(monHorlogeProvider)), au lieu de garder l'heure de
// l'appareil.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_incidents_seances.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_candidature/libelles_candidature.dart';
import 'package:rewayah_academy/features/admin_dossiers/textes_dossier.dart';
import 'package:rewayah_academy/features/admin_fusion/fusion_libelles.dart';
import 'package:rewayah_academy/features/admin_journal/incidents_page.dart';
import 'package:rewayah_academy/features/admin_planning/feuille_nouvelle_date.dart';
import 'package:rewayah_academy/features/admin_planning/planning_libelles.dart';
import 'package:rewayah_academy/features/admin_tirage/tirage_libelles.dart';

final MonHorloge _kolkata = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T12:00:00Z',
  'moi': <String, Object?>{
    'fuseau': 'Asia/Kolkata',
    'decalage_secondes': 19800,
  },
});

final DateTime _midi = DateTime.utc(2026, 11, 12, 12);

class _UnIncident implements PortIncidentsSeances {
  @override
  Future<List<IncidentSeance>> dernieres24h(DateTime maintenant) async =>
      <IncidentSeance>[
        IncidentSeance(
          id: 'i1',
          classe: 'Classe fictive',
          statut: StatutSeance.incidentTechnique,
          survenuLe: _midi,
        ),
      ];
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tearDown(() => poserMonHorlogePourTest(null));

  test('l appareil de test n est pas au fuseau du profil', () {
    expect(_midi.toLocal().timeZoneOffset, isNot(const Duration(minutes: 330)));
  });

  group('formateurs, au fuseau du profil', () {
    setUp(() => poserMonHorlogePourTest(_kolkata));

    test('planning et seances reportees', () {
      expect(libelleHeure(_midi), contains('17'));
      expect(libelleHeure(_midi), contains('30'));
      expect(quandSeanceReportee(_midi), contains('30'));
    });

    test('tirage, fusion, candidatures, dossiers', () {
      expect(libelleQuandTirage(_midi), contains('17:30'));
      expect(libelleQuand(_midi), contains('17:30'));
      expect(instantHistorique(_midi), contains('17:30'));
      expect(dateRevue(_midi), contains('17:30'));
      expect(quandDepuis(_midi, _midi), contains('17:30'));
    });
  });

  testWidgets('la page des incidents se redessine quand le fuseau arrive '
      'apres son premier rendu', (WidgetTester tester) async {
    final Completer<MonHorloge?> arrivee = Completer<MonHorloge?>();
    tester.view.physicalSize = const Size(1440, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          portIncidentsSeancesProvider.overrideWithValue(_UnIncident()),
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
          monHorlogeProvider.overrideWith((Ref _) => arrivee.future),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const IncidentsPage(),
          ),
        ),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Premier rendu : pas encore de fuseau, l'heure de l'appareil.
    final Finder ligne = find.byKey(const ValueKey<String>('incident-i1'));
    expect(ligne, findsOneWidget);
    String texte() => tester
        .widgetList<Text>(
          find.descendant(of: ligne, matching: find.byType(Text)),
        )
        .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join(' ');
    expect(texte(), isNot(contains('30')));

    // Le fuseau du profil arrive : la page se redessine a 17 h 30.
    poserMonHorlogePourTest(_kolkata);
    arrivee.complete(_kolkata);
    await tester.pump();
    await tester.pump();
    expect(texte(), contains('17'));
    expect(texte(), contains('30'));
  });
}
