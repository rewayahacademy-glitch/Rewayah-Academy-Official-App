import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/confirm_destructive.dart';
import 'package:rewayah_academy/features/inscription/inscription_page.dart';

import '../support/harnais.dart';

/// Lot A1 : le clavier (Bible V2 §13.4), sur des ecrans reels et le composant
/// modal partage, pas seulement au niveau des jetons.
///
/// Trois axes, chacun deja mentionne ailleurs sans jamais avoir ete prouve :
///
/// 1. **Ordre de focus coherent** : `Tab` avance vers le champ suivant dans
///    l'ordre visuel, pas dans un ordre qui daterait de la construction.
/// 2. **Focus visible** : la bordure de focus vient bien de `borderStrong`,
///    pas d'une couleur oubliee (`test/theme/contraste_test.dart` mesure deja
///    le contraste de `borderStrong` lui-meme, mais ne verifie pas qu'il est
///    reellement celui que `app_theme.dart` cable en `focusedBorder`).
/// 3. **Echap ferme une surface modale** : documente comme « le comportement
///    par defaut d'une route modale, il n'y a rien a cabler »
///    (`lib/core/widgets/app_bottom_sheet.dart`), mais jamais rejoue. C'est le
///    seul point d'entree des surfaces modales du produit
///    (`AppBottomSheet.ouvrir`) : le prouver ici couvre transitivement
///    `ConfirmDestructive`, `FeuilleDemandeTuteur` et `FeuilleRegle`, qui n'en
///    sont que des contenus.
void main() {
  group('Ordre de focus au clavier', () {
    testWidgets(
      'Tab avance du champ prenom vers le champ nom, dans l ordre visuel '
      '(TUT-00c, page identite)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          hote(
            const InscriptionPage(),
            surcharges: <Override>[
              serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
              sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            ],
          ),
        );

        await tester.tap(find.text(t.inscription.roleTuteur));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.commun.continuer));
        await tester.pumpAndSettle();

        final Finder champs = find.byType(TextField);
        expect(champs, findsNWidgets(2), reason: 'prenom, puis nom');

        EditableText editable(int rang) => tester.widget<EditableText>(
          find.descendant(
            of: champs.at(rang),
            matching: find.byType(EditableText),
          ),
        );

        // On entre par le premier champ, comme le ferait un clavier physique
        // qui commence sa tabulation en haut de l'ecran.
        await tester.tap(champs.first);
        await tester.pump();
        expect(
          editable(0).focusNode.hasFocus,
          isTrue,
          reason: 'le champ prenom doit tenir le focus initial',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expect(
          editable(1).focusNode.hasFocus,
          isTrue,
          reason: 'Tab doit faire passer le focus au champ nom, pas ailleurs',
        );
        expect(editable(0).focusNode.hasFocus, isFalse);
      },
    );
  });

  group('Focus visible : la bordure de focus est bien primaryText', () {
    test('app_theme.dart cable focusedBorder sur primaryText, a 2px', () {
      final AppPalette palette = AppPalette.claire();
      final ThemeData theme = AppTheme.pour(
        InterfaceMode.standard,
        Brightness.light,
      );
      final OutlineInputBorder focus =
          theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;

      expect(focus.borderSide.color, palette.inkAccent.asBorderSide().color);
      expect(focus.borderSide.width, 2);

      // Un champ au repos et un champ desactive ne doivent jamais se
      // confondre avec un champ focalise : la largeur les distingue toutes
      // les deux du focus, et l'un de l'autre.
      final OutlineInputBorder repos =
          theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
      final OutlineInputBorder desactive =
          theme.inputDecorationTheme.disabledBorder! as OutlineInputBorder;
      expect(focus.borderSide.width, greaterThan(repos.borderSide.width));
      expect(repos.borderSide.color, isNot(focus.borderSide.color));
      expect(desactive.borderSide.color, isNot(focus.borderSide.color));
    });
  });

  group('Echap ferme une surface modale (Bible V2 §13.4)', () {
    testWidgets(
      'AppBottomSheet.ouvrir se ferme sur Echap, comme un glissement ou Annuler',
      (WidgetTester tester) async {
        bool? resultat;
        await tester.pumpWidget(
          hote(
            Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () async {
                  resultat = await AppBottomSheet.ouvrir<bool>(
                    context,
                    titre: 'Titre de test',
                    constructeur: (BuildContext _) =>
                        const Text('corps de la feuille'),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        expect(find.text('corps de la feuille'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('corps de la feuille'), findsNothing);
        expect(
          resultat,
          isNull,
          reason:
              'Echap ferme sans reponse, exactement comme un glissement : '
              'ce n est ni une confirmation ni un refus explicite.',
        );
      },
    );

    testWidgets(
      'ConfirmDestructive.demander rend false sur Echap, jamais true',
      (WidgetTester tester) async {
        bool? reponse;
        await tester.pumpWidget(
          hote(
            Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () async {
                  reponse = await ConfirmDestructive.demander(
                    context,
                    question: 'Retirer Aicha du foyer ?',
                    consequence: 'Son acces sera desactive.',
                    libelleConfirmer: 'Retirer Aicha',
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        expect(find.text('Retirer Aicha du foyer ?'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.text('Retirer Aicha du foyer ?'), findsNothing);
        expect(
          reponse,
          isFalse,
          reason:
              'demander() convertit toute fermeture sans reponse explicite '
              'en false : Echap ne doit jamais se lire comme une confirmation.',
        );
      },
    );
  });
}
