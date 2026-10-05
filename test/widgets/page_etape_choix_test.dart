// Demandes B-3 et A-2 : le gabarit d'etape partage (rangee d'etape V6 sans
// actions de coquille) et le ChoiceCardGroup enrichi (description, option
// indisponible expliquee, radio dessine).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_color_pair.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/page_etape.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/hote_theme.dart';
import '../theme/support/contraste.dart';

const Key _cleCloche = Key('cloche-coquille');

/// Une page sous une coquille qui pose une action d'en-tete (la cloche).
Widget _sousCoquille(Widget page, {double echelleTexte = 1}) => hoteTheme(
  ActionsEnteteCoquille(
    actions: const <Widget>[SizedBox.square(key: _cleCloche, dimension: 48)],
    child: page,
  ),
  defilant: false,
  echelleTexte: echelleTexte,
);

void main() {
  group('PageShell.actionsCoquille', () {
    testWidgets('par defaut, la page garde les actions de la coquille', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        _sousCoquille(PageShell(onRetour: () {}, child: const Text('corps'))),
      );
      expect(find.byKey(_cleCloche), findsOneWidget);
    });

    testWidgets('a faux, ni cloche ni bascule ; le retour reste', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        _sousCoquille(
          PageShell(
            actionsCoquille: false,
            onRetour: () {},
            child: const Text('corps'),
          ),
        ),
      );
      expect(find.byKey(_cleCloche), findsNothing);
      expect(find.byType(DisqueRetour), findsOneWidget);
    });
  });

  group('PageEtape : la rangee d etape V6 en premiere ligne', () {
    Widget page({required VoidCallback onRetour, VoidCallback? onAction}) =>
        PageEtape(
          numero: 2,
          total: 3,
          onRetour: onRetour,
          action: ActionPrincipale(
            libelle: 'Continuer',
            onPress: onAction ?? () {},
            pilule: true,
          ),
          child: const Text('Pour qui est ce profil ?'),
        );

    testWidgets(
      'sans actions de coquille, rangee avant le contenu, CTA en bas',
      (WidgetTester tester) async {
        fixerVue(tester, vueMobile);
        await tester.pumpWidget(_sousCoquille(page(onRetour: () {})));
        expect(tester.takeException(), isNull);
        expect(find.byKey(_cleCloche), findsNothing);
        expect(find.text('2 sur 3'), findsOneWidget);

        final double yRetour = tester.getTopLeft(find.byType(DisqueRetour)).dy;
        final double yContenu = tester
            .getTopLeft(find.text('Pour qui est ce profil ?'))
            .dy;
        final double yAction = tester.getTopLeft(find.text('Continuer')).dy;
        expect(yRetour, lessThan(yContenu));
        expect(yContenu, lessThan(yAction));
        // L'action est collee en bas de l'ecran (zone d'action de PageShell).
        expect(yAction, greaterThan(vueMobile.height / 2));
      },
    );

    testWidgets('semantique : Etape n sur N, retour lu et de 48', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      int retours = 0;
      await tester.pumpWidget(_sousCoquille(page(onRetour: () => retours++)));

      expect(
        find.bySemanticsLabel(t.commun.etape.surLue(n: 2, total: 3)),
        findsOneWidget,
      );
      // Le « 2 sur 3 » visible n'est pas lu deux fois.
      expect(find.bySemanticsLabel('2 sur 3'), findsNothing);
      expect(
        tester.getSemantics(find.byType(DisqueRetour)),
        isSemantics(
          label: t.commun.entete.retour,
          isButton: true,
          hasTapAction: true,
        ),
      );
      final Size disque = tester.getSize(find.byType(DisqueRetour));
      expect(disque.width, greaterThanOrEqualTo(AppTouchTarget.standard));
      expect(disque.height, greaterThanOrEqualTo(AppTouchTarget.standard));

      await tester.tap(find.byType(DisqueRetour));
      expect(retours, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantique.dispose();
    });

    testWidgets('texte a 200 % : aucun debordement, retour et CTA touches', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      int retours = 0;
      int actions = 0;
      await tester.pumpWidget(
        _sousCoquille(
          page(onRetour: () => retours++, onAction: () => actions++),
          echelleTexte: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DisqueRetour));
      await tester.tap(find.text('Continuer'));
      expect(retours, 1);
      expect(actions, 1);
    });
  });

  group('ChoiceCardGroup enrichi', () {
    List<OptionChoix> options() => const <OptionChoix>[
      OptionChoix(
        valeur: 'enfant',
        libelle: 'Mon enfant',
        icone: AppIcons.profil,
        description: 'Un profil suivi par vous',
      ),
      OptionChoix(
        valeur: 'moi',
        libelle: 'Moi-meme',
        description: 'Votre propre profil eleve',
        disponible: false,
        raisonIndisponible: 'Bientot disponible',
      ),
      OptionChoix(valeur: 'autre', libelle: 'Sans description'),
    ];

    testWidgets(
      'description et raison affichees ; indisponible ne se presse pas',
      (WidgetTester tester) async {
        fixerVue(tester, vueMobile);
        final List<ReponseChoix> reponses = <ReponseChoix>[];
        await tester.pumpWidget(
          hoteTheme(
            ChoiceCardGroup(
              options: options(),
              onChange: reponses.add,
              autoriserSaisieLibre: false,
            ),
          ),
        );
        expect(find.text('Un profil suivi par vous'), findsOneWidget);
        expect(find.text('Bientot disponible'), findsOneWidget);

        await tester.tap(find.text('Moi-meme'));
        await tester.pump();
        expect(reponses, isEmpty);

        await tester.tap(find.text('Mon enfant'));
        await tester.pump();
        expect(reponses.single.valeurs, <String>{'enfant'});
        // Selection unique : un radio par carte, aucune coche.
        expect(find.byType(RadioChoix), findsNWidgets(3));
        expect(find.byIcon(AppIcons.succes.actif), findsNothing);
      },
    );

    testWidgets('raison par defaut : « Indisponible » (commun)', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          ChoiceCardGroup(
            options: const <OptionChoix>[
              OptionChoix(valeur: 'x', libelle: 'Option x', disponible: false),
            ],
            onChange: (ReponseChoix _) {},
            autoriserSaisieLibre: false,
          ),
        ),
      );
      expect(find.text(t.commun.choix.indisponible), findsOneWidget);
    });

    testWidgets('semantique : coche, groupe exclusif, libelle complet', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          ChoiceCardGroup(
            options: options(),
            onChange: (ReponseChoix _) {},
            autoriserSaisieLibre: false,
            valeurInitiale: const ReponseChoix(valeurs: <String>{'enfant'}),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Mon enfant')),
        isSemantics(
          label: 'Mon enfant. Un profil suivi par vous',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Moi-meme')),
        isSemantics(
          label: 'Moi-meme. Votre propre profil eleve. Bientot disponible',
          hasEnabledState: true,
          hasCheckedState: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      // Un usage existant, sans description : lu a l'identique.
      expect(
        tester.getSemantics(find.text('Sans description')).label,
        'Sans description',
      );
      semantique.dispose();
    });

    testWidgets('selection multiple : la coche reste, pas de radio', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          ChoiceCardGroup(
            options: const <OptionChoix>[
              OptionChoix(valeur: 'a', libelle: 'Lundi'),
              OptionChoix(valeur: 'b', libelle: 'Mardi'),
            ],
            onChange: (ReponseChoix _) {},
            selectionMultiple: true,
            valeurInitiale: const ReponseChoix(valeurs: <String>{'a'}),
          ),
        ),
      );
      expect(find.byType(RadioChoix), findsNothing);
      expect(find.byIcon(AppIcons.succes.actif), findsOneWidget);
      // La carte « Autre » reste la (autoriserSaisieLibre par defaut).
      expect(find.text(t.choix.autre), findsOneWidget);
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets(
        'anneau du radio >= 3:1, cartes de 48, texte 200 %, $luminosite',
        (WidgetTester tester) async {
          fixerVue(tester, vueMobile);
          await tester.pumpWidget(
            hoteTheme(
              ChoiceCardGroup(
                options: options(),
                onChange: (ReponseChoix _) {},
                autoriserSaisieLibre: false,
                valeurInitiale: const ReponseChoix(valeurs: <String>{'enfant'}),
              ),
              luminosite: luminosite,
              echelleTexte: 2,
            ),
          );
          expect(tester.takeException(), isNull);
          final AppPalette palette = AppPalette.of(
            tester.element(find.byType(ChoiceCardGroup)),
          );
          final List<RadioChoix> radios = tester
              .widgetList<RadioChoix>(find.byType(RadioChoix))
              .toList();
          // Retenu (sur washAccent) puis disponible au repos (sur surfaceRaised).
          final List<(RadioChoix, AppColorPair)> cas =
              <(RadioChoix, AppColorPair)>[
                (radios[0], palette.washAccent),
                (radios[2], palette.surfaceRaised),
              ];
          for (final (RadioChoix radio, AppColorPair carte) in cas) {
            final Color anneau = Color.alphaBlend(
              radio.anneau(palette).debugValue,
              carte.background,
            );
            expect(
              contraste(anneau, carte.background),
              greaterThanOrEqualTo(seuilComposant),
              reason: 'retenue=${radio.retenue}',
            );
          }
          for (final String libelle in <String>['Mon enfant', 'Moi-meme']) {
            final Size carte = tester.getSize(
              find
                  .ancestor(
                    of: find.text(libelle),
                    matching: find.byType(Container),
                  )
                  .first,
            );
            expect(carte.height, greaterThanOrEqualTo(AppTouchTarget.standard));
          }
        },
      );
    }
  });

  group('ChoiceCardGroup.coteACote (A-5.2)', () {
    List<OptionChoix> deux() => <OptionChoix>[
      const OptionChoix(
        valeur: 'homme',
        libelle: 'Homme',
        icone: AppIcons.profil,
        cle: Key('opt-homme'),
      ),
      const OptionChoix(
        valeur: 'femme',
        libelle: 'Femme',
        icone: AppIcons.profil,
        cle: Key('opt-femme'),
      ),
    ];

    testWidgets('par defaut, les cartes restent empilees', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          ChoiceCardGroup(
            options: deux(),
            onChange: (ReponseChoix _) {},
            autoriserSaisieLibre: false,
          ),
        ),
      );
      final Rect a = tester.getRect(find.byKey(const Key('opt-homme')));
      final Rect b = tester.getRect(find.byKey(const Key('opt-femme')));
      expect(a.left, b.left);
      expect(b.top, greaterThan(a.bottom - 1));
    });

    for (final Brightness luminosite in Brightness.values) {
      testWidgets(
        'cote a cote : meme rangee, meme hauteur, icone au-dessus du titre, '
        'radio en haut a droite, tape Femme, $luminosite',
        (WidgetTester tester) async {
          fixerVue(tester, vueMobile);
          ReponseChoix? recue;
          await tester.pumpWidget(
            hoteTheme(
              ChoiceCardGroup(
                options: deux(),
                onChange: (ReponseChoix r) => recue = r,
                autoriserSaisieLibre: false,
                coteACote: true,
              ),
              luminosite: luminosite,
            ),
          );
          expect(tester.takeException(), isNull);
          final Rect homme = tester.getRect(find.byKey(const Key('opt-homme')));
          final Rect femme = tester.getRect(find.byKey(const Key('opt-femme')));
          expect(homme.top, femme.top);
          expect(homme.height, femme.height);
          expect(femme.left, greaterThan(homme.right));
          expect(homme.height, greaterThanOrEqualTo(AppTouchTarget.standard));

          final Finder dansHomme = find.descendant(
            of: find.byKey(const Key('opt-homme')),
            matching: find.byType(Icon),
          );
          final Rect icone = tester.getRect(dansHomme.first);
          final Rect titre = tester.getRect(find.text('Homme'));
          expect(icone.bottom, lessThanOrEqualTo(titre.top));
          expect(icone.center.dx, closeTo(titre.center.dx, 1));

          final Rect radio = tester.getRect(
            find.descendant(
              of: find.byKey(const Key('opt-homme')),
              matching: find.byType(RadioChoix),
            ),
          );
          expect(radio.center.dx, greaterThan(homme.center.dx));
          expect(radio.center.dy, lessThan(titre.top));

          await tester.tap(find.byKey(const Key('opt-femme')));
          await tester.pump();
          expect(recue?.valeurs, <String>{'femme'});
          final RadioChoix radioFemme = tester.widget<RadioChoix>(
            find.descendant(
              of: find.byKey(const Key('opt-femme')),
              matching: find.byType(RadioChoix),
            ),
          );
          expect(radioFemme.retenue, isTrue);
        },
      );
    }

    testWidgets('texte a 200 % : aucun debordement', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, vueMobile);
      await tester.pumpWidget(
        hoteTheme(
          ChoiceCardGroup(
            options: deux(),
            onChange: (ReponseChoix _) {},
            autoriserSaisieLibre: false,
            coteACote: true,
          ),
          echelleTexte: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
