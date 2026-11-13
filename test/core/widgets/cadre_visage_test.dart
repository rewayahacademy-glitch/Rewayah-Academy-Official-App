// SCENE-CLASSE (directeur, 11/11/2026) : LE cadre d'une personne dans la
// salle (MODES-AFFICHAGE §2, regle 2). De 64 a 480 de cote, clair et sombre,
// texte x2, arabe : rien ne deborde ; le nom part le premier en petit (il
// reste lu) ; le micro ferme se dit par une icone et un mot lu ; l'anneau de
// parole apparait sans rien deplacer, et se lit.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/cadre_visage.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../../capture/outil_capture.dart';

const Key _boite = ValueKey<String>('boite');

Widget _image() => const ColoredBox(color: Color(0xFF3A3A3A));

Future<void> _monter(
  WidgetTester tester,
  CadreVisage cadre, {
  double cote = 240,
  double rapport = 4 / 3,
  ThemeMode theme = ThemeMode.light,
  double texte = 1,
}) async {
  fixerVueCapture(tester, const Size(800, 700), 1);
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(
          child: SizedBox(
            key: _boite,
            width: cote,
            height: (cote / rapport).floorToDouble(),
            child: cadre,
          ),
        ),
      ),
      themeMode: theme,
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => LocaleSettings.setLocale(AppLocale.fr));

  group('de 64 a 480, clair et sombre, texte x1 et x2 : rien ne deborde', () {
    for (final double cote in <double>[64, 96, 128, 240, 480]) {
      for (final ThemeMode theme in <ThemeMode>[
        ThemeMode.light,
        ThemeMode.dark,
      ]) {
        for (final double texte in <double>[1, 2]) {
          for (final bool camera in <bool>[true, false]) {
            testWidgets('$cote, ${theme.name}, x$texte, camera $camera', (
              WidgetTester tester,
            ) async {
              await _monter(
                tester,
                CadreVisage(
                  nom: 'Abdurrahman',
                  prenom: 'Abdurrahman',
                  microCoupe: true,
                  recite: true,
                  parle: true,
                  image: camera ? _image() : null,
                ),
                cote: cote,
                rapport: cote <= 96 ? 1 : 4 / 3,
                theme: theme,
                texte: texte,
              );
              expect(tester.takeException(), isNull, reason: 'debordement');
              final Rect boite = tester.getRect(find.byKey(_boite));
              // Tout ce qui s'ecrit reste dans le cadre.
              for (final Element e
                  in find
                      .descendant(
                        of: find.byKey(_boite),
                        matching: find.byType(RichText),
                      )
                      .evaluate()) {
                final Rect r = tester.getRect(find.byWidget(e.widget));
                expect(
                  boite.inflate(0.5).contains(r.topLeft) &&
                      boite.inflate(0.5).contains(r.bottomRight),
                  isTrue,
                  reason: 'texte $r hors du cadre $boite',
                );
              }
            });
          }
        }
      }
    }
  });

  testWidgets('en grand : le nom sur sa pastille, le micro ferme en icone '
      'et lu, jamais par la couleur seule', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await _monter(
      tester,
      CadreVisage(
        nom: 'Khadija',
        prenom: 'Khadija',
        microCoupe: true,
        image: _image(),
      ),
    );
    expect(find.byKey(CadreVisage.cleNom), findsOneWidget);
    expect(find.byKey(CadreVisage.cleMicro), findsOneWidget);
    expect(find.text(t.salle.microCoupe), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Khadija, ${t.salle.microCoupe}')),
      findsOneWidget,
    );
    // L'etiquette est en bas au debut du cadre.
    final Rect boite = tester.getRect(find.byKey(_boite));
    final Rect nom = tester.getRect(find.byKey(CadreVisage.cleNom));
    expect(nom.bottom, greaterThan(boite.center.dy));
    expect(nom.left, lessThan(boite.center.dx));
    h.dispose();
  });

  testWidgets('en petit (64) : le nom part, il reste lu et en infobulle ; '
      'le signe du micro reste', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await _monter(
      tester,
      CadreVisage(
        nom: 'Khadija',
        prenom: 'Khadija',
        microCoupe: true,
        recite: true,
        image: _image(),
        menu: const SizedBox.square(dimension: 48),
      ),
      cote: 64,
      rapport: 1,
    );
    expect(find.byKey(CadreVisage.cleNom), findsNothing);
    expect(find.byKey(CadreVisage.cleMicro), findsOneWidget);
    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.byType(StatusPill), findsNothing);
    expect(find.byKey(const ValueKey<String>('gestes-Khadija')), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp(
          'Khadija, ${t.salle.microCoupe}, '
          '${t.tc.classe.recitation.pastille}',
        ),
      ),
      findsOneWidget,
    );
    h.dispose();
  });

  testWidgets('quelqu un parle : l anneau apparait en fondu, rien ne bouge, '
      'et le lecteur d ecran le dit', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    CadreVisage cadre(bool parle) => CadreVisage(
      key: const ValueKey<String>('c'),
      nom: 'Omar',
      prenom: 'Omar',
      parle: parle,
      image: _image(),
    );
    await _monter(tester, cadre(false));
    final Rect nomAvant = tester.getRect(find.byKey(CadreVisage.cleNom));
    AnimatedOpacity anneau() =>
        tester.widget<AnimatedOpacity>(find.byKey(CadreVisage.cleAnneau));
    expect(anneau().opacity, 0);
    await _monter(tester, cadre(true));
    expect(anneau().opacity, 1);
    expect(tester.getRect(find.byKey(CadreVisage.cleNom)), nomAvant);
    expect(
      find.bySemanticsLabel(RegExp('Omar, ${t.salle.scene.parle}')),
      findsOneWidget,
    );
    h.dispose();
  });

  testWidgets('camera eteinte : la photo ou l initiale (TuileSansImage), '
      'fondu entre image et photo', (WidgetTester tester) async {
    await _monter(
      tester,
      const CadreVisage(nom: 'Maryam', prenom: 'Maryam', recite: true),
    );
    expect(find.byType(TuileSansImage), findsOneWidget);
    expect(find.byType(StatusPill), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsOneWidget);
  });

  testWidgets('un nom vide (camarade sans prenom lisible) : aucune pastille '
      'vide sur l image', (WidgetTester tester) async {
    await _monter(tester, CadreVisage(nom: '', prenom: '', image: _image()));
    expect(find.byKey(CadreVisage.cleNom), findsNothing);
    // La pastille de l'etiquette (rayon xs) n'est pas posee.
    expect(
      find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).borderRadius == AppRadius.arrondiXs,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('en arabe : l etiquette au debut (a droite)', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await _monter(
      tester,
      CadreVisage(nom: 'خديجة', prenom: 'خديجة', image: _image()),
    );
    final Rect boite = tester.getRect(find.byKey(_boite));
    final Rect nom = tester.getRect(find.byKey(CadreVisage.cleNom));
    expect(nom.right, greaterThan(boite.center.dx));
    expect(tester.takeException(), isNull);
  });
}
