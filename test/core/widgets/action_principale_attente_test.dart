// BOUTON-ATTENTE (garde-cap, 07/11/2026 ; DECISION-FLUIDITE-2026-11-07 §2) :
// l'etat `enCours` d'`ActionPrincipale` etait un arc fige aux deux tiers
// (`value: 0.65`), qui se lisait « bloque ». C'est desormais une attente
// vivante dans le bouton :
// - le bouton garde sa taille ;
// - il n'est pas cliquable ;
// - l'attente est annoncee au lecteur d'ecran ;
// - seules l'opacite et une translation bougent ;
// - en mouvement reduit, l'etat est fixe, sans boucle.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

import '../../support/hote_theme.dart';

const ValueKey<String> _cle = ValueKey<String>('bouton');

Widget _hote({
  required bool reduit,
  bool enCours = true,
  bool fleche = false,
  VoidCallback? onPress,
  TextDirection sens = TextDirection.ltr,
}) => hoteTheme(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
      child: Directionality(
        textDirection: sens,
        child: Center(
          child: ActionPrincipale(
            key: _cle,
            libelle: 'Enregistrer',
            pleineLargeur: false,
            fleche: fleche,
            enCours: enCours,
            onPress: onPress ?? () {},
          ),
        ),
      ),
    ),
  ),
);

/// Les translations du reflet (vide quand il n'y a pas de reflet).
List<Offset> _translations(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(AttenteVivante),
        matching: find.byType(Transform),
      ),
    )
    .map(
      (Transform x) => Offset(
        x.transform.getTranslation().x,
        x.transform.getTranslation().y,
      ),
    )
    .toList();

/// L'opacite effective du libelle « Enregistrer » (produit des opacites qui
/// l'enveloppent dans le bouton).
double _opaciteLibelle(WidgetTester tester) {
  double o = 1;
  for (final AnimatedOpacity a in tester.widgetList<AnimatedOpacity>(
    find.ancestor(
      of: find.text('Enregistrer'),
      matching: find.byType(AnimatedOpacity),
    ),
  )) {
    o *= a.opacity;
  }
  return o;
}

void main() {
  group('BOUTON-ATTENTE : l attente vivante du bouton', () {
    testWidgets('en cours : un reflet qui traverse, le libelle reste lu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AttenteVivante), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Le libelle reste visible : un libelle d'attente (« Ouverture du
      // support... ») se lit entier.
      expect(find.text('Enregistrer'), findsOneWidget);
      final List<Offset> avant = _translations(tester);
      expect(avant, hasLength(1));
      await tester.pump(const Duration(milliseconds: 300));
      final List<Offset> apres = _translations(tester);
      // Le mouvement est continu : le reflet a avance, a l'horizontale seule.
      expect(apres.single.dx, greaterThan(avant.single.dx));
      expect(apres.single.dy, 0);
      expect(tester.binding.hasScheduledFrame, isTrue);
      // La boucle dure tant que l'attente dure : pumpAndSettle n'aboutit pas.
      await expectLater(
        () => tester.pumpAndSettle(const Duration(milliseconds: 100)),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets(
      'n anime ni taille ni flou : seulement opacite et translation',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hote(reduit: false));
        await tester.pump(const Duration(milliseconds: 250));
        final Finder dans = find.descendant(
          of: find.byType(AttenteVivante),
          matching: find.byType(SizedBox),
        );
        final Set<Size> tailles = <Size>{};
        for (int i = 0; i < 4; i++) {
          for (final Element e in dans.evaluate()) {
            tailles.add(e.size!);
          }
          await tester.pump(const Duration(milliseconds: 150));
        }
        expect(
          tailles,
          hasLength(1),
          reason: 'le reflet ne change pas de taille',
        );
        expect(
          find.descendant(
            of: find.byType(AttenteVivante),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AttenteVivante),
            matching: find.byType(ImageFiltered),
          ),
          findsNothing,
        );
      },
    );

    for (final bool fleche in <bool>[false, true]) {
      testWidgets('le bouton garde sa taille (fleche : $fleche)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _hote(reduit: false, enCours: false, fleche: fleche),
        );
        await tester.pump();
        final Size repos = tester.getSize(find.byKey(_cle));
        await tester.pumpWidget(_hote(reduit: false, fleche: fleche));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.getSize(find.byKey(_cle)), repos);
      });
    }

    testWidgets('en arabe, le reflet traverse dans le sens de lecture', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, sens: TextDirection.rtl));
      await tester.pump(const Duration(milliseconds: 100));
      final double avant = _translations(tester).single.dx;
      await tester.pump(const Duration(milliseconds: 300));
      expect(_translations(tester).single.dx, lessThan(avant));
    });

    testWidgets('le reflet reste dans le bouton dessine', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      final Rect bouton = tester.getRect(
        find
            .descendant(
              of: find.byKey(_cle),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final Rect attente = tester.getRect(find.byType(AttenteVivante));
      expect(attente, bouton);
    });

    testWidgets('pas cliquable pendant l attente', (WidgetTester tester) async {
      int appuis = 0;
      await tester.pumpWidget(_hote(reduit: false, onPress: () => appuis++));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(_cle), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(appuis, 0);
    });

    testWidgets('annoncee au lecteur d ecran, region vivante', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      final Finder annonce = find.bySemanticsLabel(t.commun.chargement);
      expect(annonce, findsOneWidget);
      expect(tester.getSemantics(annonce).flagsCollection.isLiveRegion, isTrue);
      poignee.dispose();
    });

    testWidgets('mouvement reduit : aucun reflet, aucune boucle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: true));
      await tester.pumpAndSettle();
      expect(find.byType(AttenteVivante), findsOneWidget);
      expect(_translations(tester), isEmpty);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('mouvement reduit : l attente se voit (libelle attenue)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: true));
      await tester.pump();
      // Immediat : aucune animation sous mouvement reduit.
      expect(_opaciteLibelle(tester), lessThan(1));
      expect(_opaciteLibelle(tester), 0.6);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('mouvement normal : le libelle s attenue aussi, en douceur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, enCours: false));
      await tester.pump();
      expect(_opaciteLibelle(tester), 1);
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opaciteLibelle(tester), 0.6);
    });

    testWidgets('au repos : aucune attente, le libelle se lit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, enCours: false));
      await tester.pumpAndSettle();
      expect(find.byType(AttenteVivante), findsNothing);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(_opaciteLibelle(tester), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
