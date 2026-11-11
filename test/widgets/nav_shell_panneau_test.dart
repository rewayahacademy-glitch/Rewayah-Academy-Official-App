// NAV-REFONTE etape 3 (brief du garde-cap du 09/11/2026, feu vert du pilote
// du 11/11/2026) : le panneau de navigation de la tablette et de
// l'ordinateur. Un seul bouton carre, a la meme place ouvert ou replie ; le
// Compte quitte la liste et vit au pied, en photo, prenom et menu (Compte,
// theme, sortie) ; replie, un rail d'icones a infobulles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/theme/app_gabarit.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/halo_compte.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../support/aucun_mot_coupe.dart';

List<Destination> _enseignant() =>
    destinationsPour(role: AppRole.teacher, mode: InterfaceMode.standard);

Future<ProviderContainer> _monter(
  WidgetTester tester, {
  required Size taille,
  List<Destination>? destinations,
  void Function(String chemin)? onAller,
  VoidCallback? onDeconnexion,
  EtatHaloCompte? halo,
  ThemeMode theme = ThemeMode.light,
  TextDirection direction = TextDirection.ltr,
  double echelle = 1,
  InterfaceMode mode = InterfaceMode.standard,
  bool? repliee,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ProviderContainer conteneur = ProviderContainer();
  addTearDown(conteneur.dispose);
  if (repliee != null) {
    conteneur
        .read(navigationReplieeProvider.notifier)
        .choisir(repliee: repliee);
  }
  final List<Destination> d = destinations ?? _enseignant();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: conteneur,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(mode, Brightness.light),
          darkTheme: AppTheme.pour(mode, Brightness.dark),
          themeMode: theme,
          builder: (BuildContext contexte, Widget? enfant) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: enfant!,
            ),
          ),
          home: NavShell(
            destinations: d,
            indexActif: 0,
            onAller: onAller ?? (String _) {},
            onDeconnexion: onDeconnexion,
            halo: halo,
            libellesDansLeRail: true,
            child: const PageShell(child: SizedBox(key: Key('contenu'))),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return conteneur;
}

Finder _bouton() => find.byKey(NavShell.boutonRepliKey);
Finder _pied() => find.byKey(NavShell.piedCompteKey);

void main() {
  group('un seul bouton, a la meme place', () {
    for (final TextDirection sens in TextDirection.values) {
      testWidgets('ouvert puis replie (${sens.name}) : meme bord, meme haut', (
        WidgetTester tester,
      ) async {
        await _monter(tester, taille: const Size(1440, 900), direction: sens);
        expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
        final Rect ouvert = tester.getRect(_bouton());
        await tester.tap(_bouton());
        await tester.pump();
        expect(find.byKey(NavShell.railKey), findsOneWidget);
        final Rect replie = tester.getRect(_bouton());
        expect(replie.top, ouvert.top);
        if (sens == TextDirection.ltr) {
          expect(replie.left, ouvert.left);
        } else {
          expect(replie.right, ouvert.right);
        }
        // Un seul bouton de bascule, jamais deux fleches.
        expect(_bouton(), findsOneWidget);
      });
    }

    testWidgets('le bouton dit son etat et sa cible fait 48', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1440, 900));
      expect(tester.getSize(_bouton()).width, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(_bouton()),
        matchesSemantics(
          label: t.nav.replier,
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          hasExpandedState: true,
          isExpanded: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    });
  });

  group('le Compte quitte la liste, au pied du panneau', () {
    testWidgets(
      'enseignant : Aujourd hui, Classes, Messages ; Compte au pied',
      (WidgetTester tester) async {
        await _monter(tester, taille: const Size(1440, 900));
        final List<Destination> d = _enseignant();
        final Destination compte = d.firstWhere((Destination x) => x.compte);
        expect(
          d
              .where((Destination x) => !x.compte)
              .map((Destination x) => x.libelle),
          <String>[
            t.nav.enseignant.journee,
            t.nav.enseignant.classes,
            t.com.socle.lexique.messages,
          ],
        );
        for (final Destination x in d.where((Destination x) => !x.compte)) {
          expect(find.text(x.libelle), findsOneWidget, reason: x.libelle);
        }
        // Sans prenom lu, le pied montre le nom de la destination, une fois.
        expect(_pied(), findsOneWidget);
        expect(
          find.descendant(of: _pied(), matching: find.text(compte.libelle)),
          findsOneWidget,
        );
        // Au pied, sous la derniere destination de la liste.
        expect(
          tester.getTopLeft(_pied()).dy,
          greaterThan(
            tester.getBottomLeft(find.text(t.com.socle.lexique.messages)).dy,
          ),
        );
      },
    );

    testWidgets('le menu : Compte, theme, Se deconnecter', (
      WidgetTester tester,
    ) async {
      final List<String> allers = <String>[];
      int sorties = 0;
      final ProviderContainer c = await _monter(
        tester,
        taille: const Size(1440, 900),
        onAller: allers.add,
        onDeconnexion: () => sorties++,
      );
      final Destination compte = _enseignant().firstWhere(
        (Destination x) => x.compte,
      );

      await tester.tap(_pied());
      await tester.pumpAndSettle();
      expect(find.text(t.commun.theme.sombre), findsOneWidget);
      expect(find.text(t.compte.deconnexion), findsOneWidget);
      // L'entree du Compte, dans le menu (le pied porte aussi son nom).
      expect(find.text(compte.libelle), findsNWidgets(2));

      await tester.tap(find.text(t.commun.theme.sombre));
      await tester.pumpAndSettle();
      expect(c.read(preferencesLocalesProvider).theme, PreferenceTheme.sombre);

      await tester.tap(_pied());
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.compte.deconnexion));
      await tester.pumpAndSettle();
      expect(sorties, 1);

      await tester.tap(_pied());
      await tester.pumpAndSettle();
      await tester.tap(find.text(compte.libelle).last);
      await tester.pumpAndSettle();
      expect(allers, <String>[compte.chemin]);
    });

    testWidgets('sans sortie fournie, aucune entree « Se deconnecter »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(1440, 900));
      await tester.tap(_pied());
      await tester.pumpAndSettle();
      expect(find.text(t.compte.deconnexion), findsNothing);
    });

    testWidgets('avec un halo : « En ce moment » en tete du menu', (
      WidgetTester tester,
    ) async {
      final List<EtatHaloCompte> touches = <EtatHaloCompte>[];
      tester.view.physicalSize = const Size(1440, 900);
      await _monter(
        tester,
        taille: const Size(1440, 900),
        halo: EtatHaloCompte.nouveau(nombre: 2, chemin: '/notifications'),
      );
      expect(touches, isEmpty);
      await tester.tap(_pied());
      await tester.pumpAndSettle();
      final Finder enCeMoment = find.text(t.nav.halo.enCeMoment);
      expect(enCeMoment, findsOneWidget);
      expect(
        tester.getTopLeft(enCeMoment).dy,
        lessThan(tester.getTopLeft(find.text(t.commun.theme.sombre)).dy),
      );
    });
  });

  group('rail replie', () {
    testWidgets('tablette 800 : replie par defaut, photo seule au pied', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        taille: const Size(800, 1000),
        destinations: destinationsPour(
          role: AppRole.guardian,
          mode: InterfaceMode.standard,
        ),
      );
      expect(find.byKey(NavShell.railKey), findsOneWidget);
      expect(
        tester.getSize(find.byKey(NavShell.railKey)).width,
        greaterThanOrEqualTo(AppGabarit.largeurRail),
      );
      // Replie : le nom en infobulle, pas ecrit.
      final Destination compte = destinationsPour(
        role: AppRole.guardian,
        mode: InterfaceMode.standard,
      ).firstWhere((Destination x) => x.compte);
      expect(
        find.descendant(of: _pied(), matching: find.text(compte.libelle)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _pied(),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Tooltip && w.message == compte.libelle,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(_pied()).height, greaterThanOrEqualTo(48));
    });

    testWidgets('le choix de l appareil est garde (navigation.repliee)', (
      WidgetTester tester,
    ) async {
      final ProviderContainer c = await _monter(
        tester,
        taille: const Size(1440, 900),
      );
      await tester.tap(_bouton());
      await tester.pump();
      expect(c.read(navigationReplieeProvider), isTrue);
    });
  });

  group('800 et 1440, texte x1 et x2, clair et sombre, arabe', () {
    for (final Size taille in const <Size>[Size(800, 1000), Size(1440, 900)]) {
      for (final double echelle in const <double>[1, 2]) {
        for (final ThemeMode theme in const <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          for (final TextDirection sens in TextDirection.values) {
            for (final bool repliee in const <bool>[false, true]) {
              final String nom =
                  '${taille.width.toInt()} x$echelle ${theme.name} '
                  '${sens.name} ${repliee ? 'replie' : 'ouvert'}';
              testWidgets('$nom : rien de coupe, pied dans le panneau', (
                WidgetTester tester,
              ) async {
                await _monter(
                  tester,
                  taille: taille,
                  echelle: echelle,
                  theme: theme,
                  direction: sens,
                  repliee: repliee,
                );
                final Finder colonne = find.byKey(
                  repliee ? NavShell.railKey : NavShell.barreLateraleKey,
                );
                expect(colonne, findsOneWidget);
                verifierAucunMotCoupe(tester, colonne);
                final Rect panneau = tester.getRect(colonne);
                final Rect pied = tester.getRect(_pied());
                expect(pied.left, greaterThanOrEqualTo(panneau.left));
                expect(pied.right, lessThanOrEqualTo(panneau.right));
                expect(pied.bottom, lessThanOrEqualTo(panneau.bottom));
                expect(tester.takeException(), isNull);
              });
            }
          }
        }
      }
    }

    testWidgets('Mode Accessibilite, rail : le nom reste ecrit sous la photo', (
      WidgetTester tester,
    ) async {
      final List<Destination> d = destinationsPour(
        role: AppRole.teacher,
        mode: InterfaceMode.enfant,
      );
      await _monter(
        tester,
        taille: const Size(800, 1000),
        destinations: d,
        mode: InterfaceMode.enfant,
      );
      final Destination compte = d.firstWhere((Destination x) => x.compte);
      expect(
        find.descendant(of: _pied(), matching: find.text(compte.libelle)),
        findsOneWidget,
      );
      expect(tester.getSize(_pied()).height, greaterThanOrEqualTo(72));
    });
  });
}
