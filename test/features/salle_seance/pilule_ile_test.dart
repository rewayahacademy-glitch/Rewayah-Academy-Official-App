// ILE-SALLE (directeur, 11/11/2026 ; D-007 approuvee) : la pilule de la salle
// est une ile repliee au repos (le cercle, le temps restant, un point
// d'etat) ; une phrase qui arrive la deplie, puis elle se replie seule
// (AppMouvement.ilePassage, AppMouvement.ileMention pour la mention a
// l'entree) ; un appui la redeplie ; ce qui empeche d'entendre reste deplie ;
// le lecteur d'ecran lit toujours la mention entiere.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_horloge/chrono_seance.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/chrono_vivant.dart';
import 'package:rewayah_academy/features/salle_seance/chrono_salle.dart';
import 'package:rewayah_academy/features/salle_seance/pilule_etat_salle.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../support/demo/seance_demo.dart';

final DateTime _t0 = DateTime.utc(2026, 11, 11, 17);
final BornesChrono _bornes = BornesChrono(
  debutUtc: _t0,
  finPrevueUtc: _t0.add(const Duration(minutes: 60)),
);

VueSeance _vue({
  ConnexionSeance connexion = ConnexionSeance.enLigne,
  bool videoSuspendue = false,
}) => DonneesSeanceDemo.vue(RoleSeance.eleve, EtatDemoSalle.repos).copyWith(
  chrono: _bornes,
  connexion: connexion,
  videoSuspendue: videoSuspendue,
);

Future<void> _poser(
  WidgetTester tester,
  VueSeance vue, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  bool reduit = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        horlogeChronoProvider.overrideWithValue(
          () => _t0.add(const Duration(minutes: 20)),
        ),
      ],
      child: TranslationProvider(
        child: MediaQuery(
          data: MediaQueryData(
            size: taille,
            textScaler: TextScaler.linear(echelle),
            disableAnimations: reduit,
          ),
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Material(
              child: Align(
                alignment: Alignment.topLeft,
                child: PiluleEtatSalle(
                  vue: vue,
                  avecChrono: true,
                  largeurMax: taille.width - 32,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Laisse passer [duree] (les secondes du chrono comprises), puis les
/// fondus.
Future<void> _attendre(WidgetTester tester, Duration duree) async {
  await tester.pump(duree);
  await tester.pump(const Duration(milliseconds: 500));
}

bool _depliee() => find.byKey(PiluleEtatSalle.cleDepliee).evaluate().isNotEmpty;

void main() {
  testWidgets('a l entree, la mention se lit 10 s, puis l ile se replie sur '
      'le cercle, le temps restant et ses points', (WidgetTester tester) async {
    await _poser(tester, _vue());
    expect(_depliee(), isTrue);
    expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
    expect(find.byType(ChronoVivant), findsOneWidget);

    await _attendre(tester, AppMouvement.ilePassage);
    expect(_depliee(), isTrue, reason: 'la mention reste plus longtemps');

    await _attendre(tester, AppMouvement.ileMention - AppMouvement.ilePassage);
    expect(_depliee(), isFalse);
    expect(find.byKey(PiluleEtatSalle.cleRepliee), findsOneWidget);
    expect(find.text(t.salle.bandeauPermanent), findsNothing);
    expect(find.text(t.salle.seance.enLigne), findsNothing);
    expect(find.byType(ChronoVivant), findsOneWidget);
    // Le lecteur d'ecran lit toujours la phrase entiere.
    expect(find.bySemanticsLabel(t.salle.bandeauPermanent), findsOneWidget);
  });

  testWidgets('un appui redeplie l ile pour 6 s, puis elle se replie', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _vue());
    await _attendre(tester, AppMouvement.ileMention);
    expect(_depliee(), isFalse);
    // La cible fait 48 de haut, l'ile repliee 36.
    expect(
      tester.getSize(find.byKey(PiluleEtatSalle.cleDeplier)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('pilule-etat-salle'))),
      isA<Size>().having((Size s) => s.height, 'hauteur', lessThan(48)),
    );

    await tester.tap(find.byKey(PiluleEtatSalle.cleDeplier));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(_depliee(), isTrue);
    expect(find.text(t.salle.bandeauPermanent), findsOneWidget);

    await _attendre(tester, AppMouvement.ilePassage);
    expect(_depliee(), isFalse);
  });

  testWidgets('image coupee : la phrase se deplie, puis un signe court reste '
      'a cote du chrono', (WidgetTester tester) async {
    await _poser(tester, _vue());
    await _attendre(tester, AppMouvement.ileMention);
    await _poser(tester, _vue(videoSuspendue: true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_depliee(), isTrue);
    expect(find.text(t.salle.videoSuspendue), findsOneWidget);

    await _attendre(tester, AppMouvement.ilePassage);
    expect(_depliee(), isFalse);
    expect(find.text(t.salle.videoSuspendue), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(PiluleEtatSalle.cleRepliee),
        matching: find.byType(Icon),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(t.salle.videoSuspendue), findsOneWidget);
  });

  testWidgets('reconnexion : ce qui empeche d entendre reste deplie tant que '
      'ca dure', (WidgetTester tester) async {
    await _poser(tester, _vue());
    await _attendre(tester, AppMouvement.ileMention);
    await _poser(tester, _vue(connexion: ConnexionSeance.reconnexion));
    await _attendre(tester, AppMouvement.ileMention);
    expect(_depliee(), isTrue);
    expect(find.text(t.salle.seance.reconnexion), findsOneWidget);

    await _poser(tester, _vue());
    await _attendre(tester, AppMouvement.ilePassage);
    expect(_depliee(), isFalse);
  });

  testWidgets('reduire les animations : meme comportement, sans mouvement', (
    WidgetTester tester,
  ) async {
    await _poser(tester, _vue(), reduit: true);
    expect(_depliee(), isTrue);
    await tester.pump(AppMouvement.ileMention);
    await tester.pump();
    expect(_depliee(), isFalse);
    expect(find.text(t.salle.bandeauPermanent), findsNothing);
  });

  for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
    testWidgets('320 px, texte x2, ${langue.name} : depliee et repliee, '
        'aucun debordement', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(langue));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      await _poser(tester, _vue(), taille: const Size(320, 700), echelle: 2);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await _attendre(tester, AppMouvement.ileMention);
      expect(_depliee(), isFalse);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('pilule-etat-salle')))
            .right,
        lessThanOrEqualTo(320),
      );
    });
  }
}
