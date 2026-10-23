// DUREE-INSECABLE-4 (reprise 2) : le Planning de la classe (tuteur), sur le
// vrai routeur, a 320 px et texte x2, en LTR et en RTL, mesure en vraies
// polices.
//
// - « 18:10 · 45 min » : la duree suit l'heure sans ancre de sens au milieu
//   (dureeEnPhrase), et la ligne est isolee dans son sens en RTL (et non
//   « 18: · 10 45 min ») ;
// - aucun mot coupe : la pastille d'etat passe sous le jour au lieu de
//   l'ecraser en une colonne etroite (« Lu/ndi », « sep/te/mbre ») ;
// - la precision sous la liste garde son point final a sa place en RTL.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../features/classe_tuteur/support_classe.dart';
import '../router/support_routeur.dart' show stabiliser;
import '../support/aucun_mot_coupe.dart';
import '../support/sens_et_echelle.dart';

const String _fsi = '\u2068';
const String _pdi = '\u2069';
const String _lrm = '\u200E';

Future<void> _monterPlanning(WidgetTester tester, TextDirection sens) async {
  tester.view.physicalSize = const Size(320, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surchargesClasse(),
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              builder: sensEtEchelle(direction: sens, echelle: 2),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go('${Routes.classeSousPage(classeA, 'planning')}?eleve=$eleveA1');
  await stabiliser(tester);
}

List<String> _textes(Finder ou) => <String>[
  for (final Element e
      in find.descendant(of: ou, matching: find.byType(Text)).evaluate())
    if ((e.widget as Text).data case final String d) d,
];

void main() {
  group('Planning de la classe a 320 px, texte x2 (vraies polices)', () {
    setUpAll(chargerPolicesDuDepot);

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('${sens.name} : aucun mot coupe, ligne « heure · duree » '
          'sans ancre au milieu', (WidgetTester tester) async {
        await _monterPlanning(tester, sens);
        final Finder carte = find.ancestor(
          of: find.byType(StatusPill),
          matching: find.byType(AppCard),
        );
        expect(carte, findsOneWidget);
        verifierAucunMotCoupe(tester, carte);

        final String ligne = _textes(carte)
            .firstWhere((String d) => d.contains(' · '));
        expect(ligne, contains('45\u00A0min'));
        expect(ligne, isNot(contains(_lrm)));
        if (sens == TextDirection.rtl) {
          expect(ligne, allOf(startsWith(_fsi), endsWith(_pdi)));
        } else {
          expect(ligne, isNot(contains(_fsi)));
        }

        // La pastille passe sous le jour : elle commence plus bas que lui.
        final Finder jour = find.descendant(
          of: carte,
          matching: find.textContaining('septembre'),
        );
        expect(
          tester.getTopLeft(find.byType(StatusPill)).dy,
          greaterThan(tester.getTopLeft(jour).dy),
        );

        final String precision = t.classe.pagePlanning.habituelIndisponible;
        expect(
          find.text(
            sens == TextDirection.rtl ? '$_fsi$precision$_pdi' : precision,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
