import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';

import '../../support/hote_theme.dart';

/// FILTERPILL-ETAT-1 (09/10) : l'etat retenu d'une `FilterPill` ne se lit
/// jamais a la seule couleur (`lib/CLAUDE.md`). Une coche (`AppIcons.succes`)
/// double le fond doux et le filet fort, la semantique garde `selected`, et
/// la pilule garde la meme largeur dans les deux etats (la place de la coche
/// est reservee), pour qu'une rangee ne se recompose pas sous le doigt.

const List<String> _jours = <String>[
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

Finder _coche(Finder pilule) => find.descendant(
  of: pilule,
  matching: find.byWidgetPredicate(
    (Widget w) => w is Icon && w.icon == AppIcons.succes.actif,
  ),
);

/// Les libelles non vides du noeud et de ses descendants.
List<String> _libelles(SemanticsNode noeud) {
  final List<String> libelles = <String>[
    if (noeud.label.isNotEmpty) noeud.label,
  ];
  noeud.visitChildren((SemanticsNode enfant) {
    libelles.addAll(_libelles(enfant));
    return true;
  });
  return libelles;
}

Finder _pilule(String libelle) => find.widgetWithText(FilterPill, libelle);

/// Une rangee de jours, comme la feuille « Ajouter une plage ».
class _Rangee extends StatefulWidget {
  const _Rangee({this.initiaux = const <int>{}});

  final Set<int> initiaux;

  @override
  State<_Rangee> createState() => _RangeeState();
}

class _RangeeState extends State<_Rangee> {
  late final Set<int> _retenus = <int>{...widget.initiaux};

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: <Widget>[
      for (int i = 0; i < _jours.length; i++)
        FilterPill(
          libelle: _jours[i],
          compteur: i == 6 ? 12 : null,
          retenue: _retenus.contains(i),
          onPress: () => setState(() {
            if (!_retenus.remove(i)) _retenus.add(i);
          }),
        ),
    ],
  );
}

void main() {
  for (final Brightness luminosite in Brightness.values) {
    for (final TextDirection sens in TextDirection.values) {
      final String nom = '${luminosite.name}, ${sens.name}';

      testWidgets('coche seulement a l\'etat retenu ($nom)', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(
          hoteTheme(
            Directionality(textDirection: sens, child: const _Rangee()),
            luminosite: luminosite,
          ),
        );
        for (final String j in _jours) {
          expect(_coche(_pilule(j)), findsNothing, reason: j);
        }

        await tester.tap(_pilule('Mardi'));
        await tester.pump();
        expect(_coche(_pilule('Mardi')), findsOneWidget);
        for (final String j in _jours.where((String j) => j != 'Mardi')) {
          expect(_coche(_pilule(j)), findsNothing, reason: j);
        }

        // La coche est devant le libelle, dans le sens de lecture.
        final Rect coche = tester.getRect(_coche(_pilule('Mardi')));
        final Rect texte = tester.getRect(find.text('Mardi'));
        if (sens == TextDirection.ltr) {
          expect(coche.right, lessThanOrEqualTo(texte.left));
        } else {
          expect(coche.left, greaterThanOrEqualTo(texte.right));
        }

        // Relachee : la coche disparait.
        await tester.tap(_pilule('Mardi'));
        await tester.pump();
        expect(_coche(_pilule('Mardi')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('la semantique dit selected, et seulement a l\'etat retenu', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle poignee = tester.ensureSemantics();
    fixerVue(tester, vueMobile);
    await tester.pumpWidget(hoteTheme(const _Rangee(initiaux: <int>{0})));

    final SemanticsNode lundi = tester.getSemantics(_pilule('Lundi'));
    final SemanticsNode mardi = tester.getSemantics(_pilule('Mardi'));
    expect(
      lundi,
      isSemantics(label: 'Lundi', isSelected: true, isButton: true),
    );
    expect(
      mardi,
      isSemantics(label: 'Mardi', isSelected: false, isButton: true),
    );
    // Le libelle annonce reste le seul mot : la coche n'en ajoute aucun.
    expect(_libelles(lundi), <String>['Lundi']);
    expect(_libelles(mardi), <String>['Mardi']);
    poignee.dispose();
  });

  for (final (Size vue, double echelle) cas in <(Size, double)>[
    (const Size(390, 900), 1),
    (const Size(1440, 900), 1),
    (const Size(1440, 900), 2),
  ]) {
    testWidgets('la rangee ne bouge pas a la selection '
        '(${cas.$1.width.toInt()} px, texte x${cas.$2.toInt()})', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, cas.$1);
      await tester.pumpWidget(hoteTheme(const _Rangee(), echelleTexte: cas.$2));
      final Map<String, Rect> avant = <String, Rect>{
        for (final String j in _jours) j: tester.getRect(_pilule(j)),
      };
      for (final String j in _jours) {
        await tester.tap(_pilule(j));
        await tester.pump();
        // Apres chaque touche, aucune pilule n'a bouge ni change de taille.
        for (final String k in _jours) {
          expect(tester.getRect(_pilule(k)), avant[k], reason: '$j : $k');
        }
      }
      for (final String j in _jours) {
        expect(_coche(_pilule(j)), findsOneWidget, reason: j);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'place manquante (320 px, texte x2) : largeur gardee, la coche passe '
    'au-dessus du libelle, aucun mot coupe',
    (WidgetTester tester) async {
      fixerVue(tester, const Size(320, 900));
      await tester.pumpWidget(hoteTheme(const _Rangee(), echelleTexte: 2));
      final Map<String, Rect> avant = <String, Rect>{
        for (final String j in _jours) j: tester.getRect(_pilule(j)),
      };
      final double ligne = avant.values
          .map((Rect r) => r.width)
          .reduce((double a, double b) => a > b ? a : b);
      for (final String j in _jours) {
        await tester.tap(_pilule(j));
        await tester.pump();
      }
      for (final String j in _jours) {
        final Rect apres = tester.getRect(_pilule(j));
        // Jamais plus large, jamais deplacee en largeur.
        expect(apres.left, avant[j]!.left, reason: j);
        expect(apres.width, avant[j]!.width, reason: j);
        final Rect coche = tester.getRect(_coche(_pilule(j)));
        final Rect texte = tester.getRect(find.text(j));
        if (apres.height != avant[j]!.height) {
          // Seule une pilule qui occupe toute la ligne change de hauteur, et
          // c'est parce que la coche est posee au-dessus du libelle.
          expect(apres.width, ligne, reason: j);
          expect(coche.bottom, lessThanOrEqualTo(texte.top), reason: j);
        }
        // Le libelle tient sur une ligne : aucun mot coupe pour la coche.
        final RenderParagraph p = tester.renderObject(find.text(j));
        expect(
          p
              .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: j.length),
              )
              .map((TextBox b) => b.top)
              .toSet(),
          hasLength(1),
          reason: j,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final Brightness luminosite in Brightness.values) {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('320 px, texte x2 : rien ne deborde, contenu centre '
          '(${luminosite.name}, ${sens.name})', (WidgetTester tester) async {
        fixerVue(tester, const Size(320, 900));
        await tester.pumpWidget(
          hoteTheme(
            Directionality(
              textDirection: sens,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Rangee(initiaux: <int>{0, 2, 6}),
                  SizedBox(height: AppSpacing.lg),
                  FilterPill(
                    libelle:
                        'Tester la camera et le micro avant la seance '
                        'du mardi',
                    retenue: true,
                    compteur: 3,
                    onPress: null,
                  ),
                ],
              ),
            ),
            luminosite: luminosite,
            echelleTexte: 2,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        const double ecran = 320;
        for (final Element e in find.byType(FilterPill).evaluate()) {
          final Rect r = tester.getRect(find.byWidget(e.widget));
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(ecran));
          final Finder pilule = find.byWidget(e.widget);
          final Rect coche = _coche(pilule).evaluate().isEmpty
              ? Rect.zero
              : tester.getRect(_coche(pilule));
          if (coche != Rect.zero) {
            expect(coche.left, greaterThanOrEqualTo(r.left));
            expect(coche.right, lessThanOrEqualTo(r.right));
            expect(coche.top, greaterThanOrEqualTo(r.top));
            expect(coche.bottom, lessThanOrEqualTo(r.bottom));
          }
        }
      });
    }
  }

  testWidgets(
    'le retrait annonce est celui de la pilule, dans les deux etats',
    (WidgetTester tester) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FilterPill(libelle: 'Jeudi', onPress: null),
              FilterPill(libelle: 'Jeudi', retenue: true, onPress: null),
            ],
          ),
        ),
      );
      final double texte = tester.getSize(find.text('Jeudi').first).width;
      for (int i = 0; i < 2; i++) {
        expect(
          tester.getSize(find.byType(FilterPill).at(i)).width,
          moreOrLessEquals(texte + FilterPill.retraitLargeur, epsilon: 0.01),
        );
      }
    },
  );
}
