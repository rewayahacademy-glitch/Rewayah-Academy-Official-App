import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_typography.dart';
import 'package:rewayah_academy/core/widgets/brand_logo.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/marque_page.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';
import 'package:rewayah_academy/features/bienvenue/bienvenue_page.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';
import 'package:rewayah_academy/features/connexion/connexion_page.dart';

import '../support/garde_interface.dart';
import '../support/harnais.dart';
import '../support/hote_theme.dart';
import '../support/logo.dart';

/// HIER-1, revue du directeur du 01/10 : « un nom et un titre ne doivent
/// jamais avoir la meme taille ». Un niveau de texte par role, chaque niveau
/// strictement plus grand que le suivant, dans les deux echelles, dans les
/// composants partages, puis sur les ecrans-cles a 320 px et 1440 px.

double _taille(TextStyle? s) => s!.fontSize!;

void main() {
  group('l\'echelle typographique est strictement decroissante', () {
    for (final (String nom, TextTheme echelle) in <(String, TextTheme)>[
      ('standard', AppTypography.standard),
      ('enfant', AppTypography.enfant),
    ]) {
      test('echelle $nom : titres d\'ecran, de section, de carte', () {
        final List<(String, TextStyle?)> niveaux = <(String, TextStyle?)>[
          ('headlineLarge', echelle.headlineLarge),
          ('headlineMedium', echelle.headlineMedium),
          ('headlineSmall', echelle.headlineSmall),
          ('titleLarge', echelle.titleLarge),
          ('titleMedium', echelle.titleMedium),
          ('titleSmall', echelle.titleSmall),
        ];
        for (int i = 1; i < niveaux.length; i++) {
          expect(
            _taille(niveaux[i - 1].$2),
            greaterThan(_taille(niveaux[i].$2)),
            reason:
                '${niveaux[i - 1].$1} doit etre plus grand que '
                '${niveaux[i].$1} (echelle $nom)',
          );
        }
      });

      test('echelle $nom : aucun titre plus petit que le corps', () {
        final double corps = _taille(echelle.bodyLarge);
        expect(_taille(echelle.titleMedium), greaterThan(corps));
        // `titleSmall` peut valoir le corps, a condition d'etre plus gras :
        // le role se lit alors a la graisse.
        expect(_taille(echelle.titleSmall), greaterThanOrEqualTo(corps));
        if (_taille(echelle.titleSmall) == corps) {
          expect(
            echelle.titleSmall!.fontWeight!.value,
            greaterThan(echelle.bodyLarge!.fontWeight!.value),
          );
        }
      });
    }
  });

  group('composants partages', () {
    for (final Size vue in <Size>[
      const Size(320, 900),
      const Size(1440, 900),
    ]) {
      testWidgets('la marque est plus petite que le titre d\'ecran '
          '(${vue.width} px)', (WidgetTester tester) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            const Column(
              children: <Widget>[
                MarquePage(),
                EntetePage(titre: 'Titre de page'),
                SectionHeader(titre: 'Titre de section'),
              ],
            ),
            defilant: false,
          ),
        );

        verifierHierarchie(
          tester,
          titre: find.text('Titre de page'),
          inferieurs: <String, Finder>{
            'la marque': find.text(t.commun.marque),
            'un titre de section': find.text('Titre de section'),
          },
        );
      });

      testWidgets('un titre de section est plus petit que le titre de '
          'PageShell (${vue.width} px)', (WidgetTester tester) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            const PageShell(
              titre: 'Titre de page',
              child: SectionHeader(titre: 'Titre de section'),
            ),
            defilant: false,
          ),
        );

        verifierHierarchie(
          tester,
          titre: find.text('Titre de page'),
          inferieurs: <String, Finder>{
            'un titre de section': find.text('Titre de section'),
          },
        );
      });
    }
  });

  group('ecrans-cles', () {
    for (final Size vue in <Size>[
      const Size(320, 900),
      const Size(1440, 900),
    ]) {
      testWidgets('accueil public : marque et titre (${vue.width} px)', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(const BienvenuePage(), defilant: false),
        );
        await tester.pump();

        verifierHierarchie(
          tester,
          titre: find.byKey(const ValueKey<String>('bienvenue-accroche')),
          inferieurs: <String, Finder>{'la marque': find.text(t.commun.marque)},
        );
      });

      testWidgets('connexion : marque et titre (${vue.width} px)', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            const ConnexionPage(),
            defilant: false,
            surcharges: <Override>[
              serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
            ],
          ),
        );
        await tester.pump();

        // LOGO-APP (10/10) : la marque de la connexion est le logo vertical,
        // une image, plus un texte ; HIER-1 ne compare que des textes. Le
        // titre reste le seul titre d'ecran, sans mot-marque concurrent.
        expect(find.text(t.connexion.titre), findsOneWidget);
        expect(find.text(t.commun.marque), findsNothing);
        expect(logoRendu(VarianteLogo.vertical), findsOneWidget);
      });

      testWidgets('compte : titre d\'ecran et titres de section '
          '(${vue.width} px)', (WidgetTester tester) async {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            const ReglagesComptePage(),
            defilant: false,
            surcharges: <Override>[
              sourceSessionProvider.overrideWithValue(FausseSourceSession()),
            ],
          ),
        );
        await tester.pump();

        verifierHierarchie(
          tester,
          titre: find.text(t.compte.reglagesTitre),
          inferieurs: <String, Finder>{
            'la section Apparence': find.text(t.compte.apparence),
            'la section Accessibilite': find.text(t.compte.accessibilite),
            'la section Notifications': find.text(t.compte.notifications),
          },
        );
      });
    }
  });
}
