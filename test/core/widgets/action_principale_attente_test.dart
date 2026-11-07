// BOUTON-ATTENTE, puis FLUIDITE-1 (correction du directeur du 07/11/2026 :
// le reflet « attire l'oeil, il ne dit pas : attendez, je fais quelque
// chose ») : l'etat `enCours` d'`ActionPrincipale` etait un arc fige aux deux
// tiers (`value: 0.65`). C'est desormais un anneau indetermine qui tourne
// vraiment, a la place et a la taille de l'ancien, a cote du libelle attenue :
// - le bouton garde sa taille (sans prefixe, avec fleche, avec prefixe) ;
// - il n'est pas cliquable, et l'attente est annoncee au lecteur d'ecran ;
// - aucun reflet, aucune taille animee, aucun flou ;
// - en mouvement reduit : aucune rotation, un pictogramme d'attente fixe ;
// - la coche de reussite est jouee une seule fois par jeton, apres quoi le
//   libelle revient ; fixe en mouvement reduit.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';

import '../../support/annonces.dart';
import '../../support/hote_theme.dart';

const ValueKey<String> _cle = ValueKey<String>('bouton');

Widget _hote({
  required bool reduit,
  bool enCours = true,
  bool fleche = false,
  Widget? prefixe,
  Object? reussite,
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
            prefixe: prefixe,
            enCours: enCours,
            reussite: reussite,
            onPress: onPress ?? () {},
          ),
        ),
      ),
    ),
  ),
);

/// L'opacite effective du libelle « Enregistrer » (produit des opacites qui
/// l'enveloppent dans le bouton).
double _opaciteLibelle(WidgetTester tester) {
  double o = 1;
  final Finder libelle = find.text('Enregistrer');
  for (final AnimatedOpacity a in tester.widgetList<AnimatedOpacity>(
    find.ancestor(of: libelle, matching: find.byType(AnimatedOpacity)),
  )) {
    o *= a.opacity;
  }
  for (final Opacity a in tester.widgetList<Opacity>(
    find.ancestor(of: libelle, matching: find.byType(Opacity)),
  )) {
    o *= a.opacity;
  }
  return o;
}

Finder get _anneau => find.descendant(
  of: find.byType(AttenteVivante),
  matching: find.byType(CircularProgressIndicator),
);

Finder get _coche => find.byType(CocheReussite);

final Duration _jeu =
    AppMouvement.apparition +
    AppMouvement.reussiteMaintien +
    AppMouvement.disparitionOpacite;

void main() {
  group('L attente du bouton : un anneau qui tourne', () {
    testWidgets('en cours : un anneau indetermine, le libelle reste lu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_anneau, findsOneWidget);
      // Indetermine : il tourne, il ne montre pas une valeur figee.
      expect(tester.widget<CircularProgressIndicator>(_anneau).value, isNull);
      expect(find.text('Enregistrer'), findsOneWidget);
      // Il tourne tant que l'attente dure : pumpAndSettle n'aboutit pas.
      expect(tester.binding.hasScheduledFrame, isTrue);
      await expectLater(
        () => tester.pumpAndSettle(const Duration(milliseconds: 100)),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('l anneau est a cote du libelle, avant lui, a la place de l '
        'ancien (xl, trait 2)', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      // La place de l'ancien anneau fige : un carre AppSpacing.xl (20).
      final Rect anneau = tester.getRect(find.byType(AttenteVivante));
      final Rect libelle = tester.getRect(find.text('Enregistrer'));
      expect(anneau.size, const Size.square(AppSpacing.xl));
      expect(tester.widget<CircularProgressIndicator>(_anneau).strokeWidth, 2);
      expect(anneau.right, lessThanOrEqualTo(libelle.left));
      expect(anneau.center.dy, closeTo(libelle.center.dy, 1));
      // L'anneau reste dans le bouton dessine.
      final Rect bouton = tester.getRect(
        find
            .descendant(
              of: find.byKey(_cle),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(bouton.contains(anneau.topLeft), isTrue);
      expect(bouton.contains(anneau.bottomRight), isTrue);
    });

    testWidgets('en arabe, l anneau est avant le libelle, a droite', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, sens: TextDirection.rtl));
      await tester.pump(const Duration(milliseconds: 100));
      final Rect anneau = tester.getRect(_anneau);
      final Rect libelle = tester.getRect(find.text('Enregistrer'));
      expect(anneau.left, greaterThanOrEqualTo(libelle.right));
    });

    for (final (String cas, bool fleche, Widget? prefixe)
        in <(String, bool, Widget?)>[
          ('sans prefixe ni fleche', false, null),
          ('avec fleche', true, null),
          ('avec prefixe', false, const SizedBox.square(dimension: 24)),
        ]) {
      testWidgets('le bouton garde sa taille ($cas)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _hote(
            reduit: false,
            enCours: false,
            fleche: fleche,
            prefixe: prefixe,
          ),
        );
        await tester.pump();
        final Size repos = tester.getSize(find.byKey(_cle));
        await tester.pumpWidget(
          _hote(reduit: false, fleche: fleche, prefixe: prefixe),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.getSize(find.byKey(_cle)), repos);
      });
    }

    testWidgets('aucun reflet, aucun flou dans l attente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 250));
      for (final Type type in <Type>[BackdropFilter, ImageFiltered]) {
        expect(
          find.descendant(of: find.byKey(_cle), matching: find.byType(type)),
          findsNothing,
        );
      }
      expect(
        find.descendant(
          of: find.byType(AttenteVivante),
          matching: find.byType(Transform),
        ),
        findsNothing,
        reason: 'plus de reflet qui traverse',
      );
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

    testWidgets('mouvement reduit : aucune rotation, un pictogramme fixe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: true));
      await tester.pumpAndSettle();
      expect(find.byType(AttenteVivante), findsOneWidget);
      expect(_anneau, findsNothing);
      expect(
        find.descendant(
          of: find.byType(AttenteVivante),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(_opaciteLibelle(tester), 0.6);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('mouvement normal : le libelle s attenue, en douceur', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, enCours: false));
      await tester.pump();
      expect(_opaciteLibelle(tester), 1);
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_opaciteLibelle(tester), 0.6);
    });

    testWidgets('au repos : aucune attente, aucune coche, le libelle se lit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(reduit: false, enCours: false));
      await tester.pumpAndSettle();
      expect(find.byType(AttenteVivante), findsNothing);
      expect(_coche, findsNothing);
      expect(_opaciteLibelle(tester), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('La coche de reussite, une seule fois', () {
    Finder iconeCoche() =>
        find.descendant(of: _coche, matching: find.byType(Icon));

    testWidgets('apres la confirmation : la coche entre, puis le libelle '
        'revient, le bouton garde sa taille', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(reduit: false));
      await tester.pump(const Duration(milliseconds: 100));
      final Size taille = tester.getSize(find.byKey(_cle));
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 1),
      );
      await tester.pump(AppMouvement.apparition);
      expect(iconeCoche(), findsOneWidget);
      expect(_opaciteLibelle(tester), lessThan(0.1));
      expect(tester.getSize(find.byKey(_cle)), taille);
      await tester.pumpAndSettle();
      expect(iconeCoche(), findsNothing);
      expect(_opaciteLibelle(tester), 1);
      expect(tester.getSize(find.byKey(_cle)), taille);
    });

    testWidgets('le meme jeton ne rejoue rien ; un nouveau jeton rejoue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 'a'),
      );
      await tester.pumpAndSettle();
      expect(iconeCoche(), findsNothing);
      // Reconstruit avec le meme jeton : rien de plus.
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 'a'),
      );
      await tester.pump(AppMouvement.apparition);
      expect(iconeCoche(), findsNothing);
      // Un nouveau jeton : la coche rejoue une fois.
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 'b'),
      );
      await tester.pump(AppMouvement.apparition);
      expect(iconeCoche(), findsOneWidget);
      await tester.pump(_jeu);
      await tester.pump();
      expect(iconeCoche(), findsNothing);
    });

    testWidgets('la coche n anime que l opacite et l echelle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 1),
      );
      await tester.pump(AppMouvement.apparition ~/ 2);
      final Transform echelle = tester.widget<Transform>(
        find.descendant(of: _coche, matching: find.byType(Transform)).first,
      );
      final double s = echelle.transform.storage[0];
      expect(s, greaterThan(0.6));
      expect(s, lessThan(1));
      expect(echelle.transform.getTranslation().x, 0);
      await tester.pumpAndSettle();
    });

    testWidgets('annoncee une fois au lecteur d ecran', (
      WidgetTester tester,
    ) async {
      final List<String> annonces = ecouterAnnonces(tester);
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 1),
      );
      await tester.pump(AppMouvement.apparition);
      await tester.pumpWidget(
        _hote(reduit: false, enCours: false, reussite: 1),
      );
      await tester.pumpAndSettle();
      expect(annonces, <String>[t.commun.reussite]);
    });

    testWidgets('mouvement reduit : la coche fixe, sans echelle, puis le '
        'libelle', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(reduit: true, enCours: false, reussite: 1));
      await tester.pump();
      expect(iconeCoche(), findsOneWidget);
      final Transform echelle = tester.widget<Transform>(
        find.descendant(of: _coche, matching: find.byType(Transform)).first,
      );
      expect(echelle.transform.storage[0], 1);
      await tester.pump(_jeu);
      await tester.pump();
      expect(iconeCoche(), findsNothing);
      expect(_opaciteLibelle(tester), 1);
    });
  });
}
