// HEURES-PROFIL H4 (garde-cap, 12/11/2026) : les ecrans qui disaient
// « heure de cet appareil » se lisent au fuseau du PROFIL ; la mention ne
// s'affiche plus que quand le profil n'a pas de fuseau servi (repli sur
// l'appareil), parce qu'alors elle est vraie.
//
// (i) profil a +05:30 (Asia/Kolkata), appareil different : 12:00 UTC se dit
//     17:30, sans mention ;
// (ii) profil SANS fuseau : l'heure de l'appareil, avec la mention ;
// (iii) une page peinte AVANT l'arrivee du fuseau se redessine.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/entretien_candidat.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/dates_appareil.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_horloge/mon_horloge.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/candidature/entretien_creneaux.dart';

final MonHorloge _kolkata = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T12:00:00Z',
  'moi': <String, Object?>{
    'fuseau': 'Asia/Kolkata',
    'decalage_secondes': 19800,
  },
});

final MonHorloge _sansFuseau = MonHorloge.lire(const <String, Object?>{
  'maintenant': '2026-11-12T12:00:00Z',
});

final DateTime _midi = DateTime.utc(2026, 11, 12, 12);
final DateTime _fin = DateTime.utc(2026, 11, 12, 12, 45);

Widget _page(Future<MonHorloge?> Function() horloge) => ProviderScope(
  overrides: <Override>[
    horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
    monHorlogeProvider.overrideWith((Ref _) => horloge()),
    creneauxOuvertsProvider.overrideWith(
      (Ref _) async => <CreneauOuvert>[
        CreneauOuvert(
          id: 'c1',
          debut: _midi,
          fin: _fin,
          langues: const <String>[],
        ),
      ],
    ),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: ChoixCreneauEntretien(candidature: CandidatureDossier()),
        ),
      ),
    ),
  ),
);

Future<void> _attendre(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _textes(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join(' | ');

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  tearDown(() => poserMonHorlogePourTest(null));

  test('l appareil de test n est pas au fuseau du profil', () {
    expect(_midi.toLocal().timeZoneOffset, isNot(const Duration(minutes: 330)));
  });

  group('(i) profil a +05:30', () {
    setUp(() => poserMonHorlogePourTest(_kolkata));

    test('l heure du profil, et ce n est plus l heure de l appareil', () {
      expect(estHeureDeLAppareil(_midi), isFalse);
      expect(horaireEntretien(_midi, _fin), contains('17:30'));
      expect(horaireEntretien(_midi, _fin), contains('18:15'));
    });

    testWidgets('choix du moment : 17:30, et AUCUNE mention de l appareil', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_page(() async => _kolkata));
      await _attendre(tester);
      expect(find.textContaining('17:30'), findsOneWidget);
      expect(find.text(t.recrutement.entretien.heureAppareil), findsNothing);
    });
  });

  group('(ii) profil sans fuseau servi', () {
    setUp(() => poserMonHorlogePourTest(_sansFuseau));

    test('l heure de l appareil, dite', () {
      expect(estHeureDeLAppareil(_midi), isTrue);
      expect(
        horaireEntretien(_midi, _fin),
        contains(heureDeLAppareil(_midi.toLocal())),
      );
    });

    testWidgets('choix du moment : la mention est la', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_page(() async => _sansFuseau));
      await _attendre(tester);
      expect(find.text(t.recrutement.entretien.heureAppareil), findsOneWidget);
      expect(
        find.textContaining(heureDeLAppareil(_midi.toLocal())),
        findsOneWidget,
      );
    });
  });

  testWidgets('(iii) le fuseau arrive apres le premier rendu : la page se '
      'redessine, l heure change et la mention part', (
    WidgetTester tester,
  ) async {
    final Completer<MonHorloge?> arrivee = Completer<MonHorloge?>();
    await tester.pumpWidget(_page(() => arrivee.future));
    await _attendre(tester);
    // Premier rendu : aucun fuseau lu, l'appareil, et la mention.
    expect(find.text(t.recrutement.entretien.heureAppareil), findsOneWidget);
    expect(_textes(tester), isNot(contains('17:30')));

    poserMonHorlogePourTest(_kolkata);
    arrivee.complete(_kolkata);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('17:30'), findsOneWidget);
    expect(find.text(t.recrutement.entretien.heureAppareil), findsNothing);
  });
}
