// CTRL-SEANCE-1 : le releve (faits automatiques) et le roster autorise sont
// lus PAR SEANCE. Deux visites A et B a terminer en meme temps : le compte
// rendu de A montre les faits de A, l'observation de A propose les prenoms
// de A, jamais ceux de la Classe B. Les vrais ecrans, horloge fixe.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/isolat_bidi.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle.dart';
import 'package:rewayah_academy/features/controleur/compte_rendu_controle_page.dart';
import 'package:rewayah_academy/features/controleur/observation_controle.dart';
import 'package:rewayah_academy/features/controleur/observation_controle_page.dart';

final CompteRenduEnSuspens _a = CompteRenduEnSuspens(
  seanceId: 'seance-A',
  classe: 'Classe Al-Fajr',
  debut: DateTime(2026, 9, 28, 16),
);

final CompteRenduEnSuspens _b = CompteRenduEnSuspens(
  seanceId: 'seance-B',
  classe: 'Classe Al-Nour',
  debut: DateTime(2026, 9, 28, 17),
);

FaitsVisite _faits({required int presents, required int attendus}) =>
    FaitsVisite(
      debutPrevu: DateTime(2026, 9, 28, 16),
      finPrevue: DateTime(2026, 9, 28, 17),
      debutReel: DateTime(2026, 9, 28, 16, 2),
      participantsAttendus: attendus,
      participantsPresents: presents,
      reconnexions: 1,
    );

final Map<String, FaitsVisite> _faitsParSeance = <String, FaitsVisite>{
  'seance-A': _faits(presents: 7, attendus: 8),
  'seance-B': _faits(presents: 3, attendus: 12),
};

const Map<String, List<EleveRoster>> _rosterParSeance =
    <String, List<EleveRoster>>{
      'seance-A': <EleveRoster>[EleveRoster(id: 'a1', prenom: 'Amina')],
      'seance-B': <EleveRoster>[EleveRoster(id: 'b1', prenom: 'Bilal')],
    };

Future<List<String>> _monter(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<String> lues = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        visitesObserveesProvider.overrideWith(
          () => VisitesObservees(<String, CompteRenduEnSuspens>{
            _a.seanceId: _a,
            _b.seanceId: _b,
          }),
        ),
        faitsVisiteProvider.overrideWith((Ref _, String seance) async {
          lues.add('faits:$seance');
          return _faitsParSeance[seance];
        }),
        rosterControleProvider.overrideWith((Ref _, String seance) async {
          lues.add('roster:$seance');
          return _rosterParSeance[seance] ?? const <EleveRoster>[];
        }),
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
  await tester.pumpAndSettle();
  return lues;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void main() {
  final c = t.controleur.compteRendu;

  testWidgets('le compte rendu de A montre les faits de A, jamais ceux de B', (
    WidgetTester tester,
  ) async {
    final List<String> lues = await _monter(
      tester,
      CompteRenduControlePage(seanceId: _a.seanceId),
    );
    await _toucher(tester, find.text(c.faits));
    expect(find.text(c.presents(presents: 7, attendus: 8)), findsOneWidget);
    expect(find.text(c.presents(presents: 3, attendus: 12)), findsNothing);
    expect(find.text(c.faitsAbsents), findsNothing);
    expect(lues, everyElement('faits:seance-A'));
  });

  testWidgets('le compte rendu de B montre les faits de B', (
    WidgetTester tester,
  ) async {
    await _monter(tester, CompteRenduControlePage(seanceId: _b.seanceId));
    await _toucher(tester, find.text(c.faits));
    expect(find.text(c.presents(presents: 3, attendus: 12)), findsOneWidget);
    expect(find.text(c.presents(presents: 7, attendus: 8)), findsNothing);
  });

  testWidgets('l observation de A propose les prenoms de A, jamais ceux de B', (
    WidgetTester tester,
  ) async {
    final List<String> lues = await _monter(
      tester,
      ObservationControlePage(seanceId: _a.seanceId),
    );
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleNature(NatureObservation.pointPositif),
      ),
    );
    await _toucher(tester, find.text(t.commun.continuer).last);
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.cleDomaine(DomaineObservation.interaction),
      ),
    );
    await _toucher(tester, find.text(t.commun.continuer).last);
    await _toucher(
      tester,
      find.byKey(
        ObservationControlePage.clePersonne(PersonneConcernee.elevePrecis),
      ),
    );
    expect(find.byKey(ObservationControlePage.cleEleve('a1')), findsOneWidget);
    expect(find.text(isolerSens('Amina')), findsOneWidget);
    expect(find.byKey(ObservationControlePage.cleEleve('b1')), findsNothing);
    expect(find.text(isolerSens('Bilal')), findsNothing);
    expect(lues, everyElement('roster:seance-A'));
  });
}
