// FN-023 : les salles du 26/10 (ordinateur, telephone de l'enseignant, plein
// ecran de l'eleve) n'ont pas d'autre en-tete que la pilule d'etat ; le chrono
// du temps restant y est porte. Sans bornes, en Interface guidee, ou sans le
// drapeau (ancien `ChromeSeance`, qui rend son chrono lui-meme) : rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/pilule_etat_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 1, 17);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
);

Future<void> _poser(
  WidgetTester tester, {
  required DateTime maintenant,
  RoleSeance role = RoleSeance.eleve,
  bool avecChrono = true,
  bool aLaLigne = false,
  BornesChrono? bornes,
  bool sansBornes = false,
  Size taille = const Size(1440, 900),
  double echelle = 1,
  AppLocale langue = AppLocale.fr,
}) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final VueSeance vue = DonneesSeanceDemo.vue(
    role,
    EtatDemoSalle.repos,
  ).copyWith(chrono: bornes ?? _bornes, sansChrono: sansBornes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horlogeChronoProvider.overrideWithValue(() => maintenant),
      ],
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
          ),
          child: MaterialApp(
            theme: AppTheme.pour(
              role == RoleSeance.guidee
                  ? InterfaceMode.enfant
                  : InterfaceMode.standard,
              Brightness.light,
            ),
            home: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: PiluleEtatSalle(
                  vue: vue,
                  avecChrono: avecChrono,
                  aLaLigne: aLaLigne,
                  largeurMax: taille.width - 32,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

String _texte(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ChronoSalle.cleTexte)).data!;

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final RoleSeance role in <RoleSeance>[
    RoleSeance.eleve,
    RoleSeance.enseignant,
  ]) {
    testWidgets('${role.name} : la pilule dit le temps restant', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        role: role,
        maintenant: _t0.add(const Duration(minutes: 57, seconds: 30)),
      );
      expect(_texte(tester), contains('00:02:30'));
      expect(_texte(tester), contains('restant'));
    });
  }

  testWidgets('apres la fin prevue : « Temps prévu écoulé »', (
    WidgetTester tester,
  ) async {
    await _poser(
      tester,
      maintenant: _t0.add(const Duration(minutes: 61)),
      aLaLigne: true,
    );
    expect(_texte(tester), t.salle.seance.chrono.tempsPrevuEcoule);
  });

  testWidgets('sans le drapeau, sans bornes, ou en Interface guidee : rien', (
    WidgetTester tester,
  ) async {
    final DateTime pendant = _t0.add(const Duration(minutes: 10));
    await _poser(tester, maintenant: pendant, avecChrono: false);
    expect(find.byType(ChronoSalle), findsNothing);
    await _poser(tester, maintenant: pendant, sansBornes: true);
    expect(find.byType(ChronoSalle), findsNothing);
    await _poser(tester, maintenant: pendant, role: RoleSeance.guidee);
    expect(find.byType(ChronoSalle), findsNothing);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    for (final bool ligne in <bool>[false, true]) {
      testWidgets('${langue.name}, 320 px, texte x2, aLaLigne $ligne : '
          'aucun debordement', (WidgetTester tester) async {
        await _poser(
          tester,
          maintenant: _t0.add(const Duration(minutes: 30)),
          taille: const Size(320, 640),
          echelle: 2,
          aLaLigne: ligne,
          langue: langue,
        );
        expect(find.byType(ChronoSalle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
