import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/commande_salle.dart';

import '../../support/hote_theme.dart';

/// ETATS-BTN-1 (revue du directeur, 01/10/2026) : une bascule de la salle
/// montre son etat par trois signaux cumules (disque plein ou contour seul,
/// icone differente, mot d'etat), jamais par la couleur seule.

const Key _micro = ValueKey<String>('micro');
const Key _camera = ValueKey<String>('camera');
const Key _quitter = ValueKey<String>('quitter');
const Key _disqueCle = ValueKey<String>('disque-appel');
const Key _motCle = ValueKey<String>('mot-commande');

/// Une rangee de commandes, comme le dock : micro, camera, quitter.
Widget _rangee({required bool micro, required bool camera}) => Row(
  children: <Widget>[
    Expanded(
      child: CommandeSalle(
        key: _micro,
        icone: (micro ? AppIcons.micro : AppIcons.microCoupe).repos,
        libelle: micro ? t.salle.microOuvert : t.salle.microCoupe,
        libelleSemantique: micro ? t.salle.fermerMicro : t.salle.ouvrirMicro,
        bascule: micro,
        onPress: () {},
      ),
    ),
    Expanded(
      child: CommandeSalle(
        key: _camera,
        icone: (camera ? AppIcons.camera : AppIcons.cameraCoupee).repos,
        libelle: camera ? t.salle.cameraAllumee : t.salle.cameraCoupee,
        libelleSemantique: camera ? t.salle.fermerCamera : t.salle.ouvrirCamera,
        bascule: camera,
        onPress: () {},
      ),
    ),
    Expanded(
      child: CommandeSalle(
        key: _quitter,
        icone: AppIcons.raccrocher.repos,
        libelle: t.salle.quitter,
        onPress: () {},
      ),
    ),
  ],
);

Finder _disque(Key cle) =>
    find.descendant(of: find.byKey(cle), matching: find.byKey(_disqueCle));

BoxDecoration _decoration(WidgetTester tester, Key cle) {
  final Finder boite = find.descendant(
    of: _disque(cle),
    matching: find.byType(DecoratedBox),
  );
  return tester.widget<DecoratedBox>(boite.first).decoration as BoxDecoration;
}

IconData _icone(WidgetTester tester, Key cle) => tester
    .widget<Icon>(
      find.descendant(of: find.byKey(cle), matching: find.byType(Icon)),
    )
    .icon!;

Finder _motFinder(Key cle) =>
    find.descendant(of: find.byKey(cle), matching: find.byKey(_motCle));

String _mot(WidgetTester tester, Key cle) =>
    tester.widget<Text>(_motFinder(cle)).data!;

void main() {
  for (final Brightness luminosite in Brightness.values) {
    group('bascule, theme ${luminosite.name}', () {
      testWidgets(
        'active : disque plein de contraste, icone micro, mot ouvert',
        (WidgetTester tester) async {
          fixerVue(tester, const Size(1440, 900));
          await tester.pumpWidget(
            hoteTheme(
              _rangee(micro: true, camera: true),
              luminosite: luminosite,
              defilant: false,
            ),
          );
          final AppPalette palette = AppPalette.of(
            tester.element(find.byKey(_micro)),
          );
          final BoxDecoration d = _decoration(tester, _micro);
          // Signal 1 : un fond plein, a la paire de contraste du theme.
          expect(d.color, palette.surfaceInverse.background);
          expect(d.border, isNull);
          // Signal 2 : l'icone du micro ouvert.
          expect(_icone(tester, _micro), AppIcons.micro.repos);
          // Signal 3 : le mot d'etat.
          expect(_mot(tester, _micro), t.salle.microOuvert);
          expect(_mot(tester, _camera), t.salle.cameraAllumee);
        },
      );

      testWidgets('inactive : contour seul, icone barree, mot coupe', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          hoteTheme(
            _rangee(micro: false, camera: false),
            luminosite: luminosite,
            defilant: false,
          ),
        );
        final AppPalette palette = AppPalette.of(
          tester.element(find.byKey(_micro)),
        );
        final BoxDecoration d = _decoration(tester, _micro);
        // Signal 1 : aucun fond, un contour de deux points a l'encre de bord
        // forte.
        expect(d.color, isNull);
        expect(d.border, isNotNull);
        final BorderSide cote = (d.border! as Border).top;
        expect(cote.width, 2);
        expect(cote.color, palette.borderStrong.asBorderSide().color);
        // Signal 2 : l'icone du micro barre.
        expect(_icone(tester, _micro), AppIcons.microCoupe.repos);
        // Signal 3 : le mot d'etat.
        expect(_mot(tester, _micro), t.salle.microCoupe);
        expect(_mot(tester, _camera), t.salle.cameraCoupee);
      });

      testWidgets('les trois signaux different, un par un', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, const Size(1440, 900));
        await tester.pumpWidget(
          hoteTheme(
            _rangee(micro: true, camera: true),
            luminosite: luminosite,
            defilant: false,
          ),
        );
        final BoxDecoration actif = _decoration(tester, _micro);
        final IconData iconeActive = _icone(tester, _micro);
        final String motActif = _mot(tester, _micro);
        await tester.pumpWidget(
          hoteTheme(
            _rangee(micro: false, camera: true),
            luminosite: luminosite,
            defilant: false,
          ),
        );
        final BoxDecoration inactif = _decoration(tester, _micro);
        expect(inactif.color, isNot(actif.color), reason: 'fond');
        expect(inactif.border, isNot(actif.border), reason: 'contour');
        expect(_icone(tester, _micro), isNot(iconeActive), reason: 'icone');
        expect(_mot(tester, _micro), isNot(motActif), reason: 'mot');
      });
    });
  }

  group('geometrie', () {
    for (final Size taille in const <Size>[Size(320, 640), Size(1440, 900)]) {
      for (final double echelle in <double>[1, 2]) {
        for (final bool allume in <bool>[true, false]) {
          testWidgets('${taille.width.toInt()} px, texte x${echelle.toInt()}, '
              '${allume ? 'actif' : 'inactif'} : cibles 48, ecart, mot centre, '
              'sans debordement', (WidgetTester tester) async {
            fixerVue(tester, taille);
            await tester.pumpWidget(
              hoteTheme(
                _rangee(micro: allume, camera: allume),
                echelleTexte: echelle,
                defilant: false,
              ),
            );
            expect(tester.takeException(), isNull);
            final List<Rect> disques = <Rect>[
              for (final Key cle in <Key>[_micro, _camera, _quitter])
                tester.getRect(_disque(cle)),
            ];
            for (final Rect d in disques) {
              expect(d.width, greaterThanOrEqualTo(48), reason: '$d');
              expect(d.height, closeTo(d.width, 0.01), reason: 'rond');
              expect(d.left, greaterThanOrEqualTo(0));
              expect(d.right, lessThanOrEqualTo(taille.width));
            }
            // Aucune touche accidentelle : au moins un palier d'ecart entre
            // deux disques voisins.
            for (int i = 1; i < disques.length; i++) {
              expect(
                disques[i].left - disques[i - 1].right,
                greaterThanOrEqualTo(AppSpacing.sm),
                reason: 'disques $i et ${i - 1} trop proches',
              );
            }
            // La zone pressable de chaque commande tient la cible de 48.
            for (final Key cle in <Key>[_micro, _camera, _quitter]) {
              final Size s = tester.getSize(find.byKey(cle));
              expect(s.height, greaterThanOrEqualTo(48), reason: '$cle');
              expect(s.width, greaterThanOrEqualTo(48), reason: '$cle');
            }
            // Le mot d'etat est centre sous son disque, dans l'ecran.
            for (final Key cle in <Key>[_micro, _camera]) {
              final Finder mot = _motFinder(cle);
              expect(
                (tester.getCenter(mot).dx - tester.getCenter(_disque(cle)).dx)
                    .abs(),
                lessThanOrEqualTo(1),
                reason: 'mot de $cle non centre',
              );
              final Rect m = tester.getRect(mot);
              expect(m.left, greaterThanOrEqualTo(-1));
              expect(m.right, lessThanOrEqualTo(taille.width + 1));
            }
          });
        }
      }
    }

    testWidgets("lecteur d'ecran : l'acte est lu, jamais seulement l'etat", (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      final SemanticsHandle sem = tester.ensureSemantics();
      await tester.pumpWidget(
        hoteTheme(_rangee(micro: true, camera: false), defilant: false),
      );
      // Le nom du bouton est l'acte ; le mot d'etat s'y ajoute.
      expect(
        find.bySemanticsLabel(RegExp('^${t.salle.fermerMicro}')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^${t.salle.ouvrirCamera}')),
        findsOneWidget,
      );
      sem.dispose();
    });
  });

  testWidgets('Quitter n est lu qu une fois par le lecteur d ecran', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(390, 844));
    final SemanticsHandle sem = tester.ensureSemantics();
    await tester.pumpWidget(
      hoteTheme(
        Row(
          children: <Widget>[
            Expanded(
              child: CommandeSalle(
                key: _quitter,
                icone: AppIcons.raccrocher.repos,
                libelle: t.salle.quitter,
                libelleSemantique: t.salle.seance.sortir,
                onPress: () {},
              ),
            ),
          ],
        ),
        defilant: false,
      ),
    );
    // Le nom lu est celui du bouton, une fois : le mot peint se tait.
    final noeud = tester.getSemantics(find.byKey(_quitter));
    expect(noeud.label, t.salle.seance.sortir);
    sem.dispose();
  });

  Widget compacte() => CommandeSalleCompacte(
    diametre: 48,
    child: Row(
      children: <Widget>[
        Expanded(
          child: CommandeSalle(
            key: _micro,
            icone: AppIcons.micro.repos,
            libelle: t.salle.microOuvert,
            bascule: true,
            onPress: () {},
          ),
        ),
      ],
    ),
  );

  testWidgets(
    'rangee compacte, texte tres agrandi : le mot passe en infobulle',
    (WidgetTester tester) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(compacte(), echelleTexte: 2, defilant: false),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(t.salle.microOuvert), findsNothing);
      expect(_disque(_micro), findsOneWidget);
    },
  );

  testWidgets('rangee compacte, texte a 130 % : le mot reste affiche', (
    WidgetTester tester,
  ) async {
    fixerVue(tester, const Size(320, 640));
    await tester.pumpWidget(
      hoteTheme(compacte(), echelleTexte: 1.3, defilant: false),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(t.salle.microOuvert), findsOneWidget);
  });

  group('bascule inerte (hors salle, reconnexion)', () {
    for (final bool allumee in <bool>[true, false]) {
      testWidgets(
        'inerte et ${allumee ? 'active' : 'inactive'} : etat encore lisible',
        (WidgetTester tester) async {
          fixerVue(tester, const Size(1440, 900));
          await tester.pumpWidget(
            hoteTheme(
              CommandeSalle(
                key: _micro,
                icone: (allumee ? AppIcons.micro : AppIcons.microCoupe).repos,
                libelle: allumee ? t.salle.microOuvert : t.salle.microCoupe,
                bascule: allumee,
                onPress: null,
              ),
              defilant: false,
            ),
          );
          final BoxDecoration d = _decoration(tester, _micro);
          // Plein (surface neutre) quand actif, contour seul quand inactif :
          // le disque garde sa forme, seule l'encre s'attenue.
          if (allumee) {
            expect(d.color, isNotNull);
          } else {
            expect(d.color, isNull);
            expect((d.border! as Border).top.width, 2);
          }
          expect(
            _icone(tester, _micro),
            (allumee ? AppIcons.micro : AppIcons.microCoupe).repos,
          );
          expect(
            _mot(tester, _micro),
            allumee ? t.salle.microOuvert : t.salle.microCoupe,
          );
        },
      );
    }
  });
}
